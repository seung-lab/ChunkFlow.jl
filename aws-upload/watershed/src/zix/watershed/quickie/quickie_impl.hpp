//
// Copyright (C) 2010  Aleksandar Zlateski <zlateski@mit.edu>
// ----------------------------------------------------------
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#ifndef ZI_WATERSHED_QUICKIE_QUICKIE_IMPL_HPP
#define ZI_WATERSHED_QUICKIE_QUICKIE_IMPL_HPP 1

#include <zi/watershed/detail/types.hpp>
#include <zi/watershed/detail/traits.hpp>
#include <zi/watershed/detail/utility.hpp>
#include <zi/watershed/detail/volume_ref.hpp>

#include <zi/bits/cstdint.hpp>
#include <zi/bits/tuple.hpp>
#include <zi/bits/function.hpp>
#include <zi/bits/type_traits.hpp>
#include <zi/bits/unordered_map.hpp>

#include <zi/utility/for_each.hpp>
#include <zi/utility/assert.hpp>

#include <zi/parallel/algorithm.hpp>

#include <zi/disjoint_sets/disjoint_sets.hpp>

#include <vector>
#include <queue>
#include <deque>

#include <functional>
#include <algorithm>
#include <utility>
#include <cstddef>
#include <iostream>
#include <limits>

#include <zi/watershed/quickie/prefix.hpp>

namespace zi {
namespace watershed {

namespace detail {

void dummy_function() {}

template< class T, std::size_t, class >
struct highest_bit_helper;

template< class T >
struct highest_bit_helper< T, 2, true_type >
    : integral_constant< T, 0x8000 >
{};

template< class T >
struct highest_bit_helper< T, 4, true_type >
    : integral_constant< T, 0x80000000 >
{};

template< class T >
struct highest_bit_helper< T, 8, true_type >
    : integral_constant< T, 0x8000000000000000ll >
{};

template< class T >
struct highest_bit
    : highest_bit_helper< T, sizeof(T), typename is_integral< T >::type >
{};

} // namespace detail

struct border
{
    static const int none     = 0x00;
    static const int before_x = 0x01;
    static const int after_x  = 0x08;
    static const int before_y = 0x02;
    static const int after_y  = 0x10;
    static const int before_z = 0x04;
    static const int after_z  = 0x20;
    static const int all      = 0x3f;
};

template< class T, class Id, class Count >
inline size_type
chunk_quickie_impl( const size_type      xsize,
                    const size_type      ysize,
                    const size_type      zsize,
                    const T*             conn,
                    const T&             high,
                    const T&             low,
                    const Count&         min_size,
                    const T&             low_merge,
                    const int            borders,
                    Id*                  seg,
                    std::vector< Count >& counts,
                    std::vector< tuple< Id, Id, T > >& dendr,
                    function< void() >   clear_conn_fn =
                    function< void() >( &detail::dummy_function ) )
{
    typedef T        value_type ;
    typedef Id       id_type    ;
    typedef Count    count_type ;

    typedef std::pair< id_type, id_type > id_pair;
    typedef tuple< id_type, id_type, T >  edge_type;

    typedef typename detail::highest_bit< Id >::type      assigned_bit   ;
    typedef typename detail::highest_bit< Count >::type   border_bit     ;
    typedef typename integral_constant< Id, 0x40 >::type  visited_bit    ;

    const size_type size = xsize*ysize*zsize;
    const index     xdim = static_cast< index >( xsize );
    const index     ydim = static_cast< index >( ysize );
    const index     zdim = static_cast< index >( zsize );

    //
    // Initialization
    //

    std::fill_n( seg, size, 0 );
    counts.clear();
    dendr.clear();

    //
    // make a graph representation
    //
    const_volume_ref< T, 4 > cmat( conn, extents[ xdim ][ ydim ][ zdim ][ 3 ] );
    volume_ref< Id, 3 >      ids ( seg,  extents[ xdim ][ ydim ][ zdim ] );

    const id_type border_vals[6] =
        {
            borders & border::before_x ? 0 : 0x08,
            borders & border::before_y ? 0 : 0x10,
            borders & border::before_z ? 0 : 0x20,
            borders & border::after_x  ? 0 : 0x01,
            borders & border::after_y  ? 0 : 0x02,
            borders & border::after_z  ? 0 : 0x04
        };

    QW_FOR_2( index, z, 1, zdim-1, y, 1, ydim-1 )
    {
        ids[0][y][z]      = cmat[1][y][z][0]      >= high ? 0x08 : border_vals[0];
        ids[xdim-1][y][z] = cmat[xdim-1][y][z][0] >= high ? 0x01 : border_vals[3];
    }

    QW_FOR_2( index, z, 1, zdim-1, x, 1, xdim-1 )
    {
        ids[x][0][z]      = cmat[x][1][z][1]      >= high ? 0x10 : border_vals[1];
        ids[x][ydim-1][z] = cmat[x][ydim-1][z][1] >= high ? 0x02 : border_vals[4];
    }

    QW_FOR_2( index, y, 1, ydim-1, x, 1, xdim-1 )
    {
        ids[x][y][0]      = cmat[x][y][1][2]      >= high ? 0x20 : border_vals[2];
        ids[x][y][zdim-1] = cmat[x][y][zdim-1][2] >= high ? 0x04 : border_vals[5];
    }

    QW_FOR_3( index, z, 1, zdim-1, y, 1, ydim-1, x, 1, xdim-1 )
    {
        id_type& id = ids[x][y][z];

        const T negx = cmat[x][y][z][0];
        const T negy = cmat[x][y][z][1];
        const T negz = cmat[x][y][z][2];
        const T posx = cmat[x+1][y][z][0];
        const T posy = cmat[x][y+1][z][1];
        const T posz = cmat[x][y][z+1][2];

        value_type m = QW_MAX6( negx, negy, negz, posx, posy, posz );

        if ( m >= low )
        {
            if ( negx == m || negx >= high ) { id |= 0x01; }
            if ( negy == m || negy >= high ) { id |= 0x02; }
            if ( negz == m || negz >= high ) { id |= 0x04; }
            if ( posx == m || posx >= high ) { id |= 0x08; }
            if ( posy == m || posy >= high ) { id |= 0x10; }
            if ( posz == m || posz >= high ) { id |= 0x20; }
        }
    }

    const index   dindex[6]   = { -1, -xdim, -xdim*ydim, 1, xdim, xdim*ydim };
    const id_type dirmask[6]  = { 0x01, 0x02, 0x04, 0x08, 0x10, 0x20 };
    const id_type idirmask[6] = { 0x08, 0x10, 0x20, 0x01, 0x02, 0x04 };

    std::deque< index >  bfs;
    index                bfs_index;

    id_type next_id = 1;

    counts.push_back( 0 );

    QW_FOR_3( index, iz, 1, zdim-1, iy, 1, ydim-1, ix, 1, xdim-1 )
    {
        index idx = &ids[ix][iy][iz] - seg;

        if ( !( seg[ idx ] & assigned_bit::value ) && seg[ idx ] )
        {
            bfs.push_back( idx );
            bfs_index = 0;
            seg[ idx ] |= visited_bit::value;

            while ( bfs_index < static_cast< index >( bfs.size() ))
            {
                index y = bfs[ bfs_index ];

                for ( index d = 0; d < 6; ++d )
                {
                    if ( seg[ y ] & dirmask[ d ] )
                    {
                        index z = y + dindex[ d ];

                        if ( seg[ z ] & assigned_bit::value )
                        {
                            id_type& seg_id = seg[ z ];
                            counts[ seg_id & ~assigned_bit::value ] += bfs.size();
                            FOR_EACH( it, bfs )
                            {
                                seg[ *it ] = seg_id;
                            }

                            bfs.clear();
                            break;
                        }
                        else if ( !( seg[ z ] & visited_bit::value ) )
                        {
                            seg[ z ] |= visited_bit::value;
                            bfs.push_back( z );
                            if ( !( seg[ z ] & idirmask[ d ] ) )  // dfs now
                            {
                                bfs_index = bfs.size() - 2;
                                break;
                            }
                        }
                    }
                }
                ++bfs_index;
            }

            if ( bfs.size() )
            {
                counts.push_back( bfs.size() );
                FOR_EACH( it, bfs )
                {
                    seg[ *it ] = assigned_bit::value | next_id;
                }
                ++next_id;
                bfs.clear();
            }
        }
    }

    //std::cout << "next_id: " << next_id << " \n";

    for ( id_type i = 0; i < static_cast< id_type >( size ); ++i )
    {
        if ( seg[ i ] & assigned_bit::value )
        {
            seg[ i ] &= ~assigned_bit::value;
        }
        else
        {
            seg[ i ] = 0;
        }
    }

    zi::unordered_map< id_pair, T > uniques;

    value_type dend_min = std::min( low, low_merge );

    for ( index d = 0, eoff = 0; d < 3; ++d, eoff += size )
    {
        QW_FOR_3( index, z, 1, zdim-1, y, 1, ydim-1, x, 1, xdim-1 )
        {
            index i = &ids[x][y][z] - seg;

            if ( conn[ eoff + i ] >= dend_min &&
                 seg[ i ] &&
                 seg[ i + dindex[ d ] ] &&
                 seg[ i + dindex[ d ] ] != seg[ i ] )
            {
                id_pair p = minmax( seg[ i ], seg[ i + dindex[ d ] ] );
                typename unordered_map< id_pair, T >::iterator it =
                    uniques.find( p );

                if ( it == uniques.end() )
                {
                    uniques.insert( std::make_pair( p, conn[ eoff + i ] ) );
                }
                else
                {
                    if ( it->second < conn[ eoff + i ] )
                    {
                        it->second = conn[ eoff + i ];
                    }
                }
            }
        }
    }

    dendr.resize( uniques.size() );
    index idx = 0;

    FOR_EACH( it, uniques )
    {
        dendr[ idx ] = tie( it->first.first, it->first.second, it->second );
        ++idx;
    }

    uniques.clear();

    zi::sort( dendr.begin(), dendr.end(), edge_compare< T, Id > );

    std::vector< bool > on_border( next_id );
    std::vector< bool > locked( next_id );

    const bool has_border[6] = { borders & border::before_x,
                                 borders & border::before_y,
                                 borders & border::before_z,
                                 borders & border::after_x,
                                 borders & border::after_y,
                                 borders & border::after_z };

    QW_FOR_2( index, z, 1, zdim-1, y, 1, ydim-1 )
    {
        on_border[ ids[xdim-2][y][z] ] = has_border[0];
        on_border[ ids[1][y][z]      ] = has_border[3];
    }

    QW_FOR_2( index, z, 1, zdim-1, x, 1, xdim-1 )
    {
        on_border[ ids[x][ydim-2][z] ] = has_border[1];
        on_border[ ids[x][1][z]      ] = has_border[4];
    }

    QW_FOR_2( index, y, 1, ydim-1, x, 1, xdim-1 )
    {
        on_border[ ids[x][y][zdim-2] ] = has_border[2];
        on_border[ ids[x][y][1]      ] = has_border[5];
    }

    QW_FOR_2( index, z, 1, zdim-1, y, 1, ydim-1 )
    {
        locked[ ids[xdim-1][y][z] ] = locked[ ids[xdim-1][y][z] ] ||
            ( cmat[xdim-1][y][z][0] < high && has_border[0] );
        locked[ ids[0][y][z]      ] = locked[ ids[0][y][z]      ] ||
            ( cmat[1][y][z][0] < high && has_border[3] );
    }

    QW_FOR_2( index, z, 1, zdim-1, x, 1, xdim-1 )
    {
        locked[ ids[x][ydim-1][z] ] = locked[ ids[x][ydim-1][z] ] ||
            ( cmat[x][ydim-1][z][1] < high && has_border[1] );
        locked[ ids[x][0][z]      ] = locked[ ids[x][0][z]      ] ||
            ( cmat[x][1][z][1] < high && has_border[4] );
    }

    QW_FOR_2( index, y, 1, ydim-1, x, 1, xdim-1 )
    {
        locked[ ids[x][y][zdim-1] ] = locked[ ids[x][y][zdim-1] ] ||
            ( cmat[x][y][zdim-1][2] < high && has_border[2] );
        locked[ ids[x][y][0]      ] = locked[ ids[x][y][0]      ] ||
            ( cmat[x][y][1][2] < high && has_border[5] );
    }

    disjoint_sets< id_type > sets( next_id );

    for ( size_type i = 0; i < dendr.size(); ++i )
    {
        id_type v1 = sets.find_set( zi::get< 0 >( dendr[ i ] ) );
        id_type v2 = sets.find_set( zi::get< 1 >( dendr[ i ] ) );

        ZI_ASSERT_0( v1 == 0 || v2 == 0 );

        if ( v1 != v2 )
        {
            if ( locked[ v1 ] )
            {
                on_border[ v2 ] = true;
            }

            if ( locked[ v2 ] )
            {
                on_border[ v1 ] = true;
            }

            if ( ( counts[ v1 ] < min_size && !on_border[ v1 ] ) ||
                 ( counts[ v2 ] < min_size && !on_border[ v2 ] ) )
            {
                on_border[ v1 ] = on_border[ v2 ] = on_border[ v1 ] || on_border[ v2 ];
                counts[ v1 ] += counts[ v2 ];
                counts[ v2 ]  = 0;
                std::swap( counts[ sets.join( v1, v2 ) ], counts[ v1 ] );
                --next_id;
            }
        }
    }

    std::vector< id_type > remaps( counts.size() );

    id_type next_new_id = 1;
    for ( size_type i = 1; i < counts.size(); ++i )
    {
        if ( counts[ i ] )
        {
            ZI_ASSERT( sets.find_set( i ) == static_cast< id_type >( i ) );

            if ( counts[ i ] >= min_size || on_border[ i ] )
            {
                counts[ next_new_id ] = counts[ i ];
                remaps[ i ] = next_new_id;
                ++next_new_id;
            }
            else
            {
                counts[ 0 ] += counts[ i ];
                counts[ i ]  = remaps[ i ] = 0;
            }
        }
    }

    counts.resize( next_new_id );

    for ( size_type i = 1; i < remaps.size(); ++i )
    {
        remaps[ i ] = remaps[ sets.find_set( i ) ];
    }

    for ( size_type i = 0; i < size; ++i )
    {
        ZI_ASSERT( remaps[ sets.find_set( seg[ i ] ) ] == remaps[ seg[ i ] ] );
        seg[ i ] = remaps[ seg[ i ] ];
    }

    sets.resize( next_new_id );

    index dend_len = 0;
    for ( size_type i = 0; i < dendr.size(); ++i )
    {
        id_type a1 = remaps[ zi::get< 0 >( dendr[ i ] ) ];
        id_type a2 = remaps[ zi::get< 1 >( dendr[ i ] ) ];

        id_type v1 = sets.find_set( a1 );
        id_type v2 = sets.find_set( a2 );

        if ( v1 && v2 && v1 != v2 )
        {
            sets.join( v1, v2 );
            dendr[ dend_len++ ] = tie( a1, a2, zi::get< 2 >( dendr[ i ] ) );
        }
    }

    dendr.resize( dend_len );

    return counts.size();

    //std::cout << "next_nw: " << counts.size() << " \n";
    //std::cout << "dendlen: " << dendr.size() << " \n";

}

/*
template< class T, class Id, class Count >
inline size_type
chunk_quickie( const size_type      xsize,
               const size_type      ysize,
               const size_type      zsize,
               typename watershed_traits< T, Id, Count >::const_value_ptr   conn,
               typename watershed_traits< T, Id, Count >::const_value_type& high,
               typename watershed_traits< T, Id, Count >::const_value_type& low,
               typename watershed_traits< T, Id, Count >::const_count_type& min_size,
               typename watershed_traits< T, Id, Count >::const_value_type& low_merge,
               const int                                                   borders,
               typename watershed_traits< T, Id, Count >::id_ptr           seg,
               typename watershed_traits< T, Id, Count >::count_vector&    counts,
               typename watershed_traits< T, Id, Count >::edge_vector&    dendr,
               function< void() > clear_conn_fn =
               function< void() >( &detail::dummy_function ) )
{
    chunk_quickie_impl< T, Id, Count >( xsize, ysize, zsize, conn, high, low, min_size,
                                        low_merge, seg, count, dendr, clear_conn_fn );
}

*/

} // namespace watershed
} // namespace zi

#include <zi/watershed/quickie/suffix.hpp>

#endif
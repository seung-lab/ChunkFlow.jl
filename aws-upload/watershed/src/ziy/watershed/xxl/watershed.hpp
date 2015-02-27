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

#ifndef ZI_WATERSHED_XXL_WATERSHED_HPP
#define ZI_WATERSHED_XXL_WATERSHED_HPP 1

#include <zi/watershed/xxl/base.hpp>
#include <zi/watershed/xxl/chunk_dimensions.hpp>
#include <zi/watershed/quickie/quickie_impl.hpp>
#include <zi/watershed/detail/xxl_chunk.hpp>
#include <zi/watershed/detail/xxl_queue.hpp>

#include <zi/watershed/detail/mmap_file.hpp>
#include <zi/watershed/detail/mmap_vector.hpp>
#include <zi/watershed/detail/mmap_ostream.hpp>

#include <limits>
#include <algorithm>

namespace zi {
namespace watershed {

namespace xxl {

template< class T, class Id, class Count >
class watershed_impl:
        watershed_base< T, Id, Count, shared_ptr< detail::xxl_chunk< T, Id, Count > > >
{
public:
    typedef watershed_base< T, Id, Count, shared_ptr< detail::xxl_chunk< T, Id, Count > > > super_type;
    typedef watershed_impl< T, Id, Count > this_type;

    typedef detail::xxl_chunk< T, Id, Count > xxl_chunk_type;
    typedef shared_ptr< xxl_chunk_type >      chunk_type;

    typedef typename super_type::value_type value_type;
    typedef typename super_type::const_value_type const_value_type;
    typedef typename super_type::value_ptr value_ptr;
    typedef typename super_type::const_value_ptr const_value_ptr;

    typedef typename super_type::id_type id_type;
    typedef typename super_type::const_id_type const_id_type;
    typedef typename super_type::id_ptr id_ptr;
    typedef typename super_type::const_id_ptr const_id_ptr;

    typedef typename super_type::count_type count_type;
    typedef typename super_type::const_count_type const_count_type;

    typedef typename super_type::affinity_volume_ref affinity_volume_ref;
    typedef typename super_type::id_volume_ref id_volume_ref;

    typedef typename super_type::id_pair id_pair;
    typedef typename super_type::edge_type edge_type;
    typedef typename super_type::count_vector count_vector;

    typedef typename super_type::edge_vector edge_vector;
    typedef typename super_type::id_pair_vector id_pair_vector;
    typedef typename super_type::edge_map edge_map;

    typedef unordered_map< id_pair, value_type > edgemap_type;


protected:
    task_manager::simple task_manager_;
    task_manager::simple serial_task_manager_;

    std::vector< count_type > sizes_      ;
    disjoint_sets< id_type  > sets_       ;
    std::vector< value_type > merge_at_   ;
    std::vector< id_type    > reorder_    ;

    size_type num_ready_for_serial_start_ ;
    id_type   total_num_domains_          ;

    bool verbose_;

public:
    watershed_impl( const std::string& filename,
                    const value_type&  high_threshold,
                    const value_type&  low_threshold,
                    const count_type&  dust_threshold,
                    const value_type&  dust_merge_threshold,
                    size_type xsize,
                    size_type ysize,
                    size_type zsize,
                    const chunk_dimensions* cdims,
                    size_type num_threads = 2,
                    bool verbose = true )
        : super_type( filename, high_threshold, low_threshold, dust_threshold,
                      dust_merge_threshold, xsize, ysize, zsize ),
          task_manager_( num_threads ),
          serial_task_manager_( 1 ),
          sizes_(),
          sets_(),
          merge_at_(),
          reorder_(),
          num_ready_for_serial_start_(0),
          total_num_domains_(0),
          verbose_( verbose )
    {
        for ( size_type x = 0, idx = 0; x < super_type::xdim(); ++x )
            for ( size_type y = 0; y < super_type::ydim(); ++y )
                for ( size_type z = 0; z < super_type::zdim(); ++z, ++idx )
                {
                    int flags = 0;
                    flags |= x == 0 ? 0 : border::before_x;
                    flags |= y == 0 ? 0 : border::before_y;
                    flags |= z == 0 ? 0 : border::before_z;
                    flags |= x == super_type::xdim() - 1 ? 0 : border::after_x;
                    flags |= y == super_type::ydim() - 1 ? 0 : border::after_y;
                    flags |= z == super_type::zdim() - 1 ? 0 : border::after_z;

                    super_type::chunk( x, y, z ) = chunk_type
                        ( new xxl_chunk_type( x, y, z, flags,
                                              cdims[idx].x(),
                                              cdims[idx].y(),
                                              cdims[idx].z(),
                                              filename ));
                }
    }


    void initial_chunk_quickie( chunk_type c )
    {
        const_value_ptr affinities = c->load_affinities();
        id_ptr          ids        = c->allocate_chunk();

        mmap_vector< count_type >& counts     = c->counts();
        mmap_vector< edge_type  >& dendrogram = c->dendr();

        chunk_quickie_impl< T, Id, Count >
            ( c->xdim(), c->ydim(), c->zdim(),
              affinities,
              super_type::high_threshold(),
              super_type::low_threshold(),
              super_type::dust_threshold(),
              super_type::dust_merge_threshold(),
              c->flags(),
              ids,
              counts,
              dendrogram,
              bind( &xxl_chunk_type::free_affinities, c.get() ));

        c->flush_chunk( true );
        c->count( counts.size() );

        if ( verbose_ )
        {
            mutex::guard g( super_type::mutex_ );
            std::cout << "initial_chunk_quickie: " << (*c)
                      << " domains: " << counts.size()
                      << " dendr: " << dendrogram.size() << "\n";
        }

        //counts.flush();
        //dendrogram.flush();
    }

    void report_chunk_ready()
    {
        mutex::guard g( super_type::mutex_ );
        ++num_ready_for_serial_start_;

        if ( num_ready_for_serial_start_ == super_type::size() )
        {
            merge_at_.resize( total_num_domains_ );
            sets_.resize( total_num_domains_ );
            serial_task_manager_.start();

            if ( verbose_ )
            {
                std::cout << "serial manager starting...\n";
            }
        }
    }

    void get_chunk_sizes( chunk_type c )
    {
        mmap_vector< count_type >& counts = c->counts();
        id_type offset = c->offset();

        {
            mutex::guard g( super_type::mutex_ );
            sizes_[ 0 ] += counts[ 0 ];
        }

        for ( size_type i = 1; i < counts.size(); ++i )
        {
            sizes_[ i + offset ] = counts[ i ];
        }

        //counts.clear();
        report_chunk_ready();
    }

    void process_chunk_borders( chunk_type c )
    {
        const index x = c->xpos();
        const index y = c->ypos();
        const index z = c->zpos();
        const index dx[3] = { 1, 0, 0 };
        const index dy[3] = { 0, 1, 0 };
        const index dz[3] = { 0, 0, 1 };

        mmap_vector< edge_type >& false_minima = c->false_minima();
        edgemap_type              edges;
        unordered_set< id_pair >  same;

        std::vector< value_type > conn;
        std::vector< id_type >    a0, a1, b0, b1;

        for ( int i = 0; i < 3; ++i )
        {
            if ( c->pos( i ) > 0 )
            {
                chunk_type o = super_type::chunks_[x-dx[i]][y-dy[i]][z-dz[i]];

                c->get_border_affinities( i, conn );
                c->get_seg_faces( i, 1, b0, b1 );
                o->get_seg_faces( i, 0, a0, a1 );

                id_type aoff = o->offset();
                id_type boff = c->offset();

                ZI_ASSERT( a0.size() == a1.size() &&
                           b0.size() == b1.size() &&
                           a1.size() == b0.size() );

                for ( size_type idx = 0; idx < a0.size(); ++idx )
                {
                    if ( a0[idx] && b1[idx] )
                    {
                        if ( a1[idx] && b0[idx] )
                        {
                            false_minima.push_back( edge_type( aoff+a1[idx],
                                                               boff+b0[idx],
                                                               conn[idx] ));
                        }
                        else if ( a1[idx] )
                        {
                            same.insert( std::make_pair( aoff+a1[idx], boff+b1[idx] ));
                        }
                        else if ( b0[idx] )
                        {
                            same.insert( std::make_pair( aoff+a0[idx], boff+b0[idx] ));
                        }
                        else
                        {
                            id_pair x( aoff+a0[idx], boff+b1[idx] );
                            typename edgemap_type::iterator it = edges.find( x );
                            if ( it == edges.end() )
                            {
                                edges.insert( std::make_pair( x, conn[ idx ] ));
                            }
                            else if ( it->second < conn[ idx ] )
                            {
                                it->second = conn[ idx ];
                            }
                        }
                    }

                    ZI_ASSERT( !a1[idx] || a0[idx] );
                    ZI_ASSERT( !b0[idx] || b1[idx] );
                }
            }
        }

        mmap_vector< edge_type >& more_dendr = c->more_dendr();
        more_dendr.resize( edges.size() );

        size_type idx = 0;
        FOR_EACH( it, edges )
        {
            more_dendr[ idx++ ] = tie( it->first.first, it->first.second, it->second );
        }

        zi::sort( more_dendr.begin(), more_dendr.end(), edge_compare< T, id_type > );
        //more_dendr.flush();

        mmap_vector< id_pair >& merge_pairs = c->merge_pairs();
        merge_pairs.resize( same.size() );
        std::copy( same.begin(), same.end(), merge_pairs.begin() );
        //merge_pairs.flush();

        //false_minima.flush();

        // we can add stuff to the serial manager
        serial_task_manager_.push_back( bind( &this_type::merge_chunk_borders, this, c ) );

        if ( verbose_ )
        {
            mutex::guard g( super_type::mutex_ );
            std::cout << "processed_chunk_borders: " << (*c)
                      << " false_min: " << false_minima.stored_size()
                      << " more_dend: " << more_dendr.stored_size()
                      << " same_pairs: " << merge_pairs.stored_size() << "\n";
        }

    }


    void merge_chunk_borders( chunk_type c )
    {
        mmap_vector< edge_type >& fmin = c->false_minima();

        FOR_EACH( it, fmin )
        {
            const id_type v1 = sets_.find_set( zi::get< 0 >( *it ) );
            const id_type v2 = sets_.find_set( zi::get< 1 >( *it ) );

            ZI_ASSERT( v1 && v2 );

            if ( v1 != v2 )
            {
                const id_type vr = sets_.join( v1, v2 );
                sizes_[ v1 ] += sizes_[ v2 ];
                sizes_[ v2 ]  = 0;

                merge_at_[ v1 ] = std::max
                    ( zi::get< 2 >( *it ), std::max( merge_at_[ v1 ], merge_at_[ v2 ] ));
                merge_at_[ v2 ] = 0;

                std::swap( sizes_[ vr ],    sizes_[ v1 ]    );
                std::swap( merge_at_[ vr ], merge_at_[ v1 ] );
            }
            else
            {
                merge_at_[ v1 ] = std::max( merge_at_[ v1 ], zi::get< 2 >( *it ) );

            }
        }

        fmin.clear();

        mmap_vector< id_pair >& pairs = c->merge_pairs();

        FOR_EACH( it, pairs )
        {
            const id_type v1 = sets_.find_set( zi::get< 0 >( *it ) );
            const id_type v2 = sets_.find_set( zi::get< 1 >( *it ) );

            ZI_ASSERT( v1 && v2 );

            if ( v1 != v2 )
            {
                const id_type vr = sets_.join( v1, v2 );
                sizes_[ v1 ] += sizes_[ v2 ];
                sizes_[ v2 ]  = 0;
                std::swap( sizes_[ vr ], sizes_[ v1 ] );

                merge_at_[vr] = std::max( merge_at_[v1], merge_at_[v2] );
            }
        }

        pairs.clear();
    }

    //void ( chunk_type c )


    void update_chunk_data( chunk_type c )
    {
        id_type off = c->offset();

        // rename the domains in the stored dendrogram(s)

        mmap_vector< edge_type >& dendr = c->dendr();
        size_type idx = 0;

        for ( size_type i = 0; i < dendr.size(); ++i )
        {
            id_type a1 = reorder_[ zi::get< 0 >( dendr[ i ] ) + off ];
            id_type a2 = reorder_[ zi::get< 1 >( dendr[ i ] ) + off ];

            if ( a1 && a2 && a1 != a2 )
            {
                dendr[ idx++ ] = tie( a1, a2, zi::get< 2 >( dendr[ i ] ));
            }
        }
        dendr.resize( idx );

        mmap_vector< edge_type >& more_dendr = c->more_dendr();

        FOR_EACH( it, more_dendr )
        {
            id_type a1 = reorder_[ zi::get< 0 >( *it ) ];
            id_type a2 = reorder_[ zi::get< 1 >( *it ) ];

            if ( a1 && a2 && a1 != a2 )
            {
                dendr.push_back( tie( a1, a2, zi::get< 2 >( *it ) ));
            }
        }

        zi::sort( dendr.begin(), dendr.end(), edge_compare< T, id_type > );
        //dendr.flush();
        //more_dendr.clear();

        c->load_chunk();
        id_ptr seg = c->get()->data();

        const size_type chunk_size = c->get()->size();

        for ( size_type i = 0; i < chunk_size; ++i )
        {
            if ( seg[ i ] )
            {
                seg[ i ] = reorder_[ seg[ i ] + off ];
            }
        }

        c->flush_chunk();

        if ( verbose_ )
        {
            mutex::guard g( super_type::mutex_ );
            std::cout << "flush_chunk: " << (*c) << "\n";
        }
    }

    void operator()( bool verbose = true )
    {
        verbose_ = verbose;

        task_manager_.start();

        // do quickie on all the chunks
        for ( size_type i = 0; i < super_type::size(); ++i )
        {
            task_manager_.push_back( bind( &this_type::initial_chunk_quickie,
                                           this, super_type::chunks_.at( i ) ));
        }

        task_manager_.join();

        for ( size_type i = 0; i < super_type::size(); ++i )
        {
            super_type::chunks_.at( i )->offset( total_num_domains_ );
            total_num_domains_ += super_type::chunks_.at( i )->count() - 1;
        }

        ++total_num_domains_; // count zero (empty) as domain
        sizes_.resize( total_num_domains_ );

        task_manager_.start();

        for ( size_type i = 0; i < super_type::size(); ++i )
        {
            task_manager_.push_back( bind( &this_type::get_chunk_sizes,
                                           this, super_type::chunks_.at( i ) ));
        }

        for ( size_type i = 0; i < super_type::size(); ++i )
        {
            task_manager_.push_back( bind( &this_type::process_chunk_borders,
                                           this, super_type::chunks_.at( i ) ));
        }

        task_manager_.join();

        // the serial task manager should be started already,
        // we have to wait for it too

        serial_task_manager_.join();

        // modify the merge_at vector, so that we have to merge
        // exactly when the edge is smaller than the merge_at value

        for( size_type i = 0; i < merge_at_.size(); ++i )
        {
            if ( merge_at_[ i ] == 0 )
            {
                merge_at_[ i ] = std::numeric_limits< value_type >::max();
            }
        }

        // now we have to apply the size threshold, and perform the
        // merges that we have to do because of the chunking

        detail::xxl_queue< edge_type, edge_less< value_type, id_type > > queue;

        for ( size_type i = 0; i < super_type::size(); ++i )
        {
            chunk_type c = super_type::chunks_.at( i );
            queue.add_source( c->dendr().filename(), c->dendr().stored_size(), c->offset() );
            queue.add_source( c->more_dendr().filename(), c->more_dendr().stored_size(), 0 );
        }

        const value_type min_threshold  = super_type::dust_merge_threshold();
        const count_type dust_threshold = super_type::dust_threshold();

        while ( !queue.empty() )
        {
            const id_type off = queue.top_key();
            const id_type v1  = sets_.find_set( zi::get< 0 >( queue.top() ) + off );
            const id_type v2  = sets_.find_set( zi::get< 1 >( queue.top() ) + off );

            ZI_ASSERT( v1 && v2 );

            if ( v1 != v2 )
            {
                const value_type& val = zi::get< 2 >( queue.top() );

                if ( merge_at_[ v1 ] <= val || merge_at_[ v2 ] <= val ||
                     ( val >= min_threshold &&
                       ( sizes_[ v1 ] < dust_threshold ||
                         sizes_[ v2 ] < dust_threshold ) ))
                {
                    const id_type vr = sets_.join( v1, v2 );
                    sizes_[ v1 ] += sizes_[ v2 ];
                    sizes_[ v2 ]  = 0;
                    std::swap( sizes_[ vr ], sizes_[ v1 ] );
                    merge_at_[ vr ] = std::max( merge_at_[ v1 ], merge_at_[ v2 ] );
                }
            }

            queue.pop();
        }

        queue.clear();

        // renumber the domains, to save some space before the final processing
        // we don't need the merge_at_ vector

        merge_at_.clear();
        reorder_.resize( total_num_domains_ );

        id_type new_index = 1;
        for ( id_type i = 1; i < total_num_domains_; ++i )
        {
            if ( sizes_[ i ] )
            {
                if ( sizes_[ i ] >= dust_threshold )
                {
                    sizes_[ new_index ] = sizes_[ i ];
                    reorder_[ i ] = new_index;
                    ++new_index;
                }
                else
                {
                    sizes_[ 0 ] += sizes_[ i ];
                    sizes_[ i ]  = reorder_[ i ] = 0;
                }
            }
        }

        for ( id_type i = 1; i < total_num_domains_; ++i )
        {
            if ( !reorder_[ i ] )
            {
                reorder_[ i ] = reorder_[ sets_.find_set( i ) ];
            }
        }

        sets_.resize( new_index );
        sizes_.resize( new_index );

        mmap_file::write_n( super_type::filename() + ".sizes", sizes_.begin(), new_index );

        // we know the total number of domains now!

        if ( verbose_ )
        {
            std::cout << "total number of domains: " << new_index << std::endl;
        }

        task_manager_.start();

        for ( size_type i = 0; i < super_type::size(); ++i )
        {
            task_manager_.push_back( bind( &this_type::update_chunk_data,
                                           this, super_type::chunks_.at( i ) ));
        }

        task_manager_.join();

        std::fill( sizes_.begin(), sizes_.end(), 0 );

        for ( size_type i = 0; i < super_type::size(); ++i )
        {
            chunk_type c = super_type::chunks_.at( i );
            queue.add_source( c->dendr().filename(), c->dendr().stored_size() );
        }

        value_type low_threshold = super_type::low_threshold();

        // store the round for the topological sort
        id_type round = 0;

        id_pair_vector dend_pairs;
        detail::mmap_ostream< value_type > dend_vals_out( super_type::filename() + ".dend_values" );

        while ( !queue.empty() )
        {
            if ( zi::get< 2 >( queue.top() ) < low_threshold )
            {
                break;
            }

            const id_type a1  = zi::get< 0 >( queue.top() );
            const id_type a2  = zi::get< 1 >( queue.top() );

            ZI_ASSERT( a1 && a2 );

            const id_type v1  = sets_.find_set( a1 );
            const id_type v2  = sets_.find_set( a2 );

            ZI_ASSERT( v1 && v2 );

            if ( v1 != v2 )
            {
                dend_vals_out << zi::get< 2 >( queue.top() );
                dend_pairs.push_back( std::make_pair( a1, a2 ) );
                sizes_[ a1 ] = sizes_[ a2 ] = ++round;
                sets_.join( v1, v2 );
            }
            queue.pop();
        }

        queue.clear();


        detail::mmap_ostream< id_type > dend_pairs_out( super_type::filename() + ".dend_pairs" );

        sets_.clear();


        FOR_EACH( it, dend_pairs )
        {

            const id_type v1  = sets_.find_set( it->first );
            const id_type v2  = sets_.find_set( it->first );

            if ( sizes_[ v1 ] > sizes_[ v2 ] )
            {
                dend_pairs_out << it->second;
                dend_pairs_out << it->first;
            }
            else
            {
                dend_pairs_out << it->first;
                dend_pairs_out << it->second;
            }

            sizes_[ sets_.join( v1, v2 ) ] = std::max( sizes_[ v1 ], sizes_[ v2 ] );
        }

        if ( verbose_ )
        {
            std::cout << "total dendrogram size: " << dend_pairs.size() << "\n";
        }


    }


};


} // namespace xxl

} // namespace watershed
} // namespace zi

#endif


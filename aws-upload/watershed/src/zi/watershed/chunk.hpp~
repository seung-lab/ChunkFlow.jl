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

#ifndef ZI_WATERSHED_CHUNK_HPP
#define ZI_WATERSHED_CHUNK_HPP 1

#include <zi/utility/non_copyable.hpp>
#include <zi/bits/shared_ptr.hpp>
#include <cstddef>
#include <cstdlib>
#include <string>
#include <algorithm>
#include <vector>

namespace zi {
namespace watershed {

template< class T >
class chunk: non_copyable
{
private:
    mutable T           *data_ ;

    const std::size_t    x_    ;
    const std::size_t    y_    ;
    const std::size_t    z_    ;
    const std::size_t    size_ ;

    std::size_t         *yoffs_;
    std::size_t         *zoffs_;
    bool                 zero_fill_;

public:
    chunk( std::size_t x, std::size_t y, std::size_t z, bool zero_fill = true )
        : data_( 0 ),
          x_( x ),
          y_( y ),
          z_( z ),
          size_( x * y * z ),
          yoffs_( 0 ),
          zoffs_( 0 ),
          zero_fill_( zero_fill )
    {
        allocate();

        yoffs_ = reinterpret_cast< std::size_t* >( malloc( y * sizeof( std::size_t ) ));

        yoffs_[ 0 ] = 0;
        for ( std::size_t i = 1; i < y; ++i )
        {
            yoffs_[ i ] = yoffs_[ i - 1 ] + x;
        }

        std::size_t xy = x * y;
        zoffs_ = reinterpret_cast< std::size_t* >( malloc( z * sizeof( std::size_t ) ));

        zoffs_[ 0 ] = 0;
        for ( std::size_t i = 1; i < z; ++i )
        {
            zoffs_[ i ] = zoffs_[ i - 1 ] + xy;
        }

    }

    void allocate() const
    {
        if ( !data_ )
        {
            data_  = reinterpret_cast< T* >( malloc( static_cast< std::size_t >( x_ ) * y_ * z_ * sizeof( T ) ));
            if ( data_ && zero_fill_ )
            {
                std::fill_n( data_, size_, 0 );
            }
        }
    }

    ~chunk()
    {
        if ( data_ )
        {
            free( data_ );
        }

        if ( yoffs_ )
        {
            free( yoffs_ );
        }

        if ( zoffs_ )
        {
            free( zoffs_ );
        }
    }

    void deallocate() const
    {
        if ( data_ )
        {
            free( data_ );
            data_ = 0;
        }
    }

    T* data( bool alloc_if_not_there = false ) const
    {
        if ( alloc_if_not_there )
        {
            allocate();
        }
        return data_;
    }

    std::size_t x() const
    {
        return x_;
    }

    std::size_t y() const
    {
        return y_;
    }

    std::size_t z() const
    {
        return z_;
    }

    std::size_t size() const
    {
        return size_;
    }

    const T& at( std::size_t i, std::size_t j, std::size_t k ) const
    {
        return data_[ i + yoffs_[ j ] + zoffs_[ k ] ];
    }

    T& at( std::size_t i, std::size_t j, std::size_t k )
    {
        return data_[ i + yoffs_[ j ] + zoffs_[ k ] ];
    }

    const T& operator()( std::size_t i, std::size_t j, std::size_t k ) const
    {
        return data_[ i + yoffs_[ j ] + zoffs_[ k ] ];
    }

    T& operator()( std::size_t i, std::size_t j, std::size_t k )
    {
        return data_[ i + yoffs_[ j ] + zoffs_[ k ] ];
    }

    std::size_t xslice( std::size_t n, std::vector< T >& out ) const
    {
        out.resize( y_ * z_ );
        for ( std::size_t i = 0, z = 0; z < z_; ++z )
        {
            for ( std::size_t y = 0; y < y_; ++y, ++i )
            {
                out[ i ] = at( n, y, z );
            }
        }
        return out.size();
    }

    std::size_t yslice( std::size_t n, std::vector< T >& out ) const
    {
        out.resize( x_ * z_ );
        for ( std::size_t i = 0, z = 0; z < z_; ++z )
        {
            for ( std::size_t x = 0; x < x_; ++x, ++i )
            {
                out[ i ] = at( x, n, z );
            }
        }
        return out.size();
    }

    std::size_t zslice( std::size_t n, std::vector< T >& out ) const
    {
        out.resize( x_ * y_ );
        for ( std::size_t i = 0, y = 0; y < y_; ++y )
        {
            for ( std::size_t x = 0; x < x_; ++x, ++i )
            {
                out[ i ] = at( x, y, n );
            }
        }
        return out.size();
    }

    void fill_xslice( std::size_t n, const T& v )
    {
        for ( std::size_t i = 0, z = 0; z < z_; ++z )
        {
            for ( std::size_t y = 0; y < y_; ++y, ++i )
            {
                at( n, y, z ) = v;
            }
        }
    }

    void fill_yslice( std::size_t n, const T& v )
    {
        for ( std::size_t i = 0, z = 0; z < z_; ++z )
        {
            for ( std::size_t x = 0; x < x_; ++x, ++i )
            {
                at( x, n, z ) = v;
            }
        }
    }

    void fill_zslice( std::size_t n, const T& v )
    {
        for ( std::size_t i = 0, y = 0; y < y_; ++y )
        {
            for ( std::size_t x = 0; x < x_; ++x, ++i )
            {
                at( x, y, n ) = v;
            }
        }
    }

    void fill( const T& v = 0 )
    {
        std::fill_n( data_, size_, v );
    }

};


} // namespace watershed
} // namespace zi

#endif


#include <cstddef>
#include <utility>
#include <algorithm>
#include <vector>

template< class T >
void make_unique( T* volout, const T* volume, std::size_t volume_size,
                  T* paiout, const T* pairs,  std::size_t pairs_size )
{
  T max = static_cast<T>(0);
  for ( std::size_t i = 0; i < volume_size; ++i )
    {
      max = std::max( max, volume[i] );
    }

  std::vector<T> maps(max+1);
  T curr = 0;

  for ( std::size_t i = 0; i < volume_size; ++i )
    {
      const T& v = volume[i];
      if ( v )
	{
	  if ( maps[static_cast<std::size_t>(v)] )
	    {
	      volout[i] = maps[static_cast<std::size_t>(v)];
	    }
	  else
	    {
	      volout[i] = ++curr;
	      maps[static_cast<std::size_t>(v)] = curr;
	    }
	}
      else
	{
	  volout[i] = static_cast<T>(0);
	}
    }

  for ( std::size_t i = 0; i < pairs_size; ++i )
    {
      paiout[i] = maps[static_cast<std::size_t>(pairs[i])];
    }
}

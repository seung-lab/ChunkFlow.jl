#include <cstddef>
#include <utility>
#include <algorithm>
#include <vector>
#include <mex.h>

template< class T >
void make_unique( T* volume, std::size_t volume_size,
                  T* pairs,  std::size_t pairs_size )
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
      if ( maps[static_cast<std::size_t>(v)] )
        {
	  volume[i] = maps[static_cast<std::size_t>(v)];
        }
      else
        {
	  volume[i] = ++curr;
	  maps[static_cast<std::size_t>(v)] = curr;
        }
    }

  for ( std::size_t i = 0; i < pairs_size; ++i )
    {
      pairs[i] = maps[static_cast<std::size_t>(pairs[i])];
    }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[])
{
  const std::size_t volume_size = static_cast<std::size_t>(mxGetNumberOfElements(prhs[0]));
  int* volume = const_cast<int*>(static_cast<const int*>(mxGetData(prhs[0])));
  const std::size_t pairs_size = static_cast<std::size_t>(mxGetNumberOfElements(prhs[1]));
  int* pairs = const_cast<int*>(static_cast<const int*>(mxGetData(prhs[1])));
  make_unique<int>(volume, volume_size, pairs, pairs_size);
}

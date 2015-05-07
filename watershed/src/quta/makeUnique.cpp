#include <cstddef>
#include <utility>
#include <algorithm>
#include <vector>
#include <mex.h>

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

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if ( nlhs < 2 ) 
    {
      return;
    }

  const std::size_t volume_size = static_cast<std::size_t>(mxGetNumberOfElements(prhs[0]));
  const int* volume = static_cast<const int*>(mxGetData(prhs[0]));

  plhs[0] = mxCreateNumericArray(mxGetNumberOfDimensions(prhs[0]),
				 mxGetDimensions(prhs[0]),
				 mxINT32_CLASS,
				 mxREAL);
				 
  int* volout = static_cast<int*>(mxGetData(plhs[0]));

  const std::size_t pairs_size = static_cast<std::size_t>(mxGetNumberOfElements(prhs[1]));
  const int* pairs = static_cast<const int*>(mxGetData(prhs[1]));

  plhs[1] = mxCreateNumericArray(mxGetNumberOfDimensions(prhs[1]),
				 mxGetDimensions(prhs[1]),
				 mxINT32_CLASS,
				 mxREAL);
				 
  int* paiout = static_cast<int*>(mxGetData(plhs[1]));
  

  make_unique<int>(volout, volume, volume_size, paiout, pairs, pairs_size);
}
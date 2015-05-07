#include <mex.h>

#include <boost/multi_array.hpp>
#include <boost/multi_array/types.hpp>
#include <zi/utility/assert.hpp>
#include <zi/bits/unordered_set.hpp>

#include <cstddef>
#include <vector>
#include <algorithm>

template< typename T, std::size_t N >
boost::multi_array_ref<T,N> get_matlab_array( mxArray* arr )
{
    ZI_ASSERT( mxGetNumberOfDimensions(arr) == N );

    std::vector<std::size_t> dims(N);
    const mwSize* mexd = mxGetDimensions(arr);
    std::copy( mexd, mexd+N, dims.begin() );

    return boost::multi_array_ref<T,N>( reinterpret_cast<T*>(mxGetData(arr)),
                                        dims,
                                        boost::fortran_storage_order() );

}

template< typename T, std::size_t N >
boost::const_multi_array_ref<T,N> get_matlab_const_array( mxArray* arr )
{
    ZI_ASSERT( mxGetNumberOfDimensions(arr) == N );

    std::vector<std::size_t> dims(N);
    const mwSize* mexd = mxGetDimensions(arr);
    std::copy( mexd, mexd+N, dims.begin() );

    return boost::const_multi_array_ref<T,N>( reinterpret_cast<T*>(mxGetData(arr)),
                                              dims,
                                              boost::fortran_storage_order() );
}

void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, mxArray *prhs[] )

{
    boost::const_multi_array_ref<int,3>   seg = get_matlab_const_array<float,3>(prhs[0]);
    boost::const_multi_array_ref<float,4> aff = get_matlab_const_array<float,4>(prhs[1]);


    zi::unordered_set<int> inside;



}

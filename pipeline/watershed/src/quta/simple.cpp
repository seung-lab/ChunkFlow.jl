#include <mex.h>
#include <iostream>

int mexFunction(int nplhs, mxArray *plhs[], int nprhs, mxArray *prhs[])
{
  std::cout << mxGetNumberOfElements(prhs[0]) << "\n";
}

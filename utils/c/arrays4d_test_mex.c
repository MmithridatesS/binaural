/***********************************************************************
 * % function that tests MEX memory allocation for a 4-D array
 * % (stand-alone function)
 * % ----------------------------------------------------------------------
 * % Author:       Lars Häring
 * %
 * % ----------------------------------------------------------------------
 * % Last update:  14.11.02
 * %
 * % **********************************************************************
 * % input parameters:
 * % =================
 * % array_in      4D input array
 * % dim1          length of first dimension
 * % dim2          length of second dimension
 * % dim3          length of third dimension
 * % dim4          length of fourth dimension
 * % ----------------------------------------------------------------------
 * % output parameters:
 * % ==================
 * % array_out     4D output array
 * % --------------------------------------------------------------------*/

#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include "mex.h"
#include "arrays.c"

void arrays4d_test_mex(double ****array_out, double ****array_in, int dim1,
        int dim2, int dim3, int dim4)
{
  int i,ii,iii,iiii;
  
  for (iiii=0;iiii<dim4;iiii++) {
    for(iii=0;iii<dim3;iii++) {
      for(ii=0;ii<dim2;ii++) {
        for(i=0;i<dim1;i++) {
          //printf("%d %d %d %d %f\n",iiii,iii,ii,i,array_in[iiii][iii][ii][i]);
          //printf("%f ",array_in[2][3][0][0]);
          array_out[iiii][iii][ii][i] = 2*array_in[iiii][iii][ii][i];
        }
      }
    }
  }
}

void mexFunction(int nlhs,mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int i;
  
  const int *dims;
  int ndim;
  
  /* Output matrices */
  double ****array_out;
  /* Input parameters */
  double ****array_in;
  
  /* Output matrices */
  ndim = mxGetNumberOfDimensions(prhs[0]);
  printf("Number of dimensions %d\n",ndim);
  dims = mxGetDimensions(prhs[0]);
  printf("Dimension 1: %d ",dims[0]);
  printf("Dimension 2: %d ",dims[1]);
  printf("Dimension 3: %d ",dims[2]);
  printf("Dimension 4: %d\n",dims[3]);
  
  /* Check for proper number of arguments. */
  if(nrhs != 1) {
    mexErrMsgTxt("One input required.");
  } else if(nlhs > 1) {
    mexErrMsgTxt("Too many output arguments");
  }
  
  /* Allocate memory for arrays - first step */
  array_in =  array4_1(dims[3],dims[2],dims[1],dims[0]);
  array_out = array4_1(dims[3],dims[2],dims[1],dims[0]);
  
  
  /* Get pointers to the inputs. */
  array_in[0][0][0] =   mxGetPr(prhs[0]);
  
  /* Create new arrays and set the output pointers to them. */
  plhs[0] =       mxCreateNumericArray(ndim, dims, mxDOUBLE_CLASS, mxREAL);
  array_out[0][0][0] =  mxGetPr(plhs[0]);
  
  /* For vector -> matrix-notation second step necessary */
  array_in =  array4_2(array_in,dims[3],dims[2],dims[1],dims[0]);
  array_out = array4_2(array_out,dims[3],dims[2],dims[1],dims[0]);
  
  /* Call C-function */
  arrays4d_test_mex(array_out,array_in,dims[0],dims[1],dims[2],dims[3]);
}


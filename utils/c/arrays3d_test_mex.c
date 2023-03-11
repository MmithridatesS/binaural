/***********************************************************************
% function that tests MEX memory allocation for a 3-D array
% (stand-alone function)
% ----------------------------------------------------------------------
% Author:       Lars Häring
% 
% ----------------------------------------------------------------------
% Last update:  14.11.02
%
% **********************************************************************
% input parameters:
% =================
% array_in      3D input array
% dim1          length of first dimension
% dim2          length of second dimension
% dim3          length of third dimension
% ----------------------------------------------------------------------
% output parameters:
% ==================
% array_out     3D output array
% --------------------------------------------------------------------*/

#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include "mex.h"
#include "utils.c"
#include "arrays.c"

void arrays3d_test_mex(double ***array_out, double ***array_in, int dim1,
    int dim2, int dim3)
{
    int i,ii,iii;
    
    for (i=0;i<dim1;i++) {
        for(ii=0;ii<dim2;ii++) {
            for(iii=0;iii<dim3;iii++) {
                array_out[iii][ii][i] = array_in[iii][ii][i];
            }
        }
    }
}

void mexFunction(int nlhs,mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    int i;
 
    const int  *dims;
    int ndim;
    
	/* Output matrices */
	double ***array_out;
	/* Input parameters */
	double ***array_in;
	
	/* Output matrices */
    ndim = mxGetNumberOfDimensions(prhs[0]); printf("Number of dimensions %d\n",ndim);
    dims = mxGetDimensions(prhs[0]);
	printf("Dimension 1: %d ",dims[0]);
	printf("Dimension 2: %d ",dims[1]);
	printf("Dimension 3: %d ",dims[2]);
 	
    /* Check for proper number of arguments. */
    if(nrhs != 1) {
         mexErrMsgTxt("One input required.");
    } else if(nlhs > 1) {
         mexErrMsgTxt("Too many output arguments");
    }

    /* Allocate memory for arrays - first step */    
    array_in =  array3_1(dims[2],dims[1],dims[0]);    
    array_out = array3_1(dims[2],dims[1],dims[0]);
    
    /* Get pointers to the inputs. */
 	array_in[0][0] =   mxGetPr(prhs[0]);

    /* Create two new arrays and set the output pointers to them. */
    plhs[0] =       mxCreateNumericArray(ndim, dims, mxDOUBLE_CLASS, mxREAL);
	array_out[0][0] =  mxGetPr(plhs[0]);
	
	/* For vector -> matrix-notation second step necessary */
	array_in =  array3_2(array_in,dims[2],dims[1],dims[0]);
	array_out = array3_2(array_out,dims[2],dims[1],dims[0]);
	 
    /* Call C-function */
	arrays3d_test_mex(array_out,array_in,dims[0],dims[1],dims[2]);	
}


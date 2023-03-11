/***********************************************************************
% function that tests MEX memory allocation for a 2-D array
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
% array_in      2D input array
% dim1          length of first dimension
% dim2          length of second dimension
% ----------------------------------------------------------------------
% output parameters:
% ==================
% array_out     2D output array
% --------------------------------------------------------------------*/

#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include "mex.h"
#include "utils.c"
#include "arrays.c"

void arrays_test_mex(double **array_out, double **array_in, int dim1, int dim2)
{
    int i,ii;
    
    for (i=0;i<dim1;i++) {
        for(ii=0;ii<dim2;ii++) {
            array_out[ii][i] = array_in[ii][i];
        }
    }
}

void mexFunction(int nlhs,mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    int i;
 
    int dim1,dim2;
    
	/* Output matrices */
	double **array_out;
	/* Input parameters */
	double **array_in;
	
	/* Output matrices */

	dim1 = mxGetM(prhs[0]);
	dim2 = mxGetN(prhs[0]);
	
    /* Check for proper number of arguments. */
    if(nrhs != 1) {
         mexErrMsgTxt("Six inputs required.");
    } else if(nlhs > 1) {
         mexErrMsgTxt("Too many output arguments");
    }

    /* Allocate memory for arrays - first step */    
    array_in =  array2_1(dim2,dim1);    
    array_out = array2_1(dim2,dim1);
    
    
    /* Get pointers to the inputs. */
 	array_in[0] =   mxGetPr(prhs[0]);

    /* Create two new arrays and set the output pointers to them. */
	plhs[0] =       mxCreateDoubleMatrix(dim1,dim2,mxREAL);
	array_out[0] =  mxGetPr(plhs[0]);
	
	/* For vector -> matrix-notation second step necessary */
	array_in =  array2_2(array_in,dim2,dim1);
	array_out = array2_2(array_out,dim2,dim1);
	 
    /* Call C-function */
	arrays_test_mex(array_out,array_in,dim1,dim2);				 
}


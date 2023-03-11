// Headers: --------------------------------------------------------------------
#include "mex.h"
#include <stdlib.h>
#include <float.h>
#include <string.h>
#include <math.h>

// Definitions: ----------------------------------------------------------------
// Assume 32 bit addressing for Matlab 6.5:
// See MEX option "compatibleArrayDims" for MEX in Matlab >= 7.7.
#ifndef MWSIZE_MAX
#define mwSize  int32_T               // Defined in tmwtypes.h
#define mwIndex int32_T
#define MWSIZE_MAX MAX_int32_T
#endif

// Limit number of dimensions of the input - this saves 2% computing time if
// the signal is tiny (e.g. [16 x 1]):
#define MAX_NDIMS 32

// Disable the /fp:precise flag to increase the speed on MSVC compiler:
#ifdef _MSC_VER
#pragma float_control(except, off)    // disable exception semantics
#pragma float_control(precise, off)   // disable precise semantics
#pragma fp_contract(on)               // enable contractions
// #pragma fenv_access(off)           // disable fpu environment sensitivity
#endif

// Error messages do not contain the function name in Matlab 6.5! This is not
// necessary in Matlab 7, but it does not bother:
#define ERR_HEAD "*** FilterRealizer[mex]: "
#define ERR_ID   "LHaering:FilterRealizer:"

// Some macros to reduce the confusion:
#define H_in   prhs[0]
#define X_in   prhs[1]
#define Z_in   prhs[2]
#define A_in   prhs[3]
#define Y_out  plhs[0]
#define Z_out  plhs[1]

// Prototypes: -----------------------------------------------------------------
void CoreFilterSingle(double *Y, double *H, double *X, double *Z, double *A,
        mwSize iFiltLen, mwSize iNoTx, mwSize iSigLen, int iCRx, int iCTx);
void CoreFilter(double *Y, double *H, double *X, double *Z, double *A,
        mwSize iFiltLen, mwSize iNoTx, mwSize iSigLen);

// Main function ===============================================================
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  double *Y;
  mwSize iOrder, iFiltLen, iSigLen, iNoTx;
  mwSize Ydims[3];
  int iCTx, iCRx;
  int i;
  
  size_t Hndims         = mxGetNumberOfDimensions(H_in);
  const mwSize *Hdims   = mxGetDimensions(H_in);
  size_t Hnelem         = mxGetNumberOfElements(H_in);
  double *H             = mxGetPr(H_in);
  iFiltLen              = Hdims[0];
  iNoTx                 = Hdims[2];
//   printf("Filter length: %d \n",iFiltLen);
//   printf("Number of Tx sources: %d \n",iNoTx);
//   for (i=0; i<Hnelem; i++) printf("H: %d: %f \n",i,H[i]);
  
  size_t Xndims         = mxGetNumberOfDimensions(X_in);
  const mwSize *Xdims   = mxGetDimensions(X_in);
  size_t Xnelem         = mxGetNumberOfElements(X_in);
  double *X             = mxGetPr(X_in);
  iSigLen               = Xdims[0];
//   printf("Signal length: %d \n",iSigLen);
//   for (i=0; i<Xnelem; i++) printf("X: %d: %f \n",i,X[i]);
  
  size_t Zndims         = mxGetNumberOfDimensions(Z_in);
  const mwSize *Zdims   = mxGetDimensions(Z_in);
  size_t Znelem         = mxGetNumberOfElements(Z_in);
  double *Z             = mxGetPr(Z_in);
  iOrder                = Zdims[0];
//   printf("State length: %d \n",iOrder);
//   for (i=0; i<Znelem; i++) printf("Z: %d: %f \n",i,Z[i]);
  
  size_t Andims         = mxGetNumberOfDimensions(A_in);
  const mwSize *Adims   = mxGetDimensions(A_in);
  size_t Anelem         = mxGetNumberOfElements(A_in);
  double *A             = mxGetPr(A_in);
  
  // Check number of inputs and outputs:
  if (nrhs != 4) {
    mexErrMsgIdAndTxt(ERR_ID   "BadNInput",
            ERR_HEAD "4 inputs required.");
  }
  if (nlhs > 2) {
    mexErrMsgIdAndTxt(ERR_ID   "BadNOutput",
            ERR_HEAD "2 outputs allowed.");
  }
  if (iOrder != iFiltLen-1) {
    mexErrMsgTxt("Number of states not equal to (filter length-1).");
  }
  if (iSigLen != Adims[1]) {
    printf("Number of angles: %d\n",Adims[1]);
    printf("Signal length:    %d\n",iSigLen);
    mexErrMsgTxt("Number of angles not equal to input signal length.");
  }
  // Create the state array:
  Z_out = mxDuplicateArray(Z_in);
  Z     = mxGetPr(Z_out);
//    for (i=0; i<Znelem; i++) printf("Z: %d: %f \n",i,Z[i]);
  
  // Create the output array:
  Ydims[0] = iSigLen;
  Ydims[1] = 2;
  Ydims[2] = iNoTx;
  Y_out = mxCreateNumericArray(3, Ydims, mxDOUBLE_CLASS, mxREAL);
  Y     = mxGetPr(Y_out);
  
//   for(iCRx=0; iCRx<2; iCRx++){
//     for(iCTx=0; iCTx<iNoTx; iCTx++){
//       CoreFilterSingle(Y,H,X,Z,A,iFiltLen,iNoTx,iSigLen,iCRx,iCTx);
//     }
//   }
  CoreFilter(Y,H,X,Z,A,iFiltLen,iNoTx,iSigLen);
}


void CoreFilter(double *Y, double *H, double *X, double *Z, double *A,
        mwSize iFiltLen, mwSize iNoTx, mwSize iSigLen)
{
  double Xm, Ym;
  int m, n, iOffset, i, iCRx, iCTx;
  int iOffsetY, iOffsetX, iOffsetH, iOffsetZ;
  
  for(iCRx=0; iCRx<2; iCRx++){
    for(iCTx=0; iCTx<iNoTx; iCTx++){
      iOffsetY = iSigLen*iCRx+iSigLen*2*iCTx;
      iOffsetX = iSigLen*iCTx;
      iOffsetH = iFiltLen*iCRx+iFiltLen*2*iCTx;
      iOffsetZ = (iFiltLen-1)*iCRx+(iFiltLen-1)*2*iCTx;
      
      for (m=0; m<iSigLen; m++) {
        iOffset = iOffsetH+iFiltLen*2*iNoTx*A[m];
        Xm      = X[m+iOffsetX];
        Ym      = H[0+iOffset]*Xm+Z[0+iOffsetZ];
//     printf("iOffset: %d \n",iOffset);
//     printf("Xm: %f \n",Xm);
//     printf("Ym: %f \n",Y[m]);
//     printf("H: %f \n",H[0+iOffset]);
        for (n=1; n<iFiltLen-1; n++) {
//       printf("H: %f \n",H[n+iOffset]);
          Z[n-1+iOffsetZ] = H[n+iOffset] * Xm + Z[n+iOffsetZ];
        }
        Z[iFiltLen-1-1+iOffsetZ] = H[iFiltLen-1+iOffset] * Xm;
        Y[m+iOffsetY] = Ym;
//     printf("H: %f \n",H[iFiltLen-1+iOffset]);
      }
    }
  }
  return;
}

void CoreFilterSingle(double *Y, double *H, double *X, double *Z, double *A,
        mwSize iFiltLen, mwSize iNoTx, mwSize iSigLen, int iCRx, int iCTx)
{
  double Xm;
  int m, n, iOffset, i;
  int iOffsetY = iSigLen*iCRx+iSigLen*2*iCTx;
  int iOffsetX = iSigLen*iCTx;
  int iOffsetH = iFiltLen*iCRx+iFiltLen*2*iCTx;
  int iOffsetZ = (iFiltLen-1)*iCRx+(iFiltLen-1)*2*iCTx;
  
  for (m=0; m<iSigLen; m++) {
    iOffset       = iOffsetH+iFiltLen*2*iNoTx*A[m];
    Xm            = X[m+iOffsetX];
    Y[m+iOffsetY] = H[0+iOffset]*Xm+Z[0+iOffsetZ];
//     printf("iOffset: %d \n",iOffset);
//     printf("Xm: %f \n",Xm);
//     printf("Ym: %f \n",Y[m]);
//     printf("H: %f \n",H[0+iOffset]);
    for (n=1; n<iFiltLen-1; n++) {
//       printf("H: %f \n",H[n+iOffset]);
      Z[n-1+iOffsetZ] = H[n+iOffset] * Xm + Z[n+iOffsetZ];
    }
    Z[iFiltLen-1-1+iOffsetZ] = H[iFiltLen-1+iOffset] * Xm;
//     printf("H: %f \n",H[iFiltLen-1+iOffset]);
  }
  return;
}
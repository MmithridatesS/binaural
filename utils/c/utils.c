/***********************************************************************
% utility functions for C
% ----------------------------------------------------------------------
% Author:       Lars Häring
% 
% ----------------------------------------------------------------------
% Last update:  14.11.02
%
% **********************************************************************
% input parameters:
% =================
% -
% ----------------------------------------------------------------------
% output parameters:
% ==================
% -
% --------------------------------------------------------------------*/

#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>

double *rand_c(double num)
{
    mxArray *array_in[2], *array_out[1];   
    double one = 1.0f;
    
    array_in[0] =   (mxArray *)mxCreateDoubleMatrix(1,1,mxREAL);
    array_in[1] =   (mxArray *)mxCreateDoubleMatrix(1,1,mxREAL);    
    array_out[0] =  (mxArray *)mxCreateDoubleMatrix(num,1,mxREAL);
    
    memcpy(mxGetPr(array_in[0]),&one,1*sizeof(double));
    memcpy(mxGetPr(array_in[1]),&num,1*sizeof(double));
    
    mexCallMATLAB(1,array_out,2,array_in,"rand");
    
    return mxGetPr(array_out[0]);
}

double *randn_c(double num)
{
    mxArray *array_in[2], *array_out[1];   
    double one = 1.0f;
    
    array_in[0] =   (mxArray *)mxCreateDoubleMatrix(1,1,mxREAL);
    array_in[1] =   (mxArray *)mxCreateDoubleMatrix(1,1,mxREAL);    
    array_out[0] =  (mxArray *)mxCreateDoubleMatrix(num,1,mxREAL);
    
    memcpy(mxGetPr(array_in[0]),&one,1*sizeof(double));
    memcpy(mxGetPr(array_in[1]),&num,1*sizeof(double));
    
    mexCallMATLAB(1,array_out,2,array_in,"randn");
    
    return mxGetPr(array_out[0]);
}

double modulo(double x, double mod)
{
    if(mod!=0) return (x - mod*floor(x/mod));
    return -1;
}

void piksrt(int n, double *arr)
{
    int i,j;
    double a;
    for (j=1;j<n;j++) {
        a = arr[j];
        i = j-1;
        while(i>0 && arr[i] > a) {
            arr[i+1] = arr[i];
            i--;
        }
        arr[i+1] = a;
    }
}

double random (void);          /* return the next random number x: 0 <= x < 1*/
void  rand_seed (unsigned int);         /* seed the generator */


static unsigned int SEED = 93186752;


double random ()  
{
/* The following parameters are recommended settings based on research
   uncomment the one you want. */


   static unsigned int a = 1588635695, m = 4294967291U, q = 2, r = 1117695901;
/* static unsigned int a = 1223106847, m = 4294967291U, q = 3, r = 625646750;*/
/* static unsigned int a = 279470273, m = 4294967291U, q = 15, r = 102913196;*/
/* static unsigned int a = 1583458089, m = 2147483647, q = 1, r = 564025558; */
/* static unsigned int a = 784588716, m = 2147483647, q = 2, r = 578306215;  */
/* static unsigned int a = 16807, m = 2147483647, q = 127773, r = 2836;      */
/* static unsigned int a = 950706376, m = 2147483647, q = 2, r = 246070895;  */

   SEED = a*(SEED % q) - r*(SEED / q);
   return ((double)SEED / (double)m);
 }
void rand_seed (unsigned int init)
{
    if (init != 0) SEED = init;
}


double gaussrand()
{
   static double V2, fac;
   static int phase = 0;
   double S, Z, U1, U2, V1;

   if (phase)
      Z = V2 * fac;
   else
      {
      do {
         U1 = random();
         U2 = random();

         V1 = 2 * U1 - 1;
         V2 = 2 * U2 - 1;
         S = V1 * V1 + V2 * V2;
         } while(S >= 1);

      fac = sqrt (-2 * log(S) / S);
      Z = V1 * fac;
      }

   phase = 1 - phase;

   return Z;
}

int find_c(int *output, double *input, int value, int length)
{    
    int i,counter=0;
    
    for (i=0;i<length;i++) {
        if ((int)input[i]==value) {
            output[counter] = i;
            counter++;
        }
    }
    return counter;          
}



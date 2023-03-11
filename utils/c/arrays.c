/***********************************************************************
 * % functions that allocates memory for different array dimensions:
 * % separation of functions in arrayX_1 and arrayX_2 is necessary
 * % for MEX memory allocation
 * % ----------------------------------------------------------------------
 * % Author:       Lars Häring
 * %
 * % ----------------------------------------------------------------------
 * % Last update:  14.11.02
 * %
 * % **********************************************************************
 * % input parameters:
 * % =================
 * % -
 * % ----------------------------------------------------------------------
 * % output parameters:
 * % ==================
 * % -
 * % --------------------------------------------------------------------*/

#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>

void nerror(char error_text[])
{
  fprintf(stderr,"Runtime error");
  fprintf(stderr,"%s\n",error_text);
  fprintf(stderr,"Exiting to system...");
  exit(1);
}

double **array2(int dim1, int dim2)
{
  int i;
  double **a;
  
  a = (double **) mxCalloc(dim1,sizeof(double*));
  if(!a) nerror("allocation failure 1 in array2");
  
  a[0] = (double *) mxCalloc(dim1*dim2,sizeof(double));
  if(!a[0]) nerror("allocation failure 2 in array2");
  
  for(i=1;i<dim1;i++) a[i]=a[0]+i*dim2;
  
  return a;
}

double **array2_1(int dim1, int dim2)
{
  double **a;
  
  a = (double **) mxCalloc(dim1,sizeof(double*));
  if(!a) nerror("allocation failure 1 in array2");
  
  a[0] = (double *) mxCalloc(dim1*dim2,sizeof(double));
  if(!a[0]) nerror("allocation failure 2 in array2");
  
  return a;
}

double **array2_2(double **a, int dim1, int dim2)
{
  int i;
  
  for(i=1;i<dim1;i++) a[i]=a[0]+i*dim2;
  
  return a;
}



double ***array3(int dim1, int dim2, int dim3)
{
  int i,j;
  
  double ***a;
  
  a = (double ***) mxCalloc(dim1,sizeof(double**));
  if(!a) nerror("allocation failure 1 in array3");
  
  a[0] = (double **) mxCalloc(dim1*dim2,sizeof(double*));
  if(!a[0]) nerror("allocation failure 2 in array3");
  
  a[0][0] = (double *) mxCalloc(dim1*dim2*dim3,sizeof(double));
  if(!a[0][0]) nerror("allocation failure 3 in array3");
  
  for(j=1;j<dim2;j++) {
    a[0][j] = a[0][0] + j*dim3;
  }
  
  for(i=1;i<dim1;i++) {
    a[i] = a[0] + i*dim2;
    a[i][0] = a[0][0] + i*dim2*dim3;
    for(j=1;j<dim2;j++) {
      a[i][j] = a[i][0] + j*dim3;
    }
  }
  
  return a;
}

double ***array3_1(int dim1, int dim2, int dim3)
{
  double ***a;
  
  a = (double ***) mxCalloc(dim1,sizeof(double**));
  if(!a) nerror("allocation failure 1 in array3");
  
  a[0] = (double **) mxCalloc(dim1*dim2,sizeof(double*));
  if(!a[0]) nerror("allocation failure 2 in array3");
  
  a[0][0] = (double *) mxCalloc(dim1*dim2*dim3,sizeof(double));
  if(!a[0][0]) nerror("allocation failure 3 in array3");
  
  return a;
}


double ***array3_2(double ***a, int dim1, int dim2, int dim3)
{
  int i,j;
  
  for(j=1;j<dim2;j++) {
    a[0][j] = a[0][0] + j*dim3;
  }
  
  for(i=1;i<dim1;i++) {
    a[i] = a[0] + i*dim2;
    a[i][0] = a[0][0] + i*dim2*dim3;
    for(j=1;j<dim2;j++) {
      a[i][j] = a[i][0] + j*dim3;
    }
  }
  
  return a;
}

double ****array4(int dim1, int dim2, int dim3, int dim4)
{
  int i,j,k;
  
  double ****a;
  
  a = (double ****) mxCalloc(dim1,sizeof(double***));
  if(!a) nerror("allocation failure 1 in array4");
  
  a[0] = (double ***) mxCalloc(dim1*dim2,sizeof(double**));
  if(!a[0]) nerror("allocation failure 2 in array4");
  
  a[0][0] = (double **) mxCalloc(dim1*dim2*dim3,sizeof(double*));
  if(!a[0][0]) nerror("allocation failure 3 in array4");
  
  a[0][0][0] = (double *) mxCalloc(dim1*dim2*dim3*dim4,sizeof(double));
  if(!a[0][0][0]) nerror("allocation failure 4 in array4");
  
  for(k=1;k<dim3;k++) {
    a[0][0][k] = a[0][0][0] + k*dim4;
  }
  for(j=1;j<dim2;j++) {
    a[0][j] = a[0][0] + j*dim3;
    a[0][j][0] = a[0][0][0] + j*dim3*dim4;
    for(k=1;k<dim3;k++) {
      a[0][j][k] = a[0][j][0] + k*dim4;
    }
  }
  for(i=1;i<dim1;i++) {
    a[i] = a[0] + i*dim2;
    a[i][0] = a[0][0] + i*dim2*dim3;
    a[i][0][0] = a[0][0][0] + i*dim2*dim3*dim4;
    for(k=1;k<dim3;k++) {
      a[i][0][k] = a[i][0][0] + k*dim4;
    }
    for(j=1;j<dim2;j++) {
      a[i][j] = a[i][0] + j*dim3;
      a[i][j][0] = a[i][0][0] + j*dim3*dim4;
      for(k=1;k<dim3;k++) {
        a[i][j][k] = a[i][j][0] + k*dim4;
      }
    }
  }
  
  return a;
}

double ****array4_1(int dim1, int dim2, int dim3, int dim4)
{
  double ****a;
  
  a = (double ****) mxCalloc(dim1,sizeof(double***));
  if(!a) nerror("allocation failure 1 in array4");
  
  a[0] = (double ***) mxCalloc(dim1*dim2,sizeof(double**));
  if(!a[0]) nerror("allocation failure 2 in array4");
  
  a[0][0] = (double **) mxCalloc(dim1*dim2*dim3,sizeof(double*));
  if(!a[0][0]) nerror("allocation failure 3 in array4");
  
  a[0][0][0] = (double *) mxCalloc(dim1*dim2*dim3*dim4,sizeof(double));
  if(!a[0][0][0]) nerror("allocation failure 4 in array4");
  
  return a;
}

double ****array4_2(double ****a, int dim1, int dim2, int dim3, int dim4)
{
  int i,j,k;
  
  for(i=0;i<dim1;i++) {
    a[i] = a[0] + i*dim2;
    for(j=0;j<dim2;j++) {
      a[i][j] = a[0][0] + i*dim2*dim3 + j*dim3;
      for(k=0;k<dim3;k++) {
        a[i][j][k] = a[0][0][0] + i*dim2*dim3*dim4 + j*dim3*dim4 + k*dim4;
      }
    }
  }
  return a;
}

double *****array5_1(int dim1, int dim2, int dim3, int dim4, int dim5)
{
  double *****a;
  
  a = (double *****) mxCalloc(dim1,sizeof(double****));
  if(!a) nerror("allocation failure 1 in array5");
  
  a[0] = (double ****) mxCalloc(dim1*dim2,sizeof(double***));
  if(!a[0]) nerror("allocation failure 2 in array5");
  
  a[0][0] = (double ***) mxCalloc(dim1*dim2*dim3,sizeof(double**));
  if(!a[0][0]) nerror("allocation failure 3 in array5");
  
  a[0][0][0] = (double **) mxCalloc(dim1*dim2*dim3*dim4,sizeof(double*));
  if(!a[0][0][0]) nerror("allocation failure 4 in array5");
  
  a[0][0][0][0] = (double *) mxCalloc(dim1*dim2*dim3*dim4*dim5,sizeof(double));
  if(!a[0][0][0][0]) nerror("allocation failure 5 in array5");
  
  return a;
}

double *****array5_2(double *****a, int dim1, int dim2, int dim3, int dim4, int dim5)
{
  int i,j,k,m;
  
  for(i=0;i<dim1;i++) {
    a[i] = a[0] + i*dim2;
    for(j=0;j<dim2;j++) {
      a[i][j] = a[0][0] + i*dim2*dim3 + j*dim3;
      for(k=0;k<dim3;k++) {
        a[i][j][k] = a[0][0][0] + i*dim2*dim3*dim4 + j*dim3*dim4 + k*dim4;
        for(m=0;m<dim4;m++) {
          a[i][j][k][m] = a[0][0][0][0] + i*dim2*dim3*dim4*dim5 + j*dim3*dim4*dim5 + k*dim4*dim5 + m*dim5;
        }
      }
    }
  }
  return a;
}

double *****array5(int dim1, int dim2, int dim3, int dim4, int dim5)
{
  int i,j,k,m;
  double *****a;
  
  a = (double *****) mxCalloc(dim1,sizeof(double****));
  if(!a) nerror("allocation failure 1 in array5");
  
  a[0] = (double ****) mxCalloc(dim1*dim2,sizeof(double***));
  if(!a[0]) nerror("allocation failure 2 in array5");
  
  a[0][0] = (double ***) mxCalloc(dim1*dim2*dim3,sizeof(double**));
  if(!a[0][0]) nerror("allocation failure 3 in array5");
  
  a[0][0][0] = (double **) mxCalloc(dim1*dim2*dim3*dim4,sizeof(double*));
  if(!a[0][0][0]) nerror("allocation failure 4 in array5");
  
  a[0][0][0][0] = (double *) mxCalloc(dim1*dim2*dim3*dim4*dim5,sizeof(double));
  if(!a[0][0][0][0]) nerror("allocation failure 5 in array5");
  
  for(i=0;i<dim1;i++) {
    a[i] = a[0] + i*dim2;
    for(j=0;j<dim2;j++) {
      a[i][j] = a[0][0] + i*dim2*dim3 + j*dim3;
      for(k=0;k<dim3;k++) {
        a[i][j][k] = a[0][0][0] + i*dim2*dim3*dim4 + j*dim3*dim4 + k*dim4;
        for(m=0;m<dim4;m++) {
          a[i][j][k][m] = a[0][0][0][0] + i*dim2*dim3*dim4*dim5 + j*dim3*dim4*dim5 + k*dim4*dim5 + m*dim5;
        }
      }
    }
  }
  return a;
}
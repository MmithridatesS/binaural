/***********************************************************************
% several matrix operations for C
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

double **matrix_mult(double **a, double **b, int nrow1, int ncol1, 
    int nrow2, int ncol2)
{
    int i, j, k;
    double **c;
    
	/* memory allocation is missing */
    if(ncol1!=nrow2) printf("Matrix dimension incorrect");
    
    for (i=0;i<nrow1;i++) {
        for (j=0;j<ncol2;j++) {
            c[i][j] = 0.0;
            for (k=0;i<ncol1;i++) {
                c[i][j] = c[i][j] + a[i][k]*b[k][j];;
            }        
        }
    }    
    return c;
}
void matrix_add(double **c, double **a, double **b, int nrow, int ncol) {
    
	int i, j;
//    double **c;
    
    for (i=0;i<nrow;i++) {
        for (j=0;j<ncol;j++) {
            c[i][j] = a[i][j] + b[i][j];
        }
    }    
//    return c;
}
void vector_add(double *c, double *a, double *b, int length, int sub_flag) {
	int i;
	if(sub_flag == -1) { // subtraction
		for(i=0;i<length;i++) {
			c[i] = a[i] - b[i];
		}
	}
	else {
		for(i=0;i<length;i++) {
			c[i] = a[i] + b[i];
		}
	}
}

void A_times_b(double *c, double **A, double *b, int nrow1, int ncol1, int change_flag)
{
	int i, j;
//	double *c;

	if(change_flag==-1) {	// rows and columns are of A are changed
		for(i=0;i<nrow1;i++) {
			c[i] = 0.0;
			for(j=0;j<ncol1;j++) {
				c[i] = c[i] + A[j][i]*b[j];
			}
		}
	}
	else {
		for(i=0;i<nrow1;i++) {
			c[i] = 0.0;
			for(j=0;j<ncol1;j++) {
				c[i] = c[i] + A[i][j]*b[j];
			}
		}
	}
//	return c;
}

void a_ah(double **cr, double **ci, double *ar, double *ai, int length)
{
    int i,j;
    for (i=0;i<length;i++) {
        for (j=0;j<length;j++) {
            cr[i][j] =  ar[i] * ar[j] + ai[i] * ai[j];
            ci[i][j] = -ar[i] * ai[j] + ai[i] * ar[j];            
        }
    }    
}

void ah_b(double *cr, double *ci, double *ar, double *ai, double *br, double *bi, int length)
{
	int i;

	*cr = 0.0;
	*ci = 0.0;

    for (i=0;i<length;i++) {
        *cr = *cr + ar[i]*br[i] + ai[i]*bi[i];
        *ci = *ci + ar[i]*bi[i] - ai[i]*br[i];		        
    }
}


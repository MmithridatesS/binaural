/***********************************************************************
% functions that enable to handle complex values in C
%
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

#include <math.h>

typedef struct DCOMPLEX {double r,i;} dcomplex;

dcomplex Cadd(dcomplex a, dcomplex b)
{
    dcomplex c;
    c.r=a.r+b.r;
    c.i=a.i+b.i;
    return c;
}

dcomplex Csub(dcomplex a, dcomplex b)
{
    dcomplex c;
    c.r=a.r-b.r;
    c.i=a.i-b.i;
    return c;
}

dcomplex Cmul(dcomplex a, dcomplex b)
{
    dcomplex c;
    c.r=a.r*b.r-a.i*b.i;
    c.i=a.i*b.r+a.r*b.i;
    return c;
}

dcomplex Complex(double re, double im)
{
    dcomplex c;
    c.r=re;
    c.i=im;
    return c;
}

dcomplex Conjg(dcomplex z)
{
    dcomplex c;
    c.r=z.r;
    c.i=-z.i;
    return c;
}

double Cabs(double x, double y)
{
    double ans,temp;
    if(x==0.0)
        ans = y;
    else if(y==0)
        ans = x;
    else if(x>y) {
        temp=y/x;
        ans=x*sqrt(1.0+temp*temp);
    }
    else {
        temp=x/y;
        ans=y*sqrt(1.0+temp*temp);
    }
    return ans;    
}

double Cabs2(dcomplex z)
{
    double x,y,ans,temp;
    x=fabs(z.r);
    y=fabs(z.i);
    if(x==0.0)
        ans = y;
    else if(y==0)
        ans = x;
    else if(x>y) {
        temp=y/x;
        ans=x*sqrt(1.0+temp*temp);
    }
    else {
        temp=x/y;
        ans=y*sqrt(1.0+temp*temp);
    }
    return ans;    
}

dcomplex RCmul(double x, dcomplex a)
{
    dcomplex c;
    c.r = x*a.r;
    c.i = x*a.i;
    return c;
}




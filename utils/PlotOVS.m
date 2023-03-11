function [x,y] = PlotOVS(vSig,fOSF,sColor)
iN  = length(vSig);
x   = 1+[0:iN*fOSF-1]/fOSF;
y   = fOSF*real(ifft(fft(vSig,[],1),iN*fOSF,1));
plot(x,y,sColor);
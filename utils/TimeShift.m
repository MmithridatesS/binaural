function [y] = TimeShift(x,fTimeShift)
iN  = length(x);
X   = fftshift(fft(x,iN,1)).*exp(-1i*2*pi/iN*[-iN/2:iN/2-1]*fTimeShift).';
y   = real(ifft(ifftshift(X),iN,1));

%% version 2 without fftshift
% vSC = [0:iN/2-1,-iN/2:-1];
% X2  = fft(x,iN,1).*exp(-1i*2*pi/iN*vSC*fTimeShift).';
% y2  = real(ifft(X2,iN,1));
end
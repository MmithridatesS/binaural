function [H,H_fdw] = fdw(h,fs,le_20,ri_20,le_20k,ri_20k)
% reference
N = length(h);
H = fft(h);

[~,iMax] = max(h);

H_fdw = zeros(N/2,1);
wrapN = @(x,N)(1+mod(x-1,N));
for iC=2:N/2
  f = (iC-1)*fs/N;
  le = (le_20k-le_20)/(20e3-20)*(f-20)+le_20;
  re = (ri_20k-ri_20)/(20e3-20)*(f-20)+ri_20;  
  vWin = wrapN(iMax-floor(le/f*fs):iMax+floor(re/f*fs),N);
%   length(vWin)
  H_fdw(iC) = sum(h(vWin).*blackman(length(vWin)).'.*exp(-1i*2*pi/N*iC*(vWin-1)));
end
figure
semilogx([0:2^16/2-1]/2^16*48e3,20*log10(abs(H(1:N/2))))
hold on
semilogx([0:2^16/2-1]/2^16*48e3,20*log10(abs(H_fdw(1:N/2))))
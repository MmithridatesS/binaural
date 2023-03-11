function [y] = SRC(x,iSampleRateIn,iSampleRateOut)

%% parameter setup
iFac      = gcd(iSampleRateIn,iSampleRateOut);
M         = iSampleRateIn/iFac;
L         = iSampleRateOut/iFac;
iFiltLen  = 2^18;
  
%% filter coefficients
if L>M
  h   = sinc([-(iFiltLen-1)/2:(iFiltLen-1)/2]/L);
else
  h   = sinc([-(iFiltLen-1)/2:(iFiltLen-1)/2]/M);
end

%% method 1 (upsample, filter, downsample)
% xup   = upsample(x,L);
% xfilt = fftfilt(h,[xup;zeros(iFiltLen-1,1)]);
% xfilt = xfilt((iFiltLen-1)/2+1:end-(iFiltLen-1)/2);
% y     = downsample(xfilt,M);

%% method 2 (polyphase)
y        = upfirdn(x,h,L,M);
fLen_res = ((length(x)-1)*L+length(h))/M;
fLen_y   = iSampleRateOut/iSampleRateIn*length(x);
y        = TimeShift(y,-(fLen_res-fLen_y-M/L)/2-1);
y        = y(1:ceil(fLen_y));

%% debugging
% temporary comparison between resample methods
% iLen = length(y);
% y  = interpft(y,iLen*8,1);   
% y2  = interpft(y2,iLen*8,1);   
% figure; plot(y(1:1000)); hold on;
% plot(y2(1:1000),'b');

bDebugPlot = false;
if bDebugPlot
  figure; plot(h);
  figure; plot([0:length(x)-1]/iSampleRateIn,x); hold on;
  plot([0:length(y)-1]/iSampleRateOut,y,'r');
end
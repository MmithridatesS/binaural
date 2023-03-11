clear all; close all;
% [x,fSamplFreq] = audioread('LogSweep44.wav');
fSamplFreq  = 48e3;
fDur        = 10;
fmin        = 10;
fmax        = fSamplFreq/2;
t           = [0:1/fSamplFreq:fDur-1/fSamplFreq];
y_part      = 0.5*sin(2*pi*fmin*fDur/log(fmax/fmin)*(exp(t/fDur*log(fmax/fmin))-1));
vWindow     = window(@tukeywin,fSamplFreq*fDur,0.002).';
vWindow     = ones(size(y_part));
% vInd        = find(t<=0.09);
% vWindow(vInd)     = (exp(t(vInd)/0.09)-1)/(exp(1)-1);
y_part      = y_part.*vWindow;
y           = zeros(size());
y           = [zeros(1,88200),1,zeros(1,88200-1),y_part,zeros(1,88200),1,zeros(1,88200-1)];
y(:,2)      = [zeros(1,88200),1,zeros(1,88200-1),y_part,zeros(1,88200),1,zeros(1,88200-1)];

% figure; plot([0:length(x)-1]/fSamplFreq,x)
hold on; plot([0:length(y)-1]/fSamplFreq,y,'g')
audiowrite('MyLogSweep.wav',y,fSamplFreq);
%%
y_part      = [zeros(1,2^15),y_part,zeros(1,2^15)];
iN          = length(y_part);
Y_part      = fft(y_part);
iIndMin     = floor(fmin/fSamplFreq*iN);
iIndMax     = floor(fmax/fSamplFreq*iN);
vInd1       = [iIndMin:iIndMax,iN-iIndMax+2:iN-iIndMin+2];
vInd2       = [1:iN];
vInd2(vInd1) = [];
Y_inv       = zeros(size(Y_part));
Y_inv(vInd1)  = conj(Y_part(vInd1))./(conj(Y_part(vInd1)).*Y_part(vInd1)+1e-6);
Y_inv(vInd2)  = conj(Y_part(vInd2))./(conj(Y_part(vInd2)).*Y_part(vInd2)+1e12);
y_inv       = ifft(Y_inv);
y_inv_n     = y_inv/max(abs(y_inv));


x_part      = x(176401:176400+fSamplFreq*fDur,1).';
x_part      = [zeros(1,2^15),x_part,zeros(1,2^15)];
iN          = length(x_part);
X_part      = fft(x_part);
df          = 10; fEpsMax = 1e30; fEpsMin = 1;
vEpsilon    = GenWindow(iN,fSamplFreq,10,22.05e3,df,fEpsMax,fEpsMin);
X_inv       = conj(X_part)./(conj(X_part).*X_part+vEpsilon);
figure; plot(10*log10(abs(X_inv)));
x_inv       = ifft(X_inv);
x_inv_n     = x_inv/max(abs(x_inv));

x_mirr = x_part(end:-1:1);
X_part = fft(x_part);
figure;
semilogx([0:iN/2-1],10*log10(abs(X_part(1:iN/2))));
x_conv = fftfilt(x_part,x_mirr);

df        = 20; fEpsMax = 1e8; fEpsMin = 0.001;
vEpsilon  = GenWindow(iN,fSamplFreq,10,22.05e3,df,fEpsMax,fEpsMin);
X_mirr    = 1/sqrt(iN)*fft(x_mirr);
X_conv    = 1/sqrt(iN)*fft(x_conv);
X_inv2    = X_mirr./(abs(X_conv).^2);
X_inv2    = X_mirr./(abs(X_conv).^2+vEpsilon);
x_inv2    = ifft(X_inv2);
x_inv2_n  = x_inv2/max(abs(x_inv2));
figure;

[x_inv_BM,fSamplFreq] = audioread('Inverse48.wav');
plot([0:length(x_inv_BM)-1]/fSamplFreq,x_inv_BM); hold on;
% plot([0:length(x_inv_n)-1]/fSamplFreq,x_inv_n,'g');  hold on;
plot([0:length(x_inv2_n)-1]/fSamplFreq,x_inv2_n,'r--');
% semilogx([0:iN/2-1],10*log10(abs(X_inv2(1:iN/2))));

figure
plot(fftfilt(x_inv2_n,x(:,1).'),'r'); hold on;
plot(fftfilt(x_inv_BM,x(:,1).'),'b');
plot(fftfilt(x_inv_n,x(:,1).'),'g'); hold on;
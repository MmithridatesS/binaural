function [] = PlotAudioSpectrum(X,fSampFreq,sColor)
iN = size(X,1);
semilogx([1:iN/2-1]*fSampFreq/iN,20*log10(abs(X(2:end/2,:))),sColor);
set(gca,'xlim',[10,fSampFreq/2]);
[fMax,~] = max(abs(X(:)));
set(gca,'ylim',[-50,5]+20*log10(fMax));
grid on;
xlabel('Frequency [Hz]'); ylabel('Magnitude [dB]');
iFiltLen = 2^10;
fFreqMin = 20;
fFreqMax = 80;
fSampFreq = 48e3;
iN        = 2^16;
bpFilt          = designfilt('bandpassfir', 'FilterOrder', iFiltLen, ...
  'CutoffFrequency1', fFreqMin, 'CutoffFrequency2', fFreqMax, 'SampleRate', fSampFreq,...
  'DesignMethod', 'window', 'Window', 'kaiser');
vIR = bpFilt.Coefficients;
vTargetBP       = fft(vIR,iN).'; 
subplot(2,1,1)
plot([0:iFiltLen]/fSampFreq,vIR); grid on;
subplot(2,1,2)
PlotAudioSpectrum(vTargetBP,fSampFreq,'r')
function [vTF_eq] = EqualizeHP(stSys,vTF1,vTF2,fFreqMin,fFreqMax)

iN = stSys.iN;
% vTF_eq    = vTF1./vTF2;
vTF2old = vTF2;
vEq = 1./vTF2;
fThreshold = min(abs(vEq))*10;
vEq(find(abs(vEq)>fThreshold)) = fThreshold*exp(1i*phase(vEq(find(abs(vEq)>fThreshold))));
vTF2 = 1./vEq;
vTF2(iN/2+2:iN) = conj(vTF2(stSys.iN/2:-1:2));
vTF2 = fft(real(ifft(vTF2)));

df        = 10; fEpsMax = 1e3; fEpsMin = 1e-6;
vEpsilon  = GenWindow(stSys.iN,stSys.fSampFreq,fFreqMin,fFreqMax,df,fEpsMax,fEpsMin);
% vEpsilon  = GenWindow2(stSys.iN,stSys.fSampFreq,fFreqMin,fFreqMax,df,fEpsMax,fEpsMin);
vTF2_inv  = conj(vTF2)./(conj(vTF2).*vTF2+vEpsilon.');

vTF2_inv(iN/2+2:iN) = conj(vTF2_inv(stSys.iN/2:-1:2));
% figure;
% PlotAudioSpectrum(1./vTF2_inv,iN,48e3,'b'); hold on;
% PlotAudioSpectrum(vTF2old,iN,48e3,'r');

vTF_eq              = vTF1.*vTF2_inv;
vTF_eq(1) = 1e-12;
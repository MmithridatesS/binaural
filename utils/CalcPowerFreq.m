function [y] = CalcPower(x,iN,fSamplFreq,f1,f2)

x = squeeze(x);
vInd = max(1,round(f1/fSamplFreq*iN)):min(iN,round(f2/fSamplFreq*iN));
y = 1/numel(vInd)*sum(abs(x(vInd,:,:)).^2);
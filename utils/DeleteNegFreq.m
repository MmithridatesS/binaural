function vSpecHalf=DeleteNegFreq(vSpec)

% delete negative frequencies of spectrum
len               = size(vSpec,1);
% vSpecHalf enthält auch die höchste Frequenz, obwohl diese zum negativen Teil d. Spektrums gehört!!!
vSpecHalf         = vSpec(1:len/2+1,:);    
% Daher wird diese Frequenz bereits komplex konjugiert, wie es in ergRe beim negativen Rest auch geschieht.
vSpecHalf(end,:)  = conj(vSpecHalf(end,:));
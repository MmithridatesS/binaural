function vSpecHalf=DeleteNegFreq(vSpec)

% delete negative frequencies of spectrum
len               = size(vSpec,1);
% vSpecHalf enth�lt auch die h�chste Frequenz, obwohl diese zum negativen Teil d. Spektrums geh�rt!!!
vSpecHalf         = vSpec(1:len/2+1,:);    
% Daher wird diese Frequenz bereits komplex konjugiert, wie es in ergRe beim negativen Rest auch geschieht.
vSpecHalf(end,:)  = conj(vSpecHalf(end,:));
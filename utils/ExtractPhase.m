function [vTF_out] = ExtractPhase(stSys,vTF_in,fFreqMin,fFreqMax)

iN        = stSys.iN;
fSampFreq = stSys.fSampFreq;
vTF_out   = vTF_in;

% lower frequency
iIndMin                       = round(fFreqMin/fSampFreq*iN);
vTF_out(1)                    = 1e-12;
vTF_out(2:iIndMin)            = vTF_out(iIndMin)*exp(1i*phase(vTF_out(2:iIndMin)));

% upper frequency
iIndMax                       = round(fFreqMax/fSampFreq*iN);
vTF_out(iN/2+1)               = abs(vTF_out(iIndMax));
vTF_out(iIndMax:iN/2)         = vTF_out(iIndMax)*exp(1i*phase(vTF_out(iIndMax:iN/2)));

% make it real
vTF_out(iN/2+2:iN)            = conj(vTF_out(iN/2:-1:2));
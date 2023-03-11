function [vTF1n,vTF2n,vIR1n,vIR2n] = NormalizePower(vTF1,vTF2)
vTF1n   = vTF1/sqrt(CalcPower(vTF1));
vIR1n   = ifft(vTF1n);
vTF2n   = vTF2/sqrt(CalcPower(vTF1));
vIR2n   = ifft(vTF2n);
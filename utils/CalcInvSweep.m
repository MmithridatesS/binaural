function y=CalcInvSweep(vSweep)
%berechnet ein Filter als Inverse vom sweep
%ist der Sweep eine mehrkanälige Datei, wird nur der erste Kanal beachtet!

%Sweep=normalisiere(Sweep); Ist mathematisch EXAKT (auch in MATLAB) das
%Gleiche, ob man hier normalisiert, oder nicht! (Die Summe des Differenzvektors der
%Endprodukt-Audiodateien ist exakt 0!)

vSweep  = vSweep(end:-1:1,1);          %zeitlich spiegeln
vSweep  = DeleteNegFreq(fft(vSweep));
iLen    = size(vSweep,1)-1;

%Amplitudenanpassung
vSweep(iLen+1,1)          = vSweep(iLen+1,1)*iLen;
vSweep(iLen-[0:iLen-1],1) = vSweep(iLen-[0:iLen-1],1).*(iLen-[0:iLen-1].');

y       = ifft(FillNegFreq(vSweep));
y       = y/max(y);
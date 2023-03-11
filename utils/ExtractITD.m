function [fITD] = ExtractITD(vIR,fRelThres,fOSF)

iN        = length(vIR);
vSubSampl = 1+[0:iN*fOSF-1]/fOSF;
vIROVS    = interpft(vIR,iN*fOSF,1);

bSRDet    = true;
if bSRDet
  vSROVS    = cumsum(vIROVS);
  vSROVS    = vSROVS / max(abs(vSROVS));
  vInd      = find(abs(vSROVS)>fRelThres);
else
  vIROVS    = vIROVS / max(abs(vIROVS));
  vInd      = find(abs(vIROVS)>fRelThres);  
end
fITD      = vSubSampl(vInd(1));
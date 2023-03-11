function [mSweep,vInvSweep] = WriteLogSweep(fFreqMin,fFreqMax,fDur,fPause,fAmpl,fSamplFreq,Bits,sMode,vActTx)

%% training signal
t = [0:1/fSamplFreq:fDur-1/fSamplFreq];
y = 0.5*sin(2*pi*fFreqMin*fDur/log(fFreqMax/fFreqMin)*(exp(t/fDur*log(fFreqMax/fFreqMin))-1)).';

%% fade-in and windowing
% 0.1 sec
vWindow             = blackman(0.1*fSamplFreq);
iLen                = length(vWindow);
y(1:iLen/2)         = y(1:iLen/2).*vWindow(1:iLen/2);
y(end-iLen/2+1:end) = y(end-iLen/2+1:end).*vWindow(iLen/2+1:end);

%% insert pause and copying
switch sMode
  case 'LSP'
    vActTxInt = find(vActTx);
    iNoTx     = length(vActTx);
    iNoActTx  = length(vActTxInt);
    vHelp     = [y;zeros(fSamplFreq*fPause,1)];
    iLen      = length(vHelp);
    mSweep    = zeros(iNoActTx*iLen,iNoTx);
    for iC = 1:iNoActTx      
      mSweep((iC-1)*iLen+1:iC*iLen,vActTxInt(iC)) = vHelp;
    end
%     mSweep = [zeros(fSamplFreq*fPause,2);mSweep];    
  case 'HP'
    mSweep = repmat([zeros(fSamplFreq*fPause,1);y;zeros(fSamplFreq*fPause,1)],1,2);
  otherwise
    disp('Check input parameters!')
end

%% save log-sweep
sFileName = ['measure/training/Sweep_' num2str(fFreqMin) '_' num2str(fFreqMax) '_' ...
  num2str(fDur) '_' num2str(fAmpl) '_' num2str(fSamplFreq) '_' num2str(Bits) '.wav'];
audiowrite(sFileName,mSweep,fSamplFreq,'BitsPerSample',Bits);

%% 
vInvSweep = CalcInvSweep([y;zeros(2^15,1)]);
sFileName = ['measure/training/Sweep_' num2str(fFreqMin) '_' num2str(fFreqMax) '_' ...
  num2str(fDur) '_' num2str(fAmpl) '_' num2str(fSamplFreq) '_' num2str(Bits) '_inv.wav'];
audiowrite(sFileName,vInvSweep,fSamplFreq,'BitsPerSample',Bits);

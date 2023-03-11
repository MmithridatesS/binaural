function [] = Calibrate()

clc;
disp('Calibration')
disp('===========')
%% read parameters and initialize audio device
addpath('utils'); SetParameters;
fSR = stSys.fSampFreq;

% Fireface UC
playRec     = audioPlayerRecorder('Device','ASIO Fireface USB',...
  'PlayerChannelMapping',[1:2],'RecorderChannelMapping',[1:2],...
  'SampleRate',fSR,'BitDepth','32-bit float');

%% generate noise signal
mNoise    = 1/10*randn(2*fSR,2);

iPackLen  = 256;
iNoFr     = round(size(mNoise,1)/iPackLen);
iRem      = mod(size(mNoise,1),iPackLen);
mNoise    = [mNoise;zeros(iRem,size(mNoise,2))];

mRecSig   = zeros(size(mNoise));
for iCF=1:iNoFr
  vInd            = (iCF-1)*iPackLen+1:iCF*iPackLen;
  mRecSig(vInd,:) = playRec(mNoise(vInd,:));
end

bDebugMode = false;
if bDebugMode
  figure
  title('Calibration: Measured white noise')
  plot([0:size(mRecSig,1)-1]/fSR,mRecSig(:,1)); hold on;
  plot([0:size(mRecSig,1)-1]/fSR,mRecSig(:,2),'r');
  xlabel('Time [s]'); ylabel('Amplitude'); grid on;
end

vAvAmpl = zeros(1,2);
for iCRx = 1:2
  vAvAmpl(iCRx) = sqrt(CalcPower(mRecSig(:,iCRx)));
end
fImbalance = vAvAmpl(2)/vAvAmpl(1);

disp(['Imbalance factor: ',num2str(fImbalance,'%.3f'),' (linear)'])
disp(['                  ',num2str(20*log10(fImbalance),'%.3f'),' (dB)'])
disp('  ... calibration completed.');

%% save data
save('measure/calibration.mat','fImbalance');
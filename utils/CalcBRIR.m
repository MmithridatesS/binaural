function [mIR] = CalcBRIR(sSetup,sRoomName,sHeadphoneName,fSampleRateTarget)

%% check input parameters
switch nargin
  case 4
    disp(' ');
    disp(['Calculating BRIR for dataset: ',sSetup,'/',sRoomName,' + ',sHeadphoneName])
  otherwise
    warning('Check number of inputs!');
end
%% PARAMETERS
addpath('utils');
SetParameters;
iN              = stSys.iN;
fSampFreq       = stSys.fSampFreq;

%% CALCULATE BRIRs
load(['PRIR/',sSetup,'/',sRoomName,'/PRIR'],'stPRIR');
stBRIR.vAngle = stPRIR.vAngle;
vActTxInt     = find(stPRIR.vActTx);
iNoTx         = length(stPRIR.vActTx);
iNoActTx      = length(vActTxInt);
load(['HPIR/',sHeadphoneName,'/HPIR'],'stHPIR');
mIR_HP_inv    = stHPIR.mIR_HP_inv;


fVolMax = 0; % maximum volume
for iCA = 1:length(stBRIR.vAngle)
  disp(['  for angle: ',int2str(stBRIR.vAngle(iCA)),'°'])  
  mPRIR     = stPRIR.stData(iCA).mIR;

  %% calculate BRIR
  mIR = zeros(iN,2,iNoTx);
  for iCRx = 1:2
    for iCTx = 1:iNoTx
      mIR(:,iCRx,iCTx)  = fftfilt(mIR_HP_inv(:,iCRx),mPRIR(:,iCRx,iCTx));
    end
  end
  % find maximal volume of frequency response
  mTF = fft(mIR,iN,1);
  fVolMax = max(fVolMax,max(abs(mTF(:))));

  %% REDUCE LATENCY
  % must be further elaborated
%   iShift  = 256;
%   mIR     = [mIR(1+iShift:end,:,:);mIR(1:iShift,:,:)];
  
  %% copy to output
  stBRIR.stData(iCA).mIR  = mIR;

  %% graphical output
  if bShowBRIR
    figure;
    for iCTx = 1:iNoActTx
      subplot(iNoActTx,2,2*(iCTx-1)+1);
      mIRInt  = interpft(mIR,iN*iOSF,1);
      if ~bStepResponse
        title('Impulse response');
        plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,mIRInt(:,1,iCTx),'b'); hold on;
        plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,mIRInt(:,2,iCTx),'r');
        [fMax,~] = max(mIRInt(:));
        ylabel(['Tx ',int2str(vActTxInt(iCTx))]);
      else
        title('step response');
        plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,cumsum(mIRInt(:,1,iCTx)),'b'); hold on;
        plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,cumsum(mIRInt(:,2,iCTx)),'r');
        fMax = max(max(max(abs(cumsum(mIRInt)))));
        ylabel(['Tx ',int2str(vActTxInt(iCTx))]);
      end
      grid on;
      set(gca,'xlim',[0,(iN-1)/fSampFreq*1e3/16]);
      set(gca,'ylim',[-fMax*1.2,fMax*1.2]);
      leg = legend('L','R'); grid on;
      set(leg,'Location','Southeast');
    end
    xlabel('Time [ms]');
    subplot(iNoActTx,2,1);
    if ~bStepResponse
      title(['Binaural IR at ',int2str(stBRIR.vAngle(iCA)),'°']);
    else
      title(['Binaural SR at ',int2str(stBRIR.vAngle(iCA)),'°']);
    end

    for iCTx = 1:iNoActTx
      subplot(iNoActTx,2,2*iCTx);
      semilogx([1:iN/2-1]*fSampFreq/iN,20*log10(abs(mTF(2:end/2,1,iCTx))),'b'); hold on;
      semilogx([1:iN/2-1]*fSampFreq/iN,20*log10(abs(mTF(2:end/2,2,iCTx))),'r');
      set(gca,'xlim',[20,fSampFreq/2]);
      [fMax,~] = max(abs(mTF(:)));
      set(gca,'ylim',[-60,2]+20*log10(fMax));
      grid on;
      ylabel(['Tx ',int2str(vActTxInt(iCTx)),' [dB]']);
    end
    xlabel('Frequency [Hz]');
    subplot(iNoActTx,2,2);
    title(['Binaural frequency response at ',int2str(stBRIR.vAngle(iCA)),'°']);
  end
end

%% Normalization to maximum of frequency response
for iCA = 1:length(stBRIR.vAngle)
  stBRIR.stData(iCA).mIR = stBRIR.stData(iCA).mIR / fVolMax; 
end

%% CONVERSION TO TARGET SAMPLE RATE
disp(' ')
disp('Resampling BRIRs to target sample rate')
fSamplFreq   = 48e3;
disp(['  to rate: ',num2str(fSampleRateTarget/1e3),'kHz']);
fSamplFreqRS = fSampleRateTarget;
for iCA = 1:length(stBRIR.vAngle)
  mIR = stBRIR.stData(iCA).mIR;
  mIR_RS = zeros(ceil(iN*fSamplFreqRS/fSamplFreq),2,iNoTx);
  for iCRx = 1:2
    for iCTx = 1:iNoTx
      mIR_RS(:,iCRx,iCTx)  = SRC(mIR(:,iCRx,iCTx),fSamplFreq,fSamplFreqRS);
    end
  end
  % old IR will be overwritten
  stBRIR.stData(iCA).mIR = mIR_RS;
end
disp(['  ... done!']);

%% SAVE DATASET
stBRIR.iNoHeadPos   = stPRIR.iNoHeadPos;
stBRIR.iHeadRange   = stPRIR.iHeadRange;
stBRIR.vActTx       = stPRIR.vActTx;
stBRIR.iNoTx        = length(stBRIR.vActTx);
stBRIR.fSampleRate  = fSampleRateTarget;
stBRIR.fHeadRadius  = stPRIR.fHeadRadius;
stBRIR.fDist2Source = stPRIR.fDist2Source;
stBRIR.vAngleSource = stPRIR.vAngleSource;
stBRIR.mITD_table   = stPRIR.mITD_table;

switch stBRIR.iNoTx
  case 2
    sBRIRName = ['Room_',sRoomName,'_HP_',sHeadphoneName];
    sSetup    = '2.0/';
  case 6
    sBRIRName = ['Room_',sRoomName,'_HP_',sHeadphoneName];
    sSetup    = '5.1/';    
end
sDirName = ['BRIR/',sSetup,sBRIRName];
if ~exist(sDirName,'dir')
  mkdir(sDirName);
end
save([sDirName,'/BRIR'],'stBRIR');
disp(' ')
disp(['BRIR saved in folder /BRIR/',sSetup,sBRIRName,'/']);
if bEqualizerAPO
  mIRInt = InterpIR(stBRIR,0);
  audiowrite([sDirName,'/BRIR44L.wav'],squeeze(mIRInt(:,1,:)),fSampleRateTarget,'BitsPerSample',64);
  audiowrite([sDirName,'/BRIR44R.wav'],squeeze(mIRInt(:,2,:)),fSampleRateTarget,'BitsPerSample',64);
  switch stBRIR.iNoTx
    case 2
      copyfile('utils/EqualizerAPO_config_2.0.txt',sDirName);
    case 6
      copyfile('utils/EqualizerAPO_config_5.1.txt',sDirName);
  end
  disp('  ... also for EqualizerAPO')
end
  
%% Resampling 192kHz
bFilter192 = false;
if bFilter192 == true
  fSampFreqRS   = 192e3;
  if fSampFreqRS~=fSampFreq
    for iCRx = 1:2
      for iCTx = 1:iNoTx
        mIR_RS(:,iCRx,iCTx) = SRC(mIR(:,iCRx,iCTx),fSampFreq,fSampFreqRS);
      end
    end
    iOff      = round((fSampFreqRS/fSampFreq-1)*iOffset);
    mIR_RS = mIR_RS(iOff+1:iOff+iN,:,:);
    audiowrite([sDirName,'/BRIR192L.wav'],squeeze(mIR_RS(:,1,:)),fSampFreqRS,'BitsPerSample',64);
    audiowrite([sDirName,'/BRIR192R.wav'],squeeze(mIR_RS(:,2,:)),fSampFreqRS,'BitsPerSample',64);
    disp('BRIR in 192kHz calculated ...');
  end
end
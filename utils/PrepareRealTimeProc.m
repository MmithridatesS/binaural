function [mIRInt,vAngle] = PrepareRealTimeProc(sDirName,iFiltLen,bInterpolate)
% clear all;
clc;
disp('Binaural Synthesizer');
disp('====================');
disp('Preparing data ...');

%% load data
addpath('utils');
load(['BRIR/',sDirName,'/BRIR']);
iNoTx       = size(stBRIR.stData(1).mIR,3);

%% truncate IR if needed
if iFiltLen < size(stBRIR.stData(1).mIR,1)
  for iC = 1:stBRIR(1).iNoHeadPos
    stBRIR.stData(iC).mIR = stBRIR.stData(iC).mIR(1:iFiltLen,:,:);
  end
elseif iFiltLen > size(stBRIR.stData(1).mIR,1)
  iFiltLen = size(stBRIR.stData(1).mIR,1);
  disp('Filter length set to maximum - no truncating done!');
end

%% AIR (Brüggemann)
bAIR = false;
if bAIR
  mAIR = randn(size(stBRIR.stData(1).mIR));
  f = [0,5/22.05,15/22.05,1];
  mhi = [0,1,1,0];
  bhi = fir2(34,f,mhi);
  iNo = 441*2;
  for iCTx=1:2
    for iC=1:2
      mAIR(:,iC,iCTx) = filter(bhi,1,mAIR(:,iC,iCTx));
      mAIR(:,iC,iCTx) = wshift('1D',mAIR(:,iC,iCTx),12);
      mAIR(:,iC,iCTx) = sqrt(exp(-1/200*[0:size(mAIR,1)-1])).'.*mAIR(:,iC,iCTx);
      mAIR(:,iC,iCTx) = wshift('1D',mAIR(:,iC,iCTx),-iNo);
      mAIR(1:iNo,iC,iCTx) = 0;
      %    sum(abs(mAIR(:,iC,iCTx)).^2)
    end
  end
  mAIR = 1/200*mAIR;
  for iC = 1:stBRIR(1).iNoHeadPos
    stBRIR.stData(iC).mIR = stBRIR.stData(iC).mIR+mAIR;
  end
end  

%% interpolate IR
if stBRIR.iNoHeadPos == 1
  mIRInt = stBRIR.stData(1).mIR(1:iFiltLen,:,:);
  vAngle = 0;
else
  fPowFac   = 1.75;
  bInterpolate = true;
  if bInterpolate
    vAngle    = [0:(1/(16*stBRIR.iHeadRange))^(1/fPowFac):1].^fPowFac*stBRIR.iHeadRange;
    vAngle    = [-vAngle(end:-1:2),vAngle];
    mIRInt    = InterpIR(stBRIR,vAngle);
    disp('BRIRs for headtracking interpolated ...');
  else
    vAngle    = [-60:15:60]; % if not interpolated
    mIRInt    = zeros([size(stBRIR.stData(1).mIR),length(vAngle)]);
    for iC=1:length(stBRIR.stData)
      mIRInt(:,:,:,iC) = stBRIR.stData(iC).mIR;
    end
  end 
end
%% post processing -> smooth transitions
bSmoothing = true;
if bSmoothing
  iLenLe  = 8;
  iLenRe  = 128*iLenLe;
  vWinLe  = blackman(iLenLe);
  vWinRe  = blackman(iLenRe);
  for iCTx = 1:iNoTx
    for iCRx = 1:2      
      for iCA = 1:length(vAngle)
        mIRInt(1:iLenLe/2,iCRx,iCTx,iCA)         = mIRInt(1:iLenLe/2,iCRx,iCTx,iCA).*vWinLe(1:iLenLe/2);
        mIRInt(end-iLenRe/2+1:end,iCRx,iCTx,iCA) = mIRInt(end-iLenRe/2+1:end,iCRx,iCTx,iCA).*vWinRe(iLenRe/2+1:end);
      end
    end
  end
end

%% correct center position
fCenterPos = mean(stBRIR.vAngleSource(1:2));
vAngle = vAngle - fCenterPos;
disp(['Correct center position by: ',num2str(fCenterPos),'°'])

%% filter length should be power of two
mIRInt = [mIRInt;zeros(2^nextpow2(iFiltLen)-size(mIRInt,1),size(mIRInt,2),size(mIRInt,3),size(mIRInt,4))];
load TestBeneData.mat
addpath('utils');
iFiltLen  = 2^15;
mIRInt    = mIRInt(1:iFiltLen,:,:,:);

%% read file parameters
frameLength   = 2^9;
fUpdateTime   = frameLength/44.1e3;
disp(['Packet length [ms]: ',num2str(fUpdateTime*1e3)]);

vAngleSave  = 2*[1:1:1e4];%zeros(1e4,1);

%% real-time processing
iNoIter = 1;%frameLength;
mReg    = zeros(size(mIRInt,1)-1,2,iNoTx);
mHelp   = zeros(frameLength/iNoIter,iNoTx,2);
mReg2   = zeros(size(mIRInt,1)-1,2,iNoTx);
mHelp2  = zeros(frameLength/iNoIter,iNoTx,2);
mOut    = zeros(frameLength,2);
mOut2   = zeros(frameLength,2);
%
mRegC2  = zeros(size(mIRInt,1)-1,iNoTx);
mInLong     = zeros(frameLength+size(mIRInt,1)-1,2);

bGPUon  = true;
if bGPUon
  mRegGPU    = gpuArray(mReg);
  mOutGPU    = gpuArray(mOut);
  mHelpGPU   = gpuArray(mHelp);
end

disp('Real-time convolving starts')
iCount      = 0;
% tic;
iNoRuns     = 5000;
mFile       = randn(frameLength,2,iNoRuns);
vSum        = zeros(1,iNoRuns);


vWeightsUp    = [1:frameLength].'/frameLength;
mWeightsUp    = repmat(vWeightsUp,1,2);
mWeightsDown  = 1-mWeightsUp;




while iCount < iNoRuns
  
  iCount = iCount + 1;
  
  %% read data
  mIn       = mFile(:,:,iCount);
  
  %% find angle
  fAngle    = vAngleSave(iCount);
  [~,iInd]  = min(abs(vAngle-fAngle));
  mIR       = mIRInt(:,:,:,iInd);
  
  %% piecewise filtering interpolated
  if iCount>2
    vAngleFine      = interp1([0:1],vAngleSave(iCount-1:iCount),[1:iNoIter]/iNoIter);
  else
    vAngleFine      = vAngleSave(1)*ones(iNoIter,1);
  end


  vAngleInd  = zeros(1,iNoIter);
  for iCFine=1:iNoIter    
    [~,vAngleInd(iCFine)] = min(abs(vAngle-vAngleFine(iCFine)));
  end
%   tic;  
  %% Implementation in Matlab
  if iCount>2
    [~,iAngleIndOld] = min(abs(vAngle-vAngleSave(iCount-1)));
  else
    [~,iAngleIndOld] = min(abs(vAngle-vAngleSave(iCount)));
  end  

%   for iCFine=1:iNoIter
%     vIndFine      = (iCFine-1)*frameLength/iNoIter+1:iCFine*frameLength/iNoIter;
%     mInFine       = mIn(vIndFine,:);
%     parfor iCRx=1:2
%       for iCTx=1:iNoTx
%         [mHelp(:,iCRx,iCTx),mReg(:,iCRx,iCTx)] = ...
%           filter(mIRInt(:,iCRx,iCTx,vAngleInd(iCFine)),1,mInFine(:,iCTx),mReg(:,iCRx,iCTx));
%       end
%     end    
%     mOut(vIndFine,:) = sum(mHelp,3);
%     
%     parfor iCRx=1:2
%       for iCTx=1:iNoTx
%         [mHelp2(:,iCRx,iCTx),mReg2(:,iCRx,iCTx)] = ...
%           filter(mIRInt(:,iCRx,iCTx,iAngleIndOld),1,mInFine(:,iCTx),mReg2(:,iCRx,iCTx));
%       end
%     end    
%     mOut2(vIndFine,:) = sum(mHelp2,3);    
%     
%     mOut = mWeightsDown.*mOut + mWeightsUp.*mOut2;
%   end
  
  
  %% Implementation in C
%   [mHelp,mReg]  = FilterRealizer(mIRInt,mIn,mReg,vAngleInd-1);
%   mOut          = sum(mHelp,3);

  %% Implementation 2 in C
%   mInLong   = circshift(mInLong,frameLength);
%   mInLong(1:frameLength,:) = mIn;
%   mHelp     = FilterRealizer1(mIRInt,mInLong,vAngleInd-1);
%   mOut      = sum(mHelp,3);
%   mRegC2    = circshift(mRegC2,frameLength);
%   mRegC2(1:frameLength,:) = mIn;
    
%   vSum(iCount) = toc;
  
  %% GPU
  if bGPUon
    tic;
    for iCFine=1:iNoIter
      [~,iAngleInd] = min(abs(vAngle-vAngleFine(iCFine)));
      mIRFine       = mIRInt(:,:,:,iAngleInd);
      vIndFine      = (iCFine-1)*frameLength/iNoIter+1:iCFine*frameLength/iNoIter;
      mInFine       = mIn(vIndFine,:);
      for iCRx=1:2
        for iCTx=1:iNoTx
          [mHelpGPU(:,iCRx,iCTx),mRegGPU(:,iCRx,iCTx)] = ...
            filter(mIRFine(:,iCRx,iCTx),1,mInFine(:,iCTx),mRegGPU(:,iCRx,iCTx));
        end
      end
      mOutGPU(vIndFine,:) = sum(mHelpGPU,3);
    end
    toc;
  end
end
disp(['Run time - average [ms]: ',num2str(mean(vSum)*1e3)]);
disp(['Run time - max [ms]:     ',num2str(max(vSum)*1e3)]);
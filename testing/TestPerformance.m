if ~exist('mIRInt','var')
  load('utils/ActiveFilter.mat');  
  sDirName        = [sSetup,'/',sBRIRName];
  frameLength     = 2^9;
  iFiltLen        = 2^14-frameLength+1;
  [mIRInt,vAngle] = PrepareRealTimeProc(sDirName,iFiltLen);
  disp(sBRIRName);
end
iNoTx   = size(mIRInt,3);
fid     = fopen('utils/AngleRange.txt','w');
fprintf(fid,'%f',max(abs(vAngle)));
fclose(fid);

%% Read file parameters
iNoIter       = 1;% frameLength;


%% Real-time processing
% for speaker implementation
iDelay        = 50;
vIR           = [1,zeros(1,iDelay+1)];
mReg          = zeros(length(vIR)-1,iNoTx);

% for fading implementation
vWeightsUp    = [1:frameLength/iNoIter].'/(frameLength/iNoIter);
% vWeightsUp(1:frameLength/iNoIter) = sin([1:frameLength/iNoIter].'/(frameLength/iNoIter)*pi/2).^2;
mWeightsUp    = repmat(vWeightsUp,1,2);
mWeightsDown  = 1-mWeightsUp;

% for frequency-domain filtering
M       = frameLength;
N       = size(mIRInt,1);
K       = 2^ceil(log2(N+M-1));
mTFInt  = fft(mIRInt,K,1);
% mOutReg = zeros(K/M,K,2,iNoTx);
mOutReg = zeros(K/M,K,iNoTx);
mOut    = zeros(frameLength,2);
mOutCur = zeros(frameLength,2);
mOutOld = zeros(frameLength,2);
disp('Real-time convolving starts')
iCount        = 0;
bHeadphone    = true;

mInputFile    = randn(frameLength,2,10000);
vSum          = zeros(10000,1);

while iCount<10000%toc<3600
  tic;
  iCount = iCount + 1;
  

  
  %% read data
  mIn     = mInputFile(frameLength,2,iCount);
  
  if ~bHeadphone % headphone is off
    clc;
    fprintf('Headphone is off!\n');
    for iCTx=1:iNoTx
      [mOut(:,iCTx),mReg(:,iCTx)] = filter(vIR,1,mIn(:,iCTx),mReg(:,iCTx));
    end
  else   
   
    %% Frequency-domain MATLAB implementation
    fAngleHor             = 0;
    vAngleHorSave(iCount) = fAngleHor;
    [~,iAngleIndOld]      = min(abs(vAngle-vAngleHorSave(max(iCount-1,1))));
    [~,iAngleIndCur]      = min(abs(vAngle-fAngleHor)); 
    
%     tic;
    
    % get old and current TF
    mTFOld            = mTFInt(:,:,:,iAngleIndOld);
    mTFCur            = mTFInt(:,:,:,iAngleIndCur);
    mInFFT            = fft(mIn,K,1);

    mTFOld            = permute(mTFOld(:,1,:)+1i*mTFOld(:,2,:),[1,3,2]);
    mTFCur            = permute(mTFCur(:,1,:)+1i*mTFCur(:,2,:),[1,3,2]);

%     P = K/2/M;
%     Y0         = mTFOld.*mInFFT;
%     Y1         = mTFCur.*mInFFT;
%     Y          = 1/4*(2*Y0-circshift(Y0,P)-circshift(Y0,-P)+...
%       2*Y1+circshift(Y1,P)+circshift(Y1,-P));
    
    % circular pointer
    iCircPoint                = mod(1-iCount,K/M)+1;    
%     mOutReg(iCircPoint,:,:)   = ifft(Y,K,1);
    mOutReg(iCircPoint,:,:)   = ifft(mTFOld.*mInFFT,K,1);
    
    mMat                      = zeros(K/M,M,iNoTx);
    for iCB = 1:K/M
      iCBPt           = mod(iCircPoint+(iCB-1)-1,K/M)+1;
      mMat(iCBPt,:,:) = mOutReg(iCBPt,(iCB-1)*M+1:iCB*M,:);
    end
    mMatSum   = squeeze(sum(mMat,1));
    mOutOld(:,1) = sum(real(mMatSum),2);
    mOutOld(:,2) = sum(imag(mMatSum),2);
    
    mOutReg(iCircPoint,:,:)   = ifft(mTFCur.*mInFFT,K,1);
    % update mMat (only where changes occured)
    mMatSum   = mMatSum-squeeze(mMat(iCircPoint,:,:,:))...
      +squeeze(mOutReg(iCircPoint,1:M,:,:));
    mOutCur(:,1) = sum(real(mMatSum),2);
    mOutCur(:,2) = sum(imag(mMatSum),2);    
    
    % combine old and current contribution
    mOut    = mWeightsDown.*mOutOld + mWeightsUp.*mOutCur;
    
    % Preamplifier
    mOut    = 1.1*mOut;
  end
  vSum(iCount) = toc;

end
toc;
disp(['Run time - average [ms]: ',num2str(mean(vSum)*1e3)]);
disp(['Run time - max [ms]:     ',num2str(max(vSum)*1e3)]);
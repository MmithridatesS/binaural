if ~exist('mIRInt','var')
  load('utils/ActiveFilter.mat');  
  frameLength     = 2^9;
  iFiltLen        = 2^14-frameLength+1;
  [mIRInt,vAngle] = PrepareRealTimeProc(sBRIRName,iFiltLen);
  disp(sBRIRName);
end
iNoTx   = size(mIRInt,3);
fid     = fopen('utils/AngleRange.txt','w');
fprintf(fid,'%f',max(abs(vAngle)));
fclose(fid);

%% Read file parameters
iNoIter       = 1;% frameLength;

%% Set audio interface
sAudioInterface = 'Babyface';
SetAudioInterface;

fUpdateTime   = frameLength/fileReader.SampleRate;
disp(['Packet length [ms]: ',num2str(fUpdateTime*1e3)]);

%% Network parameters
if ~isempty(instrfindall)
  fclose(instrfindall);
end
vSerial   = seriallist;
iBaudrate = 38400;%115200; 
oSerial = serial(vSerial(2),'Baudrate',iBaudrate);
set(oSerial,'InputBufferSize',256);
fopen(oSerial);

% wait until buffer is filled
while (oSerial.BytesAvailable<36)
  pause(0.25);
end
for iC = 1:1000
  if (oSerial.BytesAvailable>=36)
    [fAngleHorRef,fAngleVerRef] = ReadAngles(oSerial);
  end
end
% initial angles 
fAngleHorRef    = mod(fAngleHorRef-180,360)-180;
fAngleVerRef    = mod(fAngleVerRef-180,360)-180;
fAngleHor       = fAngleHorRef;
fAngleVer       = fAngleVerRef;

%% Real-time processing
% mReg    = zeros(size(mIRInt,1)-1,2,iNoTx);
% mHelp   = zeros(frameLength/iNoIter,2,iNoTx);
mOut    = zeros(frameLength,2);

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
M         = frameLength;
N         = size(mIRInt,1);
K         = 2^ceil(log2(N+M-1));
mTFInt    = fft(mIRInt,K,1);
mOutReg   = zeros(K/M,K,2,iNoTx);

% debugging
vAngleHorSave   = zeros(1,1e5);
vAngleHorSerial = zeros(1,1e5);
vRunTime        = zeros(1,1e5);

disp('Real-time convolving starts')
iCount        = 0;
bHeadphone    = true;

tic;
while iCount<10000% toc<10
  
  iCount = iCount + 1;
  
  % update angles if possible
%   iNoBytesAvailable = oSerial.BytesAvailable;
%   if iNoBytesAvailable>=36  
  if oSerial.BytesAvailable>=36
    [fAngleHorNew,fAngleVerNew] = ReadAngles(oSerial);
    fAngleVer           = mod(fAngleVerNew-fAngleVerRef-180,360)-180;
    fAngleHor           = mod(fAngleHorNew-fAngleHorRef-180,360)-180;
    vAngleHorSerial(iCount) = fAngleHor;
  else
    vAngleHorSerial(iCount) = -1;
  end
  
  % calibrate if wantend
  if mod(iCount,100)==0
    if exist('utils/CalibrateOn.txt','file')
      % reset ref angles
      fAngleHorRef = fAngleHor+fAngleHorRef;
      fAngleVerRef = fAngleVer+fAngleVerRef;
      delete('utils/CalibrateOn.txt');
    end
  end
  
  % check whether toggle between headphone and loudspeakers
  if mod(iCount,5)==1
    if bHeadphone
      if fAngleVer<-40
        bHeadphone    = false;
        release(deviceWriterActive);
        deviceWriterActive = deviceWriterSpeaker;
        mReg   = zeros(length(vIR)-1,iNoTx);
        mOut   = zeros(frameLength,iNoTx);
      end
      fid = fopen('utils/Angles.txt','w');
      fprintf(fid,'%+09.4f\n',fAngleHor);
      fprintf(fid,'%+09.4f',fAngleVer);
      fclose(fid);

    else % Speakers are on
      if fAngleVer>-45
        bHeadphone    = true;
        release(deviceWriterActive);
        deviceWriterActive = deviceWriterHeadphone;      
      end
    end
  end
  
  %% read data
  mIn     = fileReader();
  
  if ~bHeadphone % headphone is off
    clc;
    fprintf('Headphone is off!\n');
    for iCTx=1:iNoTx
      [mOut(:,iCTx),mReg(:,iCTx)] = filter(vIR,1,mIn(:,iCTx),mReg(:,iCTx));
    end
  else
    
    %% Get angle and choose interpolated IR
    if mod(iCount,5)==1
      clc;
      fprintf('Binaural Synthesizer\n');
      fprintf('====================\n\n');
      fprintf('Room:      %s\n',sRoomName);
      fprintf('Headphone: %s\n\n',sHeadphoneName);
      if abs(fAngleHor) > max(abs(vAngle))
        fprintf('Headphone is ON!\n');
        fprintf('Horizontal orientation: %3.2f°\n',fAngleHor);
        fprintf('Out of range\n');
        fprintf('Vertical orientation:   %3.2f°\n',fAngleVer);
      else
        fprintf('Headphone is ON!\n');
        fprintf('Horizontal orientation: %3.2f°\n',fAngleHor);
        fprintf('Vertical orientation:   %3.2f°\n',fAngleVer);
      end
    end
    
   
    %% Frequency-domain MATLAB implementation
    vAngleHorSave(iCount) = fAngleHor;
    [~,iAngleIndOld]      = min(abs(vAngle-vAngleHorSave(max(iCount-1,1))));
    [~,iAngleIndCur]      = min(abs(vAngle-fAngleHor)); 
    
    tic;
    
    % get old and current TF
    mTFOld            = mTFInt(:,:,:,iAngleIndOld);
    mTFCur            = mTFInt(:,:,:,iAngleIndCur);
    mInFFT            = fft(mIn,K,1);
    mInFFTExt         = permute(repmat(mInFFT,[1,1,2]),[1,3,2]);

    % circular pointer
    iCircPoint                = mod(1-iCount,K/M)+1;
    mOutReg(iCircPoint,:,:,:) = ifft((mTFCur+1i*mTFOld).*mInFFTExt,K,1);
    mMat                      = zeros(K/M,M,2,iNoTx);
    for iCB = 1:K/M
      iCBPt             = mod(iCircPoint+(iCB-1)-1,K/M)+1;
      mMat(iCBPt,:,:,:) = real(mOutReg(iCBPt,(iCB-1)*M+1:iCB*M,:,:));
    end
    mMatSum   = squeeze(sum(mMat,1));
    mOutCur   = sum(mMatSum,3);    
    % update mMat (only where changes occured)
    mMatSum   = mMatSum-squeeze(mMat(iCircPoint,:,:,:))...
      +squeeze(imag(mOutReg(iCircPoint,1:M,:,:)));
    mOutOld   = sum(mMatSum,3);      
    
    % combine old and current contribution
    mOut    = mWeightsDown.*mOutOld + mWeightsUp.*mOutCur;
    
    % Preamplifier
    mOut    = 1.1*mOut;
    
    vRunTime(iCount) = toc;

    %% save for debugging
%     mOutSave(:,iCount,:) = mOut;

  end
  nUnderrun = play(deviceWriterActive,mOut);
  if nUnderrun > 0
    fprintf('Audio writer queue was underrun by %d samples.\n',...
      nUnderrun);
  end
end
release(fileReader);
release(deviceWriter);
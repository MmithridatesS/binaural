%% BRIR setup
addpath('utils');
frameLength     = 2^7;
iFiltLen        = 2^16;

%% Initialize NUPOLS
% sFilterName = 'AKG712_2.0_3D_Home' % 1: -30° nach unten, 2: 0°, 3: 30° nach oben
% sFilterName = 'HD800_5.1_3D_Home' % 1: -30° nach unten, 2: 0°, 3: 30° nach oben
% sFilterName = 'IE300_5.1_2D_Office'
% sFilterName = 'Room_Seminarraum_weit_N_220922_HP_HD650_2'
% sFilterName = 'HD800_5.1_2D_weit'
sFilterName = 'Room_Seminarraum_nah_längs_P_270922_HP_HD650_2';
load(['filters/',sFilterName,'.mat']);

sRoomName1 = sRoomName;
sHeadphoneName1 = sHeadphoneName;
iNoTx = size(mIRInt,3);
iNoAngleEl = size(mIRInt,5);
vTxInd = 1:iNoTx;
[H1tp,mFDL_buf1_old,mFDL_buf1_cur,x_in_buf1_old,x_in_buf1_cur,iC1,...
  H2tp,mFDL_buf2_old,mFDL_buf2_cur,x_in_buf2_old,x_in_buf2_cur,iC2,...
  H3tp,mFDL_buf3_old,mFDL_buf3_cur,x_in_buf3_old,x_in_buf3_cur,iC3,...
  H4tp,mFDL_buf4_old,mFDL_buf4_cur,x_in_buf4_old,x_in_buf4_cur,iC4,...
  x_ring,y_ring_cur,y_ring_old,B,Bi,Pi,N_RB_x,N_RB_y,N,...
  vBlockDelay,vSchedOffset]...
  = InitializeNUPOLS(frameLength,mIRInt);
H1 = H1tp(:,:,:,:,:,(iNoAngleEl+1)/2);
H2 = H2tp(:,:,:,:,:,(iNoAngleEl+1)/2);
H3 = H3tp(:,:,:,:,:,(iNoAngleEl+1)/2);
H4 = H4tp(:,:,:,:,:,(iNoAngleEl+1)/2);
if iNoAngleEl > 1
  disp('ELevation correction active');
else
  disp('Elevation correction inactive');
end
%clear mIRInt;

%% Initialize NUPOLS
% sFilterName = 'Netflix_HD800' % 5.1, solide
% sFilterName = 'Room_BA245_220831_HP_HD650'
sFilterName = 'Room_TIW_weit_HP_HD650';
load(['filters/',sFilterName,'.mat']);

sRoomName2 = sRoomName;
sHeadphoneName2 = sHeadphoneName;
iNoTx = size(mIRInt,3);
iNoAngleEl = size(mIRInt,5);
vTxInd = 1:iNoTx;
[H1tp2,mFDL_buf1_old2,mFDL_buf1_cur2,x_in_buf1_old2,x_in_buf1_cur2,iC1,...
  H2tp2,mFDL_buf2_old2,mFDL_buf2_cur2,x_in_buf2_old2,x_in_buf2_cur2,iC2,...
  H3tp2,mFDL_buf3_old2,mFDL_buf3_cur2,x_in_buf3_old2,x_in_buf3_cur2,iC3,...
  H4tp2,mFDL_buf4_old2,mFDL_buf4_cur2,x_in_buf4_old2,x_in_buf4_cur2,iC4,...
  x_ring2,y_ring_cur2,y_ring_old2,B,Bi,Pi,N_RB_x,N_RB_y,N,...
  vBlockDelay,vSchedOffset]...
  = InitializeNUPOLS(frameLength,mIRInt);
H12 = H1tp2(:,:,:,:,:,(iNoAngleEl+1)/2);
H22 = H2tp2(:,:,:,:,:,(iNoAngleEl+1)/2);
H32 = H3tp2(:,:,:,:,:,(iNoAngleEl+1)/2);
H42 = H4tp2(:,:,:,:,:,(iNoAngleEl+1)/2);
if iNoAngleEl > 1
  disp('ELevation correction active');
else
  disp('Elevation correction inactive');
end
clear mIRInt;

%% Parameter setup
fSamplFreq = 44.1e3;
% display options
fUpdateTime  = frameLength/fSamplFreq;
iNoIterShowDisplay = floor(0.5/fUpdateTime); % each 0.5s
bShowDisplay = true;

%% Set audio interface
if ispc
  sDriverName = 'ASIO';
else % macOS
  sDriverName = 'CoreAudio';
end
sAudioInterface = 'Babyface'; % 'Banana'
% sAudioInterface = 'Fireface'; % 'Banana'
[fileReader,deviceWriterHeadphone,deviceWriterSpeaker] = ...
  SetAudioInterface2f(sAudioInterface,sDriverName,frameLength,iNoTx,fSamplFreq);
deviceWriterActive = deviceWriterHeadphone;

%% Initialize UDP receiver for headtracker
if exist('u','var')
  clear u
end
echoudp("off")
if ispc
  echoudp("on",5005)
else % macOS
  echoudp("on",5006)
end
u = udpport("datagram",'LocalHost','127.0.0.1','LocalPort',5005);

%% Initialize counters etc.
iCount        = 0;
fAngleHor     = 0;
fAngleVer     = 0;
vAngleHorSave = zeros(1,1e3,'single');
vAngleHorPred = zeros(1,1e3,'single');
bHeadphone    = true; % start with headphone ON
iCountMax     = 0;
fMaxAmpl      = 0;
iRunTimeLen   = 100000;
vRunTime      = zeros(1,iRunTimeLen,'single');
vUnderrun     = false(1,iRunTimeLen);

% For speaker implementation
iDelay        = 50;
vIR           = [zeros(1,iDelay+1),1];
mReg          = zeros(length(vIR)-1,iNoTx);
% For fading implementation: Output is calculated twice (old/current) and
% mixed
vWeightsUp    = (1:frameLength).'/frameLength;
mWeightsUp    = repmat(vWeightsUp,1,2);
mWeightsDown  = 1-mWeightsUp;


%% Real-time processing
disp('Real-time convolving starts ... ')
while true % endless

  iCount = iCount + 1;

  %% Toggle filter
  if mod(iCount,20)==1
    if exist('status/FilterNumber.txt','file')
      fid             = fopen('status/FilterNumber.txt', 'r');
      sNumber         = fscanf(fid,'%c',[1]);
      iFiltNo         = uint8(str2double(sNumber));
      fclose(fid);
    end
  end

  %% Receiving headtracker data via UDP
  if u.NumDatagramsAvailable > 0
    data = read(u,u.NumDatagramsAvailable,"char");
    sAngleNew = data(end).Data;
    fAngleHor = str2double(sAngleNew(1:8));
    fAngleVer = str2double(sAngleNew(9:16));
  end
  % Kalman filtering of raw data will be added here later
  vAngleHorPred(mod(iCount-1,length(vAngleHorPred))+1) = fAngleHor;
  
  %% Toggle between headphone and loudspeakers
  if mod(iCount,5)==1
    if bHeadphone
      if fAngleVer<-50
        bHeadphone = false;
        release(deviceWriterActive);
        deviceWriterActive = deviceWriterSpeaker;
        mReg   = zeros(length(vIR)-1,iNoTx);
        mOut   = zeros(frameLength,iNoTx);
      end
    else % Speakers are on
      if fAngleVer>-55
        bHeadphone = true;
        release(deviceWriterActive);
        deviceWriterActive = deviceWriterHeadphone;
      end
    end
  end

  %% Read data
  mIn       = fileReader();

  %% Check whether headphone is on
  tic; % for performance analysis
  if ~bHeadphone
    %% Headphone is OFF
    mOut = zeros(frameLength,iNoTx);
    if bShowDisplay && mod(iCount,iNoIterShowDisplay)==1
      PrintStatus2f(sRoomName1,sHeadphoneName1,sRoomName2,sHeadphoneName2,iFiltNo,'OFF');
    end
    for iCTx=1:iNoTx
      [mOut(:,iCTx),mReg(:,iCTx)] = filter(vIR,1,mIn(:,iCTx),mReg(:,iCTx));
    end
    if iNoTx == 6
      mOutMap(:,1) = mOut(:,1) + mOut(:,3)/2 + mOut(:,4)/2 + mOut(:,5);
      mOutMap(:,2) = mOut(:,2) + mOut(:,3)/2 + mOut(:,4)/2 + mOut(:,6);
      mOut = mOutMap;
    end
    if strcmp(sAudioInterface,'Fireface')
      if iFiltNo == 2
        mOut(:,3:4) = mOut;
        mOut(:,1:2) = zeros(frameLength,2);
      else
        mOut(:,3:4) = zeros(frameLength,2);
      end
    end
  else
    %% Headphone is ON
    if bShowDisplay && mod(iCount,iNoIterShowDisplay)==1
      PrintStatus2f(sRoomName1,sHeadphoneName1,sRoomName2,sHeadphoneName2,iFiltNo,'ON',N,...
        iNoTx,fAngleHor,fAngleVer,vAngle,vRunTime,vUnderrun,fUpdateTime,iCount);
    end

    %% Frequency-domain real-time convolution
    iCMod                 = 1+mod(iCount-1,length(vAngleHorSave));
    vAngleHorSave(iCMod)  = fAngleHor; % save angle for debugging
    [~,iAngleIndOld]      = min(abs(vAngle-vAngleHorPred(1+mod(iCMod-2,length(vAngleHorSave)))));
    [~,iAngleIndCur]      = min(abs(vAngle-vAngleHorPred(iCMod)));

    %% Update ring buffer
    iCircPt_x             = mod(iCount-1,N_RB_x)+1;
    iCircPt_y             = mod(iCount-1,N_RB_y)+1;
    x_ring(:,iCircPt_x,:) = mIn;
    iCircPt_y_Del                 = mod(iCircPt_y-1-1,N_RB_y)+1;
    y_ring_old(:,iCircPt_y_Del,:) = 0;
    y_ring_cur(:,iCircPt_y_Del,:) = 0;

    %% SEGMENT 1
    if mod(iCount,Bi(1)/B==0) % when it is available, here every block
      iC1 = iC1 + 1;
      vInd1_x = iCircPt_x;
      mIn     = x_ring(:,vInd1_x,:);
      if iNoAngleEl > 1
        vIndUpdate = [iAngleIndOld,iAngleIndCur];
        if iFiltNo == 2
          H12(:,:,:,:,vIndUpdate) = interpElevation(H1tp2(:,:,:,:,vIndUpdate,:),vAngleVer,fAngleVer);
        else
          H1(:,:,:,:,vIndUpdate) = interpElevation(H1tp(:,:,:,:,vIndUpdate,:),vAngleVer,fAngleVer);
        end
      end
      if iFiltLen == 2
        [y_part1_old,x_in_buf1_old,mFDL_buf1_old] = UPConv(mIn,x_in_buf1_old,mFDL_buf1_old,vTxInd,H12,iC1,iAngleIndOld,Bi(1),Pi(1));
        [y_part1_cur,x_in_buf1_cur,mFDL_buf1_cur] = UPConv(mIn,x_in_buf1_cur,mFDL_buf1_cur,vTxInd,H12,iC1,iAngleIndCur,Bi(1),Pi(1));
      else
        [y_part1_old,x_in_buf1_old,mFDL_buf1_old] = UPConv(mIn,x_in_buf1_old,mFDL_buf1_old,vTxInd,H1,iC1,iAngleIndOld,Bi(1),Pi(1));
        [y_part1_cur,x_in_buf1_cur,mFDL_buf1_cur] = UPConv(mIn,x_in_buf1_cur,mFDL_buf1_cur,vTxInd,H1,iC1,iAngleIndCur,Bi(1),Pi(1));
      end
      vInd1_y = iCircPt_y;
      y_ring_old(:,vInd1_y,:) = y_ring_old(:,vInd1_y,:) + reshape(y_part1_old,B,Bi(1)/B,[]);
      y_ring_cur(:,vInd1_y,:) = y_ring_cur(:,vInd1_y,:) + reshape(y_part1_cur,B,Bi(1)/B,[]);
    end
    %% SEGMENT 2
    if numel(Bi)>1 && mod(iCount,Bi(2)/B)==0 % when it is available
      iC2 = iC2 + 1;
      vInd2_x = mod(iCircPt_x+(-Bi(2)/B+1:0)-1,N_RB_x)+1;
      mIn     = reshape(x_ring(:,vInd2_x,:),Bi(2),[]);
      if iNoAngleEl > 1
        if iFiltNo == 2
          H22(:,:,:,:,vIndUpdate) = interpElevation(H2tp2(:,:,:,:,vIndUpdate,:),vAngleVer,fAngleVer);
        else
          H2(:,:,:,:,vIndUpdate) = interpElevation(H2tp(:,:,:,:,vIndUpdate,:),vAngleVer,fAngleVer);
        end
      end
      if iFiltNo == 2
        [y_part2_old,x_in_buf2_old,mFDL_buf2_old] = UPConv(mIn,x_in_buf2_old,mFDL_buf2_old,vTxInd,H22,iC2,iAngleIndOld,Bi(2),Pi(2));
        [y_part2_cur,x_in_buf2_cur,mFDL_buf2_cur] = UPConv(mIn,x_in_buf2_cur,mFDL_buf2_cur,vTxInd,H22,iC2,iAngleIndCur,Bi(2),Pi(2));
      else
        [y_part2_old,x_in_buf2_old,mFDL_buf2_old] = UPConv(mIn,x_in_buf2_old,mFDL_buf2_old,vTxInd,H2,iC2,iAngleIndOld,Bi(2),Pi(2));
        [y_part2_cur,x_in_buf2_cur,mFDL_buf2_cur] = UPConv(mIn,x_in_buf2_cur,mFDL_buf2_cur,vTxInd,H2,iC2,iAngleIndCur,Bi(2),Pi(2));
      end
      vInd2_y = mod(iCircPt_y+vBlockDelay(2)+(0:Bi(2)/B-1)-1,N_RB_y)+1;
      y_ring_old(:,vInd2_y,:) = y_ring_old(:,vInd2_y,:) + reshape(y_part2_old,B,Bi(2)/B,[]);
      y_ring_cur(:,vInd2_y,:) = y_ring_cur(:,vInd2_y,:) + reshape(y_part2_cur,B,Bi(2)/B,[]);
    end
    %% SEGMENT 3
    if numel(Bi)>2 && mod(iCount,Bi(3)/B)==0+vSchedOffset(3) % when it is available
      iC3 = iC3 + 1;
      vInd3_x = mod(iCircPt_x-vSchedOffset(3)+(-Bi(3)/B+1:0)-1,N_RB_x)+1;
      mIn     = reshape(x_ring(:,vInd3_x,:),Bi(3),[]);
      if iNoAngleEl > 1
        if iFiltNo == 2
          H32(:,:,:,:,vIndUpdate) = interpElevation(H3tp2(:,:,:,:,vIndUpdate,:),vAngleVer,fAngleVer);
        else
          H3(:,:,:,:,vIndUpdate) = interpElevation(H3tp(:,:,:,:,vIndUpdate,:),vAngleVer,fAngleVer);
        end
      end
      if iFiltNo == 2
        [y_part3_old,x_in_buf3_old,mFDL_buf3_old]  = UPConv(mIn,x_in_buf3_old,mFDL_buf3_old,vTxInd,H32,iC3,iAngleIndOld,Bi(3),Pi(3));
        [y_part3_cur,x_in_buf3_cur,mFDL_buf3_cur]  = UPConv(mIn,x_in_buf3_cur,mFDL_buf3_cur,vTxInd,H32,iC3,iAngleIndCur,Bi(3),Pi(3));
      else
        [y_part3_old,x_in_buf3_old,mFDL_buf3_old]  = UPConv(mIn,x_in_buf3_old,mFDL_buf3_old,vTxInd,H3,iC3,iAngleIndOld,Bi(3),Pi(3));
        [y_part3_cur,x_in_buf3_cur,mFDL_buf3_cur]  = UPConv(mIn,x_in_buf3_cur,mFDL_buf3_cur,vTxInd,H3,iC3,iAngleIndCur,Bi(3),Pi(3));
      end
      vInd3_y = mod(iCircPt_y-vSchedOffset(3)+vBlockDelay(3)+(0:Bi(3)/B-1)-1,N_RB_y)+1;
      y_ring_old(:,vInd3_y,:) = y_ring_old(:,vInd3_y,:) + reshape(y_part3_old,B,Bi(3)/B,[]);
      y_ring_cur(:,vInd3_y,:) = y_ring_cur(:,vInd3_y,:) + reshape(y_part3_cur,B,Bi(3)/B,[]);
    end
    %% SEGMENT 4
    if numel(Bi)>=4 && mod(iCount,Bi(4)/B)==0+vSchedOffset(4) % when it is available
      iC4 = iC4 + 1;
      vInd4_x = mod(iCircPt_x-vSchedOffset(4)+(-Bi(4)/B+1:0)-1,N_RB_x)+1;
      mIn     = reshape(x_ring(:,vInd4_x,:),Bi(4),[]);
      if iNoAngleEl > 1
        if iFiltNo == 2
          H42(:,:,:,:,vIndUpdate) = interpElevation(H4tp2(:,:,:,:,vIndUpdate,:),vAngleVer,fAngleVer);
        else
          H4(:,:,:,:,vIndUpdate) = interpElevation(H4tp(:,:,:,:,vIndUpdate,:),vAngleVer,fAngleVer);
        end
      end
      if iFiltNo == 2
        [y_part4_old,x_in_buf4_old,mFDL_buf4_old]  = UPConv(mIn,x_in_buf4_old,mFDL_buf4_old,vTxInd,H42,iC4,iAngleIndOld,Bi(4),Pi(4));
        [y_part4_cur,x_in_buf4_cur,mFDL_buf4_cur]  = UPConv(mIn,x_in_buf4_cur,mFDL_buf4_cur,vTxInd,H42,iC4,iAngleIndCur,Bi(4),Pi(4));
      else
        [y_part4_old,x_in_buf4_old,mFDL_buf4_old]  = UPConv(mIn,x_in_buf4_old,mFDL_buf4_old,vTxInd,H4,iC4,iAngleIndOld,Bi(4),Pi(4));
        [y_part4_cur,x_in_buf4_cur,mFDL_buf4_cur]  = UPConv(mIn,x_in_buf4_cur,mFDL_buf4_cur,vTxInd,H4,iC4,iAngleIndCur,Bi(4),Pi(4));
      end
      vInd4_y = mod(iCircPt_y-vSchedOffset(4)+vBlockDelay(4)+(0:Bi(4)/B-1)-1,N_RB_y)+1;
      y_ring_old(:,vInd4_y,:) = y_ring_old(:,vInd4_y,:) + reshape(y_part4_old,B,Bi(4)/B,[]);
      y_ring_cur(:,vInd4_y,:) = y_ring_cur(:,vInd4_y,:) + reshape(y_part4_cur,B,Bi(4)/B,[]);
    end

    %% Take block from ring buffer
    mOut_Old = squeeze(y_ring_old(:,iCircPt_y,:));
    mOut_Cur = squeeze(y_ring_cur(:,iCircPt_y,:));
    % Fading: Combine old and current output
    mOut = mWeightsDown.*mOut_Old + mWeightsUp.*mOut_Cur;

    %% Preamplifier
    mOut = 2 * mOut;
    fMaxAmpl  = max(max(abs(mOut(:))),fMaxAmpl);
    if bShowDisplay && mod(iCount,iNoIterShowDisplay)==1
      if fMaxAmpl>0.5
        iCountMax = iCountMax + 1;
        if iCountMax == 3000
          fMaxAmpl = 0;
          iCountMax = 0;
        end
        disp(['Critical maximal amplitude: ',num2str(fMaxAmpl)]);
      end
    end
    % save run time per iteration for speed analysis
    vRunTime(mod(iCount-1,length(vRunTime))+1) = toc;
  end
  %% Write data to output buffer
  nUnderrun = play(deviceWriterActive,mOut);
  vUnderrun(mod(iCount-1,length(vRunTime))+1) = false;
  if nUnderrun > 0
    fprintf('Audio writer queue was underrun by %d samples.\n',...
      nUnderrun);
    vUnderrun(mod(iCount-1,length(vRunTime))+1) = true;
  end
end
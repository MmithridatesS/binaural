function [mRecSig] = SingleMeasurementPRIR(stMeas,angle_horizontal, angle_vertical)
%S Summary of this function goes here
%   Detailed explanation goes here
%% read parameters and initialize audio device
addpath('utils'); SetParameters;
fSR = stSys.fSampFreq;

% Fireface UC
playRec = audioPlayerRecorder('Device','ASIO Fireface USB',...
  'PlayerChannelMapping',1:stMeas.iNoTx,'RecorderChannelMapping',1:2,...
  'SampleRate',fSR,'BitDepth','32-bit float');

%% prepare measurement
[mSweep,vInvSweep] = WriteLogSweep(stMeas.fFreqMin,stMeas.fFreqMax,stMeas.fDur,stMeas.fPause,0.5,fSR,64,'LSP',stMeas.vActTx);
fDur    = size(mSweep,1)/fSR;
disp(['Duration of sweep: ',num2str(fDur),' s']);
if stMeas.bVoiceOn
  Text2Speech('Lautsprecher-Messung: Drücken Sie eine beliebige Taste, um die Aufnahme zu starten.',[],1)
end
disp('Press any key to continue ...');
pause;

% Noise to indicate correct head position
mNoise           = zeros(fSR/2,stMeas.iNoTx);
mNoise(1:2048,:) = randn(2048,stMeas.iNoTx);

%% measurement
iPackLen  = 512;
iNoFr     = round(size(mSweep,1)/iPackLen);
iRem      = mod(size(mSweep,1),iPackLen);
mSweep    = [mSweep;zeros(iRem,size(mSweep,2))];
mRecSig = [];

%% Equidistant sampling
bEquidist = true;
if bEquidist
  if stMeas.bHeadtracker
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
  end
  %% bvoiceon is not supported
  % if stMeas.bVoiceOn....
  % else ...
  % end
  if stMeas.bHeadtracker
    bCorrectAngle = false;
    fAngleHor = 0;
    fAngleVer = 0;      
    while ~bCorrectAngle
        pause(0.05);
        if u.NumDatagramsAvailable > 0
          data = read(u,u.NumDatagramsAvailable,"char");
          bAngleNew = data(end).Data;
          fAngleHor = str2double(bAngleNew(1:8));
          fAngleVer = str2double(bAngleNew(9:16));
        end
        clc;
        fprintf('Target Elevation orientation:     %3.2f°\n',angle_vertical);
        fprintf('Target Azimuth orientation:     %3.2f°\n',angle_horizontal);
        fprintf('Horizontal orientation: %3.2f°\n',fAngleHor);
        fprintf('Vertical orientation:   %3.2f°\n',fAngleVer);
        fTolHor = 0.5; % tolerance window (azimuth)
        fTolVer = 5; % tolerance window (elevation)
        if abs(fAngleHor-angle_horizontal)<fTolHor/2 && abs(fAngleVer-angle_vertical)<fTolVer
          if stMeas.bVoiceOn
            Text2Speech('Ok',[],1);
          else
            disp('Ok')
            % play some loud noise as sign to stop head movement
            for iCF=1:floor(24000/iPackLen)
              vInd  = (iCF-1)*iPackLen+1:iCF*iPackLen;
              dummy = playRec(mNoise(vInd,:));
            end
          end 
          bCorrectAngle = true;
        end
    end 
  else 
    pause(1.0)
  end
  for iCF=1:iNoFr
    vInd = (iCF-1)*iPackLen+1:iCF*iPackLen;
    mRecSig(vInd,:) = playRec(mSweep(vInd,:));
  end
  if exist('fImbalance','var')
    mRecSig(:,1) = mRecSig(:,1)*fImbalance;
  end
  bDebugMode = true;
  if bDebugMode
    %sb = subplot(length(stRoomMeas.vAngleAzimuth),1,iC);
    plot((0:size(mRecSig,1)-1)/fSR,mRecSig(:,1)); hold on;
    plot((0:size(mRecSig,1)-1)/fSR,mRecSig(:,2),'r'); hold off;
    legend('ear 1','ear 2','Fontsize',6);
    if stMeas.bHeadtracker
      %title(['Target angle: ',num2str(stRoomMeas.vAngleAzimuth(iC)),'°, Angle (meas.): ',num2str(fAngleHor),'°']);
      text(0,0,['Target horizontal angle: ',num2str(angle_horizontal),'°, Angle (meas.): ',num2str(fAngleHor),'°']);
      text(0,0,['Target vertical angle: ',num2str(angle_vertical),'°, Angle (meas.): ',num2str(fAngleVer),'°']);
    else
      title(['Target horizontal angle: ',num2str(angle_horizontal)]);
      title(['Target vertical angle: ',num2str(angle_vertical)]);
    end
    ylabel('r(t)'); grid on;
    %if iC==length(stRoomMeas.vAngleAzimuth)
    %xlabel('Time [s]');
    %end
    %set(sb,'Fontsize',7)
  end
else
end
sFileName = ['measure/room/2.0/ds/Home_221025_left_right'];
load(sFileName,'measurementData');
measurementData.extra.mSweep = mSweep;
measurementData.extra.vInvSweep = vInvSweep;
save(sFileName,'measurementData');
end








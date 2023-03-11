function [] = MeasPRIR(sSetup,sRoomName,stMeas)
clc;
disp('PRIR measurements')
disp('=================')
%% read parameters and initialize audio device
addpath('utils'); SetParameters;
stRoomMeas.fSR = stSys.fSampFreq;
load('measure/calibration.mat','fImbalance');
fImbalance = 1;

% Babyface / Fireface UC
sDevice = 'Babyface Pro (71969190)';
%sDevice = 'ASIO Fireface USB';
playRec     = audioPlayerRecorder('Device',sDevice,...
  'PlayerChannelMapping',1:stMeas.iNoTx,'RecorderChannelMapping',1:2,...
  'SampleRate',stRoomMeas.fSR,'BitDepth','32-bit float');

%% Multiple head positions
stRoomMeas.iNoHeadPos = stMeas.iNoHeadPos;
stRoomMeas.iHeadRange = stMeas.iHeadRange;
stRoomMeas.iNoHeadPosE = stMeas.iNoHeadPosE; % Number of elavation positions
stRoomMeas.iHeadRangeE = stMeas.iHeadRangeE; % Range along elavation angle 
stRoomMeas.mAngles = ones(stRoomMeas.iNoHeadPosE,1)*linspace(-stRoomMeas.iHeadRange,stRoomMeas.iHeadRange,stRoomMeas.iNoHeadPos); % matrice with rows as azimuth measurements and columns as elavation measurements
% if stRoomMeas.iNoHeadPos == 1
%   stRoomMeas.vAngle = 0;
% else
%   stRoomMeas.vAngle  = ...
%     linspace(-stRoomMeas.iHeadRange,stRoomMeas.iHeadRange,stRoomMeas.iNoHeadPos);
% end

%% prepare measurement
[mSweep,vInvSweep] = WriteLogSweep(stMeas.fFreqMin,stMeas.fFreqMax,stMeas.fDur,stMeas.fPause,0.5,stRoomMeas.fSR,64,'LSP',stMeas.vActTx);
fDur    = size(mSweep,1)/stRoomMeas.fSR;
disp(['Duration of sweep: ',num2str(fDur),' s']);
if stMeas.bVoiceOn
  Text2Speech('Lautsprecher-Messung: Drücken Sie eine beliebige Taste, um die Aufnahme zu starten.',[],1)
end
disp('Press any key to continue ...');
pause;

% Noise to indicate correct head position
mNoise           = zeros(stRoomMeas.fSR/2,stMeas.iNoTx);
mNoise(1:2048,:) = randn(2048,stMeas.iNoTx);

%% measurement
iPackLen  = 512;
iNoFr     = round(size(mSweep,1)/iPackLen);
iRem      = mod(size(mSweep,1),iPackLen);
mSweep    = [mSweep;zeros(iRem,size(mSweep,2))];

bEquidist = true;
%% Equidistant sampling
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

  bRoomMeasRunning = true;
  iC = 1;
  while bRoomMeasRunning
%  for iC = 1:length(stRoomMeas.vAngle)
    for eAngle = 1:stRoomMeas.iNoHeadPosE % creating rows corresponding to elevation angles
        fMeasAngle = stRoomMeas.mAngle(eAngle,iC);
        fVMeasAngle = -stRoomMeas.iHeadRangeE+(eAngle-1)*(2*stRoomMeas.iHeadRange/(stRoomMeas.iNoHeadPosE-1)); 
        disp(['Head angle elavation: ',int2str(fVMeasAngle),'°']);
        disp(['Head angle azimuth: ',int2str(fMeasAngle),'°']);
        if stMeas.bVoiceOn
          if stRoomMeas.mAngle(eAngle,iC)>0
            Text2Speech(['Drehen Sie den Kopf auf ',int2str(fMeasAngle),'° nach links!'],[],1)
          elseif stRoomMeas.mAngle(eAngle,iC)<0
            Text2Speech(['Drehen Sie den Kopf auf ',int2str(-fMeasAngle),'° nach rechts!'],[],1)
          else
            Text2Speech(['Schauen Sie genau geradeaus!'])
          end
        else % no voice on
          if stRoomMeas.mAngle(eAngle,iC)>0
            disp(['Turn your head ',int2str(fMeasAngle),'° to the left!'])
          elseif stRoomMeas.mAngle(eAngle,iC)<0
            disp(['Turn your head ',int2str(-fMeasAngle),'° to the right!'])
          else
            disp(['Look straight ahead!'])
          end
        end
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
            fprintf('Target horizontal orientation:     %3.2f°\n',fMeasAngle);
            fprintf('Target vertical orientation:       %3.2f°\n',fVMeasAngle);
            fprintf('Horizontal orientation:            %3.2f°\n',fAngleHor);
            fprintf('Vertical orientation:              %3.2f°\n',fAngleVer);
            fTolHor = 2; % 0.5 tolerance window (azimuth)
            fTolVer = 10; % tolerance window (elevation)
            if abs(fAngleHor-fMeasAngle)<fTolHor/2 && abs(fAngleVer)<fTolVer
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
          pause(1.0);
        end
        for iCF=1:iNoFr
          vInd                                      = (iCF-1)*iPackLen+1:iCF*iPackLen;
          stRoomMeas.stMeasData(iC).mRecSig(vInd,:) = playRec(mSweep(vInd,:));
        end
        % mic calibration
        if exist('fImbalance','var')
          stRoomMeas.stMeasData(iC).mRecSig(:,1) = stRoomMeas.stMeasData(iC).mRecSig(:,1)*fImbalance;
        end
        bDebugMode = true;
        if bDebugMode
          figure(2)
          sb = subplot(length(stRoomMeas.vAngle),1,iC);
          plot((0:size(stRoomMeas.stMeasData(iC).mRecSig,1)-1)/stRoomMeas.fSR,stRoomMeas.stMeasData(iC).mRecSig(:,1)); hold on;
          plot((0:size(stRoomMeas.stMeasData(iC).mRecSig,1)-1)/stRoomMeas.fSR,stRoomMeas.stMeasData(iC).mRecSig(:,2),'r'); hold off;
          legend('ear 1','ear 2','Fontsize',6);
          if stMeas.bHeadtracker
            text(0,0,['Target angle: ',num2str(stRoomMeas.mAngle(eAngle,iC)),'°, Angle (meas.): ',num2str(fAngleHor),'°']);
          else
            title(['Target angle: ',num2str(stRoomMeas.mAngle(eAngle,iC))]);
          end
          ylabel('r(t)'); grid on;
          if iC==length(stRoomMeas.vAngle)
            xlabel('Time [s]');
          end
          set(sb,'Fontsize',7)
        end
        stRoomMeas.vAngleMeas(iC) = fAngleHor;
    
        % check whether measurement shall be repeated
        % large figure to check
        if bDebugMode
          figure(1)
          plot((0:size(stRoomMeas.stMeasData(iC).mRecSig,1)-1)/stRoomMeas.fSR,stRoomMeas.stMeasData(iC).mRecSig(:,1)); hold on;
          plot((0:size(stRoomMeas.stMeasData(iC).mRecSig,1)-1)/stRoomMeas.fSR,stRoomMeas.stMeasData(iC).mRecSig(:,2),'r'); hold off;
          legend('ear 1','ear 2','Fontsize',6);
          if stMeas.bHeadtracker
            text(0,0,['Target angle: ',num2str(stRoomMeas.mAngle(eAngle,iC)),'°, Angle (meas.): ',num2str(fAngleHor),'°']);
          else
            title(['Target angle: ',num2str(stRoomMeas.mAngle(eAngle,iC))]);
          end
          ylabel('r(t)'); grid on;
          if iC==length(stRoomMeas.vAngle)
            xlabel('Time [s]');
          end
          set(sb,'Fontsize',7)
        end
        reply = input('Repeat measurement? y/n [n]:','s');
        if isempty(reply) || reply ~= 'y'
          iC = iC+1;
        end
        if iC > size(stRoomMeas.vAngle,2) && eAngle == stRoomMeas.iNoHeadPosE
          bRoomMeasRunning = false;
        end
    end
  end
  
  %% irregular sampling (not supported right now!)
else
  stRoomMeas.vAngle = [];
  bStop = false;
  iC    = 0;
  while ~bStop
    disp('Press y to start a measurement of any other key to quit')
    w = waitforbuttonpress;
    if w && strcmp(get(gcf,'CurrentCharacter'),'y')
      close(gcf)
      iC        = iC+1;
      fid       = fopen('utils/Angles.txt', 'r');
      vAngleNew = str2num(fscanf(fid,'%c',[8,2]).');
      fclose(fid);
      % update angles if possible
      if numel(vAngleNew)>0
        fAngleHor = vAngleNew(1);
        if numel(vAngleNew)>1
          fAngleVer = vAngleNew(2);
        end
      else
        disp('No value');
      end
      clc;
      fprintf('Horizontal orientation: %3.2f°\n',fAngleHor);
      fprintf('Vertical orientation:   %3.2f°\n',fAngleVer);
      stRoomMeas.mAngle(eAngle,iC) = fAngleHor;
      for iCF=1:iNoFr
        vInd                                      = (iCF-1)*iPackLen+1:iCF*iPackLen;
        stRoomMeas.stMeasData(iC).mRecSig(vInd,:) = playRec(mSweep(vInd,:));
      end
      % mic calibration
      if exist('fImbalance','var')
        stRoomMeas.stMeasData(iC).mRecSig(:,1) = stRoomMeas.stMeasData(iC).mRecSig(:,1)*fImbalance;
      end
      bDebugMode = true;
      if bDebugMode
        plot([0:size(stRoomMeas.stMeasData(iC).mRecSig,1)-1]/stRoomMeas.fSR,stRoomMeas.stMeasData(iC).mRecSig(:,1)); hold on;
        plot([0:size(stRoomMeas.stMeasData(iC).mRecSig,1)-1]/stRoomMeas.fSR,stRoomMeas.stMeasData(iC).mRecSig(:,2),'r'); hold off;
        legend('left','right')
        title(['Angle (meas.): ',num2str(fAngleHor)]);
        xlabel('Time [s]'); ylabel('Amplitude'); grid on;
      end
    else
      close(gcf)
      bStop = true;
    end
  end
end
%%
disp('... measurements completed.');
if stMeas.bVoiceOn
  Text2Speech(['Die Raumvermessung ist abgeschlossen!'],[],1)
else
  disp(['Room measurements completed!'])
end
%% save data
sFileName = ['measure/room/',sSetup,'/',sRoomName];
if exist('sFileName','file')
  load(sFileName,'stRoomMeas');
end
stRoomMeas.vAngle     = stRoomMeas.vAngleMeas;
stRoomMeas.vActTx     = stMeas.vActTx;
stRoomMeas.mSweep     = mSweep;
stRoomMeas.vInvSweep  = vInvSweep;
save(sFileName,'stRoomMeas');
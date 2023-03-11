function [] = MeasHPIR(sHeadphoneName,stMeas)

clc;
disp('HPIR measurements')
disp('=================')
%% read parameters and initialize audio device
addpath('utils'); SetParameters;
stHPMeas.fSR = stSys.fSampFreq;
load('measure/calibration.mat','fImbalance');

% Fireface UC
% playRec     = audioPlayerRecorder('Device','ASIO Fireface USB',...
%   'PlayerChannelMapping',[7:8],'RecorderChannelMapping',[1:2],...
%   'SampleRate',stHPMeas.fSR,'BitDepth','32-bit float');

% Babyface
sDevice = 'Babyface Pro (71969190)';
playRec     = audioPlayerRecorder('Device',sDevice,...
  'PlayerChannelMapping',[3:4],'RecorderChannelMapping',[1:2],...
  'SampleRate',stHPMeas.fSR,'BitDepth','32-bit float');

%% Multiple measurements
stHPMeas.iNoHPMeas = stMeas.iNoHPMeas;

%% Headphone measurement
if stMeas.bVoiceOn
  Text2Speech('Setzen Sie nun den Kopfhörer auf.',[],1);
  Text2Speech('Drücken Sie eine beliebige Taste, um die Messung zu starten.',[],1);
else
  disp('Setzen Sie nun den Kopfhörer auf.');
  disp('Drücken Sie eine beliebige Taste, um die Messung zu starten.');  
end
disp('Press any key to continue ...');
pause;
clc;
disp('HPIR measurements')
disp('=================')
if stMeas.bVoiceOn
  if stMeas.iNoHPMeas == 1
    Text2Speech('Es folgt eine einzelne Messung.',[],1)
  else
    Text2Speech(['Es folgen ',int2str(stMeas.iNoHPMeas),' Messungen.'],[],1)
    Text2Speech('Variieren Sie die Kopfhörer-Position zwischen den Messungen.',[],1)
  end
else
  if stMeas.iNoHPMeas == 1
    disp('Es folgt eine einzelne Messung.')
  else
    disp(['Es folgen ',int2str(stMeas.iNoHPMeas),' Messungen.'])
    disp('Variieren Sie die Kopfhörer-Position zwischen den Messungen.')
  end
  
end
[mSweep,vInvSweep]  = WriteLogSweep(stMeas.fFreqMin,stMeas.fFreqMax,stMeas.fDur,stMeas.fPause,0.5,stHPMeas.fSR,64,'HP');
fDur                = size(mSweep,1)/stHPMeas.fSR; 
disp(['Duration of sweep: ',num2str(fDur),' s']);
iPackLen  = 256;
iNoFr     = round(size(mSweep,1)/iPackLen);
iRem      = mod(size(mSweep,1),iPackLen);
mSweep    = [mSweep;zeros(iRem,size(mSweep,2))];
for iC = 1:stHPMeas.iNoHPMeas
  disp(['Measurement No. ',int2str(iC)]);
  for iCF=1:iNoFr
    vInd                                    = (iCF-1)*iPackLen+1:iCF*iPackLen;
    stHPMeas.stMeasData(iC).mRecSig(vInd,:) = playRec(mSweep(vInd,:));
  end  
  if stHPMeas.iNoHPMeas>1
    disp('... single measurement completed');
    disp('Press any key to continue ...');
    pause;
  end
  % mic calibration
  if exist('fImbalance','var')
    stHPMeas.stMeasData(iC).mRecSig(:,1) = stHPMeas.stMeasData(iC).mRecSig(:,1)*fImbalance;
  end
  bDebugMode = true;
  if bDebugMode
    plot([0:size(stHPMeas.stMeasData(iC).mRecSig,1)-1]/stHPMeas.fSR,stHPMeas.stMeasData(iC).mRecSig(:,1)); hold on;
    plot([0:size(stHPMeas.stMeasData(iC).mRecSig,1)-1]/stHPMeas.fSR,stHPMeas.stMeasData(iC).mRecSig(:,2),'r'); hold off;
    xlabel('Time [s]'); ylabel('Amplitude'); grid on;
  end
end
disp('... measurements completed.');
if stMeas.bVoiceOn
  Text2Speech(['Die Kopfhörer-Messung ist abgeschlossen!'],[],1);
else
  disp(['Die Kopfhörer-Messung ist abgeschlossen!']);
end

%% Save data
sFileName = ['measure/headphone/',sHeadphoneName];
stHPMeas.mSweep     = mSweep;
stHPMeas.vInvSweep  = vInvSweep;
save(sFileName,'stHPMeas');
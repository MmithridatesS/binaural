function [mIR] = CalcPRIR(sSetup,sRoomName)

%% CHECK INPUT PARAMETERS
switch nargin
  case 2
    disp(' ');
    disp(['Calculating PRIR for dataset: ',sSetup,'/ds/',sRoomName])
  otherwise
    warning('Check number of input parameters!');
end

%% SET PARAMETERS
addpath('utils');
SetParameters;
iN              = stSys.iN;
iOffset         = stSys.iOffset;
fSampFreq       = stSys.fSampFreq;

load(['measure/room/',sSetup,'/ds/',sRoomName],'measurementData');
stPRIR.fSR      = fSampFreq;
stPRIR.Angles   = measurementData.Angles;
vInverse        = measurementData.extra.vInvSweep;

% read room correction filter
if bRoomCor
  mCorFilt        = audioread(['measure/room_correction/',sRoomCorName,'/Cor1S48.wav']);
end

%% DECONVOLUTION 
vActTxInt = find(measurementData.extra.vActTx);
iNoTx     = length(measurementData.extra.vActTx);
iNoActTx  = length(vActTxInt);

fHeadRadius  = stEnv.fHeadRadius;
fDist2Source = stEnv.fDist2Source;
vAngleSource = stEnv.vAngleSource;

disp('Coarse timing and ITD calculation ...');
iNoAngles   = length(measurementData.Angles);
mITDvsAngle = zeros(2,2,iNoAngles);
for iCA = 1:iNoAngles
  disp(['  for angle (azimuth, elevation): ',int2str(measurementData.Angles(1,iCA)),',',int2str(measurementData.Angles(2,iCA)),'°'])
  fAngle_head_azimuth   = measurementData.Angles(1,iCA);
  fAngle_head_elevation   = measurementData.Angles(2,iCA);
  mLogSweep_rec = measurementData.Data(iCA).mRecSig;
  iLen          = size(mLogSweep_rec,1);
  iLenPerSource = floor(iLen/iNoActTx);
  mLogSweep_rec = mLogSweep_rec(1:iLenPerSource*iNoActTx,:);
  mLogSweep_rec = reshape(mLogSweep_rec,iLen/iNoActTx,iNoActTx,2);
  mLogSweep_rec = permute(mLogSweep_rec,[1,3,2]);
  
  % convolution with inverse training signal
  mIR_long = zeros(size(mLogSweep_rec,1)+2*stSys.iN+1,2,iNoActTx); % extend by stSys.iN
  for iCRx = 1:2
    for iCTx = 1:iNoActTx
      vIR_long_tp             = fftfilt(vInverse,[mLogSweep_rec(:,iCRx,iCTx);zeros(2*stSys.iN+1,1)]);
      if bRoomCor
        mIR_long(:,iCRx,iCTx) = fftfilt(mCorFilt(:,iCTx),vIR_long_tp);
      else
        mIR_long(:,iCRx,iCTx) = vIR_long_tp;
      end
    end
  end
  mIR_long = mIR_long(stSys.iN+1:end,:,:);
%   clear mLogSweep_rec;  
  
  %% coarse timing
  [~,iIndMax1] = max(abs(mIR_long(:,1,1)));
  [~,iIndMax2] = max(abs(mIR_long(:,2,2)));
  iDiffAllowed = 1000;
  if abs(iIndMax1-iIndMax2)<iDiffAllowed
    mIR_long = mIR_long(min(iIndMax1,iIndMax2)-iDiffAllowed:end,:,:);
  else
    disp('Something went wrong - Maxima too wide apart');
    pause
  end  
    
  %% measured ITDs
  vITD_meas   = zeros(2,1);
  mTD_meas    = zeros(2,iNoTx);  
  mIR_aligned = zeros(size(mIR_long));
  for iCTx = 1:iNoActTx
    for iCRx = 1:2
      mTD_meas(iCRx,iCTx)       = ExtractTD(mIR_long(:,iCRx,iCTx),fRelThres,16);
      mIR_aligned(:,iCRx,iCTx)  = TimeShift(mIR_long(:,iCRx,iCTx),iOffset+1-mTD_meas(iCRx,iCTx));
    end
    vITD_meas(iCTx) = mTD_meas(2,iCTx)-mTD_meas(1,iCTx);
    mITDvsAngle(:,iCTx,iCA) = [-fAngle_head_azimuth;vITD_meas(iCTx)]; % find a way to nest fAngle_head_elevation
  end
  % save mIR
  stPRIR.Data(iCA).mIR = mIR_aligned(1:iN,:,:);
end
disp(' ');

figure
mITDvsCorrAngle = zeros(2,iNoTx,iNoAngles);
mITD_poly = zeros(2,iNoTx,iNoAngles);
pinv = zeros(iNoTx,5+1);
p = zeros(iNoTx,5+1);
vAngleSourceMeas = zeros(1,iNoTx);
bUseAngleSourceMeas = true;
sLegend = [];
for iCTx = 1:iNoTx
  % find estimate of Tx source angle
  pinv(iCTx,:) = polyfit(mITDvsAngle(2,iCTx,:),mITDvsAngle(1,iCTx,:),5);
  vAngleSourceMeas(iCTx) = -pinv(iCTx,end);
  if bUseAngleSourceMeas
    vAngleSource(iCTx) = vAngleSourceMeas(iCTx);
  end
  disp(['Speaker ',int2str(iCTx),' located at: ',num2str(vAngleSource(iCTx)),'°'])
  % consider Tx source angle
  mITDvsCorrAngle(1,iCTx,:) = vAngleSource(iCTx)+mITDvsAngle(1,iCTx,:);
  mITDvsCorrAngle(2,iCTx,:) = mITDvsAngle(2,iCTx,:);
  
  p(iCTx,:) = polyfit(mITDvsCorrAngle(1,iCTx,:),mITDvsCorrAngle(2,iCTx,:),5);
  mITD_poly(1,iCTx,:) = mITDvsCorrAngle(1,iCTx,:); 
  mITD_poly(2,iCTx,:) = polyval(p(iCTx,:),mITD_poly(1,iCTx,:));
  disp(['RMSE of polynomial interpolation: ',num2str(sqrt(mean((mITD_poly(2,iCTx,:)-mITDvsCorrAngle(2,iCTx,:)).^2))),' samples'])
  plot(squeeze(mITDvsCorrAngle(1,iCTx,:)),squeeze(mITDvsCorrAngle(2,iCTx,:)),'.','MarkerSize',15); hold on; grid on;
  plot(squeeze(mITDvsCorrAngle(1,iCTx,:)),squeeze(mITD_poly(2,iCTx,:)),'-');
  xlabel('Azimuth Angles [Grad]');
  ylabel('Interaural time delay [Samples]');
  sLegend{2*(iCTx-1)+1} = ['Tx ',int2str(iCTx),' measured'];
  sLegend{2*(iCTx-1)+2} = ['Tx ',int2str(iCTx),' polynomial'];
end
leg = legend(sLegend);
set(leg,'Location','SouthEast');

stPRIR.vAngleSource = vAngleSource;

%% Average ITD calculation
disp('Calculation of average ITDs ...');
[mITD_poly,mITD_meas] = CalcAvITDvsAngle(stEnv,mITDvsCorrAngle);

%% Compare ITD according to model and measurement
disp(' '); disp('ITD calculation ...')
for iCA = 1:length(measurementData.Angles)
  disp(['  for angle (azimuth, elevation): ',int2str(measurementData.Angles(1,iCA)),',',int2str(measurementData.Angles(2,iCA)),'°'])
  %% ITD COMPARISON (measured/predicted)
  fAngle_head_azimuth = measurementData.Angles(1,iCA);
  vITD_model  = zeros(iNoTx,1);
  vITD_poly   = zeros(iNoTx,1);
  for iCTx = 1:iNoTx
    vITD_model(iCTx,1)  = CalcITD(fHeadRadius,fDist2Source,vAngleSource(iCTx),fAngle_head_azimuth);
    vITD_poly(iCTx,1)   = interp1(mITD_poly(1,:),mITD_poly(2,:),vAngleSource(iCTx)-fAngle_head_azimuth,'pchip');
  end
  
  % display on console
  sAnglesTx   = [];
  sAnglesDiff = [];
  sITDmeas    = [];
  sITDpoly    = [];
  sITDmodel   = [];
  for iC=1:iNoActTx
    sITDmeas    = [sITDmeas,'  ',num2str(mITDvsAngle(2,iC,iCA),'%0+5.1f')];
    sITDpoly    = [sITDpoly,'  ',num2str(vITD_poly(iC),'%0+5.1f')];  
    sITDmodel   = [sITDmodel,'  ',num2str(vITD_model(iC),'%0+5.1f')];  
    sAnglesTx   = [sAnglesTx, '  ',num2str(vAngleSource(iC),'%0+3.0f'),'° '];
    sAnglesDiff = [sAnglesDiff, '  ',num2str(vAngleSource(iC)-fAngle_head_azimuth,'%0+3.0f'),'° '];
  end  
  % disp(['    Angle source:  ',sAnglesTx])
  disp(['    Angle diff:    ',sAnglesDiff])
  disp(['    ITD meas:      ',sITDmeas])
  disp(['    ITD poly:      ',sITDpoly])
  disp(['    ITD model:     ',sITDmodel])
end

%% Postprocessing

% find volume max in FD, normalization could be implemented more efficiently
fVolMax = 0;
for iCA = 1:length(measurementData.Angles)
  % load IR
  mIR = stPRIR.Data(iCA).mIR;
  % Fourier transform
  mTF = fft(mIR,iN,1);
  % find volume max
  fVolMax = max(fVolMax,max(abs(mTF(:))));
end

for iCA = 1:length(measurementData.Angles)

  % load IR
  mIR = stPRIR.Data(iCA).mIR;

  % Fourier transform
  mTF = fft(mIR,iN,1);
  %mTF = mTF/max(abs(mTF(:)));
  mTF = mTF/fVolMax;
  
  %% Bass extension
  if 0%bBassExt
    % first step, add subwoofer signal (IIR bandpass)
    iFiltOrd    = 4;
    bpFilt      = designfilt('bandpassiir', 'FilterOrder', iFiltOrd, ...
      'HalfPowerFrequency1', fBassExtMin, 'HalfPowerFrequency2', fBassExtMax, ...
      'SampleRate', fSampFreq);
    vBPIR       = filter(bpFilt,[1,zeros(1,iN-1)]);
    [~,iBPInd]  = max(vBPIR);
    vFreqBand   = [80,300];
    vFreqInd    = round(vFreqBand/fSampFreq*iN);
    for iCRx = 1:2
      for iCTx = 1:iNoTx
        [~,iInd]         = max(mIR(:,iCRx,iCTx));
        vBPTF            = fft(wshift('1D',vBPIR,iBPInd-iInd),iN).';
        fAvPR            = mean(abs(mTF(vFreqInd,iCRx,iCTx)));
        mTF(:,iCRx,iCTx) = mTF(:,iCRx,iCTx) + 1.5*fAvPR*vBPTF;
      end
    end
    % second step, target curve
    mTFtp           = zeros(iN/2,2,2);
    for iCRx = 1:2
      for iCTx = 1:iNoTx
        mTFtp(:,iCRx,iCTx) = smoothnew3(abs(mTF(:,iCRx,iCTx)),1/24,(iN/2-1)*fSampFreq/iN,[0:iN/2-1]*fSampFreq/iN).';
      end
    end
    mTFtp           = mTFtp/max(abs(mTFtp(:)));
    mTFinv          = zeros(iN/2,2,2);
    mTFinv_av       = zeros(iN/2,2,2);
    mTarget         = zeros(iN/2,2,2);    
    for iCRx = 1:2
      for iCTx = 1:iNoTx
        fAvPR                         = mean(abs(mTFtp(vFreqInd,iCRx,iCTx)));
        fEndFreq                      = 100;
        iIndBEQ                       = round(fEndFreq/fSampFreq*iN);
        mTarget(:,iCRx,iCTx)          = abs(mTFtp(1:iN/2,iCRx,iCTx));
        mTarget(1:iIndBEQ,iCRx,iCTx)  = fAvPR;
        % incorporate resonance at specified frequency
        fResFreq                      = 80;
        iResFreqInd                   = round(fResFreq/fSampFreq*iN);        
        mTarget(:,iCRx,iCTx)          = mTarget(:,iCRx,iCTx).*(1+a./(b*([1:iN/2].'-iResFreqInd).^2+1));
        % inversion
        mTFinv(:,iCRx,iCTx)           = min(1,mTarget(:,iCRx,iCTx)./mTFtp(:,iCRx,iCTx));
        % smoothen inversion curve
        mTFinv_av(:,iCRx,iCTx)        = smoothnew3(abs(mTFinv(:,iCRx,iCTx)),1/24,(iN/2-1)*fSampFreq/iN,[0:iN/2-1]*fSampFreq/iN).';
      end
    end
    if 0%bDebug
      figure
      PlotAudioSpectrum(MakeConjSym([mTFtp(:,1,1);0]),fSampFreq,'c');    hold on;
      PlotAudioSpectrum(MakeConjSym([mTarget(:,1,1);0]),fSampFreq,'g');
      PlotAudioSpectrum(MakeConjSym([mTFinv(:,1,1);0]),fSampFreq,'m');
      PlotAudioSpectrum(MakeConjSym([mTFinv_av(:,1,1);0]),fSampFreq,'m--');
      PlotAudioSpectrum(mTF(:,1,1),fSampFreq,'b');
      PlotAudioSpectrum(mTF(:,1,1).*MakeConjSym([mTFinv_av(:,1,1);0]),fSampFreq,'r');
    end
    mTFinv_av(iN/2+1,:,:)     = mTFinv_av(iN/2,:,:);
    mTFinv_av(iN/2+2:iN,:,:)  = conj(mTFinv_av(iN/2:-1:2,:,:));
    for iCRx = 1:2
      for iCTx = 1:iNoTx
        mTFinv_av(:,iCRx,iCTx)  = abs(mTFinv_av(:,iCRx,iCTx)).*exp(-1i*imag(hilbert(log(abs(mTFinv_av(:,iCRx,iCTx))))));
        mTF(:,iCRx,iCTx)        = mTF(:,iCRx,iCTx).*mTFinv_av(:,iCRx,iCTx);
      end
    end
    mTF(1,:,:)  = 1e-12;
    mIR         = real(ifft(mTF,iN,1));
  end
  
  %% POWER NORMALIZATION (FD domain)
  if bPRIR_PowerNorm
    vPow = zeros(2,iNoTx);
    for iCRx = 1:2
      for iCTx = 1:iNoTx
%         vPow(iCRx,iCTx)   = CalcPower(mTF(2:iN/2,iCRx,iCTx)./(sqrt([2:iN/2]-1).'));
        vPow(iCRx,iCTx)   = CalcPower(mTF(:,iCRx,iCTx));
      end
      mTF(:,iCRx,:) = mTF(:,iCRx,:)/mean(vPow(iCRx,:));
    end
    mIR = ifft(mTF,iN,1);
  end
  
  % save in structure
  stPRIR.Data(iCA).mIR      = mIR;
  stPRIR.Data(iCA).mTD_meas = mTD_meas-min(mTD_meas(:,1));
  
  %% GRAPHICAL OUTPUT
  if bShowPRIR
    figure;
    for iCTx = 1:iNoActTx
      subplot(iNoActTx,2,2*(iCTx-1)+1);
      mIRInt  = interpft(mIR,iN*iOSF,1);
      if ~bStepResponse
        plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,mIRInt(:,1,iCTx),'b'); hold on;
        plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,mIRInt(:,2,iCTx),'r');
        [fMax,~] = max(mIR(:));
        ylabel(['Tx ',int2str(vActTxInt(iCTx))]);
      else
        title('step response');
        plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,cumsum(mIRInt(:,1,iCTx)),'b'); hold on;
        plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,cumsum(mIRInt(:,2,iCTx)),'r');
        fMax = max(max(max(abs(cumsum(mIRInt)))));
        ylabel(['Tx ',int2str(vActTxInt(iCTx))]);
      end
      grid on;
      set(gca,'xlim',[0,(iN-1)/fSampFreq*1e3/8]);
      set(gca,'ylim',[-fMax*1.2,fMax*1.2]);
      leg = legend('L','R'); grid on;
      set(leg,'Location','Southeast');
    end
    xlabel('Time [ms]');
    subplot(iNoActTx,2,1);
    if ~bStepResponse
      title(['Room IR at (azimuth,elevation): ',int2str(measurementData.Angles(1,iCA)),',',int2str(measurementData.Angles(2,iCA)),'°']);
    else
      title(['Room SR at (azimuth,elevation): ',int2str(measurementData.Angles(1,iCA)),',',int2str(measurementData.Angles(2,iCA)),'°']);
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
    title(['Room frequency response at (azimuth,elevation): ',int2str(measurementData.Angles(1,iCA)),',',int2str(measurementData.Angles(2,iCA)),'°']);
  end
end
%% SAVE DATASET
stPRIR.vActTx       = measurementData.extra.vActTx;
stPRIR.iNoHeadPos   = measurementData.extra.iNoHeadPos;
stPRIR.iHeadRange   = measurementData.extra.iHeadRange;
stPRIR.fHeadRadius  = fHeadRadius;
stPRIR.fDist2Source = fDist2Source;
stPRIR.vAngleSource = vAngleSource;
stPRIR.mITD_table   = mITD_poly; % also possible: mITD_meas, mITD_model

sDirName = ['PRIR/',sSetup,'/',sRoomName];
if ~exist(sDirName,'dir')
  mkdir(sDirName);
end
save([sDirName,'/PRIR'],'stPRIR');
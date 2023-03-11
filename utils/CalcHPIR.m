function [mIR_HP] = CalcHPIR(sHeadphoneName)

%% CHECK INPUT PARAMETERS
switch nargin
  case 1
    disp(' ');
    disp(['Calculating HPIR for dataset: ',sHeadphoneName])
  otherwise
    warning('Check number of input parameters!');
end

%% SET PARAMETERS
addpath('utils');
SetParameters;
load(['measure/headphone/',sHeadphoneName],'stHPMeas');
iN              = stSys.iN;
iOffset         = stSys.iOffset;
fSampFreq       = stSys.fSampFreq;
vInverse        = stHPMeas.vInvSweep;
  
%% DECONVOLUTION
for iCA = 1:stHPMeas.iNoHPMeas
  disp(['  for measurement no. ',int2str(iCA)])
  mLogSweep_rec = stHPMeas.stMeasData(iCA).mRecSig;
  mIR_long = zeros(size(mLogSweep_rec,1)+2^16,2);
  for iC = 1:2
    mIR_long(:,iC) = fftfilt(vInverse,[mLogSweep_rec(:,iC);zeros(2^16,1)]);
  end
  clear mLogSweep_rec;
  mIR_HP = zeros(iN,2);
  for iC = 1:2
    vIR_tp  = filter(ones(1,5),1,mIR_long(:,iC));
    vInd    = find(vIR_tp>0.2*max(vIR_tp));
    iInd    = vInd(1)-(5-1)/2;
    iStart  = max(1,iInd+1-iOffset);
    iEnd    = min(iInd+iN-iOffset,size(mIR_long,1));
    if (iEnd-iStart+1~=iN)
      disp('No valid impulse response detected!');
      iStart  = 1;
      iEnd    = iN;
    end
    mIR_HP(:,iC)  = mIR_long(iStart:iEnd,iC);
  end
  clear mIR_long;
  mTF_HP  = fft(mIR_HP,iN,1);
  
  %% POWER NORMALIZATION (FD domain)
  if bHPIR_PowerNorm
    for iCRx = 1:2
      fEnergy         = CalcEnergy(mIR_HP(:,iCRx));
      mIR_HP(:,iCRx)  = mIR_HP(:,iCRx)/sqrt(fEnergy);
    end
    mTF_HP  = fft(mIR_HP,iN,1);
  end

  %% Bass compensation
  bDeactivateBassComp = false;
  if ~bDeactivateBassComp
    fBassCutOff = 50; % Hz
    iIndBass = round(fBassCutOff/(fSampFreq/iN));
    mTF_HP(1:iIndBass,1) = mTF_HP(iIndBass+1,1);
    mTF_HP(1:iIndBass,2) = mTF_HP(iIndBass+1,2);
  end

  %% OCTAVE-BAND FILTERING
  mTF_HP_av = zeros(iN,2);
  for iCRx = 1:2
    vTFtp             = smoothnew3(abs(mTF_HP(:,iCRx)),iOctBandFiltFac,(iN/2-1)*fSampFreq/iN,[0:iN/2-1]*fSampFreq/iN).';
    vTFtp(1)          = 1e-12;
    mTF_HP_av(:,iCRx) = [vTFtp(1:iN/2);vTFtp(iN/2);vTFtp(iN/2:-1:2)];
  end
  %% AVERAGE TF FOR BOTH DRIVERS
  if bHPAvLeftRight
    vTF_HP_av = mean(mTF_HP_av,2);
    for iCRx = 1:2
      mTF_HP_av(:,iCRx) = vTF_HP_av;
    end
  end
  
  %% MINIMUM PHASE RESPONSE
  mTF = zeros(iN,2);
  mIR = zeros(iN,2);
  for iC = 1:2
    mTF(:,iC) = abs(mTF_HP_av(:,iC)).*exp(-1i*imag(hilbert(log(abs(mTF_HP_av(:,iC))))));
    mIR(:,iC) = real(ifft(mTF(:,iC)));
    mTF(:,iC) = fft(mIR(:,iC));
  end  
  % save in structure
  stHPIR.stData(iCA).mIR      = mIR;
  stHPIR.stData(iCA).mIR_LP   = mIR_HP;
  stHPIR.stData(iCA).mTF      = mTF;
  stHPIR.stData(iCA).mTF_LP   = mTF_HP;    
  disp('  ... done!');
end

%% AVERAGE HPIR
stHPIR.mTF_av_mag = zeros(stSys.iN,2);
for iCA = 1:stHPMeas.iNoHPMeas
  stHPIR.mTF_av_mag = stHPIR.mTF_av_mag + abs(stHPIR.stData(iCA).mTF);
end
stHPIR.mTF_av_mag = stHPIR.mTF_av_mag/stHPMeas.iNoHPMeas;
stHPIR.mIR_av     = ifft(stHPIR.mTF_av_mag,iN,1);
% force minimal phase
for iC = 1:2
  stHPIR.mTF_av(:,iC) = abs(stHPIR.mTF_av_mag(:,iC)).*exp(-1i*imag(hilbert(log(abs(stHPIR.mTF_av_mag(:,iC))))));
  stHPIR.mIR_av(:,iC) = real(ifft(stHPIR.mTF_av(:,iC)));
  stHPIR.mTF_av(:,iC) = fft(stHPIR.mIR_av(:,iC));
end

%% POWER NORMALIZATION
vPinkNoise  = GenPinkNoise(1,2^17);
vPow        = zeros(1,2);
for iCRx    = 1:2
  vPow(iCRx) = CalcPower(fftfilt(stHPIR.mIR_av(:,iCRx),vPinkNoise));
end
fAmplImbal  = sqrt(vPow(2)/vPow(1));
disp(['  amplitude imbalance (right/left): ',num2str(fAmplImbal)]);

%% INVERT HEADPHONE TRANSFER FUNCTION
bHPideal = false;
if bHPideal
  stHPIR.mIR_av = [ones(1,2);zeros(iN_HP-1,2)];
end
mIR_HP          = stHPIR.mIR_av(1:iN_HP,:);
mTF_HP          = fft(mIR_HP,iN_HP,1);
mTF_HP          = mTF_HP/max(abs(mTF_HP(:)));
mTF_HP_inv      = zeros(iN_HP,2);
vEpsilon        = GenWindow(iN_HP,fSampFreq,fFreqMin,fFreqMax,20,1000,1,1e-6);
if bShowHPIR
  figure;
  semilogx([1:iN_HP/2-1]/iN_HP*fSampFreq,vEpsilon(2:end/2),'linewidth',2);
  grid on
  title('Window for headphone equalization')
  xlabel('Frequency f [Hz]')
  ylabel('\epsilon(f)');
  xlim([10,fSampFreq/2])
end
iFiltLen        = iN_HP;
bpFilt          = designfilt('bandpassfir', 'FilterOrder', iFiltLen, ...
  'CutoffFrequency1', fFreqMin, 'CutoffFrequency2', fFreqMax, 'SampleRate', fSampFreq,...
  'DesignMethod', 'window', 'Window', 'kaiser');
vBPIR           = filter(bpFilt,[1,zeros(1,iN_HP-1)]);
vTargetBP       = fft(vBPIR,iN_HP).';
for iC = 1:2
  % clip peaks which are 10 dB larger than rest
  vEq                     = 1./mTF_HP(:,iC);
  fThres                  = min(abs(vEq))*10;
  vInd                    = find(abs(vEq)>fThres);
  vEq(vInd)               =  fThres*exp(1i*angle(vEq(vInd)));%fThres*exp(1i*phase(vEq(vInd)));
  vTF                     = 1./vEq;
  % force minimal phase again after magnitude manipulation
  vTF                     = abs(vTF).*exp(-1i*imag(hilbert(log(abs(vTF)))));
  % guarantees symmetry
  vTF(iN_HP/2+2:iN_HP)    = conj(vTF(iN_HP/2:-1:2)); 
  beta                    = 0.4;
  switch sHPEqMethod
    case 'HPEQ_linPhase'
      vTFinv              = conj(vTF).*vTargetBP./(conj(vTF).*vTF+beta*vEpsilon.');
    case 'HPEQ_minPhase'  
      A                   = abs(vTargetBP)./(1+beta*vEpsilon.'./(abs(vTF).^2));
      A                   = A.*exp(-1i*imag(hilbert(log(A))));
      vTFinv              = conj(vTF).*A./(abs(vTF).^2);
%       % make minPhase again, needed?
%       vTFinv              = abs(vTFinv).*exp(-1i*imag(hilbert(log(abs(vTFinv)))));
    otherwise
      warning('No valid headphone equalization method chosen!');
  end
  vTFinv(iN_HP/2+2:iN_HP) = conj(vTFinv(iN_HP/2:-1:2));
  mTF_HP_inv(:,iC)        = vTFinv;
end
mIR_HP_inv = real(ifft(mTF_HP_inv,[],1));
if bShowHPIR
  figure
  subplot(2,1,1);
  plot([0:iN_HP-1]/fSampFreq*1e3,mIR_HP_inv(:,1),'b'); hold on;
  plot([0:iN_HP-1]/fSampFreq*1e3,mIR_HP_inv(:,2),'r'); hold on;
  grid on;
  xlabel('Time [ms]')
  ylabel('Impulse response');
  title('Headphone correction filter response');
  subplot(2,1,2)
  PlotAudioSpectrum(mTF_HP_inv(:,1),fSampFreq,'b'); hold on;
  PlotAudioSpectrum(mTF_HP_inv(:,2),fSampFreq,'r'); hold on;
  ylabel('Transfer function');
  grid on;
end

%% IR windowing
% if sHPEqMethod=='HPEQ_linPhase'
%   vWin2       = hann(1*iN_HP);
%   [~,iIndMax] = max(mIR_HP_inv(:,1));
%   vWin2       = wshift('1D',vWin2,iN_HP/2-iIndMax);
%   mIR_tp = zeros(iN,2);
%   for iC=1:2
%     vIR               = mIR_HP_inv(:,iC).*vWin2;
%     vIndL             = mod([iIndMax-iN_HP/2:iIndMax+iN_HP/2-1]-1,iN)+1;
%     vIndS             = mod([iIndMax-iN_HP/2:iIndMax+iN_HP/2-1]-1,iN_HP)+1;
%     mIR_tp(vIndL,iC)  = vIR(vIndS,1);
%   end
%   mIR_HP_inv = mIR_tp;
% end
% subplot(2,1,1);
% plot([0:iN-1]/fSampFreq*1e3,mIR_HP_inv,'r');
% subplot(2,1,2);
% mTF_HP_inv = fft(mIR_HP_inv,iN,1);
% PlotAudioSpectrum(mTF_HP_inv,fSampFreq,'r')

% store in structure variable
stHPIR.mTF_HP_inv = mTF_HP_inv;
stHPIR.mIR_HP_inv = mIR_HP_inv;

%% GRAPHICAL OUTPUT
if bShowHPIR
  figure;
  for iCA = 1:stHPMeas.iNoHPMeas
    subplot(stHPMeas.iNoHPMeas+1,2,2*(iCA-1)+1);
    mIR_LP_Int  = interpft(stHPIR.stData(iCA).mIR_LP,iN*iOSF,1);
    mIR_Int     = interpft(stHPIR.stData(iCA).mIR,iN*iOSF,1);
    if ~bStepResponse
      plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,mIR_LP_Int(:,1),'b--'); hold on;
      plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,mIR_LP_Int(:,2),'r--');
      plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,mIR_Int(:,1),'b');
      plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,mIR_Int(:,2),'r');
      [fMax,~] = max(mIR_Int(:));
    else
      title('step response');
      plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,cumsum(mIR_LP_Int(:,1)),'b--'); hold on;
      plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,cumsum(mIR_LP_Int(:,2)),'r--');
      plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,cumsum(mIR_Int(:,1)),'b');
      plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,cumsum(mIR_Int(:,2)),'r');
      fMax = max(max(max(abs(cumsum(mIR_Int)))));
    end
    ylabel(['No. ',int2str(iCA)]);
    grid on;
    leg = legend('L (lp)','R (lp)','L (av+mp)','R (av+mp)'); grid on;
    set(leg,'Location','Southeast');
    set(gca,'xlim',[0,(iN-1)/fSampFreq*1e3/32]);
    set(gca,'ylim',[-fMax*1.2,fMax*1.2]);
  end
  for iCA = 1:stHPMeas.iNoHPMeas
    subplot(stHPMeas.iNoHPMeas+1,2,2*iCA);
    semilogx([1:iN/2-1]*fSampFreq/iN,20*log10(abs(stHPIR.stData(iCA).mTF_LP(2:end/2,1))),'b--'); hold on;
    semilogx([1:iN/2-1]*fSampFreq/iN,20*log10(abs(stHPIR.stData(iCA).mTF_LP(2:end/2,2))),'r--');
    semilogx([1:iN/2-1]*fSampFreq/iN,20*log10(abs(stHPIR.stData(iCA).mTF(2:end/2,1))),'b');
    semilogx([1:iN/2-1]*fSampFreq/iN,20*log10(abs(stHPIR.stData(iCA).mTF(2:end/2,2))),'r');
    set(gca,'xlim',[20,fSampFreq/2]);
    [fMax,~] = max(abs(mTF(:)));
    set(gca,'ylim',[-60,2]+20*log10(fMax));
    grid on;
    leg = legend('L','R','L (av)','R (av)'); grid on;
    set(leg,'Location','Southwest');
    ylabel(['No. ',int2str(iCA),' [dB]']);
  end
  % averaged response
  subplot(stHPMeas.iNoHPMeas+1,2,2*stHPMeas.iNoHPMeas+1);
  mIR_Int     = interpft(stHPIR.mIR_av,iN*iOSF,1);
  if ~bStepResponse
    plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,mIR_Int(:,1),'b'); hold on;
    plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,mIR_Int(:,2),'r');
    [fMax,~] = max(mIR_Int(:));
  else
    title('step response');
    plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,cumsum(mIR_Int(:,1)),'b'); hold on;
    plot([0:iOSF*iN-1]/iOSF/fSampFreq*1e3,cumsum(mIR_Int(:,2)),'r');
    fMax = max(max(max(abs(cumsum(mIR_Int)))));
  end
  xlabel('Time (ms)')
  ylabel('averaged');
  grid on;
  set(gca,'xlim',[0,(iN-1)/fSampFreq*1e3/32]);
  set(gca,'ylim',[-fMax*1.2,fMax*1.2]);
  leg = legend('L','R');
  set(leg,'Location','Southeast');
  subplot(stHPMeas.iNoHPMeas+1,2,2*stHPMeas.iNoHPMeas+2);
  semilogx([1:iN/2-1]*fSampFreq/iN,20*log10(abs(stHPIR.mTF_av(2:end/2,1))),'b'); hold on;
  semilogx([1:iN/2-1]*fSampFreq/iN,20*log10(abs(stHPIR.mTF_av(2:end/2,2))),'r');
  set(gca,'xlim',[20,fSampFreq/2]);
  [fMax,~] = max(abs(mTF(:)));
  set(gca,'ylim',[-60,2]+20*log10(fMax));
  grid on;
  leg = legend('L','R'); grid on;
  set(leg,'Location','Southwest');
  ylabel(['averaged [dB]']);
  xlabel('Frequency [Hz]');
  subplot(stHPMeas.iNoHPMeas+1,2,1);
  if ~bStepResponse
    title('Headphone IR');
  else
    title('Headphone SR');
  end
  subplot(stHPMeas.iNoHPMeas+1,2,2);
  title('Headphone frequency response');
end
%% SAVE DATASET
sDirName = ['HPIR/',sHeadphoneName];
if ~exist(sDirName,'dir')
  mkdir(sDirName);
end
save([sDirName,'/HPIR'],'stHPIR');
%% Basic parameters
stSys.iN        = 2^16;
stSys.fSampFreq = 48e3;
stSys.iOffset   = 128;

%% PRIR calculation
bRoomCor        = false;
sRoomCorName    = 'APS_Klasik';
fRelThres       = 0.5;%0.25;
bPRIR_PowerNorm = false;

bBassExt        = false;
fBassExtMin     = 20;
fBassExtMax     = 75;
a               = 1.25;
b               = 0.01;

% environment
stEnv.fHeadRadius  = 0.095;%0.51*(0.16/2)+0.019*(0.25/2)+0.18*(0.18/2)+0.032;
stEnv.fDist2Source = 2; %1;
stEnv.vAngleSource = [30,-30,0,0,105,-105]; % nach Standard
% stEnv.vAngleSource  = [0,30]; % Centereinmessung
% stEnv.vAngleSource = [25,-25,0,0,105,-105]; % nach Standard
% stEnv.vAngleSource = [150,-150]; % turn-around for rear channels

%% HPIR calculation
bHPAvFilt       = true;
iOctBandFiltFac = 1/2;%1/3;%1/6;
bHPAvLeftRight  = true;
bHPIR_PowerNorm = false;
sHPEqMethod     = 'HPEQ_minPhase'; % 'HPEQ_linPhase' or 'HPEQ_minPhase'
switch sHPEqMethod 
  case 'HPEQ_minPhase'
    iN_HP         = 2^16;
  case 'HPEQ_linPhase'
    iN_HP         = 2^12;
end

%% BRIR calculation
fFreqMin        = 30;
fFreqMax        = 21.5e3;19.5e3; 21.99e3;%19.5e3;%  23.99e3;%19.5e3;

%% Graphical output
iOSF            = 8;
bStepResponse   = true;
bShowPRIR       = true;
bShowHPIR       = true;
bShowBRIR       = true;

%% Post processing
bFilter44       = true;
bFilter48       = false;
bFilter192      = false;
bEqualizerAPO   = false;
function [mIRInt] = InterpIR(stBRIR,vAngleHead)

try
  fHeadRadius = stBRIR.fHeadRadius;
catch
  disp('Use standard head radius')
  fHeadRadius = 0.51*(0.16/2)+0.019*(0.25/2)+0.18*(0.18/2)+0.032;
end
try
  fDist2Source = stBRIR.fDist2Source;
catch
  disp('Use standard source distance')
  fDist2Source = 2; % standard
end
try
  vAngleSource = stBRIR.vAngleSource;
catch
  disp('Use standard angle source')
  vAngleSource = [30,-30,0,0,105,-105]; % standard
end
try
  mITD_table = stBRIR.mITD_table;
catch
  disp('Use standard ITD table')
  load('utils/mITD_table_reference_before_211203.mat','mITD_table');
end

%%
mIRInt        = zeros([size(stBRIR.stData(1).mIR),length(vAngleHead)]);
mIRAll        = zeros([length(stBRIR.stData),size(stBRIR.stData(1).mIR)]);

%% sort with respect to angles if needed
[~,vSortInd] = sort(stBRIR.vAngle);
stBRIR.vAngle = stBRIR.vAngle(vSortInd)+1e-3*randn(size(stBRIR.vAngle));
for iC=1:length(stBRIR.stData)
  mIRAll(iC,:,:,:) = stBRIR.stData(vSortInd(iC)).mIR;
end

for iC=1:length(stBRIR.stData)
  mIRAll(iC,:,:,:) = stBRIR.stData(iC).mIR;
end

% smoothing in angle direction
bSmoothing = false;
if bSmoothing
  disp('Smoothening ...')
  iSpan = 3;
  for iCPath=1:size(mIRAll,2)
    for iCRx = 1:size(mIRAll,3)
      for iCTx = 1:size(mIRAll,4)
        mIRAll(:,iCPath,iCRx,iCTx) = smooth(mIRAll(:,iCPath,iCRx,iCTx),iSpan);
      end
    end
  end
end

% % time-domain interpolation
sInterpType = 'linear'; %'pchip'
for iC = 1:length(vAngleHead)
  fAngleHead        = vAngleHead(iC);
  mIR               = permute(interp1(stBRIR.vAngle,mIRAll,fAngleHead,sInterpType,'extrap'),[2,3,4,1]);
  mIR               = [zeros(128,size(mIR,2),size(mIR,3));mIR];
  mIRtp             = AdjustDelays(mIR,fHeadRadius,fDist2Source,vAngleSource,fAngleHead,mITD_table);
  mIRInt(:,:,:,iC)  = mIRtp(129:end,:,:);
%   mIRInt(:,:,:,iC)  = AdjustDelays(mIR,fHeadRadius,fDist2Source,vAngleSource,fAngleHead,mITD_table);
end

% frequency-domain interpolation
% iN = 2^16;
% mTFAll = fft(mIRAll,iN,2);
% mTFAllabs = abs(mTFAll);
% mTFAllph = unwrap(angle(mTFAll),[],1);
% % mIRInt = zeros(iN,size(mTFAll,3),size(mTFAll,4),size(mTFAll,1));
% mIRInt = zeros(size(mIRAll,2),size(mTFAll,3),size(mTFAll,4),size(mTFAll,1));
% sInterpType = 'linear';
% for iC = 1:length(vAngleHead)
%   fAngleHead        = vAngleHead(iC);
%   mTFabs            = permute(interp1(stBRIR.vAngle,mTFAllabs,fAngleHead,sInterpType,'extrap'),[2,3,4,1]);
%   mTFph             = permute(interp1(stBRIR.vAngle,mTFAllph,fAngleHead,sInterpType,'extrap'),[2,3,4,1]);
%   mTF               = mTFabs.*exp(1i*mTFph);
%   mIR               = real(ifft(mTF,iN,1));
%   mIR               = [zeros(128,size(mIR,2),size(mIR,3));mIR];
%   mIRtp             = AdjustDelays(mIR,fHeadRadius,fDist2Source,vAngleSource,fAngleHead,mITD_table);
%   mIRInt(:,:,:,iC)  = mIRtp(129:end,:,:);
% %   mIRInt2(:,:,:,iC) = AdjustDelays(mIR,fHeadRadius,fDist2Source,vAngleSource,fAngleHead,mITD_table);
% end
% % mIRInt = mIRInt(1:size(mIRAll,2),:,:,:);
disp('Interpolation completed')
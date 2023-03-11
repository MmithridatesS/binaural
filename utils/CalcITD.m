function [fITD,vTD] = CalcITD(fHeadRadius,fDist2Source,fAngleSource,fAngleHead)

fSamplFreq  = 48e3;
fSoundSpeed = 340;

%% exact method
dist_s_ear    = zeros(2,1);
pos_ear       = fHeadRadius*[[cos((180+fAngleHead)*pi/180);sin((180+fAngleHead)*pi/180)],...
    [cos(fAngleHead*pi/180);sin(fAngleHead*pi/180)]];
% pos_ear       = reshape(pos_ear,2,length(fAngleHead),2);
pos_ear       = reshape(pos_ear,2,2);
pos_source    = fDist2Source*[cos((fAngleSource+90)*pi/180);sin((fAngleSource+90)*pi/180)];

% distance source to ear
dist_s_ear(:,1)  = ...
  [sqrt(sum(abs(pos_ear(:,1)-pos_source).^2));sqrt(sum(abs(pos_ear(:,2)-pos_source).^2))];

% related to head center
dist_s_ear  = dist_s_ear - fDist2Source;
vTD       = dist_s_ear/fSoundSpeed*fSamplFreq;

%% Woodworth
fAngle  = (fAngleHead-fAngleSource)/180*pi;
if fAngle>=0 && fAngle<=pi/2
  fITD    = -fHeadRadius/fSoundSpeed * (sin(fAngle)+fAngle) * fSamplFreq;
elseif fAngle>pi/2
  fITD    = -fHeadRadius/fSoundSpeed * (sin(fAngle)+pi-fAngle) * fSamplFreq;
elseif fAngle<0 && fAngle>=-pi/2
  fITD    = fHeadRadius/fSoundSpeed * (sin(-fAngle)-fAngle) * fSamplFreq;
elseif fAngle<-pi/2
  fITD    = fHeadRadius/fSoundSpeed * (sin(-fAngle)+pi+fAngle) * fSamplFreq;
end

%% plots
% figure
% plot(pos_ear(1,:),pos_ear(2,:),'.'); hold on
% plot(fHeadRadius*cos(0:0.1:2*pi),fHeadRadius*sin(0:0.1:2*pi))
% plot(pos_source(1,:),pos_source(2,:),'x')
% axis([-1,1,-1,1]*fDist2Source*1.1)
% axis square
% grid on
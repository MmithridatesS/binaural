function [dist_s_ear,sampl,fITD] = CalcITD_old(fHeadRadius,fDist2Source,fAngleSource,fAngleHead)
% function [dist_s_ear_approx,sampl_approx] = CalcITD(fHeadRadius,fDist2Source,vAngleSource,fAngleHead)
fSamplFreq  = 48e3;
fSoundSpeed = 340;
%% exact method
% dist_s_ear    = zeros(2,length(fAngleHead));
dist_s_ear    = zeros(2,1);
pos_ear       = fHeadRadius*[[cos((180+fAngleHead)*pi/180);sin((180+fAngleHead)*pi/180)],...
    [cos(fAngleHead*pi/180);sin(fAngleHead*pi/180)]];
% pos_ear       = reshape(pos_ear,2,length(fAngleHead),2);
pos_ear       = reshape(pos_ear,2,2);
pos_source    = fDist2Source*[cos((fAngleSource+90)*pi/180);sin((fAngleSource+90)*pi/180)];

% iCount = 0;
% for angle = fAngleHead
%   iCount                = iCount + 1;
%   dist_s_ear(:,iCount)  = ...
%     [sqrt(sum(abs(pos_ear(:,iCount,1)-pos_source).^2));sqrt(sum(abs(pos_ear(:,iCount,2)-pos_source).^2))];
% end
dist_s_ear(:,1)  = ...
  [sqrt(sum(abs(pos_ear(:,1)-pos_source).^2));sqrt(sum(abs(pos_ear(:,2)-pos_source).^2))];

  % related to head center
dist_s_ear  = dist_s_ear - fDist2Source;
sampl       = dist_s_ear/fSoundSpeed*fSamplFreq;

% %% approximated method
% dist_s_ear_approx = sqrt(fHeadRadius^2+fDist2Source^2)-fDist2Source + ...
%   [fDist2Source+fHeadRadius*sin((fAngleHead-vAngleSource)*pi/180);fDist2Source+fHeadRadius*sin((fAngleHead-vAngleSource+180)*pi/180)]-fDist2Source;
% sampl_approx = dist_s_ear_approx/fSoundSpeed*fSamplFreq;

%% Woodworth
vAngle  = fAngleHead+fAngleSource;
fITD    = fHeadRadius/fSoundSpeed * (sin(vAngle)+vAngle) * fSamplFreq;

%% plots
% figure
% plot(pos_ear(1,:),pos_ear(2,:),'.'); hold on
% plot(fHeadRadius*cos(0:0.1:2*pi),fHeadRadius*sin(0:0.1:2*pi))
% plot(pos_source(1,:),pos_source(2,:),'x')
% axis([-1,1,-1,1]*fDist2Source*1.1)
% axis square
% grid on
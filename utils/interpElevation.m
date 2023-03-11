function H = interpElevation(Htp,vAngleVer,fAngleVer)

if fAngleVer>30
  H = Htp(:,:,:,:,:,3);
elseif fAngleVer>=0
  m = fAngleVer/(vAngleVer(3)-vAngleVer(2));
  H = squeeze(m*Htp(:,:,:,:,:,3)+(1-m)*Htp(:,:,:,:,:,2));
elseif fAngleVer>-30
  m = fAngleVer/(vAngleVer(1)-vAngleVer(2));
  H = squeeze(m*Htp(:,:,:,:,:,1)+(1-m)*Htp(:,:,:,:,:,2));
else
  H = Htp(:,:,:,:,:,1);
end

% a = (fAngleVer<-30)*1 + (fAngleVer>=-30&&fAngleVer<0)*(-fAngleVer/20);
% b = (fAngleVer>=-30&&fAngleVer<0)*(1+fAngleVer/20) + (fAngleVer>=0&&fAngleVer<30)*(1-fAngleVer/20);
% c = (fAngleVer>=30)*1 + (fAngleVer<30&&fAngleVer>0)*(fAngleVer/20);
% H = squeeze(a*Htp(1,:,:,:,:,:) + b*Htp(2,:,:,:,:,:) + c*Htp(3,:,:,:,:,:));
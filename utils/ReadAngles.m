function [fAngleHor,fAngleVer,fAngleHorSlope,vAngleHor] = ReadAngles(oSerial)

%% read and clear input buffer
vSeq        = fread(oSerial,oSerial.BytesAvailable);

%% read horizontal angle (format x.yyy rad)
% vIndHor     = find(vSeq==120);
% iIndHor     = vIndHor(end);
% vCutHor     = vSeq(iIndHor-5:iIndHor-1);
% fAngleHor   = 180/pi*str2double(char(vCutHor));

vIndHor     = find(vSeq==120);
vIndHor     = vIndHor(vIndHor>=6);
iNoAngleHor = length(vIndHor);
vAngleHor   = zeros(1,iNoAngleHor);
for iC=1:iNoAngleHor
  iIndStart = vIndHor(iC)-5;
  iIndEnd   = vIndHor(iC)-1;
  vAngleHor(iC) = 180/pi*str2double(char(vSeq(iIndStart:iIndEnd)));
end
fAngleHor   = vAngleHor(end);
if iNoAngleHor>1
  vAngleHor = mod(vAngleHor-180,360)-180;
  fFac      = 7.5e-3/(512/44.1e3);
%   p   = polyfit([0:iNoAngleHor-1]*fFac,vAngleHor,max(iNoAngleHor-2,1));
%   pd  = polyder(p);
%   fAngleHorSlope = polyval(pd,(iNoAngleHor-1)*fFac);
%   fAngleHorSlope = p(1);
  fAngleHorSlope = (vAngleHor(end)-vAngleHor(end-1))/fFac;
%   if fAngleHorSlope>0
%     disp('<-- to the left')
%   elseif fAngleHorSlope<0
%     disp('    to the right -->')
%   else
%     disp(' --              -- ')
%   end
else
  fAngleHorSlope = 0;
end

%% read vertical angle (format x.yyy rad)
vIndVer     = find(vSeq==122);
iIndVer     = vIndVer(end);
vCutVer     = vSeq(iIndVer-5:iIndVer-1);
fAngleVer   = 180/pi*str2double(char(vCutVer));
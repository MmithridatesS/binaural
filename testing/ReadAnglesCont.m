function ReadAnglesCont(object_ser,event)
% read and clear input buffer
a           = fread(object_ser,object_ser.BytesAvailable);
length(a)
% read horizontal angle (format x.yyy rad)
vIndHor     = find(a==120);
iIndHor     = vIndHor(end);
vCutHor     = a(iIndHor-5:iIndHor-1);
fAngleHor   = 180/pi*str2double(char(vCutHor));
disp(fAngleHor)

% read vertical angle (format x.yyy rad)
% vIndVer     = find(a==122);
% iIndVer     = vIndVer(end);
% vCutVer     = a(iIndVer-5:iIndVer-1);
% fAngleVer   = 180/pi*str2double(char(vCutVer));
% disp(fAngleVer)
cputime
end
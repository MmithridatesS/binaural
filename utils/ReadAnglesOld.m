function [fAngleHor,fAngleVer] = ReadAngles(s)

s.BytesAvailable
a         = fread(s,s.BytesAvailable)
vInd_x    = find(a==120);
vInd_z    = find(a==122);

iIndEnd_x       = vInd_x(end)-1;
vInd_z_Before_x = find(vInd_z<iIndEnd_x);
iInd_z_Before_x = vInd_z_Before_x(end);
iIndStart_x     = vInd_z(iInd_z_Before_x)+1;
vCut_x          = a(iIndStart_x:iIndEnd_x);
fAngleHor       = 180/pi*str2double(char(vCut_x));

iIndEnd_z       = vInd_z(end)-1;
vInd_x_Before_z = find(vInd_x<iIndEnd_z);
iInd_x_Before_z = vInd_x_Before_z(end);
iIndStart_z     = vInd_x(iInd_x_Before_z)+1;
vCut_z          = a(iIndStart_z:iIndEnd_z);
fAngleVer       = 180/pi*str2double(char(vCut_z));
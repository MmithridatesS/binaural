%% Network parameters
if (~exist('oSerial','var'))
    oSerial = Bluetooth('ht1',1);
    oSerial.BytesAvailableFcnCount = 24;
    oSerial.BytesAvailableFcnMode = 'byte';
    oSerial.BytesAvailableFcn=@(oSerial,event) ReadAnglesCont(oSerial,event);
    fopen(oSerial);
    disp('Opened Bluetooth connection ...');
end
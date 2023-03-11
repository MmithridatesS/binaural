function [] = MeasPRIR_shell(ssetup, sroomname, stmeas)
    clc;
    disp('____Auto measurement for given range___');
    rangeElevation = stmeas.iHeadRangeE ;
    noElevation =  stmeas.iNoHeadPosE;
    rangeAzimuth = stmeas.iHeadRange;
    noAzimut = stmeas.iNoHeadPos;
    d_e = 2*rangeElevation/(noElevation-1);
    d_a = 2*rangeAzimuth/(noAzimut-1);
    %list of elevation angles
    eAngles = -rangeElevation:d_e:rangeElevation;
    aAngles = -rangeAzimuth:d_a:rangeAzimuth;
   
    for i = eAngles
        for j = aAngles
            SingleMeasurementPRIR_shell(ssetup, sroomname, stmeas, j,i);
        end
    end

   


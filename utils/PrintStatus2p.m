function [] = PrintStatus2p(sRoomName,sHeadphoneName,sRoomName2,sHeadphoneName2,iFiltNo,sStatus,N,iNoTx,...
  fAngleHor,fAngleVer,fAngleHor2,fAngleVer2,vAngle,vRunTime,vUnderrun,fUpdateTime,iCount)

switch sStatus
  case 'OFF'
    clc;
    fprintf('Binaural Synthesizer\n');
    fprintf('====================\n\n');
    fprintf('Room 1:       %s\n',sRoomName);
    fprintf('Headphone 1:  %s\n\n',sHeadphoneName);
    fprintf('Room 2:       %s\n',sRoomName2);
    fprintf('Headphone 2:  %s\n\n',sHeadphoneName2);
    fprintf('Headphone is OFF!\n');
  case 'ON'
    vRunTimeStats = zeros(4,1,'single');
    iRunTimeLen   = length(vRunTime);
    vTimeWin      = mod((max(1,iCount-iRunTimeLen):iCount)-1,iRunTimeLen)+1;
    vRunTimeStats(1) = mean(vRunTime(vTimeWin));
    vRunTimeStats(2) = numel(find(vRunTime(vTimeWin)>0.75*fUpdateTime))/length(vTimeWin);
    vRunTimeStats(3) = numel(find(vRunTime(vTimeWin)>1.00*fUpdateTime))/length(vTimeWin);
    vRunTimeStats(4) = mean(vUnderrun(vTimeWin));
    clc;
    fprintf('Binaural Synthesizer\n');
    fprintf('====================\n\n');
    fprintf('Room 1:       %s\n',sRoomName);
    fprintf('Headphone 1:  %s\n\n',sHeadphoneName);
    fprintf('Room 2:       %s\n',sRoomName2);
    fprintf('Headphone 2:  %s\n\n',sHeadphoneName2);
    fprintf('BRIR length:  %d\n',N);
    fprintf('No. speakers: %d\n\n',iNoTx);
    fprintf('Mean time:    %3.1f ms / %3.1f ms\n',...
      vRunTimeStats(1)*1e3,fUpdateTime*1e3);
    fprintf('>75%% frame:   %3.2f %%\n',...
      vRunTimeStats(2)*100);
    fprintf('>100%% frame:  %3.2f %%\n',...
      vRunTimeStats(3)*100);
    fprintf('Underruns:    %3.3f %%\n\n',...
      vRunTimeStats(4)*100);
    fprintf('Headphone is ON!\n\n');
    fprintf('1st Headphone:\n');
    if abs(fAngleHor) > max(abs(vAngle))
      fprintf('Azimutal:     %3.2f° (Out of range!)\n',fAngleHor);
    else
      fprintf('Azimutal:     %3.2f°\n',fAngleHor);
    end
    if abs(fAngleVer) > 30
      fprintf('Elevation:    %3.1f° (Out of range!)\n\n',fAngleVer);
    else
      fprintf('Elevation:    %3.1f°\n\n',fAngleVer);
    end
    fprintf('2nd Headphone:\n');
    if abs(fAngleHor2) > max(abs(vAngle))
      fprintf('Azimutal:     %3.2f° (Out of range!)\n',fAngleHor2);
    else
      fprintf('Azimutal:     %3.2f°\n',fAngleHor2);
    end
    if abs(fAngleVer2) > 30
      fprintf('Elevation:    %3.1f° (Out of range!)\n\n',fAngleVer2);
    else
      fprintf('Elevation:    %3.1f°\n\n',fAngleVer2);
    end
    if iFiltNo == 2
      fprintf('Outputs are exchanged!\n\n');
    end
end
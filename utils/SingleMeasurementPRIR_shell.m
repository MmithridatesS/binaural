function [] = SingleMeasurementPRIR_shell(sSetup,sRoomName,stMeas,angle_horizontal, angle_vertical)
sFileName = ['measure/room/',sSetup,'/ds/',sRoomName];
mRecSig = SingleMeasurementPRIR(stMeas, angle_horizontal,angle_vertical);

if exist('sFileName')
    load(sFileName,'measurementData');
    
    bool = false;
    for i = 1:size(measurementData.Angles,2)
        if measurementData.Angles(:,i) == [angle_vertical;angle_horizontal]
            bool = true;
            measurementData.Data(i).mRecSig = mRecSig;
        end
    end
    if bool == false
       measurementData.Angles = [measurementData.Angles, [angle_vertical;angle_horizontal]];
       measurementData.Data(i+1).mRecSig = mRecSig;
    end

%     for i = 1:size(measurementData.Angles,2)
%         if measurementData.Angles(:,i) == [angle_vertical;angle_horizontal]
%             measurementData.Data(i).mRecSig = mRecSig;
% 
% 
%         else 
% 
%         end
%     end 	
else 
  
  measurementData.Angles = [angle_vertical;angle_horizontal];
  measurementData.Data.mRecSig = mRecSig;
end
save(sFileName,'measurementData'); 
end


function [mITD_poly,mITD_meas] = CalcAvITDvsAngle(stEnv,mITDvsAngle)
fHeadRadius  = stEnv.fHeadRadius;
fDist2Source = stEnv.fDist2Source;

mITDvsAngle     = reshape(mITDvsAngle,2,[]);
mITDvsAngle     = abs(mITDvsAngle);
[~,vInd]        = sort(mITDvsAngle(1,:));
mITDvsAngleSort = mITDvsAngle(:,vInd);
mITDav          = [];
iAngleCur       = 0;
iCounter        = 1;
iNoElem         = size(mITDvsAngleSort,2);
for iC=1:iNoElem
  iAngleNew = mITDvsAngleSort(1,iC);
  if iAngleNew~=iAngleCur || iC==iNoElem
    if iC<iNoElem
      fITD      = mean(mITDvsAngleSort(2,iCounter:iC-1));
    else
      fITD      = mean(mITDvsAngleSort(2,iCounter:iC));
    end
    mITDav    = [mITDav,[iAngleCur;fITD]];
    iCounter  = iC;
    iAngleCur = iAngleNew;
  end
end
mITD_meas = [-mITDav(:,end:-1:2),[0;0],mITDav(:,2:end)];
p = polyfit(mITD_meas(1,:),mITD_meas(2,:),5);
mITD_poly(1,:) = mITD_meas(1,:); % could be also regular grid
mITD_poly(2,:) = polyval(p,mITD_poly(1,:));
disp(['RMSE of polynomial interpolation: ',num2str(sqrt(mean((mITD_poly(2,:)-mITD_meas(2,:)).^2))),' samples'])

%% 
bUse_standard_ITD_table = false;
if bUse_standard_ITD_table
  load('utils/mITD_table_reference_before_211203.mat','mITD_table');
  mITD_poly      = mITD_table;
%   vAngle_table   = mITD_table(1,:);
%   vITD_table     = mITD_table(2,:);
end
figure
plot(mITD_meas(1,:),mITD_meas(2,:),'.'); hold on; grid on;
plot(mITD_poly(1,:),mITD_poly(2,:),'-');
vAngle_table = mITD_poly(1,:);
vITD_model   = zeros(size(vAngle_table,2),1);
for iC=1:length(vAngle_table)
  vITD_model(iC,1) = CalcITD(fHeadRadius,fDist2Source,0,vAngle_table(length(vAngle_table)+1-iC));
end
plot(vAngle_table,vITD_model,'c');
xlabel('Angles [Grad]');
ylabel('Interaural time delay [Samples]');
leg = legend('measured','polynomial','model');
set(leg,'Location','SouthEast')
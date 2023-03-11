function [mIR] = AdjustDelays(mIR,fHeadRadius,fDist2Source,vAngleSource,fAngleHead,mITD_table)

iNoTx         = size(mIR,3);
% mTD_calc      = zeros(2,iNoTx);
for iCTx = 1:iNoTx
  [fITD_calc,mTD_calc] = CalcITD(fHeadRadius,fDist2Source,vAngleSource(iCTx),fAngleHead);
  % only mTD_calc is needed
  fITD_calc = interp1(mITD_table(1,:),mITD_table(2,:),vAngleSource(iCTx)-fAngleHead,'pchip');
  vTD_calc = mTD_calc(1)+[0,fITD_calc];
  for iCRx = 1:2    
%     fTimeDelay        = mTD_calc(iCRx,iCTx);
    fTimeDelay        = vTD_calc(iCRx);
    mIR(:,iCRx,iCTx)  = TimeShift(mIR(:,iCRx,iCTx),fTimeDelay);
  end
end
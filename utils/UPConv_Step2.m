function [Y_out,mFDL_buf] = UPConv_Step2(mInFFT,mFDL_buf,vTxInd,H,iCount,iAngleInd,B,P)

%% step 2
% FDL
iCircPt               = mod(P-iCount,P)+1;
mFDL_buf(:,iCircPt,:) = mInFFT(1:B+1,:);
vFDLInd               = circshift([1:P],1-iCircPt);

% product of spectra, sum subspectra and IFFT
Y_out(1:B+1,1)        = sum(sum(squeeze(mFDL_buf(:,vFDLInd,:)).*squeeze(H(:,:,1,vTxInd,iAngleInd)),3),2);
Y_out(1:B+1,2)        = sum(sum(squeeze(mFDL_buf(:,vFDLInd,:)).*squeeze(H(:,:,2,vTxInd,iAngleInd)),3),2);

end
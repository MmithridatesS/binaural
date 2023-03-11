function [y,x_in_buf,mFDL_buf] = UPConv(mIn,x_in_buf,mFDL_buf,vTxInd,H,iCount,iAngleInd,B,P)

%% step 1
% fill input buffer
x_in_buf(1:B,:)       = x_in_buf(B+1:end,:);
x_in_buf(B+1:end,:)   = mIn(:,:);

% FFT
mInFFT                = fft(x_in_buf,2*B,1);

%% step 2
% FDL
iCircPt               = mod(P-iCount,P)+1;
mFDL_buf(:,iCircPt,:) = mInFFT(1:B+1,:);
vFDLInd               = circshift([1:P],1-iCircPt);

% product of spectra, sum subspectra and IFFT
Y_out(1:B+1,1)        = sum(sum(squeeze(mFDL_buf(:,vFDLInd,:)).*squeeze(H(:,:,1,vTxInd,iAngleInd)),3),2);
Y_out(1:B+1,2)        = sum(sum(squeeze(mFDL_buf(:,vFDLInd,:)).*squeeze(H(:,:,2,vTxInd,iAngleInd)),3),2);

%% step 3
y_out_tp              = ifft(Y_out,2*B,1,'symmetric');
y                     = y_out_tp(B+1:end,:);
end
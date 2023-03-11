function [mInFFT,x_in_buf] = UPConv_Step1(mIn,x_in_buf,B)

%% step 1
% fill input buffer
x_in_buf(1:B,:)       = x_in_buf(B+1:end,:);
x_in_buf(B+1:end,:)   = mIn(:,:);

% FFT
mInFFT                = fft(x_in_buf,2*B,1);
end
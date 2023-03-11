function [y] = UPConv_Step3(Y_out,B)

%% step 3
y_out_tp              = ifft(Y_out,2*B,1,'symmetric');
y                     = y_out_tp(B+1:end,:);
end
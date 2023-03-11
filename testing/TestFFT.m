randn('state',0)
% parameters
N = 2^15;
B = 2^9;
L = B;
P = N/L;
K = 2*B;

% buffer initialization
mFDL_buf = zeros(B+1,P);
x_in_buf = zeros(2*B,1);
Y_out    = zeros(2*B,1);
y_out    = zeros(B,10);
vInd     = 1:P;

% test signals
h             = randn(1,N);
h_reshape     = reshape(h,L,P);
H_reshape     = fft(h_reshape,K,1);
H_reshape(B+2:end,:) = [];
x_in          = randn(1,1000*B);
x_in_reshape  = reshape(x_in,B,[]);

% fftw('planner','measure');

tic;
for iC2=1:100

  % fill input buffer
  x_in_buf(1:B)     = x_in_buf(B+1:end);
  x_in_buf(B+1:end) = x_in_reshape(:,iC2);
  % FFT
  X_in              = fft(x_in_buf,K,1);

  % FDL
%   iCircPoint = mod(1-iC2,P/M)+1;
%   for iC=P:-1:2
%      mFDL_buf(:,iC) = mFDL_buf(:,iC-1);
%   end
%   mFDL_buf(:,1) = X_in(1:B+1,1);
  
  % FDL
  iCircPoint              = mod(P-iC2,P)+1;
  mFDL_buf(:,iCircPoint)  = X_in(1:B+1,1);
  
  % product of spectra
  vInd                    = circshift(vInd,1);
  Y_reshape               = mFDL_buf(:,vInd).*H_reshape;
  
  % summation of subspectra
  Y_out(1:B+1,1)          = sum(Y_reshape,2);
  Y_out(B+2:end,1)        = conj(Y_out(B:-1:2));
  
  % IFFT
  y_out_tp = ifft(Y_out,K,1);
  
  % cut out signal
  y_out(:,iC2) = y_out_tp(B+1:end,1);

end
toc;
% close all
% plot(filter(h,1,x_in),'r')
% hold on
% plot(y_out(:))
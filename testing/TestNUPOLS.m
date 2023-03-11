clear all; close all;
clc;
addpath('Utils');

% uniform partition
% B   = 128;
% Bi  = [1]*B;
% Pi  = [256*2.5];

% % test config
% B   = 256;
% Bi  = [1,2,4,32]*B;
% Pi  = [2,4,8,8];

% test config
B   = 512;
if B==512
  Bi  = [1,2,4,8]*B;
  Pi  = [2,8,9,8];
  Bi  = [1,2,4,16]*B;
  Pi  = [2,2,4,6];
  
end

% % proposed config for B=128
% B   = 128;
% Bi  = [1,2,8,64]*B;
% Pi  = [2,4,8,10];

vSchedOffset = [0,0,1,3]; % Bi=[1,2,4,16]->[0,0,1,3] or [0,0,1,7]


N   = sum(Bi.*Pi)
disp(['Filter length: ',int2str(N)])

P   = N/B;

vOffset     = zeros(size(Bi));
vBlockDelay = zeros(size(Bi));
for iCOffset=2:length(vOffset)
  vOffset(iCOffset) = sum(Bi(1:iCOffset-1)/B.*Pi(1:iCOffset-1))+1;
end
vOffset;
vAvailFirst         = Bi/B;
vBlockDelay(2:end)  = vOffset(2:end)-vAvailFirst(2:end)

% buffer initialization
vTxInd   = [1:6];
iNoTx    = length(vTxInd);
Y_out    = single(zeros(2*B,2));
vFDLInd  = 1:P;

% example
iNoBl   = 500;
x       = randn(iNoBl*B,length(vTxInd));
h       = randn(N,2,length(vTxInd),10);

%% prepare for segment 1
vInd1     = 0+[1:Bi(1)*Pi(1)];
H1        = single(fft(reshape(h(vInd1,:,:,:),Bi(1),Pi(1),2,iNoTx,[]),2*Bi(1),1));
H1(Bi(1)+2:end,:,:,:,:) = [];
mFDL_buf1 = single(zeros(Bi(1)+1,Pi(1),length(vTxInd)));
x_in_buf1 = single(zeros(2*Bi(1),length(vTxInd)));
%% prepare for segment 2
if length(Bi)>1
  vInd2     = vInd1(end)+[1:Bi(2)*Pi(2)];
  H2        = single(fft(reshape(h(vInd2,:,:,:),Bi(2),Pi(2),2,iNoTx,[]),2*Bi(2),1));
  H2(Bi(2)+2:end,:,:,:,:) = [];
  mFDL_buf2 = single(zeros(Bi(2)+1,Pi(2),length(vTxInd)));
  x_in_buf2 = single(zeros(2*Bi(2),length(vTxInd)));
end
%% prepare for segment 3
if length(Bi)>2
  vInd3     = vInd2(end)+[1:Bi(3)*Pi(3)];
  H3        = single(fft(reshape(h(vInd3,:,:,:),Bi(3),Pi(3),2,iNoTx,[]),2*Bi(3),1));
  H3(Bi(3)+2:end,:,:,:,:) = [];
  mFDL_buf3 = single(zeros(Bi(3)+1,Pi(3),length(vTxInd)));
  x_in_buf3 = single(zeros(2*Bi(3),length(vTxInd)));
end
%% prepare for segment 4
if length(Bi)>3
  vInd4     = vInd3(end)+[1:Bi(4)*Pi(4)];
  H4        = single(fft(reshape(h(vInd4,:,:,:),Bi(4),Pi(4),2,iNoTx,[]),2*Bi(4),1));
  H4(Bi(4)+2:end,:,:,:,:) = [];
  mFDL_buf4 = single(zeros(Bi(4)+1,Pi(4),length(vTxInd)));
  x_in_buf4 = single(zeros(2*Bi(4),length(vTxInd)));
end

%% reference
tic;
for iCRx=1:2
  for iCTx=1:6
    ytp(:,iCRx,iCTx) = conv(h(:,iCRx,iCTx,3),x(:,iCTx));
  end
end
ytarget = sum(ytp,3);
toc;

%% NUPOLS
N_RB_x  = Bi(end)/B+max(vSchedOffset);
N_RB_y  = vBlockDelay(end)+Bi(end)/B
x_ring  = zeros(B,N_RB_x,iNoTx);
y_ring  = zeros(B,N_RB_y,2);
iC1     = 0;
iC2     = 0;
iC3     = 0;
iC4     = 0;
vRunTime  = zeros(1,iNoBl);
for iC=1:iNoBl
%   disp(iC)
  tic;
  
  %   clc;
  %   disp(['Block no. ',int2str(iC),' ------------'])
  %% update ring buffer
  iCircPt_x             = mod(iC-1,N_RB_x)+1;
  iCircPt_y             = mod(iC-1,N_RB_y)+1;
  x_ring(:,iCircPt_x,:) = x((iC-1)*B+1:iC*B,:);
%   x_ring(:,:,1)
  iCircPt_y_Del         = mod(iCircPt_y-1-1,N_RB_y)+1;
  y_ring(:,iCircPt_y_Del,:) = 0;
  
  %% SEGMENT 1
  if mod(iC,Bi(1)/B==0) % when it is available, here every block
    iC1 = iC1 + 1;
%     disp('Segment 1 start');
    vInd1_x               = iCircPt_x;
    mIn                   = x_ring(:,vInd1_x,:);
    [y_part1,x_in_buf1,mFDL_buf1]  = UPConv(mIn,x_in_buf1,mFDL_buf1,vTxInd,H1,iC1,3,Bi(1),Pi(1));
%     tempo = reshape(y_part1,B,Bi(1)/B,[]); tempo(:,:,1)
    vInd1_y               = iCircPt_y;
    y_ring(:,vInd1_y,:)   = y_ring(:,vInd1_y,:) + reshape(y_part1,B,Bi(1)/B,[]);
%     y_ring(:,:,1)
  end
  
  %% SEGMENT 2
  if numel(Bi)>1 && mod(iC,Bi(2)/B)==0 % when it is available
%   tic;
    iC2 = iC2 + 1;
%     disp('Segment 2 start');
    vInd2_x               = mod(iCircPt_x+[-Bi(2)/B+1:0]-1,N_RB_x)+1;
    mIn                   = reshape(x_ring(:,vInd2_x,:),Bi(2),[]);
    [y_part2,x_in_buf2,mFDL_buf2]  = UPConv(mIn,x_in_buf2,mFDL_buf2,vTxInd,H2,iC2,3,Bi(2),Pi(2));
%     tempo = reshape(y_part2,B,Bi(2)/B,[]); tempo(:,:,1)
    vInd2_y               = mod(iCircPt_y+vBlockDelay(2)+[0:Bi(2)/B-1]-1,N_RB_y)+1;
    y_ring(:,vInd2_y,:)   = y_ring(:,vInd2_y,:) + reshape(y_part2,B,Bi(2)/B,[]);
%     y_ring(:,:,1)
%   toc;
  end
  %% SEGMENT 3
  if numel(Bi)>2 && mod(iC,Bi(3)/B)==0+vSchedOffset(3) % when it is available
    iC3 = iC3 + 1;
%     disp('******* Segment 3 start *************');
    vInd3_x               = mod(iCircPt_x-vSchedOffset(3)+[-Bi(3)/B+1:0]-1,N_RB_x)+1;
    mIn                   = reshape(x_ring(:,vInd3_x,:),Bi(3),[]);
    [y_part3,x_in_buf3,mFDL_buf3]  = UPConv(mIn,x_in_buf3,mFDL_buf3,vTxInd,H3,iC3,3,Bi(3),Pi(3));
%     tempo = reshape(y_part3,B,Bi(3)/B,[]); tempo(:,:,1)
    vInd3_y               = mod(iCircPt_y-vSchedOffset(3)+vBlockDelay(3)+[0:Bi(3)/B-1]-1,N_RB_y)+1;
    y_ring(:,vInd3_y,:)   = y_ring(:,vInd3_y,:) + reshape(y_part3,B,Bi(3)/B,[]);
%     y_ring(:,:,1)
  end
  
  %% SEGMENT 4
  if numel(Bi)>3 && mod(iC,Bi(4)/B)==0+vSchedOffset(4) % when it is available
    iC4 = iC4 + 1;
%     disp('******* Segment 4 start *************');
    vInd4_x               = mod(iCircPt_x-vSchedOffset(4)+[-Bi(4)/B+1:0]-1,N_RB_x)+1;
    mIn                   = reshape(x_ring(:,vInd4_x,:),Bi(4),[]);
    [y_part4,x_in_buf4,mFDL_buf4]  = UPConv(mIn,x_in_buf4,mFDL_buf4,vTxInd,H4,iC4,3,Bi(4),Pi(4));
%     tempo = reshape(y_part4,B,Bi(4)/B,[]); tempo(:,:,1)
    vInd4_y               = mod(iCircPt_y-vSchedOffset(4)+vBlockDelay(4)+[0:Bi(4)/B-1]-1,N_RB_y)+1;
    y_ring(:,vInd4_y,:)   = y_ring(:,vInd4_y,:) + reshape(y_part4,B,Bi(4)/B,[]);
%     y_ring(:,:,1)
  end
  
  %% take block from ring buffer
  y((iC-1)*B+1:iC*B,:)  = squeeze(y_ring(:,iCircPt_y,:));
%   reshape(y(1:iC*B,1),B,iC)
%   reshape(ytarget(1:iC*B,1),B,iC)
  vRunTime(iC) = toc;

end
% toc;
subplot(2,1,1)
plot(ytarget(:,1)); hold on;
plot(y(:,1))
subplot(2,1,2)
plot(ytarget(:,2)); hold on;
plot(y(:,2))

% function [y,x_in_buf,mFDL_buf] = UPConv(mIn,x_in_buf,mFDL_buf,vTxInd,H,iCount,B,P)
% 
% % fill input buffer
% x_in_buf(1:B,:)       = x_in_buf(B+1:end,:);
% x_in_buf(B+1:end,:)   = mIn(:,:);
% 
% % FFT
% mInFFT                = fft(x_in_buf,2*B,1);
% 
% % FDL
% iCircPt               = mod(P-iCount,P)+1;
% mFDL_buf(:,iCircPt,:) = mInFFT(1:B+1,:);
% % vFDLInd               = circshift(vFDLInd,1)
% vFDLInd               = circshift([1:P],1-iCircPt);
% 
% % product of spectra, sum subspectra and IFFT
% Y_out(1:B+1,1)        = sum(sum(squeeze(mFDL_buf(:,vFDLInd,:)).*squeeze(H(:,:,1,vTxInd,3)),3),2);
% Y_out(1:B+1,2)        = sum(sum(squeeze(mFDL_buf(:,vFDLInd,:)).*squeeze(H(:,:,2,vTxInd,3)),3),2);
% 
% % Y_out(1:B+1,1)        = sum(mFDL_buf(:,vFDLInd).*H,2);
% y_out_tp              = ifft(Y_out,2*B,1,'symmetric');
% y                     = y_out_tp(B+1:end,:);
% end
function [H1,mFDL_buf1_old,mFDL_buf1_cur,x_in_buf1_old,x_in_buf1_cur,iC1,...
  H2,mFDL_buf2_old,mFDL_buf2_cur,x_in_buf2_old,x_in_buf2_cur,iC2,...
  H3,mFDL_buf3_old,mFDL_buf3_cur,x_in_buf3_old,x_in_buf3_cur,iC3,...
  H4,mFDL_buf4_old,mFDL_buf4_cur,x_in_buf4_old,x_in_buf4_cur,iC4,...
  x_ring,y_ring_cur,y_ring_old,B,Bi,Pi,N_RB_x,N_RB_y,N,...
  vBlockDelay,vSchedOffset]...
  = InitializeNUPOLS(frameLength,mIRInt)

iNoTx = size(mIRInt,3);
B     = frameLength;
% proposed config for B=128
if B==128
  Bi  = [1,2,8,64]*B;
  Pi  = [2,4,8,7];
  %  Pi  = [2,4,8,10]; % optimal
end
if B==256
  Bi  = [1,2,4,16]*B;
  Pi  = [2,4,10,12];
end
if B==512
  Bi  = B*[1,2,4,16];
  Pi  = [2,2,4,6];
  %   Bi  = [1,2]*B;
  %   Pi  = [2,2];
  %   Bi = [1,2,8,32]*B;
  %   Pi = [2,4,5,2]
end
vSchedOffset = [0,0,1,3]; % Bi=[1,2,4,16]->[0,0,1,3] or [0,0,1,7]
N = sum(Bi.*Pi);
disp(['Filter length: ',int2str(N)])
vOffset     = zeros(size(Bi));
vBlockDelay = zeros(size(Bi));
for iCOffset = 2:length(vOffset)
  vOffset(iCOffset) = sum(Bi(1:iCOffset-1)/B.*Pi(1:iCOffset-1))+1;
end
vAvailFirst         = Bi/B;
vBlockDelay(2:end)  = vOffset(2:end)-vAvailFirst(2:end);

%% buffer initialization
iNoAngleAz = size(mIRInt,4);
iNoAngleEl = size(mIRInt,5);
h                           = zeros(max(N,size(mIRInt,1)),size(mIRInt,2),size(mIRInt,3),iNoAngleAz,iNoAngleEl);
h(1:size(mIRInt,1),:,:,:,:) = mIRInt(1:size(mIRInt,1),:,:,:,:);
%% prepare for segment 1
vInd1     = 0+(1:Bi(1)*Pi(1));
H1        = single(fft(reshape(h(vInd1,:,:,:),Bi(1),Pi(1),2,iNoTx,iNoAngleAz,iNoAngleEl),2*Bi(1),1));
H1(Bi(1)+2:end,:,:,:,:,:) = [];
mFDL_buf1_old = single(zeros(Bi(1)+1,Pi(1),iNoTx));
mFDL_buf1_cur = single(zeros(Bi(1)+1,Pi(1),iNoTx));
x_in_buf1_old = single(zeros(2*Bi(1),iNoTx));
x_in_buf1_cur = single(zeros(2*Bi(1),iNoTx));
%% prepare for segment 2
if length(Bi)>=2
  vInd2     = vInd1(end)+(1:Bi(2)*Pi(2));
  H2        = single(fft(reshape(h(vInd2,:,:,:),Bi(2),Pi(2),2,iNoTx,iNoAngleAz,iNoAngleEl),2*Bi(2),1));
  H2(Bi(2)+2:end,:,:,:,:,:) = [];
  mFDL_buf2_old = single(zeros(Bi(2)+1,Pi(2),iNoTx));
  mFDL_buf2_cur = single(zeros(Bi(2)+1,Pi(2),iNoTx));
  x_in_buf2_old = single(zeros(2*Bi(2),iNoTx));
  x_in_buf2_cur = single(zeros(2*Bi(2),iNoTx));
end
%% prepare for segment 3
if length(Bi)>=3
  vInd3     = vInd2(end)+(1:Bi(3)*Pi(3));
  H3        = single(fft(reshape(h(vInd3,:,:,:),Bi(3),Pi(3),2,iNoTx,iNoAngleAz,iNoAngleEl),2*Bi(3),1));
  H3(Bi(3)+2:end,:,:,:,:,:) = [];
  mFDL_buf3_old = single(zeros(Bi(3)+1,Pi(3),iNoTx));
  mFDL_buf3_cur = single(zeros(Bi(3)+1,Pi(3),iNoTx));
  x_in_buf3_old = single(zeros(2*Bi(3),iNoTx));
  x_in_buf3_cur = single(zeros(2*Bi(3),iNoTx));
end
%% prepare for segment 4
if length(Bi)>=4
  vInd4     = vInd3(end)+(1:Bi(4)*Pi(4));
  H4        = single(fft(reshape(h(vInd4,:,:,:),Bi(4),Pi(4),2,iNoTx,iNoAngleAz,iNoAngleEl),2*Bi(4),1));
  H4(Bi(4)+2:end,:,:,:,:,:) = [];
  mFDL_buf4_old = single(zeros(Bi(4)+1,Pi(4),iNoTx));
  mFDL_buf4_cur = single(zeros(Bi(4)+1,Pi(4),iNoTx));
  x_in_buf4_old = single(zeros(2*Bi(4),iNoTx));
  x_in_buf4_cur = single(zeros(2*Bi(4),iNoTx));
%   x_in_buf4     = single(zeros(2*Bi(4),iNoTx));
end
%% NUPOLS parameters
N_RB_x      = Bi(end)/B+max(vSchedOffset);
N_RB_y      = vBlockDelay(end)+Bi(end)/B;
x_ring      = single(zeros(B,N_RB_x,iNoTx));
y_ring_old  = single(zeros(B,N_RB_y,2));
y_ring_cur  = single(zeros(B,N_RB_y,2));
iC1         = 0;
iC2         = 0;
iC3         = 0;
iC4         = 0;
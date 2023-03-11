function [] = Filter_Stefan(sAudioFileName)
sAudioProperties  = audioinfo([sAudioFileName,'.wav']);
mIn               = audioread([sAudioFileName,'.wav']);
load('mIR_Stefan.mat');
mOut              = single(zeros(size(mIn,1),2));
for iCTx = 1:size(mIn,2)
  for iCRx = 1:2
    if iCTx~=4
      mOut(:,iCRx) = mOut(:,iCRx) + fftfilt(mIR(:,iCRx,iCTx),mIn(:,iCTx));
    else % LFE
      mOut(:,iCRx) = 0.5*mIn(:,iCTx);
    end
  end
end
sAudioFileNameOut = [sAudioFileName,'_out.wav']
audiowrite(sAudioFileNameOut,mOut,sAudioProperties.SampleRate);
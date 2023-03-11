function [fileReader,deviceWriterHeadphone,deviceWriterSpeaker] = ...
  SetAudioInterface(sAudioInterface,sDriverName,frameLength,iNoTx,fSamplFreq)
%% SetAudioInterface
switch sAudioInterface
  case 'Babyface' % RME Babyface (stereo output)
    switch sDriverName 
      case 'ASIO'
        % Windows
        sAudioDevice    = 'ASIO Fireface USB';
      case 'CoreAudio'
        % macOS
        sAudioDevice    = 'Babyface Pro (71969190)';
      otherwise
        disp('operating system not supported');
    end
    fileReader      = audioDeviceReader('Device',sAudioDevice,'Driver',sDriverName,...
      'SamplesPerFrame',frameLength,'NumChannels',iNoTx,'SampleRate',fSamplFreq);
    deviceWriterHeadphone   = audioDeviceWriter('Device',sAudioDevice,...
      'Driver',sDriverName,'SampleRate',fileReader.SampleRate,'BufferSize',32);
    deviceWriterSpeaker     = audioDeviceWriter('Device',sAudioDevice,...
      'Driver',sDriverName,'SampleRate',fileReader.SampleRate,'BufferSize',32);
    set(fileReader,...
      'ChannelMappingSource','Property','ChannelMapping',6+[1:iNoTx]);
    set(deviceWriterHeadphone,...
      'ChannelMappingSource','Property','ChannelMapping',8+[1,2]);
    set(deviceWriterSpeaker,...
      'ChannelMappingSource','Property','ChannelMapping',6+[1:iNoTx]);
  
  case 'Fireface'  % RME Fireface (surround)
    sAudioDevice    = 'ASIO Fireface USB';
    fileReader      = audioDeviceReader('Driver','ASIO','Device',sAudioDevice,...
      'SamplesPerFrame',frameLength,'NumChannels',iNoTx,'SampleRate',fSamplFreq);
    deviceWriterHeadphone   = audioDeviceWriter('Device',sAudioDevice,...
      'Driver','ASIO','SampleRate',fileReader.SampleRate,'BufferSize',32);
    deviceWriterSpeaker     = audioDeviceWriter('Device',sAudioDevice,...
      'Driver','ASIO','SampleRate',fileReader.SampleRate,'BufferSize',32);
    set(fileReader,...
      'ChannelMappingSource','Property','ChannelMapping',10+[1:iNoTx]);
    set(deviceWriterHeadphone,...
      'ChannelMappingSource','Property','ChannelMapping',6+[1:2]);
    set(deviceWriterSpeaker,...
      'ChannelMappingSource','Property','ChannelMapping',10+[1:iNoTx]);
    
  case 'Banana'  % Arbitrary sound interface
    sAudioReader    = 'Voicemeeter Virtual ASIO';
    sAudioWriter    = 'Voicemeeter Virtual ASIO';
    fileReader      = audioDeviceReader('Driver','ASIO','Device',sAudioReader,...
      'SamplesPerFrame',frameLength,'NumChannels',iNoTx,'SampleRate',fSamplFreq);
    switch iNoTx
      case 2
        set(fileReader,...
        'ChannelMappingSource','Property','ChannelMapping',[1:2]);
      case 6
        set(fileReader,...
        'ChannelMappingSource','Property','ChannelMapping',[1:4,7,8]);
    end
    deviceWriterHeadphone   = audioDeviceWriter('Driver','ASIO','Device',sAudioWriter,...
      'SampleRate',fileReader.SampleRate,'BufferSize',1024,'SampleRate',fSamplFreq);
    set(deviceWriterHeadphone,...
      'ChannelMappingSource','Property','ChannelMapping',[5:6]);
    deviceWriterSpeaker     = audioDeviceWriter('Driver','ASIO','Device',sAudioWriter,...
      'SampleRate',fileReader.SampleRate,'BufferSize',1024,'SampleRate',fSamplFreq);    
    set(deviceWriterSpeaker,...
      'ChannelMappingSource','Property','ChannelMapping',[5:6]);
    
  otherwise
    warning('No valid audio interface selected');
end
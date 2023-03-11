load vAngleVsTime2;
vAngleVsTimeDiff    = diff([0,vAngleVsTime]);
vIndChange          = find(vAngleVsTimeDiff~=0);
vAngleVsTimeInterp  = interp1(vIndChange,vAngleVsTime(vIndChange),[1:length(vAngleVsTime)],'pchip');
% figure
% plot(vAngleVsTime); hold on;
% plot(vIndChange,vAngleVsTime(vIndChange),'.')
% plot(vAngleVsTimeInterp)
grid on

%% normalize training data
data = vAngleVsTimeInterp;

numTimeStepsTrain = floor(0.99*numel(data));

dataTrain = data(1:numTimeStepsTrain+1);
dataTest  = data(numTimeStepsTrain+1:end);

mu        = 0;
sig       = std(dataTrain);

dataTrainStandardized = (dataTrain - mu) / sig;


%% LSTM network
% XTrain = dataTrainStandardized(1:end-1);
% YTrain = dataTrainStandardized(2:end);
% numFeatures = 1;
% numResponses = 1;
% numHiddenUnits = 100;
% 
% layers = [ ...
%     sequenceInputLayer(numFeatures)
%     lstmLayer(numHiddenUnits)
%     fullyConnectedLayer(numResponses)
%     regressionLayer];
%   
% options = trainingOptions('adam', ...
%     'MaxEpochs',100, ...
%     'GradientThreshold',1, ...
%     'InitialLearnRate',0.005, ...
%     'LearnRateSchedule','piecewise', ...
%     'LearnRateDropPeriod',200, ...
%     'LearnRateDropFactor',0.25, ...
%     'Verbose',0, ...
%     'Plots','training-progress');
%   
% net = trainNetwork(XTrain,YTrain,layers,options);
% save('Neural_Network_512','net','sig','XTrain');

%% fully connected network
XTrain = [];
iWinLen = 20;
for iC = 1:length(dataTrainStandardized)-iWinLen-1
  XTrain(:,iC) = dataTrainStandardized(1,iC:iC+iWinLen-1);
  YTrain(1,iC) = dataTrainStandardized(1,iC+iWinLen);
end

layers = [ ...
    sequenceInputLayer(size(XTrain,1))
    fullyConnectedLayer(50)
    fullyConnectedLayer(25)
    fullyConnectedLayer(1)
    regressionLayer];
options = trainingOptions('adam', ...
    'MaxEpochs',1000, ...
    'GradientThreshold',1, ...
    'InitialLearnRate',0.005, ...
    'LearnRateSchedule','piecewise', ...
    'LearnRateDropPeriod',200, ...
    'LearnRateDropFactor',0.25, ...
    'Verbose',0, ...
    'Plots','training-progress');
net = trainNetwork(XTrain,YTrain,layers,options);
save('Neural_Network_FC_512','net','sig');

%% testing procedure
% dataTestStandardized = (dataTest - mu) / sig;
% XTest = dataTestStandardized(1:end-1);
% 
% net = predictAndUpdateState(net,XTrain);
% [net,YPred] = predictAndUpdateState(net,YTrain(end));
% numTimeStepsTest = numel(XTest);
% for i = 2:numTimeStepsTest
%     [net,YPred(:,i)] = predictAndUpdateState(net,YPred(:,i-1),'ExecutionEnvironment','cpu');
% end
% YPred = sig*YPred + mu;
% 
% YTest = dataTest(2:end);
% rmse = sqrt(mean((YPred-YTest).^2))
% 
% figure
% plot(dataTrain(1:end-1))
% hold on
% idx = numTimeStepsTrain:(numTimeStepsTrain+numTimeStepsTest);
% plot(idx,[data(numTimeStepsTrain) YPred],'.-')
% hold off
% legend(["Observed" "Forecast"])
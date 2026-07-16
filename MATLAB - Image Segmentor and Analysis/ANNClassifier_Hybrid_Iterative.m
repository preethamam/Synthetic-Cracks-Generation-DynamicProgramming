%//%************************************************************************%
%//%*                              Ph.D                                    *%
%//%*                           Crack Package						       *%
%//%*                                                                      *%
%//%*             Name: Preetham Manjunatha                		           *%
%//%*             USC ID Number: 7356627445		                           *%
%//%*             USC Email: aghalaya@usc.edu                              *%
%//%*             Submission Date: --/--/2017                              *%
%//%************************************************************************%
%//%*             Viterbi School of Engineering,                           *%
%//%*             Sonny Astani Dept. of Civil Engineering,                 *%
%//%*             University of Southern california,                       *%
%//%*             Los Angeles, California.                                 *%
%//%************************************************************************%

%% Start parameters
%//%************************************************************************%
clear; close all; clc;
if(isempty(gcp('nocreate')))
    parpool;
end
tic;
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);

%% This script assumes these variables are defined:
%//%************************************************************************%
%   Feature_matrix - input data
%   Labels - target data

% Change of variables
% [ 1 2 3 4 5 6 6 7 7 8 8 8 ...... 12]
% [ 1 2 3 4 5 6 6 7 7 8 8 8 ...... 12]
% [ 1 2 3 4 5 6 6 7 7 8 8 8 ...... 12]
%  . . . . . . . . . . . . . . . . . .
% [ 1 2 3 4 5 6 6 7 7 8 8 8 ...... 12]
% [ 1 2 3 4 5 6 6 7 7 8 8 8 ...... 12]
% rows x columns [n x m]
% n - samples; m - features (requires transpose). Similarly, to
% labels/targets
% If not the above format, then no need to transpose

% Feature matrix (transposed) and % Labels/targets (transposed)
load ZZZ_XYTargets5JahanFeat_elastic_morpho_combo_JahanSynRot5_90_v1_1280_720_Unique.mat Xtrain Xval Xtest Ytrain Yval Ytest ...
    Targettrain Targetval Targettest

kraken = 'ZZZ_XYTargets5JahanFeat_elastic_hybrid_combo_JahanSynRot5_90_v1_1280_720.mat'
beast  = 'ZZZ_XYTargets5JahanFeat_elastic_morpho_combo_JahanSynRot5_90_v1_1280_720_Unique_100000.mat'
mackey = 'ZZZ_XYTargets5JahanFeat_elastic_morpho_combo_JahanSynRot5_90_v1_1280_720'
ghost  = ''

x = [Xtrain; Xval; Xtest]';
t = [Targettrain; Targetval; Targettest]';

% Number of hidden layers [maximum 3]
hidden_layers = 1;

% Hidden layer size
hiddenLayerSize_Vec = 10:5:50;         % 1HL
% hiddenLayerSize_Vec   = 10:10:200;   % 2HL
% hiddenLayerSize_Vec = 10:10:200;   % 3 HL

% Window view / plotting options [on | off]
plotter      = 'no';
viewfinalnet = 'off';

%% Create hidden layers (>1) neuron units combinations
%//%************************************************************************%
switch hidden_layers    
    case 1
        pairs = hiddenLayerSize_Vec(:);
        
    case 2
        [p,q] = meshgrid(hiddenLayerSize_Vec, hiddenLayerSize_Vec);
        pairs = [p(:) q(:)];
        
    case 3
        [p,q,r] = meshgrid(hiddenLayerSize_Vec, hiddenLayerSize_Vec, hiddenLayerSize_Vec);
        pairs = [p(:) q(:) r(:)];     
end

%% Train the network
%//%************************************************************************%
% Waitbar handler
h = waitbar(0,'Initializing...','Name','Finding optimum number of neurons...!',...
            'CreateCancelBtn',...
            'setappdata(gcbf,''canceling'',1)');
setappdata(h,'canceling',0)

for incStep = 1 : size(pairs,1)
    
    % Check for Cancel button press
    if getappdata(h,'canceling')
        break
    end

    
    % Random seed generator
    rng('default')
    
    % Create a Pattern Recognition Network
    net = patternnet(pairs(incStep,:));

    
    % Network options
    %//%*******************************************************************
    % Choose Input and Output Pre/Post-Processing Functions
    % For a list of all processing functions type: help nnprocess
    net.input.processFcns = {'removeconstantrows','mapminmax'}; % mapstd mapminmax
    net.output.processFcns = {'removeconstantrows','mapminmax'}; % mapstd mapminmax

    % Setup Division of Data for Training, Validation, Testing
    % For a list of all data division functions type: help nndivide
    net.divideFcn =  'divideind'; %'divideind';  % Divide data randomly
    net.divideMode =  'sample';%'none';  % Divide up every sample

    % Divide the datasets by index
    net.divideParam.trainInd = 1 : size(Xtrain,1);

    if (~isempty(Xval))
        net.divideParam.valInd   = size(Xtrain,1) + 1 : ...
                                   size(Xtrain,1) + size(Xval,1);
    else
        net.divideParam.valInd   = [];
    end
    net.divideParam.testInd  = size(Xtrain,1) + size(Xval,1) + 1 :...
                               size(Xtrain,1) + size(Xval,1) + ...
                               size(Xtest,1);

    % Train parameters
    net.trainFcn = 'trainscg';  %'trainlm' 'trainscg' 'traingdx' 'traingda' 'traingdm' 'traingd'
    net.trainParam.epochs = 1000;
    net.trainParam.goal = 1e-3 ;
    net.trainParam.showCommandLine = true;
    net.trainParam.show	= 25;
    net.trainParam.max_fail = 100;
    net.trainParam.min_grad=1e-6;
    net.trainParam.lr = 0.01;

    % Choose a Performance Function
    % For a list of all performance functions type: help nnperformance
    net.performFcn = 'crossentropy';  % Cross-entropy

    % Change the transfer function for all hidden layers [output layer in deafult 'softmax']
    for i = 1:size(pairs,2)
        net.layers{i}.transferFcn = 'logsig'; %'logsig'; %'softmax'; %'tansig';
    end

    % Turn on/off nntraintoll window
    net.trainParam.showWindow = 0;

    % Callback of neural netwrok function
    % Train the Network
    [net,tr] = train(net,x,t,'useParallel','yes','useGPU','yes');

    % Test the Network
    y = net(x,'useParallel','yes','useGPU','yes'); 
%     y  = sim (net, Xtest');

   % e = gsubtract(t,y);
    ActualTrainind  = vec2ind(t(:,tr.trainInd(:)));
    PredictTrainind = vec2ind(y(:,tr.trainInd(:)));
    percentErrorsTrain = sum(ActualTrainind ~= PredictTrainind)/numel(ActualTrainind);
        
    ActualTestind  = vec2ind(t(:,tr.testInd(:)));
    PredictTestind = vec2ind(y(:,tr.testInd(:)));
    percentErrorsTest = sum(ActualTestind ~= PredictTestind)/numel(ActualTestind);
    
    % Performance
    performance   = perform(net,t,y);

    % Recalculate Training, Validation and Test Performance
    trainTargets = t .* tr.trainMask{1};
    valTargets   = t .* tr.valMask{1};
    testTargets  = t .* tr.testMask{1};
    trainPerformance = perform(net,trainTargets,y);
    valPerformance   = perform(net,valTargets,y);
    testPerformance  = perform(net,testTargets,y);
    
    % Store error outputs
    NNerrDetails(incStep).trainErrTotal = percentErrorsTrain;
    NNerrDetails(incStep).testErrTotal = percentErrorsTest;
    NNerrDetails(incStep).testAccuracy = 1 - percentErrorsTest;
    NNerrDetails(incStep).neuronUnits  = pairs(incStep,:);
    
    % Report current estimate in the waitbar's message field
    waitbar(incStep/length(pairs), h, sprintf('HLU itr. = %i | Accuracy: %1.3f',...
            incStep, 1 - percentErrorsTest))
        
    % Average precision and recall
    [C,order] = confusionmat(ActualTestind,PredictTestind); %,'order',grouporder);
    [avgPresicion, avgRecall, avgAccuracy, avgSpecificity, avgF1score] ...
            = multiclassPrecision_Recall(C);
    TotalConfMat(:,:,incStep) = C;
    
    % Store classification measures
    NNerrDetails(incStep).avgPresicion       = avgPresicion;
    NNerrDetails(incStep).avgRecall          = avgRecall;
    NNerrDetails(incStep).avgAccuracy        = avgAccuracy;
    NNerrDetails(incStep).avgSpecificity     = avgSpecificity;
    NNerrDetails(incStep).avgF1score         = avgF1score;
end

% DELETE the waitbar; don't try to CLOSE it
delete(h)

%% View network
if (strcmp(viewfinalnet, 'on'))
    view (finalnet)
end

%% End parameters
% Close figures, waitbars and all
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);

% Close nntraintool window
nntraintool('close');

% Runtime
Runtime = toc;

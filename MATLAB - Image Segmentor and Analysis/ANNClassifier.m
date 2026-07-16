%//%************************************************************************%
%//%*                              Ph.D                                    *%
%//%*                           Crack Package						       *%
%//%*                                                                      *%
%//%*             Name: Preetham Aghalaya Manjunatha    		           *%
%//%*             USC Email: aghalaya@usc.edu                              *%
%//%*             Submission Date: --/--/2012                              *%
%//%************************************************************************%
%//%*             Viterbi School of Engineering,                           *%
%//%*             Sonny Astani Dept. of Civil Engineering,                 *%
%//%*             University of Southern california,                       *%
%//%*             Los Angeles, California.                                 *%
%//%************************************************************************%
%% Start parameters
%//%************************************************************************%
clear; close all; clc;
tic;
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);

%% This script assumes these variables are defined:
%//%************************************************************************%

% Add MAT files folder
addpath('../MAT Files')

% Feature matrix (transposed) and % Labels/targets (transposed)
load ZZZ_XYTargets5JahanFeat_morpho_Realworld_elasticDefAug.mat Xtrain Xval Xtest Ytrain Yval Ytest ...
    Targettrain Targetval Targettest

%%
x = [Xtrain; Xval; Xtest]';
t = [Targettrain; Targetval; Targettest]';

% Number of hidden layers [maximum 3]
% Paper details v1/v2: | morpho: [50,30,30] ; hybrid: [30,30,10];
% Paper details combo: | morpho: [10,20,30] ; hybrid: [30,30,10]; 
hidden_layers = 1;
pairs = 10; %[30,20,10];  %[30 30 30]; % Ideal 2 Layer [30 170] 
AVGIteration = 1;

% Window view / plotting options [on | off]
plotter      = 'no';
viewfinalnet = 'off';

%% Train the network
%//%************************************************************************%
% Waitbar handler
h = waitbar(0,'Initializing...','Name','Finding optimum number of neurons...!',...
            'CreateCancelBtn',...
            'setappdata(gcbf,''canceling'',1)');
setappdata(h,'canceling',0)

for incStep = 1 : AVGIteration
    
    % Check for Cancel button press
    if getappdata(h,'canceling')
        break
    end
    
    % Random seed generator
    rng('default')
    
    % Train the network
    %//%************************************************************************%            
    % Create a Pattern Recognition Network
    net = patternnet(pairs);

    %
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
    % net.divideParam.trainInd = 1 : size(Xtrain,1);        
    % net.divideParam.valInd   = [];
    % net.divideParam.testInd  =  size(Xtrain,1)+1 : size(x,2);

    % net.divideParam.trainInd = 1 : 600;        
    % net.divideParam.valInd   = [];
    % net.divideParam.testInd  =  600+1 : 699;

    % Setup Division of Data for Training, Validation, Testing
    % net.divideParam.trainRatio = 70/100;
    % net.divideParam.valRatio = 15/100;
    % net.divideParam.testRatio = 15/100;

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
    net.trainParam.min_grad = 1e-6;
    net.trainParam.lr = 0.01;

    % Choose a Performance Function
    % For a list of all performance functions type: help nnperformance
    net.performFcn = 'crossentropy';  % Cross-entropy

    % Change the transfer function for all hidden layers [output layer in deafult 'softmax']
    for i = 1:size(pairs,2)
        net.layers{i}.transferFcn = 'tansig'; %'logsig'; %'softmax'; %'tansig';
    end

    % Turn on/off nntraintoll window
    net.trainParam.showWindow = 0;
    
    % Callback of neural netwrok function
    % Train the Network
    [net,tr] = train(net,x,t,'useParallel','yes'); %,'useGPU','yes');

    % Test the Network
    y = net(x,'useParallel','yes'); %,'useGPU','yes');
    
    % Training error
    ActualTrainind  = vec2ind(t(:,tr.trainInd(:)));
    PredictTrainind = vec2ind(y(:,tr.trainInd(:)));
    percentErrorsTrain = sum(ActualTrainind ~= PredictTrainind)/numel(ActualTrainind);
    
    % Validation error
    ActualValind  = vec2ind(t(:,tr.valInd(:)));
    PredictValind = vec2ind(y(:,tr.valInd(:)));
    percentErrorsVal = sum(ActualValind ~= PredictValind)/numel(ActualValind);

    % Performance
    performance   = perform(net,t,y);

    % Recalculate Training, Validation and Test Performance
    trainTargets = t .* tr.trainMask{1};
    valTargets   = t .* tr.valMask{1};
    
    trainPerformance = perform(net,trainTargets,y);
    valPerformance   = perform(net,valTargets,y);        
    
    % Store error outputs
    NNerrDetails(incStep).trainErrTotal = percentErrorsTrain;    
    NNerrDetails(incStep).neuronUnits  = pairs;      
    
    if ~ isempty(Ytest)
        % Test errors and metrics
        ActualTestind  = vec2ind(t(:,tr.testInd(:)));
        PredictTestind = vec2ind(y(:,tr.testInd(:)));
        percentErrorsTest = sum(ActualTestind ~= PredictTestind)/numel(ActualTestind);
    
        testTargets  = t .* tr.testMask{1};
        testPerformance  = perform(net,testTargets,y);
    
        NNerrDetails(incStep).testErrTotal = percentErrorsTest;
        NNerrDetails(incStep).testAccuracy = 1 - percentErrorsTest;
    
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
        
        % Plot confusion matrix
        plotconfusion(Targettest', y(:,tr.testInd(:)))
    else
        percentErrorsTest = NaN;
    end

    % Report current estimate in the waitbar's message field
    waitbar(incStep/AVGIteration, h, sprintf('HLU itr. = %i | Accuracy: %1.3f',...
            incStep, 1 - percentErrorsTest))  
end

% DELETE the waitbar; don't try to CLOSE it
delete(h)

%% View network
if (strcmp(viewfinalnet, 'on'))
    view(net)
end

%% End parameters
% Close figures, waitbars and all
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);

% Close nntraintool window
% nntraintool('close');

% Runtime
Runtime = toc;

% ZZZ_MdlANN_elastic_mfat_combo_JahanSynRot5_90_v1_1280_720_Unique_100000

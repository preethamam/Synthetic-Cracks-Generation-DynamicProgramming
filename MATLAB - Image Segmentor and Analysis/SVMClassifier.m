%//%************************************************************************%
%//%*                              Ph.D                                    *%
%//%*                           Crack Package						       *%
%//%*                                                                      *%
%//%*             Name: Preetham Manjunatha              		           *%
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
%   Feature_matrix - input data
%   Labels - target data

% Add MAT files folder
addpath('../MAT Files')

load ZZZ_XYTargets5JahanFeat_mfat_Realworld+elasticDefAug+synthetic.mat Xtrain Xval Xtest Ytrain Yval Ytest ...
                   Targettrain Targetval Targettest
useparallel = 'no';
kernelType = 'radial';  % 'radial' | 'polynomial' 
kernelPolyorder = 3;

%% SVM Train/test
%//%************************************************************************%
% t = templateSVM('KernelFunction','linear');
% pool = parpool; % Invoke workers
% options = statset('UseParallel',0);
% Random seed generator
rng('default')
    
%Train the SVM Classifier
switch useparallel
    case 'yes'
        switch kernelType
            case 'radial'
                MdlSVM = fitcsvm(Xtrain,Ytrain,'KernelFunction','rbf',...
                    'BoxConstraint',1e3,'KernelScale', 'auto', 'ClassNames',[1,2],...
                    'Verbose',1,'IterationLimit',1e6,'OptimizeHyperparameters','auto','HyperparameterOptimizationOptions',struct('UseParallel',...
                    true));
            case 'polynomial'
                MdlSVM = fitcsvm(Xtrain,Ytrain,'KernelFunction','polynomial', 'PolynomialOrder', kernelPolyorder, ...
                    'BoxConstraint',1e3,'KernelScale', 'auto', 'ClassNames',[1,2],...
                    'Verbose',1,'IterationLimit',1e6,'OptimizeHyperparameters','auto','HyperparameterOptimizationOptions',struct('UseParallel',...
                    true));
        end
    case 'no'
        switch kernelType
            case 'radial'
                MdlSVM = fitcsvm(Xtrain,Ytrain,'KernelFunction','rbf',...
                    'BoxConstraint',1e3,'KernelScale', 'auto', 'ClassNames',[1,2],...
                    'Verbose',1,'IterationLimit',1e6);
            case 'polynomial'
                MdlSVM = fitcsvm(Xtrain,Ytrain,'KernelFunction','polynomial', 'PolynomialOrder', kernelPolyorder,...
                    'BoxConstraint',1e3,'KernelScale', 'auto', 'ClassNames',[1,2],...
                    'Verbose',1,'IterationLimit',1e6);
        end
end
disp('Finished MdlSVM');

% Cross validate
% CVMdlSVM = crossval(MdlSVM);
% classLoss = kfoldLoss(CVMdlSVM);

% Re substituition score
% ScoreSVMModel = fitPosterior(MdlSVM);
% [~,score_svmTr] = resubPredict(ScoreSVMModel);
score_svmTr = [];
% disp('Finished ScoreSVMModel');


%% Testing
% SVM probabilities of predictions
CompactSVMModel = compact(MdlSVM);
[ScoreCSVMModel,ScoreParameters] = fitPosterior(CompactSVMModel,...
                                                Xtrain,Ytrain);

% Train accuracy
[yTrain,score_knnTr,costTr] = predict(MdlSVM,Xtrain);
percentErrorsTr = sum(yTrain ~= Ytrain)/numel(Ytrain);
accuracyTrain = 1 - percentErrorsTr;

% Val accuracy
[yVal,score_knnVal,costVal] = predict(MdlSVM,Xval);
percentErrorsVal = sum(yVal ~= Yval)/numel(Yval);
accuracyVal = 1 - percentErrorsVal;

if ~ isempty(Ytest)
    [labels,postProbs] = predict(ScoreCSVMModel,Xtest);
    
    % Test the SVM
    [yTest,score_svmTs,costTest] = predict(MdlSVM,Xtest);
    percentErrorsTest = sum(yTest ~= Ytest)/numel(Ytest);
    accuracyTest = 1 - percentErrorsTest;
    
    % Average precision and recall
    [C_svm,order_svm] = confusionmat(Ytest,yTest); %,'order',grouporder);
    [avgPresicion_svm, avgRecall_svm, avgAccuracy_svm, avgSpecificity_svm, ...
        avgF1score_svm] = multiclassPrecision_Recall(C_svm);
    
    
    %% Precision-recall plot
    % Test
    [XsvmTs,YsvmTs,TsvmTs,AUCsvmTs] = perfcurve(Ytest, score_svmTs(:,2), 2, ...
                                        'xCrit', 'reca', 'yCrit', 'prec','xvals','all');
                                    
    % Train
    if ~(isempty(score_svmTr)) 
        [XsvmTr,YsvmTr,TsvmTr,AUCsvmTr] = perfcurve(Ytrain,score_svmTr(:,2), 2, ...
                                        'xCrit', 'reca', 'yCrit', 'prec','xvals','all');
    else
        XsvmTr = XsvmTs;
        YsvmTr = zeros(size(YsvmTs));
        TsvmTr = [];
        AUCsvmTr = 0;
    end
    
    figure;
    plot(XsvmTr,YsvmTr, '--r', 'LineWidth',3)
    hold on
    plot(XsvmTs,YsvmTs, '-b', 'LineWidth',3)
    hold off
    grid on
    xlabel('Recall'); ylabel('Precision')
    legend ('Precision-recall Train Dataset', 'Precision-recall Test Dataset')
    legend ( 'Precision-recall Test Dataset')
    title(['SVM Precision-recall curve (AUC Train: ' ...
            num2str(AUCsvmTr) ' | ' 'AUC Test: ' num2str(AUCsvmTs) ')'])
end

%% End parameters
% Close figures, waitbars and all
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);

% Runtime
Runtime = toc;


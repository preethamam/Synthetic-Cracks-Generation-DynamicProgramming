%//%************************************************************************%
%//%*                              Ph.D                                    *%
%//%*                           Crack Package						       *%
%//%*                                                                      *%
%//%*             Name: Preetham Manjunatha             		           *%
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
tic;
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);

%% This script assumes these variables are defined:
%//%************************************************************************%
%   Feature_matrix - input data
%   Labels - target data

% Add MAT files folder
addpath('../MAT Files')

load ZZZ_XYTargets5JahanFeat_hessian_Realworld+elasticDefAug+synthetic.mat Xtrain Xval Xtest Ytrain Yval Ytest ...
                   Targettrain Targetval Targettest
useparallel = 'no';

%% KNN Train/test
%//%************************************************************************%
% Random seed generator
rng('default')

switch useparallel
    case 'yes'
        MdlKNN = fitcknn(Xtrain,Ytrain,'NumNeighbors',5,...
            'NSMethod','exhaustive','Distance','euclidean','OptimizeHyperparameters','auto','HyperparameterOptimizationOptions',...
            struct('Verbose',1,'UseParallel',true));
    case 'no'
        MdlKNN = fitcknn(Xtrain,Ytrain,'NumNeighbors',5,...
            'NSMethod','exhaustive','Distance','euclidean');
end

% cvmdl = crossval(MdlKNN,'kfold',10);
% kloss = kfoldLoss(cvmdl);

% Find posterior probabilities
% [~,score_knnTr] = resubPredict(MdlKNN);
score_knnTr = [];

% Train accuracy
[yTrain,score_knnTr,costTr] = predict(MdlKNN,Xtrain);
percentErrorsTr = sum(yTrain ~= Ytrain)/numel(Ytrain);
accuracyTrain = 1 - percentErrorsTr;

% Val accuracy
[yVal,score_knnVal,costVal] = predict(MdlKNN,Xval);
percentErrorsVal = sum(yVal ~= Yval)/numel(Yval);
accuracyVal = 1 - percentErrorsVal;

if ~ isempty(Ytest)
    % Test the KNN
    [yTest,score_knnTs,costTest] = predict(MdlKNN,Xtest);
    percentErrorsTest = sum(yTest ~= Ytest)/numel(Ytest);
    accuracyTest = 1 - percentErrorsTest;
    
    % Average precision and recall
    [C_knn,order_knn] = confusionmat(Ytest,yTest); %,'order',grouporder);
    [avgPresicion_knn, avgRecall_knn, avgAccuracy_knn, avgSpecificity_knn, ...
        avgF1score_knn] = multiclassPrecision_Recall(C_knn);
    
    confusionchart(C_knn)
        
    %% Feature train/test figure
    figure;
    gscatter(Xtest(:,1),Xtest(:,4),Ytest, 'br','xo');
    title('Scatter Diagram of Train/test Data')
    
    %% Precision-recall plot
    % Test
    [XknnTs,YknnTs,TknnTs,AUCknnTs] = perfcurve(Ytest, score_knnTs(:,2), 2); %, ...
    %                                     'xCrit', 'reca', 'yCrit', 'prec','xvals','all');
    
    % Train
    if ~(isempty(score_knnTr)) 
        [XknnTr,YknnTr,TknnTr,AUCknnTr] = perfcurve(Ytrain,score_knnTr(:,2), 2, ...
                                        'xCrit', 'reca', 'yCrit', 'prec','xvals','all');
    else
        XknnTr = XknnTs;
        YknnTr = zeros(size(YknnTs));
        TknnTr = [];
        AUCknnTr = 0;
    end
    
    figure;
    plot(XknnTr,YknnTr, '--r', 'LineWidth',3)
    hold on
    plot(XknnTs,YknnTs, '-b', 'LineWidth',3)
    hold off
    grid on
    % xlabel('Recall'); ylabel('Precision')
    xlabel('False positive rate')
    ylabel('True positive rate')
    legend ('Precision-recall Train Dataset', 'Precision-recall Test Dataset')
    title(['K-NN Precision-recall curve (AUC Train: ' ...
            num2str(AUCknnTr) ' | ' 'AUC Test: ' num2str(AUCknnTs) ')'])
        
    % Precision-recall external
    % Ytest(Ytest==1)=0;
    % Ytest(Ytest==2)=1;
    
    % prec_rec(score_knnTs(:,2),Ytest);
end

%% End parameters
% Close figures, waitbars and all
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);


% Runtime
Runtime = toc;

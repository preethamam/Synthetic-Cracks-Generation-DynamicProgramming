%//%************************************************************************%
%//%*                              Ph.D                                    *%
%//%*                           Crack Package						       *%
%//%*                                                                      *%
%//%*             Name: Preetham Manjunatha              		           *%
%//%*             USC ID Number: 7356627445		                           *%
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

%% Inputs
ROC_TYPE    = 'true_false'; % pre_recall | true_false
TRAIN_TEST  = 'testing';    % training | testing

%% ROC/Precision-recall plots
% SVM
load ZZZ_MdlSVM_LongShort_5JahanFeatures_unique.mat
switch ROC_TYPE
    case 'pre_recall'
        % Train
        [XsvmTr,YsvmTr,TsvmTr,AUCsvmTr] = perfcurve(Ytrain,score_svmTr(:,2), 2, ...
                                            'xCrit', 'reca', 'yCrit', 'prec','xvals','all');

        % Test
        [XsvmTs,YsvmTs,TsvmTs,AUCsvmTs] = perfcurve(Ytest, score_svmTs(:,2), 2, ...
                                            'xCrit', 'reca', 'yCrit', 'prec','xvals','all');
    case 'true_false'
        % Train
        [XsvmTr,YsvmTr,TsvmTr,AUCsvmTr] = perfcurve(Ytrain,score_svmTr(:,2), 2);

        % Test
        [XsvmTs,YsvmTs,TsvmTs,AUCsvmTs] = perfcurve(Ytest, score_svmTs(:,2), 2);
end

% KNN
load ZZZ_MdlKNN_LongShort_5JahanFeatures_unique.mat

switch ROC_TYPE
    case 'pre_recall'
        % Train
        [XknnTr,YknnTr,TknnTr,AUCknnTr] = perfcurve(Ytrain,score_knnTr(:,2), 2, ...
                                            'xCrit', 'reca', 'yCrit', 'prec','xvals','all');

        % Test
        [XknnTs,YknnTs,TknnTs,AUCknnTs] = perfcurve(Ytest, score_knnTs(:,2), 2, ...
                                            'xCrit', 'reca', 'yCrit', 'prec','xvals','all');
    case 'true_false'
        % Train
        [XknnTr,YknnTr,TknnTr,AUCknnTr] = perfcurve(Ytrain,score_knnTr(:,2), 2);
        % Test
        [XknnTs,YknnTs,TknnTs,AUCknnTs] = perfcurve(Ytest, score_knnTs(:,2), 2);
end

% ANN
load ZZZ_MdlANN_LongShort_5JahanFeatures_unique.mat
score_annTr = y(:,tr.trainInd(:))';
score_annTs = y(:,tr.testInd(:))';

switch ROC_TYPE
    case 'pre_recall'
        % Train
        [XannTr,YannTr,TannTr,AUCannTr] = perfcurve(ActualTrainind, score_annTr(:,2), 2, ...
                                            'xCrit', 'reca', 'yCrit', 'prec','xvals','all');

        % Test
        [XannTs,YannTs,TannTs,AUCannTs] = perfcurve(ActualTestind, score_annTs(:,2), 2, ...
                                            'xCrit', 'reca', 'yCrit', 'prec','xvals','all');
    case 'true_false'
        % Train
        [XannTr,YannTr,TannTr,AUCannTr] = perfcurve(ActualTrainind, score_annTr(:,2), 2);
        
        % Test
        [XannTs,YannTs,TannTs,AUCannTs] = perfcurve(ActualTestind, score_annTs(:,2), 2);
end

figure;
switch ROC_TYPE
    case 'pre_recall'
        switch TRAIN_TEST
            case 'training'
                plot(XannTr,YannTr, '-r', 'LineWidth',3)
                hold on
                plot(XsvmTr,YsvmTr, '-.g', 'LineWidth',3)
                plot(XknnTr,YknnTr, '--b', 'LineWidth',3)
                % xlim([0 1]) xlabel('False positive rate'); ylabel('True positive rate');
                % ylim([0 1])
                hold off
                grid on
                xlabel('Recall'); ylabel('Precision')
                legend ('ANN','SVM', 'K-NN')
                title(['ANN vs. SVM vs. K-NN Training Precision-recall curve (AUC ANN: ' num2str(AUCannTr) ' | ' 'AUC SVM: ' ...
                    num2str(AUCsvmTr) ' | ' 'AUC K-NN: ' num2str(AUCknnTr) ')'])
            case 'testing'
                plot(XannTs,YannTs, '-r', 'LineWidth',3)
                hold on
                plot(XsvmTs,YsvmTs, '-.g', 'LineWidth',3)
                plot(XknnTs,YknnTs, '--b', 'LineWidth',3)
                hold off
                grid on
                xlabel('Recall'); ylabel('Precision')
                legend ('ANN','SVM', 'K-NN')
                title(['ANN vs. SVM vs. K-NN Testing Precision-recall curve (AUC ANN: ' num2str(AUCannTs) ' | ' 'AUC SVM: ' ...
                    num2str(AUCsvmTs) ' | ' 'AUC K-NN: ' num2str(AUCknnTs) ')'])
        end
    
    case 'true_false'
        switch TRAIN_TEST
            case 'training'
                plot(XannTr,YannTr, '-r', 'LineWidth',3)
                hold on
                plot(XsvmTr,YsvmTr, '-.g', 'LineWidth',3)
                plot(XknnTr,YknnTr, '--b', 'LineWidth',3)
                hold off
                grid on
                xlabel('False positive rate'); ylabel('True positive rate');
                legend ('ANN','SVM', 'K-NN')
                title(['ROC Curves for ANN, SVM and K-NN Training (AUC ANN: ' num2str(AUCannTr) ' | ' 'AUC SVM: ' ...
                    num2str(AUCsvmTr) ' | ' 'AUC K-NN: ' num2str(AUCknnTr) ')'])
            case 'testing'
                plot(XannTs,YannTs, '-r', 'LineWidth',3)
                hold on
                plot(XsvmTs,YsvmTs, '-.g', 'LineWidth',3)
                plot(XknnTs,YknnTs, '--b', 'LineWidth',3)
                hold off
                grid on
                xlabel('False positive rate'); ylabel('True positive rate');
                legend ('ANN','SVM', 'K-NN')
                title(['ROC Curves for SVM and K-NN Testing (AUC ANN: ' num2str(AUCannTs) ' | ' 'AUC SVM: ' ...
                    num2str(AUCsvmTs) ' | ' 'AUC K-NN: ' num2str(AUCknnTs) ')'])
        end
end

%% End parameters
% Close figures, waitbars and all
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);

% Runtime
Runtime = toc;

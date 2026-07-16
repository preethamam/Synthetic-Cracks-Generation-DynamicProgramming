function [rocArray_ImageClassification, rocArray_ALLCC, rocArrayBBox_MLAB, rocArray_SSM] = store_ROC_Values(input,Ytest,score_svmTs,score_knnTs, score_annTs,...
                                                      objBoxCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs, ...
                                                      BBoxANN,BBoxKNN,BBoxSVM, ...
                                                      classnumber,PredictScoresImgANN,PredictScoresImgKNN, PredictScoresImgSVM,...
                                                      PixGT, PredictScoresSSMANN, PredictScoresSSMKNN, PredictScoresSSMSVM)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%% ROC/Precision-recall plots image classification
% SVM
rocArray_ImageClassification =[];

if ~(strcmp(input.ImagesType,'crack_only')) 
    switch input.ROC_TYPE
        case 'pre_recall'
            % Test
            [XsvmTs,YsvmTs,TsvmTs,AUCsvmTs] = perfcurve(classnumber', PredictScoresImgSVM, 2, ...
                                                'xCrit', 'reca', 'yCrit', 'prec','xvals','all');
        case 'true_false'
            % Test
            [XsvmTs,YsvmTs,TsvmTs,AUCsvmTs] = perfcurve(classnumber', PredictScoresImgSVM, 2);
    end

    % KNN
    switch input.ROC_TYPE
        case 'pre_recall'
            % Test
            [XknnTs,YknnTs,TknnTs,AUCknnTs] = perfcurve(classnumber', PredictScoresImgKNN, 2, ...
                                                'xCrit', 'reca', 'yCrit', 'prec','xvals','all');
        case 'true_false'
            % Test
            [XknnTs,YknnTs,TknnTs,AUCknnTs] = perfcurve(classnumber', PredictScoresImgKNN, 2);
    end

    % ANN
    switch input.ROC_TYPE
        case 'pre_recall'
            % Test
            [XannTs,YannTs,TannTs,AUCannTs] = perfcurve(classnumber', PredictScoresImgANN, 2, ...
                                                'xCrit', 'reca', 'yCrit', 'prec','xvals','all');
        case 'true_false'
            % Test
            [XannTs,YannTs,TannTs,AUCannTs] = perfcurve(classnumber', PredictScoresImgANN, 2);
    end

    % Store X, Y, threshold and area of ROC curves
    rocArray_ImageClassification{1} = XannTs;
    rocArray_ImageClassification{2} = XknnTs;
    rocArray_ImageClassification{3} = XsvmTs;

    rocArray_ImageClassification{4} = YannTs;
    rocArray_ImageClassification{5} = YknnTs;
    rocArray_ImageClassification{6} = YsvmTs;

    rocArray_ImageClassification{7} = TannTs;
    rocArray_ImageClassification{8} = TknnTs;
    rocArray_ImageClassification{9} = TsvmTs;

    rocArray_ImageClassification{10} = AUCannTs;
    rocArray_ImageClassification{11} = AUCknnTs;
    rocArray_ImageClassification{12} = AUCsvmTs;
end

%% ROC/Precision-recall plots All connected components
rocArray_ALLCC{1} = [];
rocArray_ALLCC{2} = [];
rocArray_ALLCC{3} = [];

rocArray_ALLCC{4} = [];
rocArray_ALLCC{5} = [];
rocArray_ALLCC{6} = [];

rocArray_ALLCC{7} = [];
rocArray_ALLCC{8} = [];
rocArray_ALLCC{9} = [];

rocArray_ALLCC{10} = [];
rocArray_ALLCC{11} = [];
rocArray_ALLCC{12} = [];
    
% SVM
if (numel(unique(Ytest)) == 2)
    switch input.ROC_TYPE
        case 'pre_recall'
            % Test
            [XsvmTs,YsvmTs,TsvmTs,AUCsvmTs] = perfcurve(Ytest, score_svmTs(:,2), 2, ...
                                                'xCrit', 'reca', 'yCrit', 'prec','xvals','all');
        case 'true_false'
            % Test
            [XsvmTs,YsvmTs,TsvmTs,AUCsvmTs] = perfcurve(Ytest, score_svmTs(:,2), 2);
    end

    % KNN
    switch input.ROC_TYPE
        case 'pre_recall'
            % Test
            [XknnTs,YknnTs,TknnTs,AUCknnTs] = perfcurve(Ytest, score_knnTs(:,2), 2, ...
                                                'xCrit', 'reca', 'yCrit', 'prec','xvals','all');
        case 'true_false'
            % Test
            [XknnTs,YknnTs,TknnTs,AUCknnTs] = perfcurve(Ytest, score_knnTs(:,2), 2);
    end

    % ANN
    switch input.ROC_TYPE
        case 'pre_recall'
            % Test
            [XannTs,YannTs,TannTs,AUCannTs] = perfcurve(Ytest, score_annTs(:,2), 2, ...
                                                'xCrit', 'reca', 'yCrit', 'prec','xvals','all');
        case 'true_false'
            % Test
            [XannTs,YannTs,TannTs,AUCannTs] = perfcurve(Ytest, score_annTs(:,2), 2);
    end

    % Store X, Y, threshold and area of ROC curves
    rocArray_ALLCC{1} = XannTs;
    rocArray_ALLCC{2} = XknnTs;
    rocArray_ALLCC{3} = XsvmTs;

    rocArray_ALLCC{4} = YannTs;
    rocArray_ALLCC{5} = YknnTs;
    rocArray_ALLCC{6} = YsvmTs;

    rocArray_ALLCC{7} = TannTs;
    rocArray_ALLCC{8} = TknnTs;
    rocArray_ALLCC{9} = TsvmTs;
    
    rocArray_ALLCC{10} = AUCannTs;
    rocArray_ALLCC{11} = AUCknnTs;
    rocArray_ALLCC{12} = AUCsvmTs;
else
    warning('Only 1 class detected!')
end




%% ROC/Precision-recall plots MATLAB's Bounding Boxes
% Evalaute the BBoxes
% ANN
[apBBoxANN_MLAB, recallBBoxANN_MLAB, precisionBBoxANN_MLAB] = evaluateDetectionPrecision(BBoxANN, objBoxCracksnNoncracksGTs);

% KNN
[apBBoxKNN_MLAB, recallBBoxKNN_MLAB, precisionBBoxKNN_MLAB] = evaluateDetectionPrecision(BBoxKNN, objBoxCracksnNoncracksGTs);

% SVM
[apBBoxSVM_MLAB, recallBBoxSVM_MLAB, precisionBBoxSVM_MLAB] = evaluateDetectionPrecision(BBoxSVM, objBoxCracksnNoncracksGTs);

% Store X, Y, threshold and area of ROC curves
rocArrayBBox_MLAB{1} = recallBBoxANN_MLAB;
rocArrayBBox_MLAB{2} = recallBBoxKNN_MLAB;
rocArrayBBox_MLAB{3} = recallBBoxSVM_MLAB;

rocArrayBBox_MLAB{4} = precisionBBoxANN_MLAB;
rocArrayBBox_MLAB{5} = precisionBBoxKNN_MLAB;
rocArrayBBox_MLAB{6} = precisionBBoxSVM_MLAB;

rocArrayBBox_MLAB{7} = apBBoxANN_MLAB;
rocArrayBBox_MLAB{8} = apBBoxKNN_MLAB;
rocArrayBBox_MLAB{9} = apBBoxSVM_MLAB;


%% ROC/Precision-recall plots MATLAB's semantic segmentation
% Evalaute the semantic segmentation
% ANN
switch input.ROC_TYPE
    case 'pre_recall'
        % Test
        [XannTs,YannTs,TannTs,AUCannTs] = perfcurve(PixGT, PredictScoresSSMANN, 1, ...
                                            'xCrit', 'reca', 'yCrit', 'prec','xvals','all');
    case 'true_false'
        % Test
        [XannTs,YannTs,TannTs,AUCannTs] = perfcurve(PixGT, PredictScoresSSMANN, 1);
end

% KNN
switch input.ROC_TYPE
    case 'pre_recall'
        % Test
        [XknnTs,YknnTs,TknnTs,AUCknnTs] = perfcurve(PixGT, PredictScoresSSMKNN, 1, ...
                                            'xCrit', 'reca', 'yCrit', 'prec','xvals','all');
    case 'true_false'
        % Test
        [XknnTs,YknnTs,TknnTs,AUCknnTs] = perfcurve(PixGT, PredictScoresSSMKNN, 1);
end

% SVM
switch input.ROC_TYPE
    case 'pre_recall'
        % Test
        [XsvmTs,YsvmTs,TsvmTs,AUCsvmTs] = perfcurve(PixGT, PredictScoresSSMSVM, 1, ...
                                            'xCrit', 'reca', 'yCrit', 'prec','xvals','all');
    case 'true_false'
        % Test
        [XsvmTs,YsvmTs,TsvmTs,AUCsvmTs] = perfcurve(PixGT, PredictScoresSSMSVM, 1);
end

% Store X, Y, threshold and area of ROC curves
rocArray_SSM{1} = XannTs;
rocArray_SSM{2} = XknnTs;
rocArray_SSM{3} = XsvmTs;

rocArray_SSM{4} = YannTs;
rocArray_SSM{5} = YknnTs;
rocArray_SSM{6} = YsvmTs;

rocArray_SSM{7} = TannTs;
rocArray_SSM{8} = TknnTs;
rocArray_SSM{9} = TsvmTs;

rocArray_SSM{10} = AUCannTs;
rocArray_SSM{11} = AUCknnTs;
rocArray_SSM{12} = AUCsvmTs;

end


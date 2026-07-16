function [rocArrayij_ImageClassification, rocArrayij_AllComponents, rocArrayBBox_MLAB, rocArray_SSM, ...
    Classification_Results] = ...
    Processed_Results(workerID, fileID, hybrid_inpstruct,jahan_inpstruct, hybrid_allPerms, images2classifier,imagesGroundTruth2classifier, ...
                                classnumber, MdlKNN, ScoreCSVMModel, net, imgCount, objBoxCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs, ...
                                ANN_classifier_hessian, KNN_classifier_hessian, SVM_classifier_hessian,...
                                ANN_classifier_mfat, KNN_classifier_mfat, SVM_classifier_mfat,...
                                ANN_classifier_morpho, KNN_classifier_morpho, SVM_classifier_morpho)
                            
    % Extract feature matrix and labels
    switch hybrid_inpstruct.parallel_sequential_processing
        case 'sequential'
            [TPFPFNTNpixANN, TPFPFNTNpixKNN, TPFPFNTNpixSVM, TPFPFNBboxANN, ...
            TPFPFNBboxKNN, TPFPFNBboxSVM,...
            PredictLabelsANN,PredictLabelsKNN,PredictLabelsSVM,SCORES,true_index,BBoxANN,BBoxKNN,BBoxSVM, ...
            ssmPixCracksnNoncracks_ANN, ssmPixCracksnNoncracks_KNN, ssmPixCracksnNoncracks_SVM, ...
            PredictScoresImgANN,PredictScoresImgKNN, PredictScoresImgSVM, ...
            PixGT, PredictScoresSSMANN, PredictScoresSSMKNN, PredictScoresSSMSVM]  = classifierResult_2017Revised...
                (workerID, hybrid_inpstruct, hybrid_allPerms, jahan_inpstruct,images2classifier,[], imagesGroundTruth2classifier, ...
                 classnumber, MdlKNN, ScoreCSVMModel, net, imgCount);
        case 'parallel'
            [TPFPFNTNpixANN, TPFPFNTNpixKNN, TPFPFNTNpixSVM, TPFPFNBboxANN, ...
            TPFPFNBboxKNN, TPFPFNBboxSVM,...
            PredictLabelsANN,PredictLabelsKNN,PredictLabelsSVM,SCORES,true_index,BBoxANN,BBoxKNN,BBoxSVM, ...
            ssmPixCracksnNoncracks_ANN, ssmPixCracksnNoncracks_KNN, ssmPixCracksnNoncracks_SVM, ...
            PredictScoresImgANN,PredictScoresImgKNN, PredictScoresImgSVM, ...
            PixGT, PredictScoresSSMANN, PredictScoresSSMKNN, PredictScoresSSMSVM] = classifierResult_2020_ParFor...
                (workerID, hybrid_inpstruct, hybrid_allPerms, jahan_inpstruct,images2classifier,[], imagesGroundTruth2classifier, ...
                 classnumber, MdlKNN, ScoreCSVMModel, net, imgCount);
        otherwise
            error('Need one method (sequential or parallel)!')
    end

    %% Scores of ANN, KNN and SVM
    score_annTs = cat(2,SCORES.ann)';
    score_knnTs = cat(1,SCORES.knn);
    score_svmTs = cat(1,SCORES.svm);
    Ytest = cell2mat(cat(1, true_index{:}));

    %% Store ROC curves data
    [rocArrayij_ImageClassification, rocArrayij_AllComponents, rocArrayBBox_MLAB, rocArray_SSM] = store_ROC_Values(hybrid_inpstruct,Ytest,score_svmTs,score_knnTs, score_annTs, ...
    objBoxCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs, BBoxANN, BBoxKNN, BBoxSVM, ...
                              classnumber,PredictScoresImgANN,PredictScoresImgKNN, PredictScoresImgSVM, ...
                              PixGT, PredictScoresSSMANN, PredictScoresSSMKNN, PredictScoresSSMSVM);

    %% Classification results
    ALLresults = calculate_Results2Write (hybrid_inpstruct, TPFPFNTNpixANN, TPFPFNTNpixKNN, TPFPFNTNpixSVM, ...
                                                 TPFPFNBboxANN, TPFPFNBboxKNN, TPFPFNBboxSVM, BBoxANN, BBoxKNN, BBoxSVM, ...
                                                 objBoxCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs, ssmPixCracksnNoncracks_ANN, ...
                                                 ssmPixCracksnNoncracks_KNN, ssmPixCracksnNoncracks_SVM, ...
                                                 classnumber,PredictLabelsANN, PredictLabelsKNN, PredictLabelsSVM);


    %% Write output to a textfile
    wrtiteOutputs2TextFile (fileID,hybrid_inpstruct,jahan_inpstruct, hybrid_allPerms, ANN_classifier_hessian, KNN_classifier_hessian, SVM_classifier_hessian,...
                                  ANN_classifier_mfat, KNN_classifier_mfat, SVM_classifier_mfat,...
                                  ANN_classifier_morpho, KNN_classifier_morpho, SVM_classifier_morpho, ALLresults);

    %% Store in a structure
    % Algorithm type, aniso iterations and post-processing
    % details
    Classification_Results.Alg_TYPE  = hybrid_inpstruct.Algorithm_TYPE;
    
    switch hybrid_inpstruct.Algorithm_TYPE
        case 'hybrid_hessian'
            Classification_Results.Alg_iter  = hybrid_allPerms(1,1:2);
            Classification_Results.Delta_t   = hybrid_allPerms(1,3:4);
            Classification_Results.Kappa     = hybrid_allPerms(1,5:6);
            Classification_Results.Aniso_option      = hybrid_inpstruct.aniso.option;
            
            Classification_Results.FrangiScaleRange  = hybrid_allPerms(1,7:8);
            Classification_Results.FrangiScaleRatio  = hybrid_inpstruct.frangiopt.FrangiScaleRatio;
            Classification_Results.FrangiBetaOne     = hybrid_allPerms(1,9);
            Classification_Results.FrangiBetaTwo     = hybrid_allPerms(1,10);
            
            Classification_Results.MFATsigmas1       = [];
            Classification_Results.MFATsigmas2       = [];
            Classification_Results.MFATsigmasScaleRatio = [];
            Classification_Results.MFATspacing       = []; 
            Classification_Results.MFATtau           = []; 
            Classification_Results.MFATtau2          = []; 
            Classification_Results.MFAT_D            = [];
            
        case 'hybrid_MFAT'
            Classification_Results.Alg_iter  = hybrid_allPerms(1,1:2);
            Classification_Results.Delta_t   = hybrid_allPerms(1,3:4);
            Classification_Results.Kappa     = hybrid_allPerms(1,5:6);
            Classification_Results.Aniso_option      = hybrid_inpstruct.aniso.option;
            
            Classification_Results.FrangiScaleRange  = [];
            Classification_Results.FrangiScaleRatio  = [];
            Classification_Results.FrangiBetaOne     = [];
            Classification_Results.FrangiBetaTwo     = [];
            
            Classification_Results.MFATsigmas1       = hybrid_allPerms(1,7);
            Classification_Results.MFATsigmas2       = hybrid_allPerms(1,8);
            Classification_Results.MFATsigmasScaleRatio = hybrid_allPerms(1,9);
            Classification_Results.MFATspacing       = hybrid_allPerms(1,10); 
            Classification_Results.MFATtau           = hybrid_allPerms(1,11); 
            Classification_Results.MFATtau2          = hybrid_allPerms(1,12); 
            Classification_Results.MFAT_D            = hybrid_allPerms(1,13);
            
        case {'morpho'}
            Classification_Results.Alg_iter  = [];
            Classification_Results.Delta_t   = [];
            Classification_Results.Kappa     = [];
            Classification_Results.Aniso_option      = [];
            
            Classification_Results.FrangiScaleRange  = [];
            Classification_Results.FrangiScaleRatio  = [];
            Classification_Results.FrangiBetaOne     = [];
            Classification_Results.FrangiBetaTwo     = [];
            
            Classification_Results.MFATsigmas1       = [];
            Classification_Results.MFATsigmas2       = [];
            Classification_Results.MFATsigmasScaleRatio = [];
            Classification_Results.MFATspacing       = []; 
            Classification_Results.MFATtau           = []; 
            Classification_Results.MFATtau2          = []; 
            Classification_Results.MFAT_D            = [];
    end
    
    Classification_Results.Alg_circ  = hybrid_inpstruct.circularity_threshold;
    Classification_Results.Alg_blob  = hybrid_inpstruct.blobfilter_sigma;

    % Image wise
    if ~(strcmp(hybrid_inpstruct.ImagesType,'crack_only'))
        Classification_Results.PrANNImg = ALLresults.PrecisionANNImg;
        Classification_Results.PrKNNImg = ALLresults.PrecisionKNNImg;
        Classification_Results.PrSVMImg = ALLresults.PrecisionSVMImg;

        Classification_Results.ReANNImg = ALLresults.RecallANNImg;
        Classification_Results.ReKNNImg = ALLresults.RecallKNNImg;
        Classification_Results.ReSVMImg = ALLresults.RecallSVMImg;

        Classification_Results.F1ANNImg = ALLresults.F1scoreANNImg;
        Classification_Results.F1KNNImg = ALLresults.F1scoreKNNImg;
        Classification_Results.F1SVMImg = ALLresults.F1scoreSVMImg;

        Classification_Results.AccANNImg = ALLresults.AccuracyANNImg;
        Classification_Results.AccKNNImg = ALLresults.AccuracyKNNImg;
        Classification_Results.AccSVMImg = ALLresults.AccuracySVMImg;

        Classification_Results.SpecANNImg = ALLresults.SpecificityANNImg;
        Classification_Results.SpecKNNImg = ALLresults.SpecificityKNNImg;
        Classification_Results.SpecSVMImg = ALLresults.SpecificitySVMImg;
    end

    % Bounding box
    Classification_Results.PrANNBbox = ALLresults.PrecisionANNBbox;
    Classification_Results.PrKNNBbox = ALLresults.PrecisionKNNBbox;
    Classification_Results.PrSVMBbox = ALLresults.PrecisionSVMBbox;

    Classification_Results.ReNNBbox = ALLresults.RecallANNBbox;
    Classification_Results.ReKNNBbox = ALLresults.RecallKNNBbox;
    Classification_Results.ReSVMBbox = ALLresults.RecallSVMBbox;

    Classification_Results.F1ANNBbox = ALLresults.F1scoreANNBbox;
    Classification_Results.F1KNNBbox = ALLresults.F1scoreKNNBbox;
    Classification_Results.F1SVMBbox = ALLresults.F1scoreSVMBbox;

    % Pixel wise
    Classification_Results.PrANNPix = ALLresults.PrecisionANNPix;
    Classification_Results.PrKNNPix = ALLresults.PrecisionKNNPix;
    Classification_Results.PrSVMPix = ALLresults.PrecisionSVMPix;

    Classification_Results.ReANNPix = ALLresults.RecallANNPix;
    Classification_Results.ReKNNPix = ALLresults.RecallKNNPix;
    Classification_Results.ReSVMPix = ALLresults.RecallSVMPix;

    Classification_Results.F1ANNPix = ALLresults.F1scoreANNPix;
    Classification_Results.F1KNNPix = ALLresults.F1scoreKNNPix;
    Classification_Results.F1SVMPix = ALLresults.F1scoreSVMPix;


    % Bounding box MATLAB
    Classification_Results.PrANNBbox_MLAB = ALLresults.PrecisionANNBbox_MLAB;
    Classification_Results.PrKNNBbox_MLAB = ALLresults.PrecisionKNNBbox_MLAB;
    Classification_Results.PrSVMBbox_MLAB = ALLresults.PrecisionSVMBbox_MLAB;

    Classification_Results.ReNNBbox_MLAB = ALLresults.RecallANNBbox_MLAB;
    Classification_Results.ReKNNBbox_MLAB = ALLresults.RecallKNNBbox_MLAB;
    Classification_Results.ReSVMBbox_MLAB = ALLresults.RecallSVMBbox_MLAB;

    Classification_Results.F1ANNBbox_MLAB = ALLresults.F1scoreANNBbox_MLAB;
    Classification_Results.F1KNNBbox_MLAB = ALLresults.F1scoreKNNBbox_MLAB;
    Classification_Results.F1SVMBbox_MLAB = ALLresults.F1scoreSVMBbox_MLAB;

    % Pixel wise MATLAB
    Classification_Results.PrANNPix_MLAB = ALLresults.PrecisionANNPix_MLAB;
    Classification_Results.PrKNNPix_MLAB = ALLresults.PrecisionKNNPix_MLAB;
    Classification_Results.PrSVMPix_MLAB = ALLresults.PrecisionSVMPix_MLAB;

    Classification_Results.ReANNPix_MLAB = ALLresults.RecallANNPix_MLAB;
    Classification_Results.ReKNNPix_MLAB = ALLresults.RecallKNNPix_MLAB;
    Classification_Results.ReSVMPix_MLAB = ALLresults.RecallSVMPix_MLAB;

    Classification_Results.F1ANNPix_MLAB = ALLresults.F1scoreANNPix_MLAB;
    Classification_Results.F1KNNPix_MLAB = ALLresults.F1scoreKNNPix_MLAB;
    Classification_Results.F1SVMPix_MLAB = ALLresults.F1scoreSVMPix_MLAB;

    Classification_Results.AccANNPix_MLAB = ALLresults.AccuracyANNPix_MLAB;
    Classification_Results.AccKNNPix_MLAB = ALLresults.AccuracyKNNPix_MLAB;
    Classification_Results.AccSVMPix_MLAB = ALLresults.AccuracySVMPix_MLAB;

    Classification_Results.SpecANNPix_MLAB = ALLresults.SpecificityANNPix_MLAB;
    Classification_Results.SpecKNNPix_MLAB = ALLresults.SpecificityKNNPix_MLAB;
    Classification_Results.SpecSVMPix_MLAB = ALLresults.SpecificitySVMPix_MLAB;

    Classification_Results.GlobalAccANNPix_MLAB = ALLresults.ssmMetrics_ANN.DataSetMetrics.GlobalAccuracy;
    Classification_Results.GlobalAccKNNPix_MLAB = ALLresults.ssmMetrics_KNN.DataSetMetrics.GlobalAccuracy;
    Classification_Results.GlobalAccSVMPix_MLAB = ALLresults.ssmMetrics_SVM.DataSetMetrics.GlobalAccuracy;

    Classification_Results.MeanAccuracyANNPix_MLAB = ALLresults.ssmMetrics_ANN.DataSetMetrics.MeanAccuracy;
    Classification_Results.MeanAccuracyKNNPix_MLAB = ALLresults.ssmMetrics_KNN.DataSetMetrics.MeanAccuracy;
    Classification_Results.MeanAccuracySVMPix_MLAB = ALLresults.ssmMetrics_SVM.DataSetMetrics.MeanAccuracy;

    Classification_Results.MeanIoUANNPix_MLAB = ALLresults.ssmMetrics_ANN.DataSetMetrics.MeanIoU;
    Classification_Results.MeanIoUKNNPix_MLAB = ALLresults.ssmMetrics_KNN.DataSetMetrics.MeanIoU;
    Classification_Results.MeanIoUSVMPix_MLAB = ALLresults.ssmMetrics_SVM.DataSetMetrics.MeanIoU;

    Classification_Results.WeightedIoUANNPix_MLAB = ALLresults.ssmMetrics_ANN.DataSetMetrics.WeightedIoU;
    Classification_Results.WeightedIoUKNNPix_MLAB = ALLresults.ssmMetrics_KNN.DataSetMetrics.WeightedIoU;
    Classification_Results.WeightedIoUSVMPix_MLAB = ALLresults.ssmMetrics_SVM.DataSetMetrics.WeightedIoU;

    Classification_Results.MeanBFScoreANNPix_MLAB = ALLresults.ssmMetrics_ANN.DataSetMetrics.MeanBFScore;
    Classification_Results.MeanBFScoreKNNPix_MLAB = ALLresults.ssmMetrics_KNN.DataSetMetrics.MeanBFScore;
    Classification_Results.MeanBFScoreSVMPix_MLAB = ALLresults.ssmMetrics_SVM.DataSetMetrics.MeanBFScore;
    
    
end





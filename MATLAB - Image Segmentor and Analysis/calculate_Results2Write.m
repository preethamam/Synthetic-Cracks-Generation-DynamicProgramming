function [ALLresults] = calculate_Results2Write (hybrid_inpstruct, TPFPFNTNpixANN, TPFPFNTNpixKNN, TPFPFNTNpixSVM, ...
                                                 TPFPFNBboxANN, TPFPFNBboxKNN, TPFPFNBboxSVM, BBoxANN, BBoxKNN, BBoxSVM, ...
                                                 objBoxCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs, ssmPixCracksnNoncracks_ANN, ...
                                                 ssmPixCracksnNoncracks_KNN, ssmPixCracksnNoncracks_SVM, ...
                                                 classnumber,PredictLabelsANN, PredictLabelsKNN, PredictLabelsSVM)

    %% Preethm's functions results
    % Post-processing steps (Precision and recall by Pixels)
    %--------------------------------------------------------------------------
    % Precision and recall values for ANN
    TPFPFNTNpixANNTotal = sum(TPFPFNTNpixANN);
    ALLresults.ConfmatANNPix = [TPFPFNTNpixANNTotal(1), TPFPFNTNpixANNTotal(3); 
                     TPFPFNTNpixANNTotal(2), TPFPFNTNpixANNTotal(4)];
    [ALLresults.PrecisionANNPix, ALLresults.RecallANNPix, ALLresults.AccuracyANNPix, ALLresults.SpecificityANNPix, ALLresults.F1scoreANNPix] ...
            = multiclassPrecision_Recall(ALLresults.ConfmatANNPix);

    % Precision and recall values for KNN
    TPFPFNTNpixKNNTotal = sum(TPFPFNTNpixKNN);
    ALLresults.ConfmatKNNPix = [TPFPFNTNpixKNNTotal(1), TPFPFNTNpixKNNTotal(3); 
                     TPFPFNTNpixKNNTotal(2), TPFPFNTNpixKNNTotal(4)];
    [ALLresults.PrecisionKNNPix, ALLresults.RecallKNNPix, ALLresults.AccuracyKNNPix, ALLresults.SpecificityKNNPix, ALLresults.F1scoreKNNPix] ...
            = multiclassPrecision_Recall(ALLresults.ConfmatKNNPix);

    % Precision and recall values for SVM
    TPFPFNTNpixSVMTotal = sum(TPFPFNTNpixSVM);
    ALLresults.ConfmatSVMPix = [TPFPFNTNpixSVMTotal(1), TPFPFNTNpixSVMTotal(3); 
                     TPFPFNTNpixSVMTotal(2), TPFPFNTNpixSVMTotal(4)];
    [ALLresults.PrecisionSVMPix, ALLresults.RecallSVMPix, ALLresults.AccuracySVMPix, ALLresults.SpecificitySVMPix, ALLresults.F1scoreSVMPix] ...
            = multiclassPrecision_Recall(ALLresults.ConfmatSVMPix);

    % Post-processing steps (Precision and recall by Bounding Box)
    %--------------------------------------------------------------------------
    % Precision and recall values for ANN
    TPFPFNBboxANNTotal = sum(TPFPFNBboxANN);
    ALLresults.PrecisionANNBbox   = TPFPFNBboxANNTotal(1) / (TPFPFNBboxANNTotal(1) + TPFPFNBboxANNTotal(2));
    ALLresults.RecallANNBbox      = TPFPFNBboxANNTotal(1) / (TPFPFNBboxANNTotal(1) + TPFPFNBboxANNTotal(3));
    ALLresults.F1scoreANNBbox     = 2*((ALLresults.PrecisionANNBbox * ALLresults.RecallANNBbox)/(ALLresults.PrecisionANNBbox + ALLresults.RecallANNBbox));

    % Precision and recall values for KNN
    TPFPFNBboxKNNTotal = sum(TPFPFNBboxKNN);
    ALLresults.PrecisionKNNBbox   = TPFPFNBboxKNNTotal(1) / (TPFPFNBboxKNNTotal(1) + TPFPFNBboxKNNTotal(2));
    ALLresults.RecallKNNBbox      = TPFPFNBboxKNNTotal(1) / (TPFPFNBboxKNNTotal(1) + TPFPFNBboxKNNTotal(3));
    ALLresults.F1scoreKNNBbox     = 2*((ALLresults.PrecisionKNNBbox * ALLresults.RecallKNNBbox)/(ALLresults.PrecisionKNNBbox + ALLresults.RecallKNNBbox));

    % Precision and recall values for SVM
    TPFPFNBboxSVMTotal = sum(TPFPFNBboxSVM);
    ALLresults.PrecisionSVMBbox   = TPFPFNBboxSVMTotal(1) / (TPFPFNBboxSVMTotal(1) + TPFPFNBboxSVMTotal(2));
    ALLresults.RecallSVMBbox      = TPFPFNBboxSVMTotal(1) / (TPFPFNBboxSVMTotal(1) + TPFPFNBboxSVMTotal(3));
    ALLresults.F1scoreSVMBbox     = 2*((ALLresults.PrecisionSVMBbox * ALLresults.RecallSVMBbox)/(ALLresults.PrecisionSVMBbox + ALLresults.RecallSVMBbox));

    % Post-processing steps (Image classification accuracies)
    %--------------------------------------------------------------------------
    if ~(strcmp(hybrid_inpstruct.ImagesType,'crack_only'))
        % Average precision and recall
        [ALLresults.ConfmatANN, ALLresults.orderANN] = confusionmat(classnumber,PredictLabelsANN); %,'order',grouporder);
        [ALLresults.PrecisionANNImg, ALLresults.RecallANNImg, ALLresults.AccuracyANNImg, ALLresults.SpecificityANNImg, ALLresults.F1scoreANNImg] ...
                = multiclassPrecision_Recall(ALLresults.ConfmatANN);

        [ALLresults.ConfmatKNN,  ALLresults.orderKNN] = confusionmat(classnumber,PredictLabelsKNN); %,'order',grouporder);
        [ALLresults.PrecisionKNNImg, ALLresults.RecallKNNImg, ALLresults.AccuracyKNNImg, ALLresults.SpecificityKNNImg, ALLresults.F1scoreKNNImg] ...
                = multiclassPrecision_Recall(ALLresults.ConfmatKNN);

        [ALLresults.ConfmatSVM, ALLresults.orderSVM] = confusionmat(classnumber,PredictLabelsSVM); %,'order',grouporder);
        [ALLresults.PrecisionSVMImg, ALLresults.RecallSVMImg, ALLresults.AccuracySVMImg, ALLresults.SpecificitySVMImg, ALLresults.F1scoreSVMImg] ...
                = multiclassPrecision_Recall(ALLresults.ConfmatSVM);
    end

    %---------------------------------------------------------------------------------------------------------------------------------------
    %% MATLAB functions results
    % Post-processing steps (Precision and recall by Bounding Box)
    %--------------------------------------------------------------------------
    % Precision and recall values for ANN
    [precision_MLAB_ANN,recall_MLAB_ANN] = bboxPrecisionRecall(BBoxANN(:,1), ...
                                            table(objBoxCracksnNoncracksGTs.LabelData(:,1)), hybrid_inpstruct.BBoxthreshold);
    ALLresults.PrecisionANNBbox_MLAB   = mean(precision_MLAB_ANN);
    ALLresults.RecallANNBbox_MLAB      = mean(recall_MLAB_ANN);
    ALLresults.F1scoreANNBbox_MLAB     = 2*((ALLresults.PrecisionANNBbox_MLAB * ALLresults.RecallANNBbox_MLAB)/...
                                (ALLresults.PrecisionANNBbox_MLAB + ALLresults.RecallANNBbox_MLAB));

    % Precision and recall values for KNN
    [precision_MLAB_KNN,recall_MLAB_KNN] = bboxPrecisionRecall(BBoxKNN(:,1), ...
                                            table(objBoxCracksnNoncracksGTs.LabelData(:,1)), hybrid_inpstruct.BBoxthreshold);
    ALLresults.PrecisionKNNBbox_MLAB   = mean(precision_MLAB_KNN);
    ALLresults.RecallKNNBbox_MLAB      = mean(recall_MLAB_KNN);
    ALLresults.F1scoreKNNBbox_MLAB     = 2*((ALLresults.PrecisionKNNBbox_MLAB * ALLresults.RecallKNNBbox_MLAB)/...
                                (ALLresults.PrecisionKNNBbox_MLAB + ALLresults.RecallKNNBbox_MLAB));

    % Precision and recall values for SVM
    [precision_MLAB_SVM,recall_MLAB_SVM] = bboxPrecisionRecall(BBoxSVM(:,1), ...
                                            table(objBoxCracksnNoncracksGTs.LabelData(:,1)), hybrid_inpstruct.BBoxthreshold);
    ALLresults.PrecisionSVMBbox_MLAB   = mean(precision_MLAB_SVM);
    ALLresults.RecallSVMBbox_MLAB      = mean(recall_MLAB_SVM);
    ALLresults.F1scoreSVMBbox_MLAB     = 2*((ALLresults.PrecisionSVMBbox_MLAB * ALLresults.RecallSVMBbox_MLAB)/...
                                (ALLresults.PrecisionSVMBbox_MLAB + ALLresults.RecallSVMBbox_MLAB));

    % Post-processing steps (Precision and recall by semantic segmentation Box)
    %--------------------------------------------------------------------------
    % Precision and recall values for ANN 
    ALLresults.ssmMetrics_ANN = evaluateSemanticSegmentation(ssmPixCracksnNoncracks_ANN, ssmPixCracksnNoncracksGTs, 'Verbose', hybrid_inpstruct.ssmVerbose);
    [ALLresults.PrecisionANNPix_MLAB, ALLresults.RecallANNPix_MLAB, ALLresults.AccuracyANNPix_MLAB, ALLresults.SpecificityANNPix_MLAB, ...
     ALLresults.F1scoreANNPix_MLAB] = multiclassPrecision_Recall(table2array(ALLresults.ssmMetrics_ANN.ConfusionMatrix));

    % Precision and recall values for KNN
    ALLresults.ssmMetrics_KNN = evaluateSemanticSegmentation(ssmPixCracksnNoncracks_KNN, ssmPixCracksnNoncracksGTs,'Verbose', hybrid_inpstruct.ssmVerbose);
    [ALLresults.PrecisionKNNPix_MLAB, ALLresults.RecallKNNPix_MLAB, ALLresults.AccuracyKNNPix_MLAB, ALLresults.SpecificityKNNPix_MLAB, ...
        ALLresults.F1scoreKNNPix_MLAB] = multiclassPrecision_Recall(table2array(ALLresults.ssmMetrics_KNN.ConfusionMatrix));

    % Precision and recall values for SVM
    ALLresults.ssmMetrics_SVM = evaluateSemanticSegmentation(ssmPixCracksnNoncracks_SVM, ssmPixCracksnNoncracksGTs,'Verbose', hybrid_inpstruct.ssmVerbose);
    [ALLresults.PrecisionSVMPix_MLAB, ALLresults.RecallSVMPix_MLAB, ALLresults.AccuracySVMPix_MLAB, ALLresults.SpecificitySVMPix_MLAB, ...
        ALLresults.F1scoreSVMPix_MLAB] = multiclassPrecision_Recall(table2array(ALLresults.ssmMetrics_SVM.ConfusionMatrix));

end
function  wrtiteOutputs2TextFile (fileID,hybrid_inpstruct,jahan_inpstruct, hybrid_allPerms, ANN_classifier_hessian, KNN_classifier_hessian, SVM_classifier_hessian,...
                                    ANN_classifier_mfat, KNN_classifier_mfat, SVM_classifier_mfat,...
                                    ANN_classifier_morpho, KNN_classifier_morpho, SVM_classifier_morpho, ALLresults)

                              
                              
    % Populate the all permutations back to the struct
    if ~(isempty(hybrid_allPerms))
        hybrid_inpstruct.aniso_num_iter = hybrid_allPerms(1,1:2);
        hybrid_inpstruct.aniso.delta_t  = hybrid_allPerms(1,3:4);
        hybrid_inpstruct.aniso.kappa    = hybrid_allPerms(1,5:6);

        switch hybrid_inpstruct.Algorithm_TYPE
            case 'hybrid_hessian'
                hybrid_inpstruct.frangiopt.FrangiScaleRange  = hybrid_allPerms(1,7:8);
                hybrid_inpstruct.frangiopt.FrangiBetaOne     = hybrid_allPerms(1,9);
                hybrid_inpstruct.frangiopt.FrangiBetaTwo     = hybrid_allPerms(1,10);
            case 'hybrid_MFAT'    
                hybrid_inpstruct.MFAToptions.sigmas1       = hybrid_allPerms(1,7);
                hybrid_inpstruct.MFAToptions.sigmas2       = hybrid_allPerms(1,8);
                hybrid_inpstruct.MFAToptions.sigmasScaleRatio = hybrid_allPerms(1,9);
                hybrid_inpstruct.MFAToptions.spacing       = hybrid_allPerms(1,10); 
                hybrid_inpstruct.MFAToptions.tau           = hybrid_allPerms(1,11); 
                hybrid_inpstruct.MFAToptions.tau2          = hybrid_allPerms(1,12); 
                hybrid_inpstruct.MFAToptions.D             = hybrid_allPerms(1,13);
        end
    end

    % Algorithm type
    fprintf(fileID,'Algorithm Type Switch \n');
    fprintf(fileID,'---------------------------------------------------------------------------\n');
    fprintf(fileID,'Algorithm type: %s \n', hybrid_inpstruct.Algorithm_TYPE);
    fprintf(fileID,'Classifier required to filter blobs: %s \n',hybrid_inpstruct.classifier_required);
    fprintf(fileID,'Post-processing using circularity index: %d \n',hybrid_inpstruct.postprocess); 
    fprintf(fileID,'Post-processing type: %s \n',hybrid_inpstruct.post_process_Type); 
    fprintf(fileID,'Image closing switch: %d \n',hybrid_inpstruct.imclosing);
    fprintf(fileID,'Image closing structuring element disk size: %d \n',hybrid_inpstruct.imclose_disk_size);
    fprintf(fileID,'Crack debrancher: %s \n',hybrid_inpstruct.crackDebrancher_required);
    fprintf(fileID,'Crack thin prune method: %s \n',hybrid_inpstruct.thinPruneMethod);
    fprintf(fileID,'Crack thin prune threshold: %3.3f \n',hybrid_inpstruct.thinPruneThresh);
    fprintf(fileID,'Crack or cracks + non-cracks: %s \n',hybrid_inpstruct.ImagesType);
    
    % Algorithm inputs
    switch hybrid_inpstruct.Algorithm_TYPE
        case 'hybrid_hessian'
            fprintf(fileID,'\n\nAlgorithm Inputs \n');
            fprintf(fileID,'---------------------------------------------------------------------------\n');
            fprintf(fileID,'Circularity threshold: %3.4f %3.4f\n',hybrid_inpstruct.circularity_threshold(1),hybrid_inpstruct.circularity_threshold(2));
            fprintf(fileID,'Image contrasting algorithm: %s \n',hybrid_inpstruct.contrast_type);
            fprintf(fileID,'Block size [rows cols] %d %d \n', hybrid_inpstruct.blockSizeR, hybrid_inpstruct.blockSizeC);
            fprintf(fileID,'Non-crack class number: %d \n', hybrid_inpstruct.non_crack_class);
            fprintf(fileID,'Crack class number: %d \n',hybrid_inpstruct.crack_class);
            fprintf(fileID,'CC overlap: %d%% \n',hybrid_inpstruct.CC_overlap_percent *100);
            fprintf(fileID,'Blob removal method: %s\n',hybrid_inpstruct.blobRemovalType);
            fprintf(fileID,'Blob filter standard deviation scale: %3.4f \n', hybrid_inpstruct.blobfilter_sigma);
            fprintf(fileID,'Blob filter removal area: < %d pixels\n', hybrid_inpstruct.morpho_blob_size_area);
            fprintf(fileID,'Anisotropic iteration numbers: %d %d \n', hybrid_inpstruct.aniso_num_iter(1),... 
                    hybrid_inpstruct.aniso_num_iter(2));
            fprintf(fileID,'Anisotropic kappa: %d %d \n', hybrid_inpstruct.aniso.kappa(1),...
                    hybrid_inpstruct.aniso.kappa(2));
            fprintf(fileID,'Frangi scale range: %d %d \n', hybrid_inpstruct.frangiopt.FrangiScaleRange(1),...
                    hybrid_inpstruct.frangiopt.FrangiScaleRange(2));
            fprintf(fileID,'Frangi scale ratio: %d \n', hybrid_inpstruct.frangiopt.FrangiScaleRatio);
            fprintf(fileID,'Frangi beta one: %3.4f \n', hybrid_inpstruct.frangiopt.FrangiBetaOne);
            fprintf(fileID,'Frangi beta two: %3.4f \n', hybrid_inpstruct.frangiopt.FrangiBetaTwo);

            % Algorithm inputs
            fprintf(fileID,'\n\nTrained Classifiers \n');
            fprintf(fileID,'---------------------------------------------------------------------------\n');
            fprintf(fileID,'ANN classifier filename: %s\n',ANN_classifier_hessian);
            fprintf(fileID,'KNN classifier filename: %s\n',KNN_classifier_hessian);
            fprintf(fileID,'SVM classifier filename: %s\n',SVM_classifier_hessian);

        case 'hybrid_MFAT'
            fprintf(fileID,'\n\nAlgorithm Inputs \n');
            fprintf(fileID,'---------------------------------------------------------------------------\n');
            fprintf(fileID,'Circularity threshold: %3.4f %3.4f\n',hybrid_inpstruct.circularity_threshold(1),hybrid_inpstruct.circularity_threshold(2));
            fprintf(fileID,'Image contrasting algorithm: %s \n',hybrid_inpstruct.contrast_type);
            fprintf(fileID,'Block size [rows cols] %d %d \n', hybrid_inpstruct.blockSizeR, hybrid_inpstruct.blockSizeC);
            fprintf(fileID,'Non-crack class number: %d \n', hybrid_inpstruct.non_crack_class);
            fprintf(fileID,'Crack class number: %d \n',hybrid_inpstruct.crack_class);
            fprintf(fileID,'CC overlap: %d%% \n',hybrid_inpstruct.CC_overlap_percent *100);
            fprintf(fileID,'Blob removal method: %s\n',hybrid_inpstruct.blobRemovalType);
            fprintf(fileID,'Blob filter standard deviation scale: %3.4f \n', hybrid_inpstruct.blobfilter_sigma);
            fprintf(fileID,'Blob filter removal area: < %d pixels\n', hybrid_inpstruct.morpho_blob_size_area);
            fprintf(fileID,'Anisotropic iteration numbers: %d %d \n', hybrid_inpstruct.aniso_num_iter(1),...
                    hybrid_inpstruct.aniso_num_iter(2));
            fprintf(fileID,'Anisotropic kappa: %d %d \n', hybrid_inpstruct.aniso.kappa(1),...
                    hybrid_inpstruct.aniso.kappa(2));
            fprintf(fileID,'MFAT algorithm type: %s \n', hybrid_inpstruct.MFAT_TYPE);
            fprintf(fileID,'MFAT scale range: %d %d \n', hybrid_inpstruct.MFAToptions.sigmas1,... 
                    hybrid_inpstruct.MFAToptions.sigmas2);
            fprintf(fileID,'MFAT scale step size: %d \n', hybrid_inpstruct.MFAToptions.sigmasScaleRatio);
            fprintf(fileID,'MFAT spacing: %3.4f \n', hybrid_inpstruct.MFAToptions.spacing);
            fprintf(fileID,'MFAT whiteondark: %d \n', hybrid_inpstruct.MFAToptions.whiteondark);
            fprintf(fileID,'MFAT tau: %3.4f \n', hybrid_inpstruct.MFAToptions.tau);
            fprintf(fileID,'MFAT tau2: %3.4f \n', hybrid_inpstruct.MFAToptions.tau2);
            fprintf(fileID,'MFAT D: %3.4f \n', hybrid_inpstruct.MFAToptions.D);

            % Algorithm inputs
            fprintf(fileID,'\n\nTrained Classifiers \n');
            fprintf(fileID,'---------------------------------------------------------------------------\n');
            fprintf(fileID,'ANN classifier filename: %s\n',ANN_classifier_mfat);
            fprintf(fileID,'KNN classifier filename: %s\n',KNN_classifier_mfat);
            fprintf(fileID,'SVM classifier filename: %s\n',SVM_classifier_mfat);

        case 'morpho'
            fprintf(fileID,'\n\nAlgorithm Inputs \n');
            fprintf(fileID,'---------------------------------------------------------------------------\n');
            fprintf(fileID,'Circularity threshold: %3.4f %3.4f\n',hybrid_inpstruct.circularity_threshold(1),hybrid_inpstruct.circularity_threshold(2));
            fprintf(fileID,'Image contrasting algorithm: %s \n',hybrid_inpstruct.contrast_type);
            fprintf(fileID,'Block size [rows cols] %d %d \n', hybrid_inpstruct.blockSizeR, hybrid_inpstruct.blockSizeC);
            fprintf(fileID,'Non-crack class number: %d \n', hybrid_inpstruct.non_crack_class);
            fprintf(fileID,'Crack class number: %d \n',hybrid_inpstruct.crack_class);
            fprintf(fileID,'CC overlap: %d%% \n',hybrid_inpstruct.CC_overlap_percent *100);
            fprintf(fileID,'Blob removal method: %s\n',hybrid_inpstruct.blobRemovalType);
            fprintf(fileID,'Blob filter standard deviation scale: %3.4f \n', hybrid_inpstruct.blobfilter_sigma);
            fprintf(fileID,'Blob filter removal area: < %d pixels\n', hybrid_inpstruct.morpho_blob_size_area);
            fprintf(fileID,'Minimum crack size in pixel: %d\n',jahan_inpstruct.nmin);
            fprintf(fileID,'Maximum crack size in pixel: %d\n',jahan_inpstruct.nmax);
            fprintf(fileID,'Maximum crack size in pixel: %d\n',jahan_inpstruct.nstep);
            fprintf(fileID,'Angle of structuring element: %d\n',jahan_inpstruct.anglebetween);

            % Algorithm inputs
            fprintf(fileID,'\n\nTrained Classifiers \n');
            fprintf(fileID,'---------------------------------------------------------------------------\n');
            fprintf(fileID,'ANN classifier filename: %s\n',ANN_classifier_morpho);
            fprintf(fileID,'KNN classifier filename: %s\n',KNN_classifier_morpho);
            fprintf(fileID,'SVM classifier filename: %s\n',SVM_classifier_morpho);
    end

    % Image wise classification results
    if ~(strcmp(hybrid_inpstruct.ImagesType,'crack_only'))
        fprintf(fileID,'\n\nImage wise classification results \n');
        fprintf(fileID,'---------------------------------------------------------------------------\n');
        fprintf(fileID,'Classifier name      ANN           KNN            SVM \n');
        fprintf(fileID,'---------------------------------------------------------------------------\n');
        fprintf(fileID,'Precision           %3.4f         %3.4f         %3.4f \n', ALLresults.PrecisionANNImg, ...
                ALLresults.PrecisionKNNImg, ALLresults.PrecisionSVMImg);
        fprintf(fileID,'Recall              %3.4f         %3.4f         %3.4f \n', ALLresults.RecallANNImg, ...
                ALLresults.RecallKNNImg, ALLresults.RecallSVMImg);
        fprintf(fileID,'F1score             %3.4f         %3.4f         %3.4f \n', ALLresults.F1scoreANNImg, ...
            ALLresults.F1scoreKNNImg, ALLresults.F1scoreSVMImg);
        fprintf(fileID,'Accuracy            %3.4f         %3.4f         %3.4f \n', ALLresults.AccuracyANNImg, ...
            ALLresults.AccuracyKNNImg, ALLresults.AccuracySVMImg);
        fprintf(fileID,'Specificity         %3.4f         %3.4f         %3.4f \n', ALLresults.SpecificityANNImg, ...
            ALLresults.SpecificityKNNImg, ALLresults.SpecificitySVMImg);
    end

    % Bounding box classification results
    fprintf(fileID,'\n\nEach object wise (Bounding Box) classification results \n');
    fprintf(fileID,'---------------------------------------------------------------------------\n');
    fprintf(fileID,'Classifier name      ANN           KNN            SVM \n');
    fprintf(fileID,'---------------------------------------------------------------------------\n');
    fprintf(fileID,'Precision           %3.4f         %3.4f         %3.4f \n', ALLresults.PrecisionANNBbox, ...
            ALLresults.PrecisionKNNBbox, ALLresults.PrecisionSVMBbox);
    fprintf(fileID,'Recall              %3.4f         %3.4f         %3.4f \n', ALLresults.RecallANNBbox, ...
            ALLresults.RecallKNNBbox, ALLresults.RecallSVMBbox);
    fprintf(fileID,'F1score             %3.4f         %3.4f         %3.4f \n', ALLresults.F1scoreANNBbox, ...
            ALLresults.F1scoreKNNBbox, ALLresults.F1scoreSVMBbox);

    % Pixels classification results
    fprintf(fileID,'\n\nEach object wise (Pixels) classification results \n');
    fprintf(fileID,'---------------------------------------------------------------------------\n');
    fprintf(fileID,'Classifier name      ANN           KNN            SVM \n');
    fprintf(fileID,'---------------------------------------------------------------------------\n');
    fprintf(fileID,'Precision           %3.4f         %3.4f         %3.4f \n', ALLresults.PrecisionANNPix, ...
            ALLresults.PrecisionKNNPix, ALLresults.PrecisionSVMPix);
    fprintf(fileID,'Recall              %3.4f         %3.4f         %3.4f \n', ALLresults.RecallANNPix, ...
            ALLresults.RecallKNNPix, ALLresults.RecallSVMPix);
    fprintf(fileID,'F1score             %3.4f         %3.4f         %3.4f \n', ALLresults.F1scoreANNPix, ...
            ALLresults.F1scoreKNNPix, ALLresults.F1scoreSVMPix);
    fprintf(fileID,'Accuracy            %3.4f         %3.4f         %3.4f \n', ALLresults.AccuracyANNPix, ...
        ALLresults.AccuracyKNNPix, ALLresults.AccuracySVMPix);
    fprintf(fileID,'Specificity         %3.4f         %3.4f         %3.4f \n', ALLresults.SpecificityANNPix, ...
        ALLresults.SpecificityKNNPix, ALLresults.SpecificitySVMPix);
    fprintf(fileID,'---------------------------------------------------------------------------\n');
    fprintf(fileID,'---------------------------------------------------------------------------\n\n\n');



    % Bounding box classification results (MATLAB)
    fprintf(fileID,'---------------------------------------------------------------------------\n');
    fprintf(fileID,'\n\nEach object wise (Bounding Box) classification results by MATLAB\n');
    fprintf(fileID,'---------------------------------------------------------------------------\n');
    fprintf(fileID,'Classifier name      ANN           KNN            SVM \n');
    fprintf(fileID,'---------------------------------------------------------------------------\n');
    fprintf(fileID,'Precision           %3.4f         %3.4f         %3.4f \n', ALLresults.PrecisionANNBbox_MLAB, ...
            ALLresults.PrecisionKNNBbox_MLAB, ALLresults.PrecisionSVMBbox_MLAB);
    fprintf(fileID,'Recall              %3.4f         %3.4f         %3.4f \n', ALLresults.RecallANNBbox_MLAB, ...
            ALLresults.RecallKNNBbox_MLAB, ALLresults.RecallSVMBbox_MLAB);
    fprintf(fileID,'F1score             %3.4f         %3.4f         %3.4f \n', ALLresults.F1scoreANNBbox_MLAB, ...
            ALLresults.F1scoreKNNBbox_MLAB, ALLresults.F1scoreSVMBbox_MLAB);

    % Pixels classification results (MATLAB)
    fprintf(fileID,'\n\nEach object wise (Pixels) classification results by MATLAB\n');
    fprintf(fileID,'---------------------------------------------------------------------------\n');
    fprintf(fileID,'Classifier name      ANN           KNN            SVM \n');
    fprintf(fileID,'---------------------------------------------------------------------------\n');
    fprintf(fileID,'Precision           %3.4f         %3.4f         %3.4f \n', ALLresults.PrecisionANNPix_MLAB, ...
            ALLresults.PrecisionKNNPix_MLAB, ALLresults.PrecisionSVMPix_MLAB);
    fprintf(fileID,'Recall              %3.4f         %3.4f         %3.4f \n', ALLresults.RecallANNPix_MLAB, ...
            ALLresults.RecallKNNPix_MLAB, ALLresults.RecallSVMPix_MLAB);
    fprintf(fileID,'F1score             %3.4f         %3.4f         %3.4f \n', ALLresults.F1scoreANNPix_MLAB, ...
            ALLresults.F1scoreKNNPix_MLAB, ALLresults.F1scoreSVMPix_MLAB);
    fprintf(fileID,'Accuracy            %3.4f         %3.4f         %3.4f \n', ALLresults.AccuracyANNPix_MLAB, ...
        ALLresults.AccuracyKNNPix_MLAB, ALLresults.AccuracySVMPix_MLAB);
    fprintf(fileID,'Specificity         %3.4f         %3.4f         %3.4f \n', ALLresults.SpecificityANNPix_MLAB, ...
        ALLresults.SpecificityKNNPix_MLAB, ALLresults.SpecificitySVMPix_MLAB);
    
    fprintf(fileID,'--------------------------------------------------------------------------- \n');
    fprintf(fileID,'GlobalAccuracy      %3.4f         %3.4f         %3.4f \n', ALLresults.ssmMetrics_ANN.DataSetMetrics.GlobalAccuracy, ...
        ALLresults.ssmMetrics_KNN.DataSetMetrics.GlobalAccuracy, ALLresults.ssmMetrics_SVM.DataSetMetrics.GlobalAccuracy);
    fprintf(fileID,'MeanAccuracy        %3.4f         %3.4f         %3.4f \n', ALLresults.ssmMetrics_ANN.DataSetMetrics.MeanAccuracy, ...
        ALLresults.ssmMetrics_KNN.DataSetMetrics.MeanAccuracy, ALLresults.ssmMetrics_SVM.DataSetMetrics.MeanAccuracy);
    fprintf(fileID,'MeanIoU             %3.4f         %3.4f         %3.4f \n', ALLresults.ssmMetrics_ANN.DataSetMetrics.MeanIoU, ...
        ALLresults.ssmMetrics_KNN.DataSetMetrics.MeanIoU, ALLresults.ssmMetrics_SVM.DataSetMetrics.MeanIoU);
    fprintf(fileID,'WeightedIoU         %3.4f         %3.4f         %3.4f \n', ALLresults.ssmMetrics_ANN.DataSetMetrics.WeightedIoU, ...
        ALLresults.ssmMetrics_KNN.DataSetMetrics.WeightedIoU, ALLresults.ssmMetrics_SVM.DataSetMetrics.WeightedIoU);
    fprintf(fileID,'MeanBFScore         %3.4f         %3.4f         %3.4f \n', ALLresults.ssmMetrics_ANN.DataSetMetrics.MeanBFScore, ...
        ALLresults.ssmMetrics_KNN.DataSetMetrics.MeanBFScore, ALLresults.ssmMetrics_SVM.DataSetMetrics.MeanBFScore);
    fprintf(fileID,'---------------------------------------------------------------------------\n');
    fprintf(fileID,'---------------------------------------------------------------------------\n\n\n');

end
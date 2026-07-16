% Initialize arrays
rocArrayij_ImageClassification = cell(2*size(aniso.num_iter,1)+1,1);
rocArrayij_AllComponents = cell(2*size(aniso.num_iter,1)+1,1);
rocArrayBBox_MLAB = cell(2*size(aniso.num_iter,1)+1,1);
rocArray_SSM = cell(2*size(aniso.num_iter,1)+1,1);

for i = 1:length(Algorithm_TYPE)
    
    % Populate algorithm type
    hybrid_inpstruct.Algorithm_TYPE = Algorithm_TYPE{i};
    
    switch hybrid_inpstruct.Algorithm_TYPE
        case 'hybrid_hessian'

        % Load ANN, KNN and SVM kernels
        load (ANN_classifier_hybrid,'net');
        load (KNN_classifier_hybrid,'MdlKNN');
        load (SVM_classifier_hybrid,'ScoreCSVMModel');

            for j = 1:size(aniso.num_iter,1)
                
                % Get worker ID
                workerID = 0;
                
                % Iteration numbers
                hybrid_Frangi_allPerms = hybrid_Frangi_search_allPerms(j,:);
                
                % Print the anisotropic iteration number
                fprintf('Hessian Total iteration no.: %d | Anisotropic [I and II] iterations: %d %d\n', j, hybrid_Frangi_allPerms(1,1),...
                        hybrid_Frangi_allPerms(1,2));

                % Extract feature matrix and labels
                switch hybrid_inpstruct.parallel_sequential_processing
                    case 'sequential'
                        [TPFPFNTNpixANN, TPFPFNTNpixKNN, TPFPFNTNpixSVM, TPFPFNBboxANN, ...
                            TPFPFNBboxKNN, TPFPFNBboxSVM,...
                            PredictLabelsANN,PredictLabelsKNN,PredictLabelsSVM,SCORES,true_index,BBoxANN,BBoxKNN,BBoxSVM, ...
                            ssmPixCracksnNoncracks_ANN, ssmPixCracksnNoncracks_KNN, ssmPixCracksnNoncracks_SVM, ...
                            PredictScoresImgANN,PredictScoresImgKNN, PredictScoresImgSVM, ...
                            PixGT, PredictScoresSSMANN, PredictScoresSSMKNN, PredictScoresSSMSVM]  = classifierResult_2017Revised...
                                    (workerID, fileID, hybrid_inpstruct, jahan_inpstruct, hybrid_Frangi_allPerms,images2classifier,[], imagesGroundTruth2classifier, ...
                            classnumber, MdlKNN, ScoreCSVMModel, net, imgCount);
                    case 'parallel'
                        [TPFPFNTNpixANN, TPFPFNTNpixKNN, TPFPFNTNpixSVM, TPFPFNBboxANN, ...
                            TPFPFNBboxKNN, TPFPFNBboxSVM,...
                            PredictLabelsANN,PredictLabelsKNN,PredictLabelsSVM,SCORES,true_index,BBoxANN,BBoxKNN,BBoxSVM, ...
                            ssmPixCracksnNoncracks_ANN, ssmPixCracksnNoncracks_KNN, ssmPixCracksnNoncracks_SVM, ...
                            PredictScoresImgANN,PredictScoresImgKNN, PredictScoresImgSVM, ...
                            PixGT, PredictScoresSSMANN, PredictScoresSSMKNN, PredictScoresSSMSVM] = classifierResult_2020_ParFor...
                                    (workerID, fileID, hybrid_inpstruct, jahan_inpstruct, hybrid_Frangi_allPerms,images2classifier,[], imagesGroundTruth2classifier, ...
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
                [rocArrayij_ImageClassification{j}, rocArrayij_AllComponents{j}, rocArrayBBox_MLAB{j}, rocArray_SSM{j}] = store_ROC_Values(hybrid_inpstruct,Ytest,score_svmTs,score_knnTs, score_annTs, ...
                    objBoxCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs, BBoxANN, BBoxKNN, BBoxSVM, ...
                                                      classnumber,PredictScoresImgANN,PredictScoresImgKNN, PredictScoresImgSVM, ...
                                                      PixGT, PredictScoresSSMANN, PredictScoresSSMKNN, PredictScoresSSMSVM);

                %% Classification results
                Calculate_Classification_Results;

                %% Write output to a textfile
                WriteOutputs;

                %% Store in a structure

                % Algorithm type, aniso iterations and post-processing
                % details
                Classification_Results(j).Alg_TYPE  = hybrid_inpstruct.Algorithm_TYPE;
                Classification_Results(j).Alg_iter  = hybrid_itrnum.aniso_num_iter;
                Classification_Results(j).Alg_circ  = hybrid_inpstruct.circularity_threshold;
                Classification_Results(j).Alg_blob  = hybrid_inpstruct.blobfilter_sigma;

                % Image wise
                if ~(strcmp(hybrid_inpstruct.ImagesType,'crack_only'))
                    Classification_Results(j).PrANNImg = PrecisionANNImg;
                    Classification_Results(j).PrKNNImg = PrecisionKNNImg;
                    Classification_Results(j).PrSVMImg = PrecisionSVMImg;

                    Classification_Results(j).ReANNImg = RecallANNImg;
                    Classification_Results(j).ReKNNImg = RecallKNNImg;
                    Classification_Results(j).ReSVMImg = RecallSVMImg;

                    Classification_Results(j).F1ANNImg = F1scoreANNImg;
                    Classification_Results(j).F1KNNImg = F1scoreKNNImg;
                    Classification_Results(j).F1SVMImg = F1scoreSVMImg;

                    Classification_Results(j).AccANNImg = AccuracyANNImg;
                    Classification_Results(j).AccKNNImg = AccuracyKNNImg;
                    Classification_Results(j).AccSVMImg = AccuracySVMImg;

                    Classification_Results(j).SpecANNImg = SpecificityANNImg;
                    Classification_Results(j).SpecKNNImg = SpecificityKNNImg;
                    Classification_Results(j).SpecSVMImg = SpecificitySVMImg;
                end

                % Bounding box
                Classification_Results(j).PrANNBbox = PrecisionANNBbox;
                Classification_Results(j).PrKNNBbox = PrecisionKNNBbox;
                Classification_Results(j).PrSVMBbox = PrecisionSVMBbox;

                Classification_Results(j).ReNNBbox = RecallANNBbox;
                Classification_Results(j).ReKNNBbox = RecallKNNBbox;
                Classification_Results(j).ReSVMBbox = RecallSVMBbox;

                Classification_Results(j).F1ANNBbox = F1scoreANNBbox;
                Classification_Results(j).F1KNNBbox = F1scoreKNNBbox;
                Classification_Results(j).F1SVMBbox = F1scoreSVMBbox;

                % Pixel wise
                Classification_Results(j).PrANNPix = PrecisionANNPix;
                Classification_Results(j).PrKNNPix = PrecisionKNNPix;
                Classification_Results(j).PrSVMPix = PrecisionSVMPix;

                Classification_Results(j).ReANNPix = RecallANNPix;
                Classification_Results(j).ReKNNPix = RecallKNNPix;
                Classification_Results(j).ReSVMPix = RecallSVMPix;

                Classification_Results(j).F1ANNPix = F1scoreANNPix;
                Classification_Results(j).F1KNNPix = F1scoreKNNPix;
                Classification_Results(j).F1SVMPix = F1scoreSVMPix;
                
                
                % Bounding box MATLAB
                Classification_Results(j).PrANNBbox_MLAB = PrecisionANNBbox_MLAB;
                Classification_Results(j).PrKNNBbox_MLAB = PrecisionKNNBbox_MLAB;
                Classification_Results(j).PrSVMBbox_MLAB = PrecisionSVMBbox_MLAB;

                Classification_Results(j).ReNNBbox_MLAB = RecallANNBbox_MLAB;
                Classification_Results(j).ReKNNBbox_MLAB = RecallKNNBbox_MLAB;
                Classification_Results(j).ReSVMBbox_MLAB = RecallSVMBbox_MLAB;

                Classification_Results(j).F1ANNBbox_MLAB = F1scoreANNBbox_MLAB;
                Classification_Results(j).F1KNNBbox_MLAB = F1scoreKNNBbox_MLAB;
                Classification_Results(j).F1SVMBbox_MLAB = F1scoreSVMBbox_MLAB;

                % Pixel wise MATLAB
                Classification_Results(j).PrANNPix_MLAB = PrecisionANNPix_MLAB;
                Classification_Results(j).PrKNNPix_MLAB = PrecisionKNNPix_MLAB;
                Classification_Results(j).PrSVMPix_MLAB = PrecisionSVMPix_MLAB;

                Classification_Results(j).ReANNPix_MLAB = RecallANNPix_MLAB;
                Classification_Results(j).ReKNNPix_MLAB = RecallKNNPix_MLAB;
                Classification_Results(j).ReSVMPix_MLAB = RecallSVMPix_MLAB;

                Classification_Results(j).F1ANNPix_MLAB = F1scoreANNPix_MLAB;
                Classification_Results(j).F1KNNPix_MLAB = F1scoreKNNPix_MLAB;
                Classification_Results(j).F1SVMPix_MLAB = F1scoreSVMPix_MLAB;
                
                Classification_Results(j).AccANNPix_MLAB = AccuracyANNPix_MLAB;
                Classification_Results(j).AccKNNPix_MLAB = AccuracyKNNPix_MLAB;
                Classification_Results(j).AccSVMPix_MLAB = AccuracySVMPix_MLAB;

                Classification_Results(j).SpecANNPix_MLAB = SpecificityANNPix_MLAB;
                Classification_Results(j).SpecKNNPix_MLAB = SpecificityKNNPix_MLAB;
                Classification_Results(j).SpecSVMPix_MLAB = SpecificitySVMPix_MLAB;
                
                Classification_Results(j).GlobalAccANNPix_MLAB = ssmMetrics_ANN.DataSetMetrics.GlobalAccuracy;
                Classification_Results(j).GlobalAccKNNPix_MLAB = ssmMetrics_KNN.DataSetMetrics.GlobalAccuracy;
                Classification_Results(j).GlobalAccSVMPix_MLAB = ssmMetrics_SVM.DataSetMetrics.GlobalAccuracy;
                
                Classification_Results(j).MeanAccuracyANNPix_MLAB = ssmMetrics_ANN.DataSetMetrics.MeanAccuracy;
                Classification_Results(j).MeanAccuracyKNNPix_MLAB = ssmMetrics_KNN.DataSetMetrics.MeanAccuracy;
                Classification_Results(j).MeanAccuracySVMPix_MLAB = ssmMetrics_SVM.DataSetMetrics.MeanAccuracy;
                
                Classification_Results(j).MeanIoUANNPix_MLAB = ssmMetrics_ANN.DataSetMetrics.MeanIoU;
                Classification_Results(j).MeanIoUKNNPix_MLAB = ssmMetrics_KNN.DataSetMetrics.MeanIoU;
                Classification_Results(j).MeanIoUSVMPix_MLAB = ssmMetrics_SVM.DataSetMetrics.MeanIoU;
                
                Classification_Results(j).WeightedIoUANNPix_MLAB = ssmMetrics_ANN.DataSetMetrics.WeightedIoU;
                Classification_Results(j).WeightedIoUKNNPix_MLAB = ssmMetrics_KNN.DataSetMetrics.WeightedIoU;
                Classification_Results(j).WeightedIoUSVMPix_MLAB = ssmMetrics_SVM.DataSetMetrics.WeightedIoU;
                
                Classification_Results(j).MeanBFScoreANNPix_MLAB = ssmMetrics_ANN.DataSetMetrics.MeanBFScore;
                Classification_Results(j).MeanBFScoreKNNPix_MLAB = ssmMetrics_KNN.DataSetMetrics.MeanBFScore;
                Classification_Results(j).MeanBFScoreSVMPix_MLAB = ssmMetrics_SVM.DataSetMetrics.MeanBFScore;
                
            end
            
        case 'hybrid_MFAT'

            % Load ANN, KNN and SVM kernels
            load (ANN_classifier_hybrid,'net');
            load (KNN_classifier_hybrid,'MdlKNN');
            load (SVM_classifier_hybrid,'ScoreCSVMModel');

            for j = size(hybrid_Frangi_search_allPerms,1) + 1 : size(hybrid_Frangi_search_allPerms,1) + size(hybrid_MFAT_search_allPerms,1)

                % Get worker ID
                workerID = 0;
                
                idx = j - size(hybrid_Frangi_search_allPerms,1);
                
                % Iteration numbers
                hybrid_MFAT_allPerms = hybrid_MFAT_search_allPerms(idx,:);
                
                % Print the anisotropic iteration number
                fprintf('MFAT Total iteration no.: %d | Anisotropic [I and II] iterations: %d %d\n', idx, hybrid_MFAT_allPerms(1,1),...
                        hybrid_MFAT_allPerms(1,2))

                % Extract feature matrix and labels
                switch hybrid_inpstruct.parallel_sequential_processing
                    case 'sequential'
                        [TPFPFNTNpixANN, TPFPFNTNpixKNN, TPFPFNTNpixSVM, TPFPFNBboxANN, ...
                            TPFPFNBboxKNN, TPFPFNBboxSVM,...
                            PredictLabelsANN,PredictLabelsKNN,PredictLabelsSVM,SCORES,true_index,BBoxANN,BBoxKNN,BBoxSVM, ...
                            ssmPixCracksnNoncracks_ANN, ssmPixCracksnNoncracks_KNN, ssmPixCracksnNoncracks_SVM, ...
                            PredictScoresImgANN,PredictScoresImgKNN, PredictScoresImgSVM, ...
                            PixGT, PredictScoresSSMANN, PredictScoresSSMKNN, PredictScoresSSMSVM]  = classifierResult_2017Revised...
                                    (workerID, fileID, hybrid_inpstruct, jahan_inpstruct, hybrid_Frangi_allPerms,images2classifier,[], imagesGroundTruth2classifier, ...
                            classnumber, MdlKNN, ScoreCSVMModel, net, imgCount);
                    case 'parallel'
                        [TPFPFNTNpixANN, TPFPFNTNpixKNN, TPFPFNTNpixSVM, TPFPFNBboxANN, ...
                            TPFPFNBboxKNN, TPFPFNBboxSVM,...
                            PredictLabelsANN,PredictLabelsKNN,PredictLabelsSVM,SCORES,true_index,BBoxANN,BBoxKNN,BBoxSVM, ...
                            ssmPixCracksnNoncracks_ANN, ssmPixCracksnNoncracks_KNN, ssmPixCracksnNoncracks_SVM, ...
                            PredictScoresImgANN,PredictScoresImgKNN, PredictScoresImgSVM, ...
                            PixGT, PredictScoresSSMANN, PredictScoresSSMKNN, PredictScoresSSMSVM] = classifierResult_2020_ParFor...
                                    (workerID, fileID, hybrid_inpstruct, jahan_inpstruct, hybrid_Frangi_allPerms,images2classifier,[], imagesGroundTruth2classifier, ...
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
                [rocArrayij_ImageClassification{j}, rocArrayij_AllComponents{j}, rocArrayBBox_MLAB{j}, rocArray_SSM{j}] = store_ROC_Values(hybrid_inpstruct,Ytest,score_svmTs,score_knnTs, score_annTs, ...
                    objBoxCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs, BBoxANN, BBoxKNN, BBoxSVM, ...
                                                      classnumber,PredictScoresImgANN,PredictScoresImgKNN, PredictScoresImgSVM, ...
                                                      PixGT, PredictScoresSSMANN, PredictScoresSSMKNN, PredictScoresSSMSVM);

                %% Classification results
                Calculate_Classification_Results;

                %% Write output to a textfile
                WriteOutputs;

                %% Store in a structure

                % Algorithm type, aniso iterations and post-processing
                % details
                Classification_Results(j).Alg_TYPE  = hybrid_inpstruct.Algorithm_TYPE;
                Classification_Results(j).Alg_iter  = hybrid_itrnum.aniso_num_iter;
                Classification_Results(j).Alg_circ  = hybrid_inpstruct.circularity_threshold;
                Classification_Results(j).Alg_blob  = hybrid_inpstruct.blobfilter_sigma;

                % Image wise
                if ~(strcmp(hybrid_inpstruct.ImagesType,'crack_only'))
                    Classification_Results(j).PrANNImg = PrecisionANNImg;
                    Classification_Results(j).PrKNNImg = PrecisionKNNImg;
                    Classification_Results(j).PrSVMImg = PrecisionSVMImg;

                    Classification_Results(j).ReANNImg = RecallANNImg;
                    Classification_Results(j).ReKNNImg = RecallKNNImg;
                    Classification_Results(j).ReSVMImg = RecallSVMImg;

                    Classification_Results(j).F1ANNImg = F1scoreANNImg;
                    Classification_Results(j).F1KNNImg = F1scoreKNNImg;
                    Classification_Results(j).F1SVMImg = F1scoreSVMImg;

                    Classification_Results(j).AccANNImg = AccuracyANNImg;
                    Classification_Results(j).AccKNNImg = AccuracyKNNImg;
                    Classification_Results(j).AccSVMImg = AccuracySVMImg;

                    Classification_Results(j).SpecANNImg = SpecificityANNImg;
                    Classification_Results(j).SpecKNNImg = SpecificityKNNImg;
                    Classification_Results(j).SpecSVMImg = SpecificitySVMImg;
                end

                % Bounding box
                Classification_Results(j).PrANNBbox = PrecisionANNBbox;
                Classification_Results(j).PrKNNBbox = PrecisionKNNBbox;
                Classification_Results(j).PrSVMBbox = PrecisionSVMBbox;

                Classification_Results(j).ReNNBbox = RecallANNBbox;
                Classification_Results(j).ReKNNBbox = RecallKNNBbox;
                Classification_Results(j).ReSVMBbox = RecallSVMBbox;

                Classification_Results(j).F1ANNBbox = F1scoreANNBbox;
                Classification_Results(j).F1KNNBbox = F1scoreKNNBbox;
                Classification_Results(j).F1SVMBbox = F1scoreSVMBbox;

                % Pixel wise
                Classification_Results(j).PrANNPix = PrecisionANNPix;
                Classification_Results(j).PrKNNPix = PrecisionKNNPix;
                Classification_Results(j).PrSVMPix = PrecisionSVMPix;

                Classification_Results(j).ReANNPix = RecallANNPix;
                Classification_Results(j).ReKNNPix = RecallKNNPix;
                Classification_Results(j).ReSVMPix = RecallSVMPix;

                Classification_Results(j).F1ANNPix = F1scoreANNPix;
                Classification_Results(j).F1KNNPix = F1scoreKNNPix;
                Classification_Results(j).F1SVMPix = F1scoreSVMPix;
                
                
                % Bounding box MATLAB
                Classification_Results(j).PrANNBbox_MLAB = PrecisionANNBbox_MLAB;
                Classification_Results(j).PrKNNBbox_MLAB = PrecisionKNNBbox_MLAB;
                Classification_Results(j).PrSVMBbox_MLAB = PrecisionSVMBbox_MLAB;

                Classification_Results(j).ReNNBbox_MLAB = RecallANNBbox_MLAB;
                Classification_Results(j).ReKNNBbox_MLAB = RecallKNNBbox_MLAB;
                Classification_Results(j).ReSVMBbox_MLAB = RecallSVMBbox_MLAB;

                Classification_Results(j).F1ANNBbox_MLAB = F1scoreANNBbox_MLAB;
                Classification_Results(j).F1KNNBbox_MLAB = F1scoreKNNBbox_MLAB;
                Classification_Results(j).F1SVMBbox_MLAB = F1scoreSVMBbox_MLAB;

                % Pixel wise MATLAB
                Classification_Results(j).PrANNPix_MLAB = PrecisionANNPix_MLAB;
                Classification_Results(j).PrKNNPix_MLAB = PrecisionKNNPix_MLAB;
                Classification_Results(j).PrSVMPix_MLAB = PrecisionSVMPix_MLAB;

                Classification_Results(j).ReANNPix_MLAB = RecallANNPix_MLAB;
                Classification_Results(j).ReKNNPix_MLAB = RecallKNNPix_MLAB;
                Classification_Results(j).ReSVMPix_MLAB = RecallSVMPix_MLAB;

                Classification_Results(j).F1ANNPix_MLAB = F1scoreANNPix_MLAB;
                Classification_Results(j).F1KNNPix_MLAB = F1scoreKNNPix_MLAB;
                Classification_Results(j).F1SVMPix_MLAB = F1scoreSVMPix_MLAB;
                
                Classification_Results(j).AccANNPix_MLAB = AccuracyANNPix_MLAB;
                Classification_Results(j).AccKNNPix_MLAB = AccuracyKNNPix_MLAB;
                Classification_Results(j).AccSVMPix_MLAB = AccuracySVMPix_MLAB;

                Classification_Results(j).SpecANNPix_MLAB = SpecificityANNPix_MLAB;
                Classification_Results(j).SpecKNNPix_MLAB = SpecificityKNNPix_MLAB;
                Classification_Results(j).SpecSVMPix_MLAB = SpecificitySVMPix_MLAB;
                
                Classification_Results(j).GlobalAccANNPix_MLAB = ssmMetrics_ANN.DataSetMetrics.GlobalAccuracy;
                Classification_Results(j).GlobalAccKNNPix_MLAB = ssmMetrics_KNN.DataSetMetrics.GlobalAccuracy;
                Classification_Results(j).GlobalAccSVMPix_MLAB = ssmMetrics_SVM.DataSetMetrics.GlobalAccuracy;
                
                Classification_Results(j).MeanAccuracyANNPix_MLAB = ssmMetrics_ANN.DataSetMetrics.MeanAccuracy;
                Classification_Results(j).MeanAccuracyKNNPix_MLAB = ssmMetrics_KNN.DataSetMetrics.MeanAccuracy;
                Classification_Results(j).MeanAccuracySVMPix_MLAB = ssmMetrics_SVM.DataSetMetrics.MeanAccuracy;
                
                Classification_Results(j).MeanIoUANNPix_MLAB = ssmMetrics_ANN.DataSetMetrics.MeanIoU;
                Classification_Results(j).MeanIoUKNNPix_MLAB = ssmMetrics_KNN.DataSetMetrics.MeanIoU;
                Classification_Results(j).MeanIoUSVMPix_MLAB = ssmMetrics_SVM.DataSetMetrics.MeanIoU;
                
                Classification_Results(j).WeightedIoUANNPix_MLAB = ssmMetrics_ANN.DataSetMetrics.WeightedIoU;
                Classification_Results(j).WeightedIoUKNNPix_MLAB = ssmMetrics_KNN.DataSetMetrics.WeightedIoU;
                Classification_Results(j).WeightedIoUSVMPix_MLAB = ssmMetrics_SVM.DataSetMetrics.WeightedIoU;
                
                Classification_Results(j).MeanBFScoreANNPix_MLAB = ssmMetrics_ANN.DataSetMetrics.MeanBFScore;
                Classification_Results(j).MeanBFScoreKNNPix_MLAB = ssmMetrics_KNN.DataSetMetrics.MeanBFScore;
                Classification_Results(j).MeanBFScoreSVMPix_MLAB = ssmMetrics_SVM.DataSetMetrics.MeanBFScore;
                
            end

        case 'morpho'
            
            % Print the anisotropic iteration number
            fprintf('Morphological method started!\n');
            
            % Load ANN, KNN and SVM kernels
            load (ANN_classifier_morpho,'net');
            load (KNN_classifier_morpho,'MdlKNN');
            load (SVM_classifier_morpho,'ScoreCSVMModel');
        
            % Get worker ID
            workerID = 0;
            
            if(isempty(j))
                j=1;
            else
                j=j+1;
            end

            hybrid_itrnum = [];

            switch hybrid_inpstruct.parallel_sequential_processing
                case 'sequential'
                % Extract feature matrix and labels
                    [TPFPFNTNpixANN, TPFPFNTNpixKNN, TPFPFNTNpixSVM, TPFPFNBboxANN, ...
                        TPFPFNBboxKNN, TPFPFNBboxSVM,...
                        PredictLabelsANN,PredictLabelsKNN,PredictLabelsSVM,SCORES,true_index,BBoxANN,BBoxKNN,BBoxSVM,...
                        ssmPixCracksnNoncracks_ANN, ssmPixCracksnNoncracks_KNN, ssmPixCracksnNoncracks_SVM, ...
                            PredictScoresImgANN,PredictScoresImgKNN, PredictScoresImgSVM, ...
                            PixGT, PredictScoresSSMANN, PredictScoresSSMKNN, PredictScoresSSMSVM] = classifierResult_2017Revised...
                            (workerID, fileID, hybrid_inpstruct, jahan_inpstruct, hybrid_Frangi_allPerms,images2classifier,[], imagesGroundTruth2classifier, ...
                                classnumber, MdlKNN, ScoreCSVMModel, net, imgCount);
                case 'parallel'
                % Extract feature matrix and labels
                    [TPFPFNTNpixANN, TPFPFNTNpixKNN, TPFPFNTNpixSVM, TPFPFNBboxANN, ...
                        TPFPFNBboxKNN, TPFPFNBboxSVM,...
                        PredictLabelsANN,PredictLabelsKNN,PredictLabelsSVM,SCORES,true_index,BBoxANN,BBoxKNN,BBoxSVM,...
                        ssmPixCracksnNoncracks_ANN, ssmPixCracksnNoncracks_KNN, ssmPixCracksnNoncracks_SVM, ...
                            PredictScoresImgANN,PredictScoresImgKNN, PredictScoresImgSVM, ...
                            PixGT, PredictScoresSSMANN, PredictScoresSSMKNN, PredictScoresSSMSVM] = classifierResult_2020_ParFor...
                                (workerID, fileID, hybrid_inpstruct, jahan_inpstruct, hybrid_Frangi_allPerms,images2classifier,[], imagesGroundTruth2classifier, ...
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
            [rocArrayij_ImageClassification{j}, rocArrayij_AllComponents{j}, rocArrayBBox_MLAB{j}, rocArray_SSM{j}] = store_ROC_Values(hybrid_inpstruct,Ytest,score_svmTs,score_knnTs, score_annTs,  ...
                    objBoxCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs, BBoxANN, BBoxKNN, BBoxSVM, ...
                                                      classnumber,PredictScoresImgANN,PredictScoresImgKNN,PredictScoresImgSVM, ...
                                                      PixGT, PredictScoresSSMANN, PredictScoresSSMKNN, PredictScoresSSMSVM);

            %% Classification results
            Calculate_Classification_Results;

            %% Write output to a textfile
            WriteOutputs;

            %% Store in a structure

            % Algorithm type
            Classification_Results(j).Alg_TYPE  = hybrid_inpstruct.Algorithm_TYPE;
            Classification_Results(j).Alg_iter  = 'N/A';
            Classification_Results(j).Alg_circ  = hybrid_inpstruct.circularity_threshold;
            Classification_Results(j).Alg_blob  = hybrid_inpstruct.morpho_blob_size_area;

            % Image wise
            if ~(strcmp(hybrid_inpstruct.ImagesType,'crack_only'))
                Classification_Results(j).PrANNImg = PrecisionANNImg;
                Classification_Results(j).PrKNNImg = PrecisionKNNImg;
                Classification_Results(j).PrSVMImg = PrecisionSVMImg;

                Classification_Results(j).ReANNImg = RecallANNImg;
                Classification_Results(j).ReKNNImg = RecallKNNImg;
                Classification_Results(j).ReSVMImg = RecallSVMImg;

                Classification_Results(j).F1ANNImg = F1scoreANNImg;
                Classification_Results(j).F1KNNImg = F1scoreKNNImg;
                Classification_Results(j).F1SVMImg = F1scoreSVMImg;

                Classification_Results(j).AccANNImg = AccuracyANNImg;
                Classification_Results(j).AccKNNImg = AccuracyKNNImg;
                Classification_Results(j).AccSVMImg = AccuracySVMImg;

                Classification_Results(j).SpecANNImg = SpecificityANNImg;
                Classification_Results(j).SpecKNNImg = SpecificityKNNImg;
                Classification_Results(j).SpecSVMImg = SpecificitySVMImg;
            end

            % Bounding box
            Classification_Results(j).PrANNBbox = PrecisionANNBbox;
            Classification_Results(j).PrKNNBbox = PrecisionKNNBbox;
            Classification_Results(j).PrSVMBbox = PrecisionSVMBbox;

            Classification_Results(j).ReNNBbox = RecallANNBbox;
            Classification_Results(j).ReKNNBbox = RecallKNNBbox;
            Classification_Results(j).ReSVMBbox = RecallSVMBbox;

            Classification_Results(j).F1ANNBbox = F1scoreANNBbox;
            Classification_Results(j).F1KNNBbox = F1scoreKNNBbox;
            Classification_Results(j).F1SVMBbox = F1scoreSVMBbox;

            % Pixel wise
            Classification_Results(j).PrANNPix = PrecisionANNPix;
            Classification_Results(j).PrKNNPix = PrecisionKNNPix;
            Classification_Results(j).PrSVMPix = PrecisionSVMPix;

            Classification_Results(j).ReANNPix = RecallANNPix;
            Classification_Results(j).ReKNNPix = RecallKNNPix;
            Classification_Results(j).ReSVMPix = RecallSVMPix;

            Classification_Results(j).F1ANNPix = F1scoreANNPix;
            Classification_Results(j).F1KNNPix = F1scoreKNNPix;
            Classification_Results(j).F1SVMPix = F1scoreSVMPix;
            
            % Bounding box MATLAB
            Classification_Results(j).PrANNBbox_MLAB = PrecisionANNBbox_MLAB;
            Classification_Results(j).PrKNNBbox_MLAB = PrecisionKNNBbox_MLAB;
            Classification_Results(j).PrSVMBbox_MLAB = PrecisionSVMBbox_MLAB;

            Classification_Results(j).ReNNBbox_MLAB = RecallANNBbox_MLAB;
            Classification_Results(j).ReKNNBbox_MLAB = RecallKNNBbox_MLAB;
            Classification_Results(j).ReSVMBbox_MLAB = RecallSVMBbox_MLAB;

            Classification_Results(j).F1ANNBbox_MLAB = F1scoreANNBbox_MLAB;
            Classification_Results(j).F1KNNBbox_MLAB = F1scoreKNNBbox_MLAB;
            Classification_Results(j).F1SVMBbox_MLAB = F1scoreSVMBbox_MLAB;

            % Pixel wise MATLAB
            Classification_Results(j).PrANNPix_MLAB = PrecisionANNPix_MLAB;
            Classification_Results(j).PrKNNPix_MLAB = PrecisionKNNPix_MLAB;
            Classification_Results(j).PrSVMPix_MLAB = PrecisionSVMPix_MLAB;

            Classification_Results(j).ReANNPix_MLAB = RecallANNPix_MLAB;
            Classification_Results(j).ReKNNPix_MLAB = RecallKNNPix_MLAB;
            Classification_Results(j).ReSVMPix_MLAB = RecallSVMPix_MLAB;

            Classification_Results(j).F1ANNPix_MLAB = F1scoreANNPix_MLAB;
            Classification_Results(j).F1KNNPix_MLAB = F1scoreKNNPix_MLAB;
            Classification_Results(j).F1SVMPix_MLAB = F1scoreSVMPix_MLAB;

            Classification_Results(j).AccANNPix_MLAB = AccuracyANNPix_MLAB;
            Classification_Results(j).AccKNNPix_MLAB = AccuracyKNNPix_MLAB;
            Classification_Results(j).AccSVMPix_MLAB = AccuracySVMPix_MLAB;

            Classification_Results(j).SpecANNPix_MLAB = SpecificityANNPix_MLAB;
            Classification_Results(j).SpecKNNPix_MLAB = SpecificityKNNPix_MLAB;
            Classification_Results(j).SpecSVMPix_MLAB = SpecificitySVMPix_MLAB;

            Classification_Results(j).GlobalAccANNPix_MLAB = ssmMetrics_ANN.DataSetMetrics.GlobalAccuracy;
            Classification_Results(j).GlobalAccKNNPix_MLAB = ssmMetrics_KNN.DataSetMetrics.GlobalAccuracy;
            Classification_Results(j).GlobalAccSVMPix_MLAB = ssmMetrics_SVM.DataSetMetrics.GlobalAccuracy;

            Classification_Results(j).MeanAccuracyANNPix_MLAB = ssmMetrics_ANN.DataSetMetrics.MeanAccuracy;
            Classification_Results(j).MeanAccuracyKNNPix_MLAB = ssmMetrics_KNN.DataSetMetrics.MeanAccuracy;
            Classification_Results(j).MeanAccuracySVMPix_MLAB = ssmMetrics_SVM.DataSetMetrics.MeanAccuracy;

            Classification_Results(j).MeanIoUANNPix_MLAB = ssmMetrics_ANN.DataSetMetrics.MeanIoU;
            Classification_Results(j).MeanIoUKNNPix_MLAB = ssmMetrics_KNN.DataSetMetrics.MeanIoU;
            Classification_Results(j).MeanIoUSVMPix_MLAB = ssmMetrics_SVM.DataSetMetrics.MeanIoU;

            Classification_Results(j).WeightedIoUANNPix_MLAB = ssmMetrics_ANN.DataSetMetrics.WeightedIoU;
            Classification_Results(j).WeightedIoUKNNPix_MLAB = ssmMetrics_KNN.DataSetMetrics.WeightedIoU;
            Classification_Results(j).WeightedIoUSVMPix_MLAB = ssmMetrics_SVM.DataSetMetrics.WeightedIoU;

            Classification_Results(j).MeanBFScoreANNPix_MLAB = ssmMetrics_ANN.DataSetMetrics.MeanBFScore;
            Classification_Results(j).MeanBFScoreKNNPix_MLAB = ssmMetrics_KNN.DataSetMetrics.MeanBFScore;
            Classification_Results(j).MeanBFScoreSVMPix_MLAB = ssmMetrics_SVM.DataSetMetrics.MeanBFScore;

    end
end

%% Plot ROC curves
ROC_Curves_TestingDataset;

%% Save mat file of workspace variables
if(hybrid_inpstruct.save_mat_file || strcmp(hybrid_inpstruct.searchType,'grid_search'))
    % Variables to save
    matSaveStruct.Classification_Results         = Classification_Results;
    matSaveStruct.rocArrayBBox_MLAB              = rocArrayBBox_MLAB;
    matSaveStruct.rocArray_SSM                   = rocArray_SSM;
    matSaveStruct.rocArrayij_ImageClassification = rocArrayij_AllComponents;
    matSaveStruct.rocArrayij_ImageClassification = rocArrayij_ImageClassification;
    matSaveStruct.hybrid_FrangiITRnum = size(hybrid_Frangi_search_allPerms,1);
    matSaveStruct.hybrid_MFATITRnum   = size(hybrid_MFAT_search_allPerms,1);
    
    % MAT file name to save
    [filepath,name,ext] = fileparts(textFile);
    matFileName = [name '_' datestr(now,'yyyy_mm_dd_HH_MM_SS_FFF') '.mat'];
    save(fullfile(matFolder,matFileName),'-struct', 'matSaveStruct', '-v7.3')
end

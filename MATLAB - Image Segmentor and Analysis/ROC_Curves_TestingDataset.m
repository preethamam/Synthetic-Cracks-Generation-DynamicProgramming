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

%% Hybrid get maximum F1 score and plot for that image classification by
hybrid_FrangiITRnum = size(hybrid_Frangi_search_allPerms,1);
hybrid_MFATITRnum   = size(hybrid_MFAT_search_allPerms,1);
hybrid_sumITRnum = hybrid_FrangiITRnum + hybrid_MFATITRnum;

% Preetham's function
if ~(strcmp(hybrid_inpstruct.ImagesType,'crack_only'))
    AllF1ANNImgHess = cat(1,Classification_Results(1:hybrid_FrangiITRnum).F1ANNImg);
    AllF1KNNImgHess = cat(1,Classification_Results(1:hybrid_FrangiITRnum).F1KNNImg);
    AllF1SVMImgHess = cat(1,Classification_Results(1:hybrid_FrangiITRnum).F1SVMImg);

    F1sumPixHess = AllF1ANNImgHess + AllF1KNNImgHess + AllF1SVMImgHess;
    [maxNumHess, maxIndxImgHess] = max(F1sumPixHess);
    
    % Write best anisotropic Hessian to file
    hybridHess_itr_ImgClassification = cat(1,Classification_Results(1:hybrid_FrangiITRnum).Alg_iter);
    max_hybridHess_itr_ImgClassification = hybridHess_itr_ImgClassification(maxIndxImgHess,:);
    
    
    AllF1ANNImgMFAT = cat(1,Classification_Results(hybrid_FrangiITRnum+1 : hybrid_sumITRnum).F1ANNImg);
    AllF1KNNImgMFAT = cat(1,Classification_Results(hybrid_FrangiITRnum+1 : hybrid_sumITRnum).F1KNNImg);
    AllF1SVMImgMFAT = cat(1,Classification_Results(hybrid_FrangiITRnum+1 : hybrid_sumITRnum).F1SVMImg);

    F1sumMFAT = AllF1ANNImgMFAT + AllF1KNNImgMFAT + AllF1SVMImgMFAT;
    [maxNumMFAT, maxIndxImgMFAT] = max(F1sumMFAT + hybrid_FrangiITRnum);
    
    % Write best anisotropic Hessian to file
    hybridMFAT_itr_ImgClassification = cat(1,Classification_Results(hybrid_FrangiITRnum+1 : hybrid_sumITRnum).Alg_iter);
    max_hybridMFAT_itr_ImgClassification = hybridMFAT_itr_ImgClassification(maxIndxImgMFAT,:);
    
    % Hessian ROC image classification storage
    hybridHess_roc_ImgClassification = rocArrayij_ImageClassification{maxIndxImgHess};
    
    % Hessian ROC image classification storage
    hybridMFAT_roc_ImgClassification = rocArrayij_ImageClassification{maxIndxImgMFAT + hybrid_FrangiITRnum};
    
    % Morpho plot parameters
    morpho_roc_ImgClassification = rocArrayij_ImageClassification{end};

    % Print the best result for anisotropic iteration number
    fprintf(fileID,'---------------------------------------------------------------------------\n');
    fprintf(fileID,'Anisotropic Hessian with best results of Img by Preetham''s functions\n');
    fprintf(fileID,'Image classification\n');
    fprintf(fileID,'---------------------------------------------------------------------------\n');
    fprintf(fileID,'Anisotropic Hessian iteration 1: %i | Anisotropic MFAT iteration 1: %i \n', ...
        max_hybridHess_itr_ImgClassification(1), max_hybridMFAT_itr_ImgClassification(1));
    fprintf(fileID,'Anisotropic Hessian iteration 2: %i | Anisotropic MFAT iteration 1: %i \n', ...
        max_hybridHess_itr_ImgClassification(2), max_hybridMFAT_itr_ImgClassification(2));
    fprintf(fileID,'---------------------------------------------------------------------------\n');
end

%% Hybrid get maximum F1 score and plot for that bounding box method by
% Preetham's function All components
AllF1ANNBboxHess = cat(1,Classification_Results(1:hybrid_FrangiITRnum).F1ANNBbox);
AllF1KNNBboxHess = cat(1,Classification_Results(1:hybrid_FrangiITRnum).F1KNNBbox);
AllF1SVMBboxHess = cat(1,Classification_Results(1:hybrid_FrangiITRnum).F1SVMBbox);

F1sumPixHess = AllF1ANNBboxHess + AllF1KNNBboxHess + AllF1SVMBboxHess;
[maxNumHess, maxIndxBboxHess] = max(F1sumPixHess);

% Write best anisotropic Hessian to file
hybridHess_itr     = cat(1,Classification_Results(1:hybrid_FrangiITRnum).Alg_iter);
max_hybridHess_itr = hybridHess_itr(maxIndxBboxHess,:);

AllF1ANNBboxMFAT = cat(1,Classification_Results(hybrid_FrangiITRnum+1 : hybrid_sumITRnum).F1ANNBbox);
AllF1KNNBboxMFAT = cat(1,Classification_Results(hybrid_FrangiITRnum+1 : hybrid_sumITRnum).F1KNNBbox);
AllF1SVMBboxMFAT = cat(1,Classification_Results(hybrid_FrangiITRnum+1 : hybrid_sumITRnum).F1SVMBbox);

F1sumBboxMFAT = AllF1ANNBboxMFAT + AllF1KNNBboxMFAT + AllF1SVMBboxMFAT;
[maxNumMFAT, maxIndxBboxMFAT] = max(F1sumBboxMFAT);

% Write best anisotropic Hessian to file
hybridMFAT_itr_Bbox     = cat(1,Classification_Results(hybrid_FrangiITRnum+1 : hybrid_sumITRnum).Alg_iter);
max_hybridMFAT_itr_Bbox = hybridMFAT_itr_Bbox(maxIndxBboxMFAT,:);

% Hessian ROC ALL CC
hybridHess_roc = rocArrayij_AllComponents{maxIndxBboxHess};

% MFAT ROC ALL CC
hybridMFAT_roc = rocArrayij_AllComponents{maxIndxBboxMFAT + hybrid_FrangiITRnum};

% Morpho plot parameters
morpho_roc = rocArrayij_AllComponents{end};

% Print the best result for anisotropic iteration number
fprintf(fileID,'---------------------------------------------------------------------------\n');
fprintf(fileID,'Anisotropic Hessian with best results of BBox by Preetham''s functions All\n');
fprintf(fileID,'Components\n');
fprintf(fileID,'---------------------------------------------------------------------------\n');
fprintf(fileID,'Anisotropic Hessian iteration 1: %i | Anisotropic MFAT iteration 1: %i \n', ...
        max_hybridHess_itr(1), max_hybridMFAT_itr_Bbox(1));
    fprintf(fileID,'Anisotropic Hessian iteration 2: %i | Anisotropic MFAT iteration 2: %i \n', ...
        max_hybridHess_itr(2), max_hybridMFAT_itr_Bbox(2));
fprintf(fileID,'---------------------------------------------------------------------------\n');

%% Hybrid get maximum F1 score and plot for that bounding box method by
% MATLAB's default bounding box function ROC/PR curve
AllF1ANNBbox_MLABHess = cat(1,Classification_Results(1:hybrid_FrangiITRnum).F1ANNBbox_MLAB);
AllF1KNNBbox_MLABHess = cat(1,Classification_Results(1:hybrid_FrangiITRnum).F1KNNBbox_MLAB);
AllF1SVMBbox_MLABHess = cat(1,Classification_Results(1:hybrid_FrangiITRnum).F1SVMBbox_MLAB);

F1sumBbox_MLABHess = AllF1ANNBbox_MLABHess + AllF1KNNBbox_MLABHess + AllF1SVMBbox_MLABHess;
[maxNumHess, maxIndxBbox_MLABHess] = max(F1sumBbox_MLABHess);

% Write best anisotropic Hessian to file
hybridHess_itrBBox_MLAB     = cat(1,Classification_Results(1:end-1).Alg_iter);
max_hybridHess_itrBBox_MLAB = hybridHess_itrBBox_MLAB(maxIndxBbox_MLABHess,:);

AllF1ANNBbox_MLABMFAT = cat(1,Classification_Results(hybrid_FrangiITRnum+1 : hybrid_sumITRnum).F1ANNBbox_MLAB);
AllF1KNNBbox_MLABMFAT = cat(1,Classification_Results(hybrid_FrangiITRnum+1 : hybrid_sumITRnum).F1KNNBbox_MLAB);
AllF1SVMBbox_MLABMFAT = cat(1,Classification_Results(hybrid_FrangiITRnum+1 : hybrid_sumITRnum).F1SVMBbox_MLAB);

F1sumBbox_MLABMFAT = AllF1ANNBbox_MLABMFAT + AllF1KNNBbox_MLABMFAT + AllF1SVMBbox_MLABMFAT;
[maxNumMFAT, maxIndxBbox_MLABMFAT] = max(F1sumBbox_MLABMFAT + hybrid_FrangiITRnum);

% Write best anisotropic Hessian to file
hybridMFAT_itr_Bbox_MLAB     = cat(1,Classification_Results(hybrid_FrangiITRnum+1 : hybrid_sumITRnum).Alg_iter);
max_hybridMFAT_itr_Bbox_MLAB = hybridMFAT_itr_Bbox_MLAB(maxIndxBbox_MLABMFAT,:);

% Hessian storage
hybridHess_rocBBox_MLAB = rocArrayBBox_MLAB{maxIndxBbox_MLABHess};

% MFAT storage
hybridMFAT_rocBBox_MLAB = rocArrayBBox_MLAB{maxIndxBbox_MLABMFAT + hybrid_FrangiITRnum};

% Morpho plot parameters
morpho_rocBBox_MLAB = rocArrayBBox_MLAB{end};

% Print the best result for anisotropic iteration number
fprintf(fileID,'---------------------------------------------------------------------------\n');
fprintf(fileID,'Anisotropic Hessian with best results of BBox by MATLAB''s functions \n');
fprintf(fileID,'---------------------------------------------------------------------------\n');
fprintf(fileID,'Anisotropic Hessian iteration 1: %i | Anisotropic MFAT iteration 1: %i \n', ...
        max_hybridHess_itrBBox_MLAB(1), max_hybridMFAT_itr_Bbox_MLAB(1));
    fprintf(fileID,'Anisotropic Hessian iteration 2: %i | Anisotropic MFAT iteration 2: %i \n', ...
        max_hybridHess_itrBBox_MLAB(2), max_hybridMFAT_itr_Bbox_MLAB(2));
fprintf(fileID,'---------------------------------------------------------------------------\n');

%% Semantic segmentation function ROC/PR curve
% Preetham's function
AllF1ANNSSMHess = cat(1,Classification_Results(1:hybrid_FrangiITRnum).F1ANNPix_MLAB);
AllF1KNNSSMHess = cat(1,Classification_Results(1:hybrid_FrangiITRnum).F1KNNPix_MLAB);
AllF1SVMSSMHess = cat(1,Classification_Results(1:hybrid_FrangiITRnum).F1SVMPix_MLAB);

F1sumPixHess = AllF1ANNSSMHess + AllF1KNNSSMHess + AllF1SVMSSMHess;
[maxNumHess, maxIndxSSMHess] = max(F1sumPixHess);

% Write best anisotropic Hessian to file
hybridHess_itr_SSM     = cat(1,Classification_Results(1:end-1).Alg_iter);
max_hybridHess_itr_SSM = hybridHess_itr_SSM(maxIndxSSMHess,:);

AllF1ANNSSMMFAT = cat(1,Classification_Results(hybrid_FrangiITRnum+1 : hybrid_sumITRnum).F1ANNPix_MLAB);
AllF1KNNSSMMFAT = cat(1,Classification_Results(hybrid_FrangiITRnum+1 : hybrid_sumITRnum).F1KNNPix_MLAB);
AllF1SVMSSMMFAT = cat(1,Classification_Results(hybrid_FrangiITRnum+1 : hybrid_sumITRnum).F1SVMPix_MLAB);

F1sumSSMMFAT = AllF1ANNSSMMFAT + AllF1KNNSSMMFAT + AllF1SVMSSMMFAT;
[maxNumMFAT, maxIndxSSMMFAT] = max(F1sumSSMMFAT);

% Write best anisotropic Hessian to file
hybridMFAT_itr_SSM     = cat(1,Classification_Results(hybrid_FrangiITRnum+1 : hybrid_sumITRnum).Alg_iter);
max_hybridMFAT_itr_SSM = hybridMFAT_itr_SSM(maxIndxSSMMFAT,:);

% Hybrid Hessian storage
hybridHess_roc_SSM = rocArray_SSM{maxIndxSSMHess};

% Hybrid Hessian storage
hybridMFAT_roc_SSM = rocArray_SSM{maxIndxSSMHess + hybrid_FrangiITRnum};

% Morpho plot parameters
morpho_roc_SSM = rocArray_SSM{end};

% Print the best result for anisotropic iteration number
fprintf(fileID,'---------------------------------------------------------------------------\n');
fprintf(fileID,'Anisotropic Hessian with best results of Img by Preetham''s functions\n');
fprintf(fileID,'Semantic segmentation\n');
fprintf(fileID,'---------------------------------------------------------------------------\n');
fprintf(fileID,'Anisotropic Hessian iteration 1: %i | Anisotropic MFAT iteration 1: %i \n', ...
        max_hybridHess_itr_SSM(1), max_hybridMFAT_itr_SSM(1));
    fprintf(fileID,'Anisotropic Hessian iteration 2: %i | Anisotropic MFAT iteration 2: %i \n', ...
        max_hybridHess_itr_SSM(2), max_hybridMFAT_itr_SSM(2));
fprintf(fileID,'---------------------------------------------------------------------------\n');

%% Plot ROC curves
f1 = [];
if (strcmp(hybrid_inpstruct.figShow_ROCCurves,'yes'))
    f1 = figure(5);
    set(f1,'Name','ROC Curves','NumberTitle','on')
    switch hybrid_inpstruct.ROC_TYPE
        case 'pre_recall'
            switch hybrid_inpstruct.TRAIN_TEST
                case 'training'
                    disp('Not Valid!');
                case 'testing'
                    switch hybrid_inpstruct.PR_ROC_CURVE_METHOD
                        
                        case 'IMAGE_CLASSIFICATION'
                            hold on
                            % ANN
                            plot(hybridHess_roc_ImgClassification{1},hybridHess_roc_ImgClassification{4}, '-.r', 'LineWidth',2, 'MarkerSize',5)
                            plot(hybridMFAT_roc_ImgClassification{1},hybridMFAT_roc_ImgClassification{4}, '-sr', 'LineWidth',2, 'MarkerSize',5)
                            plot(morpho_roc_ImgClassification{1},morpho_roc_ImgClassification{4}, '-^r', 'LineWidth',2, 'MarkerSize',5)

                            % KNN
                            plot(hybridHess_roc_ImgClassification{2},hybridHess_roc_ImgClassification{5}, '--g', 'LineWidth',2, 'MarkerSize',5)
                            plot(hybridMFAT_roc_ImgClassification{2},hybridMFAT_roc_ImgClassification{5}, '-sg', 'LineWidth',2, 'MarkerSize',5)
                            plot(morpho_roc_ImgClassification{2},morpho_roc_ImgClassification{5}, '--dg', 'LineWidth',2, 'MarkerSize',5)

                            % SVM
                            plot(hybridHess_roc_ImgClassification{3},hybridHess_roc_ImgClassification{6}, '-xb', 'LineWidth',2, 'MarkerSize',5)
                            plot(hybridMFAT_roc_ImgClassification{3},hybridMFAT_roc_ImgClassification{6}, '-sb', 'LineWidth',2, 'MarkerSize',5)
                            plot(morpho_roc_ImgClassification{3},morpho_roc_ImgClassification{6}, '-ob', 'LineWidth',2, 'MarkerSize',5)
                            hold off
                            grid on
                            xlabel('Recall'); ylabel('Precision')
                            legend (['ANN-hybridH' ' | ' 'AUC = ' num2str(hybridHess_roc_ImgClassification{10}, '%.4f')], ...
                                    ['ANN-hybridM' ' | ' 'AUC = ' num2str(hybridMFAT_roc_ImgClassification{10}, '%.4f')], ...
                                    ['ANN-morpho'  ' | ' 'AUC = ' num2str(morpho_roc_ImgClassification{10}, '%.4f')], ...
                                    ['KNN-hybridH' ' | ' 'AUC = ' num2str(hybridHess_roc_ImgClassification{11}, '%.4f')], ...
                                    ['KNN-hybridM' ' | ' 'AUC = ' num2str(hybridMFAT_roc_ImgClassification{11}, '%.4f')], ...
                                    ['KNN-morpho'  ' | ' 'AUC = ' num2str(morpho_roc_ImgClassification{11}, '%.4f')], ...
                                    ['SVM-hybridH' ' | ' 'AUC = ' num2str(hybridHess_roc_ImgClassification{12}, '%.4f')], ...
                                    ['SVM-hybridM' ' | ' 'AUC = ' num2str(hybridMFAT_roc_ImgClassification{12}, '%.4f')], ...
                                    ['SVM-morpho'  ' | ' 'AUC = ' num2str(morpho_roc_ImgClassification{12}, '%.4f')])
                            if(hybrid_inpstruct.show_ROC_curve_title)
                                title({'ANN vs. SVM vs. K-NN Testing Precision-recall curve (Img. Classification)'; ...
                                      ['AUC ANN-h1/h2/m: ' num2str(hybridHess_roc_ImgClassification{10}) '/' num2str(hybridMFAT_roc_ImgClassification{10}) '/' num2str(morpho_roc_ImgClassification{10}) ' | ' ...
                                       'AUC KNN-h1/h2/m: ' num2str(hybridHess_roc_ImgClassification{11}) '/' num2str(hybridMFAT_roc_ImgClassification{11}) '/' num2str(morpho_roc_ImgClassification{11}) ' | ' ...
                                       'AUC SVM-h1/h2/m: ' num2str(hybridHess_roc_ImgClassification{12}) '/' num2str(hybridMFAT_roc_ImgClassification{12}) '/' num2str(morpho_roc_ImgClassification{12})]})
                            end
                        case 'ALL_IMAGE_CONNECTED_COMPONENTS'
                            hold on
                            % ANN
                            plot(hybridHess_roc{1},hybridHess_roc{4}, '-.r', 'LineWidth',2, 'MarkerSize',5)
                            plot(hybridMFAT_roc{1},hybridMFAT_roc{4}, '-sr', 'LineWidth',2, 'MarkerSize',5)
                            plot(morpho_roc{1},morpho_roc{4}, '-^r', 'LineWidth',2, 'MarkerSize',5)

                            % KNN
                            plot(hybridHess_roc{2},hybridHess_roc{5}, '--g', 'LineWidth',2, 'MarkerSize',5)
                            plot(hybridMFAT_roc{2},hybridMFAT_roc{5}, '-sg', 'LineWidth',2, 'MarkerSize',5)
                            plot(morpho_roc{2},morpho_roc{5}, '--dg', 'LineWidth',2, 'MarkerSize',5)

                            % SVM
                            plot(hybridHess_roc{3},hybridHess_roc{6}, '-xb', 'LineWidth',2, 'MarkerSize',5)
                            plot(hybridMFAT_roc{3},hybridMFAT_roc{6}, '-sb', 'LineWidth',2, 'MarkerSize',5)
                            plot(morpho_roc{3},morpho_roc{6}, '-ob', 'LineWidth',2, 'MarkerSize',5)
                            hold off
                            grid on
                            xlabel('Recall'); ylabel('Precision')
                            legend (['ANN-hybridH' ' | ' 'AUC = ' num2str(hybridHess_roc{10}, '%.4f')], ...
                                    ['ANN-hybridM' ' | ' 'AUC = ' num2str(hybridMFAT_roc{10}, '%.4f')], ...
                                    ['ANN-morpho' ' | ' 'AUC = ' num2str(morpho_roc{10}, '%.4f')], ...
                                    ['KNN-hybridH' ' | ' 'AUC = ' num2str(hybridHess_roc{11}, '%.4f')], ...
                                    ['KNN-hybridM' ' | ' 'AUC = ' num2str(hybridMFAT_roc{11}, '%.4f')], ...
                                    ['KNN-morpho' ' | ' 'AUC = ' num2str(morpho_roc{11}, '%.4f')], ...
                                    ['SVM-hybridH' ' | ' 'AUC = ' num2str(hybridHess_roc{12}, '%.4f')], ...
                                    ['SVM-hybridH' ' | ' 'AUC = ' num2str(hybridMFAT_roc{12}, '%.4f')], ...
                                    ['SVM-morpho' ' | ' 'AUC = ' num2str(morpho_roc{12}, '%.4f')])
                            if(hybrid_inpstruct.show_ROC_curve_title)
                                title({'ANN vs. SVM vs. K-NN Testing Precision-recall curve (ALL CC)'; ...
                                      ['AUC ANN-h1/h2/m: ' num2str(hybridHess_roc{10}) '/' num2str(hybridMFAT_roc{10}) '/' num2str(morpho_roc{10}) ' | ' ...
                                       'AUC KNN-h1/h2/m: ' num2str(hybridHess_roc{11}) '/' num2str(hybridMFAT_roc{11}) '/' num2str(morpho_roc{11}) ' | ' ...
                                       'AUC SVM-h1/h2/m: ' num2str(hybridHess_roc{12}) '/' num2str(hybridMFAT_roc{12}) '/' num2str(morpho_roc{12})]})
                            end
                        case 'MATLAB_BBox'
                            switch hybrid_inpstruct.ImagesType
                                case 'crack_only'
                                    hold on
                                    % ANN
                                    plot(hybridHess_rocBBox_MLAB{1},hybridHess_rocBBox_MLAB{4}, '-.r', 'LineWidth',2, 'MarkerSize',5)
                                    plot(hybridMFAT_rocBBox_MLAB{1},hybridMFAT_rocBBox_MLAB{4}, '-sr', 'LineWidth',2, 'MarkerSize',5)
                                    plot(morpho_rocBBox_MLAB{1},morpho_rocBBox_MLAB{4}, '-^r', 'LineWidth',2, 'MarkerSize',5)

                                    % KNN
                                    plot(hybridHess_rocBBox_MLAB{2},hybridHess_rocBBox_MLAB{5}, '--g', 'LineWidth',2, 'MarkerSize',5)
                                    plot(hybridMFAT_rocBBox_MLAB{2},hybridMFAT_rocBBox_MLAB{5}, '-sg', 'LineWidth',2, 'MarkerSize',5)
                                    plot(morpho_rocBBox_MLAB{2},morpho_rocBBox_MLAB{5}, '--dg', 'LineWidth',2, 'MarkerSize',5)

                                    % SVM
                                    plot(hybridHess_rocBBox_MLAB{3},hybridHess_rocBBox_MLAB{6}, '-xb', 'LineWidth',2, 'MarkerSize',5)
                                    plot(hybridMFAT_rocBBox_MLAB{3},hybridMFAT_rocBBox_MLAB{6}, '-sb', 'LineWidth',2, 'MarkerSize',5)
                                    plot(morpho_rocBBox_MLAB{3},morpho_rocBBox_MLAB{6}, '-ob', 'LineWidth',2, 'MarkerSize',5)
                                    hold off
                                    grid on
                                    xlabel('Recall'); ylabel('Precision')
                                    legend (['ANN-hybridH' ' | ' 'AP = ' num2str(hybridHess_rocBBox_MLAB{7}, '%.4f')], ...
                                            ['ANN-hybridM' ' | ' 'AP = ' num2str(hybridMFAT_rocBBox_MLAB{7}, '%.4f')], ...
                                            ['ANN-morpho' ' | ' 'AP = ' num2str(morpho_rocBBox_MLAB{7}, '%.4f')], ...
                                            ['KNN-hybridH' ' | ' 'AP = ' num2str(hybridHess_rocBBox_MLAB{8}, '%.4f')], ...
                                            ['KNN-hybridM' ' | ' 'AP = ' num2str(hybridMFAT_rocBBox_MLAB{8}, '%.4f')], ...
                                            ['KNN-morpho' ' | ' 'AP = ' num2str(morpho_rocBBox_MLAB{8}, '%.4f')], ...
                                            ['SVM-hybridH' ' | ' 'AP = ' num2str(hybridHess_rocBBox_MLAB{9}, '%.4f')], ...
                                            ['SVM-hybridM' ' | ' 'AP = ' num2str(hybridMFAT_rocBBox_MLAB{9}, '%.4f')], ...
                                            ['SVM-morpho' ' | ' 'AP = ' num2str(morpho_rocBBox_MLAB{9}, '%.4f')])
                                    if(hybrid_inpstruct.show_ROC_curve_title)
                                        title({'ANN vs. SVM vs. K-NN Testing Precision-recall curve (MATLAB BBox)'; ...
                                              ['AP ANN-h1/h2/m: ' num2str(hybridHess_rocBBox_MLAB{7}) '/' num2str(hybridMFAT_rocBBox_MLAB{7}) '/' num2str(morpho_rocBBox_MLAB{7}) ' | ' ...
                                               'AP KNN-h1/h2/m: ' num2str(hybridHess_rocBBox_MLAB{8}) '/' num2str(hybridMFAT_rocBBox_MLAB{8}) '/' num2str(morpho_rocBBox_MLAB{8}) ' | ' ...
                                               'AP SVM-h1/h2/m: ' num2str(hybridHess_rocBBox_MLAB{9}) '/' num2str(hybridMFAT_rocBBox_MLAB{9}) '/' num2str(morpho_rocBBox_MLAB{9})]})
                                    end
                                case 'crackANDnoncracks'
                                    hold on
                                    % ANN
                                    plot(hybridHess_rocBBox_MLAB{1}{1},hybridHess_rocBBox_MLAB{4}{1}, '-.r', 'LineWidth',2, 'MarkerSize',5)
                                    plot(hybridMFAT_rocBBox_MLAB{1}{1},hybridMFAT_rocBBox_MLAB{4}{1}, '-sr', 'LineWidth',2, 'MarkerSize',5)
                                    plot(morpho_rocBBox_MLAB{1}{1},morpho_rocBBox_MLAB{4}{1}, '-^r', 'LineWidth',2, 'MarkerSize',5)

                                    % KNN
                                    plot(hybridHess_rocBBox_MLAB{2}{1},hybridHess_rocBBox_MLAB{5}{1}, '--g', 'LineWidth',2, 'MarkerSize',5)
                                    plot(hybridMFAT_rocBBox_MLAB{2}{1},hybridMFAT_rocBBox_MLAB{5}{1}, '-sg', 'LineWidth',2, 'MarkerSize',5)
                                    plot(morpho_rocBBox_MLAB{2}{1},morpho_rocBBox_MLAB{5}{1}, '--dg', 'LineWidth',2, 'MarkerSize',5)

                                    % SVM
                                    plot(hybridHess_rocBBox_MLAB{3}{1},hybridHess_rocBBox_MLAB{6}{1}, '-xb', 'LineWidth',2, 'MarkerSize',5)
                                    plot(hybridMFAT_rocBBox_MLAB{3}{1},hybridMFAT_rocBBox_MLAB{6}{1}, '-sb', 'LineWidth',2, 'MarkerSize',5)
                                    plot(morpho_rocBBox_MLAB{3}{1},morpho_rocBBox_MLAB{6}{1}, '-ob', 'LineWidth',2, 'MarkerSize',5)
                                    hold off
                                    grid on
                                    xlabel('Recall'); ylabel('Precision')
                                    legend (['ANN-hybridH' ' | ' 'AP = ' num2str(hybridHess_rocBBox_MLAB{7}(1), '%.4f')], ...
                                            ['ANN-hybridM' ' | ' 'AP = ' num2str(hybridMFAT_rocBBox_MLAB{7}(1), '%.4f')], ...
                                            ['ANN-morpho' ' | ' 'AP = ' num2str(morpho_rocBBox_MLAB{7}(1), '%.4f')], ...
                                            ['KNN-hybridH' ' | ' 'AP = ' num2str(hybridHess_rocBBox_MLAB{8}(1), '%.4f')], ...
                                            ['KNN-hybridM' ' | ' 'AP = ' num2str(hybridMFAT_rocBBox_MLAB{8}(1), '%.4f')], ...
                                            ['KNN-morpho' ' | ' 'AP = ' num2str(morpho_rocBBox_MLAB{8}(1), '%.4f')], ...
                                            ['SVM-hybridH' ' | ' 'AP = ' num2str(hybridHess_rocBBox_MLAB{9}(1), '%.4f')], ...
                                            ['SVM-hybridM' ' | ' 'AP = ' num2str(hybridMFAT_rocBBox_MLAB{9}(1), '%.4f')], ...
                                            ['SVM-morpho' ' | ' 'AP = ' num2str(morpho_rocBBox_MLAB{9}(1), '%.4f')])
                                    if(hybrid_inpstruct.show_ROC_curve_title)
                                        title({'ANN vs. SVM vs. K-NN Testing Precision-recall curve (MATLAB BBox)'; ...
                                              ['AP ANN-h1/h2/m: ' num2str(hybridHess_rocBBox_MLAB{7}(1)) '/' num2str(hybridMFAT_rocBBox_MLAB{7}(1)) '/' num2str(morpho_rocBBox_MLAB{7}(1)) ' | ' ...
                                               'AP KNN-h1/h2/m: ' num2str(hybridHess_rocBBox_MLAB{8}(1)) '/' num2str(hybridMFAT_rocBBox_MLAB{8}(1)) '/' num2str(morpho_rocBBox_MLAB{8}(1)) ' | ' ...
                                               'AP SVM-h1/h2/m: ' num2str(hybridHess_rocBBox_MLAB{9}(1)) '/' num2str(hybridMFAT_rocBBox_MLAB{9}(1)) '/' num2str(morpho_rocBBox_MLAB{9}(1))]})
                                    end
                            end

                            
                            
                        case 'SEMANTIC_SEG'
                            hold on
                            % ANN
                            plot(hybridHess_roc_SSM{1},hybridHess_roc_SSM{4}, '-.r', 'LineWidth',2, 'MarkerSize',5)
                            plot(hybridMFAT_roc_SSM{1},hybridMFAT_roc_SSM{4}, '-sr', 'LineWidth',2, 'MarkerSize',5)
                            plot(morpho_roc_SSM{1},morpho_roc_SSM{4}, '-^r', 'LineWidth',2, 'MarkerSize',5)

                            % KNN
                            plot(hybridHess_roc_SSM{2},hybridHess_roc_SSM{5}, '--g', 'LineWidth',2, 'MarkerSize',5)
                            plot(hybridMFAT_roc_SSM{2},hybridMFAT_roc_SSM{5}, '-sg', 'LineWidth',2, 'MarkerSize',5)
                            plot(morpho_roc_SSM{2},morpho_roc_SSM{5}, '--dg', 'LineWidth',2, 'MarkerSize',5)

                            % SVM
                            plot(hybridHess_roc_SSM{3},hybridHess_roc_SSM{6}, '-xb', 'LineWidth',2, 'MarkerSize',5)
                            plot(hybridMFAT_roc_SSM{3},hybridMFAT_roc_SSM{6}, '-sb', 'LineWidth',2, 'MarkerSize',5)
                            plot(morpho_roc_SSM{3},morpho_roc_SSM{6}, '-ob', 'LineWidth',2, 'MarkerSize',5)
                            hold off
                            grid on
                            xlabel('Recall'); ylabel('Precision')
                            legend (['ANN-hybridH' ' | ' 'AUC = ' num2str(hybridHess_roc_SSM{10}, '%.4f')], ...
                                    ['ANN-hybridM' ' | ' 'AUC = ' num2str(hybridMFAT_roc_SSM{10}, '%.4f')], ...
                                    ['ANN-morpho' ' | ' 'AUC = ' num2str(morpho_roc_SSM{10}, '%.4f')], ...
                                    ['KNN-hybridH' ' | ' 'AUC = ' num2str(hybridHess_roc_SSM{11}, '%.4f')], ...
                                    ['KNN-hybridM' ' | ' 'AUC = ' num2str(hybridMFAT_roc_SSM{11}, '%.4f')], ...
                                    ['KNN-morpho' ' | ' 'AUC = ' num2str(morpho_roc_SSM{11}, '%.4f')], ...
                                    ['SVM-hybridH' ' | ' 'AUC = ' num2str(hybridHess_roc_SSM{12}, '%.4f')], ...
                                    ['SVM-hybridM' ' | ' 'AUC = ' num2str(hybridMFAT_roc_SSM{12}, '%.4f')], ...
                                    ['SVM-morpho' ' | ' 'AUC = ' num2str(morpho_roc_SSM{12}, '%.4f')])
                            if(hybrid_inpstruct.show_ROC_curve_title)
                                title({'ANN vs. SVM vs. K-NN Testing Precision-recall curve (Semantic segmentation)'; ...
                                      ['AUC ANN-h1/h2/m: ' num2str(hybridHess_roc_SSM{10}) '/' num2str(hybridMFAT_roc_SSM{10}) '/' num2str(morpho_roc_SSM{10}) ' | ' ...
                                       'AUC KNN-h1/h2/m: ' num2str(hybridHess_roc_SSM{11}) '/' num2str(hybridMFAT_roc_SSM{11}) '/' num2str(morpho_roc_SSM{11}) ' | ' ...
                                       'AUC SVM-h1/h2/m: ' num2str(hybridHess_roc_SSM{12}) '/' num2str(hybridMFAT_roc_SSM{12}) '/' num2str(morpho_roc_SSM{12})]})
                            end
                    end
            end

        case 'true_false'
            switch hybrid_inpstruct.TRAIN_TEST
                case 'training'
                    disp('Not Valid!');
                case 'testing'
                    switch hybrid_inpstruct.PR_ROC_CURVE_METHOD
                        case 'IMAGE_CLASSIFICATION'
                            hold on
                            % ANN
                            plot(hybridHess_roc_ImgClassification{1},hybridHess_roc_ImgClassification{4}, '-.r', 'LineWidth',2, 'MarkerSize',5)
                            plot(hybridMFAT_roc_ImgClassification{1},hybridMFAT_roc_ImgClassification{4}, '-sr', 'LineWidth',2, 'MarkerSize',5)
                            plot(morpho_roc_ImgClassification{1},morpho_roc_ImgClassification{4}, '-^r', 'LineWidth',2, 'MarkerSize',5)

                            % KNN
                            plot(hybridHess_roc_ImgClassification{2},hybridHess_roc_ImgClassification{5}, '--g', 'LineWidth',2, 'MarkerSize',5)
                            plot(hybridMFAT_roc_ImgClassification{2},hybridMFAT_roc_ImgClassification{5}, '-sg', 'LineWidth',2, 'MarkerSize',5)
                            plot(morpho_roc_ImgClassification{2},morpho_roc_ImgClassification{5}, '--dg', 'LineWidth',2, 'MarkerSize',5)

                            % SVM
                            plot(hybridHess_roc_ImgClassification{3},hybridHess_roc_ImgClassification{6}, '-xb', 'LineWidth',2, 'MarkerSize',5)
                            plot(hybridMFAT_roc_ImgClassification{3},hybridMFAT_roc_ImgClassification{6}, '-sb', 'LineWidth',2, 'MarkerSize',5)
                            plot(morpho_roc_ImgClassification{3},morpho_roc_ImgClassification{6}, '-ob', 'LineWidth',2, 'MarkerSize',5)
                            hold off
                            grid on
                            xlabel('False Positive Rate'); ylabel('True Positive Rate')
                            legend (['ANN-hybridH' ' | ' 'AUC = ' num2str(hybridHess_roc_ImgClassification{10}, '%.4f')], ...
                                    ['ANN-hybridM' ' | ' 'AUC = ' num2str(hybridMFAT_roc_ImgClassification{10}, '%.4f')], ...
                                    ['ANN-morpho'  ' | ' 'AUC = ' num2str(morpho_roc_ImgClassification{10}, '%.4f')], ...
                                    ['KNN-hybridH' ' | ' 'AUC = ' num2str(hybridHess_roc_ImgClassification{11}, '%.4f')], ...
                                    ['KNN-hybridM' ' | ' 'AUC = ' num2str(hybridMFAT_roc_ImgClassification{11}, '%.4f')], ...
                                    ['KNN-morpho'  ' | ' 'AUC = ' num2str(morpho_roc_ImgClassification{11}, '%.4f')], ...
                                    ['SVM-hybridH' ' | ' 'AUC = ' num2str(hybridHess_roc_ImgClassification{12}, '%.4f')], ...
                                    ['SVM-hybridM' ' | ' 'AUC = ' num2str(hybridMFAT_roc_ImgClassification{12}, '%.4f')], ...
                                    ['SVM-morpho'  ' | ' 'AUC = ' num2str(morpho_roc_ImgClassification{12}, '%.4f')])
                            if(hybrid_inpstruct.show_ROC_curve_title)
                                title({'ANN vs. SVM vs. K-NN Testing Precision-recall curve (Img. Classification)'; ...
                                      ['AUC ANN-h1/h2/m: ' num2str(hybridHess_roc_ImgClassification{10}) '/' num2str(hybridMFAT_roc_ImgClassification{10}) '/' num2str(morpho_roc_ImgClassification{10}) ' | ' ...
                                       'AUC KNN-h1/h2/m: ' num2str(hybridHess_roc_ImgClassification{11}) '/' num2str(hybridMFAT_roc_ImgClassification{11}) '/' num2str(morpho_roc_ImgClassification{11}) ' | ' ...
                                       'AUC SVM-h1/h2/m: ' num2str(hybridHess_roc_ImgClassification{12}) '/' num2str(hybridMFAT_roc_ImgClassification{12}) '/' num2str(morpho_roc_ImgClassification{12})]})
                            end
                        case 'ALL_IMAGE_CONNECTED_COMPONENTS'
                            hold on
                            % ANN
                            plot(hybridHess_roc{1},hybridHess_roc{4}, '-.r', 'LineWidth',2, 'MarkerSize',5)
                            plot(hybridMFAT_roc{1},hybridMFAT_roc{4}, '-sr', 'LineWidth',2, 'MarkerSize',5)
                            plot(morpho_roc{1},morpho_roc{4}, '-^r', 'LineWidth',2, 'MarkerSize',5)

                            % KNN
                            plot(hybridHess_roc{2},hybridHess_roc{5}, '--g', 'LineWidth',2, 'MarkerSize',5)
                            plot(hybridMFAT_roc{2},hybridMFAT_roc{5}, '-sg', 'LineWidth',2, 'MarkerSize',5)
                            plot(morpho_roc{2},morpho_roc{5}, '--dg', 'LineWidth',2, 'MarkerSize',5)

                            % SVM
                            plot(hybridHess_roc{3},hybridHess_roc{6}, '-xb', 'LineWidth',2, 'MarkerSize',5)
                            plot(hybridMFAT_roc{3},hybridMFAT_roc{6}, '-sb', 'LineWidth',2, 'MarkerSize',5)
                            plot(morpho_roc{3},morpho_roc{6}, '-ob', 'LineWidth',2, 'MarkerSize',5)
                            hold off
                            grid on
                            xlabel('False Positive Rate'); ylabel('True Positive Rate')
                            legend (['ANN-hybridH' ' | ' 'AUC = ' num2str(hybridHess_roc{10}, '%.4f')], ...
                                    ['ANN-hybridM' ' | ' 'AUC = ' num2str(hybridMFAT_roc{10}, '%.4f')], ...
                                    ['ANN-morpho' ' | ' 'AUC = ' num2str(morpho_roc{10}, '%.4f')], ...
                                    ['KNN-hybridH' ' | ' 'AUC = ' num2str(hybridHess_roc{11}, '%.4f')], ...
                                    ['KNN-hybridM' ' | ' 'AUC = ' num2str(hybridMFAT_roc{11}, '%.4f')], ...
                                    ['KNN-morpho' ' | ' 'AUC = ' num2str(morpho_roc{11}, '%.4f')], ...
                                    ['SVM-hybridH' ' | ' 'AUC = ' num2str(hybridHess_roc{12}, '%.4f')], ...
                                    ['SVM-hybridH' ' | ' 'AUC = ' num2str(hybridMFAT_roc{12}, '%.4f')], ...
                                    ['SVM-morpho' ' | ' 'AUC = ' num2str(morpho_roc{12}, '%.4f')])
                            if(hybrid_inpstruct.show_ROC_curve_title)
                                title({'ANN vs. SVM vs. K-NN Testing Precision-recall curve (ALL CC)'; ...
                                      ['AUC ANN-h1/h2/m: ' num2str(hybridHess_roc{10}) '/' num2str(hybridMFAT_roc{10}) '/' num2str(morpho_roc{10}) ' | ' ...
                                       'AUC KNN-h1/h2/m: ' num2str(hybridHess_roc{11}) '/' num2str(hybridMFAT_roc{11}) '/' num2str(morpho_roc{11}) ' | ' ...
                                       'AUC SVM-h1/h2/m: ' num2str(hybridHess_roc{12}) '/' num2str(hybridMFAT_roc{12}) '/' num2str(morpho_roc{12})]})
                            end
                        case 'MATLAB_BBox'
                            hold on
                            
                            
                        case 'SEMANTIC_SEG'
                            hold on
                            % ANN
                            plot(hybridHess_roc_SSM{1},hybridHess_roc_SSM{4}, '-.r', 'LineWidth',2, 'MarkerSize',5)
                            plot(hybridMFAT_roc_SSM{1},hybridMFAT_roc_SSM{4}, '-sr', 'LineWidth',2, 'MarkerSize',5)
                            plot(morpho_roc_SSM{1},morpho_roc_SSM{4}, '-^r', 'LineWidth',2, 'MarkerSize',5)

                            % KNN
                            plot(hybridHess_roc_SSM{2},hybridHess_roc_SSM{5}, '--g', 'LineWidth',2, 'MarkerSize',5)
                            plot(hybridMFAT_roc_SSM{2},hybridMFAT_roc_SSM{5}, '-sg', 'LineWidth',2, 'MarkerSize',5)
                            plot(morpho_roc_SSM{2},morpho_roc_SSM{5}, '--dg', 'LineWidth',2, 'MarkerSize',5)

                            % SVM
                            plot(hybridHess_roc_SSM{3},hybridHess_roc_SSM{6}, '-xb', 'LineWidth',2, 'MarkerSize',5)
                            plot(hybridMFAT_roc_SSM{3},hybridMFAT_roc_SSM{6}, '-sb', 'LineWidth',2, 'MarkerSize',5)
                            plot(morpho_roc_SSM{3},morpho_roc_SSM{6}, '-ob', 'LineWidth',2, 'MarkerSize',5)
                            hold off
                            grid on
                            xlabel('False Positive Rate'); ylabel('True Positive Rate')
                            legend (['ANN-hybridH' ' | ' 'AUC = ' num2str(hybridHess_roc_SSM{10}, '%.4f')], ...
                                    ['ANN-hybridM' ' | ' 'AUC = ' num2str(hybridMFAT_roc_SSM{10}, '%.4f')], ...
                                    ['ANN-morpho' ' | ' 'AUC = ' num2str(morpho_roc_SSM{10}, '%.4f')], ...
                                    ['KNN-hybridH' ' | ' 'AUC = ' num2str(hybridHess_roc_SSM{11}, '%.4f')], ...
                                    ['KNN-hybridM' ' | ' 'AUC = ' num2str(hybridMFAT_roc_SSM{11}, '%.4f')], ...
                                    ['KNN-morpho' ' | ' 'AUC = ' num2str(morpho_roc_SSM{11}, '%.4f')], ...
                                    ['SVM-hybridH' ' | ' 'AUC = ' num2str(hybridHess_roc_SSM{12}, '%.4f')], ...
                                    ['SVM-hybridM' ' | ' 'AUC = ' num2str(hybridMFAT_roc_SSM{12}, '%.4f')], ...
                                    ['SVM-morpho' ' | ' 'AUC = ' num2str(morpho_roc_SSM{12}, '%.4f')])
                            if(hybrid_inpstruct.show_ROC_curve_title)
                                title({'ANN vs. SVM vs. K-NN Testing Precision-recall curve (Semantic segmentation)'; ...
                                      ['AUC ANN-h1/h2/m: ' num2str(hybridHess_roc_SSM{10}) '/' num2str(hybridMFAT_roc_SSM{10}) '/' num2str(morpho_roc_SSM{10}) ' | ' ...
                                       'AUC KNN-h1/h2/m: ' num2str(hybridHess_roc_SSM{11}) '/' num2str(hybridMFAT_roc_SSM{11}) '/' num2str(morpho_roc_SSM{11}) ' | ' ...
                                       'AUC SVM-h1/h2/m: ' num2str(hybridHess_roc_SSM{12}) '/' num2str(hybridMFAT_roc_SSM{12}) '/' num2str(morpho_roc_SSM{12})]})
                            end
                    end
            end
    end
end

%% Save figure
if~(isempty(f1))    
    % Save the figure as .fig file
    [filepath,name,ext] = fileparts(textFile);
    figFileName = [name '_' datestr(now,'yyyy_mm_dd_HH_MM_SS_FFF') '.fig'];
    savefig(f1, fullfile(figFolder,figFileName))
end

%% End parameters

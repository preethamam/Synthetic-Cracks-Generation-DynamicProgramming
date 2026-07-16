% Initialize arrays
rocArrayij_ImageClassification = cell(size(hybrid_Frangi_search_allPerms,1) + size(hybrid_MFAT_search_allPerms,1) + 1, 1);
rocArrayij_AllComponents = cell(size(hybrid_Frangi_search_allPerms,1) + size(hybrid_MFAT_search_allPerms,1) + 1, 1);
rocArrayBBox_MLAB = cell(size(hybrid_Frangi_search_allPerms,1) + size(hybrid_MFAT_search_allPerms,1) + 1, 1);
rocArray_SSM = cell(size(hybrid_Frangi_search_allPerms,1) + size(hybrid_MFAT_search_allPerms,1) + 1, 1);
Classification_Results = [];

for i = 1:length(Algorithm_TYPE)
    
    % Populate algorithm type
    hybrid_inpstruct.Algorithm_TYPE = Algorithm_TYPE{i};
    
    switch hybrid_inpstruct.Algorithm_TYPE
        case 'hybrid_hessian'

        % Load ANN, KNN and SVM kernels
        load (ANN_classifier_hessian,'net');
        load (KNN_classifier_hessian,'MdlKNN');
        load (SVM_classifier_hessian,'ScoreCSVMModel');

            for m = 1:size(hybrid_Frangi_search_allPerms,1)
                
                % Get worker ID
                workerID = 0;
                
                % Iteration numbers
                hybrid_Frangi_allPerms = hybrid_Frangi_search_allPerms(m,:);
                
                % Print the anisotropic iteration number
                fprintf('Hessian Total iteration no.: %d | Anisotropic [I and II] iterations: %d %d\n', m, hybrid_Frangi_allPerms(1,1),...
                        hybrid_Frangi_allPerms(1,2));
                
                % Main images processing
                [rocArrayij_ImageClassification{m}, rocArrayij_AllComponents{m}, rocArrayBBox_MLAB{m}, rocArray_SSM{m}, ...
                Algorithm_Results] = Processed_Results(workerID, fileID, hybrid_inpstruct, jahan_inpstruct, hybrid_Frangi_allPerms, ...
                                                        images2classifier,imagesGroundTruth2classifier, ...
                                                        classnumber, MdlKNN, ScoreCSVMModel, net, imgCount, ...
                                                        objBoxCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs,...
                                                        ANN_classifier_hessian, KNN_classifier_hessian, SVM_classifier_hessian,...
                                                        ANN_classifier_mfat, KNN_classifier_mfat, SVM_classifier_mfat,...
                                                        ANN_classifier_morpho, KNN_classifier_morpho, SVM_classifier_morpho);  
                
                Classification_Results = [Classification_Results, Algorithm_Results];
            end

        case 'hybrid_MFAT'

            % Load ANN, KNN and SVM kernels
            load (ANN_classifier_mfat,'net');
            load (KNN_classifier_mfat,'MdlKNN');
            load (SVM_classifier_mfat,'ScoreCSVMModel');

            for m = size(hybrid_Frangi_search_allPerms,1) + 1 : size(hybrid_Frangi_search_allPerms,1) + size(hybrid_MFAT_search_allPerms,1)
                
                % Get worker ID
                workerID = 0;
                
                idx = m - size(hybrid_Frangi_search_allPerms,1);
                
                % Iteration numbers
                hybrid_MFAT_allPerms = hybrid_MFAT_search_allPerms(idx,:);
                
                % Print the anisotropic iteration number
                fprintf('MFAT Total iteration no.: %d | Anisotropic [I and II] iterations: %d %d\n', idx, hybrid_MFAT_allPerms(1,1),...
                        hybrid_MFAT_allPerms(1,2))
                
                % Main images processing
                [rocArrayij_ImageClassification{m}, rocArrayij_AllComponents{m}, rocArrayBBox_MLAB{m}, rocArray_SSM{m}, ...
                Algorithm_Results] = Processed_Results(workerID,fileID, hybrid_inpstruct, jahan_inpstruct, hybrid_MFAT_allPerms, ...
                                                        images2classifier,imagesGroundTruth2classifier, ...
                                                        classnumber, MdlKNN, ScoreCSVMModel, net, imgCount, ...
                                                        objBoxCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs,...
                                                        ANN_classifier_hessian, KNN_classifier_hessian, SVM_classifier_hessian,...
                                                        ANN_classifier_mfat, KNN_classifier_mfat, SVM_classifier_mfat,...
                                                        ANN_classifier_morpho, KNN_classifier_morpho, SVM_classifier_morpho);
                
                Classification_Results = [Classification_Results, Algorithm_Results];
                
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

            if length(hybrid_inpstruct.Algorithm_TYPE) == 1
                m = [];
            end
                
            if(isempty(m))
                m = 1;
            else
                m = m+1;
            end            

            % Main images processing
            [rocArrayij_ImageClassification{m}, rocArrayij_AllComponents{m}, rocArrayBBox_MLAB{m}, rocArray_SSM{m}, ...
            Algorithm_Results] = Processed_Results(workerID, fileID, hybrid_inpstruct, jahan_inpstruct, [], ...
                                                    images2classifier,imagesGroundTruth2classifier, ...
                                                    classnumber, MdlKNN, ScoreCSVMModel, net, imgCount, ...
                                                    objBoxCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs,...
                                                    ANN_classifier_hessian, KNN_classifier_hessian, SVM_classifier_hessian,...
                                                    ANN_classifier_mfat, KNN_classifier_mfat, SVM_classifier_mfat,...
                                                    ANN_classifier_morpho, KNN_classifier_morpho, SVM_classifier_morpho);
                                                
            Classification_Results = [Classification_Results, Algorithm_Results];

    end
end

%% Plot ROC curves
if (strcmp(hybrid_inpstruct.figShow_ROCCurves,'yes'))
    ROC_Curves_TestingDataset;
end

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

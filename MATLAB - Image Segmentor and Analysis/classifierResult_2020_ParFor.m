function [TPFPFNTNpixANN, TPFPFNTNpixKNN, TPFPFNTNpixSVM, ...
    TPFPFNBboxANN, TPFPFNBboxKNN, TPFPFNBboxSVM, ...
    PredictLabelsANN,PredictLabelsKNN,PredictLabelsSVM,SCORES,true_index,BBoxANN,BBoxKNN,BBoxSVM,...
    ssmPixCracksnNoncracks_ANN, ssmPixCracksnNoncracks_KNN, ssmPixCracksnNoncracks_SVM, ...
    PredictScoresImgANN,PredictScoresImgKNN, PredictScoresImgSVM, ...
    PixGT, PredictScoresSSMANN, PredictScoresSSMKNN, PredictScoresSSMSVM] ...
        = classifierResult_2020_ParFor (workerID, input, hybrid_allPerms, jahaninput, inputImages, inputGroundTruthImages,...
                         inputGroundTruthImagesPreRecall, crackClass, MdlKNN, ScoreCSVMModel, net, imgCount)
                 
    % Initialize
    TPFPFNTNpixANN = zeros(length(inputImages), 4);
    TPFPFNTNpixKNN = zeros(length(inputImages), 4);
    TPFPFNTNpixSVM = zeros(length(inputImages), 4);
    
    TPFPFNBboxANN = zeros(length(inputImages), 3);
    TPFPFNBboxKNN = zeros(length(inputImages), 3);
    TPFPFNBboxSVM = zeros(length(inputImages), 3);
    
    PredictScoresImgANN = zeros(length(inputImages),1);
    PredictScoresImgKNN = zeros(length(inputImages),1);
    PredictScoresImgSVM = zeros(length(inputImages),1);
    
    SElength_TYPE = jahaninput.SElength;
    crackLEN = jahaninput.crackLEN;
    anglebetween = jahaninput.anglebetween;
    SElength_percent = jahaninput.SElength_percent;
    
    
    % Populate the all permutations back to the struct
    if ~(isempty(hybrid_allPerms))
        hybrid_itrnum.aniso_num_iter = hybrid_allPerms(1,1:2);
        input.aniso.delta_t          = hybrid_allPerms(1,3:4);
        input.aniso.kappa            = hybrid_allPerms(1,5:6);
    
        switch input.Algorithm_TYPE
            case 'hybrid_hessian'
                input.frangiopt.FrangiScaleRange  = hybrid_allPerms(1,7:8);
                input.frangiopt.FrangiBetaOne     = hybrid_allPerms(1,9);
                input.frangiopt.FrangiBetaTwo     = hybrid_allPerms(1,10);
            case 'hybrid_MFAT'    
                input.MFAToptions.sigmas1       = hybrid_allPerms(1,7);
                input.MFAToptions.sigmas2       = hybrid_allPerms(1,8);
                input.MFAToptions.sigmasScaleRatio = hybrid_allPerms(1,9);
                input.MFAToptions.spacing       = hybrid_allPerms(1,10); 
                input.MFAToptions.tau           = hybrid_allPerms(1,11); 
                input.MFAToptions.tau2          = hybrid_allPerms(1,12); 
                input.MFAToptions.D             = hybrid_allPerms(1,13);
        end
    else
        hybrid_itrnum.aniso_num_iter = [];
        input.aniso.delta_t          = [];
        input.aniso.kappa            = [];
    
        input.frangiopt.FrangiScaleRange  = [];
        input.frangiopt.FrangiBetaOne     = [];
        input.frangiopt.FrangiBetaTwo     = [];
    
        input.MFAToptions.sigmas1       = [];
        input.MFAToptions.sigmas2       = [];
        input.MFAToptions.sigmasScaleRatio = [];
        input.MFAToptions.spacing       = []; 
        input.MFAToptions.tau           = []; 
        input.MFAToptions.tau2          = []; 
        input.MFAToptions.D             = [];
    end
    
    %Before the loop, we need to construct the object. 
    WaitMessage = waitbarParfor(length(inputImages), 'Waitbar', true);
         
    % For all training images 125:130 %
    parfor i = 1:length(inputImages)
    
        %Send a message to the object. 
        WaitMessage.Send;
    
        % Initialize
        BW_image = []; BW = []; BW3 = [];
        debranchedImage =[];
        branchFilledImage = [];
        anyBranches = [];
        crackDebrancher_required_flag = [];
        Featuremat = []; Pixcoords = []; yANN = []; yKNN = []; 
        ySVM = []; score_ann_trans = []; score_knn = []; score_svm = []; 
        Ivessel = [];
        
        %----------------------------------------------------------
        % Image parameters
        %----------------------------------------------------------
        % Read image
        ImageID = inputImages{i};
        [imheight, imwidth, imbytesppix, Ioriginal, Igray] ...
                = imconversion2gray(ImageID, input.gpuarray, input.resizeImage,...
                  input.maxImageResizePixels, input.resizeImageSize, input.resizeImageSizeScale, input.contrast_type); %#ok<*ASGLU>
    
        % Obtain ground truth (GT) imagee for true index getter
        if (isempty(inputGroundTruthImages))
            ImageID_ground    = inputGroundTruthImagesPreRecall{i};
            [GT, ~, ~] = groundNnoisy_BWimage (input, ImageID_ground, ...
             input.gpuarray, input.resizeImage,...
                  input.maxImageResizePixels, input.resizeImageSize, input.resizeImageSizeScale, input.contrast_type, input.RGBstartindex, ...
             [], input.colorspace); %#ok<*NASGU>
        else
            % Obtain the ground-truth and noisy binary images
            ImageID_ground    = inputGroundTruthImages{i};
            [GT, ~, ~] = groundNnoisy_BWimage (input, ImageID_ground, ...
             input.gpuarray, input.resizeImage,...
                  input.maxImageResizePixels, input.resizeImageSize, input.resizeImageSizeScale, input.contrast_type, input.RGBstartindex, ...
             BW_image, input.colorspace); %#ok<*NASGU>        
        end
    
        % Block in rows
        % Most will be blockSizeR but there may be a remainder amount of less than that.
        wholeBlockRows = floor(imheight / input.blockSizeR);
        blockVectorR = [input.blockSizeR * ones(1, wholeBlockRows), rem(imheight, input.blockSizeR)];
    
        % Block in columns
        wholeBlockCols = floor(imwidth / input.blockSizeC);
        blockVectorC = [input.blockSizeC * ones(1, wholeBlockCols), rem(imwidth, input.blockSizeC)];
    
        % Create the cell array, ca. 
        % Each cell (except for the remainder cells at the end of the image)
        % in the array contains a blockSizeR by blockSizeC by 3 color array.
        % This line is where the image is actually divided up into blocks.
    
        blockIMcolor = mat2cell(Ioriginal, blockVectorR, ...
                       blockVectorC, imbytesppix);
        blockIMgray  = mat2cell(Igray, blockVectorR, blockVectorC);
        blockGT      = mat2cell(GT, blockVectorR, blockVectorC);
    
        % Total blocks in row anc columns
        numPlotsR = size(blockIMgray, 1);
        numPlotsC = size(blockIMgray, 2);
    
        % Store blocks for Aniso 1 and 2, ANN, KNN, and SVM
        Result_BW_image_ANN = cell(numPlotsR, numPlotsC);
        Result_BW_image_KNN = cell(numPlotsR, numPlotsC);
        Result_BW_image_SVM = cell(numPlotsR, numPlotsC);
        BW_image            = cell(numPlotsR, numPlotsC);
        BW_image_classifier_bypass = cell(numPlotsR, numPlotsC);
        branchFilledImageTotal = cell(numPlotsR, numPlotsC);
        Result_Im_aniso_1   = cell(numPlotsR, numPlotsC);
        Result_Im_aniso_2   = cell(numPlotsR, numPlotsC);
        GTimg               = cell(numPlotsR, numPlotsC); 
        
        bboxesANN_rowcol = cell(numPlotsR, numPlotsC);
        scoresANN_rowcol = cell(numPlotsR, numPlotsC);
        labelsANN_rowcol = cell(numPlotsR, numPlotsC);
        
        bboxesKNN_rowcol = cell(numPlotsR, numPlotsC);
        scoresKNN_rowcol = cell(numPlotsR, numPlotsC);
        labelsKNN_rowcol = cell(numPlotsR, numPlotsC);
        
        bboxesSVM_rowcol = cell(numPlotsR, numPlotsC);
        scoresSVM_rowcol = cell(numPlotsR, numPlotsC);
        labelsSVM_rowcol = cell(numPlotsR, numPlotsC);
    
    
        for r = 1 : numPlotsR
            for c = 1 : numPlotsC
    
                %----------------------------------------------------------
                % Anisotropic diffusion to suppress the effect of
                % background (and textury noise)
                %----------------------------------------------------------      
                blockImage = cell2mat(blockIMgray(r,c));
    
                switch input.Algorithm_TYPE
    
                    case 'hybrid_hessian'
    
                        % Anisotropic diffusion function callback *dummy block)
                        Result_Im_aniso_1(r,c) = {blockImage};
    
                        %----------------------------------------------------------
                        % Hessian matrix method for curvature dominant feature 
                        % extraction
                        %----------------------------------------------------------
    
                        % Hessian matrix (Frangi filter) function callback
                        Ivessel  = FrangiFilter2D(blockImage, input.frangiopt);
    
                        % Anisotropic diffusion function callback after vessel 
                        % extraction. This ensures good smoothing.
                        Ivessel2 = Ivessel;
                        Result_Im_aniso_2(r,c) = {Ivessel2};
    
                        %----------------------------------------------------------
                        % Binary conversion
                        %----------------------------------------------------------
                        % Display the Hessian matrix (Frangi filter) results
                        % Ostu's grayscale threshold
                        level = graythresh(Ivessel2);
    
                        % Convert to the binary image
                        BW = imbinarize(Ivessel2, level);
                        
                        
                    case 'hybrid_MFAT'
    
                        % Anisotropic diffusion function callback *dummy block)
                        Result_Im_aniso_1(r,c) = {blockImage};
    
                        %----------------------------------------------------------
                        % MFAT method for curvature dominant feature 
                        % extraction
                        %----------------------------------------------------------
                        switch input.MFAT_TYPE
                            case 'EigenFAT'
                                % Proposed Method (Eign values based version)
                                Ivessel = FractionalIstropicTensor(blockImage,input.MFAToptions);
                                Ivessel = normalize(Ivessel);
                            case 'ProbabilisticFAT'
                                % Proposed Method (probability based version)
    %                             Ivessel = ProbabiliticMFATSpacing(Im_ad,input.MFAToptions);
                                Ivessel = ProbabiliticMFATSigmas(blockImage,input.MFAToptions);
                                Ivessel = normalize(Ivessel);
                        end
        
    
                        % Anisotropic diffusion function callback after vessel 
                        % extraction. This ensures good smoothing.
                        Ivessel2 = Ivessel;
                        Result_Im_aniso_2(r,c) = {Ivessel2};
    
                        %----------------------------------------------------------
                        % Binary conversion
                        %----------------------------------------------------------
                        % Display the Hessian matrix (Frangi filter) results
                        % Ostu's grayscale threshold
                        level = graythresh(Ivessel2);
    
                        % Convert to the binary image
                        BW = imbinarize(Ivessel2, level);
    
                    case 'morpho'            
                        switch SElength_TYPE
                            case 'default'
    
                                % Morphological method (Jahanshahi's method)
                                BW = funct_crackDetect_Salembier_Sinha_Jahan ...
                                                (blockImage, crackLEN, ...
                                                anglebetween);
                                Ivessel  = [];            
                                Ivessel2 = [];
    
                            case 'imageDimBased'
                                jahaninput_nmax = round(SElength_percent  * max(size(blockImage)));
    
                                % Crack structural length
                                jahaninput_crackLEN = jahaninput.nmin+2 : jahaninput.nstep : jahaninput_nmax+10;  % options:  [1 : max(size(image))]
    
                                % Morphological method (Jahanshahi's method)
                                BW = funct_crackDetect_Salembier_Sinha_Jahan ...
                                                (blockImage, jahaninput_crackLEN, ...
                                                jahaninput.anglebetween);
                                Ivessel  = [];            
                                Ivessel2 = [];
                        end
                end
                
                if(input.postprocess == 1)
                    %----------------------------------------------------------
                    % Line filtering
                    %----------------------------------------------------------
                    BW1 = BW;
    
                    %----------------------------------------------------------
                    % Low-level filtering
                    %----------------------------------------------------------
                    % Stage I/ first step filter [for orphan/flakey pixels
                    % and bridging close neighbors]
                    BW2 = filter_stage_I (BW1);
    
                    %----------------------------------------------------------
                    % Close small holes
                    %----------------------------------------------------------                            
                    if (input.imclosing)
                        SE = strel('disk',input.imclose_disk_size);
                        BW2 = imclose(BW2,SE);
                    end
    
                    %----------------------------------------------------------
                    % Blob removal
                    %----------------------------------------------------------
                    switch input.Algorithm_TYPE
    
                        case {'hybrid_hessian', 'hybrid_MFAT'}
                            % Connected components
                            CC = bwconncomp(BW2);
                            S  = regionprops(CC,'Area');
    
                            % Normal distribution fit
                            [mu_hessian, sigma_hessian] = normfit(cell2mat(struct2cell(S)));
    
                            % check for sigma
                            if ((isempty(sigma_hessian)) || (isnan (sigma_hessian)))
                                sigma_hessian = 0;
                            end
    
                            % Remove smaller area lesser than sigma_morph
                            BW3 = bwareaopen(BW2, ceil(input.blobfilter_sigma * ...
                                                        sigma_hessian), 8);
        %                     figure;imshow(BW3)
    
                        case 'morpho'
                            switch input.blobRemovalType
                                case 'autoBlobRemoval'
                                    CC = bwconncomp(BW2);
                                    S  = regionprops(CC,'Area');
    
                                    % Normal distribution fit
                                    [mu_hessian, sigma_hessian] = normfit(cell2mat(struct2cell(S)));
    
                                    % check for sigma
                                    if ((isempty(sigma_hessian)) || (isnan (sigma_hessian)))
                                        sigma_hessian = 0;
                                    end
    
                                    % Remove smaller area lesser than sigma_morph
                                    BW3 = bwareaopen(BW2, ceil(input.blobfilter_sigma * ...
                                                                sigma_hessian), 8);
    
                                case 'areaPreDefined'
                                    % Remove smaller area lesser than sigma_morph
                                    BW3 = bwareaopen(BW2, input.morpho_blob_size_area, 8);
                            end
    
                    end
                elseif (input.postprocess == 2)
                    %----------------------------------------------------------
                    % Line filtering
                    %----------------------------------------------------------
                    BW1 = BW;
    
                    %----------------------------------------------------------
                    % Low-level filtering
                    %----------------------------------------------------------
                    % Stage I/ first step filter [for orphan/flakey pixels
                    % and bridging close neighbors]
                    BW2 = filter_stage_I (BW1);
    
                    BW3 = BW2;
                else
                    BW3 = BW;
                end
    
                switch input.crackDebrancher_required
                    case 'yes'
    %                             [debranchedImage, branchFilledImage] = crack_deBrancher(blockImage,BW3,input.thinPruneMethod,...
    %                                                             input.thinPruneThresh, input.figShow_debranch);
    
                        [debranchedImage, branchFilledImage, anyBranches] = crack_deBrancher_BP2EPnBP_LengthConstraint_Feb2019...
                            (uint8(blockImage),BW3,input.thinPruneMethod,...
                                                        input.thinPruneThresh, input.branchlengthThreshold,...
                                                        input.imclose_disk_size, input.boundary_smooth, ...
                                                        input.windowSize, input.figShow_debranch);
                    case 'no'
                         debranchedImage   = [];
                         branchFilledImage = [];
                         anyBranches = 'no';
                end
    
                %----------------------------------------------------------
                % Feature vector 
                %----------------------------------------------------------
                % Class number (folder corresponds to class)
                % crack_non_crackfeaturesNlabels_2018Revised_5JahanFeatures
                class_number = crackClass(i);
                crackDebrancher_required_flag = anyBranches;
    
                [Featuremat, Label_matrix, BBoxes, Pixcoords, CircIndex,Branch_points,holes]...
                = crack_non_crackfeaturesNlabels_2018Revised_5JahanFeatures ...
                (Ioriginal, ...
                blockImage, BW3, debranchedImage, GT, class_number,input); 
    
                %----------------------------------------------------------
                % Test feature matrix
                %----------------------------------------------------------
                if (isempty(Featuremat))
                    yANN = [];
                    score_ann = [];
    
                    yKNN = [];
                    score_knn = [];
    
                    ySVM = [];
                    score_svm = [];
                else
                    % Test feature matrix with ANN
                    yANN  = sim (net, Featuremat'); %, 'useParallel','yes');
                    score_ann = yANN;
                    score_ann = softmax(score_ann);
    
                    yANN  = vec2ind(yANN);
    
                    % Test feature matrix with KNN
                    [yKNN,score_knn,cost_knn] = predict(MdlKNN, Featuremat);
    
                    % Test feature matrix with SVM
    %                         [ySVM,score_svm,cost_svm] = predict(MdlSVM, Featuremat);
                    [ySVM,score_svm] = predict(ScoreCSVMModel,Featuremat);
                end
                score_ann_trans = score_ann';
    
    
                % Image classification scores
                if ~(isempty(score_ann_trans))  
                    PredictScoresImgANN(i,1) = max(score_ann_trans(:,2));
                else
                    PredictScoresImgANN(i,1) = NaN;
                end
                
                
                if ~(isempty(score_knn))
                    PredictScoresImgKNN(i,1) = max(score_knn(:,2));
                else
                    PredictScoresImgKNN(i,1) = NaN;
                end
                
                
                if ~(isempty(score_svm))
                    PredictScoresImgSVM(i,1) = max(score_svm(:,2));
                else
                    PredictScoresImgSVM(i,1) = NaN;
                end                                            
    
                % Store scores of ANN, KNN and SVM
                SCORES(i).ann = score_ann;
                SCORES(i).knn = score_knn;
                SCORES(i).svm = score_svm;
                
                % Store true labels
                true_index{i} = Label_matrix;
    
                %----------------------------------------------------------
                % Fix class 2 in figure BW3
                %----------------------------------------------------------
                crackDebrancher_required_flag = anyBranches;   
                
                switch crackDebrancher_required_flag
                    case 'yes'
                        switch input.classifier_required
                            case 'classifier'
                                [fixedIMANN, BBoxes_ANN, BBoxes_scores_ANN, BBoxes_Labels_ANN] = fixClass2Labels(input, debranchedImage, yANN, Pixcoords, input.postprocess, ...
                                        input.non_crack_class, input.post_process_Type, input.circularity_threshold, ...
                                        input.branchpoints, CircIndex,Branch_points,holes, BBoxes, score_ann_trans);
                                Result_BW_image_ANN(r,c) = {fixedIMANN};
    
                                bboxesANN_rowcol(r,c) = {BBoxes_ANN};
                                scoresANN_rowcol(r,c) = {BBoxes_scores_ANN};
                                labelsANN_rowcol(r,c) = {BBoxes_Labels_ANN};
    
                                [fixedIMKNN, BBoxes_KNN, BBoxes_scores_KNN, BBoxes_Labels_KNN] = fixClass2Labels(input, debranchedImage, yKNN, Pixcoords, input.postprocess, ...
                                        input.non_crack_class, input.post_process_Type, input.circularity_threshold, ...
                                        input.branchpoints, CircIndex,Branch_points,holes, BBoxes, score_knn);
                                Result_BW_image_KNN(r,c) = {fixedIMKNN};
    
                                bboxesKNN_rowcol(r,c) = {BBoxes_KNN};
                                scoresKNN_rowcol(r,c) = {BBoxes_scores_KNN};
                                labelsKNN_rowcol(r,c) = {BBoxes_Labels_KNN};
    
                                [fixedIMSVM, BBoxes_SVM, BBoxes_scores_SVM, BBoxes_Labels_SVM] = fixClass2Labels(input, debranchedImage, ySVM, Pixcoords, input.postprocess, ...
                                        input.non_crack_class, input.post_process_Type, input.circularity_threshold, ...
                                        input.branchpoints, CircIndex,Branch_points,holes, BBoxes, score_svm);
                                Result_BW_image_SVM(r,c) = {fixedIMSVM};
    
                                bboxesSVM_rowcol(r,c) = {BBoxes_SVM};
                                scoresSVM_rowcol(r,c) = {BBoxes_scores_SVM};
                                labelsSVM_rowcol(r,c) = {BBoxes_Labels_SVM};
                                
                            case 'classifier_bypass'
                        
                                [fixedIMclassifier_bypass, BBoxes_none, BBoxes_scores_none, BBoxes_Labels_none] = fixClass2Labels(input, debranchedImage, [], Pixcoords, input.postprocess, ...
                                        input.non_crack_class, input.post_process_Type, input.circularity_threshold, ...
                                        input.branchpoints, CircIndex, Branch_points,holes);
                                BW_image_classifier_bypass(r,c) = {fixedIMclassifier_bypass, BBoxes, []};
                                
                                bboxesANN_rowcol(r,c) = {BBoxes_none};
                                scoresANN_rowcol(r,c) = {BBoxes_scores_none};
                                labelsANN_rowcol(r,c) = {BBoxes_Labels_none};
                                
                                bboxesKNN_rowcol(r,c) = {BBoxes_none};
                                scoresKNN_rowcol(r,c) = {BBoxes_scores_none};
                                labelsKNN_rowcol(r,c) = {BBoxes_Labels_none};
                                
                                bboxesSVM_rowcol(r,c) = {BBoxes_none};
                                scoresSVM_rowcol(r,c) = {BBoxes_scores_none};
                                labelsSVM_rowcol(r,c) = {BBoxes_Labels_none};
                        end
    
                    case 'no'
                        switch input.classifier_required
                            case 'classifier'
                                [fixedIMANN, BBoxes_ANN, BBoxes_scores_ANN, BBoxes_Labels_ANN] = fixClass2Labels(input, BW3, yANN, Pixcoords, input.postprocess, ...
                                        input.non_crack_class, input.post_process_Type, input.circularity_threshold, ...
                                        input.branchpoints, CircIndex,Branch_points,holes, BBoxes, score_ann_trans);
                                Result_BW_image_ANN(r,c) = {fixedIMANN};
                                
                                bboxesANN_rowcol(r,c) = {BBoxes_ANN};
                                scoresANN_rowcol(r,c) = {BBoxes_scores_ANN};
                                labelsANN_rowcol(r,c) = {BBoxes_Labels_ANN};
    
                                [fixedIMKNN, BBoxes_KNN, BBoxes_scores_KNN, BBoxes_Labels_KNN] = fixClass2Labels(input, BW3, yKNN, Pixcoords, input.postprocess, ...
                                        input.non_crack_class, input.post_process_Type, input.circularity_threshold, ...
                                        input.branchpoints, CircIndex,Branch_points,holes, BBoxes, score_knn);
                                Result_BW_image_KNN(r,c) = {fixedIMKNN};
                                
                                bboxesKNN_rowcol(r,c) = {BBoxes_KNN};
                                scoresKNN_rowcol(r,c) = {BBoxes_scores_KNN};
                                labelsKNN_rowcol(r,c) = {BBoxes_Labels_KNN};
                                
                                [fixedIMSVM, BBoxes_SVM, BBoxes_scores_SVM, BBoxes_Labels_SVM] = fixClass2Labels(input, BW3, ySVM, Pixcoords, input.postprocess, ...
                                        input.non_crack_class, input.post_process_Type, input.circularity_threshold, ...
                                        input.branchpoints, CircIndex,Branch_points,holes, BBoxes, score_svm);
                                Result_BW_image_SVM(r,c) = {fixedIMSVM};
                                
                                bboxesSVM_rowcol(r,c) = {BBoxes_SVM};
                                scoresSVM_rowcol(r,c) = {BBoxes_scores_SVM};
                                labelsSVM_rowcol(r,c) = {BBoxes_Labels_SVM};
                                
                            case 'classifier_bypass'
    
                                [fixedIMclassifier_bypass, BBoxes_none, BBoxes_scores_none, BBoxes_Labels_none] = fixClass2Labels(input, BW3, [], Pixcoords, input.postprocess, ...
                                        input.non_crack_class, input.post_process_Type, input.circularity_threshold, ...
                                        input.branchpoints, CircIndex, Branch_points,holes, BBoxes, []);
                                BW_image_classifier_bypass(r,c) = {fixedIMclassifier_bypass};
                                
                                bboxesANN_rowcol(r,c) = {BBoxes_none};
                                scoresANN_rowcol(r,c) = {BBoxes_scores_none};
                                labelsANN_rowcol(r,c) = {BBoxes_Labels_none};
                                
                                bboxesKNN_rowcol(r,c) = {BBoxes_none};
                                scoresKNN_rowcol(r,c) = {BBoxes_scores_none};
                                labelsKNN_rowcol(r,c) = {BBoxes_Labels_none};
                                
                                bboxesSVM_rowcol(r,c) = {BBoxes_none};
                                scoresSVM_rowcol(r,c) = {BBoxes_scores_none};
                                labelsSVM_rowcol(r,c) = {BBoxes_Labels_none};         
                        end
                end
                
                BW_image(r,c) = {BW3};
                branchFilledImageTotal(r,c) = {branchFilledImage};
            end
        end       
        
        % Populate the predicted BBOxes entries
        bboxesANN_conc = reshape(bboxesANN_rowcol',1,[])';
        scoresANN_conc = reshape(scoresANN_rowcol',1,[])';
        labelsANN_conc = reshape(labelsANN_rowcol',1,[])';
        
        BBoxesAccum_ANN{i}       = vertcat(bboxesANN_conc{:}); %#ok<*FNDSB>
        BBoxesAccum_ANNscores{i} = vertcat(scoresANN_conc{:}); %#ok<*FNDSB>
        BBoxesAccum_ANNLabels{i} = vertcat(labelsANN_conc{:}); %#ok<*FNDSB>
    
        bboxesKNN_conc = reshape(bboxesKNN_rowcol',1,[])';
        scoresKNN_conc = reshape(scoresKNN_rowcol',1,[])';
        labelsKNN_conc = reshape(labelsKNN_rowcol',1,[])';
        
        BBoxesAccum_KNN{i}       = vertcat(bboxesKNN_conc{:}); %#ok<*FNDSB>
        BBoxesAccum_KNNscores{i} = vertcat(scoresKNN_conc{:}); %#ok<*FNDSB>
        BBoxesAccum_KNNLabels{i} = vertcat(labelsKNN_conc{:}); %#ok<*FNDSB>
        
        bboxesSVM_conc = reshape(bboxesSVM_rowcol',1,[])';
        scoresSVM_conc = reshape(scoresSVM_rowcol',1,[])';
        labelsSVM_conc = reshape(labelsSVM_rowcol',1,[])';
    
        BBoxesAccum_SVM{i}       = vertcat(bboxesSVM_conc{:}); %#ok<*FNDSB>
        BBoxesAccum_SVMscores{i} = vertcat(scoresSVM_conc{:}); %#ok<*FNDSB>
        BBoxesAccum_SVMLabels{i} = vertcat(labelsSVM_conc{:}); %#ok<*FNDSB>
       
        % Convert cell to matrix
        switch input.classifier_required
            case 'classifier'
                switch crackDebrancher_required_flag
                    case 'yes'
                        Result_BW_image_ANN = imadd(cell2mat(Result_BW_image_ANN),cell2mat(branchFilledImageTotal));
                        Result_BW_image_KNN = imadd(cell2mat(Result_BW_image_KNN),cell2mat(branchFilledImageTotal));
                        Result_BW_image_SVM = imadd(cell2mat(Result_BW_image_SVM),cell2mat(branchFilledImageTotal));
                    case 'no'
                        Result_BW_image_ANN = cell2mat(Result_BW_image_ANN);
                        Result_BW_image_KNN = cell2mat(Result_BW_image_KNN);
                        Result_BW_image_SVM = cell2mat(Result_BW_image_SVM);
                end
            case 'classifier_bypass'
                switch input.crackDebrancher_required
                    case 'yes'
                        Result_BW_image_ANN = imadd(cell2mat(BW_image_classifier_bypass),cell2mat(branchFilledImageTotal));
                        Result_BW_image_KNN = imadd(cell2mat(BW_image_classifier_bypass),cell2mat(branchFilledImageTotal));
                        Result_BW_image_SVM = imadd(cell2mat(BW_image_classifier_bypass),cell2mat(branchFilledImageTotal));
                    case 'no'
                        Result_BW_image_ANN = cell2mat(BW_image_classifier_bypass);
                        Result_BW_image_KNN = cell2mat(BW_image_classifier_bypass);
                        Result_BW_image_SVM = cell2mat(BW_image_classifier_bypass);
                end
        end
        BW_image            = cell2mat(BW_image);
        Result_Im_aniso_1   = cell2mat(Result_Im_aniso_1);
        Result_Im_aniso_2   = cell2mat(Result_Im_aniso_2);
    
        if ~(islogical(Result_BW_image_ANN))
            Result_BW_image_ANN = logical(Result_BW_image_ANN);
        end
    
        if ~(islogical(Result_BW_image_KNN))
            Result_BW_image_KNN = logical(Result_BW_image_KNN);
        end
    
        if ~(islogical(Result_BW_image_SVM))
            Result_BW_image_SVM = logical(Result_BW_image_SVM);
        end
    
        
        
        % Post-processing 
        %----------------------------------------------------------
        % Ground truth and noisy data
        %----------------------------------------------------------                                          
        if (isempty(inputGroundTruthImages))
            ImageID_ground    = inputGroundTruthImagesPreRecall{i};
            [Iground2PrecisionRecall, Inoisy2PrecisionRecall, IAnnotate] ...
                = groundNnoisy_BWimage (input, ImageID_ground, ...
             input.gpuarray, input.resizeImage,...
                  input.maxImageResizePixels, input.resizeImageSize, input.resizeImageSizeScale, input.contrast_type, input.RGBstartindex, ...
             BW_image, input.colorspace); %#ok<*NASGU>
        else
            % Obtain the ground-truth and noisy binary images
            ImageID_ground    = inputGroundTruthImages{i};
            [Iground2PrecisionRecall, Inoisy2PrecisionRecall, IAnnotate] = groundNnoisy_BWimage (input,ImageID_ground, ...
             input.gpuarray, input.resizeImage,...
                  input.maxImageResizePixels, input.resizeImageSize, input.resizeImageSizeScale, input.contrast_type, input.RGBstartindex, ...
             BW_image, input.colorspace); %#ok<*NASGU>        
        end
    
    %     figure; imshow([Iground2PrecisionRecall,Result_BW_image_SVM])
        
        %----------------------------------------------------------
        % Saving the images / Write classifier output images
        %----------------------------------------------------------
        % Store GT pixel images
        [filepath,name,ext] = fileparts(ImageID_ground);
        if (i <= imgCount(2))
            outputBaseFileName = sprintf('%s.bmp',name);
            imwrite(Result_BW_image_ANN, fullfile(input.PixLabelsFolder, num2str(workerID), 'crack', 'ANN', outputBaseFileName),'bmp');   
            imwrite(Result_BW_image_KNN, fullfile(input.PixLabelsFolder, num2str(workerID), 'crack', 'KNN', outputBaseFileName),'bmp');  
            imwrite(Result_BW_image_SVM, fullfile(input.PixLabelsFolder, num2str(workerID), 'crack', 'SVM', outputBaseFileName),'bmp');
        else
            outputBaseFileName = sprintf('%s.bmp',name);
            imwrite(Result_BW_image_ANN, fullfile(input.PixLabelsFolder, num2str(workerID), 'non-crack', 'ANN', outputBaseFileName),'bmp');   
            imwrite(Result_BW_image_KNN, fullfile(input.PixLabelsFolder, num2str(workerID), 'non-crack', 'KNN', outputBaseFileName),'bmp');  
            imwrite(Result_BW_image_SVM, fullfile(input.PixLabelsFolder, num2str(workerID), 'non-crack', 'SVM', outputBaseFileName),'bmp');
        end
        
        %----------------------------------------------------------
        % Find TP, FP and FN based on Pixels
        %----------------------------------------------------------
        % ANN
        [ TPPixANN, FPPixANN, FNPixANN, TNPixANN] = ...
        TruePositive_FalsePositive_FalseNegative_Pixel_2018( Iground2PrecisionRecall,...
                                Result_BW_image_ANN);
        TPFPFNTNpixANN(i,:) = [ TPPixANN, FPPixANN, FNPixANN, TNPixANN ];
    
        % KNN
        [ TPPixKNN, FPPixKNN, FNPixKNN, TNPixKNN] = ...
        TruePositive_FalsePositive_FalseNegative_Pixel_2018( Iground2PrecisionRecall,...
                                Result_BW_image_KNN);
        TPFPFNTNpixKNN(i,:) = [ TPPixKNN, FPPixKNN, FNPixKNN, TNPixKNN ];
    
        % SVM
        [ TPPixSVM, FPPixSVM, FNPixSVM, TNPixSVM] = ...
        TruePositive_FalsePositive_FalseNegative_Pixel_2018( Iground2PrecisionRecall,...
                                Result_BW_image_SVM);
        TPFPFNTNpixSVM(i,:) = [ TPPixSVM, FPPixSVM, FNPixSVM, TNPixSVM ];
    
    
        %----------------------------------------------------------
        % Find TP, FP and FN based on bounding box
        %----------------------------------------------------------
        [filepath,filename,ext] = fileparts(ImageID);
        % ANN
        [ TPBboxANN, FPBboxANN, FNBboxANN] = ...
        TruePositive_FalsePositive_FalseNegative_Bbox_2021b(i, ...
        Ioriginal, Igray, Result_Im_aniso_1, Result_Im_aniso_2, Iground2PrecisionRecall,BW_image,...
                                Result_BW_image_ANN, IAnnotate, ...
                                input.filesavepath,input.storeFolderName,...
                                ImageID, 'ANN',...
                                input.storeOutputImages,imheight, imwidth,filename,input);
        TPFPFNBboxANN(i,:) = [ TPBboxANN, FPBboxANN, FNBboxANN];
    
        % KNN
        [ TPBboxKNN, FPBboxKNN, FNBboxKNN] = ...
        TruePositive_FalsePositive_FalseNegative_Bbox_2021b(i, ...
        Ioriginal, Igray, Result_Im_aniso_1, Result_Im_aniso_2, Iground2PrecisionRecall,BW_image,...
                                Result_BW_image_KNN, IAnnotate, ...
                                input.filesavepath,input.storeFolderName,...
                                ImageID, 'KNN',...
                                input.storeOutputImages,imheight, imwidth,filename,input);
        TPFPFNBboxKNN(i,:) = [ TPBboxKNN, FPBboxKNN, FNBboxKNN];
    
        % SVM
        [ TPBboxSVM, FPBboxSVM, FNBboxSVM] = ...
        TruePositive_FalsePositive_FalseNegative_Bbox_2021b(i, ...
        Ioriginal, Igray, Result_Im_aniso_1, Result_Im_aniso_2, Iground2PrecisionRecall,BW_image,...
                                Result_BW_image_SVM, IAnnotate, ...
                                input.filesavepath,input.storeFolderName,...
                                ImageID, 'SVM',...
                                input.storeOutputImages,imheight, imwidth,filename,input);
        TPFPFNBboxSVM(i,:) = [ TPBboxSVM, FPBboxSVM, FNBboxSVM];
    
        %----------------------------------------------------------
        % Concatenate classification predicted labels
        %----------------------------------------------------------
        if~(isempty(find(Result_BW_image_ANN, 1)))
            PredictLabelsANN(i,:) = 2; 
        else
            PredictLabelsANN(i,:) = 1;
        end
    
        if~(isempty(find(Result_BW_image_KNN, 1)))
            PredictLabelsKNN(i,:) = 2; 
        else
            PredictLabelsKNN(i,:) = 1;
        end
    
        if~(isempty(find(Result_BW_image_SVM, 1)))
            PredictLabelsSVM(i,:) = 2; 
        else
            PredictLabelsSVM(i,:) = 1;
        end
    
        %----------------------------------------------------------
        % Construct the GT, ANN, KNN and SVM
        %----------------------------------------------------------
    
        % Initialize the BW image
        BW_SSM_ANN = zeros(size(BW_image));
        BW_SSM_KNN = zeros(size(BW_image));
        BW_SSM_SVM = zeros(size(BW_image));
    
        if ~(isempty(Featuremat))
            for j = 1 : size(Featuremat,1)
                if (yANN(j) == input.crack_class)
                    rowpix = Pixcoords{1,1}{j,1};
                    colpix = Pixcoords{1,2}{j,1};
                    ind = sub2ind(size(BW_SSM_ANN),rowpix,colpix);
                    BW_SSM_ANN(ind) = score_ann_trans(j,2);
                end
                 if (yKNN(j) == input.crack_class)
                    rowpix = Pixcoords{1,1}{j,1};
                    colpix = Pixcoords{1,2}{j,1};
                    ind = sub2ind(size(BW_SSM_KNN),rowpix,colpix);
                    BW_SSM_KNN(ind) = score_knn(j,2);
                 end
                if (ySVM(j) == input.crack_class)
                    rowpix = Pixcoords{1,1}{j,1};
                    colpix = Pixcoords{1,2}{j,1};
                    ind = sub2ind(size(BW_SSM_SVM),rowpix,colpix);
                    BW_SSM_SVM(ind) = score_svm(j,2);
                end
            end
        end
    
        % Image flattening to a vector
        SSM_GTFlatten{i}  = reshape(Iground2PrecisionRecall',1,[]);
        SSM_ANNFlatten{i} = reshape(BW_SSM_ANN',1,[]);
        SSM_KNNFlatten{i} = reshape(BW_SSM_KNN',1,[]);
        SSM_SVMFlatten{i} = reshape(BW_SSM_SVM',1,[]);
    end
            
    %Destroy the object.
    WaitMessage.Destroy       
    
    % Bounding boxes of classifer outputs
    switch input.classifier_required
        case 'classifier'
            BBoxANN = table(BBoxesAccum_ANN', BBoxesAccum_ANNscores', BBoxesAccum_ANNLabels');
            BBoxANN.Properties.VariableNames = {'BBox', 'Scores', 'Labels'};
    
            BBoxKNN = table(BBoxesAccum_KNN', BBoxesAccum_KNNscores', BBoxesAccum_KNNLabels');
            BBoxKNN.Properties.VariableNames = {'BBox', 'Scores', 'Labels'};
    
            BBoxSVM = table(BBoxesAccum_SVM', BBoxesAccum_SVMscores', BBoxesAccum_SVMLabels');
            BBoxSVM.Properties.VariableNames = {'BBox', 'Scores' , 'Labels'};
        
        case 'classifier_bypass'
            BBoxANN = table(BBoxesAccum_ANN', BBoxesAccum_ANNscores', BBoxesAccum_ANNLabels');
            BBoxANN.Properties.VariableNames = {'BBox', 'Scores', 'Labels'};
    
            BBoxKNN = table(BBoxesAccum_KNN', BBoxesAccum_KNNscores', BBoxesAccum_KNNLabels');
            BBoxKNN.Properties.VariableNames = {'BBox', 'Scores', 'Labels'};
    
            BBoxSVM = table(BBoxesAccum_SVM', BBoxesAccum_SVMscores', BBoxesAccum_SVMLabels');
            BBoxSVM.Properties.VariableNames = {'BBox', 'Scores' , 'Labels'};
    end
                
    
    
    % Semantic segmentation GTs
    % Create a pixel label datastore holding the ground truth pixel labels for the test images.
    testLabelsDir_crack_ANN     = fullfile(input.PixLabelsFolder, num2str(workerID), 'crack', 'ANN');
    testLabelsDir_crack_KNN     = fullfile(input.PixLabelsFolder, num2str(workerID), 'crack', 'KNN');
    testLabelsDir_crack_SVM     = fullfile(input.PixLabelsFolder, num2str(workerID), 'crack', 'SVM');
    
    testLabelsDir_noncrack_ANN  = fullfile(input.PixLabelsFolder, num2str(workerID), 'non-crack', 'ANN');
    testLabelsDir_noncrack_KNN  = fullfile(input.PixLabelsFolder, num2str(workerID), 'non-crack', 'KNN');
    testLabelsDir_noncrack_SVM  = fullfile(input.PixLabelsFolder, num2str(workerID), 'non-crack', 'SVM');
    
    switch input.Algorithm_TYPE
        case 'hybrid_hessian'
            dest_path = fullfile(input.montage_dir_path, input.montage_dir{1}, 'Predict', 'Hessian', input.montage_dir{2});
        case 'hybrid_MFAT'
            dest_path = fullfile(input.montage_dir_path, input.montage_dir{1}, 'Predict', 'MFAT', input.montage_dir{2});
        case 'morpho'
            dest_path = fullfile(input.montage_dir_path, input.montage_dir{1}, 'Predict', 'Morpho', input.montage_dir{2});
    end
    status = copyfile(testLabelsDir_crack_ANN,dest_path);

    switch input.ImagesType
        case 'crack_only'
            % Pixel outputs
            ssmPixCracksnNoncracks_ANN = pixelLabelDatastore(testLabelsDir_crack_ANN,...
                                                                 input.classNames,input.labelIDs);
            ssmPixCracksnNoncracks_KNN = pixelLabelDatastore(testLabelsDir_crack_KNN,...
                                                                 input.classNames,input.labelIDs);
            ssmPixCracksnNoncracks_SVM = pixelLabelDatastore(testLabelsDir_crack_SVM,...
                                                                 input.classNames,input.labelIDs);
    
        case 'crackANDnoncracks'
            % Pixel outputs
            ssmPixCracksnNoncracks_ANN = pixelLabelDatastore({testLabelsDir_crack_ANN, testLabelsDir_noncrack_ANN},...
                                                                 input.classNames,input.labelIDs);
            ssmPixCracksnNoncracks_KNN = pixelLabelDatastore({testLabelsDir_crack_KNN, testLabelsDir_noncrack_KNN},...
                                                                 input.classNames,input.labelIDs);
            ssmPixCracksnNoncracks_SVM = pixelLabelDatastore({testLabelsDir_crack_SVM, testLabelsDir_noncrack_SVM},...
                                                                 input.classNames,input.labelIDs);
    end
    
    % Semantic segmentation GTs for ROC/PR curves     
    PixGT               = double(horzcat(SSM_GTFlatten{:}))';
    PredictScoresSSMANN = horzcat(SSM_ANNFlatten{:})';
    PredictScoresSSMKNN = horzcat(SSM_KNNFlatten{:})';
    PredictScoresSSMSVM = horzcat(SSM_SVMFlatten{:})';
end

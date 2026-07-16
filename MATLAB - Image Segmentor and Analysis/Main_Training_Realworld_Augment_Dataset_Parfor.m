%//%************************************************************************%
%//%*                              Ph.D                                    *%
%//%*                         Project SynCRACK						       *%
%//%*                                                                      *%
%//%*             Name: Preetham Manjunatha               		           *%
%//%*             USC Email: aghalaya@usc.edu                              *%
%//%*             Submission Date: --/--/----                              *%
%//%************************************************************************%
%//%*             Viterbi School of Engineering,                           *%
%//%*             Sonny Astani Dept. of Civil Engineering,                 *%
%//%*             University of Southern california,                       *%
%//%*             Los Angeles, California.                                 *%
%//%************************************************************************%

%% Start parameters
%--------------------------------------------------------------------------
clear; close all; clc;
if(isempty(gcp('nocreate')))
    parpool();
end
Start = tic;
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);

%% Inputs
%--------------------------------------------------------------------------

% Callback
MainInputs_Training_Realworld_Augment_Dataset;

% Add MAT files folder
addpath('../MAT Files', '../MATLAB - Crackmasks')

%% Pre-processing steps
%--------------------------------------------------------------------------
% Image superresolution

% Create image sets
if (train_inpstruct.flagswitch && ~ exist(train_inpstruct.trainImgs_filename,'file'))
    
    real_crack_Imgs = [];
    % Real crack images 
    parfor i = 1:length(train_inpstruct.imgFolder)
        real_crack_Imgs_i = dir(train_inpstruct.imgFolder{i});
        real_crack_Imgs_i = real_crack_Imgs_i(~ismember({real_crack_Imgs_i.name},{'.','..'}));
        real_crack_Imgs = [real_crack_Imgs; real_crack_Imgs_i];
    end
    
    save(train_inpstruct.trainImgs_filename, 'real_crack_Imgs');
else    
    load(train_inpstruct.trainImgs_filename);
end

%% Cluster cracks
%--------------------------------------------------------------------------
% Segregate images by the cracks strands (branch points)
% clusterCracksStrands(inpstruct, real_crack_Imgs);

%% Augment and clean real-world cracks
%--------------------------------------------------------------------------
% augmentCracks(inpstruct, real_crack_Imgs);

% Delete empty files
% deleteEmptyImages(inpstruct);

% Binarize images
% binarizeImages(inpstruct);

% Clear orphan blobs
% orphanBlobsRemoveImages(inpstruct);

%% Processing step
%--------------------------------------------------------------------------
% Extract training feature matrix and class labels
%--------------------------------------------------------------------------
if (inpstruct.flagswitch && ...
        ~ exist(inpstruct.processed_FMatLab_filename,'file'))
    % Images        
    images = dir(inpstruct.AugmentImgsSavePath);
    images = images(3:end);
    inpstruct.real_crack = images;

    % Extract feature matrix and labels
    IM_info = largeFeaturematrixNlabelsRealworldData2025(inpstruct);
    
    % Concatenate feature, label and tagget matrix for training
    Featuremat = cat(1,IM_info.featureMat);
%     Featuremat = unique(Featuremat,'stable','rows');

    % Standardize the feature matix for training
    Featuremat_std = zscore(Featuremat);

    % Label vetor for traning
    Labelmat   = grp2idx(cat(1,cat(1,IM_info.labelMat)));
    
    % Save Feature_matrix, Labelmat, Featuremat_std
    save(inpstruct.processed_FMatLab_filename,'Featuremat','Featuremat_std', 'Labelmat', 'IM_info');
else
    load(inpstruct.processed_FMatLab_filename);

end

%% Read mat file concatenate for the blobs feature matrix and labels
%
noncrackLabel = 1;
crackLabel = 2;

%{
saveOutputConcCracksFMMatFilename = 'ZZZ_FeatMAT_5JahanFeat_Realworld+elasticDefAug+synthetic_cracksOnly.mat';
findUniqueIdx = 3;

inputMatFilenames = {'ZZZ_FeatMAT_5JahanFeat_Labels_Realworld_Traincracks_AllDS.mat',...
'ZZZ_FeatMAT_5JahanFeat_Realworld_elasticDefAug_cracksOnly.mat',...
'ZZZ_FeatMAT_5JahanFeat_elastic_hessian_combo_JahanSynRot5_90_v1_1280_720.mat'};
concatenateCracksFM(inputMatFilenames, saveOutputConcCracksFMMatFilename, findUniqueIdx, crackLabel)
%}

realworld_train_FML = load('ZZZ_FeatMAT_5JahanFeat_Realworld+elasticDefAug+synthetic_cracksOnly.mat');
realworld_val_FML = load('ZZZ_FeatMAT_5JahanFeat_Labels_Realworld_Valcracks_AllDS.mat');


% hessian_mfat_morpho_wholeData_matfile = 'ZZZ_FeatMAT_5JahanFeat_elastic_hessian_combo_JahanSynRot5_90_v1_1280_720.mat';
% hessian_mfat_morpho_wholeData_matfile = 'ZZZ_FeatMAT_5JahanFeat_elastic_mfat_combo_JahanSynRot5_90_v1_1280_720.mat';
hessian_mfat_morpho_wholeData_matfile = 'ZZZ_FeatMAT_5JahanFeat_elastic_morpho_combo_JahanSynRot5_90_v1_1280_720.mat';

save_Train_matfile = 'ZZZ_FeatMAT_5JahanFeat_morpho_Realworld+elasticDefAug+synthetic_Train_crack_noncrack.mat';
save_Val_matfile = 'ZZZ_FeatMAT_5JahanFeat_morpho_Realworld+elasticDefAug+synthetic_Val_crack_noncrack.mat';

hessian_mfat_morpho_wholeData  = load(hessian_mfat_morpho_wholeData_matfile);
combineCrackNoncrackFML(realworld_train_FML, realworld_val_FML, hessian_mfat_morpho_wholeData, ...
                                    save_Train_matfile, save_Val_matfile, noncrackLabel);
%}

%
%% Extract unique rows train data
realworld_train_FML_cnc = load('ZZZ_FeatMAT_5JahanFeat_morpho_Realworld+elasticDefAug+synthetic_Train_crack_noncrack.mat');
saveUnqMatfile = 'ZZZ_Train_5JahanFeatMatLabels_morpho_Realworld+elasticDefAug+synthetic_Train_AllDS.mat';
uniqueCrackNoncrackFML(realworld_train_FML_cnc, noncrackLabel, crackLabel,  ...
                                    saveUnqMatfile, inpstruct)

%% Extract unique rows val data
realworld_val_FML_cnc = load('ZZZ_FeatMAT_5JahanFeat_morpho_Realworld+elasticDefAug+synthetic_Val_crack_noncrack.mat');
saveUnqMatfile = 'ZZZ_Train_5JahanFeatMatLabels_morpho_Realworld+elasticDefAug+synthetic_Val_AllDS.mat';
uniqueCrackNoncrackFML(realworld_val_FML_cnc, noncrackLabel, crackLabel,  ...
                                    saveUnqMatfile, inpstruct)

%% Split final feature matrices, labels and target matrices
if (inpstruct.PrepareData2Classifier)
    fmltTrain = load('ZZZ_Train_5JahanFeatMatLabels_morpho_Realworld+elasticDefAug+synthetic_Train_AllDS.mat');
    fmltVal = load('ZZZ_Train_5JahanFeatMatLabels_morpho_Realworld+elasticDefAug+synthetic_Val_AllDS.mat');

    [Xtrain,Xval,Xtest,Ytrain,Yval,Ytest,Targettrain,Targetval,Targettest]...
        = deal(fmltTrain.Feature_matrix, fmltVal.Feature_matrix, [], ...
           fmltTrain.LabelsVector, fmltVal.LabelsVector, [], ...
           fmltTrain.TargetMatrix, fmltVal.TargetMatrix, []);
            
    inpstruct.final_XYmat_labels = 'ZZZ_XYTargets5JahanFeat_morpho_Realworld+elasticDefAug+synthetic.mat';

    save (inpstruct.final_XYmat_labels, 'Xtrain', 'Xval', 'Xtest', 'Ytrain', 'Yval', 'Ytest', ...
        'Targettrain', 'Targetval', 'Targettest');
end
%}

%% End parameters
%--------------------------------------------------------------------------
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
Runtime = toc(Start);

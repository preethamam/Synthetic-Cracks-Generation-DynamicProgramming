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
MainInputs_Training_SynPlusReal_Dataset;

% Add MAT files folder
addpath('../MAT Files')

%% Pre-processing steps
%--------------------------------------------------------------------------
% Image superresolution

% Create image sets
if (train_inpstruct.flagswitch && ~ exist(train_inpstruct.traimImgs_filename,'file'))
    
    % Non-crack images
    non_crack_Imgs = [];
    parfor i = 1:length(train_inpstruct.imgFolder)
        non_crack_Imgs_i = dir(fullfile(train_inpstruct.imgFolder{i}, train_inpstruct.Traindata_folders_noncracks{i}));
        non_crack_Imgs_i = non_crack_Imgs_i(~ismember({non_crack_Imgs_i.name},{'.','..'}));
        non_crack_Imgs = [non_crack_Imgs; non_crack_Imgs_i];
    end
    
    syn_crack_Imgs = [];
    % Synthetic-crack images 
    parfor i = 1:length(train_inpstruct.synimgFolder)
        syn_crack_Imgs_i = dir(fullfile(train_inpstruct.synimgFolder{i}, train_inpstruct.Traindata_folders_syncracks{i}));
        syn_crack_Imgs_i = syn_crack_Imgs_i(~ismember({syn_crack_Imgs_i.name},{'.','..'}));
        syn_crack_Imgs = [syn_crack_Imgs; syn_crack_Imgs_i];
    end
    
    save(train_inpstruct.traimImgs_filename, 'non_crack_Imgs', 'syn_crack_Imgs');
else    
    load(train_inpstruct.traimImgs_filename);
end

%% Processing step
%--------------------------------------------------------------------------
% Extract training feature matrix and class labels
%--------------------------------------------------------------------------
if (inpstruct.flagswitch && ...
        ~ exist(inpstruct.processed_FMatLab_filename,'file'))
    % Images
    inpstruct.non_crack = non_crack_Imgs;
    
    inpstruct.syn_crack = syn_crack_Imgs;

    % Extract feature matrix and labels
    IM_info = largeFeaturematrixNlabels2025(inpstruct,jahan_inpstruct);
    
    % Concatenate feature, label and tagget matrix for training
    Featuremat = cat(1,IM_info.featureMat);

%     Featuremat = unique(Featuremat,'stable','rows');

    % Standardize the feature matix for training
    Featuremat_std = zscore(Featuremat);

    % Label vetor for traning
    Labelmat   = grp2idx(cat(1,cat(1,IM_info.labelMat)));
    
    % Save Feature_matrix, Labelmat, Featuremat_std
    save(inpstruct.processed_FMatLab_filename,'Featuremat','Featuremat_std', 'Labelmat');
else
    load(inpstruct.processed_FMatLab_filename);

end

% Read old mat file concatenate for the blobs feature matrix and labels
%{
if (inpstruct.flagswitch && ...
        ~ exist(inpstruct.processed_FMatLab_filename_conc,'file'))
    
    hybrid_oldData  = load ('ZZZ_FeatMAT_5JahanFeat_Labels_Raw_rot5_90_JahanSyn_hybrid.mat');
    idx = find(hybrid_oldData.Labelmat == 1);

    Featuremat_conc = [hybrid_oldData.Featuremat(idx,:); Featuremat];
    Featuremat_std_conc = [hybrid_oldData.Featuremat_std(idx,:); Featuremat_std];
    Labelmat_conc   = [hybrid_oldData.Labelmat(idx); 2*ones(length(Featuremat),1) ];

    save(inpstruct.processed_FMatLab_filename_conc,...
        'Featuremat_conc','Featuremat_std_conc', 'Labelmat_conc');
else
    load(inpstruct.processed_FMatLab_filename_conc);
end
%}

% Read old mat file concatenate for the blobs feature matrix and labels
% (combined JahanSync_rot5_90 + hybrid v1 + 1280_720

if (inpstruct.flagswitch && ...
        ~ exist(inpstruct.processed_FMatLab_filename_conc,'file'))
    
    hybrid_oldData  = load('ZZZ_FeatMAT_5JahanFeat_Labels_Raw_rot5_90_JahanSyn_hessian.mat');
    idx_crack_hybrid_oldData    = find(hybrid_oldData.Labelmat == 2);
    
    hybrid_v1Data   = load('ZZZ_FeatMAT_5JahanFeat_elastic_hessian.mat');
    idx_crack_hybrid_v1Data     = find(hybrid_v1Data.Labelmat == 1);
    
    hybrid_1280_720 = load('ZZZ_FeatMAT_5JahanFeat_elastic_hessian_1280_720_non_cracks_480pix.mat');
    idx_crack_hybrid_1280_720       = find(hybrid_1280_720.Labelmat == 2);
    
    Featuremat_conc     = [Featuremat; ...
                           hybrid_oldData.Featuremat(idx_crack_hybrid_oldData,:); hybrid_v1Data.Featuremat(idx_crack_hybrid_v1Data,:); ...
                           hybrid_1280_720.Featuremat(idx_crack_hybrid_1280_720,:)];
                       
    Featuremat_std_conc = [Featuremat_std; ...
                           hybrid_oldData.Featuremat_std(idx_crack_hybrid_oldData,:); hybrid_v1Data.Featuremat_std(idx_crack_hybrid_v1Data,:); ...
                           hybrid_1280_720.Featuremat_std(idx_crack_hybrid_1280_720,:)];
                       
    Labelmat_conc       = [Labelmat; ...
                           hybrid_oldData.Labelmat(idx_crack_hybrid_oldData);  2*ones(length(hybrid_v1Data.Featuremat),1);...
                           hybrid_1280_720.Labelmat(idx_crack_hybrid_1280_720)];

    save(inpstruct.processed_FMatLab_filename_conc,...
        'Featuremat_conc','Featuremat_std_conc', 'Labelmat_conc', '-v7.3');
else
    load(inpstruct.processed_FMatLab_filename_conc);
end

%% Extract unique rows
noncrackIndxs = find(Labelmat_conc == 1);
crackIndxs = find(Labelmat_conc == 2);

noncracksUnique = unique(Featuremat_conc(noncrackIndxs,:),'stable','rows');
cracksUnique = unique(Featuremat_conc(crackIndxs,:),'stable','rows');

Featuremat_conc_unique = [noncracksUnique; cracksUnique];
Labelmat_conc_unique = [ones(length(noncracksUnique),1); 2*ones(length(cracksUnique),1)];

samples = min(length(noncracksUnique), length(cracksUnique));

%% Making dataset for training, validation and testing
% Samples numbers limit
inpstruct.nosamp = 'number'; % 'full' 'percentage' 'number'

% Applicable to percent [0 to 1] | number [1 to max length of array]
inpstruct.sample_percent_number = 1937558;  % 1937558

if (inpstruct.flagswitch && ...
        ~ exist(inpstruct.shuffled_FMatLab_filename,'file'))
    
    % Shuffle feature matrix and label vector acccordingly
    [ Feature_matrix, LabelsVector, TargetMatrix, indexMap ] = ...
    shuffleFeatMatLabel( Featuremat_conc_unique, Labelmat_conc_unique, inpstruct);
    
    % Save IM_info, Feature_matrix, LabelsVector, TargetMatrix, indexMap
    save(inpstruct.shuffled_FMatLab_filename, 'Feature_matrix', 'LabelsVector', 'TargetMatrix', 'indexMap')
else
    load(inpstruct.shuffled_FMatLab_filename);
end

%% Split final feature matrices, labels and target matrices
if (inpstruct.PrepareData2Classifier)
    [Xtrain,Xval,Xtest,Ytrain,Yval,Ytest,Targettrain,Targetval,Targettest]...
        = SplitDataLabels(Feature_matrix,LabelsVector,TargetMatrix,inpstruct);

    save (inpstruct.final_XYmat_labels, 'Xtrain', 'Xval', 'Xtest', 'Ytrain', 'Yval', 'Ytest', ...
        'Targettrain', 'Targetval', 'Targettest');
end

%% End parameters
%--------------------------------------------------------------------------
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
Runtime = toc(Start);

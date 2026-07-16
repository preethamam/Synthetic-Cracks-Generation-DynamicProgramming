
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Training data parameters

%--------------------------------------------------------------------------
% Read training folder
%--------------------------------------------------------------------------
train_inpstruct.flagswitch    = 0;   %[0-off | 1-on]

%--------------------------------------------------------------------------
% Folder paths for non-cracks and synthetic cracks
%--------------------------------------------------------------------------
train_inpstruct.imgFolder     =  '';
%--------------------------------------------------------------------------
% Provide names of original training data folders (include name of the folder even its folder
% is empty)
%--------------------------------------------------------------------------
train_inpstruct.Traindata_folders    = {};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Texture feature vector params

%--------------------------------------------------------------------------
% Shuffle flag
%--------------------------------------------------------------------------
texturefeature_inpstruct.flag_texturefeatures    = 1;   %[0-off | 1-on]

%--------------------------------------------------------------------------
% Texture filter
%--------------------------------------------------------------------------
% laws - Laws multi-channel filter (level, edge, spot, wave and ripple)
% sfta - Segmentation-based Fractal Texture Analysis
texturefeature_inpstruct.texturefilter_type      = 'laws';

%--------------------------------------------------------------------------
% GPU array
%--------------------------------------------------------------------------
% yes - creates GPU array (note: works for certain Matlab functions)
% no  - non GPU array
texturefeature_inpstruct.gpuarray                = 'no';

%--------------------------------------------------------------------------
% Norm type
%--------------------------------------------------------------------------
% L1        - L1 norm
% L2        - l2 norm
% infinity  - infinity norm
% frobenius - frobenius norm
texturefeature_inpstruct.normtype                = 'L2';

%--------------------------------------------------------------------------
% Window size (energy)
%--------------------------------------------------------------------------
% n    - odd integer value (such as 3, 5, 7, 11, 13, 15, 17, ...)
texturefeature_inpstruct.windowsize              = 5;

%--------------------------------------------------------------------------
% Provide names of original data folders (include name of the folder even its folder
% is empty)
%--------------------------------------------------------------------------
texturefeature_inpstruct.originaldata_folders    = {'Testing Cracks'};

%--------------------------------------------------------------------------
% Data folder path
%--------------------------------------------------------------------------
texturefeature_inpstruct.folderpath_texture = '..\..\data\Testing\Dataset VII (Liu)';

%--------------------------------------------------------------------------
% Data set type
% training | testing
%--------------------------------------------------------------------------
texturefeature_inpstruct.datasetType              = 'testing';

%--------------------------------------------------------------------------
% Cluster images copy/paste shuffle flag
%--------------------------------------------------------------------------
texturefeature_inpstruct.flag_clusterImcpyPaste   = 0;   %[0-off | 1-on]

% Texture data saving mat file
texturefeature_inpstruct.matFilename = 'ZZZ_texture_testing_Dataset_VII.mat';

% Texture plots saving folder location
texturefeature_inpstruct.plot_folder_location = '..\..\results\Texture Plots';

% Texture contrast type
texturefeature_inpstruct.contrast_type        = 'none';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Testing parameters

%--------------------------------------------------------------------------
% Jahanshahi Inputs
%--------------------------------------------------------------------------
jahan_inpstruct.nmin = 1; %pixel-1; %1;       % minimum crack size in pixel (after transformation)
jahan_inpstruct.nmax = 120; %pixel-%120;      % maximum crack size in pixel (after transformation)
jahan_inpstruct.nstep = 5; %pixel-%5;
% Crack structural length
jahan_inpstruct.crackLEN = jahan_inpstruct.nmin+2 : jahan_inpstruct.nstep : jahan_inpstruct.nmax+10;  % options:  [1 : max(size(image))] 

% Angle between
jahan_inpstruct.anglebetween = [0 45 90 135]; % [0 : delta : 179], use symmetry
jahan_inpstruct.SElength = 'imageDimBased'; % 'imageDimBased' | 'default' (uses the above definition)
jahan_inpstruct.SElength_percent = 0.25;
%--------------------------------------------------------------------------
% File details
%--------------------------------------------------------------------------
textFileName = 'pp_hybrid_morpho_marathon_Liu'; % use custom name and .txt to bypass serial incrementer
if ismac
    
elseif isunix
    textFolder = '../Results/Text Files';
    figFolder  = '../Results/Figures';
    matFolder  = '../Results/Mat Files';
elseif ispc
    textFolder = '..\Results\Text Files';
    figFolder  = '..\Results\Figures';
    matFolder  = '..\Results\Mat Files'; %pp_hybrid_morpho_marathon_1_57_testdummy_HybridMorpho_imclose_on
else
    disp('Platform not supported')
end

hybrid_inpstruct.timeFilename = 'ZZZ_DS7_timestamps_June092021';

%--------------------------------------------------------------------------
% Shuffle flag
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
% Algorithm type
%--------------------------------------------------------------------------
% anisotrpic Hessian   - 'hybrid'
% morphological method - 'morpho'

Algorithm_TYPE          = {'hybrid_hessian', 'hybrid_MFAT', 'morpho'};
hybrid_inpstruct.searchType = 'single_search';  % 'single_search' | 'grid_search'

%--------------------------------------------------------------------------
% Algorithm processing type
%--------------------------------------------------------------------------
% anisotrpic Hessian   - 'sequential'
% morphological method - 'parallel'
hybrid_inpstruct.parallel_sequential_processing = 'parallel';

%--------------------------------------------------------------------------
% Classifier required to filter blobs
%--------------------------------------------------------------------------
% anisotrpic Hessian   - 'classifier'
% morphological method - 'classifier_bypass'

hybrid_inpstruct.classifier_required = 'classifier';

% Label matrix generator type
hybrid_inpstruct.labelMatixType = 'testing';

% Post-processing using circularity index
hybrid_inpstruct.postprocess = 0; % 0 - none | 1 - all | 2 - stage 1 filters
hybrid_inpstruct.circularity_threshold = [0.02 0.3];
hybrid_inpstruct.post_process_Type = 'circularity'; % 'circularity' | 'circ_branchpoint_holes'

% For train and test data
hybrid_inpstruct.flagswitch              = 0;   %[0-off | 1-on]

% For train and test data
hybrid_inpstruct.PrepareData2Classifier  = 0;   %[0-off | 1-on]

% For train and test data
hybrid_inpstruct.trainValTest            = [0.8 0.0 0.2];   %[0-off | 1-on]

% Save feature matrix and labels in image info structure (as a variable).
% Else store n samples in sequential .mat files
hybrid_inpstruct.savefeaturematrixNlabels ...
                                         = 1;   %[0-off | 1-on]    

% Post processing
hybrid_inpstruct.imclosing = 0;  % 0-off | 1-on
hybrid_inpstruct.imclose_disk_size = 5; % Morphological disk size
hybrid_inpstruct.branchpoints = 3;
hybrid_inpstruct.boundary_smooth = 0; % 0 - none | 1 - morphClose | 2 - kernel
hybrid_inpstruct.windowSize = 25; % Kernel size

% ROC plot inputs
hybrid_inpstruct.ROC_TYPE    = 'pre_recall'; % pre_recall | true_false
hybrid_inpstruct.TRAIN_TEST  = 'testing';    % training | testing
hybrid_inpstruct.PR_ROC_CURVE_METHOD  = 'SEMANTIC_SEG';     
% 'IMAGE_CLASSIFICATION' % 'ALL_IMAGE_CONNECTED_COMPONENTS' 
% | 'MATLAB_BBox' | 'SEMANTIC_SEG'

%--------------------------------------------------------------------------
% Turn on/off adaptive histogram
%--------------------------------------------------------------------------
% adaphist - adaptive histogram
% image_adjust - imadjust
% hist_equi - histogram equalization
% none
hybrid_inpstruct.contrast_type                = 'image_adjust';

%--------------------------------------------------------------------------
% Image patch size
%--------------------------------------------------------------------------
hybrid_inpstruct.blockSizeR              = 122400;
hybrid_inpstruct.blockSizeC              = 122400;

%--------------------------------------------------------------------------
% Image resize for too large images
%--------------------------------------------------------------------------
hybrid_inpstruct.resizeImage = 'no';
hybrid_inpstruct.maxImageResizePixels = 700;
hybrid_inpstruct.resizeImageSize = [];
hybrid_inpstruct.resizeImageSizeScale = 0.25;

%--------------------------------------------------------------------------
% Crack/non-crack decider parameters
%--------------------------------------------------------------------------
hybrid_inpstruct.non_crack_class         = 1;
hybrid_inpstruct.crack_class             = 2;
hybrid_inpstruct.CC_overlap_percent      = 0.5;
hybrid_inpstruct.BBoxthreshold           = 0.5;

%--------------------------------------------------------------------------
% Store algorithm output images
% on = 1
% off = 0
%--------------------------------------------------------------------------
hybrid_inpstruct.storeOutputImages  = 0;

%--------------------------------------------------------------------------
% Training data folder path
%--------------------------------------------------------------------------
hybrid_inpstruct.folderpath              = '';
if ismac
    
elseif isunix
    hybrid_inpstruct.filesavepath            = '/media/preethamam/Utilities-SSD';
elseif ispc
    hybrid_inpstruct.filesavepath            = 'D:\';
else
    disp('Platform not supported')
end
hybrid_inpstruct.storeFolderName         = 'Crackoutputs hybrid-morpho DS Liu';

%--------------------------------------------------------------------------
% Crack Debrancher inputs
%--------------------------------------------------------------------------
hybrid_inpstruct.crackDebrancher_required = 'no'; % 'yes' | 'no'
hybrid_inpstruct.thinPruneMethod = 'alex';  % 'conventional' | 'alex'
hybrid_inpstruct.thinPruneThresh = 0.15; % [0 1]
hybrid_inpstruct.branchlengthThreshold = 35;

%--------------------------------------------------------------------------
% Figure show and save mat files
%--------------------------------------------------------------------------
hybrid_inpstruct.figShow_debranch   = 'no';     % 'yes' | 'no'
hybrid_inpstruct.figShow_visLabels  = 'no';     % 'yes' | 'no'
hybrid_inpstruct.figShow_TPFPFN     = 'no';     % 'yes' | 'no'
hybrid_inpstruct.figShow_ROCCurves  = 'no';    % 'yes' | 'no'
hybrid_inpstruct.show_ROC_curve_title = 0; % on-1 | off - 0
hybrid_inpstruct.save_mat_file = 0; % on-1 | off - 0

%--------------------------------------------------------------------------
% Semantic segmentation inputs
%--------------------------------------------------------------------------
% Pixels result folder
if ismac
    
elseif isunix
    hybrid_inpstruct.PixLabelsFolder = '/media/preethamam/Utilities-SSD/Xtreme_Programming/Preetham/MATLAB/Dataset Predicts/DS 7 Pixel Labels';
elseif ispc
    hybrid_inpstruct.PixLabelsFolder = 'D:\Xtreme_Programming\Preetham\MATLAB\Dataset Predicts\DS Liu Pixel Labels';
else
    disp('Platform not supported')
end


% Define the class names and their associated label IDs.
% Class names
hybrid_inpstruct.classNames = ["crack","noncrack"];
hybrid_inpstruct.ImagesType = 'crack_only'; % 'crack_only' | 'crackANDnoncracks'

% Label colors
hybrid_inpstruct.labelIDs = [1, 0];
hybrid_inpstruct.ssmVerbose = 0;

%--------------------------------------------------------------------------
% Provide names of groundtruth folders (include pseudoname even if ground-truth doesn't 
% exist for a original folder, e.g. nocrack --> ground_nocrack. Also if the folder
% is empty)
%--------------------------------------------------------------------------
hybrid_inpstruct.groundtruth_folders     = {}; %{'CrackG', 'Non_Crack'};

%--------------------------------------------------------------------------
% Provide names of original data folders (include name of the folder even its folder
% is empty)
%--------------------------------------------------------------------------
hybrid_inpstruct.originaldata_folders    = {};

%--------------------------------------------------------------------------
% GPU array
%--------------------------------------------------------------------------
% yes - creates GPU array (note: works for certain Matlab functions)
% no  - non GPU array
hybrid_inpstruct.gpuarray                = 'no';

%--------------------------------------------------------------------------
% Colorspace segmentation options 
%--------------------------------------------------------------------------
% Type of colorspace to segment RGB ground-truths
% HSV (recommended) or RGB
hybrid_inpstruct.colorspace = 'hsv';  %[hsv | rgb]

% RGB startindex
% n   - channel value (integer [0, 255])
hybrid_inpstruct.RGBstartindex           = 235;

% GT label color
hybrid_inpstruct.GTcolor_TYPE = 'binary';   %[color | binary]

% Grid/seatrch of hyper parameters
if (strcmp(hybrid_inpstruct.searchType,'single_search'))
    %--------------------------------------------------------------------------
    % Anisotropic diffusion parameters
    %--------------------------------------------------------------------------
    % Stage I and Stage II
    hybrid_Frangi_gridsearch.aniso_num_iter1 = 0; %:5:10; %:10:100; %0:5:10;%:100; %0:100; %[5 5]  % 15 [5 good]
    hybrid_Frangi_gridsearch.aniso_num_iter2 = 0;
    hybrid_Frangi_gridsearch.aniso_delta_t1  = 1/7;
    hybrid_Frangi_gridsearch.aniso_delta_t2  = 1/7;
    hybrid_Frangi_gridsearch.aniso_kappa1    = 15;
    hybrid_Frangi_gridsearch.aniso_kappa2    = 15;
    
    %--------------------------------------------------------------------------
    % Hessian matrix parameters
    %--------------------------------------------------------------------------
    % Frangi filter options
    hybrid_Frangi_gridsearch.frangiopt.FrangiScaleRange1 = 1; %pixel width - 0.5637; %1; %[3 10]
    hybrid_Frangi_gridsearch.frangiopt.FrangiScaleRange2 = 15; %pixel width -5.7652; %15; %[3 10]
    
    hybrid_Frangi_gridsearch.frangiopt.FrangiBetaOne    = 0.5; %0.5 [
    hybrid_Frangi_gridsearch.frangiopt.FrangiBetaTwo    = 25; %2 %15 10 [25, 75-275 good range captures cracks continously][higher --> extracts finely, lower --> cracks will be thicket too many FP]

else

    %--------------------------------------------------------------------------
    % Frangi filter Hessian matrix grid search parameters
    %--------------------------------------------------------------------------
    % Stage I and Stage II
    hybrid_Frangi_gridsearch.aniso_num_iter1 = 0:5:50; %:5:10; %:10:100; %0:5:10;%:100; %0:100; %[5 5]  % 15 [5 good]
    hybrid_Frangi_gridsearch.aniso_num_iter2 = 0;
    hybrid_Frangi_gridsearch.aniso_delta_t1  = 1/7;
    hybrid_Frangi_gridsearch.aniso_delta_t2  = 1/7;
    hybrid_Frangi_gridsearch.aniso_kappa1    = 15:5:50;
    hybrid_Frangi_gridsearch.aniso_kappa2    = 15;

    hybrid_Frangi_gridsearch.frangiopt.FrangiScaleRange1 = 1;
    hybrid_Frangi_gridsearch.frangiopt.FrangiScaleRange2 = 5:1:35;
    hybrid_Frangi_gridsearch.frangiopt.FrangiBetaOne     = 0.5;
    hybrid_Frangi_gridsearch.frangiopt.FrangiBetaTwo     = 50;
end

hybrid_inpstruct.aniso.option   = [3, 3];

hybrid_inpstruct.frangiopt.FrangiScaleRatio = 1; %1;
hybrid_inpstruct.frangiopt.BlackWhite       = 1;
hybrid_inpstruct.frangiopt.verbose          = 0;

% Put all vectors into cell array
allVecs = {hybrid_Frangi_gridsearch.aniso_num_iter1, hybrid_Frangi_gridsearch.aniso_num_iter2, hybrid_Frangi_gridsearch.aniso_delta_t1,...
                 hybrid_Frangi_gridsearch.aniso_delta_t2,hybrid_Frangi_gridsearch.aniso_kappa1,hybrid_Frangi_gridsearch.aniso_kappa2,...
                 hybrid_Frangi_gridsearch.frangiopt.FrangiScaleRange1, hybrid_Frangi_gridsearch.frangiopt.FrangiScaleRange2, ...
                 hybrid_Frangi_gridsearch.frangiopt.FrangiBetaOne, hybrid_Frangi_gridsearch.frangiopt.FrangiBetaTwo}; 
sub = cell(1,numel(allVecs));
[sub{:}] = ndgrid(allVecs{:});
sub = cellfun(@(x)x(:),sub,'UniformOutput', false);

% allPerms is [m x n] matrix of m permutations of n vectors
% m should equal prod(cellfun(@numel,allVecs))
% n should equal numel(allVecs)
hybrid_Frangi_search_allPerms = cell2mat(sub);  % it1,it2,delta1,delta2,kappa1,kappa2,FrangiScRng1,FrangiScRng2,FrangiBetaOne,FrangiBetaTwo
% hybrid_inpstruct.searchType = 'grid_search';  % 'single_search' | 'grid_search'

if (strcmp(hybrid_inpstruct.searchType,'single_search'))    
    %--------------------------------------------------------------------------
    % Anisotropic diffusion parameters
    %--------------------------------------------------------------------------
    % Stage I and Stage II
    hybrid_MFAT_gridsearch.aniso_num_iter1 = 0; %215; %430; % 430 %:5:10; %:10:100; %0:5:10;%:100; %0:100; %[5 5]  % 15 [5 good]
    hybrid_MFAT_gridsearch.aniso_num_iter2 = 0;
    hybrid_MFAT_gridsearch.aniso_delta_t1  = 1/7;
    hybrid_MFAT_gridsearch.aniso_delta_t2  = 1/7;
    hybrid_MFAT_gridsearch.aniso_kappa1    = 15;
    hybrid_MFAT_gridsearch.aniso_kappa2    = 15;
    
    %--------------------------------------------------------------------------
    % Multiscale fractional anisotropy  parameters
    %--------------------------------------------------------------------------
    % MFAT filter options
    hybrid_MFAT_gridsearch.MFAToptions.sigmas1       = 0.4246; %old-0.7181; %1;   
    hybrid_MFAT_gridsearch.MFAToptions.sigmas2       = 6.0601; %old-7.3443; %3:25;  4:0.25:
    hybrid_MFAT_gridsearch.MFAToptions.sigmasScaleRatio = 0.25; %0.25;
    hybrid_MFAT_gridsearch.MFAToptions.spacing       = 0.7; % 0.7
    hybrid_MFAT_gridsearch.MFAToptions.tau           = 0.25; 
    hybrid_MFAT_gridsearch.MFAToptions.tau2          = 0.5; 
    hybrid_MFAT_gridsearch.MFAToptions.D             = 0.5;
else
    %--------------------------------------------------------------------------
    % MFAT filter Hessian matrix grid search parameters
    %--------------------------------------------------------------------------
    hybrid_MFAT_gridsearch.aniso_num_iter1 = 0; %:5:10; %:10:100; %0:5:10;%:100; %0:100; %[5 5]  % 15 [5 good]
    hybrid_MFAT_gridsearch.aniso_num_iter2 = 0;
    hybrid_MFAT_gridsearch.aniso_delta_t1  = 1/7;
    hybrid_MFAT_gridsearch.aniso_delta_t2  = 1/7;
    hybrid_MFAT_gridsearch.aniso_kappa1    = 15;
    hybrid_MFAT_gridsearch.aniso_kappa2    = 15;    

    hybrid_MFAT_gridsearch.MFAToptions.sigmas1       = 1;
    hybrid_MFAT_gridsearch.MFAToptions.sigmas2       = 5;
    hybrid_MFAT_gridsearch.MFAToptions.sigmasScaleRatio = 1;
    hybrid_MFAT_gridsearch.MFAToptions.spacing       = 0.2 : 0.1 : 1.0; 
    hybrid_MFAT_gridsearch.MFAToptions.tau           = 0.25:0.05:0.5; 
    hybrid_MFAT_gridsearch.MFAToptions.tau2          = 0.35:0.05:0.5; 
    hybrid_MFAT_gridsearch.MFAToptions.D             = 0.4:0.05:0.8;
end

hybrid_inpstruct.MFAT_TYPE                 = 'ProbabilisticFAT';  % 'EigenFAT' | 'ProbabilisticFAT'
hybrid_inpstruct.MFAToptions.whiteondark   = false;

% Put all vectors into cell array
allVecs = {hybrid_MFAT_gridsearch.aniso_num_iter1, hybrid_MFAT_gridsearch.aniso_num_iter2, hybrid_MFAT_gridsearch.aniso_delta_t1,...
                 hybrid_MFAT_gridsearch.aniso_delta_t2,hybrid_MFAT_gridsearch.aniso_kappa1,hybrid_MFAT_gridsearch.aniso_kappa2,...
                 hybrid_MFAT_gridsearch.MFAToptions.sigmas1, hybrid_MFAT_gridsearch.MFAToptions.sigmas2, ...
                 hybrid_MFAT_gridsearch.MFAToptions.sigmasScaleRatio, hybrid_MFAT_gridsearch.MFAToptions.spacing, ...
                 hybrid_MFAT_gridsearch.MFAToptions.tau, hybrid_MFAT_gridsearch.MFAToptions.tau2, ...
                 hybrid_MFAT_gridsearch.MFAToptions.D}; 
sub = cell(1,numel(allVecs));
[sub{:}] = ndgrid(allVecs{:});
sub = cellfun(@(x)x(:),sub,'UniformOutput', false);

% allPerms is [m x n] matrix of m permutations of n vectors
% m should equal prod(cellfun(@numel,allVecs))
% n should equal numel(allVecs)
hybrid_MFAT_search_allPerms = cell2mat(sub);  % it1,it2,delta1,delta2,kappa1,kappa2,sigmas1,...
                                              % sigmas2,sigmasScaleRatio,spacing,
                                              % tau, tau2, D
                                              
                                              
%--------------------------------------------------------------------------
% Blob removal parameters
%--------------------------------------------------------------------------
% Blob filter standard deviation scale
hybrid_inpstruct.blobfilter_sigma    = 0.5; % 0.75 % 3 
hybrid_inpstruct.morpho_blob_size_area = 120;
hybrid_inpstruct.blobRemovalType = 'autoBlobRemoval'; % 'autoBlobRemoval' | 'areaPreDefined'

%--------------------------------------------------------------------------
% Data set type
% training | testing
%--------------------------------------------------------------------------
hybrid_inpstruct.datasetType              = 'testing';

%--------------------------------------------------------------------------
% Noisy/ground-truth images copy/paste shuffle flag
%--------------------------------------------------------------------------
hybrid_inpstruct.nsyGrndImcpyPaste        = 0;       %[0-off | 1-on]

%--------------------------------------------------------------------------
% Trained classifier files
%--------------------------------------------------------------------------
% 'million_unique_all' | 'unique_100000' | 'real_world'
% 'real_world_augmented_only' | 'real_world+augmented'
% 'real_world+augmented+synthetic'
hybrid_inpstruct.classfier_trained_model = 'real_world+augmented+synthetic';


switch hybrid_inpstruct.classfier_trained_model
    case 'million_unique_all'
        % Synthetic Combined unique feature vectors
        ANN_classifier_hessian = 'ZZZ_MdlANN_elastic_hessian_combo_JahanSynRot5_90_v1_1280_720_Unique.mat';
        KNN_classifier_hessian = 'ZZZ_MdlKNN_elastic_hessian_combo_JahanSynRot5_90_v1_1280_720_Unique.mat';
        SVM_classifier_hessian = 'ZZZ_MdlSVM_elastic_hessian_combo_JahanSynRot5_90_v1_1280_720_Unique.mat';
        
        ANN_classifier_mfat = 'ZZZ_MdlANN_elastic_mfat_combo_JahanSynRot5_90_v1_1280_720_Unique.mat';
        KNN_classifier_mfat = 'ZZZ_MdlKNN_elastic_mfat_combo_JahanSynRot5_90_v1_1280_720_Unique.mat';
        SVM_classifier_mfat = 'ZZZ_MdlSVM_elastic_mfat_combo_JahanSynRot5_90_v1_1280_720_Unique.mat';
        
        ANN_classifier_morpho = 'ZZZ_MdlANN_elastic_morpho_combo_JahanSynRot5_90_v1_1280_720_Unique.mat';
        KNN_classifier_morpho = 'ZZZ_MdlKNN_elastic_morpho_combo_JahanSynRot5_90_v1_1280_720_Unique.mat';
        SVM_classifier_morpho = 'ZZZ_MdlSVM_elastic_morpho_combo_JahanSynRot5_90_v1_1280_720_Unique.mat';

        hybrid_inpstruct.montage_dir = {'Liu', '01'};

    case 'unique_100000'
        % Synthetic Combined 100000 unique feature vectors        
        ANN_classifier_hessian = 'ZZZ_MdlANN_elastic_hessian_combo_JahanSynRot5_90_v1_1280_720_Unique_100000.mat';
        KNN_classifier_hessian = 'ZZZ_MdlKNN_elastic_hessian_combo_JahanSynRot5_90_v1_1280_720_Unique_100000.mat';
        SVM_classifier_hessian = 'ZZZ_MdlSVM_elastic_hessian_combo_JahanSynRot5_90_v1_1280_720_Unique_100000.mat';
        
        ANN_classifier_mfat = 'ZZZ_MdlANN_elastic_mfat_combo_JahanSynRot5_90_v1_1280_720_Unique_100000.mat';
        KNN_classifier_mfat = 'ZZZ_MdlKNN_elastic_mfat_combo_JahanSynRot5_90_v1_1280_720_Unique_100000.mat';
        SVM_classifier_mfat = 'ZZZ_MdlSVM_elastic_mfat_combo_JahanSynRot5_90_v1_1280_720_Unique_100000.mat';
        
        ANN_classifier_morpho = 'ZZZ_MdlANN_elastic_morpho_combo_JahanSynRot5_90_v1_1280_720_Unique_100000.mat';
        KNN_classifier_morpho = 'ZZZ_MdlKNN_elastic_morpho_combo_JahanSynRot5_90_v1_1280_720_Unique_100000.mat';
        SVM_classifier_morpho = 'ZZZ_MdlSVM_elastic_morpho_combo_JahanSynRot5_90_v1_1280_720_Unique_100000.mat';
        
        hybrid_inpstruct.montage_dir = {'Liu', '02'};

    case 'real_world'
        % Realworld Train and validation Combined (Jahanshahi + CDLN + Liu) with
        % non-cracks from Hessian, MFAT and Morpho
        ANN_classifier_hessian = 'ZZZ_MdlANN_hessian_Realworld.mat';
        KNN_classifier_hessian = 'ZZZ_MdlKNN_hessian_Realworld.mat';
        SVM_classifier_hessian = 'ZZZ_MdlSVM_hessian_Realworld.mat';
        
        ANN_classifier_mfat = 'ZZZ_MdlANN_mfat_Realworld.mat';
        KNN_classifier_mfat = 'ZZZ_MdlKNN_mfat_Realworld.mat';
        SVM_classifier_mfat = 'ZZZ_MdlSVM_mfat_Realworld.mat';
        
        ANN_classifier_morpho = 'ZZZ_MdlANN_morpho_Realworld.mat';
        KNN_classifier_morpho = 'ZZZ_MdlKNN_morpho_Realworld.mat';
        SVM_classifier_morpho = 'ZZZ_MdlSVM_morpho_Realworld.mat';
        
        hybrid_inpstruct.montage_dir = {'Liu', '03'};
    case 'real_world_augmented_only'
        % Realworld augmented Train and validation 
        % Combined (Jahanshahi + CDLN + Liu) with
        % non-cracks from Hessian, MFAT and Morpho
        ANN_classifier_hessian = 'ZZZ_MdlANN_hessian_Realworld_elasticDefAug.mat';
        KNN_classifier_hessian = 'ZZZ_MdlKNN_hessian_Realworld_elasticDefAug.mat';
        SVM_classifier_hessian = 'ZZZ_MdlSVM_hessian_Realworld_elasticDefAug.mat';
        
        ANN_classifier_mfat = 'ZZZ_MdlANN_mfat_Realworld_elasticDefAug.mat';
        KNN_classifier_mfat = 'ZZZ_MdlKNN_mfat_Realworld_elasticDefAug.mat';
        SVM_classifier_mfat = 'ZZZ_MdlSVM_mfat_Realworld_elasticDefAug.mat';
        
        ANN_classifier_morpho = 'ZZZ_MdlANN_morpho_Realworld_elasticDefAug.mat';
        KNN_classifier_morpho = 'ZZZ_MdlKNN_morpho_Realworld_elasticDefAug.mat';
        SVM_classifier_morpho = 'ZZZ_MdlSVM_morpho_Realworld_elasticDefAug.mat';
        
        hybrid_inpstruct.montage_dir = {'Liu', '04'};

    case 'real_world+augmented'
        % Realworld + elastic def. augmented data  Train and validation 
        % Combined (Jahanshahi + CDLN + Liu) with
        % non-cracks from Hessian, MFAT and Morpho
        ANN_classifier_hessian = 'ZZZ_MdlANN_hessian_Realworld+elasticDefAug.mat';
        KNN_classifier_hessian = 'ZZZ_MdlKNN_hessian_Realworld+elasticDefAug.mat';
        SVM_classifier_hessian = 'ZZZ_MdlSVM_hessian_Realworld+elasticDefAug.mat';
        
        ANN_classifier_mfat = 'ZZZ_MdlANN_mfat_Realworld+elasticDefAug.mat';
        KNN_classifier_mfat = 'ZZZ_MdlKNN_mfat_Realworld+elasticDefAug.mat';
        SVM_classifier_mfat = 'ZZZ_MdlSVM_mfat_Realworld+elasticDefAug.mat';
        
        ANN_classifier_morpho = 'ZZZ_MdlANN_morpho_Realworld+elasticDefAug.mat';
        KNN_classifier_morpho = 'ZZZ_MdlKNN_morpho_Realworld+elasticDefAug.mat';
        SVM_classifier_morpho = 'ZZZ_MdlSVM_morpho_Realworld+elasticDefAug.mat';
        
        hybrid_inpstruct.montage_dir = {'Liu', '05'};

    case 'real_world+augmented+synthetic'
        % Realworld + elastic def. augmented + synthetic data Train and validation 
        % Combined (Jahanshahi + CDLN + Liu) with
        % non-cracks from Hessian, MFAT and Morpho
        ANN_classifier_hessian = 'ZZZ_MdlANN_hessian_Realworld+elasticDefAug+synthetic.mat';
        KNN_classifier_hessian = 'ZZZ_MdlKNN_hessian_Realworld+elasticDefAug+synthetic.mat';
        SVM_classifier_hessian = 'ZZZ_MdlSVM_hessian_Realworld+elasticDefAug+synthetic.mat';
        
        ANN_classifier_mfat = 'ZZZ_MdlANN_mfat_Realworld+elasticDefAug+synthetic.mat';
        KNN_classifier_mfat = 'ZZZ_MdlKNN_mfat_Realworld+elasticDefAug+synthetic.mat';
        SVM_classifier_mfat = 'ZZZ_MdlSVM_mfat_Realworld+elasticDefAug+synthetic.mat';
        
        ANN_classifier_morpho = 'ZZZ_MdlANN_morpho_Realworld+elasticDefAug+synthetic.mat';
        KNN_classifier_morpho = 'ZZZ_MdlKNN_morpho_Realworld+elasticDefAug+synthetic.mat';
        SVM_classifier_morpho = 'ZZZ_MdlSVM_morpho_Realworld+elasticDefAug+synthetic.mat';

        hybrid_inpstruct.montage_dir = {'Liu', '06'};
    otherwise
        error('Require a valid classfier trained model.')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
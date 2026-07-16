
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Training data parameters

%--------------------------------------------------------------------------
% Read training folder
%--------------------------------------------------------------------------
train_inpstruct.flagswitch    = 1;   % [0-off | 1-on]

%--------------------------------------------------------------------------
% Folder paths for non-cracks and synthetic cracks
%--------------------------------------------------------------------------
train_inpstruct.imgFolder     =  {"H:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 1 - Cracks-200\Pixel Labels\train", ...
                                  "H:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 6 - Cracks-1K (448 x 252)\Pixel Labels\train", ...
                                  "H:\Project DLCRACK\External Datasets\Yahui Liu - DeepCrack\Pixel Labels\train_crack_bmp"};

% File to save
train_inpstruct.trainImgs_filename = 'ZZZ_Train_realworld_augment_images.mat';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Training and testing feature matrix and labels parameters

%--------------------------------------------------------------------------
% Shuffle flag
%--------------------------------------------------------------------------
% For train and test data
inpstruct.flagswitch              = 1;   %[0-off | 1-on]

% For train and test data
inpstruct.PrepareData2Classifier  = 1;   %[0-off | 1-on]

% For train and test datainpstruct
inpstruct.trainValTest            = [0.7 0.05 0.25];   % [Train | Val | test]

% Parfor chunk size
inpstruct.chunk_size = 1e5;

% Save feature matrix and labels in image info structure (as a variable)
% Else store n samples in sequential .mat files
inpstruct.savefeaturematrixNlabels ...
                                         = 1;   %[0-off | 1-on]
% Samples numbers limit
inpstruct.nosamp = 'full'; % 'full' 'percentage' 'number'

% Applicable to percent [0 to 1] | number [1 to max length of array]
inpstruct.sample_percent_number = 0.50;

% Label matrix generator type
inpstruct.labelMatixType = 'training';
                                                
%--------------------------------------------------------------------------
% Turn on/off adaptive histogram
%--------------------------------------------------------------------------
% adaphist - adaptive histogram
% image_adjust - imadjust
% hist_equi - histogram equalization
inpstruct.contrast_type                = 'imadjust';

%--------------------------------------------------------------------------
% Debrancher and show labels
%--------------------------------------------------------------------------
inpstruct.crackDebrancher_required     = 'no';
inpstruct.figShow_visLabels = 'no';

%--------------------------------------------------------------------------
% Image resize for too large images
%--------------------------------------------------------------------------
inpstruct.resizeImage = 'no'; % 'yes' | 'no'
inpstruct.maxImageResizePixels = 700;
inpstruct.resizeImageSize = [];
inpstruct.resizeImageSizeScale = 0.25;

%--------------------------------------------------------------------------
% Image patch size
%--------------------------------------------------------------------------
inpstruct.blockSizeR              = 15000;
inpstruct.blockSizeC              = 15000;

%--------------------------------------------------------------------------
% Crack/non-crack decider parameters
%--------------------------------------------------------------------------
inpstruct.non_crack_class         = 1;
inpstruct.crack_class             = 2;
inpstruct.CC_overlap_percent      = 0.5;

%--------------------------------------------------------------------------
% Training data folder path, file to save names
%--------------------------------------------------------------------------
inpstruct.folderpath              =  '';
inpstruct.synfolderpath           =  '';
inpstruct.processed_FMatLab_filename = 'ZZZ_FeatMAT_5JahanFeat_Realworld_elasticDefAug_cracksOnly.mat';
inpstruct.processed_FMatLab_filename_conc = '.mat';
inpstruct.shuffled_FMatLab_filename  = '.mat';
inpstruct.final_XYmat_labels         = '.mat';


%--------------------------------------------------------------------------
% Branch points to cluster the cracks in real-world dataset images
%--------------------------------------------------------------------------
inpstruct.BPClusterImgsSavePath   =  'H:\Project MegaCRACK-RoboCRACK\Real World Data\Training-RoboCRACK';
inpstruct.BPClusters              =  [0, 1];
inpstruct.imclose_disk_size = 5; % Morphological disk size
inpstruct.boundary_smooth = 0; % 0 - none | 1 - morphClose | 2 - kernel
inpstruct.windowSize = 15; % Kernel size
inpstruct.thinPruneMethod = 'alex';  % 'conventional' | 'alex' | 'voronoi' | 'fast_marching'
inpstruct.thinPruneThresh = 0.05; % [0 1]
inpstruct.showFigure = 0; % 0-off | 1-on

%--------------------------------------------------------------------------
% Cracks to generate/augment
%--------------------------------------------------------------------------
inpstruct.AugmentImgsSavePath   =  'H:\Project MegaCRACK-RoboCRACK\Real World Data\Training-RoboCRACK\realworld_elasticdeformation_only';
inpstruct.totNumberCracksElasticDef = 20;
inpstruct.maxDistortAlpha = 0;  % 0 or 1
inpstruct.geotrans_type = {'affine', 'projective', 'piecewise_linear'};
inpstruct.showfig_points = 0;

%--------------------------------------------------------------------------
% Orphan blobs filtering
%--------------------------------------------------------------------------
inpstruct.blobFilter = 1; % 0 | 1
inpstruct.blobFilterSigma = 0.15;
inpstruct.blobFilterArea = 25;
inpstruct.blobFilterType = 'area';    % 'area' | 'gaussian'

%--------------------------------------------------------------------------
% GPU array
%--------------------------------------------------------------------------
% yes - creates GPU array (note: works for certain Matlab functions)
% no  - non GPU array
inpstruct.gpuarray                = 'no';

%--------------------------------------------------------------------------
% Data set type
% training | testing
%--------------------------------------------------------------------------
inpstruct.datasetType              = 'training';

%--------------------------------------------------------------------------
% Noisy/ground-truth images copy/paste shuffle flag
%--------------------------------------------------------------------------
inpstruct.nsyGrndImcpyPaste        = 0;       %[0-off | 1-on]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
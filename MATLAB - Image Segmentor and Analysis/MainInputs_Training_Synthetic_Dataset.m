
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Training data parameters

%--------------------------------------------------------------------------
% Read training folder
%--------------------------------------------------------------------------
train_inpstruct.flagswitch    = 1;   % [0-off | 1-on]

%--------------------------------------------------------------------------
% Folder paths for non-cracks and synthetic cracks
%--------------------------------------------------------------------------
train_inpstruct.imgFolder     =  {"F:\Training-RoboCrack 2025"};
train_inpstruct.synimgFolder  =  {""};

%--------------------------------------------------------------------------
% Provide names of original training data folders (include name of the folder even its folder
% is empty
%--------------------------------------------------------------------------
train_inpstruct.Traindata_folders_noncracks = {'non-cracks-max480pix'};
train_inpstruct.Traindata_folders_syncracks = {'synthetic_cracks'};

% File to save
train_inpstruct.traimImgs_filename = 'ZZZ_Train_images_MFAT_non-cracks.mat';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Training and testing feature matrix and labels parameters

%--------------------------------------------------------------------------
% Jahanshahi Inputs
%--------------------------------------------------------------------------
nmin = 1;       % minimum crack size in pixel (after transformation)
nmax = 100;      % maximum crack size in pixel (after transformation)

% Crack structural length
jahan_inpstruct.crackLEN = nmin+2 : nmax+10;  % options:  [1 : max(size(image))] 

% Angle between
jahan_inpstruct.anglebetween = [0 45 90 135]; % [0 : delta : 179], use symmetry

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

%--------------------------------------------------------------------------
% Algorithm type
%--------------------------------------------------------------------------
% Hessian/Frangi filter - 'hessian'
% MFAT filter - 'mfat'
% morphological method - 'morpho'

inpstruct.Algorithm_TYPE          = {'mfat'}; %{'hessian', 'mfat', 'morpho'};

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
inpstruct.processed_FMatLab_filename = 'ZZZ_FeatMAT_5JahanFeat_Labels_noncracks_mfat.mat';
inpstruct.processed_FMatLab_filename_conc = 'ZZZ_FeatMAT_5JahanFeat_elastic_mfat_combo_JahanSynRot5_90_v1_1280_720_Unique.mat';
inpstruct.shuffled_FMatLab_filename  = 'ZZZ_Train_5JahanFeatMatLabels_elastic_mfat_combo_JahanSynRot5_90_v1_1280_720_Unique.mat';
inpstruct.final_XYmat_labels         = 'ZZZ_XYTargets5JahanFeat_elastic_mfat_combo_JahanSynRot5_90_v1_1280_720_Unique.mat';


%--------------------------------------------------------------------------
% Provide names of groundtruth folders (include pseudoname even if ground-truth doesn't 
% exist for a original folder, e.g. nocrack --> ground_nocrack. Also if the folder
% is empty)
%--------------------------------------------------------------------------
inpstruct.groundtruth_folders     = {}; %{'CrackG', 'Non_Crack'};

%--------------------------------------------------------------------------
% Provide names of original data folders (include name of the folder even its folder
% is empty)
%--------------------------------------------------------------------------
inpstruct.originaldata_folders    = {'non-cracks-max480pix'};

%--------------------------------------------------------------------------
% GPU array
%--------------------------------------------------------------------------
% yes - creates GPU array (note: works for certain Matlab functions)
% no  - non GPU array
inpstruct.gpuarray                = 'no';

%--------------------------------------------------------------------------
% Colorspace segmentation options 
%--------------------------------------------------------------------------
% Type of colorspace to segment RGB ground-truths
% HSV (recommended) or RGB
inpstruct.colorspace = 'hsv';  %[hsv | rgb]

% RGB startindex
% n   - channel value (integer [0, 255])
inpstruct.RGBstartindex           = 235;

%--------------------------------------------------------------------------
% Multiscale fractional anisotropy  parameters
%--------------------------------------------------------------------------
% MFAT filter options
inpstruct.MFAT_TYPE = 'ProbabilisticFAT';
inpstruct.dynamic_mfatopt = 1;
inpstruct.MFAToptions.sigmas1       = 0.7181;  % 1
inpstruct.MFAToptions.sigmas2       = 5; % 12.5  [0.782174183815890,0.781857711412556,0.775797432964799] [0.784728063849959,0.781899268844155,0.777392362164455]
inpstruct.MFAToptions.sigmasScaleRatio = 0.25;
inpstruct.MFAToptions.spacing       = 0.39; %0.4, 0.45 0.39
inpstruct.MFAToptions.tau           = 0.25; 
inpstruct.MFAToptions.tau2          = 0.5; 
inpstruct.MFAToptions.D             = 0.5; %0.85
inpstruct.MFAToptions.whiteondark   = false;

%--------------------------------------------------------------------------
% Hessian matrix parameters
%--------------------------------------------------------------------------
% Frangi filter options
inpstruct.dynamic_frangiopt = 1;
inpstruct.frangiopt.FrangiScaleRange  = [0.7181, 5];
inpstruct.frangiopt.FrangiScaleRatio  = 0.25;
inpstruct.frangiopt.FrangiBetaOne    = 0.5; %0.5
inpstruct.frangiopt.FrangiBetaTwo    = 25; %2 %15 10
inpstruct.frangiopt.BlackWhite       = 1;
inpstruct.frangiopt.FWHM             = 1;
inpstruct.frangiopt.verbose          = 0;

%--------------------------------------------------------------------------
% Blob removal parameters
%--------------------------------------------------------------------------
% Blob filter standard deviation scale
inpstruct.blobfilter_sigma    = 0.0; % 0.75 % 3 

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
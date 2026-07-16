%% Start parameters
%--------------------------------------------------------------------------
clear; close all; clc;
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);

%% Inputs
%--------------------------------------------------------------------------
if(isempty(gcp('nocreate')))
    parpool;
end
Start = tic;

% Pixel 
if ismac
    
    elseif isunix
        inputStruct.PixLabelsFolder = '../../data/Testing/Dataset V/Pixel Labels/GT';

    elseif ispc
        inputStruct.PixLabelsFolder = 'S:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 6 - Cracks-1K (448 x 252)';

    else
        disp('Platform not supported')
end
        

% Define the class names and their associated label IDs.
% Class names
classNames = ["crack","noncrack"];

% Label colors
labelIDs = [1, 0];

% Dataset folder
if ismac
    
    elseif isunix
        PreethamYoung_DatasetPath = '../../data/Testing/Dataset V';

    elseif ispc
        PreethamYoung_DatasetPath = 'S:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 6 - Cracks-1K (448 x 252)';

    else
        disp('Platform not supported')
end

%--------------------------------------------------------------------------
% Provide names of groundtruth folders (include pseudoname even if ground-truth doesn't
% exist for a original folder, e.g. nocrack --> ground_nocrack. Also if the folder
% is empty)
%--------------------------------------------------------------------------
inputStruct.groundtruth_folders     = {'Cracks_Groundtruth_small_dataset_resized', 'Non-cracks_small_dataset'};

inputStruct.ImagesType = 'crack_only'; % 'crack_only' | 'crackANDnoncracks'

inputStruct.bypassPixFolder = 'no';

%--------------------------------------------------------------------------
% Turn on/off adaptive histogram
%--------------------------------------------------------------------------
% adaphist - adaptive histogram
% image_adjust - imadjust
% hist_equi - histogram equalization
% none
inputStruct.contrast_type                = 'image_adjust';

%--------------------------------------------------------------------------
% Image patch size
%--------------------------------------------------------------------------
inputStruct.blockSizeR              = 15000;
inputStruct.blockSizeC              = 15000;

%--------------------------------------------------------------------------
% Image resize for too large images
%--------------------------------------------------------------------------
inputStruct.resizeImage = 'no'; % 'yes' | 'no'
inputStruct.maxImageResizePixels = 700;
inputStruct.resizeImageSize = [];
inputStruct.resizeImageSizeScale = 0.25;

%--------------------------------------------------------------------------
% GPU array
%--------------------------------------------------------------------------
% yes - creates GPU array (note: works for certain Matlab functions)
% no  - non GPU array
inputStruct.gpuarray                = 'no';

%--------------------------------------------------------------------------
% Colorspace segmentation options 
%--------------------------------------------------------------------------
% Type of colorspace to segment RGB ground-truths
% HSV (recommended) or RGB
inputStruct.colorspace = 'hsv';  %[hsv | rgb]

% GT label color
inputStruct.GTcolor_TYPE = 'binary';   %[color | binary]

% RGB startindex
% n   - channel value (integer [0, 255])
inputStruct.RGBstartindex           = 235;

%% Extract images location
%--------------------------------------------------------------------------
% Training, testing and validation (if any) 
%--------------------------------------------------------------------------
imgCount          = [250 250];
imgFldDescription = {'Cracks', 'Pixel Labels', 'Non-cracks_small_dataset'};

CrackFilesG  = dir(fullfile(PreethamYoung_DatasetPath,imgFldDescription{2}, 'test'));
CrackFilesG  = CrackFilesG(~ismember({CrackFilesG.name},{'.','..'}));

Non_CrackFilesG  = dir(fullfile(PreethamYoung_DatasetPath,imgFldDescription{3}));
Non_CrackFilesG  = Non_CrackFilesG(~ismember({Non_CrackFilesG.name},{'.','..'}));

for i = 1:length(CrackFilesG)+length(Non_CrackFilesG)
    switch inputStruct.ImagesType
        case 'crack_only'
            if (i <= length(CrackFilesG))
                imagesGroundTruth2classifier{i} = fullfile(PreethamYoung_DatasetPath, ...
                                imgFldDescription{2}, 'test', CrackFilesG(i).name);
            end
        case 'crackANDnoncracks'
            if (i <= length(CrackFilesG))
                imagesGroundTruth2classifier{i} = fullfile(PreethamYoung_DatasetPath, ...
                                imgFldDescription{2}, 'test', CrackFilesG(i).name);
            else
                imagesGroundTruth2classifier{i} = fullfile(PreethamYoung_DatasetPath,'Non-cracks_small_dataset', ...
                    Non_CrackFilesG(i-length(CrackFilesG)).name);
            end
    end
end 

% Class numbers 
classnumber = [2 * ones(1,imgCount(1)),  ones(1,imgCount(2))]';


%% Get groundtruths
[objBoxCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs] = ...
    GTExtractor_2020_ParFor (inputStruct,imagesGroundTruth2classifier, imgCount, ...
    classnumber, classNames, labelIDs);

save ZZZ_GT_Dataset_CDLN_Dragon_cracks_only.mat objBoxCracksnNoncracksGTs ssmPixCracksnNoncracksGTs

%% End parameters
%--------------------------------------------------------------------------
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
statusFclose = fclose('all');
if(statusFclose == 0)
    disp('All files are closed.')
end
Runtime = toc(Start);
disp(Runtime);
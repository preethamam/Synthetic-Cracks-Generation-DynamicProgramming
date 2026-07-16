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
        inputStruct.PixLabelsFolder = '../../data/Testing/Dataset VII (Liu)/Pixel Labels/GT';

    elseif ispc
        inputStruct.PixLabelsFolder = 'H:\Project DLCRACK\External Datasets\Yahui Liu - DeepCrack';

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
        Liu_DatasetPath = '../../data/Testing/Dataset VII (Liu)';
    elseif ispc
        Liu_DatasetPath = 'H:\Project DLCRACK\External Datasets\Yahui Liu - DeepCrack';

    else
        disp('Platform not supported')
end


inputStruct.bypassPixFolder = 'no';

inputStruct.FolderPath = fullfile(Liu_DatasetPath,'Testing Cracks_Groundtruth');

%--------------------------------------------------------------------------
% Provide names of groundtruth folders (include pseudoname even if ground-truth doesn't
% exist for a original folder, e.g. nocrack --> ground_nocrack. Also if the folder
% is empty)
%--------------------------------------------------------------------------
inputStruct.groundtruth_folders     = {'Testing Cracks_Groundtruth'};

inputStruct.ImagesType = 'crack_only'; % 'crack_only' | 'crackANDnoncracks'

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
imgCount          = 237;
imgFldDescription = 'Testing Cracks_Groundtruth';

CrackFilesG  = dir(fullfile(Liu_DatasetPath,imgFldDescription));
CrackFilesG  = CrackFilesG(~ismember({CrackFilesG.name},{'.','..'}));

for i = 1:length(CrackFilesG)
    imagesGroundTruth2classifier{i} = fullfile(Liu_DatasetPath, 'Testing Cracks_Groundtruth',CrackFilesG(i).name);
end 

% Class numbers 
classnumber = 2 * ones(1,imgCount(1))';


%% Get groundtruths
[objBoxCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs] = ...
    GTExtractor_2020_ParFor (inputStruct,imagesGroundTruth2classifier, imgCount, ...
    classnumber, classNames, labelIDs);

save ZZZ_GT_Dataset_Liu_Kraken_cracks_only.mat objBoxCracksnNoncracksGTs ssmPixCracksnNoncracksGTs

%%
%{
load ZZZ_GT_Dataset_VII_Liu_Linux.mat
labelData = objBoxCracksnNoncracksGTs.LabelData;
shiftedBox = cellfun(@(a, b) a + 0.15*b, labelData(:,1), labelData(:,1), 'UniformOutput', 0);
pseudo_results = array2table([shiftedBox, dummy', labelData(:,2)]);
pseudo_results.Properties.VariableNames = {'BBox', 'Scores', 'Labels'};

% Evalaute the BBoxes
[ap, recall, precision] = evaluateDetectionPrecision(pseudo_results, objBoxCracksnNoncracksGTs);
[precision_value,recall_value] = bboxPrecisionRecall(pseudo_results(:,1), table(objBoxCracksnNoncracksGTs.LabelData(:,1)), 0.5)

% Plot the precision/recall curve.
figure;
plot(recall{1}, precision{1});
grid on
title(sprintf('Average precision = %.1f', ap))
%}

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
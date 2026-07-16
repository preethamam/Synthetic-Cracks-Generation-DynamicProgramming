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
        inputStruct.PixLabelsFolder = '../../data/Testing/Dataset I/Pixel Labels/GT';

    elseif ispc
        inputStruct.PixLabelsFolder = 'H:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 1 - Cracks-200';

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
        JahanPreetham_DatasetPath = '../../data/Testing/Dataset I';

    elseif ispc
        JahanPreetham_DatasetPath = 'H:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 1 - Cracks-200';

    else
        disp('Platform not supported')
end

%--------------------------------------------------------------------------
% Provide names of groundtruth folders (include pseudoname even if ground-truth doesn't
% exist for a original folder, e.g. nocrack --> ground_nocrack. Also if the folder
% is empty)
%--------------------------------------------------------------------------
inputStruct.groundtruth_folders     = {'CrackG', 'Non_Crack'};

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
imgCount          = [40, 40, 40];
imgFldDescription = {'test', 'test', 'Non_Crack'};
imgFolder = {'Cracks', 'Pixel Labels', 'Noncracks'};


CrackFilesG      = dir(fullfile(JahanPreetham_DatasetPath, imgFolder{2}, imgFldDescription{2}, '*.PNG'));
Non_CrackFilesG  = dir(fullfile(JahanPreetham_DatasetPath, imgFolder{3}, imgFldDescription{3}, '*.PNG'));

CrackFilesG     = {CrackFilesG(1:end).name};
Non_CrackFilesG = {Non_CrackFilesG(1:end).name};

for i = 1:length(CrackFilesG)
     switch inputStruct.ImagesType
        case 'crack_only'
            imagesGroundTruth2classifier{i} = fullfile(JahanPreetham_DatasetPath, imgFolder{2}, imgFldDescription{2}, CrackFilesG{i});
            
        case 'crackANDnoncracks'
            imagesGroundTruth2classifier{i} = fullfile(JahanPreetham_DatasetPath, imgFolder{2}, imgFldDescription{2}, CrackFilesG{i});
            imagesGroundTruth2classifier{i+imgCount(1)} = fullfile(JahanPreetham_DatasetPath, imgFolder{3}, imgFldDescription{3}, Non_CrackFilesG{i});
     end        
end 
% Class numbers 
classnumber = [2 * ones(1,imgCount(1)),  ones(1,imgCount(2))]';


%% Get groundtruths
[objBoxCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs] = ...
    GTExtractor_2020_ParFor (inputStruct,imagesGroundTruth2classifier, imgCount, ...
    classnumber, classNames, labelIDs);

save ZZZ_GT_Dataset_Jahan_Kraken_cracks_only.mat objBoxCracksnNoncracksGTs ssmPixCracksnNoncracksGTs

%% Sanity check the groundtruths by itself
% Object detection
%{
load matlab.mat
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

% Semantic segmentation
metrics = evaluateSemanticSegmentation(ssmPixCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs)
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
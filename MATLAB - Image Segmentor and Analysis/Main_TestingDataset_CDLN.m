%% Start parameters
%--------------------------------------------------------------------------
clear; close all; clc;
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);

%% Inputs
%--------------------------------------------------------------------------
% Weird = 4666 5275 6205
% Callback 
MainInputs_TestingDataset_CDLN;

% Add MAT files folder
addpath('../MAT Files')

if (strcmp(hybrid_inpstruct.parallel_sequential_processing, 'parallel'))
    if(isempty(gcp('nocreate')))
        parpool;
    end
end
Start = tic;

% Load Groundtruths
switch hybrid_inpstruct.ImagesType
    case 'crack_only'
        if ismac
    
        elseif isunix
            load ZZZ_GT_Dataset_CDLN_cracks_only_Linux.mat
        elseif ispc
            if strcmp(getenv('COMPUTERNAME'), 'PREETHAM-DRAGON')
                load ZZZ_GT_Dataset_CDLN_Dragon_cracks_only.mat
                hybrid_inpstruct.montage_dir_path = 'S:\Project MegaCRACK-RoboCRACK\Real World Data\Synthetic Papers\Paper I - Dynamic Programming\Montage Plots';
            elseif strcmp(getenv('COMPUTERNAME'), 'PREETHAM-KRAKEN')
                load ZZZ_GT_Dataset_CDLN_Kraken_cracks_only.mat
                hybrid_inpstruct.montage_dir_path = 'H:\Project MegaCRACK-RoboCRACK\Real World Data\Synthetic Papers\Paper I - Dynamic Programming\Montage Plots';
            end
        else
            disp('Platform not supported')
        end
    case 'crackANDnoncracks'
        load ZZZ_GT_Dataset_V.mat
end

% Create a file based on last serial number
if ~(contains(textFileName, '.txt'))
    textfilesDir    = dir(textFolder);
    textfilesSorted = natsort({textfilesDir.name});
    textfilesIndex  = find(contains(textfilesSorted, textFileName));
    textfileLast    = textfilesSorted(textfilesIndex(end));
    newStr = extractBetween(textfileLast{1},'_CDLN_','.');
    serialNum = str2double(newStr{1});
    textFile = [textFileName '_' num2str(serialNum+1) '.txt'];
else
    textFile = textFileName;
end
    
% File open
fileID = fopen(fullfile(textFolder,textFile),'w');

% Dataset folder
if ismac
    
elseif isunix
    PreethamYoung_DatasetPath = '../../data/Testing/Dataset V';
elseif ispc
    if strcmp(getenv('COMPUTERNAME'), 'PREETHAM-DRAGON')
        PreethamYoung_DatasetPath = 'S:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 6 - Cracks-1K (448 x 252)';
    elseif strcmp(getenv('COMPUTERNAME'), 'PREETHAM-KRAKEN')
        PreethamYoung_DatasetPath = 'H:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 6 - Cracks-1K (448 x 252)';
    end    
else
    disp('Platform not supported')
end


%--------------------------------------------------------------------------
% Provide names of groundtruth folders (include pseudoname even if ground-truth doesn't 
% exist for a original folder, e.g. nocrack --> ground_nocrack. Also if the folder
% is empty)
%--------------------------------------------------------------------------
hybrid_inpstruct.groundtruth_folders     = {'Cracks_Groundtruth_small_dataset_resized', 'Non-cracks_small_dataset'};

%--------------------------------------------------------------------------
% Provide names of original data folders (include name of the folder even its folder
% is empty)
%--------------------------------------------------------------------------
hybrid_inpstruct.originaldata_folders    = {'Cracks_small_dataset_resized', 'Non-cracks_small_dataset'};

%% Classifier Processing step
%--------------------------------------------------------------------------
% Training, testing and validation (if any) 
%--------------------------------------------------------------------------

imgCount          = [250 250 250];
imgFldDescription = {'Cracks', 'Pixel Labels', 'Non-cracks_small_dataset'};
CrackFiles = dir(fullfile(PreethamYoung_DatasetPath,imgFldDescription{1}, 'test'));
CrackFiles = CrackFiles(~ismember({CrackFiles.name},{'.','..'}));

Non_CrackFiles  = dir(fullfile(PreethamYoung_DatasetPath,imgFldDescription{3}));
Non_CrackFiles  = Non_CrackFiles(~ismember({Non_CrackFiles.name},{'.','..'}));

for i = 1:length(CrackFiles)+length(Non_CrackFiles)
    switch hybrid_inpstruct.ImagesType
        case 'crack_only'
            if (i <= length(CrackFiles))
                images2classifier{i} = fullfile(PreethamYoung_DatasetPath, imgFldDescription{1}, 'test', CrackFiles(i).name);
            end
        case 'crackANDnoncracks'
            if (i <= length(CrackFiles))
                images2classifier{i} = fullfile(PreethamYoung_DatasetPath, imgFldDescription{1}, 'test', CrackFiles(i).name);
            else
                images2classifier{i} = fullfile(PreethamYoung_DatasetPath,'Non-cracks_small_dataset', Non_CrackFiles(i-length(CrackFiles)).name);
            end
    end
end    

CrackFilesG  = dir(fullfile(PreethamYoung_DatasetPath,imgFldDescription{2}, 'test'));
CrackFilesG  = CrackFilesG(~ismember({CrackFilesG.name},{'.','..'}));

Non_CrackFilesG  = dir(fullfile(PreethamYoung_DatasetPath,imgFldDescription{3}));
Non_CrackFilesG  = Non_CrackFilesG(~ismember({Non_CrackFilesG.name},{'.','..'}));

for i = 1:length(CrackFilesG)+length(Non_CrackFilesG)
    switch hybrid_inpstruct.ImagesType
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

switch hybrid_inpstruct.ImagesType
    case 'crack_only'
        classnumber = 2 * ones(1,imgCount(2));
    case 'crackANDnoncracks'    
        classnumber = [2 * ones(1,imgCount(2)), ones(1,imgCount(3))];
end

%% Run classifier iteratively to process and store results
% Process file and store results
% ProcessFilesStoreResults_ParFor;
ProcessFilesStoreResults_Compact;


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

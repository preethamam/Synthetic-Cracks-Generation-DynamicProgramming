%% Start parameters
%--------------------------------------------------------------------------
clear; close all; clc;
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);


%% Inputs
%--------------------------------------------------------------------------
% Weird = 4666 5275 6205
% Callback 
MainInputs_TestingDataset_Liu;

% Add MAT files folder
addpath('../MAT Files')

if (strcmp(hybrid_inpstruct.parallel_sequential_processing,'parallel'))
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
            load ZZZ_GT_Dataset_Liu_cracks_only_Linux.mat
        elseif ispc
            if strcmp(getenv('COMPUTERNAME'), 'PREETHAM-DRAGON')
                load ZZZ_GT_Dataset_Liu_Dragon_cracks_only.mat
                hybrid_inpstruct.montage_dir_path = 'S:\Project MegaCRACK-RoboCRACK\Real World Data\Synthetic Papers\Paper I - Dynamic Programming\Montage Plots';
            elseif strcmp(getenv('COMPUTERNAME'), 'PREETHAM-KRAKEN')
                load ZZZ_GT_Dataset_Liu_Kraken_cracks_only.mat
                hybrid_inpstruct.montage_dir_path = 'H:\Project MegaCRACK-RoboCRACK\Real World Data\Synthetic Papers\Paper I - Dynamic Programming\Montage Plots';
            end
        else
            disp('Platform not supported')
        end
    case 'crackANDnoncracks'
        
end

% Create a file based on last serial number
if ~(contains(textFileName, '.txt'))
    textfilesDir    = dir(textFolder);
    textfilesSorted = natsort({textfilesDir.name});
    textfilesIndex  = find(contains(textfilesSorted, textFileName));
    textfileLast    = textfilesSorted(textfilesIndex(end));
    newStr = extractBetween(textfileLast{1},'_Liu_','.');
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
    Liu_DatasetPath = '../../data/Testing/Dataset VII (Liu)';
elseif ispc
    if strcmp(getenv('COMPUTERNAME'), 'PREETHAM-DRAGON')
        Liu_DatasetPath = 'S:\Project DLCRACK\External Datasets\Yahui Liu - DeepCrack';
    elseif strcmp(getenv('COMPUTERNAME'), 'PREETHAM-KRAKEN')
        Liu_DatasetPath = 'H:\Project DLCRACK\External Datasets\Yahui Liu - DeepCrack';
    end    
else
    disp('Platform not supported')
end


%--------------------------------------------------------------------------
% Provide names of groundtruth folders (include pseudoname even if ground-truth doesn't 
% exist for a original folder, e.g. nocrack --> ground_nocrack. Also if the folder
% is empty)
%--------------------------------------------------------------------------
hybrid_inpstruct.groundtruth_folders     = {'Testing Cracks_Groundtruth'};

%--------------------------------------------------------------------------
% Provide names of original data folders (include name of the folder even its folder
% is empty)
%--------------------------------------------------------------------------
hybrid_inpstruct.originaldata_folders    = {'Testing Cracks'};

%% Classifier Processing step
%--------------------------------------------------------------------------
% Training, testing and validation (if any) 
%--------------------------------------------------------------------------
imgCount          = [237 237];
imgFldDescription = {'Testing Cracks', 'Testing Cracks_Groundtruth'};

CrackFiles = dir(fullfile(Liu_DatasetPath,imgFldDescription{1}));
CrackFiles = CrackFiles(~ismember({CrackFiles.name},{'.','..'}));

CrackFilesG  = dir(fullfile(Liu_DatasetPath,imgFldDescription{2}));
CrackFilesG  = CrackFilesG(~ismember({CrackFilesG.name},{'.','..'}));

for i = 1:length(CrackFiles)
    images2classifier{i} = fullfile(Liu_DatasetPath, imgFldDescription{1}, CrackFiles(i).name);
    imagesGroundTruth2classifier{i} = fullfile(Liu_DatasetPath, imgFldDescription{2},CrackFilesG(i).name);
end 

classnumber = 2 * ones(1,imgCount(2));

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

%% Start parameters
%--------------------------------------------------------------------------
clear; close all; clc;
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);

%% Inputs
%--------------------------------------------------------------------------
% Callback
MainInputs_TestingDataset_Jahan;

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
            load ZZZ_GT_Dataset_Jahan_cracks_only_Linux.mat
        elseif ispc
            if strcmp(getenv('COMPUTERNAME'), 'PREETHAM-DRAGON')
                load ZZZ_GT_Dataset_Jahan_Dragon_cracks_only.mat
                hybrid_inpstruct.montage_dir_path = 'S:\Project MegaCRACK-RoboCRACK\Real World Data\Synthetic Papers\Paper I - Dynamic Programming\Montage Plots';
            elseif strcmp(getenv('COMPUTERNAME'), 'PREETHAM-KRAKEN')
                load ZZZ_GT_Dataset_Jahan_Kraken_cracks_only.mat
                hybrid_inpstruct.montage_dir_path = 'H:\Project MegaCRACK-RoboCRACK\Real World Data\Synthetic Papers\Paper I - Dynamic Programming\Montage Plots';
            end
        else
            disp('Platform not supported')
        end
    case 'crackANDnoncracks'
        load ZZZ_GT_Dataset_I.mat
end

% Create a file based on last serial number
if ~(contains(textFileName, '.txt'))
    textfilesDir    = dir(textFolder);
    textfilesSorted = natsort({textfilesDir.name});
    textfilesIndex  = find(contains(textfilesSorted, textFileName));
    textfileLast    = textfilesSorted(textfilesIndex(end));
    newStr = extractBetween(textfileLast{1},'_Jahan_','.');
    serialNum = str2double(newStr{1});
    textFile = [textFileName '_' num2str(serialNum+1) '.txt'];
else
    textFile = textFileName;
end
    
% File open
fileID = fopen(fullfile(textFolder,textFile),'w');

% On/off figures
% set(groot,'DefaultFigureVisible','off');

% Dataset folder
if ismac
    
elseif isunix
    JahanPreetham_DatasetPath = '../../data/Testing/Dataset I';
elseif ispc
    if strcmp(getenv('COMPUTERNAME'), 'PREETHAM-DRAGON')
        JahanPreetham_DatasetPath = 'S:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 1 - Cracks-200';
    elseif strcmp(getenv('COMPUTERNAME'), 'PREETHAM-KRAKEN')
        JahanPreetham_DatasetPath = 'H:\Project MegaCRACK-RoboCRACK\Real World Data\USC PhD\Semantic Segmentation\Dataset 1 - Cracks-200';
    end        
else
    disp('Platform not supported')
end

%--------------------------------------------------------------------------
% Provide names of groundtruth folders (include pseudoname even if ground-truth doesn't
% exist for a original folder, e.g. nocrack --> ground_nocrack. Also if the folder
% is empty)
%--------------------------------------------------------------------------
hybrid_inpstruct.groundtruth_folders     = {'Pixel Labels'};

%--------------------------------------------------------------------------
% Provide names of original data folders (include name of the folder even its folder
% is empty)
%--------------------------------------------------------------------------
hybrid_inpstruct.originaldata_folders    = {'Cracks'};

%% Classifier Processing step
%--------------------------------------------------------------------------
% Training, testing and validation (if any) 
%--------------------------------------------------------------------------
imgCount          = [40 40 40];
imgFldDescription = {'test', 'test', 'Non_Crack'};
imgFolder = {'Cracks', 'Pixel Labels', 'Noncracks'};

CrackFiles      = dir(fullfile(JahanPreetham_DatasetPath,imgFolder{1}, ...
                        imgFldDescription{1},'*.PNG'));
Non_CrackFiles  = dir(fullfile(JahanPreetham_DatasetPath,imgFolder{2},...
                        imgFldDescription{3},'*.PNG'));

CrackFiles = {CrackFiles(1:end).name};
Non_CrackFiles = {Non_CrackFiles(1:end).name};

for i = 1:length(CrackFiles)
    switch hybrid_inpstruct.ImagesType
        case 'crack_only'
            images2classifier{i} = fullfile(JahanPreetham_DatasetPath, imgFolder{1}, imgFldDescription{1}, CrackFiles{i});            
        case 'crackANDnoncracks'
            images2classifier{i} = fullfile(JahanPreetham_DatasetPath, imgFolder{1}, imgFldDescription{1}, CrackFiles{i});
            images2classifier{i+imgCount(1)} = fullfile(JahanPreetham_DatasetPath, imgFolder{3}, imgFldDescription{3}, Non_CrackFiles{i});
    end
end    

CrackFilesG      = dir(fullfile(JahanPreetham_DatasetPath, imgFolder{2}, imgFldDescription{2}, '*.PNG'));
Non_CrackFilesG  = dir(fullfile(JahanPreetham_DatasetPath, imgFolder{3}, imgFldDescription{3}, '*.PNG'));

CrackFilesG     = {CrackFilesG(1:end).name};
Non_CrackFilesG = {Non_CrackFilesG(1:end).name};

for i = 1:length(CrackFiles)
     switch hybrid_inpstruct.ImagesType
        case 'crack_only'
            imagesGroundTruth2classifier{i} = fullfile(JahanPreetham_DatasetPath, imgFolder{2}, imgFldDescription{2}, CrackFilesG{i});
            
        case 'crackANDnoncracks'
            imagesGroundTruth2classifier{i} = fullfile(JahanPreetham_DatasetPath, imgFolder{2}, imgFldDescription{2}, CrackFilesG{i});
            imagesGroundTruth2classifier{i+imgCount(1)} = fullfile(JahanPreetham_DatasetPath, imgFolder{3}, imgFldDescription{3}, Non_CrackFilesG{i});
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
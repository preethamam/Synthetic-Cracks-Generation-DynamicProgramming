clc; close all; clear;

% Inputs
gtFolder = "H:\Project DLCRACK\External Datasets\Yahui Liu - DeepCrack\Training Cracks_Groundtruth";
moveFolderRoot = "H:\Project DLCRACK\External Datasets\Yahui Liu - DeepCrack\Pixel Labels";
trainValFolders = {'train_crack_bmp', 'val_crack_bmp'};
valImgNum = 50;

% Read directory
imgs = dir(gtFolder);
imgs = imgs(3:end);

% Get image filenames
imgs = {imgs.name};

% Train and val images
valImgs = randsample(imgs, valImgNum);
trainImgs = setdiff(imgs,valImgs);

for i = 1:length(trainValFolders)
    if i == 1
       filesNum = numel(trainImgs);
    else
       filesNum = numel(valImgs);
    end

    for j = 1:filesNum
        if i == 1
           originalImgName = trainImgs{j};
           I = imread(fullfile(gtFolder,originalImgName));
           writeFolder = fullfile(moveFolderRoot,trainValFolders{i});
        else
           originalImgName = valImgs{j};
           I = imread(fullfile(gtFolder,originalImgName));
           writeFolder = fullfile(moveFolderRoot,trainValFolders{i});
        end

        [filepath,name,ext] = fileparts(originalImgName);

        I2 = imbinarize(I);
        imwrite(I2, fullfile(writeFolder, [name '.bmp']))
    end
end  

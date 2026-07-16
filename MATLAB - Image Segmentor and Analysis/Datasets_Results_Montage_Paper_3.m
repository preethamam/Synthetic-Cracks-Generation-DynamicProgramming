%//%************************************************************************%
%//%*                              Ph.D                                    *%
%//%*                     Datasets result montage                          *%
%//%*                                                                      *%
%//%*             Name: Preetham Aghalaya Manjunatha    		           *%
%//%*             USC Email: aghalaya@usc.edu                              *%
%//%*             Submission Date: --/--/2019                              *%
%//%************************************************************************%
%//%*             Viterbi School of Engineering,                           *%
%//%*             Sonny Astani Dept. of Civil Engineering,                 *%
%//%*             University of Southern california,                       *%
%//%*             Los Angeles, California.                                 *%
%//%************************************************************************%

%% Start parameters
%--------------------------------------------------------------------------
clear; close all; clc;
Start = tic;
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
warning('off', 'Images:initSize:adjustingMag');

%% Inputs
chooseRandomly = 1;
imageNum = 5;
imColumns = 5;
numDatasets = 3;
imSize = [200 400];
StrictResize = 1;
imageTileSize = [imageNum * numDatasets, imColumns];

%--------------------------------------------------------------------------
ds1_fileFolder = 'H:\Project MegaCRACK-RoboCRACK\Real World Data\Synthetic Papers\Paper I - Dynamic Programming\Montage Plots\Jahan';
ds2_fileFolder = 'H:\Project MegaCRACK-RoboCRACK\Real World Data\Synthetic Papers\Paper I - Dynamic Programming\Montage Plots\CDLN';
ds3_fileFolder = 'H:\Project MegaCRACK-RoboCRACK\Real World Data\Synthetic Papers\Paper I - Dynamic Programming\Montage Plots\Liu';

% ds1_fileFolder = 'B:\Project MegaCRACK-RoboCRACK\Real World Data\Hybrid Paper\Montage Plots\DS1';
% ds2_fileFolder = 'B:\Project MegaCRACK-RoboCRACK\Real World Data\Hybrid Paper\Montage Plots\DS5resized';
% ds3_fileFolder = 'B:\Project MegaCRACK-RoboCRACK\Real World Data\Hybrid Paper\Montage Plots\DS7';

imgSet_ds1 = imageSet(ds1_fileFolder, 'recursive');
imgSet_ds2 = imageSet(ds2_fileFolder, 'recursive');
imgSet_ds3 = imageSet(ds3_fileFolder, 'recursive');

% imgSet_ds1 = imageDatastore(ds1_fileFolder,"IncludeSubfolders",true);
% imgSet_ds2 = imageDatastore(ds2_fileFolder,"IncludeSubfolders",true);
% imgSet_ds3 = imageDatastore(ds3_fileFolder,"IncludeSubfolders",true);

% imgSet_ds1 = getFoldersImds(ds1_fileFolder);

% Hessian map
% 3 | 1    4 | 2     5 | 3    6 | 4    7 | 5    8 | 6
hess_map = [3,4,5,6,7,8];

% MFAT map
% 9 | 1    10 | 2     11 | 3    12 | 4    13 | 5    14 | 6
mfat_map = [9,10,11,12,3,14];

% Morpho map
% 15 | 1    16 | 2     17 | 3    18 | 4    19 | 5    20 | 6
morpho_map = [15,16,17,18,19,20];


montage_plot_name = {'fig_montage_plot_million_synthetic.png',...
                     'fig_montage_plot_100000_synthetic.png',...
                     'fig_montage_plot_realworld.png',...
                     'fig_montage_plot_realworld_aug.png',...
                     'fig_montage_plot_rw_rw_aug.png',...
                     'fig_montage_plot_rw_rw_aug_synthetic.png'};

%% Choose image number of images
if (chooseRandomly == 1)
     % idx_ds1 = randi([1,imgSet_ds1(1).Count],imageNum,1); 
     % idx_ds2 = randi([1,imgSet_ds2(1).Count],imageNum,1);
     % idx_ds3 = randi([1,imgSet_ds3(1).Count],imageNum,1);

     idx_ds1 = [15, 5, 31, 6, 29];
     idx_ds2 = [19, 94, 164, 67, 92];
     idx_ds3 = [44,20,28,84,141];  %139,174,52
        
     ds1_files = cell(length(hess_map), numel(idx_ds1)*imColumns);
     ds2_files = cell(length(hess_map), numel(idx_ds1)*imColumns);
     ds3_files = cell(length(hess_map), numel(idx_ds1)*imColumns);

     for i = 1:length(hess_map)
         ds1_files(i,:) = [imgSet_ds1(1).ImageLocation(idx_ds1), imgSet_ds1(2).ImageLocation(idx_ds1), imgSet_ds1(hess_map(i)).ImageLocation(idx_ds1), ...
                     imgSet_ds1(mfat_map(i)).ImageLocation(idx_ds1), imgSet_ds1(morpho_map(i)).ImageLocation(idx_ds1)];
         
         
         ds2_files(i,:) = [imgSet_ds2(1).ImageLocation(idx_ds2), imgSet_ds2(2).ImageLocation(idx_ds2), imgSet_ds2(hess_map(i)).ImageLocation(idx_ds2), ...
                      imgSet_ds2(mfat_map(i)).ImageLocation(idx_ds2), imgSet_ds2(morpho_map(i)).ImageLocation(idx_ds2)];
    
         
         ds3_files(i,:) = [imgSet_ds3(1).ImageLocation(idx_ds3), imgSet_ds3(2).ImageLocation(idx_ds3), imgSet_ds3(hess_map(i)).ImageLocation(idx_ds3), ...
                      imgSet_ds3(mfat_map(i)).ImageLocation(idx_ds3), imgSet_ds3(morpho_map(i)).ImageLocation(idx_ds3)];
     end
else
     % Load manually selected data here.
end

%% Reshuffle the image names according to the datasets

for ii = 1:length(hess_map) 
    ds_Allfiles = [ds1_files(ii,:), ds2_files(ii,:), ds3_files(ii,:)];
    fileNames = string(ds_Allfiles);
    dataSplitVar = length(ds_Allfiles)/numDatasets;
    
    c = 1;
    for i = 1:numDatasets
        for j = 1 : imageNum
            for k = (i-1) * dataSplitVar + j : imageNum : i * dataSplitVar
                fileNamesShuffled(c) = ds_Allfiles(k);
                c = c + 1;
            end
        end
    end
    fileNamesShuffled = string(fileNamesShuffled);
    
    %% Processing steps
    %--------------------------------------------------------------------------
    if (StrictResize == 1)
        montagefiles = cell(1, length(fileNames));
        myColnum = 1;
        for i = 1:length(fileNames)
           myImage = imread(fileNamesShuffled(i));
           [h,w,bytesppix] = size(myImage);
           
            if (islogical(myImage) || bytesppix == 1)
                Icomp = imcomplement(imbinarize(im2double(myImage)));
                Imresized = imresize(Icomp, imSize);
                Iborder   = addborder(Imresized, 5, 0, 'outer');
                montagefiles{i} = Iborder;
            else
               if i == myColnum
                    montagefiles{i} = imresize(myImage, imSize);
                    myColnum = myColnum + imColumns;
               else
                    Icomp = imcomplement(imbinarize(rgb2gray(myImage)));
                    Imresized = imresize(Icomp, imSize); 
                    Iborder = addborder(Imresized, 5, 0, 'outer');
                    montagefiles{i} = Iborder;
               end
            end
        end
        figure; 
        m1 = montage(montagefiles, 'BackgroundColor', 'white', 'BorderSize', [5 5], ...
                        'Size', imageTileSize);
    else
        figure; 
        m1 = montage(fileNames, 'BackgroundColor', 'white', 'BorderSize', [3 3], ...
                        'Size', imageTileSize, 'ThumbnailSize',[100 100]);
    end
    
    exportgraphics(gcf,['..\results\Paper Figs\' montage_plot_name{ii}]);

    % if ii == 1
    %     pause(3)
    % end
end

%% Convert the 3 channel rgb blackwhite to binary
%{
for i  = 1:imgSet_ds7(1).Count
    I = imread(string(imgSet_ds7(4).ImageLocation(i)));
    Inew = rgb2gray(I);
    [path, name, ext] =  fileparts(imgSet_ds7(4).ImageLocation(i));
    imwrite(Inew, fullfile(ds7_fileFolder, 'Predict', 'Liu2', [name, ext]), 'png')
end
%}

%% End parameters
%--------------------------------------------------------------------------
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
Runtime = toc(Start);






%//%************************************************************************%
%//%*                              Ph.D                                    *%
%//%*                       Pseudo Crack Package						   *%
%//%*                                                                      *%
%//%*             Name: Preetham Aghalaya Manjunatha
%*%S
%//%*             USC Email: aghalaya@usc.edu                              *%
%//%*             Submission Date: --/--/2017                              *%
%//%************************************************************************%
%//%*             Viterbi School of Engineering,                           *%
%//%*             Sonny Astani Dept. of Civil Engineering,                 *%
%//%*             University of Southern california,                       *%
%//%*             Los Angeles, California.                                 *%
%//%************************************************************************%

%% Start parameters
%--------------------------------------------------------------------------
clear; close all; clc;
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);

%% Inputs
if(isempty(gcp('nocreate')))
    parpool;
end

% Start timer
Start = tic;

% Total cracks to generate
totNumberCracks = 100;
totNumberCracksElasticDef = 1;
maxDistortAlpha = 0;  % 0 or 1

%--------------------------------------------------------------------------
% Synthetic cracks width and length input
%--------------------------------------------------------------------------
% Output image size range

minRadius = 1;
maxRadius = 20;

% Output image size range
imSize = [512 512];

% Crack angles to rotate
randAngle = randi([0, 90],1,2);
    
% Save to folder location
saveFolderPath  = 'F:\synthetic_cracks_horizontal';

% Show figure points
showfig_points = 0;

geotrans_type = {'affine', 'projective', 'piecewise_linear', 'polynomial', 'local_weighted_mean'};

%% Make cracks!

%Before the loop, we need to construct the object. 
WaitMessage = waitbarParfor(totNumberCracks, 'Waitbar', true);
    
parfor i = 1 : totNumberCracks
    
    %Send a message to the object. 
    WaitMessage.Send;
    
    optCrackStrandMask = [];
    StartSynTime = tic;
    if (rand(1) > 0.5)
        % Structural element to dilate the thin non-uniform cracks  
        recRow = randi([2, 20],1);
        recCol = randi([2, 20],1);

        SE = strel('rectangle',[recRow,recCol]);

    else
        % Radii and width of the seams
        radiusSE(i) = randi([minRadius, maxRadius]);
        width_actual_record(i,:) = radiusSE(i)*2+2;
    
        SE = strel('disk',radiusSE(i),8);

    end
    
    if (rand(1) > 0.5)
        Im = randn(randi(imSize));
    else
        Im = rand(randi(imSize));
    end

    energy = funct_energyGrey(Im);
    choice = randi(3);
    
    if (rand(1) > 0.5)        
        switch choice
            case 1
                [optCrackStrandMask, crackStrandEnergy] = funct_findOptCrackStrand_ShortestPath_Vertical(energy);
            case 2        
                [optCrackStrandMask, crackStrandEnergy] = funct_findOptCrackStrand_ShortestPath_Horizontal(energy);
            case 3
                if (rand(1) > 0.5)
                    [optCrackStrandMask, crackStrandEnergy] = funct_findOptCrackStrand_ShortestPath_Diagonal(energy, true);
                else
                    [optCrackStrandMask, crackStrandEnergy] = funct_findOptCrackStrand_ShortestPath_Diagonal(energy, false);
                end
        end
    else
        switch choice
            case 1
                [optCrackStrandMask, crackStrandEnergy] = funct_findOptCrackStrand_LongestPath_Vertical(energy);
            case 2    
                [optCrackStrandMask, crackStrandEnergy] = funct_findOptCrackStrand_LongestPath_Horizontal(energy);
            case 3
                if (rand(1) > 0.5)
                    [optCrackStrandMask, crackStrandEnergy] = funct_findOptCrackStrand_LongestPath_Diagonal(energy, true);
                else
                    [optCrackStrandMask, crackStrandEnergy] = funct_findOptCrackStrand_LongestPath_Diagonal(energy, false);
                end
        end         
    end   
    crackStrand = imcomplement(optCrackStrandMask); 
    
    % Find the centroid of that binary region
    measurements = regionprops(crackStrand, 'Centroid',"Area");
    [val,idx] = max(cat(1,measurements.Area));
    [rows, columns] = size(crackStrand);
    rowsToShift = ceil(rows/2- measurements(idx).Centroid(2));
    columnsToShift = ceil(columns/2 - measurements(idx).Centroid(1));

    % Call circshift to move region to the center.
    shiftedSeam = circshift(crackStrand, [rowsToShift columnsToShift]);

    % Lengths of the seam
    length_actual_record(i,:) = numel(find(shiftedSeam));

    % Dilate the seam
    dilateSeam = imdilate(shiftedSeam,SE);    

    % Area of the seams
    area_actual_record(i,:) = numel(find(dilateSeam ~= 0));
    
    img_elastic = elastic_def_multiplicator(dilateSeam,geotrans_type,maxDistortAlpha,totNumberCracksElasticDef,showfig_points);
    
    RuntimeSynTime(i) = toc(StartSynTime);

    for j = 1:totNumberCracksElasticDef
    
        % Rotate the seam
        for k = 1:numel(randAngle)

            % Rotate and filter
            imRotRandAngle = imrotate(img_elastic(:,:,j), randAngle(k));
            imRotRandAngle = filter_stage_I (imRotRandAngle);

            imRotRandAngle_area = regionprops(imRotRandAngle, "Area");
            [val,idx] = max(cat(1,imRotRandAngle_area.Area));
            imRotRandAngle = bwareaopen(imRotRandAngle, val-1, 8);

            % Do some flips
            flip_hori = flip(imRotRandAngle,1);
            flip_vert = flip(imRotRandAngle,2);
            flip_hor_ver = flip(flip(imRotRandAngle,1),2);

            % Image write
            outputBaseFileName = sprintf('%s%s%s%s.bmp', datestr(now,'yyyy_mm_dd_HH_MM_SS_FFF'), ...
                ['_Ang_' num2str(randAngle(k))], '_flip_hori', ['_' randomString(10)]);   
            imwrite(flip_hori, fullfile(saveFolderPath,outputBaseFileName), 'bmp');

            outputBaseFileName = sprintf('%s%s%s%s.bmp', datestr(now,'yyyy_mm_dd_HH_MM_SS_FFF'), ...
                ['_Ang_' num2str(randAngle(k))], '_flip_vert', ['_' randomString(10)]);   
            imwrite(flip_vert, fullfile(saveFolderPath,outputBaseFileName), 'bmp');

            outputBaseFileName = sprintf('%s%s%s%s.bmp', datestr(now,'yyyy_mm_dd_HH_MM_SS_FFF'), ...
                ['_Ang_' num2str(randAngle(k))], '_flip_hor_ver', ['_' randomString(10)]);   
            imwrite(flip_hor_ver, fullfile(saveFolderPath,outputBaseFileName), 'bmp');
        end
    end
end

%Destroy the object.
WaitMessage.Destroy

%% End parameters
%--------------------------------------------------------------------------
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
Runtime = toc(Start);
%//%************************************************************************%
%//%*                              Ph.D                                    *%
%//%*                       Pseudo Crack Package						   *%
%//%*                                                                      *%
%//%*             Name: Preetham Aghalaya Manjunatha    		           *%
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
totNumberCracks = 200; %52670;
totNumberCracksElasticDef = 20;
polyDegree = [4, 8];
maxDistortAlpha = 0;  % 0 or 1

% Output image size range
imSize_range = [400 640];

alphaImRange = [1 1.5];

% Crack angles to rotate
randAngle = randi([0, 90],1,2);
    
% Save to folder location
saveFolderPath  = 'D:\synthetic_cracks_elastic_final_polycurve';

% Show figure points
showfig_points = 0;

geotrans_type = {'affine', 'projective', 'polynomial', 'piecewise_linear', 'local_weighted_mean'};

% if(isfolder(saveFolderPath))
%     rmdir(saveFolderPath,'s');
%     mkdir(saveFolderPath);
% else
%     mkdir(saveFolderPath);
% end
  
%% Make cracks!
%--------------------------------------------------------------------------
% Wait bar initialization
% h = waitbar(0, 'Initializing...', ...
%     'name','Making pseudo-cracks',...
%     'CreateCancelBtn',...
%     'setappdata(gcbf,''canceling'',1)');
% setappdata(h,'canceling',0)

%Before the loop, we need to construct the object. 
WaitMessage = waitbarParfor(totNumberCracks, 'Waitbar', true);
spmd
  warning('off','all')
end


for i = 1 : totNumberCracks
    
    %Send a message to the object. 
    WaitMessage.Send;
    
    % Structural element to dilate the thin non-uniform cracks 
    recRow = randi([5, 18],1);
    recCol = randi([5, 18],1);
    
    SE = strel('rectangle',[recRow,recCol]);
    
    % Check for Cancel button press
%     if getappdata(h,'canceling')
%         %break
%     end
    
    % Curve degree
    curvedegree = randi(polyDegree);  %set as desired
    
    % Image size
    image_height = randi(imSize_range);
    im_alpha = rand(1,1)*range(alphaImRange)+min(alphaImRange);
    image_width  = round(im_alpha * image_height);

    % Generate the X and Y points 
    x = linspace(1,image_width,1500);
    y = image_height * rand(size(x));

    % Fit the curve of given order
    coeffs = polyfit(x, y, curvedegree);
    xIM = round(x);
    yIM = round(polyval(coeffs, x));

    % Create the binary image
    binaryImage = false(image_height,image_width);
    ind = sub2ind(size(binaryImage),yIM,xIM);
    binaryImage(ind) = true;
    seam = bwmorph(binaryImage,'bridge','inf');
    % [~, BW_image, ~] = edgelink(binaryImage);
    
    
    % Find the centroid of that binary region
    measurements = regionprops(seam, 'Area', 'Centroid');
    [rows, columns] = size(seam);
    blobAreas = cat(1,measurements.Area);
    blobCentroids = cat(1,measurements.Centroid);
    [value,idx] = max(blobAreas);
    rowsToShift = ceil(rows/2 - blobCentroids(idx,2));
    columnsToShift = ceil(columns/2 - blobCentroids(idx,1));
    seam = bwareaopen(seam, value);
    
    % Call circshift to move region to the center.
    shiftedImage = circshift(seam, [rowsToShift columnsToShift]);
    measurements = regionprops(shiftedImage, 'Area');
    blobAreas = cat(1,measurements.Area);
    [value,idx] = max(blobAreas);
    shiftedImage = bwareaopen(shiftedImage, value);
    
    % Dilate the seam
    dilateSeam = imdilate(shiftedImage,SE);

    img_elastic = elastic_def_multiplicator(dilateSeam,geotrans_type,maxDistortAlpha,totNumberCracksElasticDef,showfig_points);
    
    for j = 1:totNumberCracksElasticDef
    
        % Rotate the seam
        for k = 1:numel(randAngle)

            % Report current estimate in the waitbar's message field
    %         waitbar(i/totNumberCracks, h, sprintf('Current image: %i | Angle: %i' , i, randAngle(j)))

            % Rotate and filter
            imRotRandAngle = imrotate(img_elastic(:,:,j), randAngle(k));
            imRotRandAngle = filter_stage_I (imRotRandAngle);
    %         imshow(imRotRandAngle)

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

% DELETE the waitbar; don't try to CLOSE it.
% delete(h)

%Destroy the object.
WaitMessage.Destroy

%}
%% End parameters
%--------------------------------------------------------------------------
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
Runtime = toc(Start);
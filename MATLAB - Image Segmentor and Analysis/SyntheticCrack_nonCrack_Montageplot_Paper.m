%//%************************************************************************%
%//%*                              Ph.D                                    *%
%//%*                         Project RoboCRACK						       *%
%//%*                                                                      *%
%//%*             Name: Preetham Manjunatha               		           *%
%//%*             USC Email: aghalaya@usc.edu                              *%
%//%*             Submission Date: --/--/----                              *%
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

%% Inputs
non_crack_fileFolder = '';
crack_fileFolder = '';

imgSet_non_crack = imageSet(non_crack_fileFolder, 'recursive');
imgSet_crack = imageSet(crack_fileFolder, 'recursive');

for i=1:imageNum
   montagefiles_non_cracks(:,:,:,i) = imresize(imcomplement(read(imgSet_non_crack,i)),[100 100]);
   montagefiles_cracks(:,:,:,i)     = imresize(imcomplement(read(imgSet_crack,i)),[100 100]);
end

figure; m1 = montage(montagefiles_non_cracks, 'BackgroundColor', 'white', 'BorderSize', [3 3], ...
                    'Size', [5,4]);

figure; m2 = montage(montagefiles_cracks, 'BackgroundColor', 'white', 'BorderSize', [3 3], ...
                    'Size', [5,4]);
                
%% End parameters
%--------------------------------------------------------------------------
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
Runtime = toc(Start);

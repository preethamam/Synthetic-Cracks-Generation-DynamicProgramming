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
% Start timer
Start = tic;

% Add MAT files folder
addpath('../MAT Files')
load('ZZZ_SyntheticCrackProfileAnalysis_thickcrack_30x15.mat')
inputImage = img;
inputImage2 = imcomplement(img);  %img2

% Maximum distortion
maxDistortAlpha = 0;  % 0 or 1

% -------------------------------------------------------------------------
% Pixel explosion failure cases parameters
% -------------------------------------------------------------------------
% Affine: alpha_geotrans = 200 | alpha = 150
% Projective: alpha_geotrans = 200 | alpha = 150
% Piecewise_linear: alpha_geotrans = 200 | alpha = 150
% Polynomial: degree: 2 | alpha_geotrans = 20 | alpha = 150
%             degree: 3 | alpha_geotrans = 20 | alpha = 150
%             degree: 4 | alpha_geotrans = 20 | alpha = 150
% Local_weighted_mean: alpha_geotrans = 200 | alpha = 150


% Geometric transformations
geotrans_type = {'affine', 'projective', 'piecewise_linear', 'polynomial', 'local_weighted_mean'};
geotrans_idx = 4;
alpha_geotrans = 20;  % Geometric transformation scale factor 30 to 70
polydegree_idx = 2;   % 2, 3 or 4
% Polynomials best range
% alpha_geotrans = randi([5,10],1);  % Geometric transformation scale factor 5 to 10
% alpha_geotrans = randi([2,4],1);  % Geometric transformation scale factor 2 to 4
% alpha_geotrans = 1;  % Geometric transformation scale factor 1

if maxDistortAlpha == 0
    alpha = 150; %35; % Scaling factor 15 to 35 
else
    alpha = 50; % Scaling factor 50 to 90
end

% Show figure points
showfig_points = 1;

% Inputs combination
% Valid parameters for elastic deformation of synthetic cracks
% affine | alpha_geotrans [30 70] | SIGMA = 5 | alpha = [15 35]
% projective | alpha_geotrans [30 70] | SIGMA = 5 | alpha = [15 35]
% piecewise_linear | alpha_geotrans [80 100] | SIGMA = 5 | alpha = [15 35]
% polynomial | Degree 2 | alpha_geotrans [5 10] | SIGMA = 5 | alpha = [15 35]
% polynomial | Degree 3 | alpha_geotrans [2 4] | SIGMA = 5 | alpha = [15 35]
% polynomial | Degree 4 | alpha_geotrans [1] | SIGMA = 5 | alpha = [15 35]    
% local_weighted_mean: TOO MUCH DISTORTION (exploding pixels) NOT RECOMMEND TO USE THIS FOR SYNTHETIC CRACKS

switch geotrans_idx
    case 1 % affine        
        SIGMA = 5;  % Standard deviation of Gaussian convolution
        poly_degree = [];
    case 2 % projective
        SIGMA = 5;  % Standard deviation of Gaussian convolution
        poly_degree = [];
    case 3 % piecewise_linear
        SIGMA = 5;  % Standard deviation of Gaussian convolution       
        poly_degree = [];
    case 4                      
        poly_degree = polydegree_idx;      % Degree: 2|3|4
        SIGMA = 5;  % Standard deviation of Gaussian convolution                      
    case 5 % local_weighted_mean
        alpha_geotrans = randi([60,70],1);  % Geometric transformation scale factor
        SIGMA = 5;  % Standard deviation of Gaussian convolution        
        poly_degree = [];
end

% Elastic deformation
try
    [img_elastic_final, img_elastic_final2] = elastic_deformation(inputImage, inputImage2, SIGMA, alpha, geotrans_type{geotrans_idx}, ...
                            alpha_geotrans, poly_degree, showfig_points);
catch ME
    warning(ME.identifier, 'Distortion points problem: %s', ME.message);
end                               

%% End parameters
%--------------------------------------------------------------------------
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
Runtime = toc(Start);
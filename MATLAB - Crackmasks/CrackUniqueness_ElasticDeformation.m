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
%--------------------------------------------------------------------------
% Inputs
dataUnique = 'unique';  %'rotated' | 'unique'
non_crack_class   = 1;
Pseudocrack_class = 2;
randSamples = 5000;
nbins = 20;
ensemble_number = 100;
loop_max = 1000;
fig_window_size = [100, 100, 850, 750];

textFolder = '../Results/Text Files';
textFile = 'ensemble_marathon.txt';

% Add MAT files folder
addpath('../MAT Files')


% File open
fileID = fopen(fullfile(textFolder,textFile),'w');

%% Find unique pseudo crack indes
switch dataUnique
    case 'rotated'
        % Load relevant files
        % Rotated
        load ZZZ_Train_images_non_uniform_diffimsize_longshortpath_rot5_90_JahanSyn_hybrid syn_crack_Imgs
        load ZZZ_FeatMAT_5JahanFeat_Labels_Raw_rot5_90_JahanSyn_hessian

        Pcracknames = {syn_crack_Imgs.name};
        PcrackUnqIndx = find(contains(Pcracknames,'_Ang_5.bmp'));
        
        % Find indices of the unique cracks
        PcrackIndx = find(Labelmat==non_crack_class, 1, 'last' );
        PseudoCrackFeatureMat = Featuremat(PcrackIndx+PcrackUnqIndx,:);
        
    case 'unique'
        % Load relevant files
        % Unique
        load ZZZ_Train_images_non_uniform_diffimsize_longshortpath_unique_JahanSyn_hybrid syn_crack_Imgs
        load ZZZ_FeatMAT_5JahanFeat_Labels_Raw_unique_JahanSyn_hessian

        % Find indices of the unique cracks
        PcrackIndx = find(Labelmat==Pseudocrack_class);
        PseudoCrackFeatureMat = Featuremat(PcrackIndx,:);
end

% Load elastic uniques
elasticData = load('ZZZ_Train_5JahanFeatMatLabels_elastic_hessian_combo_JahanSynRot5_90_v1_1280_720_Unique_100000.mat');
elasticData_cracksIndex = find(elasticData.LabelsVector == Pseudocrack_class);
PseudoCrackFeatureMat_elastic = unique(elasticData.Feature_matrix(elasticData_cracksIndex,:),'stable','rows');


%% Ensemble of the data
meanDiff_goal = 85;
loop_iter = 1;
meanDiff = 0;
meanDiff_previous = -Inf;

% Witbar handle
h = waitbar(0,'1','Name','Ensembling the data ',...
    'CreateCancelBtn',...
    'setappdata(gcbf,''canceling'',1)');
setappdata(h,'canceling',0)

while true
    % Sample the data
    shuffle_data = datasample(PseudoCrackFeatureMat,randSamples,'Replace',false);
    shuffle_data_elastic = datasample(PseudoCrackFeatureMat_elastic,randSamples,'Replace',false);
    
    % Normalize the rows to unit --> 1
    shuffle_data_norm = normr(shuffle_data);
    shuffle_data_elastic_norm = normr(shuffle_data_elastic);
    
    % Calculate pairwise distances
    % 'euclidean' | 'seuclidean' | 'mahalanobis' | 'correlation' | 'cosine'
    PairDist         = pdist(shuffle_data_norm,'euclidean');
    PairDist_elastic = pdist(shuffle_data_elastic_norm,'euclidean');
    
    % Normalize to [0 1]
    PairDistNorm = mat2gray(PairDist);
    PairDistNorm_elastic = mat2gray(PairDist_elastic);

    for i = 2 : ensemble_number
        % Wait bar parameters
        % Check for Cancel button press
        if getappdata(h,'canceling')
            break
        end
    
        % Report current estimate in the waitbar's message field
        % Update the estimate
        waitbar(i/ensemble_number, h, sprintf('Iteration: %i | Current Ensemble number: %i', loop_iter, i))
        
        % Sample the data
        shuffle_data = datasample(PseudoCrackFeatureMat,randSamples,'Replace',false);
        shuffle_data_elastic = datasample(PseudoCrackFeatureMat_elastic,randSamples,'Replace',false);
    
        % shuffle_data = shuffle_data(:,1:2);
    
        % Normalize the rows to unit --> 1
        shuffle_data_norm = normr(shuffle_data);
        shuffle_data_elastic_norm = normr(shuffle_data_elastic);
    
        % Calculate pairwise distances
        % 'euclidean' | 'seuclidean' | 'mahalanobis' | 'correlation' | 'cosine'
        PairDist         = pdist(shuffle_data_norm,'euclidean');
        PairDist_elastic = pdist(shuffle_data_elastic_norm,'euclidean');
    
        % Normalize to [0 1]
        PairDistNorm_i              = mat2gray(PairDist);
        PairDistNorm_elastic_i = mat2gray(PairDist_elastic);
        
        % Ensemble average
        PairDistNorm = mean([PairDistNorm; PairDistNorm_i],1);
        PairDistNorm_elastic = mean([PairDistNorm_elastic; PairDistNorm_elastic_i],1);
    
    end


    %% Mean
    meanPDist = mean(PairDistNorm);   
    meanPDist_elastic_best = mean(PairDistNorm_elastic);
    mean_Diff_store(loop_iter,:) = [loop_iter, meanDiff];

    meanDiff = 100 * (meanPDist_elastic_best - meanPDist);
    fprintf('Iterationn: %i | The mean difference: %f \n', loop_iter, meanDiff);
    fprintf(fileID,'Iterationn: %i | The mean difference: %f \n', loop_iter, meanDiff);      

    if meanDiff > meanDiff_previous
        PairDistNorm_best = PairDistNorm;
        PairDistNorm_best_elastic = PairDistNorm_elastic;
        meanDiff_previous = meanDiff;
    end

    if meanDiff > meanDiff_goal || loop_iter == 2000
        break;
    end
    loop_iter = loop_iter + 1;
end 

% DELETE the waitbar; don't try to CLOSE it.
delete(h)
%}
% load('ZZZ_PairwiseDistance_Stats_Paper_2025_final.mat')

%% Pairwise distance statistics
% Convert pairwise distance to square matrix
Z = squareform(PairDistNorm_best);
Z_elastic = squareform(PairDistNorm_best_elastic);

% Correlation coefficient of features (matrix)
% R = corrcoef(PseudoCrackFeatureMat);
% R_elastic = corrcoef(PseudoCrackFeatureMat_elastic);

% Mean and 
meanPDist_best = mean(PairDistNorm_best);
varPDist  = var(PairDistNorm_best);
stdPDist  = std(PairDistNorm_best);

meanPDist_elastic_best = mean(PairDistNorm_best_elastic);
varPDist_elastic  = var(PairDistNorm_best_elastic);
stdPDist_elastic  = std(PairDistNorm_best_elastic);


meanDiff = 100 * (meanPDist_elastic_best - meanPDist_best);

%%
% Histogram
figure; 
hi = histogram(PairDistNorm_best,nbins);
hold on
h2 = histogram(PairDistNorm_best_elastic,nbins);
hold off
grid on;
xlabel('Normalized Pairwise Distance');
ylabel('Pairs Counts');
title('Histogram of Pair Distances')
legend ('Crack Seams', 'Crack Seams Elastic Deformation')
set(gca,'fontsize',10)
axis tight

%% Plot and save figures
% PDF
ksx = linspace(min(PairDistNorm_best),max(PairDistNorm_best),500);
ksx_elastic = linspace(min(PairDistNorm_best_elastic),max(PairDistNorm_best_elastic),500);

[f,xi] = ksdensity(PairDistNorm_best,ksx);
[f_elastic,xi_elastic] = ksdensity(PairDistNorm_best_elastic,ksx_elastic);

figure
plot(xi,f,'-','LineWidth',5,'Color',[1 0 0]);
hold on
plot(xi_elastic,f_elastic,'-.','LineWidth',5,'Color',[0 0 1]);
hold off
grid on;
xlabel('Normalized Pairwise Distance');
ylabel('Density');
xlim([0,1])
set(gca,'fontsize',24)
legend ('No Elastic Deformation ', 'Elastic Deformation')
set(gcf, 'Position',  fig_window_size)
%title('PDF of Pairwise Distances')
exportgraphics(gcf,['..\Results\Paper Figs\' 'fig_seamsPDF.pdf'])

%%
% CDF
figure
[h,stats] = cdfplot(PairDistNorm_best);
hold on
[h_elastic,stats_elastic] = cdfplot(PairDistNorm_best_elastic);
hold off
grid on
set(h, 'LineWidth', 5, 'LineStyle', '-', 'Color', 'r');
set(h_elastic, 'LineWidth', 5, 'LineStyle', '-.', 'Color', 'b');
xlabel('Normalized Pairwise Distance');
ylabel('Density');
xlim([0,1])
set(gca,'fontsize',24)
set(gcf, 'Position',  fig_window_size)
legend ('No Elastic Deformation ', 'Elastic Deformation','Location','SouthEast')
% title('CDF of Pairwise Distances')
title('')
exportgraphics(gcf,['..\Results\Paper Figs\' 'fig_seamsCDF.pdf']);

%%
% Pairwise distance
figure; 
imagesc(Z);
xlabel('Pair Indices');
ylabel('Pair Indices');
set(gca,'xticklabel',{'1', '1e3','2e3','3e3','4e3','5e3'})
set(gca,'yticklabel',{'1', '1e3','2e3','3e3','4e3','5e3'})
% set(gca, 'XTickLabel','FontSize', 20)
% set(gca, 'YTickLabel','FontSize', 20)
colormap('jet'); 
c = colorbar; 
c.Label.String = 'Normalized Distance';
caxis([0 1])
set(c,'YTick', 0:0.2:1)
c.Label.FontSize = 24;
ax = gca;
ax.LineWidth = 30*0.1;
ax.TickLength = [0.02, 0.02];
set(gca,'fontsize',24)
axis tight; %axis off;
set(gcf, 'Position',  fig_window_size)
% title('Pairwise Distances')
exportgraphics(gcf,['..\Results\Paper Figs\' 'fig_seamsPairwiseDistance.pdf']);

%
figure; 
imagesc(Z_elastic);
xlabel('Pair Indices');
ylabel('Pair Indices');
set(gca,'xticklabel',{'1e3','2e3','3e3','4e3','5e3'})
set(gca,'yticklabel',{'1e3','2e3','3e3','4e3','5e3'})
colormap('jet'); 
c = colorbar; 
c.Label.String = 'Normalized Distance';
caxis([0 1])
set(c,'YTick', 0.0:0.2:1)
c.Label.FontSize = 24;
ax = gca;
ax.LineWidth = 30*0.1;
ax.TickLength = [0.02, 0.02];
set(gca,'fontsize',24)
axis tight; %axis off;
set(gcf, 'Position',  fig_window_size)
% title('Pairwise Distances')
exportgraphics(gcf,['..\Results\Paper Figs\' 'fig_seamsElastic_PairwiseDistance.pdf']);


%% Print difference
fprintf('The mean difference: %f \n', 100 * (meanPDist_elastic_best-meanPDist_best))

%% Save to mat file
% save('ZZZ_PairwiseDistance_Paper_2025.mat');
% save('ZZZ_PairwiseDistance_Stats_Paper_2025.mat','meanPDist_best','meanPDist_elastic_best','PairDistNorm_best',...
%     'PairDistNorm_best_elastic','stdPDist','stdPDist_elastic','varPDist','varPDist_elastic');

%% End parameters
%--------------------------------------------------------------------------
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);
statusFclose = fclose('all');
if(statusFclose == 0)
    disp('All files are closed.')
end
Runtime = toc(Start);

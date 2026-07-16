%% Start parameters
%--------------------------------------------------------------------------
clear; close all; clc;
clcwaitbarz = findall(0,'type','figure','tag','TMWWaitbar');
delete(clcwaitbarz);


%% Inputs
%--------------------------------------------------------------------------
if (isempty(gcp('nocreate')))
    cluster = parcluster;
    ppobj = parpool(cluster);
end
Start = tic;

% On/off figures
% set(groot,'DefaultFigureVisible','off');

% Thining/pruning method
thinPrune = 'voronoi';  % 'alex' | 'voronoi' | 'conventional'
thinPruneThresh = 0.1;
showFigure = 'no';

% Dataset folder
DatasetPath = {'..\..\data\Testing\Dataset VI (Xincong)\Training Cracks_Groundtruth',...
               '..\..\data\Testing\Dataset VII (Liu)\Training Cracks_Groundtruth'};
% Save each cracks folder
saveFolder = 'D:\Cracks_splits_external';

% Initialize arrays
ImageDetailsFull = [];

% Figure maximized
if (strcmp(showFigure,'yes'))
    fh = figure('WindowState', 'maximized');
end

%{
for i = 1:length(DatasetPath)
    
    % Directory files
    crackFiles = dir(fullfile(DatasetPath{i},'*.png'));
    
    %Before the loop, we need to construct the object. 
    WaitMessage = waitbarParfor(length(crackFiles), 'Waitbar', true);
    
    parfor j = 1:length(crackFiles)
        
        %Send a message to the object. 
        WaitMessage.Send;
        
        % Read anc convert image to binary
        ImageID = fullfile(crackFiles(j).folder,crackFiles(j).name);
        Im = imread(ImageID);
        BW = imbinarize(Im);
        
        % Image size
        [rows, columns, ~] = size(BW);

        % Skeleton prune threshold
        skelPruneThresh = floor(max(rows,columns) * thinPruneThresh);

        % Fill the holes
        BW2 = imfill(BW,'holes');
%         BW2 = BW;

        % Image branch/end points extraction
        BW_thin = [];
        switch thinPrune
            case 'conventional'
                BW_thin = bwmorph(BW2,'thin',Inf);
            case 'alex'
                BW3 = skeleton(BW2) > skelPruneThresh;
                BW_thin = bwmorph(BW3,'thin',Inf);
            case 'voronoi'
                [BW3, v, e] = voronoiSkel(BW2,'trim',3.5,'fast',3);
                BW_thin = bwmorph(BW3,'thin',Inf);
        end
        
        % Get branch and end points
        BW_bp   = bwmorph(BW_thin,'branchpoints');
        [rowBP, colBP] = find(BW_bp);
        branch_points  = [rowBP, colBP]; %#ok<*NASGU>

        BW_ep   = bwmorph(BW_thin, 'endpoints', Inf);
        [rowEP, colEP] = find(BW_ep);
        end_points     = [rowEP, colEP];
        
        % Store image/crack     
        ImageDetails(j).ImageFolderLocation = crackFiles(j).folder;
        ImageDetails(j).FileName = crackFiles(j).name;
        ImageDetails(j).BranchPoints = length(branch_points);

        % Branch/end points image
        if (strcmp(showFigure,'yes'))
            subplot(1,2,1)
            imshow(BW) 
            title('Cracks');

            subplot(1,2,2)
            imshow(BW_thin)
            hold on ; 
            if ~(isempty(branch_points))
                plot(branch_points(:,2),branch_points(:,1),'ro');
                plot(end_points(:,2),end_points(:,1),'b*');
                legend('Branch points','End points')
            else
                plot(end_points(:,2),end_points(:,1),'b*');
                legend('End points')
            end
            hold off
            title('Branch/end points');

            drawnow;
    %         pause(3)
        end
    end
    
    ImageDetailsFull = [ImageDetailsFull, ImageDetails];
    ImageDetails = [];
    
    %Destroy the object
    WaitMessage.Destroy
end
%}

%% Copy files for inspection
load ImageDetailsFull.mat

allImbps  = cat(1,ImageDetailsFull.BranchPoints);

bp5 = find(allImbps <= 1);
bp10 = find(allImbps >= 5 & allImbps <= 10);
bp10p = find(allImbps > 10);

for i=1:numel(bp5)
    copyfile(fullfile(ImageDetailsFull(bp5(i)).ImageFolderLocation, ImageDetailsFull(bp5(i)).FileName), ...
             fullfile(saveFolder,'bp5',ImageDetailsFull(bp5(i)).FileName))
    
end

for i=1:numel(bp10)
    copyfile(fullfile(ImageDetailsFull(bp10(i)).ImageFolderLocation, ImageDetailsFull(bp10(i)).FileName), ...
             fullfile(saveFolder,'bp10',ImageDetailsFull(bp10(i)).FileName))
    
end

for i=1:numel(bp10p)
    copyfile(fullfile(ImageDetailsFull(bp10p(i)).ImageFolderLocation, ImageDetailsFull(bp10p(i)).FileName), ...
             fullfile(saveFolder,'bp10p',ImageDetailsFull(bp10p(i)).FileName))
    
end


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

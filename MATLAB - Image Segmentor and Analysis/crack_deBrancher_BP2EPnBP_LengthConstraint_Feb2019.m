function [debranchedImage, branchFill, isany_branches] = crack_deBrancher_BP2EPnBP_LengthConstraint_Feb2019(Igray,BW,thinPrune,...
    pruneThresh, branchlengthThreshold, morphclose_disksize, boundary_smooth, windowSize, showFigure)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

switch boundary_smooth 
    case 1
        se = strel('disk', morphclose_disksize);
        Iground_smoothed = imclose(BW,se);
    case 2
        kernel = ones(windowSize) / windowSize ^ 2;
        blurryImage = conv2(single(BW), kernel, 'same');
        Iground_smoothed = blurryImage > 0.5; % Rethreshold
    otherwise
        Iground_smoothed = BW;
end

% Image size
[rows, columns, ~] = size(Iground_smoothed);

% Skeleton prune threshold
skelPruneThresh = floor(max(rows,columns) * pruneThresh);

% Fill the holes
Ifilled = imfill(Iground_smoothed,'holes');

% Image branch/end points extraction
switch thinPrune
    case 'conventional'
        BW_thin = bwmorph(Ifilled,'thin',Inf);
    case 'alex'
        if ismac
            % Code to run on Mac platform
            BW3 = skeleton_mac(Ifilled) > skelPruneThresh;
        elseif isunix
            % Code to run on Linux platform
            BW3 = skeleton_unix(Ifilled) > skelPruneThresh;
        elseif ispc
            % Code to run on Windows platform
            BW3 = skeleton_win(Ifilled) > skelPruneThresh;
        else
            disp('Platform not supported')
        end
        
        BW_thin = bwmorph(BW3,'thin',Inf);
    case 'voronoi'
        [BW3, v, e] = voronoiSkel(Ifilled,'trim',5,'fast',1.23);
        BW_thin = bwmorph(BW3,'thin',Inf);          
    case 'fast_marching'
        % Crack centerline using the FMM
        S = skeletonFMM(Iground_smoothed);

        % Poplutate the skeleton in binary image
        BW_thin = false(size(Iground_smoothed));
        for j=1:length(S)
            L=S{j};
            x = round(L(:,1));
            y = round(L(:,2));
            for m = 1:numel(x)
                    BW_thin(x(m),y(m)) = 1;
            end
        end
end


% f = figure(10); imshow(Igray)
% imwrite(BW_thin, 'weirdcase_05.bmp');

% Get branch and end points
BW_bp   = bwmorph(BW_thin,'branchpoints');
[rowBP, colBP] = find(BW_bp);
branch_points    = [rowBP, colBP]; %#ok<*NASGU>

BW_ep   = bwmorph(BW_thin, 'endpoints');
[rowEP, colEP] = find(BW_ep);
end_points       = [rowEP, colEP];

% Initialization
allBranches_Count = zeros(size(rowBP));
debranchedImage = [];
branchFill = [];

% Find number of intersections
for i = 1:length(rowBP)
   bpi = rowBP(i);
   bpj = colBP(i);
   
   W = BW_thin(bpi,bpj-1);
   E = BW_thin(bpi,bpj+1);
   
   N = BW_thin(bpi-1,bpj);
   S = BW_thin(bpi+1,bpj);
   
   NE = BW_thin(bpi-1,bpj+1);
   SE = BW_thin(bpi+1,bpj+1);
   
   NW = BW_thin(bpi-1,bpj-1);
   SW = BW_thin(bpi+1,bpj-1);
   
   allBranches_Count(i) = N+E+W+S+NE+SE+NW+SW; 
end

% BP2EP BP2BP traverse points (Mohsin's code)
% Mohsin's traversing code callback
[strand_collection, points_collection, non_visited_points]  = ...
            BPDetection_Mohsin(BW_thin, branch_points, end_points, rows, columns);

% Extracts decison matrix to check splitable BPs
decisionMatrix = {};
for m = 1:size(branch_points,1)
    count_connectivity = 1;
    for n = 1:length(strand_collection)
        if (branch_points(m,:) == strand_collection{1, n}.points(1,:))
%             strand_collection{1, n}.points(:,1)
%             strand_collection{1, n}.points(:,2)
            arcLen = arclength(strand_collection{1, n}.points(:,1), strand_collection{1, n}.points(:,2),'linear'); 
            decisionMatrix{m}{count_connectivity,1} = [branch_points(m,:), strand_collection{1, n}.points(ceil(end/2),:), ...
                                                       strand_collection{1, n}.points(end,:), arcLen];
            count_connectivity = count_connectivity + 1;
        end
        if (branch_points(m,:) == strand_collection{1, n}.points(end,:))
            arcLen = arclength(strand_collection{1, n}.points(:,1), strand_collection{1, n}.points(:,2),'linear');
            decisionMatrix{m}{count_connectivity,1} = [branch_points(m,:), strand_collection{1, n}.points(ceil(end/2),:),...
                                                       strand_collection{1, n}.points(1,:), arcLen];
            count_connectivity = count_connectivity + 1;
        end
    end
end

decisionMatrix_array = cell2mat(vertcat(decisionMatrix{:}));

% Extract branch points that satisfy the length criterion
splitBPRowCol = [];
cntBP2split = 1;
for m = 1:length(decisionMatrix)
    if(length(decisionMatrix{m}) > 2)
        branchDecision = cell2mat(decisionMatrix{m});
        branchDist = branchDecision(:,7);
        branchDistGreatThresholdNum = find(branchDist > branchlengthThreshold);
        if(length(branchDistGreatThresholdNum) > 2)
            splitBPRowCol(cntBP2split,:) = branchDecision(1,1:2);
            cntBP2split = cntBP2split + 1;
        end
    end
end

% Initialization
branches_Count = zeros(size(splitBPRowCol,1),1);

% Find number of intersections
for i = 1:size(splitBPRowCol,1)
   bpi = splitBPRowCol(i,1);
   bpj = splitBPRowCol(i,2);
   
   W = BW_thin(bpi,bpj-1);
   E = BW_thin(bpi,bpj+1);
   
   N = BW_thin(bpi-1,bpj);
   S = BW_thin(bpi+1,bpj);
   
   NE = BW_thin(bpi-1,bpj+1);
   SE = BW_thin(bpi+1,bpj+1);
   
   NW = BW_thin(bpi-1,bpj-1);
   SW = BW_thin(bpi+1,bpj-1);
   
   branches_Count(i) = N+E+W+S+NE+SE+NW+SW; 
end

% Initializations
searchRadius = 1;
branch_num = length(branches_Count);
storeCircCoords = cell(branch_num,1);
circRadii = zeros(branch_num,1);

for i = 1:branch_num
    
    while (1)
        
        % Bound counter
        boundCounter = 0;
        
        % Get circle coordinates
        [xc, yc] = getmidpointcircle(splitBPRowCol(i,2), splitBPRowCol(i,1), searchRadius);

        % Bound check
        negxc = find(xc <= 0);
        negyc = find(yc <= 0);
        maxcolxc = find(xc > columns);
        maxrocyc = find(yc > rows);
        
        if (numel(negxc) > 1 || numel(negyc) > 1 || numel(maxcolxc) > 1 || numel(maxrocyc) > 1)
            boundCounter = 1;
        end
        
        % Check and replace max/min limits (coordinates)
        xc(xc <= 0)  = 1;
        yc(yc <= 0)  = 1;
        
        xc(xc > columns)= columns;
        yc(yc > rows)   = rows;
        

        % Branch transition points initialize
        branchTransition = 0;
        
        for j = 1:length(xc)-1
            pixelColor_i = BW(yc(j), xc(j));
            pixelColor_j = BW(yc(j+1), xc(j+1));
            if(abs(pixelColor_i - pixelColor_j) ~= 0)
                branchTransition = branchTransition + 1;
            end  
        end
        if(branchTransition >= branches_Count(i) * 2 || boundCounter == 1)
            break;
        end
        searchRadius = searchRadius + 1;
        
    end
    
    % Store circle corodinates and radii
    storeCircCoords{i} = [xc, yc];
    circRadii(i) = searchRadius;
end

% Image of binary circles
circImage = false(rows, columns); 
for i = 1:length(storeCircCoords)
    circCoords = storeCircCoords{i};
    for j = 1:size(circCoords,1)
        circImage(circCoords(j,2),circCoords(j,1)) = true;
    end
end

% Fill the cicles (flood filling)
if ~(isempty(splitBPRowCol))
    circImageFilled = imfill(circImage,[splitBPRowCol(:,1), splitBPRowCol(:,2)],4);
    branchFill      = bitand(BW,circImageFilled);
    
    % Debranched image
    debranchedImage = imsubtract(BW,branchFill);
    debranchedImage = logical(debranchedImage);
else
    circImageFilled = [];
end

if (isempty(debranchedImage) && isempty(branchFill))
    isany_branches = 'no';
else
    isany_branches = 'yes';
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Show figures
if (strcmp(showFigure,'yes'))
    f1 = figure(3);
    set(f1,'Name','Crack Debranch','NumberTitle','on')
    
    % Original image
    ax1 = subplot(2,4,1); imshow(Igray);
    title('Original image');
    
    % BW image
    ax2 = subplot(2,4,2); imshow(BW);
    title('BW image');
    
    % Overlay image
    rgb = imoverlay(BW, circImageFilled, [0 1 0]);
    ax3 = subplot(2,4,3); imshow(rgb)
    hold on
    for i =1:length(storeCircCoords)
        cricCoord = storeCircCoords{i};
        plot(cricCoord(:,1),cricCoord(:,2),'.r');
    end
    hold off
    title('Overlay image');

    % Branch/end points image
    ax4 = subplot(2,4,4); imshow(BW_thin);
    hold on ; 
    if ~(isempty(branch_points))
        plot(branch_points(:,2),branch_points(:,1),'rx');
        plot(end_points(:,2),end_points(:,1),'*');
        legend('Branch points','End points')
    else
        plot(end_points(:,2),end_points(:,1),'*');
        legend('End points')
    end
    hold off
    title('Branch/end points');
    
    % Branches text
    if ~(isempty(branches_Count))
        textCell = cellstr(string(allBranches_Count));
        RGBtext  = insertText(Igray,[colBP,rowBP],textCell,'FontSize',18,...
                             'TextColor',[0 1 0]);
        ax5 = subplot(2,4,5); imshow(RGBtext);
    else
        ax5 = subplot(2,4,5); imshow([]);
    end
     title('Branches number');
    
    if ~(isempty(branches_Count) && isempty(splitBPRowCol))
        % Branches/end points at traversed branch/end point
        branch_pts_unq = unique([decisionMatrix_array(:,1),decisionMatrix_array(:,2)],'rows','stable');
        end_pts_unq    = unique([decisionMatrix_array(:,5),decisionMatrix_array(:,6)],'rows','stable');

        BPtextCell = cellstr(join(string(branch_pts_unq),','));
        EPtextCell = cellstr(join(string(end_pts_unq),','));
        strand_length_textCell = cellstr(num2str(decisionMatrix_array(:,7),'%.1f'));
        
        % Text inputs
        text2disp = [BPtextCell;strand_length_textCell;EPtextCell];
        textPosition = [branch_pts_unq(:,2),branch_pts_unq(:,1); decisionMatrix_array(:,4),decisionMatrix_array(:,3); ...
                        end_pts_unq(:,2), end_pts_unq(:,1)];
        
        % Text insertion
        BPTravPointtext = insertText(Igray,textPosition,text2disp,'FontSize',12,...
                                 'TextColor',[0 1 0]);
        ax6 = subplot(2,4,6); imshow(BPTravPointtext);
    else
        ax6 = subplot(2,4,6); imshow([]);
    end
    title('BP to EPs and it''s Distance');

    if ~(isempty(branchFill))
        ax7 = subplot(2,4,7); imshow(branchFill);
    else
        ax7 = subplot(2,4,7); imshow([]);
    end
    title('Filled image');
    
    if ~(isempty(branchFill))
        ax8 = subplot(2,4,8); imshow(debranchedImage);
    else
        ax8 = subplot(2,4,8); imshow([]);
    end  
    title('Debranched image');
    
    drawnow;
    
    linkaxes([ax1,ax2,ax3,ax4,ax5,ax6,ax7,ax8],'xy')
    

end
end


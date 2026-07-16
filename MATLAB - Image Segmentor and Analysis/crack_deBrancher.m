function [debranchedImage, circImageFilled] = crack_deBrancher(Igray,BW,thinPrune,...
    pruneThresh,showFigure)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Image size
[rows, columns, ~] = size(BW);

% Skeleton prune threshold
skelPruneThresh = floor(max(rows,columns) * pruneThresh);

% se = strel('disk', 5);
% BW = imopen(BW,se);

% Image branch/end points extraction
switch thinPrune
    case 'conventional'
        BW_thin = bwmorph(BW,'thin',Inf);
    case 'alex'
        BW2 = skeleton(BW) > skelPruneThresh;
        BW_thin = bwmorph(BW2,'thin',Inf);
    case 'voronoi'
        [BW_thin, v, e] = voronoiSkel(BW,'trim',5,'fast',1.23);
end

BW_bp   = bwmorph(BW_thin,'branchpoints');
[rowBP, colBP] = find(BW_bp);
branchPts    = [rowBP, colBP]; %#ok<*NASGU>

BW_ep    = bwmorph(BW_thin, 'endpoints');
[rowEP, colEP] = find(BW_ep);
endPts       = [rowEP, colEP];

% Initialization
branches_Count = zeros(size(rowBP));

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
        [xc, yc] = getmidpointcircle(colBP(i), rowBP(i), searchRadius);

        % Bound check
        negxc = find(xc <= 0);
        negyc = find(yc <= 0);
        maxcolxc = find(xc > columns);
        maxrocyc = find(yc > rows);
        
        if (numel(negxc) > 1 || numel(negxc) > 1 || numel(maxcolxc) > 1 || numel(maxrocyc) > 1)
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
circImageFilled = imfill(circImage,[rowBP, colBP],4);

% Debranched image
debranchedImage = imsubtract(BW,circImageFilled);
debranchedImage(debranchedImage == -1)  = 0;
debranchedImage = logical(debranchedImage);

% Show figures
if (strcmp(showFigure,'yes'))
    f1 = figure(1);
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
    if ~(isempty(branchPts))
        plot(branchPts(:,2),branchPts(:,1),'rx');
        plot(endPts(:,2),endPts(:,1),'*');
        legend('Branch points','End points')
    else
        plot(endPts(:,2),endPts(:,1),'*');
        legend('End points')
    end
    hold off
    title('Branch/end points');
    
    
    % Branches text
    if ~(isempty(branches_Count))
        textCell = cellstr(string(branches_Count));
        RGBtext  = insertText(Igray,[colBP,rowBP],textCell,'FontSize',18,...
                             'TextColor',[0 1 0]);
        ax5 = subplot(2,4,5); imshow(RGBtext);
        title('Branches number');
    else
        ax5 = subplot(2,4,5); imshow([]);
    end
    
    
    ax6 = subplot(2,4,6); imshow(circImageFilled);
    title('Filled image');
    
    ax7 = subplot(2,4,7); imshow(debranchedImage);
    title('Debranched image');
    
    linkaxes([ax1,ax2,ax3,ax4,ax5,ax6,ax7],'xy')
end
end


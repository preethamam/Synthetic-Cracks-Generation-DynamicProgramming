function [debranchedImage, circImageFilled] = crack_deBrancher_BPLengthConstraint(Igray,BW,thinPrune,...
    pruneThresh,branchlengthThreshold,showFigure)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% Image size
[rows, columns, ~] = size(BW);

% Skeleton prune threshold
skelPruneThresh = floor(max(rows,columns) * pruneThresh);

se = strel('disk', 5);
BW = imopen(BW,se);

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

% Geo-desic distance finder
D = bwdistgeodesic(BW_thin,find(BW_bp),'quasi-euclidean');

% Counter and array initialization
cntBPvalid = 1;
traverseEPindx = [];

for i=1:length(rowEP) 
   if(D(rowEP(i),colEP(i)) > 0 && ~isinf(D(rowEP(i),colEP(i))))
       
      % On pixel position
      onPixelrow = rowEP(i);
      onPixelcol = colEP(i);
     
      % On pixel counter
      cnt = 1;
      AccumijTotal   = [];
      
       while(1)
          
          % 8-noded Neighbors
          W = BW_thin(onPixelrow,onPixelcol-1);
          E = BW_thin(onPixelrow,onPixelcol+1);
          N = BW_thin(onPixelrow-1,onPixelcol);
          S = BW_thin(onPixelrow+1,onPixelcol);

          NE = BW_thin(onPixelrow-1,onPixelcol+1);
          SE = BW_thin(onPixelrow+1,onPixelcol+1);
          NW = BW_thin(onPixelrow-1,onPixelcol-1);
          SW = BW_thin(onPixelrow+1,onPixelcol-1);
          
          % Start pixel coords
          accumij = [onPixelrow,onPixelcol];
          
          % Counter to store acuumataing row and cols of on pixels
          cnt2 = 2;
          
          % NEWS/NESENWSW on pixels accumulation
          if(W == true)
              newepi = onPixelrow;
              newepj = onPixelcol-1;
              accumij(cnt2,:) = [newepi newepj];
              cnt2 = cnt2 + 1; 
          end
          if(E == true)
              newepi = onPixelrow;
              newepj = onPixelcol+1;
              accumij(cnt2,:) = [newepi newepj];
              cnt2 = cnt2 + 1;
          end
          if(N == true)
              newepi = onPixelrow-1;
              newepj = onPixelcol;
              accumij(cnt2,:) = [newepi newepj];
              cnt2 = cnt2 + 1;
          end
          if(S == true)
              newepi = onPixelrow+1;
              newepj = onPixelcol;
              accumij(cnt2,:) = [newepi newepj];
              cnt2 = cnt2 + 1;
          end
          if(NE == true)
              newepi = onPixelrow-1;
              newepj = onPixelcol+1;
              accumij(cnt2,:) = [newepi newepj];
              cnt2 = cnt2 + 1;
          end
          if(SE == true)
              newepi = onPixelrow+1;
              newepj = onPixelcol+1;
              accumij(cnt2,:) = [newepi newepj];
              cnt2 = cnt2 + 1;
          end
          if(NW == true)
              newepi = onPixelrow-1;
              newepj = onPixelcol-1;
              accumij(cnt2,:) = [newepi newepj];
              cnt2 = cnt2 + 1;
          end
          if(SW == true)
              newepi = onPixelrow+1;
              newepj = onPixelcol-1;
              accumij(cnt2,:) = [newepi newepj];
              cnt2 = cnt2 + 1;
          end
          
          % Unique row, column push 
          AccumijTotal = unique([AccumijTotal; accumij],'stable','rows');
          
          % On pixel position update
          onPixelrow = AccumijTotal(end,1);
          onPixelcol = AccumijTotal(end,2);
          
          % Store on pixel coordinates 
          allOnPixelsCoords(cnt,:) = [onPixelrow onPixelcol];
          allOnPixelsCoordsBranches{cntBPvalid} = allOnPixelsCoords;
           
          % 5x5 box start/end pixels
          onPixelRowTopEnd = onPixelrow-2;
          onPixelRowBottomEnd = onPixelrow+2;
          onPixelColRightEnd = onPixelcol+2;
          onPixelColLeftEnd = onPixelcol-2;
          
          % Check and set limits
          if (onPixelRowTopEnd < 0)
              onPixelRowTopEnd = 1;
          end
          if (onPixelRowBottomEnd > row)
              onPixelRowBottomEnd = row;
          end
          if (onPixelColLeftEnd < 0)
              onPixelColLeftEnd = 1;
          end
          if (onPixelColRightEnd > columns)
              onPixelColRightEnd = columns;
          end
          
          % Grid coordinates
          [p,q] = meshgrid(onPixelColLeftEnd:onPixelColRightEnd, ...
                           onPixelRowTopEnd:onPixelRowBottomEnd);
          
          % Brachpoint close by             
          predictBP = [q(:) p(:)];
          
          % Intersect two arrays and obtain the BP reached 
          C = intersect(branchPts,predictBP,'stable','rows');
          
          % Store the BP
          if(~isempty(C))
               BParray2crackBranch(cntBPvalid,:) = C;
               break;
          end
          
          % Counter increment of on pixels
          cnt = cnt+1;
       end

       % Store traversed end point
       traverseEPindx(cntBPvalid,:) =  [rowEP(i),colEP(i)];
       
       
       % Decision matrix
       decisionMatrix(cntBPvalid,:) = [traverseEPindx(cntBPvalid,:) BParray2crackBranch(cntBPvalid,:)...
                        D(rowEP(i),colEP(i))];
       
       % Valid BP counter
       cntBPvalid = cntBPvalid + 1;
   end
end

% Extracts decison matrix passed BPs
validBPs = decisionMatrix(:,3:4);
[cc,ia,ib] = unique(validBPs,'stable','rows');
unqib = unique(ib);

% Extract branch points that satisfy the length criterion
splitBPRowCol = [];
cntBP2split = 1;
for i = 1:length(unqib)
    classIndx  = find(ib == unqib(i));
    branchDist = decisionMatrix(classIndx,5);
    BPelements = length(branchDist);
    if(BPelements > 1)
        if(branchDist > branchlengthThreshold)
            splitBPRowCol(cntBP2split,:) = decisionMatrix(classIndx(1),3:4);
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
circImageFilled = imfill(circImage,[splitBPRowCol(:,1), splitBPRowCol(:,2)],4);

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
    
    % Branches/end points at traversed branch/end point
    if ~(isempty(splitBPRowCol))
        BPtextCell = cellstr(join(string([splitBPRowCol(:,2),splitBPRowCol(:,1)]),','));
        travEPtextCell = cellstr(string(D(traverseEPindx(:,2), traverseEPindx(:,1))));
        
        % Text inputs
        text2disp = [BPtextCell;travEPtextCell];
        textPosition = [splitBPRowCol(:,2),splitBPRowCol(:,1); traverseEPindx(:,2), traverseEPindx(:,1)];
        
        % Text insertion
        BPTravPointtext = insertText(Igray,textPosition,text2disp,'FontSize',18,...
                                 'TextColor',[0 1 0]);
        ax6 = subplot(2,4,6); imshow(BPTravPointtext);
    else
        ax6 = subplot(2,4,6); imshow([]);
    end

    ax7 = subplot(2,4,7); imshow(circImageFilled);
    title('Filled image');
    
    ax8 = subplot(2,4,8); imshow(debranchedImage);
    title('Debranched image');
    
    linkaxes([ax1,ax2,ax3,ax4,ax5,ax6,ax7,ax8],'xy')
end
end


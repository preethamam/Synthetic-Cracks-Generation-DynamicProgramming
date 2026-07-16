function [Feature_Matrix_Total, Label_Matrix_Total, BBoxes, PixelCoord, CircIndex,Branch_points,holes]...
            = crack_non_crackfeaturesNlabels_2018Revised_5JahanFeatures...
            (imColor, imGrayscale, BW_image, BW_image_debranched, GT, classname, input)


% Image height, width
[oriheight, oriwidth, bitdepth] = size (imColor);
if ~(islogical(BW_image))
    BW_image = logical(BW_image);
end

if ~(islogical(BW_image_debranched))
    BW_image_debranched = logical(BW_image_debranched);
end

switch input.crackDebrancher_required
    
        case 'yes'
            % Region properties callback
            % Algortithm output
            STATS = regionprops(BW_image_debranched, 'Area', 'BoundingBox', 'Eccentricity', 'EulerNumber', 'ConvexArea', 'EquivDiameter', 'Extent', 'MajorAxisLength', ...
                                'MinorAxisLength', 'Orientation', 'Perimeter', 'Solidity', 'Centroid','PixelList');
            BW_image = BW_image_debranched;
            
        case 'no'
            % Region properties callback
            % Algortithm output
            STATS = regionprops(BW_image, 'Area', 'BoundingBox', 'Eccentricity', 'EulerNumber', 'ConvexArea', 'EquivDiameter', 'Extent', 'MajorAxisLength', ...
                                'MinorAxisLength', 'Orientation', 'Perimeter', 'Solidity', 'Centroid','PixelList');
        
end

% BBoxes
BBoxes = {cat(1,STATS.BoundingBox)};

% Images rows and columns of the connected components
crackPix_col = arrayfun(@(x) x.PixelList(:,1),STATS, 'UniformOutput', false); 
crackPix_row = arrayfun(@(x) x.PixelList(:,2),STATS, 'UniformOutput', false);

% Labels of 
L = bwlabel(BW_image);

if ~(isempty(STATS))
    % Feature_Matrix 1 - Eccentricity             
    Feature_Matrix(:,1) = {STATS.Eccentricity};

    % Feature_Matrix 2 - area / ellipse area
    Feature_Matrix(:,2) = cellfun(@(x, a, b) x /(pi * a * b), {STATS.Area}, ...
                             {STATS.MajorAxisLength}, {STATS.MinorAxisLength}, 'UniformOutput', 0);

    % Feature_Matrix 3 - Soliditity
    Feature_Matrix(:,3) = {STATS.Solidity};

    % Feature_Matrix 4 - Absolute correlation coefficient
    Feature_Matrix(:,4)  = cellfun(@(x,y) abs (corr2(x,y)),crackPix_row, crackPix_col, ...
                            'UniformOutput',false);

    % Feature_Matrix 5 - Compactness
    Feature_Matrix(:,5) = cellfun(@(a, b) sqrt(a/b) , {STATS.Area}, ...
                             {STATS.Perimeter}, 'UniformOutput', 0);
else
    Feature_Matrix = [];
end


% Store all the featture matrix for ground-truth and noisy images
% Also remove NAN and Inf
Feature_Matrix  = cell2mat(Feature_Matrix);
Feature_Matrix(isinf(Feature_Matrix) | isnan(Feature_Matrix)) = 0;

% Populate the feature matrix
Feature_Matrix_Total   = Feature_Matrix;

% Total label matrix
switch input.labelMatixType
    case 'training'
        Label_Matrix   = cell(length(STATS), 1);
        Label_Matrix(cellfun(@isempty,Label_Matrix)) = {classname};
    case 'testing'
        Label_Matrix   = cell(length(STATS), 1);
        Label_Matrix(cellfun(@isempty,Label_Matrix)) = {input.non_crack_class};
        for i = 1:length(STATS)

            % Images rows and columns of the connected components in Alg. output
            c = STATS(i).PixelList(:,1);
            r = STATS(i).PixelList(:,2);

            % BWSELECT to select the overlapping connected components
            if ~(isempty(GT))
                GTij = bwselect(GT,c,r,8);
                GTpixsum = sum(sum(GTij));
                overlap_pix = floor(input.CC_overlap_percent*GTpixsum);
                Alg_CCpix = numel(c);

                % Condition to check the overlap > 50%
                if(GTpixsum > 1) 
                    if ((Alg_CCpix >= GTpixsum-overlap_pix) || (Alg_CCpix <= GTpixsum+overlap_pix))
                        Label_Matrix(i) = {input.crack_class};
                    end
                end
            end
        end
end
Label_Matrix_Total     = Label_Matrix;

% Branch-points number (total)/holes
Branch_points = cell(length(STATS),1);
holes = zeros(length(STATS),1);

if (strcmp(input.labelMatixType, 'testing') && ~isempty(input.branchpoints))
    for j = 1:length(STATS)

        % Images rows and columns of the connected components
        crackPix_colBP = STATS(j).PixelList(:,1);
        crackPix_rowBP = STATS(j).PixelList(:,2);

        % Create each connected component images
        BW_image_CC             = zeros(size(BW_image));
        BW_image_CC(sub2ind(size(BW_image_CC), crackPix_rowBP, ...
        crackPix_colBP))          = 1;

        % Perform thinning of the image
        thin                    = bwmorph(BW_image_CC,'thin','inf');

        % Find the branchpoints
        branchpnts              = bwmorph(thin,'branchpoints');
        [bprow, bpcolumn]       = find(branchpnts);

        % Find the number of branchpoints
        Branch_points{j}    = numel(bprow);

        % Holes in connected components (objects/blobs)
        if (STATS(j).EulerNumber ~= 1)
            holes(j) = 0;
        else
            holes(j) = 1;
        end
    end
end

% Pixel coordinates of each components [row, col]
PixelCoord             = {crackPix_row, crackPix_col};

% Circularity index
CircIndex = cellfun(@(a, p) (4 * pi* a) / p^2, {STATS.Area}, {STATS.Perimeter}, 'UniformOutput', 0);

if (strcmp(input.figShow_visLabels,'yes'))
    f1 = figure(2);
    set(f1,'Name','BW Labels','NumberTitle','on')
    vis_Labels_CircIndex(L, CircIndex)
end
end
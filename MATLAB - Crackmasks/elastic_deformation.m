function [img_elastic,img_elastic2] = elastic_deformation(img,img2,SIGMA,alpha,geotrans_type,...
    alpha_geotrans, poly_degree, showfig_points)

% Inputs recommended
% Valid parameters for elastic deformation of synthetic cracks
% affine     | alpha_geotrans [30 70] | SIGMA = 5 | alpha = [15 35]
% projective | alpha_geotrans [30 70] | SIGMA = 5 | alpha = [15 35]
% polynomial | Degree 2 | alpha_geotrans [5 10] | SIGMA = 5 | alpha = [15 35]
% polynomial | Degree 3 | alpha_geotrans [2 4] | SIGMA = 5 | alpha = [15 35]
% polynomial | Degree 4 | alpha_geotrans [1] | SIGMA = 5 | alpha = [15 35]
% piecewise_linear | alpha_geotrans [80 100] | SIGMA = 5 | alpha = [15 35]
% local_weighted_mean: TOO MUCH DISTORTION (exploding pixels) NOT RECOMMEND TO USE THIS FOR SYNTHETIC CRACKS

% Auxillary variables
imsize = int32(size(img));
center_square = idivide(imsize, 2, 'floor');
square_size = idivide(min(imsize), 3, 'floor');
Rin = imref2d(size(img));

% assume img is your H×W (×C) image
[h, w, ~] = size(img);

% center and half-size of square (1/3 of min dimension)
cx = floor(w/2);          % center X (cols)
cy = floor(h/2);          % center Y (rows)
half = floor(min(h,w)/3);

% bounds of the square
xmin = cx - half;
xmax = cx + half;
ymin = cy - half;
ymax = cy + half;

% Create Affine transformation
switch geotrans_type
    case 'affine'    
        pts1 = double([center_square + square_size; [center_square(1) + square_size, center_square(2) - square_size]; ...
                           center_square - square_size]);        
        pts2 = pts1 + randi([-alpha_geotrans, alpha_geotrans],size(pts1));
        pts2 = pts2 + rand(size(pts2));
        tform = fitgeotrans(pts2,pts1,'affine');
        
    case 'projective'
        pts1 = double([center_square + square_size; [center_square(1) + square_size, center_square(2) - square_size]; ...
                           center_square - square_size; [center_square(1) - square_size, center_square(2) + square_size]]);
        pts2 = pts1 + randi([-alpha_geotrans, alpha_geotrans],size(pts1));
        pts2 = pts2 + rand(size(pts2));
        tform = fitgeotrans(pts2, pts1,'projective');
        
    case 'polynomial'            
        % number of control points
        switch poly_degree
            case 2
                numPts = 6;
            case 3
                numPts = 10;
            case 4
                numPts = 15;
        end

        pts1 = [ ...
            randi([xmin, xmax], numPts,1), ...
            randi([ymin, ymax], numPts,1) ...
        ];
        
        % clamp so nothing goes outside
        pts1(:,1) = min(max(pts1(:,1), 1), w);
        pts1(:,2) = min(max(pts1(:,2), 1), h);
        
        % add a small integer jitter in [2,10] pixels to each pt
        pts1 = pts1 + randi([2,10], size(pts1));
        
        % now generate pts2 by a small geometric perturbation
        % alpha_geotrans should be defined earlier
        delta = randi([-alpha_geotrans, alpha_geotrans], size(pts1)) + rand(size(pts1));
        pts2 = pts1 + delta;
        
        % clamp again just in case
        pts2(:,1) = min(max(pts2(:,1), 1), w);
        pts2(:,2) = min(max(pts2(:,2), 1), h);

        tform = fitgeotform2d(pts2, pts1,'polynomial', poly_degree);
                   
    case 'piecewise_linear'
        pts1 = double([center_square + square_size; [center_square(1) + square_size, center_square(2) - square_size]; ...
                           center_square - square_size; [center_square(1) - square_size, center_square(2) + square_size]]);
        pts2 = pts1 + randi([-alpha_geotrans, alpha_geotrans],size(pts1));
        tform = fitgeotform2d(pts2, pts1,'pwl');
              
    case 'local_weighted_mean'
        % number of control points
        numPts = 12;
        pts1 = [ ...
            randi([xmin, xmax], numPts,1), ...
            randi([ymin, ymax], numPts,1) ...
        ];

        % clamp so nothing goes outside
        pts1(:,1) = min(max(pts1(:,1), 1), w);
        pts1(:,2) = min(max(pts1(:,2), 1), h);

        % add a small integer jitter in [2,10] pixels to each pt
        pts1 = pts1 + randi([2,10], size(pts1));

        % now generate pts2 by a small geometric perturbation
        % alpha_geotrans should be defined earlier
        delta = randi([-alpha_geotrans, alpha_geotrans], size(pts1)) + rand(size(pts1));
        pts2 = pts1 + delta;

        % clamp again just in case
        pts2(:,1) = min(max(pts2(:,1), 1), w);
        pts2(:,2) = min(max(pts2(:,2), 1), h);

        tform = fitgeotform2d(pts2, pts1,'lwm',numPts);        
end

% Display moving and fixed points
if (showfig_points == 1)
    figure; imshow(img); 
    hold on;
    plot(pts1(:,1), pts1(:,2), 'r*', 'LineWidth', 2, 'MarkerSize', 10);
    plot(pts2(:,1), pts2(:,2), 'bd', 'LineWidth', 2, 'MarkerSize', 10);
    legend('Fixed Points', 'Moving Points','Location','West','FontSize',20)
    hold off
    
%     export_fig(['../../results/Hybrid Paper Figs/' 'fig_syncrack_gridlines.pdf'], '-pdf', '-transparent', gcf);
end

% Applying the displacement to the original pixels
% Compute a random displacement field
dx = -1 + 2*rand(size(img)); % dx ~ U(-1,1)
dy = -1 + 2*rand(size(img)); % dy ~ U(-1,1)

% Smoothing the field
fdx = imgaussfilt(dx,SIGMA,'FilterSize', 2*ceil(2*SIGMA)+1); % 2-D Gaussian filtering of dx
fdy = imgaussfilt(dy,SIGMA,'FilterSize', 2*ceil(2*SIGMA)+1); % 2-D Gaussian filtering of dy

fdx = alpha * fdx; % Scaling the filtered field
fdy = alpha * fdy; % Scaling the filtered field

% Warp the image based on moving and fixed points
[y,x] = ndgrid(1:size(img,1),1:size(img,2));

% Geometric transfomed image
geotrans_image = imwarp(img,tform,'OutputView',Rin);
img_elastic = griddata(x,y,double(geotrans_image),x+fdx,y+fdy);
img_elastic(isnan(img_elastic)) = 0;

if ~(isempty(img2))
    geotrans_image2 = imwarp(img2,tform,'OutputView',Rin,'FillValues',255);
    
    img_elastic2 = griddata(x,y,double(geotrans_image2),x+fdx,y+fdy);
    img_elastic2(isnan(img_elastic2)) = 0;
    
    figure; 
     subplot(1,4,1); imshow(img); 
    hold on;
    plot(pts1(:,1), pts1(:,2), 'r*', 'LineWidth', 2, 'MarkerSize', 10);
    plot(pts2(:,1), pts2(:,2), 'bd', 'LineWidth', 2, 'MarkerSize', 10);
    legend('Fixed Points', 'Moving Points','Location','West','FontSize',20)
    hold off

    subplot(1,4,2); imshow(geotrans_image)
    subplot(1,4,3); imshow(geotrans_image2)
    subplot(1,4,4); imshow(img_elastic2)
    
    if ~strcmp(geotrans_type, 'polynomial')
        imwrite(geotrans_image2, [geotrans_type '_geotrans_image' '.png'])
        imwrite(img_elastic2, [geotrans_type '_elastic_image' '.png'])
    else
        imwrite(geotrans_image2, [geotrans_type '_' num2str(poly_degree) '_geotrans_image' '.png'])
        imwrite(img_elastic2, [geotrans_type '_' num2str(poly_degree) '_elastic_image' '.png'])
    end
else
    img_elastic2 = [];
end

end
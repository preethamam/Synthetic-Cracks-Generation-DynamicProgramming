function [output, BW_skeleton] = Calculate_CrackWidthLength_Paper(input,BW4, figureStruct, seam, ...
                                                        ImageID,Igray)

    % Image size
    [rows, columns, ~] = size(BW4);

    % Skeleton prune threshold
    skelPruneThresh = floor(max(rows,columns) * input.thinPruneThresh);

    % Image branch/end points extraction
    switch input.thinPruneMethod
        case 'conventional'
            BW_skeleton = bwmorph(BW4,'thin',Inf);
        case 'alex'
            BW3 = skeleton(BW4) > skelPruneThresh;
            BW_skeleton = bwmorph(BW3,'thin',Inf);
        case 'voronoi'
            [BW3, v, e] = voronoiSkel(BW4,'trim',5,'fast',1.23);
            BW_skeleton = bwmorph(BW3,'thin',Inf);
        case 'FMM'

            % Crack centerline using the FMM
            S = skeletonFMM(BW4);
            
            % Poplutate the skeleton in binary image
            BW_skeleton = false(size(BW4));
            for i=1:length(S)
                L=S{i};
                x = round(L(:,1));
                y = round(L(:,2));
                for m = 1:numel(x)
                        BW_skeleton(x(m),y(m)) = 1;
                end
            end
    end
    
    %% Crack normal extraction
    %--------------------------------------------------------------------------
    % Calculate skeleton orientations
    Orientations = skeletonOrientation(BW_skeleton,input.skelOrientBlockSize); %5x5 box
    Onormal90 = BW_skeleton .* (Orientations + 90); %easier to view normals
    Onormal270 = BW_skeleton .*(Orientations + 270); %easier to view normals
    OnrOrient = sind(Orientations);
    OncOrient = cosd(Orientations);
    Onr90 = sind(Onormal90);   %vv
    Onc90 = cosd(Onormal90);   %uu
    Onr270 = sind(Onormal270);   %vv
    Onc270 = cosd(Onormal270);   %uu
    [r,Norm_BWWF] = find(BW_skeleton);   %row/cols
    idx = find(BW_skeleton == 1);     %Linear indices into Onr/Onc

    %% Crack width extraction
    %--------------------------------------------------------------------------
    angle_1 = Onormal90(idx);
    angle_2 = Onormal270(idx);
    mycell = cell(2,numel(r));
    XYBresenham = zeros(numel(angle_1),4);

    % Clock start
    for i=1:numel(r)
        mycell{1,i} = crackWidthLocation(Norm_BWWF(i),r(i),angle_1(i),BW4);
        mycell{2,i} = crackWidthLocation(Norm_BWWF(i),r(i),angle_2(i),BW4);
        XYBresenham(i,:) = [mycell{1,i}{1,1}(end), mycell{1, i}{2, 1}(end),...
                            mycell{2,i}{1,1}(end), mycell{2, i}{2, 1}(end)];
    end

    %% Find the crackline coordinates
    % cell, array initialization
    bresenham_cell = cell(length(XYBresenham),2);
    crackWidth_kernel = zeros(length(XYBresenham),1);
    crackWidth_bresenham = zeros(length(XYBresenham),1);

    % Clock start
    for i=1:size(XYBresenham,1)
        [x_bresenham, y_bresenham] = bresenham(XYBresenham(i,1), XYBresenham(i,2),...
                XYBresenham(i,3), XYBresenham(i,4));
        bresenham_cell{i,1} = x_bresenham;
        bresenham_cell{i,2} = y_bresenham;

    %     crackWidthLength = sqrt((XYBresenham(i,1) - XYBresenham(i,3))^2 + ...
    %                        (XYBresenham(i,2) - XYBresenham(i,4))^2);
    %     SE = strel('line',round(crackWidthLength),round(angle_1(i)));
    %     crackSEidx     = find(SE.Neighborhood);
    %     crackWidth_kernel(i)  = numel(crackSEidx);
        crackWidth_bresenham(i) = numel(x_bresenham);
    end

    %% Write output
    % Crackwidth scaled
    crackWidthscaled  = crackWidth_bresenham * input.pixelScale;
    crackLengthscaled = numel(idx) * input.pixelScale;

    % Moving window avaerage
    if (input.move_mean_median == 1)
        crackWidthscaled = movmean(crackWidthscaled, input.movWindowSize);
    else
        crackWidthscaled = movmedian(crackWidthscaled, input.movWindowSize);
    end

    if (isempty (crackWidthscaled))
        crackWidthscaled = 0;
    end
    
    % Cracks physical quantities
    myArea = numel(find(BW4 == 1));
    if (myArea > 0)
        % Statistics of crackwidth
        output.measured_length = crackLengthscaled;
        output.minCrackWidth = min(crackWidthscaled);
        output.maxCrackWidth = max(crackWidthscaled);
        output.averageCrackWidth = mean(crackWidthscaled);
        output.stdCrackWidth = std(crackWidthscaled);
        output.RMSCrackWidth = rms(crackWidthscaled);
        output.total_measure = numel(idx);
        output.totalArea = myArea;
    else
        % Statistics of crackwidth
        output.measured_length = 0;
        output.minCrackWidth = 0;
        output.maxCrackWidth = 0;
        output.averageCrackWidth = 0;
        output.stdCrackWidth = 0;
        output.RMSCrackWidth = 0;
        output.total_measure = 0;
        output.totalArea = 0;
    end
    
    
    % Plot figure
    % Write figure to file
    % Extract the file path, name and extension
    if ~isempty(ImageID)
        [pathstr,imagename,ext] = fileparts(ImageID);
        
        % Base filename 
        outputBaseFileName = sprintf('%s.png', imagename);
    end


    
    if (strcmp(input.figShow,'yes') && ~isempty(figureStruct))
        f1 = figure(2);
        set(f1,'Name','Crack Details','NumberTitle','on')
        f1.WindowState = 'maximized';

        % Original image
        ax1 = subplot(3,3,1); imshow(figureStruct.Igray);
        title('Original image');
        
        % Original image
        ax2 = subplot(3,3,2); imshow(figureStruct.Im_ad);
        title('Anisotropic image');
        
        % BW image
        ax3 = subplot(3,3,3); imshow(figureStruct.BW3);
        title('BW image'); 

        % Debranched image
        ax4 = subplot(3,3,4); imshow(figureStruct.branchFilledImage);
        title('Debranched image');

         % Debranched image
        ax5 = subplot(3,3,5); imshow(seam);
        title('Seam');
        
         % Debranched image
        ax6 = subplot(3,3,6); imshow(BW_skeleton);
        title('Skeleton');
        
        % ANN overlay image
        rgbANN = imoverlay(figureStruct.Igray, figureStruct.ANNimFinal, [1 0 0]);
        ax7 = subplot(3,3,7); imshow(rgbANN);
        title('ANN image');

        % KNN overlay image
        rgbKNN = imoverlay(figureStruct.Igray, figureStruct.KNNimFinal, [1 0 0]);
        ax8 = subplot(3,3,8); imshow(rgbKNN);
        title('KNN image');

        % SVM overlay image
        rgbSVM = imoverlay(figureStruct.Igray, figureStruct.SVMimFinal, [1 0 0]);
        ax9 = subplot(3,3,9); imshow(rgbSVM);
        title('SVM image');

        linkaxes([ax1,ax2,ax3,ax4,ax5,ax6,ax7,ax8,ax9],'xy')
        
        switch input.Algorithm_TYPE

            case 'hybrid_hessian'
               % Image write
               saveas(gcf, fullfile(input.writeAlgoOutputFig2folder,'Frangi', outputBaseFileName));

            case'hybrid_MFAT'
               % Image write
               saveas(gcf, fullfile(input.writeAlgoOutputFig2folder,'MFAT', outputBaseFileName));

            case 'morpho'
               % Image write
               saveas(gcf, fullfile(input.writeAlgoOutputFig2folder,'Morpho', outputBaseFileName));
               
           case 'CNN'
               % Image write
               saveas(gcf, fullfile(input.writeAlgoOutputFig2folder,'CNN', outputBaseFileName));
        end
        
    elseif strcmp(input.figShow,'yes') && isempty(figureStruct) &&  strcmp(input.Algorithm_TYPE,'CNN')
        
        f1 = figure(2);
        set(f1,'Name','Crack Details','NumberTitle','on')
        f1.WindowState = 'maximized';
        
        % Debranched image
        ax1 = subplot(2,2,1); imshow(uint8(Igray));
        title('Original image');
        
        ax2 = subplot(2,2,2); imshow(BW4);
        title('CNN output');
        
        ax3 = subplot(2,2,3); imshow(seam);
        title('Seam');
        
         % Debranched image
        ax4 = subplot(2,2,4); imshow(BW_skeleton);
        title('Skeleton');
        
        linkaxes([ax1,ax2,ax3,ax4],'xy')
        
        switch input.Algorithm_TYPE

            case 'hybrid_hessian'
               % Image write
               saveas(gcf, fullfile(input.writeAlgoOutputFig2folder,'Frangi', outputBaseFileName));

            case'hybrid_MFAT'
               % Image write
               saveas(gcf, fullfile(input.writeAlgoOutputFig2folder,'MFAT', outputBaseFileName));

            case 'morpho'
               % Image write
               saveas(gcf, fullfile(input.writeAlgoOutputFig2folder,'Morpho', outputBaseFileName));
               
           case 'CNN'
               % Image write
               saveas(gcf, fullfile(input.writeAlgoOutputFig2folder,'CNN', outputBaseFileName));
        end
    end
    
end


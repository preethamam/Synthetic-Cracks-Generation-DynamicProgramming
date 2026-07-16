function clusterCracksStrands(input, real_crack_Imgs)


%Before the loop, we need to construct the object. 
WaitMessage = waitbarParfor(length(real_crack_Imgs), 'Waitbar', true);

parfor i = 1:length(real_crack_Imgs)

    %Send a message to the object. 
    WaitMessage.Send;

    % Read image    
    BW = imread(fullfile(real_crack_Imgs(i).folder, real_crack_Imgs(i).name));

    % Get image filename parts
    [filepath,name,ext] = fileparts(real_crack_Imgs(i).name);  

    %----------------------------------------------------------
    % Close small holes and/or smooth boundaries
    %----------------------------------------------------------                                
    switch input.boundary_smooth 
        case 1
            se = strel('disk', input.imclose_disk_size);
            Iground_smoothed = imclose(BW,se);
        case 2
            kernel = ones(input.windowSize) / input.windowSize ^ 2;
            blurryImage = conv2(single(BW), kernel, 'same');
            Iground_smoothed = blurryImage > 0.5; % Rethreshold
        otherwise
            Iground_smoothed = BW;
    end
    
    % Image size
    [rows, columns, ~] = size(Iground_smoothed);
    
    % Skeleton prune threshold
    skelPruneThresh = floor(max(rows,columns) * input.thinPruneThresh);
    
    % Fill the holes
    Ifilled = imfill(Iground_smoothed,'holes');
    
    % Image branch/end points extraction
    switch input.thinPruneMethod
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
    
    % Get branch and end points
    BW_bp   = bwmorph(BW_thin,'branchpoints');
    [rowBP, colBP] = find(BW_bp);
    branch_points    = [rowBP, colBP]; %#ok<*NASGU>
    
    BW_ep   = bwmorph(BW_thin, 'endpoints');
    [rowEP, colEP] = find(BW_ep);
    end_points       = [rowEP, colEP];

    % Region properties callback
    % Algortithm output
    STATS = regionprops(BW_thin,'PixelList');
    
    cnt = 1;
    cnt2 = 1;
    for j = 1:length(STATS)
        blobPixels = STATS(j).PixelList;        
        blobPixels = fliplr(blobPixels);

        branch_points_found = intersect(blobPixels, branch_points, 'rows');
        total_bps = size(branch_points_found,1);

        if total_bps == input.BPClusters(1)
            folderPath = fullfile(input.BPClusterImgsSavePath, num2str(total_bps));
            [status, msg, msgID] = mkdir(folderPath);
            BW_selected = bwselect(BW,blobPixels(:,2), blobPixels(:,1), 8);

            % Write image                                  
            imwrite(BW_selected, fullfile(folderPath, [name '_' num2str(cnt) '.png']))
            cnt = cnt + 1;

        elseif total_bps >= input.BPClusters(2) - input.BPClusters(1)
            folderPath = fullfile(input.BPClusterImgsSavePath, num2str(input.BPClusters(2) - input.BPClusters(1)));
            [status, msg, msgID] = mkdir(folderPath);
            BW_selected = bwselect(BW,blobPixels(:,2), blobPixels(:,1), 8);

            % Write image             
            imwrite(BW_selected, fullfile(folderPath, [name '_' num2str(cnt2) '.png']))            
            cnt2 = cnt2 + 1;
        end
    end
    
    % Show branch and end points plots
    if input.showFigure
        ShowBPEPPlot(BW, BW_thin, branch_points, end_points)
    end
end

%Destroy the object.
WaitMessage.Destroy
end

function ShowBPEPPlot(BW, BW_thin, branch_points, end_points)
    f1 = figure;
    set(f1,'Name','Crack Debranch','NumberTitle','on')

    % BW image
    ax1 = subplot(1,2,1); imshow(BW);
    title('BW image');    

    % Branch/end points image
    ax2 = subplot(1,2,2); imshow(BW_thin);
    hold on ; 
    if ~(isempty(branch_points))
        plot(branch_points(:,2),branch_points(:,1),'rx');
        plot(end_points(:,2),end_points(:,1),'b*');
        legend('Branch points','End points')
    else
        plot(end_points(:,2),end_points(:,1),'*');
        legend('End points')
    end
    hold off
    title('Branch/end points');

    linkaxes([ax1,ax2],'xy')
end
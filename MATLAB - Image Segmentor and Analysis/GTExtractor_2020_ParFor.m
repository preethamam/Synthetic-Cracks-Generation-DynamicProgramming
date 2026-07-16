function [objBoxCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs] = ...
                                     GTExtractor_2020_ParFor (input,inputGroundTruthImagesPreRecall,...
                                     imgcount, classnumber, classNames, labelIDs)

    
%Before the loop, we need to construct the object. 
WaitMessage = waitbarParfor(length(inputGroundTruthImagesPreRecall), 'Waitbar', true);
     
% For all training images
parfor i = 1:length(inputGroundTruthImagesPreRecall)

    %Send a message to the object. 
    WaitMessage.Send;

    Iground = []; rows = []; cols = [];

    % Post-processing 
    %----------------------------------------------------------
    % Ground truth 
    %----------------------------------------------------------   
    % Get image ID
    ImageID_ground    = inputGroundTruthImagesPreRecall{i};
    
    % Read the ground truth image
    [imheight, imwidth, imbytesppix, Ioriginal, Igray] ...
            = imconversion2gray(ImageID_ground, input.gpuarray, input.resizeImage,...
                                input.maxImageResizePixels, input.resizeImageSize, ...  
                                input.resizeImageSizeScale, input.contrast_type); %#ok<*ASGLU>
                                    
    switch input.GTcolor_TYPE
        case 'color'
            
            % Switch statement for RGB and grayscale image
            switch input.colorspace
                case 'hsv'
                    switch imbytesppix
                        case 3
                            % RED | GREEN | BLUE
                            hsvImage        = rgb2hsv(Ioriginal);       % Convert the image to HSV space
                            hPlane          = 360.*hsvImage(:,:,1);     % Get the hue plane scaled from 0 to 360
                            sPlane          = hsvImage(:,:,2);          % Get the saturation plane
                            vPlane          = hsvImage(:,:,3);          % Get the saturation plane

                            nonRedIndex     = (((hPlane >= 20)  & (hPlane <= 340)) | ...  
                                              ((sPlane <= 0.8)  | (vPlane <= 0.8)));        % Select "non-red" pixels

                            nonGreenIndex   = ((hPlane >= 0)    & (hPlane <= 110)) | ...
                                              ((hPlane >= 130)  & (hPlane <= 360)) | ...
                                              ((sPlane <= 0.8)  | (vPlane <= 0.8));         % Select "non-green" pixels

                            nonBlueIndex    = ((hPlane >= 0)    & (hPlane <= 220)) | ...
                                              ((hPlane >= 260)  & (hPlane <= 360)) | ...
                                              ((sPlane <= 0.8)  | (vPlane <= 0.8));         % Select "non-blue" pixels

                            nonRGBIndex     = {nonRedIndex, nonGreenIndex, nonBlueIndex};

                            [val, index] = min([sum(nonRedIndex(:)), sum(nonGreenIndex(:)), ...
                                                sum(nonBlueIndex(:))]);

                            sPlane(nonRGBIndex{index}) = 0;      % Set the selected pixel saturations to 0
                            vPlane(nonRGBIndex{index}) = 0;      % Set the selected pixel values to 0
                            hsvImage(:,:,2) = sPlane;            % Update the saturation plane
                            hsvImage(:,:,3) = vPlane;            % Update the value plane
                            rgbImage = hsv2rgb(hsvImage);        % Convert the image back to RGB space

                            % Convert RGB to binary
                            Iground  = logical(rgbImage(:,:,1) + rgbImage(:,:,2) + ...
                                               rgbImage(:,:,3));

                       case 1
                            % Ground truth image
                            Iground = false(size(Ioriginal,1), size(Ioriginal,2));
                    end

                case 'rgb'
                    switch imbytesppix
                        case 3
                            % Image histogram for extracting R/G/B only pixels
                            Rcount = imhist(Ioriginal(:,:,1));
                            Gcount = imhist(Ioriginal(:,:,2));
                            Bcount = imhist(Ioriginal(:,:,3));

                            % Find maximum channel
                            RGBsum = [sum(Rcount(startBin : end)), sum(Gcount(startBin : end)),...
                                         sum(Bcount(startBin : end))];
                            [RGBsumcount, RGBsumIdx] = max(RGBsum);

                            % Extract the indices that have R or G or B channel only
                            switch RGBsumIdx
                                case 1
                                    [rows, cols, page] = ind2sub(size(Ioriginal), ....
                                        find(Ioriginal(:,:,1) > startBin & ...
                                        Ioriginal(:,:,2) < 0.15 * startBin & ...
                                        Ioriginal(:,:,3) < 0.15 * startBin)); %#ok<*NASGU>
                                case 2
                                    [rows, cols, page] = ind2sub(size(Ioriginal), ....
                                        find(Ioriginal(:,:,2) > startBin & ...
                                        Ioriginal(:,:,1) < 0.15 * startBin & ...
                                        Ioriginal(:,:,3) < 0.15 * startBin));
                                case 3
                                    [rows, cols, page] = ind2sub(size(Ioriginal), ....
                                        find(Ioriginal(:,:,3) > startBin & ...
                                        Ioriginal(:,:,1) < 0.15 * startBin & ...
                                        Ioriginal(:,:,2) < 0.15 * startBin));
                            end

                            % Ground truth image
                            Iground = zeros(size(Ioriginal,1), size(Ioriginal,2));
                            for ii = 1:length(rows)
                               Iground(rows(ii),cols(ii)) = 1; 
                            end

                            % Final ground truth image after low-level filtering.
                            % True signal (crack objects)
                            Iground = filter_stage_I (Iground);

                        case 1
                            % Ground truth image
                            Iground = false(size(Ioriginal,1), size(Ioriginal,2));
                    end
            end

        case 'binary'
            % Ground truth image
            if imbytesppix == 3
                Iground = imbinarize(rgb2gray(Ioriginal));
            else
                if islogical(Ioriginal)
                    Iground = Ioriginal;
                else
                    Iground = imbinarize(Ioriginal);
                end
            end
    end          

    % Ground-truth BBox
    CCIground = bwconncomp(Iground);
    BBoxes = regionprops(CCIground,'BoundingBox');
    statsIground{i} = cat(1,BBoxes.BoundingBox);
    statsIground_size = size(cat(1,BBoxes.BoundingBox),1);
    

    % Store GT pixel images
    [filepath,name,ext] = fileparts(ImageID_ground);

    % Write GT files to folder
    if (i <= imgcount(1))
%         if numel(dir(fullfile(input.PixLabelsFolder, 'crack'))) == 2 || ...
%                 numel(dir(fullfile(input.PixLabelsFolder,'crack'))) <= 2 + imgcount(1)
            outputBaseFileName = sprintf('%s.bmp', name);
            imwrite(Iground, fullfile(input.PixLabelsFolder, 'Pixel Labels', 'test_crack_bmp', outputBaseFileName),'bmp')
%         else
%             continue;
%         end
        BBoxesAccum_Labels{i} = categorical(repmat(classNames(1),statsIground_size,1));
    else
%         if numel(dir(fullfile(input.PixLabelsFolder,'non-crack'))) == 2 || ...
%                 numel(dir(fullfile(input.PixLabelsFolder,'non-crack'))) <= 2 + imgcount(2)
            outputBaseFileName = sprintf('%s.bmp', name);
%             imwrite(Iground, fullfile(input.PixLabelsFolder,'non-crack', outputBaseFileName),'bmp')
%         else
%             continue;
%         end
        BBoxesAccum_Labels{i} = []; %categorical(repmat(classNames(2),1,1));
    end
end
        
% Destroy the object.
WaitMessage.Destroy   

% Bounding box datastore
% CracksnNoncracksBBoxGTs = [statsIground', BBoxesAccum_Labels'];
switch input.ImagesType
    case 'crack_only'
        CracksnNoncracksBBoxGTs = cell(imgcount(1),1);       
        CracksnNoncracksBBoxGTs(1:imgcount(1),1)     = statsIground(1:imgcount(1));
        table_crackBBoxGTs = table(CracksnNoncracksBBoxGTs);
        table_crackBBoxGTs.Properties.VariableNames = classNames(1); 
        objBoxCracksnNoncracksGTs = boxLabelDatastore(table_crackBBoxGTs);
    case 'crackANDnoncracks'
        CracksnNoncracksBBoxGTs = cell(sum(imgcount),numel(unique(classnumber)));       
        CracksnNoncracksBBoxGTs(1:imgcount(1),1)     = statsIground(1:imgcount(1));
        CracksnNoncracksBBoxGTs(imgcount(1)+1:end,2) = statsIground(imgcount(1)+1:end);
        table_crackBBoxGTs = cell2table(CracksnNoncracksBBoxGTs);
        table_crackBBoxGTs.Properties.VariableNames = classNames;        
        objBoxCracksnNoncracksGTs = boxLabelDatastore(table_crackBBoxGTs);
end



% Semantic segmentation GTs
% Create a pixel label datastore holding the ground truth pixel labels for the test images.
switch input.ImagesType
    case 'crack_only'
        testLabelsDir_crack     = fullfile(input.PixLabelsFolder, 'Pixel Labels', 'test_crack_bmp');
        if (strcmp(input.bypassPixFolder, 'yes'))
            testLabelsDir_crack     = input.FolderPath;
        end

        % Pixel groundtruths
        ssmPixCracksnNoncracksGTs = pixelLabelDatastore(testLabelsDir_crack,...
                                                             classNames,labelIDs);
    case 'crackANDnoncracks'
        testLabelsDir_crack     = fullfile(input.PixLabelsFolder, 'Pixel Labels', 'test_crack_bmp');
        testLabelsDir_noncrack  = fullfile(input.PixLabelsFolder, 'Noncrack', 'test');

        % Pixel groundtruths
        ssmPixCracksnNoncracksGTs = pixelLabelDatastore({testLabelsDir_crack, testLabelsDir_noncrack},...
                                                             classNames,labelIDs);
end

end

function [ TruePositiveBbox, FalsePositiveBbox, FalseNegativeBbox] = ...
    TruePositive_FalsePositive_FalseNegative_Bbox_2021b...
    (imnum,Ioriginal, Icontrast, AnisoImageI, AnisoImageII, Iground2PrecisionRecall,Filtered_BW_image,...
      classifierImage, IAnnotate, filesavepath, saveFolderName, ...
      ImageID, classifierName, storeOutputImages, imheight, imwidth,filename,input)
  
%   input.figShow_TPFPFN = 'yes'
%   imwrite(Iground2PrecisionRecall,'a.bmp')
  
% Ground-truth BBox
CCIground = bwconncomp(Iground2PrecisionRecall);
statsIground     = regionprops(CCIground,'Area','BoundingBox');

% Classifier output BBox
CCIclassifier = bwconncomp(classifierImage);
statsIclassifier = regionprops(CCIclassifier,'Area','BoundingBox');


% True positive
TP = bitand(Iground2PrecisionRecall, classifierImage);

% False positive
FP = imsubtract(classifierImage,TP);
FP(FP == -1)  = 1;

% False negative
FN = imsubtract(Iground2PrecisionRecall,TP);
FN(FN == -1)  = 1;

% Count initialization
tpCount = 0;
fpCount = 0;
fnCount = 0;

Ioriginal_dup = Ioriginal;

% Extract file parts
[pathstr,name,ext] = fileparts(ImageID); %#ok<ASGLU>

% BBox image holder
RGB = [];

% Find TP/FP/FN counts and plot the bounding boxes
if (strcmp(input.figShow_TPFPFN,'yes'))
    f1 = figure(4);
    set(f1,'Name','TP FP FN','NumberTitle','on')
    hold on
end


if~(isempty(statsIground))
    gtarray = zeros(length(statsIground),1);
    for i = 1:length(statsIclassifier)
        bboxA = statsIclassifier(i).BoundingBox;
        maxIOUIndex = -1;
        maxIOU = -1;
        % Groud-truth BBox (green color)
        if (strcmp(input.figShow_TPFPFN,'yes'))
            RGB = insertShape(Ioriginal_dup,'Rectangle',bboxA,'Color','yellow',...
                                'Opacity',0.6);
        end
                        
        for j = 1:length(statsIground)                  
            bboxB = statsIground(j).BoundingBox;
            overlapRatio = bboxOverlapRatio(bboxA,bboxB);
            if (overlapRatio > maxIOU)
                maxIOUIndex = j;
                maxIOU = overlapRatio;
            end

            % Algorithm output BBox (yellow color)
            if (strcmp(input.figShow_TPFPFN,'yes'))
                RGB = insertShape(RGB,'Rectangle',bboxB,...
                    'Color','green','Opacity',0.6);
            end
        end
        
        if maxIOU < input.BBoxthreshold || maxIOUIndex == -1
            fpCount = fpCount + 1;
        elseif gtarray(maxIOUIndex) == 0
            gtarray(maxIOUIndex) = maxIOU;
            tpCount = tpCount + 1;
        elseif maxIOU > gtarray(maxIOUIndex)
            gtarray(maxIOUIndex) = maxIOU;
            fpCount = fpCount + 1;
        else
            fpCount = fpCount + 1;
        end
        Ioriginal_dup = RGB;
    end
    fnCount = length(statsIground) - tpCount;
   
else
    if~(isempty(statsIclassifier))
        % Find flase postive BBox to display
        bboxA = statsIclassifier(1).BoundingBox;
    else
        bboxA = [];
    end
        
    % Groud-truth BBox (green color)
    if (strcmp(input.figShow_TPFPFN,'yes'))
        RGB = insertShape(Ioriginal_dup,'Rectangle',bboxA,'Color','yellow',...
                            'Opacity',0.0);
    end
    for j = 1:length(statsIclassifier)
        fpCount = fpCount + 1;

        % Find flase postive BBox to display
        bboxB = statsIclassifier(j).BoundingBox;

        % Algorithm output BBox (yellow color)
        if (strcmp(input.figShow_TPFPFN,'yes'))
            RGB = insertShape(RGB,'Rectangle',bboxB,...
                'Color','yellow','Opacity',0.6);
        end
    end
end


% Plot the output and save them if needed

if (strcmp(input.figShow_TPFPFN,'yes'))
    hold off
    
    % Row 1
    ax1 = subplot(5,3,1); imshow(Ioriginal); title('Original')
    ax2 = subplot(5,3,2); imshow(uint8(Icontrast)); title('Contrasted')
    ax3 = subplot(5,3,3); imshow(IAnnotate); title('Annotated')

    % Row 2
    % Overlay
    ax4 = subplot(5,3,4); imshow(Iground2PrecisionRecall); title('Ground-truth')
    ax5 = subplot(5,3,5); imagesc((AnisoImageI)); colormap(gray); title('Anisotropic Stage I'); axis equal; axis tight; axis off; 
    ax6 = subplot(5,3,6); imagesc((AnisoImageII)); colormap(gray); title('Anisotropic Stage II'); axis equal; axis tight; axis off;

    % Row 3
    % Overlay 
    BW_overlay_classifier = imoverlay(Filtered_BW_image, classifierImage, [1 1 0]);
    ax7 = subplot(5,3,7); imshow(Filtered_BW_image);  title('Filtered BW Image');
    ax8 = subplot(5,3,8); imshow(classifierImage); title('Classifier Output')
    ax9 = subplot(5,3,9); imshow(BW_overlay_classifier); title('Classifier Overlay');

    % Row 4
    TP_overlay = imoverlay(Ioriginal, TP, [1 0 0]);
    ax10 = subplot(5,3,10); imshow(TP_overlay);  title('TP pixels');

    FP_overlay = imoverlay(Ioriginal, FP, [0 1 0]);
    ax11 = subplot(5,3,11); imshow(FP_overlay); title('FP pixels')

    FN_overlay = imoverlay(Ioriginal, FN, [0 0 1]);
    ax12 = subplot(5,3,12); imshow(FN_overlay); title('FN pixels');

    % Row 5
    if (isempty(RGB))
        ax13 = subplot(5,3,13); imshow([]);
    else
        ax13 = subplot(5,3,13); imshow(RGB); title('Bounding Boxes')
    end
    
    ax14 = subplot(5,3,14); imshow(Ioriginal); hold on;
    h = imshow(IAnnotate); title('Ground-truth Quality');
    set(h, 'AlphaData', 0.1); % .5 transparency
    
    % Overall TPFPFN pixels
    TP_red = imoverlay(Iground2PrecisionRecall, TP, [1 0 0]);
    FP_green = imoverlay(TP_red, FP, [0 1 0]);
    FN_blue = imoverlay(FP_green, FN, [0 0 1]);
    
    ax15 = subplot(5,3,15); imshow(Ioriginal); hold on;
    h1 = imshow(FN_blue); title('Overall Pixels (TPFPFN)');
    set(h1, 'AlphaData', 0.2); % .5 transparency
    stitle = sgtitle(['Image No.: ' num2str(imnum) ' | ', 'File Name: ' filename, ' | ' classifierName]);
    set(stitle, 'Interpreter', 'none')

    % Link axes
    linkaxes([ax1,ax2,ax3,ax4,ax5,ax6,ax7,ax8,ax9,ax10,ax10,ax11,ax12,ax13,ax14,ax15],'xy')
    
    drawnow;
end

% figure; imshow(RGB); title('Bounding Boxes')

% Save images
if (storeOutputImages)
    if ~exist(fullfile(filesavepath,saveFolderName), 'dir')
        mkdir(fullfile(filesavepath,saveFolderName))
    end
    saveas(gcf, fullfile(filesavepath,saveFolderName, [name, '_', classifierName, '_',...
           input.Algorithm_TYPE,lower(ext)]))
end
%}
            
% Calculate the TP, FP and FN Bounding box hits
TruePositiveBbox  = tpCount;

FalsePositiveBbox = fpCount;

FalseNegativeBbox = fnCount;

% disp(TruePositiveBbox)
% disp(FalsePositiveBbox)
% disp(FalseNegativeBbox)

% Pause to see the output and to compare the TP/FP/FN counts
% pause(2)

end


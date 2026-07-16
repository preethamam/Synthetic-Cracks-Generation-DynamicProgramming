function [IM_info_array] = largeFeaturematrixNlabelsRealworldData2025 (input)

% Iniliaze the image details struct
IM_info_array = [];

class_name = 'Cracks';

% Broadcasting variables
gpuArray = input.gpuarray;
resizeImage = input.resizeImage;
maxImageResizePixels = input.maxImageResizePixels;
resizeImageSize = input.resizeImageSize;
resizeImageSizeScale = input.resizeImageSizeScale;
contrast_type = input.contrast_type;        
savefeaturematrixNlabels = input.savefeaturematrixNlabels;

% Wait message constructor
WaitMessage = waitbarParfor(length(input.real_crack), 'Waitbar', true);

% For all training images
parfor j = 1 : length(input.real_crack)
        
    %Send a message to the object. 
    WaitMessage.Send; 
    
    % Read image
    ImageID = fullfile(input.real_crack(j).folder, input.real_crack(j).name);
    
    % File parts
    [pathstr,name,ext] = fileparts(ImageID);
                        
    % Populate image information structure
    IM_info_array(j).name     = name;
    IM_info_array(j).fileExt  = ext;
    IM_info_array(j).filePath = ImageID;
                              
    %----------------------------------------------------------
    % Image parameters
    %----------------------------------------------------------
    % Read image
    [imheight, imwidth, imbytesppix, Ioriginal, Igray] ...
            = imconversion2gray(ImageID, gpuArray, resizeImage, ...
                    maxImageResizePixels, resizeImageSize,...
                    resizeImageSizeScale,contrast_type); %#ok<*ASGLU>                               

    %----------------------------------------------------------
    % Feature vector 
    %----------------------------------------------------------
    if input.blobFilter
        Ioriginal = blobFilter(Ioriginal, input);
    end

    % Class number (folder corresponds to class)
    [Feature_matrix, Label_matrix, Pixcoords,~,~] = crack_non_crackfeaturesNlabels_2018Revised_5JahanFeatures...
    (Ioriginal, Igray, Ioriginal, [],[], class_name,input);
    
    % Image channel type
    if (imbytesppix > 1)
        IM_info_array(j).imageType = 'RGB';
    elseif (imbytesppix == 1 && ~islogical(Ioriginal))
        IM_info_array(j).imageType = 'Grayscale';
    else
        IM_info_array(j).imageType = 'Logical';
    end

    
    % Feature image resolution
    IM_info_array(j).imageResoution = [imwidth, imheight];
        
    % Feature matrix sizes
    IM_info_array(j).featureMatSize ...     
                = [size(Feature_matrix,1); size(Feature_matrix,2)];  %#ok<*AGROW>

    % Label matrix sizes
    IM_info_array(j).labelMatSize ...
                = size(Label_matrix);

    % Feature vector
    if (savefeaturematrixNlabels)
        IM_info_array(j).featureMat     = Feature_matrix;  %#ok<*AGROW>
        IM_info_array(j).labelMat       = Label_matrix;
%             IM_info(j).pixRCcoord     = Pixcoords;
    else

        % Save .mat files

    end
            
    % Remove empty rows
%     IM_info_noemptyROWS = IM_info(all(~cellfun(@isempty,struct2cell(IM_info))));    
end

%Destroy the object.
WaitMessage.Destroy

end

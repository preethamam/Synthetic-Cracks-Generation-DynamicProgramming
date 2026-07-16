function [IM_info_array] = largeFeaturematrixNlabels2025 (input,jahaninput)

% Iniliaze the image details struct
IM_info = [];
IM_info_array = [];

% Broadcasting variables
gpuArray = input.gpuarray;
resizeImage = input.resizeImage;
maxImageResizePixels = input.maxImageResizePixels;
resizeImageSize = input.resizeImageSize;
resizeImageSizeScale = input.resizeImageSizeScale;
contrast_type = input.contrast_type;

blobfilter_sigma = input.blobfilter_sigma;

jahaninput_crackLEN = jahaninput.crackLEN;
jahaninput_anglebetween = jahaninput.anglebetween;
        
if~(isempty(input.non_crack))
    non_crack_bytes = {input.non_crack.bytes};
    non_crack_folder = {input.non_crack.folder};
    non_crack_name = {input.non_crack.name};
else
    non_crack_bytes = [];
    non_crack_folder = [];
    non_crack_name = [];
end

if~(isempty(input.syn_crack))
    syn_crack_bytes = {input.syn_crack.bytes};
    syn_crack_folder = {input.syn_crack.folder};
    syn_crack_name = {input.syn_crack.name};
else
    syn_crack_bytes = [];
    syn_crack_folder = [];
    syn_crack_name = [];
end

savefeaturematrixNlabels = input.savefeaturematrixNlabels;

for algNum = 1 : length(input.Algorithm_TYPE)
    Algorithm_TYPE = input.Algorithm_TYPE{algNum};

    for i = 1 : length(input.originaldata_folders)
    
        switch input.originaldata_folders{i}
            case input.originaldata_folders{1}
                % File count
                imgCount = length(input.non_crack);
                
            case input.originaldata_folders{2}
                % File count
                imgCount = length(input.syn_crack);
        
        end
        
        class_name = input.originaldata_folders{i};
        index = unique([0:input.chunk_size:imgCount, imgCount]);
        
        for k = 1:numel(index)-1
        
        WaitMessage = waitbarParfor(abs(index(k)+1 - index(k+1)), 'Waitbar', true);
            
               
            % For all training images
            parfor j = 1:index(k+1)-index(k)
        
                %Send a message to the object. 
                WaitMessage.Send;
            
                ImageID = []; name = []; ext = []; BW3 = [];
                Feature_matrix = []; Label_matrix= []; Pixcoords = [];
                imheight = []; imwidth= []; imbytesppix = []; Ioriginal = []; Igray = [];
                Ivessel = [];
                
                % Broadcast variables
                size(non_crack_bytes); % access whole of non_crack_bytes 
                size(non_crack_folder); 
                size(non_crack_name);
                
                size(syn_crack_bytes);
                size(syn_crack_folder);
                size(syn_crack_name);
                
                jnew = j + index(k);
        
                switch i
                    case 1
                        
                        if jnew<=length(non_crack_bytes) && non_crack_bytes{jnew} ~= 0
                        % Read image
                            ImageID = fullfile(non_crack_folder{jnew}, non_crack_name{jnew});
                        else
                            continue;
                        end
        
                        % File parts
                        [pathstr,name,ext] = fileparts(ImageID);
        
                    case 2
                        
                        if jnew<=length(syn_crack_bytes) && syn_crack_bytes{jnew} ~= 0
                        % Read image
                            ImageID = fullfile(syn_crack_folder{jnew},syn_crack_name{jnew});
                        else
                            continue;
                        end
        
                        % File parts
                        [pathstr,name,ext] = fileparts(ImageID);
        
                 end
                                    
                % Populate image information structure
                IM_info(j).name     = name;
                IM_info(j).fileExt  = ext;
                IM_info(j).filePath = ImageID;
                              
                %----------------------------------------------------------
                % Image parameters
                %----------------------------------------------------------
                % Read image
                [imheight, imwidth, imbytesppix, Ioriginal, Igray] ...
                        = imconversion2gray(ImageID, gpuArray, resizeImage, ...
                                maxImageResizePixels, resizeImageSize,...
                                resizeImageSizeScale,contrast_type); %#ok<*ASGLU>
        
        
                switch Algorithm_TYPE
        
                    case 'hessian'
        
                        if (~islogical(Ioriginal))                       
        
                            %----------------------------------------------------------
                            % Hessian matrix method for curvature dominant feature 
                            % extraction
                            %----------------------------------------------------------
                            if (input.dynamic_frangiopt == 1)
                                % Frangi filter options
                                frangiopt = struct();
                                
                                if max(size(Igray)) <= 200
                                    frangiopt.FrangiScaleRange = [1, randi([10,12],1)]; 
                                else
                                    frangiopt.FrangiScaleRange = [1, randi([13,30],1)]; 
                                end
        
                                frangiopt.FrangiScaleRatio = 2;
                                frangiopt.FrangiBetaOne    = 0.5; %0.5
                                frangiopt.FrangiBetaTwo    = 25; %2 %15 10
                                frangiopt.BlackWhite       = 1;
                                frangiopt.verbose          = 0;
                            else
                                frangiopt = input.frangiopt;
                            end
                            
                            % Hessian matrix (Frangi filter) function callback
                            Ivessel  = FrangiFilter2D(Igray, frangiopt);
        
        
                            %----------------------------------------------------------
                            % Binary conversion
                            %----------------------------------------------------------
                            % Display the Hessian matrix (Frangi filter) results
                            % Ostu's grayscale threshold
                            level = graythresh(Ivessel);
        
                            % Convert to the binary image
                            BW    = imbinarize(Ivessel, level);
        
        
                            %----------------------------------------------------------
                            % Line filtering
                            %----------------------------------------------------------
                            BW1 = BW;
        
                            %----------------------------------------------------------
                            % Low-level filtering
                            %----------------------------------------------------------
                            % Stage I/ first step filter [for orphan/flakey pixels
                            % and bridging close neighbors]
                            BW2 = filter_stage_I (BW1);
        
                            %----------------------------------------------------------
                            % Blob removal
                            %----------------------------------------------------------
                            % Connected components
                            CC = bwconncomp(BW2);
                            S  = regionprops(CC,'Area');
        
                            % Normal distribution fit
                            [mu_hessian, sigma_hessian] = normfit(cell2mat(struct2cell(S)));
        
                            % check for sigma
                            if ((isempty(sigma_hessian)) || (isnan (sigma_hessian)))
                                sigma_hessian = 0;
                            end
        
                            % Remove smaller area lesser than sigma_morph
                            BW3 = bwareaopen(BW2, ceil(blobfilter_sigma * ...
                                                        sigma_hessian), 8);
        
                        else
        
                            BW3    = Ioriginal;
                        end
    
                    case 'mfat'
        
                        if (~islogical(Ioriginal))                       
        
                            %----------------------------------------------------------
                            % Hessian matrix method for curvature dominant feature 
                            % extraction
                            %----------------------------------------------------------
                            if (input.dynamic_mfatopt == 1)
                                % Frangi filter options
                                MFAToptions = struct();
                                
                                if max(size(Igray)) <= 200
                                    MFAToptions.sigmas1       = 0.7181;  % 1
                                    MFAToptions.sigmas2       = 3; 
                                else
                                    MFAToptions.sigmas1       = 0.7181;  % 1
                                    MFAToptions.sigmas2       = 5;
                                end
                                MFAToptions.sigmasScaleRatio = 0.2;
                                MFAToptions.spacing       = 0.39;
                                MFAToptions.tau           = 0.25; 
                                MFAToptions.tau2          = 0.5; 
                                MFAToptions.D             = 0.5; %0.85
                                MFAToptions.whiteondark   = false;
                            else
                                MFAToptions = input.MFAToptions;
                            end
                            
                            % MFAT function callback
                            switch input.MFAT_TYPE
                                case 'EigenFAT'
                                    % Proposed Method (Eign values based version)
                                    Ivessel = FractionalIstropicTensor(Igray, MFAToptions);
                                    Ivessel = normalize(Ivessel);
                                case 'ProbabilisticFAT'
                                    % Proposed Method (probability based version)
                                    % Ivessel = ProbabiliticMFATSpacing(Im_ad,input.MFAToptions);
                                    Ivessel = ProbabiliticMFATSigmas(Igray, MFAToptions);
                                    Ivessel = normalize(Ivessel);
                            end
        
        
                            %----------------------------------------------------------
                            % Binary conversion
                            %----------------------------------------------------------
                            % Display the Hessian matrix (Frangi filter) results
                            % Ostu's grayscale threshold
                            level = graythresh(Ivessel);
        
                            % Convert to the binary image
                            BW    = imbinarize(Ivessel, level);
        
        
                            %----------------------------------------------------------
                            % Line filtering
                            %----------------------------------------------------------
                            BW1 = BW;
        
                            %----------------------------------------------------------
                            % Low-level filtering
                            %----------------------------------------------------------
                            % Stage I/ first step filter [for orphan/flakey pixels
                            % and bridging close neighbors]
                            BW2 = filter_stage_I (BW1);
        
                            %----------------------------------------------------------
                            % Blob removal
                            %----------------------------------------------------------
                            % Connected components
                            CC = bwconncomp(BW2);
                            S  = regionprops(CC,'Area');
        
                            % Normal distribution fit
                            [mu_hessian, sigma_hessian] = normfit(cell2mat(struct2cell(S)));
        
                            % check for sigma
                            if ((isempty(sigma_hessian)) || (isnan (sigma_hessian)))
                                sigma_hessian = 0;
                            end
        
                            % Remove smaller area lesser than sigma_morph
                            BW3 = bwareaopen(BW2, ceil(blobfilter_sigma * ...
                                                        sigma_hessian), 8);
        
                        else
        
                            BW3    = Ioriginal;
                        end
    
                    case 'morpho'
                        if (~islogical(Ioriginal))
                            if~(jahaninput.SElength_percent == 0)
                                jahaninput_nmax = round(jahaninput.SElength_percent  * max(size(Igray)));
                            else
                                jahaninput_nmax  = randi([5,130],1);
                            end
                             
                            % Crack structural length
                            jahaninput_crackLEN = jahaninput.nmin+2 : jahaninput.nstep : jahaninput_nmax+10;  % options:  [1 : max(size(image))]
                                            
                                            
                            % Morphological method (Jahanshahi's method)
                            BW3 = funct_crackDetect_Salembier_Sinha_Jahan ...
                                            (Igray, jahaninput_crackLEN, ...
                                            jahaninput_anglebetween);
                        else
                            BW3 = Ioriginal;
                        end
                end
        
                %----------------------------------------------------------
                % Feature vector 
                %----------------------------------------------------------
                % Class number (folder corresponds to class)
        
                [Feature_matrix, Label_matrix, Pixcoords,~,~] = crack_non_crackfeaturesNlabels_2018Revised_5JahanFeatures...
                (Ioriginal, Igray, BW3, [],[], class_name,input);
                
                % Image channel type
                if (imbytesppix > 1)
                    IM_info(j).imageType = 'RGB';
                elseif (imbytesppix == 1 && ~islogical(Ioriginal))
                    IM_info(j).imageType = 'Grayscale';
                else
                    IM_info(j).imageType = 'Logical';
                end
        
                
                % Feature image resolution
                IM_info(j).imageResoution = [imwidth, imheight];
        
                % Feature matrix sizes
                IM_info(j).featureMatSize ...     
                            = [size(Feature_matrix,1); size(Feature_matrix,2)];  %#ok<*AGROW>
        
                % Label matrix sizes
                IM_info(j).labelMatSize ...
                            = size(Label_matrix);
        
                % Feature vector
                if (savefeaturematrixNlabels)
                    IM_info(j).featureMat     = Feature_matrix;  %#ok<*AGROW>
                    IM_info(j).labelMat       = Label_matrix;
        %             IM_info(j).pixRCcoord     = Pixcoords;
                else
        
                    % Save .mat files
        
                end
                
                %}
            end     
            
            % Remove empty rows
        %     IM_info_noemptyROWS = IM_info(all(~cellfun(@isempty,struct2cell(IM_info))));
            IM_info_array = [IM_info_array, IM_info];
            IM_info = [];
            
            %Destroy the object.
            WaitMessage.Destroy
            
            % Delete Current Pool
        %     delete(gcp('nocreate'))
            
        end
    end
end
end

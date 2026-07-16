function augmentCracks(input, real_crack_Imgs)


    %Before the loop, we need to construct the object. 
    WaitMessage = waitbarParfor(length(real_crack_Imgs), 'Waitbar', true);
    
    parfor i = 1:length(real_crack_Imgs)
    
        %Send a message to the object. 
        WaitMessage.Send;
    
        % Read image    
        BW = imread(fullfile(real_crack_Imgs(i).folder, real_crack_Imgs(i).name));
    
        % Get image filename parts
        [filepath,name,ext] = fileparts(real_crack_Imgs(i).name);  
    
        img_elastic = elastic_def_multiplicator(BW, input.geotrans_type, input.maxDistortAlpha, ...
            input.totNumberCracksElasticDef, input.showfig_points);
        
        % Parallel write
        parallelWrite(input, img_elastic, name)
       
    end
    
    %Destroy the object.
    WaitMessage.Destroy
end

function parallelWrite(input, img_elastic, name)
    parfor j = 1:input.totNumberCracksElasticDef
        % Convert to binary or logical image        
        img = img_elastic(:,:,j);
        img(img > 0) = 1;
        img = logical(img);
        
        % Write image    
        imwrite(img, fullfile(input.AugmentImgsSavePath, [name '_aug_' num2str(j) '.png']))
    end 
end
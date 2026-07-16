function orphanBlobsRemoveImages(input)

images = dir(input.AugmentImgsSavePath);
images = images(3:end);

%Before the loop, we need to construct the object. 
WaitMessage = waitbarParfor(length(images), 'Waitbar', true);

parfor i = 1:length(images)

    %Send a message to the object. 
    WaitMessage.Send;

    % Read image    
    img = imread(fullfile(images(i).folder, images(i).name));

    % Get image filename parts
    [filepath,name,ext] = fileparts(images(i).name); 

    % Remove orphan blobs
    blobFiltered = blobFilter(img, input);
    
    % Write image    
    imwrite(blobFiltered, fullfile(input.AugmentImgsSavePath, [name '.png']))
   
end

%Destroy the object.
WaitMessage.Destroy

end
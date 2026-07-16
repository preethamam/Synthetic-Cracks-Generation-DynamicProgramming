function deleteEmptyImages(input)

images = dir(input.AugmentImgsSavePath);
images = images(3:end);

%Before the loop, we need to construct the object. 
WaitMessage = waitbarParfor(length(images), 'Waitbar', true);

parfor i = 1:length(images)

    %Send a message to the object. 
    WaitMessage.Send;

    % Read image    
    BW = imread(fullfile(images(i).folder, images(i).name));

    % Delete empty files
    if sum(sum(BW)) == 0
        delete(fullfile(images(i).folder, images(i).name));
    end
   
end

%Destroy the object.
WaitMessage.Destroy

end
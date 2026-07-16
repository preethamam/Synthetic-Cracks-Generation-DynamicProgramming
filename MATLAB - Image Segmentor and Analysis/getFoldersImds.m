function dsStruct = getFoldersImds(rootFolder)


%% 2. Create one big ImageDatastore, auto-labeling by sub-folder names
imds = imageDatastore( ...
    rootFolder, ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames' ...
);

%% 3. See what labels (folder names) you have
allLabels = unique(imds.Labels);
disp(allLabels);

%% 4. Break that big datastore into one datastore per label
nLabels = numel(allLabels);
imdsPerLabel = cell(nLabels,1);
for k = 1:nLabels
    thisLabel = allLabels(k);
    idx = imds.Labels == thisLabel;
    imdsPerLabel{k} = subset(imds, idx);
    fprintf("-> %s: %d images\n", string(thisLabel), sum(idx));
end

% Now imdsPerLabel{1} holds all “cats” images, imdsPerLabel{2} all “dogs”, etc.

%% 5. (Optional) Put them in a struct for easy access by name
% after you’ve got allLabels and imdsPerLabel...
validNames = matlab.lang.makeValidName(string(allLabels));

dsStruct = struct();
for k = 1:numel(allLabels)
    fn = validNames(k);                % e.g. "X01" instead of "01"
    dsStruct.(fn) = imdsPerLabel{k};
end


end
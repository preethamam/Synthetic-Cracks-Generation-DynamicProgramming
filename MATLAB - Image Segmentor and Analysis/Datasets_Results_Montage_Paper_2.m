clc; close all; clear;


%% Datasets_Results_Montage.m
% Montage with white background, imcomplement for all masks including GT,
% and per-dataset 2×3 tiled display with tight spacing

%% 1) PARAMETERS
rootFolder     = 'H:\Project MegaCRACK-RoboCRACK\Real World Data\Synthetic Papers\Paper I - Dynamic Programming\Montage Plots';      % <-- your root
datasets     = {'CDLN','Jahan','Liu'};          % dataset names
algorithms   = {'Hessian','MFAT','Morpho'};      % prediction algorithms
variants     = {'01','02','03','04','05','06'};   % six variants per algorithm
validExts    = {'.jpg','.jpeg','.png','.tif','.tiff','.bmp'};
n            = 6;                               % random samples per dataset
desiredSize  = [200, 400];                     % [rows, cols] per sub-image
gapSize      = 10;                              % pixels of white gap between variant images

%% 2) BUILD MASTER LIST OF COMPLETE SETS
list = struct('dataset',{},'name',{});
for d = 1:numel(datasets)
    ds    = datasets{d};
    colDir = fullfile(rootFolder, ds, 'Color');
    files  = dir(fullfile(colDir,'*.*')); files = files(~[files.isdir]);
    % filter Color by valid extensions
    mask = false(size(files));
    for i = 1:numel(files)
        [~,~,e] = fileparts(files(i).name);
        mask(i) = any(strcmpi(e, validExts));
    end
    colorFiles = files(mask);
    for f = colorFiles'
        [~, base, ~] = fileparts(f.name);
        % GT must exist
        if isempty(dir(fullfile(rootFolder, ds, 'GT', [base '.*'])))
            continue;
        end
        % all variant predictions must exist
        ok = true;
        for a = 1:numel(algorithms)
            for v = 1:numel(variants)
                pat = fullfile(rootFolder, ds, 'Predict', algorithms{a}, variants{v}, [base '.*']);
                if isempty(dir(pat)); ok = false; break; end
            end
            if ~ok, break; end
        end
        if ok
            list(end+1) = struct('dataset', ds, 'name', base); %#ok<SAGROW>
        end
    end
end
if isempty(list)
    error('No complete image-sets found');
end


%% 3) PROCESS & DISPLAY PER DATASET
for d = 1:numel(datasets)
    ds      = datasets{d};
    entries = list(strcmp({list.dataset}, ds));
    N_ds    = numel(entries);
    if N_ds == 0, continue; end
    selCount = min(n, N_ds);
    idxs     = randperm(N_ds, selCount);
    sel_ds   = entries(idxs);
    comps_ds = cell(1, selCount);
    % build each composite image (as before)
    for k = 1:selCount
        base = sel_ds(k).name;
        % read & resize Color
        Icol = imresize(readAsRGB(fullfile(rootFolder, ds, 'Color', [base '.*'])), desiredSize);
        % read, invert, & resize GT mask
        rawGT = readAsRGB(fullfile(rootFolder, ds, 'GT', [base '.*']));
        Igt   = imresize(imcomplement(rawGT), desiredSize);
        % assemble each algorithm prediction column
        algStack = cell(1, numel(algorithms));
        for a = 1:numel(algorithms)
            tmp = cell(1, numel(variants));
            for v = 1:numel(variants)
                rawP = readAsRGB(fullfile(rootFolder, ds, 'Predict', algorithms{a}, variants{v}, [base '.*']));
                tmp{v} = imresize(imcomplement(rawP), desiredSize);
            end
            algStack{a} = stackWithGap(tmp, gapSize);
        end
        % pad with white
        heights = [size(Icol,1), size(Igt,1), cellfun(@(x) size(x,1), algStack)];
        tgtH    = max(heights);
        IcolP = padWhite(Icol, tgtH);
        IgtP  = padWhite(Igt,  tgtH);
        for a = 1:numel(algorithms)
            algStack{a} = padWhite(algStack{a}, tgtH);
        end
        % concatenate horizontally
        comps_ds{k} = cat(2, IcolP, IgtP, algStack{:});
    end
    % display composites in 2×3 tiled layout
        % display composites in 2×3 tiled layout with tighter vertical spacing
    fig = figure('Name', ds, 'Color', 'w', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);
    t = tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'tight');
    % % programmatically adjust inner position to reduce vertical gaps
    % ip = t.InnerPosition;
    % ip(2) = ip(2) + 0.05;      % raise bottom edge
    % ip(4) = ip(4) - 0.1;       % reduce height
    % t.InnerPosition = ip;
    % tile images
    for k = 1:selCount
        nexttile(k);
        imshow(comps_ds{k}, 'InitialMagnification', 'fit');
    end
    % programmatic vertical tightening: adjust axes positions
    % axs = findall(fig, 'Type', 'Axes');
    % for ax = axs'
    %     pos = ax.Position;
    %     % shift axes down slightly and increase height
    %     pos(2) = pos(2) - 0.02;   % lower y-coordinate
    %     pos(4) = pos(4) + 0.04;   % expand height
    %     ax.Position = pos;
    % end
end

%% HELPER FUNCTIONS
function Iout = readAsRGB(pattern)
    % Read first matching file (RGB, indexed, or grayscale) as MxNx3 uint8
    f = dir(pattern); f = f(1);
    [A, map] = imread(fullfile(f.folder, f.name));
    if ~isempty(map)
        Iout = im2uint8(ind2rgb(A, map));
    elseif size(A,3) == 1
        Iout = uint8(255*repmat(A, [1 1 3]));
    else
        Iout = A;
    end
end

function S = stackWithGap(imgs, gap)
    % Vertically stack images with white gap between
    gapRow = uint8(255 * ones(gap, size(imgs{1},2), size(imgs{1},3)));
    S = imgs{1};
    for i = 2:numel(imgs)
        S = cat(1, S, gapRow, imgs{i});
    end
end

function Ipad = padWhite(Iin, tgtH)
    % Pad image vertically to tgtH with white background
    h     = size(Iin,1);
    delta = max(0, tgtH - h);
    top   = floor(delta/2);
    bot   = delta - top;
    Ipad  = padarray(Iin, [top, 0], 255, 'pre');
    Ipad  = padarray(Ipad, [bot, 0], 255, 'post');
end












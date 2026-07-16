function [optCrackStrandMask, crackStrandEnergy] = funct_findOptCrackStrand_LongestPath_Diagonal(energy, randomize)
% finds optimal diagonal seam (longest path) from left edge to right edge
% if randomize=true, picks random start on left & end on right edges
% otherwise connects top-left to bottom-right
% returns mask where 0 indicates a pixel is in the seam

    if nargin < 2
        randomize = false;
    end
    [h, w] = size(energy);

    % invert energy and pad top and left edges
    M = padarray(energy, [1 1], realmax('double'));
    sz = size(M);

    % choose start/end rows along left/right edges
    if randomize
        startRow = randi(h);
        endRow   = randi(h);
    else
        startRow = 1;
        endRow   = h;
    end

    % forward DP: accumulate max from diag-down, down, right
    for i = 2 : sz(1)
        for j = 2 : sz(2)
            neighbors = [M(i-1,j-1), M(i-1,j), M(i,j-1)];
            M(i,j) = M(i,j) + max(neighbors);
        end
    end

    % initialize seam energy at chosen endpoint
    crackStrandEnergy = M(endRow+1, w+1);

    % backtrack to left edge
    optCrackStrandMask = false(h, w);
    i = endRow + 1;
    j = w + 1;
    while i > startRow + 1 || j > 2
        optCrackStrandMask(i-1, j-1) = true;
        neighbors = [M(i-1,j-1), M(i-1,j), M(i,j-1)];
        [val, idx] = max(neighbors);
        crackStrandEnergy = crackStrandEnergy + val;
        switch idx
            case 1, i = i - 1; j = j - 1;
            case 2, i = i - 1;
            case 3, j = j - 1;
        end
    end

    % mark start pixel
    optCrackStrandMask(startRow, 1) = true;
    % invert mask so 0 indicates the seam
    optCrackStrandMask = ~optCrackStrandMask;
end
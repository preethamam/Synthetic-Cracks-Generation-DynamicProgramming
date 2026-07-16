function [optCrackStrandMask, crackStrandEnergy] = funct_findOptCrackStrand_LongestPath_Horizontal(energy)
% finds optimal horizontal seam using longest distance
% returns mask with 0 mean a pixel is in the seam

    % invert energy and pad one row at top & bottom
    M = padarray(energy, [1 0], realmax('double'));
    sz = size(M);

    % forward pass: accumulate max‐cost from left to right
    for j = 2 : sz(2)
        for i = 2 : (sz(1) - 1)
            neighbors = [ ...
                M(i-1, j-1), ... % up‐left
                M(i  , j-1), ... % left
                M(i+1, j-1)      % down‐left
            ];
            M(i,j) = M(i,j) + max(neighbors);
        end
    end

    % start backtrack from the max in the last column
    [val, indI] = max( M(:, sz(2)) );
    crackStrandEnergy  = val;
    optCrackStrandMask = false(size(energy));

    % backtrack from rightmost to second column
    for j = sz(2) : -1 : 2
        optCrackStrandMask(indI-1, j) = true;  % undo padding
        neighbors = [ ...
            M(indI-1, j-1), ... % up‐left
            M(indI  , j-1), ... % left
            M(indI+1, j-1)      % down‐left
        ];
        [val, indIncr]         = max(neighbors);
        crackStrandEnergy      = crackStrandEnergy + val;
        indI                   = indI + (indIncr - 2);
    end

    % mark the first column
    optCrackStrandMask(indI-1, 1) = true;

    % invert mask so 0 indicates seam pixels
    optCrackStrandMask = ~optCrackStrandMask;
end

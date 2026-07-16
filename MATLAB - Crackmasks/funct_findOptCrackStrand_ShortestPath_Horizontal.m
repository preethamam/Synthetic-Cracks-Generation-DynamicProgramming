function [optCrackStrandMask, crackStrandEnergy] = funct_findOptCrackStrand_ShortestPath_Horizontal(energy)
% finds optimal horizontal seam using shortest distance
% returns mask with 0 mean a pixel is in the seam

    % pad top & bottom to avoid edge checks
    M = padarray(energy, [1 0], realmax('double'));

    sz = size(M);
    % forward pass: accumulate min-cost from left to right
    for j = 2 : sz(2)
        for i = 2 : (sz(1) - 1)
            neighbors = [ ...
                M(i-1, j-1), ... % up-left
                M(i  , j-1), ... % left
                M(i+1, j-1)      % down-left
            ];
            M(i,j) = M(i,j) + min(neighbors);
        end
    end

    % start backtrack from the min in the last column
    [val, indI]   = min( M(:, sz(2)) );
    crackStrandEnergy    = val;

    optCrackStrandMask   = false(size(energy));

    % backtrack from rightmost to the 2nd column
    for j = sz(2) : -1 : 2
        optCrackStrandMask(indI-1, j) = true;  % -1 to undo padding
        % pick the best of the three leftwards neighbors
        neighbors = [ ...
            M(indI-1, j-1), ... % up-left
            M(indI  , j-1), ... % left
            M(indI+1, j-1)      % down-left
        ];
        [val, indIncr] = min(neighbors);
        crackStrandEnergy     = crackStrandEnergy + val;
        % move indI: indIncr=1→-1 row, 2→0, 3→+1
        indI = indI + (indIncr - 2);
    end

    % mark the first column
    optCrackStrandMask(indI-1, 1) = true;

    % invert mask so 0 means seam
    optCrackStrandMask = ~optCrackStrandMask;
end

function [optCrackStrandMask, crackStrandEnergy] = funct_findOptCrackStrand_LongestPath_Vertical(energy)
% finds optimal seam using longest distance
% returns mask with 0 mean a pixel is in the seam

    % find M for vertical seams
    % for vertical - use I`
    M = padarray(energy, [0 1], realmax('double')); % to avoid handling border elements

    sz = size(M);
    for i = 2 : sz(1)
        for j = 2 : (sz(2) - 1)
            neighbors = [M(i - 1, j - 1) M(i - 1, j) M(i - 1, j + 1)];
            M(i, j) = M(i, j) + max(neighbors);
        end
    end

    % find the min element in the last raw
    [val, indJ] = max(M(sz(1), :));
    crackStrandEnergy = val;

    optCrackStrandMask = false(size(energy));
    
    %go backward and save (i, j)
    for i = sz(1) : -1 : 2
        %optSeam(i) = indJ - 1;
        optCrackStrandMask(i, indJ - 1) = 1; % -1 because of padding on 1 element from left
        neighbors = [M(i - 1, indJ - 1) M(i - 1, indJ) M(i - 1, indJ + 1)];
        [val, indIncr] = max(neighbors);

        crackStrandEnergy = crackStrandEnergy + val;

        indJ = indJ + (indIncr - 2); % (x - 2): [1,2]->[-1,1]]
    end

    optCrackStrandMask(1, indJ - 1) = 1; % -1 because of padding on 1 element from left
    optCrackStrandMask = ~optCrackStrandMask;
end
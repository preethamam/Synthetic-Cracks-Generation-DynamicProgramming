function [optCrackStrandMask, crackStrandEnergy] = funct_findOptCrackStrand_ShortestPath_Diagonal(energy, randomize)
% finds optimal shortest-path diagonal seam from left edge to right edge
% if randomize=true, picks random start on left & end on right edges
% otherwise finds minimal-energy seam from any left-edge pixel to any right-edge pixel
% returns mask where 0 indicates a pixel is in the seam

    if nargin<2, randomize = false; end
    [h, w] = size(energy);

    % pad *only* on top & left
    M = padarray(energy, [1 1], realmax('double'), 'pre');  % size (h+1)x(w+1)

    % pick start/end rows
    if randomize
        startRow = randi(h);
        endRow   = randi([startRow, h]);
    else
        startRow = 1;
        endRow   = h;
    end

    % seed the entry at (startRow+1,2)
    M(:,2) = realmax('double');
    M(startRow+1,2) = energy(startRow,1);

    % forward DP from j=3…w+1
    for j = 3 : w+1
        for i = 2 : h+1
            c      = energy(i-1, j-1);
            nbrs   = [M(i-1,j-1), M(i-1,j), M(i,j-1)];
            M(i,j) = c + min(nbrs);
        end
    end

    % total cost at (endRow+1, w+1)
    crackStrandEnergy = M(endRow+1, w+1);

    % back‐track safely
    optCrackStrandMask = false(h, w);
    i = endRow + 1;
    j = w     + 1;
    
    % loop until we either hit the seeded entry, or run out of valid i/j
    while j > 2
        optCrackStrandMask(i-1, j-1) = true;
        nbrs = [ M(i-1,j-1), M(i-1,j), M(i,j-1) ];
        mn   = min(nbrs);
        cands = find(nbrs == mn);            % all directions with equal best cost
        idx = cands(randi(numel(cands)));    % pick one at random

        switch idx
          case 1, i = i - 1; j = j - 1;      % diag-up-left
          case 2, i = i - 1;                 % straight up
          case 3, j = j - 1;                 % left
        end
    end

    % mark the exact start‐pixel on the left edge
    optCrackStrandMask(startRow, 1) = true;

    % invert so that 0’s indicate the seam
    optCrackStrandMask = ~optCrackStrandMask;
end

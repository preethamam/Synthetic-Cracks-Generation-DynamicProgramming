function outputImage = blobFilter(BW, input)    
    % BLOBFILTER Filters out small blobs from a binary image.
    %   OUTPUTIMAGE = BLOBFILTER(BW1, BLOBFILTER_SIGMA) removes blobs from
    %   the binary image BW1 that are smaller than a threshold determined
    %   by INPUT Input struct.
    %
    %   Example:
    %       BW = imread('binary_image.png');
    %       input.blobFilterSigma = 1.5;
    %       input.blobFilterType = 'area';  % 'area' | 'gaussian'
    %       outputImage = blobFilter(BW, input);
    
    % Get connected components
    CC = bwconncomp(BW);
    S  = regionprops(CC,'Area');
    
    if strcmp(input.blobFilterType, 'area')

        % Remove smaller area lesser than sigma_morph
        outputImage = bwareaopen(BW, input.blobFilterArea, 8);
    else
        % Normal distribution fit
        [mu_hessian, sigma_hessian] = normfit(cell2mat(struct2cell(S)));
        
        % check for sigma
        if ((isempty(sigma_hessian)) || (isnan (sigma_hessian)))
            sigma_hessian = 0;
        end

        % Remove smaller area lesser than sigma_morph
        outputImage = bwareaopen(BW, ceil(input.blobFilterSigma * ...
                                    sigma_hessian), 8);
    end
end
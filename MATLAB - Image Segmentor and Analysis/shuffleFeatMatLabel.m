function [ Feature_matrix, Labels, Target, indexMap ] = shuffleFeatMatLabel( featMat, labelArray, inpstruct )

%Usage: featMat    --> Feature matrix
%       labelArray --> Labels vector
%       inpstruct  --> Samples numbers limit: 
%                      hybrid_inpstruct.nosamp = 'number'; % 'full' | 'percentage' | 'number'
%                      Applicable to percent [0 to 1] | number [1 to max length of array]
%                      hybrid_inpstruct.sample_percent_number = 949260 or +ve N;

if (strcmp(inpstruct.nosamp,'full'))
    ixForFM_Lab = randperm(numel(labelArray));    
elseif (strcmp(inpstruct.nosamp,'percentage'))
    unqLabels = unique(labelArray);
    indx2shuffle = [];
    for i = 1:length(unqLabels)
        indx = find(labelArray == unqLabels(i));
        indxNum = floor(numel(indx)*inpstruct.sample_percent_number);
        [sampIndx,~] = datasample(indx,indxNum, 'Replace', false);
        indx2shuffle = [indx2shuffle; sampIndx];
        [ixForFM_Lab,indxForFM_Lab] = datasample(indx2shuffle,numel(indx2shuffle), 'Replace', false);
    end    
elseif (strcmp(inpstruct.nosamp,'number'))
    unqLabels = unique(labelArray);
    indx2shuffle = [];
    for i = 1:length(unqLabels)
        indx = find(labelArray == unqLabels(i));
        [sampIndx,~] = datasample(indx,inpstruct.sample_percent_number, 'Replace', false);
        indx2shuffle = [indx2shuffle; sampIndx];
        [ixForFM_Lab,indxForFM_Lab] = datasample(indx2shuffle,numel(indx2shuffle), 'Replace', false);
    end
end

% Populate the matrices
Feature_matrix  = featMat(ixForFM_Lab,:);
Labels          = labelArray(ixForFM_Lab,:);    
Target = full(ind2vec(Labels'))';

% Shuffled index mapping
if(strcmp(inpstruct.nosamp,'full'))
    if size(ixForFM_Lab,1) < size(labelArray,1)
        ixForFM_Lab = ixForFM_Lab';
    end
    indexMap = [labelArray; ixForFM_Lab];
else
    indexMap = [];
end
end


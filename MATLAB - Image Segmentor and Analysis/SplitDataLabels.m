function [Xtrain,Xval,Xtest,Ytrain,Yval,Ytest,Targettrain,Targetval,Targettest]...
    = SplitDataLabels(Featuremat,LabelsVector,TargetMatrix,input)
    %UNTITLED2 Summary of this function goes here
    %   Detailed explanation goes here
    
    
    % Prepare train, validation and test set fetaure matrix and its
    % corresponding labels
    trainInd = ceil(size(Featuremat,1) * input.trainValTest(1));
    valInd   = ceil(size(Featuremat,1) * input.trainValTest(2));
    
    Xtrain = Featuremat(1:trainInd,:);
    Xtest  = Featuremat(1+trainInd+valInd : size(Featuremat,1), :);
    
    if (valInd ~= 0)
        Xval   = Featuremat(1+trainInd : trainInd+valInd,:);
        Yval    = LabelsVector(1+trainInd : trainInd+valInd,:);
        Targetval   = TargetMatrix(1+trainInd : trainInd+valInd,:);
    else
        Xval = [];
        Yval = [];
        Targetval = [];
    end
    
    Ytrain = LabelsVector(1:trainInd,:);
    Ytest  = LabelsVector(1+trainInd+valInd : size(Featuremat,1), :);
    
    Targettrain = TargetMatrix(1:trainInd,:);
    Targettest  = TargetMatrix(1+trainInd+valInd : size(Featuremat,1), :);

end


function [Result_BW_image_ANN, Result_BW_image_KNN, Result_BW_image_SVM] ...
                    = RealCracksClassifierOutput_Paper (input,Igray, BW, MdlKNN, ScoreCSVMModel, net)

    
%----------------------------------------------------------
% Feature vector 
%----------------------------------------------------------        
[Featuremat, Label_matrix, ~, Pixcoords, CircIndex,Branch_points,holes]...
= crack_non_crackfeaturesNlabels_2018Revised_5JahanFeatures ...
([], ...
Igray, BW, [], [], [],input); 

%----------------------------------------------------------
% Test feature matrix
%----------------------------------------------------------
if (isempty(Featuremat))
    yANN = [];
    score_ann = [];

    yKNN = [];
    score_knn = [];

    ySVM = [];
    score_svm = [];
else
    % Test feature matrix with ANN
    yANN  = sim (net, Featuremat'); %, 'useParallel','yes');
    score_ann = yANN;
    score_ann = softmax(score_ann);

    yANN  = vec2ind(yANN);

    % Test feature matrix with KNN
    [yKNN,score_knn,cost_knn] = predict(MdlKNN, Featuremat);

    % Test feature matrix with SVM
%                         [ySVM,score_svm,cost_svm] = predict(MdlSVM, Featuremat);
    [ySVM,score_svm] = predict(ScoreCSVMModel,Featuremat);
end
score_ann_trans = score_ann';

%----------------------------------------------------------
% Fix class 2 in figure BW
%----------------------------------------------------------
BBoxes = [];
[fixedIMANN, BBoxes_ANN, BBoxes_scores_ANN, BBoxes_Labels_ANN] = fixClass2Labels(input, BW, yANN, Pixcoords, input.postprocess, ...
                        input.non_crack_class, input.post_process_Type, input.circularity_threshold, ...
                        input.branchpoints, CircIndex, Branch_points, holes, BBoxes, score_ann_trans);
Result_BW_image_ANN = fixedIMANN;


[fixedIMKNN, BBoxes_KNN, BBoxes_scores_KNN, BBoxes_Labels_KNN] = fixClass2Labels(input, BW, yKNN, Pixcoords, input.postprocess, ...
        input.non_crack_class, input.post_process_Type, input.circularity_threshold, ...
        input.branchpoints, CircIndex,Branch_points,holes, BBoxes, score_knn);
Result_BW_image_KNN = fixedIMKNN;

[fixedIMSVM, BBoxes_SVM, BBoxes_scores_SVM, BBoxes_Labels_SVM] = fixClass2Labels(input, BW, ySVM, Pixcoords, input.postprocess, ...
        input.non_crack_class, input.post_process_Type, input.circularity_threshold, ...
        input.branchpoints, CircIndex,Branch_points,holes, BBoxes, score_svm);
Result_BW_image_SVM = fixedIMSVM;


end

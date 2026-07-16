function [Precision, Recall, Accuracy, Specificity, F1score] = multiclassPrecision_Recall(confmat) 

% Array initialization
N = size(confmat,1);

Precision = zeros(1,N);
Recall = zeros(1,N);
Specificity = zeros(1,N);
Accuracy = zeros(1,N);
F1score = zeros(1,N);


if size(confmat,1) > 2

     for i = 1:size(confmat,1)

        TP = confmat(i,i);
        FN = sum(confmat(i,:))-confmat(i,i);
        FP = sum(confmat(:,i))-confmat(i,i);
        TN = sum(confmat(:))-TP -FP-FN;
                        
    %      TN = sum(diag(confmat)) - confmat(x, x);
    %      TN = sum(sum(confmat))  - sum(confmat(:, x)) - sum(confmat(x, :)) % wrong/buggy one

         Precision(:,i)   = TP / (TP+FP); % positive predictive value (PPV)
         Recall(:,i)      = TP / (TP+FN); % true positive rate (TPR), sensitivity
         if ((TN / (TN+FP)) > 1)
             Specificity(:,i) = 1;
         elseif ((TN / (TN+FP)) < 0)
             Specificity(:,i) = 0;
         else
             Specificity(:,i) = TN / (TN+FP); % (SPC) or true negative rate
         end
         Accuracy(:,i)    = (TP)/(TP+TN+FP+FN); % Accuracy
         F1score(:,i)     = (2*TP) /(2*TP + FP + FN);
     end
    
        % Remove junks         
        stats = [Precision', Recall', F1score', Accuracy', Specificity'];
        stats(any(isinf(stats),2),:) = [];
        stats(any(isnan(stats),2),:) = [];
        N = size(stats,1);
        
        % Compute averages
        Accuracy  = sum(stats(:,4));
        Precision = mean(stats(:,1));
        Recall    = mean(stats(:,2));
        Specificity = mean(Specificity);
        F1score = mean(stats(:,3));
        
%         accG = sum(diag(confmat)) / sum(sum(confmat));
%         acc  = 1 - (sum(confmat,2) + sum(confmat,1)' - 2 *diag(confmat)) ./ sum(sum(confmat));   
%         prec = diag(confmat) ./ sum(confmat,2);
%         prec(any(isnan(prec),2),:) = [];
%         
%         
%         recall = diag(confmat) ./ sum(confmat,1)';
%         recall(any(isnan(recall),2),:) = [];
%     
%         pp = mean(prec)
%         re = mean(recall)

else
         TP = confmat(1, 1);
         FP = confmat(2, 1);
         FN = confmat(1, 2);
         TN = confmat(2,2);

         Precision = TP / (TP+FP); % positive predictive value (PPV)
         Recall    = TP / (TP+FN); % true positive rate (TPR), sensitivity
         if ((TN / (TN+FP)) > 1)
             Specificity = 1;
         elseif ((TN / (TN+FP)) < 0)
             Specificity = 0;
         else
             Specificity = TN / (TN+FP); % (SPC) or true negative rate
         end
         Accuracy = (TP+TN)/(TP+TN+FP+FN); % Accuracy
         F1score  = 2*TP /(2*TP + FP + FN);
    
end

 


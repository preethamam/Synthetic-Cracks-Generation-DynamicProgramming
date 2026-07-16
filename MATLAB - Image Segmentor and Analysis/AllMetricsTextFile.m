function  AllMetricsTextFile (fileID, ALLresults, LiuMetrics, dataset_name)

    % Pixels classification results (MATLAB)
    fprintf(fileID,'Each object wise (Pixels) classification results by MATLAB\n');
    fprintf(fileID,'Data set name: %s\n', dataset_name);
    fprintf(fileID,'---------------------------------------------------------------------------\n');
    fprintf(fileID,'Classifier name      ANN           KNN            SVM          CNN \n');
    fprintf(fileID,'---------------------------------------------------------------------------\n');
    fprintf(fileID,'Precision           %3.4f         %3.4f         %3.4f       %3.4f \n', ...
        ALLresults(5),ALLresults(6), ALLresults(7), LiuMetrics(2));
    fprintf(fileID,'Recall              %3.4f         %3.4f         %3.4f       %3.4f \n', ...
        ALLresults(8),ALLresults(9), ALLresults(10), LiuMetrics(3));
    fprintf(fileID,'F1score             %3.4f         %3.4f         %3.4f       %3.4f \n', ...
        ALLresults(11),ALLresults(12),ALLresults(13), LiuMetrics(4));
    fprintf(fileID,'Specificity         %3.4f         %3.4f         %3.4f       %3.4f \n', ...
        ALLresults(2),ALLresults(3), ALLresults(4), LiuMetrics(1));
    
    fprintf(fileID,'--------------------------------------------------------------------------- \n');
    fprintf(fileID,'GlobalAccuracy      %3.4f         %3.4f         %3.4f       %3.4f\n', ...
        ALLresults(14),ALLresults(15), ALLresults(16), LiuMetrics(5));
    fprintf(fileID,'MeanAccuracy        %3.4f         %3.4f         %3.4f       %3.4f\n', ...
        ALLresults(17),ALLresults(18), ALLresults(19), LiuMetrics(6));
    fprintf(fileID,'MeanIoU             %3.4f         %3.4f         %3.4f       %3.4f\n', ...
        ALLresults(20),ALLresults(21), ALLresults(22), LiuMetrics(7));
    fprintf(fileID,'WeightedIoU         %3.4f         %3.4f         %3.4f       %3.4f\n', ...
        ALLresults(23),ALLresults(24), ALLresults(25), LiuMetrics(8));
    fprintf(fileID,'---------------------------------------------------------------------------\n');
    fprintf(fileID,'---------------------------------------------------------------------------\n');

end
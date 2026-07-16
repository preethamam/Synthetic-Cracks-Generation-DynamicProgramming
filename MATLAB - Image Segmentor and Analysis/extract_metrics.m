function [AllmetricsFrangi, AllmetricsMFAT, AllmetricsMorpho] = extract_metrics(Classification_Results,  dataType, Index_MFAT)



%% Analysis
Alg_TYPE = {Classification_Results.Alg_TYPE};
Index_Frangi_string = contains(Alg_TYPE,'hybrid_hessian');
Index_MFAT_string   = contains(Alg_TYPE,'hybrid_MFAT');
Index_morpho_string = contains(Alg_TYPE,'morpho');

diffusion_iterations_frangi = cat(1,Classification_Results(Index_Frangi_string).Alg_iter);
diffusion_iterations_MFAT   = cat(1,Classification_Results(Index_MFAT_string).Alg_iter);

diffusion_coffs_frangi = cat(1,Classification_Results(Index_Frangi_string).Kappa);
diffusion_coffs_MFAT   = cat(1,Classification_Results(Index_MFAT_string).Kappa);



% Split the classification results
ClassificationResultsFrangi = Classification_Results(Index_Frangi_string);
ClassificationResultsMFAT   = Classification_Results(Index_MFAT_string);
ClassificationResultsMorpho = Classification_Results(Index_morpho_string);

%% Extract the frangi scores
Index_Frangi = 1;

% Frangi
AllSpANNPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).SpecANNPix_MLAB);
AllSpKNNPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).SpecKNNPix_MLAB);
AllSpSVMPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).SpecSVMPix_MLAB);

AllPrANNPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).PrANNPix_MLAB);
AllPrKNNPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).PrKNNPix_MLAB);
AllPrSVMPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).PrSVMPix_MLAB);

AllReANNPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).ReANNPix_MLAB);
AllReKNNPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).ReKNNPix_MLAB);
AllReSVMPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).ReSVMPix_MLAB);

AllF1ANNPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).F1ANNPix_MLAB);
AllF1KNNPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).F1KNNPix_MLAB);
AllF1SVMPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).F1SVMPix_MLAB);

AllGAANNPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).GlobalAccANNPix_MLAB);
AllGAKNNPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).GlobalAccKNNPix_MLAB);
AllGASVMPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).GlobalAccSVMPix_MLAB);

AllMAANNPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).MeanAccuracyANNPix_MLAB);
AllMAKNNPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).MeanAccuracyKNNPix_MLAB);
AllMASVMPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).MeanAccuracySVMPix_MLAB);

AllMIoUANNPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).MeanIoUANNPix_MLAB);
AllMIoUKNNPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).MeanIoUKNNPix_MLAB);
AllMIoUSVMPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).MeanIoUSVMPix_MLAB);

AllWIoUANNPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).WeightedIoUANNPix_MLAB);
AllWIoUKNNPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).WeightedIoUKNNPix_MLAB);
AllWIoUSVMPixFrangi = cat(1,ClassificationResultsFrangi(Index_Frangi).WeightedIoUSVMPix_MLAB);


% MFAT
[F1ANNmaxval, maxF1ANNPixMFAT] = max(cat(1,ClassificationResultsMFAT.F1ANNPix_MLAB));
[F1KNNmaxval, maxF1KNNPixMFAT] = max(cat(1,ClassificationResultsMFAT.F1KNNPix_MLAB));
[F1SVMmaxval, maxF1SVMPixMFAT] = max(cat(1,ClassificationResultsMFAT.F1SVMPix_MLAB));

% MFAT
if isempty(Index_MFAT)
    
    [~, idx] = max([F1ANNmaxval, F1KNNmaxval, F1SVMmaxval]);
%     if idx == 1
        Index_MFAT = maxF1ANNPixMFAT;
%     elseif idx == 2
%         Index_MFAT = maxF1KNNPixMFAT;
%     else
%         Index_MFAT = maxF1SVMPixMFAT;
%     end
    
%     Index_MFAT
%     ClassificationResultsMFAT(Index_MFAT).Alg_iter
%     
%     AllF1ANNPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).F1ANNPix_MLAB)
%     AllF1KNNPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).F1KNNPix_MLAB)
%     AllF1SVMPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).F1SVMPix_MLAB)
end


    AllSpANNPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).SpecANNPix_MLAB);
    AllSpKNNPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).SpecKNNPix_MLAB);
    AllSpSVMPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).SpecSVMPix_MLAB);

    AllPrANNPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).PrANNPix_MLAB);
    AllPrKNNPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).PrKNNPix_MLAB);
    AllPrSVMPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).PrSVMPix_MLAB);

    AllReANNPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).ReANNPix_MLAB);
    AllReKNNPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).ReKNNPix_MLAB);
    AllReSVMPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).ReSVMPix_MLAB);

    AllF1ANNPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).F1ANNPix_MLAB);
    AllF1KNNPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).F1KNNPix_MLAB);
    AllF1SVMPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).F1SVMPix_MLAB);

    AllGAANNPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).GlobalAccANNPix_MLAB);
    AllGAKNNPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).GlobalAccKNNPix_MLAB);
    AllGASVMPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).GlobalAccSVMPix_MLAB);

    AllMAANNPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).MeanAccuracyANNPix_MLAB);
    AllMAKNNPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).MeanAccuracyKNNPix_MLAB);
    AllMASVMPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).MeanAccuracySVMPix_MLAB);

    AllMIoUANNPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).MeanIoUANNPix_MLAB);
    AllMIoUKNNPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).MeanIoUKNNPix_MLAB);
    AllMIoUSVMPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).MeanIoUSVMPix_MLAB);

    AllWIoUANNPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).WeightedIoUANNPix_MLAB);
    AllWIoUKNNPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).WeightedIoUKNNPix_MLAB);
    AllWIoUSVMPixMFAT = cat(1,ClassificationResultsMFAT(Index_MFAT).WeightedIoUSVMPix_MLAB);

 
% Concatenate results
switch dataType
    case 'diffItr'
        AllmetricsFrangi = [diffusion_iterations_frangi(Index_Frangi,1), AllSpANNPixFrangi, AllSpKNNPixFrangi, AllSpSVMPixFrangi,...
                           AllPrANNPixFrangi, AllPrKNNPixFrangi, AllPrSVMPixFrangi,...
                           AllReANNPixFrangi, AllReKNNPixFrangi, AllReSVMPixFrangi,...
                           AllF1ANNPixFrangi, AllF1KNNPixFrangi, AllF1SVMPixFrangi,...
                           AllGAANNPixFrangi, AllGAKNNPixFrangi, AllGASVMPixFrangi,...
                           AllMAANNPixFrangi, AllMAKNNPixFrangi, AllMASVMPixFrangi,...
                           AllMIoUANNPixFrangi, AllMIoUKNNPixFrangi, AllMIoUSVMPixFrangi, ...
                           AllWIoUANNPixFrangi, AllWIoUKNNPixFrangi, AllWIoUSVMPixFrangi];
    
        AllmetricsMFAT = [diffusion_iterations_MFAT(Index_MFAT,1), AllSpANNPixMFAT, AllSpKNNPixMFAT, AllSpSVMPixMFAT,...
                           AllPrANNPixMFAT, AllPrKNNPixMFAT, AllPrSVMPixMFAT,...
                           AllReANNPixMFAT, AllReKNNPixMFAT, AllReSVMPixMFAT,...
                           AllF1ANNPixMFAT, AllF1KNNPixMFAT, AllF1SVMPixMFAT,...
                           AllGAANNPixMFAT, AllGAKNNPixMFAT, AllGASVMPixMFAT,...
                           AllMAANNPixMFAT, AllMAKNNPixMFAT, AllMASVMPixMFAT,...
                           AllMIoUANNPixMFAT, AllMIoUKNNPixMFAT, AllMIoUSVMPixMFAT, ...
                           AllWIoUANNPixMFAT, AllWIoUKNNPixMFAT, AllWIoUSVMPixMFAT];
                       
     case 'diffCoff'
        AllmetricsFrangi = [diffusion_coffs_frangi(Index_Frangi,1), AllSpANNPixFrangi, AllSpKNNPixFrangi, AllSpSVMPixFrangi,...
                           AllPrANNPixFrangi, AllPrKNNPixFrangi, AllPrSVMPixFrangi,...
                           AllReANNPixFrangi, AllReKNNPixFrangi, AllReSVMPixFrangi,...
                           AllF1ANNPixFrangi, AllF1KNNPixFrangi, AllF1SVMPixFrangi,...
                           AllGAANNPixFrangi, AllGAKNNPixFrangi, AllGASVMPixFrangi,...
                           AllMAANNPixFrangi, AllMAKNNPixFrangi, AllMASVMPixFrangi,...
                           AllMIoUANNPixFrangi, AllMIoUKNNPixFrangi, AllMIoUSVMPixFrangi, ...
                           AllWIoUANNPixFrangi, AllWIoUKNNPixFrangi, AllWIoUSVMPixFrangi];
    
        AllmetricsMFAT = [diffusion_coffs_MFAT(Index_MFAT,1), AllSpANNPixMFAT, AllSpKNNPixMFAT, AllSpSVMPixMFAT,...
                           AllPrANNPixMFAT, AllPrKNNPixMFAT, AllPrSVMPixMFAT,...
                           AllReANNPixMFAT, AllReKNNPixMFAT, AllReSVMPixMFAT,...
                           AllF1ANNPixMFAT, AllF1KNNPixMFAT, AllF1SVMPixMFAT,...
                           AllGAANNPixMFAT, AllGAKNNPixMFAT, AllGASVMPixMFAT,...
                           AllMAANNPixMFAT, AllMAKNNPixMFAT, AllMASVMPixMFAT,...
                           AllMIoUANNPixMFAT, AllMIoUKNNPixMFAT, AllMIoUSVMPixMFAT, ...
                           AllWIoUANNPixMFAT, AllWIoUKNNPixMFAT, AllWIoUSVMPixMFAT];
end


% Morpho results
AllmetricsMorpho = [ClassificationResultsMorpho.SpecANNPix_MLAB, ClassificationResultsMorpho.SpecKNNPix_MLAB, ...
                    ClassificationResultsMorpho.SpecSVMPix_MLAB, ClassificationResultsMorpho.PrANNPix_MLAB, ...
                    ClassificationResultsMorpho.PrKNNPix_MLAB, ClassificationResultsMorpho.PrSVMPix_MLAB, ...
                    ClassificationResultsMorpho.ReANNPix_MLAB, ClassificationResultsMorpho.ReKNNPix_MLAB,...
                    ClassificationResultsMorpho.ReSVMPix_MLAB, ClassificationResultsMorpho.F1ANNPix_MLAB, ...
                    ClassificationResultsMorpho.F1KNNPix_MLAB, ClassificationResultsMorpho.F1SVMPix_MLAB,...
                    ClassificationResultsMorpho.GlobalAccANNPix_MLAB, ClassificationResultsMorpho.GlobalAccKNNPix_MLAB, ...
                    ClassificationResultsMorpho.GlobalAccSVMPix_MLAB, ClassificationResultsMorpho.MeanAccuracyANNPix_MLAB, ...
                    ClassificationResultsMorpho.MeanAccuracyKNNPix_MLAB, ClassificationResultsMorpho.MeanAccuracySVMPix_MLAB, ...
                    ClassificationResultsMorpho.MeanIoUANNPix_MLAB, ClassificationResultsMorpho.MeanIoUKNNPix_MLAB, ...
                    ClassificationResultsMorpho.MeanIoUSVMPix_MLAB, ClassificationResultsMorpho.WeightedIoUANNPix_MLAB, ...
                    ClassificationResultsMorpho.WeightedIoUKNNPix_MLAB, ClassificationResultsMorpho.WeightedIoUSVMPix_MLAB];

end


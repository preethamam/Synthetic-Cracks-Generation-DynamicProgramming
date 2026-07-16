function [AllPRREF1Frangi,AllPRREF1MFAT,ClassificationResultsFrangi,ClassificationResultsMFAT,...
          ClassificationResultsMorpho] = extractFrangiMFAT_Results(Classification_Results, dataType)



%% Analysis
Alg_TYPE = {Classification_Results.Alg_TYPE};
Index_Frangi = contains(Alg_TYPE,'hybrid_hessian');
Index_MFAT   = contains(Alg_TYPE,'hybrid_MFAT');
Index_morpho = contains(Alg_TYPE,'morpho');
Index_Frangi = 1;

%% Extract the F1 scores
diffusion_iterations_frangi = cat(1,Classification_Results(Index_Frangi).Alg_iter);
diffusion_iterations_MFAT   = cat(1,Classification_Results(Index_MFAT).Alg_iter);

diffusion_coffs_frangi = cat(1,Classification_Results(Index_Frangi).Kappa);
diffusion_coffs_MFAT   = cat(1,Classification_Results(Index_MFAT).Kappa);

% Frangi
AllPrANNPixFrangi = cat(1,Classification_Results(Index_Frangi).PrANNPix_MLAB);
AllPrKNNPixFrangi = cat(1,Classification_Results(Index_Frangi).PrKNNPix_MLAB);
AllPrSVMPixFrangi = cat(1,Classification_Results(Index_Frangi).PrSVMPix_MLAB);

AllReANNPixFrangi = cat(1,Classification_Results(Index_Frangi).ReANNPix_MLAB);
AllReKNNPixFrangi = cat(1,Classification_Results(Index_Frangi).ReKNNPix_MLAB);
AllReSVMPixFrangi = cat(1,Classification_Results(Index_Frangi).ReSVMPix_MLAB);

AllF1ANNPixFrangi = cat(1,Classification_Results(Index_Frangi).F1ANNPix_MLAB);
AllF1KNNPixFrangi = cat(1,Classification_Results(Index_Frangi).F1KNNPix_MLAB);
AllF1SVMPixFrangi = cat(1,Classification_Results(Index_Frangi).F1SVMPix_MLAB);


% MFAT
AllPrANNPixMFAT = cat(1,Classification_Results(Index_MFAT).PrANNPix_MLAB);
AllPrKNNPixMFAT = cat(1,Classification_Results(Index_MFAT).PrKNNPix_MLAB);
AllPrSVMPixMFAT = cat(1,Classification_Results(Index_MFAT).PrSVMPix_MLAB);

AllReANNPixMFAT = cat(1,Classification_Results(Index_MFAT).ReANNPix_MLAB);
AllReKNNPixMFAT = cat(1,Classification_Results(Index_MFAT).ReKNNPix_MLAB);
AllReSVMPixMFAT = cat(1,Classification_Results(Index_MFAT).ReSVMPix_MLAB);

AllF1ANNPixMFAT = cat(1,Classification_Results(Index_MFAT).F1ANNPix_MLAB);
AllF1KNNPixMFAT = cat(1,Classification_Results(Index_MFAT).F1KNNPix_MLAB);
AllF1SVMPixMFAT = cat(1,Classification_Results(Index_MFAT).F1SVMPix_MLAB);


% Split the classification results
ClassificationResultsFrangi = Classification_Results(Index_Frangi);
ClassificationResultsMFAT   = Classification_Results(Index_MFAT);
ClassificationResultsMorpho = Classification_Results(Index_morpho);

% Concatenate results
switch dataType
    case 'diffItr'
        AllPRREF1Frangi = [diffusion_iterations_frangi(:,1), AllPrANNPixFrangi, AllPrKNNPixFrangi, AllPrSVMPixFrangi,...
                            AllReANNPixFrangi, AllReKNNPixFrangi, AllReSVMPixFrangi, AllF1ANNPixFrangi, AllF1KNNPixFrangi, AllF1SVMPixFrangi];
        AllPRREF1MFAT   = [diffusion_iterations_MFAT(:,1), AllPrANNPixMFAT, AllPrKNNPixMFAT, AllPrSVMPixMFAT,...
                            AllReANNPixMFAT, AllReKNNPixMFAT, AllReSVMPixMFAT, AllF1ANNPixMFAT, AllF1KNNPixMFAT, AllF1SVMPixMFAT];
                        
    case 'diffCoff'
        AllPRREF1Frangi = [diffusion_coffs_frangi(:,1), AllPrANNPixFrangi, AllPrKNNPixFrangi, AllPrSVMPixFrangi,...
                            AllReANNPixFrangi, AllReKNNPixFrangi, AllReSVMPixFrangi, AllF1ANNPixFrangi, AllF1KNNPixFrangi, AllF1SVMPixFrangi];
        AllPRREF1MFAT   = [diffusion_coffs_MFAT(:,1), AllPrANNPixMFAT, AllPrKNNPixMFAT, AllPrSVMPixMFAT,...
                            AllReANNPixMFAT, AllReKNNPixMFAT, AllReSVMPixMFAT, AllF1ANNPixMFAT, AllF1KNNPixMFAT, AllF1SVMPixMFAT];
end

end


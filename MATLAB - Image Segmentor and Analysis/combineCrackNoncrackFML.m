function combineCrackNoncrackFML(realworld_train_FML, realworld_val_FML, hessian_mfat_morpho_wholeData, ...
                                    save_Train_matfile, save_Val_matfile, noncrackLabel)

    
    idx_crack_hessian_mfat_morpho_wholeData = find(hessian_mfat_morpho_wholeData.Labelmat_conc == noncrackLabel);

    hmm_FM_conc = hessian_mfat_morpho_wholeData.Featuremat_conc(idx_crack_hessian_mfat_morpho_wholeData,:);
    [Featuremat_conc_unq, ia, ic] = unique(hmm_FM_conc,'stable','rows');
     
    randIdxs = randsample(ia, ...
                          length(realworld_train_FML.Featuremat) + length(realworld_val_FML.Featuremat));
    randIdx_train = randsample(randIdxs, length(realworld_train_FML.Featuremat));
    randIdx_val = setdiff(randIdxs,randIdx_train);
    
    Featuremat_conc     = [realworld_train_FML.Featuremat; ...
                           hessian_mfat_morpho_wholeData.Featuremat_conc(randIdx_train,:)];
                       
    Featuremat_std_conc = [realworld_train_FML.Featuremat_std; ...
                           hessian_mfat_morpho_wholeData.Featuremat_std_conc(randIdx_train,:)];
                       
    Labelmat_conc       = [realworld_train_FML.Labelmat; ...
                           hessian_mfat_morpho_wholeData.Labelmat_conc(randIdx_train)];
    
    save(save_Train_matfile, ...
        'Featuremat_conc','Featuremat_std_conc', 'Labelmat_conc', '-v7.3');

    clear 'Featuremat_conc' 'Featuremat_std_conc' 'Labelmat_conc';

    Featuremat_conc     = [realworld_val_FML.Featuremat; ...
                       hessian_mfat_morpho_wholeData.Featuremat_conc(randIdx_val,:)];

    Featuremat_std_conc = [realworld_val_FML.Featuremat_std; ...
                           hessian_mfat_morpho_wholeData.Featuremat_std_conc(randIdx_val,:)];

    Labelmat_conc       = [realworld_val_FML.Labelmat; ...
                           hessian_mfat_morpho_wholeData.Labelmat_conc(randIdx_val)];

    save(save_Val_matfile,...
        'Featuremat_conc','Featuremat_std_conc', 'Labelmat_conc', '-v7.3');
end
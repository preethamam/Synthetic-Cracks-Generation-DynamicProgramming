function uniqueCrackNoncrackFML(realworld_trainval_FML_cnc, noncrackLabel, crackLabel,  ...
                                    saveUnqMatfile, inpstruct)

    noncrackIndxs = find(realworld_trainval_FML_cnc.Labelmat_conc == noncrackLabel);
    crackIndxs = find(realworld_trainval_FML_cnc.Labelmat_conc == crackLabel);
    
    noncracksUnique = unique(realworld_trainval_FML_cnc.Featuremat_conc(noncrackIndxs,:),'stable','rows');
    cracksUnique = unique(realworld_trainval_FML_cnc.Featuremat_conc(crackIndxs,:),'stable','rows');
    
    Featuremat_conc_unique = [noncracksUnique; cracksUnique];
    Labelmat_conc_unique = [ones(length(noncracksUnique),1); 2*ones(length(cracksUnique),1)];
    
    samples = [length(noncracksUnique), length(cracksUnique)]
    samples_final = min(length(noncracksUnique), length(cracksUnique))
    
    % Making dataset for training, validation and testing   
    % Shuffle feature matrix and label vector acccordingly
    [ Feature_matrix, LabelsVector, TargetMatrix, indexMap ] = ...
    shuffleFeatMatLabel( Featuremat_conc_unique, Labelmat_conc_unique, inpstruct);
    
    % Save IM_info, Feature_matrix, LabelsVector, TargetMatrix, indexMap
    save(saveUnqMatfile, ...
        'Feature_matrix', 'LabelsVector', 'TargetMatrix', 'indexMap')
end
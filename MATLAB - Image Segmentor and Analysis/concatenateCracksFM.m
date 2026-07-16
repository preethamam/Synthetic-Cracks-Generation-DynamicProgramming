function concatenateCracksFM(inputMatFilenames, saveOutputMatFilename, findUniqueIdx, crackLabel)

Featuremat = [];
Featuremat_std = [];
Labelmat = [];
for i = 1:length(inputMatFilenames)
    temp = load(inputMatFilenames{i});
    if i == findUniqueIdx
        idx_crack = find(temp.Labelmat_conc == crackLabel);
        hmm_crack_fm = temp.Featuremat_conc(idx_crack,:);
        hmm_crack_fm_std = temp.Featuremat_std_conc(idx_crack,:);
        [Featuremat_unq, ia, ic] = unique(hmm_crack_fm,'stable','rows');
        randIdx_train = randsample(ia, fmat_size);
        temp.Featuremat = hmm_crack_fm(randIdx_train,:);
        temp.Featuremat_std = hmm_crack_fm_std(randIdx_train,:);
        temp.Labelmat = 2*ones(length(randIdx_train),1);
    end
    Featuremat = [Featuremat; temp.Featuremat]; 
    Featuremat_std = [Featuremat_std; temp.Featuremat_std];
    Labelmat = [Labelmat; temp.Labelmat];

    fmat_size = size(Featuremat,1);
end 

save(saveOutputMatFilename, 'Featuremat','Featuremat_std', 'Labelmat', '-v7.3')
end
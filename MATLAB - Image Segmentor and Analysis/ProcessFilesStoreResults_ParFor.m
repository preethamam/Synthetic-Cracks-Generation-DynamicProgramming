% Initialize arrays
rocArrayij_ImageClassification = cell(size(hybrid_Frangi_search_allPerms,1) + size(hybrid_MFAT_search_allPerms,1) + 1, 1);
rocArrayij_AllComponents = cell(size(hybrid_Frangi_search_allPerms,1) + size(hybrid_MFAT_search_allPerms,1) + 1, 1);
rocArrayBBox_MLAB = cell(size(hybrid_Frangi_search_allPerms,1) + size(hybrid_MFAT_search_allPerms,1) + 1, 1);
rocArray_SSM = cell(size(hybrid_Frangi_search_allPerms,1) + size(hybrid_MFAT_search_allPerms,1) + 1, 1);
Classification_Results = [];

% Create temp folder for workers
temp = 'D:\Xtreme_Programming\MATLAB';
tempFolder = fullfile(temp,'tempfiles');


for i = 1:length(Algorithm_TYPE)
    
    % Populate algorithm type
    hybrid_inpstruct.Algorithm_TYPE = Algorithm_TYPE{i};    
    
    switch hybrid_inpstruct.Algorithm_TYPE
        case 'hybrid_hessian'

        % Load ANN, KNN and SVM kernels
        load (ANN_classifier_hybrid,'net');
        load (KNN_classifier_hybrid,'MdlKNN');
        load (SVM_classifier_hybrid,'ScoreCSVMModel');
        
        % Create temp holder for workers
        write2file_parpool_const = parallel.pool.Constant(@() fopen(tempname(tempFolder),'wt'),@fclose);
        spmd    
           filesComposite = fopen(write2file_parpool_const.Value);
        end

        % Total worker files
        totalFiles = length(filesComposite);
        
        %Before the loop, we need to construct the object. 
        WaitMessage = waitbarParfor(size(hybrid_Frangi_search_allPerms,1), 'Waitbar', true);

            parfor m = 1:size(hybrid_Frangi_search_allPerms,1)
                
                %Send a message to the object. 
                WaitMessage.Send;
                
                % Get worker ID
                getworkerID = getCurrentTask(); 
                if ~(isempty(getworkerID))
                    workerID = getworkerID.ID;
                else
                    workerID = [];
                end
                
                % Iteration numbers
                hybrid_Frangi_allPerms = hybrid_Frangi_search_allPerms(m,:);
                
                % Print the anisotropic iteration number
                fprintf('Hessian Total iteration no.: %d | Anisotropic [I and II] iterations: %d %d\n', m, hybrid_Frangi_allPerms(1,1),...
                        hybrid_Frangi_allPerms(1,2));

                % Main images processing
                [rocArrayij_ImageClassification{m}, rocArrayij_AllComponents{m}, rocArrayBBox_MLAB{m}, rocArray_SSM{m}, ...
                Algorithm_Results] = Processed_Results(workerID, write2file_parpool_const.Value, hybrid_inpstruct, jahan_inpstruct, hybrid_Frangi_allPerms, ...
                                                        images2classifier,imagesGroundTruth2classifier, ...
                                                        classnumber, MdlKNN, ScoreCSVMModel, net, imgCount, ...
                                                        objBoxCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs,...
                                                        ANN_classifier_hybrid, KNN_classifier_hybrid, SVM_classifier_hybrid,...
                                                        ANN_classifier_morpho, KNN_classifier_morpho, SVM_classifier_morpho);  
                
                Classification_Results = [Classification_Results, Algorithm_Results];
            end
            
            %Destroy the object.
            WaitMessage.Destroy 
            
            for k = 1 : totalFiles
                fileSize = dir(string(filesComposite(k)));
                the_size = fileSize.bytes;
                if ~(the_size == 0)
                    filename = sprintf('parworker_filename_%d.txt',k);
                    textFiles2merge{k} = filename;
                    fout=fopen(fullfile(tempFolder,filename),'w');
                    [filepath,name,ext] = fileparts(string(filesComposite(k)));
                    [status,message,messageId] = copyfile(fullfile(tempFolder,name), ...
                                                          fullfile(tempFolder,filename),'f');
                    fclose(fout);
                end
            end
            
            for cntfiles = 1:length(textFiles2merge)
              fin = fopen(fullfile(tempFolder,textFiles2merge{cntfiles}));
              while ~feof(fin)
                fprintf(fileID,'%s \n',fgetl(fin));
              end
              fclose(fin);
            end
            
            clear write2file_parpool_const; % Closes the temporary files.    
%             delete(gcp('nocreate'));

        case 'hybrid_MFAT'

            % Load ANN, KNN and SVM kernels
            load (ANN_classifier_hybrid,'net');
            load (KNN_classifier_hybrid,'MdlKNN');
            load (SVM_classifier_hybrid,'ScoreCSVMModel');
            
            % Create temp holder for workers
            write2file_parpool_const = parallel.pool.Constant(@() fopen(tempname(tempFolder),'wt'),@fclose);
            spmd    
               filesComposite = fopen(write2file_parpool_const.Value);
            end

            % Total worker files
            totalFiles = length(filesComposite);
            
            %Before the loop, we need to construct the object. 
            WaitMessage = waitbarParfor(size(hybrid_MFAT_search_allPerms,1), 'Waitbar', true);
            
            parfor m = size(hybrid_Frangi_search_allPerms,1) + 1 : size(hybrid_Frangi_search_allPerms,1) + size(hybrid_MFAT_search_allPerms,1)
                
                % Send a message to the object. 
                WaitMessage.Send;
                
                % Get worker ID
                getworkerID = getCurrentTask(); 
                if ~(isempty(getworkerID))
                    workerID = getworkerID.ID;
                else
                    workerID = [];
                end
                
                idx = m - size(hybrid_Frangi_search_allPerms,1);
                
                % Iteration numbers
                hybrid_MFAT_allPerms = hybrid_MFAT_search_allPerms(idx,:);
                
                % Print the anisotropic iteration number
                fprintf('MFAT Total iteration no.: %d | Anisotropic [I and II] iterations: %d %d\n', idx, hybrid_MFAT_allPerms(1,1),...
                        hybrid_MFAT_allPerms(1,2))
                
                % Main images processing
                [rocArrayij_ImageClassification{m}, rocArrayij_AllComponents{m}, rocArrayBBox_MLAB{m}, rocArray_SSM{m}, ...
                Algorithm_Results] = Processed_Results(workerID, write2file_parpool_const.Value, hybrid_inpstruct, jahan_inpstruct, hybrid_MFAT_allPerms, ...
                                                        images2classifier,imagesGroundTruth2classifier, ...
                                                        classnumber, MdlKNN, ScoreCSVMModel, net, imgCount, ...
                                                        objBoxCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs,...
                                                        ANN_classifier_hybrid, KNN_classifier_hybrid, SVM_classifier_hybrid,...
                                                        ANN_classifier_morpho, KNN_classifier_morpho, SVM_classifier_morpho);
                
                Classification_Results = [Classification_Results, Algorithm_Results];
                
            end
            
            %Destroy the object.
            WaitMessage.Destroy 
            
            for k = 1 : totalFiles
                fileSize = dir(string(filesComposite(k)));
                the_size = fileSize.bytes;
                if ~(the_size == 0)
                    filename = sprintf('parworker_filename_%d.txt',k);
                    textFiles2merge{k} = filename;
                    fout=fopen(fullfile(tempFolder,filename),'w');
                    [filepath,name,ext] = fileparts(string(filesComposite(k)));
                    [status,message,messageId] = copyfile(fullfile(tempFolder,name), ...
                                                          fullfile(tempFolder,filename),'f');
                    fclose(fout);
                end
            end
            
            for cntfiles = 1:length(textFiles2merge)
              fin = fopen(fullfile(tempFolder,textFiles2merge{cntfiles}));
              while ~feof(fin)
                fprintf(fileID,'%s \n',fgetl(fin));
              end
              fclose(fin);
            end
            
            clear write2file_parpool_const; % Closes the temporary files.   
%             delete(gcp('nocreate'));

        case 'morpho'
            
            % Print the anisotropic iteration number
            fprintf('Morphological method started!\n');
            
            % Load ANN, KNN and SVM kernels
            load (ANN_classifier_morpho,'net');
            load (KNN_classifier_morpho,'MdlKNN');
            load (SVM_classifier_morpho,'ScoreCSVMModel');
            
            % Get worker ID
            workerID = 0;
                
            m = size(hybrid_Frangi_search_allPerms,1) + size(hybrid_MFAT_search_allPerms,1) + 1;
            
            % Main images processing
            [rocArrayij_ImageClassification{m}, rocArrayij_AllComponents{m}, rocArrayBBox_MLAB{m}, rocArray_SSM{m}, ...
            Algorithm_Results] = Processed_Results(workerID, fileID, hybrid_inpstruct, jahan_inpstruct, [], ...
                                                    images2classifier,imagesGroundTruth2classifier, ...
                                                    classnumber, MdlKNN, ScoreCSVMModel, net, imgCount, ...
                                                    objBoxCracksnNoncracksGTs, ssmPixCracksnNoncracksGTs,...
                                                    ANN_classifier_hybrid, KNN_classifier_hybrid, SVM_classifier_hybrid,...
                                                    ANN_classifier_morpho, KNN_classifier_morpho, SVM_classifier_morpho);
                                                
            Classification_Results = [Classification_Results, Algorithm_Results];

    end
end

%% Plot ROC curves
ROC_Curves_TestingDataset;

%% Save mat file of workspace variables
if(hybrid_inpstruct.save_mat_file || strcmp(hybrid_inpstruct.searchType,'grid_search'))
    % Variables to save
    matSaveStruct.Classification_Results         = Classification_Results;
    matSaveStruct.rocArrayBBox_MLAB              = rocArrayBBox_MLAB;
    matSaveStruct.rocArray_SSM                   = rocArray_SSM;
    matSaveStruct.rocArrayij_ImageClassification = rocArrayij_AllComponents;
    matSaveStruct.rocArrayij_ImageClassification = rocArrayij_ImageClassification;
    matSaveStruct.hybrid_FrangiITRnum = size(hybrid_Frangi_search_allPerms,1);
    matSaveStruct.hybrid_MFATITRnum   = size(hybrid_MFAT_search_allPerms,1);
    
    % MAT file name to save
    [filepath,name,ext] = fileparts(textFile);
    matFileName = [name '_' datestr(now,'yyyy_mm_dd_HH_MM_SS_FFF') '.mat'];
    save(fullfile(matFolder,matFileName),'-struct', 'matSaveStruct', '-v7.3')
end

function [fixedIM, BBoxesData, BBoxesData_scores, BBoxesData_Labels] = fixClass2Labels(input, BW, MdlY, Pixcoords, postprocess,non_crack_class, post_process_Type, circularity_threshold, ...
    branchpoints, CircIndex,Branch_points,holes, BBoxes, scores)

switch postprocess
    case {0, 2}
        index_removed_crack = [];
        
        for i = 1 : length (CircIndex)
            if~(isempty(MdlY))
                if (MdlY(i) == non_crack_class)
                    rowpix = Pixcoords{1,1}{i,1};
                    colpix = Pixcoords{1,2}{i,1};
                    
                    ind = sub2ind(size(BW),rowpix,colpix);
                    BW(ind) = 0;
                    
                    index_removed_crack = [index_removed_crack, i];
                end
            end
        end
    case 1
        index_removed_crack = [];
        
        for i = 1 : length (CircIndex)
            if(isempty(MdlY))
                switch post_process_Type
                    case 'circularity'
                        if ((CircIndex{i} > circularity_threshold(2)) ...
                             || (CircIndex{i} < circularity_threshold(1)))                             
                            rowpix = Pixcoords{1,1}{i,1};
                            colpix = Pixcoords{1,2}{i,1};

                            ind = sub2ind(size(BW),rowpix,colpix);
                            BW(ind) = 0;
                            
                            index_removed_crack = [index_removed_crack, i];
                        end
                        
                    case 'circ_branchpoint_holes'
                        if (((CircIndex{i} > circularity_threshold(2)) ...
                             || (CircIndex{i} < circularity_threshold(1)))...
                             || Branch_points{i} > branchpoints ...
                             || holes(i) ~=1 )
                            rowpix = Pixcoords{1,1}{i,1};
                            colpix = Pixcoords{1,2}{i,1};
                            
                            ind = sub2ind(size(BW),rowpix,colpix);
                            BW(ind) = 0;
                            
                            index_removed_crack = [index_removed_crack, i];
                        end
                end
            else
                switch post_process_Type
                    case 'circularity'
                        if ((MdlY(i) == non_crack_class) || ...
                                ((CircIndex{i} > circularity_threshold(2)) ||...
                                (CircIndex{i} < circularity_threshold(1))))
                            rowpix = Pixcoords{1,1}{i,1};
                            colpix = Pixcoords{1,2}{i,1};
                            
                            ind = sub2ind(size(BW),rowpix,colpix);
                            BW(ind) = 0;
                            
                            index_removed_crack = [index_removed_crack, i];
                        end
                    case 'circ_branchpoint_holes'
                        if ((MdlY(i) == non_crack_class) || ...
                                ((CircIndex{i} > circularity_threshold(2)) ...
                                || (CircIndex{i} < circularity_threshold(1))) ...
                                || Branch_points{i} > branchpoints ...
                                || holes(i) ~=1 )
                            rowpix = Pixcoords{1,1}{i,1};
                            colpix = Pixcoords{1,2}{i,1};
                            
                            ind = sub2ind(size(BW),rowpix,colpix);
                            BW(ind) = 0;
                            
                            index_removed_crack = [index_removed_crack, i];
                        end
                 end
            end
        end
end
                
% Fixed image
fixedIM = BW;

% Concatenate the BBoxes for the classifiers
y_posIndex = setdiff(1:length(CircIndex), index_removed_crack);

if ~(isempty(y_posIndex) || isempty(BBoxes))
    BBoxesData        = BBoxes{1,1}(y_posIndex,:); %#ok<*FNDSB>
    BBoxesData_scores = scores(y_posIndex,2); %#ok<*FNDSB>
    BBoxesData_Labels = categorical(repmat(input.classNames(1),numel(y_posIndex),1)); %#ok<*FNDSB>
else
    BBoxesData        = []; %#ok<*FNDSB>
    BBoxesData_scores = []; %#ok<*FNDSB>
    BBoxesData_Labels = []; %#ok<*FNDSB>
end

end


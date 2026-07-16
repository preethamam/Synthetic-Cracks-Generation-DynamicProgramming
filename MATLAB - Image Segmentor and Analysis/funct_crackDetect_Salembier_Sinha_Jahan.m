function [crackMap] = funct_crackDetect_Salembier_Sinha_Jahan ...
                                    (IMnew, crackLEN, anglebetween)

        % Initialize crackmap array
        crackMap = zeros(size(IMnew));

        for k = 1:numel(crackLEN)
            % Initialize image open/close array
            IMopenClose_old = zeros(size(IMnew)); %-1*ones(size(IMnew));

            for i = 1:numel(anglebetween)   
                SE = strel('line', crackLEN(k), anglebetween(i));
                IMopenClose_new = imclose(imopen(IMnew,SE),SE);
                IMopenClose_old = max(IMopenClose_new, IMopenClose_old);
            end

            % Final maximum values extraction
            IMopenClose_IM_max = max(IMopenClose_old, IMnew);
            T = IMopenClose_IM_max - IMnew;

            % Binarised and thresholded image
            level = graythresh(uint8(T));
            BW    = imbinarize(uint8(T),level);

            % Multi-scale crack map
            crackMap = max(crackMap, BW);
        end
end
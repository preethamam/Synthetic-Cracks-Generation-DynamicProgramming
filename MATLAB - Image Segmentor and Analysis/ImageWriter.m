function ImageWriter( Iground2PrecisionRecall,...
                      classifierImage,Ioriginal, IAnnotate, filesavepath, ImageID, classifierName)

                  
[pathstr,name,ext] = fileparts(ImageID); 
                  
% Figures;
subplot(2,2,1); imshow(Ioriginal); title('Original Image')
subplot(2,2,2); imshow(IAnnotate); title('Annotated Image')
subplot(2,2,3); imshow(Iground2PrecisionRecall); title('Ground-truth Image') %imshow(FalseNegative)
subplot(2,2,4); imshow(classifierImage); title('Algorithm Output Image')

if (0)
    saveas(gcf, fullfile(filesavepath,'CrackOutputs', [name, '_', classifierName, lower(ext)]))
end

end


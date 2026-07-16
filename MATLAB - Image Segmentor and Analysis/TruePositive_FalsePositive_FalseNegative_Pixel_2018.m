function [ TruePositivePix, FalsePositivePix, FalseNegativePix, TrueNegativePix  ] = ...
    TruePositive_FalsePositive_FalseNegative_Pixel_2018( Iground2PrecisionRecall,...
                                    classifierImage)

% True positive
TP = bitand(Iground2PrecisionRecall, classifierImage);

% False positive
FP = imsubtract(classifierImage,TP);
FP(FP == -1)  = 1;

% False negative
FN = imsubtract(Iground2PrecisionRecall,TP);
FN(FN == -1)  = 1;

% True negative
TN = ~(Iground2PrecisionRecall | classifierImage);

% Calculate the TP, FP and FN pixels
TruePositivePix  = sum(sum(TP));

FalsePositivePix = sum(sum(FP));

FalseNegativePix = sum(sum(FN));

TrueNegativePix  = sum(sum(TN));

end


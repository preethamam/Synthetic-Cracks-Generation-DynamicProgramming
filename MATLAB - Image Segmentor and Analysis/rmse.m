function RMSE = rmse(A,B)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here


RMSE = sqrt(mean((A(:) - B(:)).^2));

end


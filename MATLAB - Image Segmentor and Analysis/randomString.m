function string = randomString(MAX_ST_LENGTH)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

symbols = ['a':'z' 'A':'Z' '0':'9'];
nums = randi(numel(symbols),[1 MAX_ST_LENGTH]);
string = symbols (nums);

end


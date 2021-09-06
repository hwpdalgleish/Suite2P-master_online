function [corr] = load_corr(fileName)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

fid = fopen(fileName,'r');
corr = fread(fid,'single');
fclose(fid);

end


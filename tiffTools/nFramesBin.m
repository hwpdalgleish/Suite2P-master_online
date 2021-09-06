function [pixelsPerLine,linesPerFrame,numFrames] = nFramesBin(filePath)
%nFrames find the number of frames in the Tiff

% %keep guessing until we seek too far
% guess = 1000;
% overSeeked = false;
% 
% if ischar(tiff)
%   tiff = Tiff(tiff, 'r');
%   closeTiff = onCleanup(@() close(tiff));
% end
% 
% while ~overSeeked
%   try
%     tiff.setDirectory(guess);
%     guess = 2*guess; %double the guess
%   catch ex
%     overSeeked = true; %we tried to seek past the last directory
%   end
% end
% %when overseeking occurs, the current directory/frame will be the last one
% n = tiff.currentDirectory;

fileID = fopen(filePath);

% Read 'header' to get dimensions
pixelsPerLine = fread(fileID, 1, 'uint16');
linesPerFrame = fread(fileID, 1, 'uint16');
samplesPerFrame = pixelsPerLine*linesPerFrame;

% Find number of frames in file
fileInfo = dir(filePath);
numBytes = fileInfo.bytes;
numFrames = ((numBytes/2) - 2) / samplesPerFrame;          % divide by 2 because format is uint16; subtract 2 because file header

end


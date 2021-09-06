function [data] = read_bin(fid,Lx,Ly,nFrames,stride,offset)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

if nargin == 3
    nFrames = inf;
    offset = 0;
    stride = 1;
elseif nargin == 4
    offset = 0;
    stride = 1;
end

if ischar(fid)
    fid = fopen(fileName,'r');
    fread(fid,2+((ops.iplane-1)*Lx*Ly),'uint16');
end

if offset > 0
    fread(fid,offset,'uint16');
end

data = zeros(Ly,Lx,nFrames,'uint16');
precision = [num2str(Ly*Lx) '*uint16'];
skip = 2*Ly*Lx*(stride-1);

frame = 1;
try
    data(:,:,frame) = fread(fid,[Ly,Lx],precision,skip);
    success = false(1,nFrames);
    success(1) = true;
    while frame<nFrames
        frame = frame+1;
        try
            data(:,:,frame) = permute(fread(fid,[Ly,Lx],precision,skip),[2 1 3]);
            success(frame) = true;
        catch
            break
        end
    end
    data = data(:,:,success);
catch
    data = [];
end

end


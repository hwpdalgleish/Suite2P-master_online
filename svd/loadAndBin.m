% needs ops.RegFile, ops.xrange, ops.yrange, ops.NavgFramesSVD
% Ly, Lx are the size of each frame. nimgbatch: the number of frames loaded per batch
% nt0 is the number of timepoints to bin over. If a sixth argument is
% present, it does not subtract the mean of each batch. 
function [mov,ops] = loadAndBin(ops, Ly, Lx, nimgbatch, nt0, clustModel)

ix = 0;
%fid = fopen(ops.RegFile, 'r');
file_idx = 1;
fid = fopen(ops.fsroot{file_idx}.name, 'r');
fread(fid,2+((ops.iplane-1)*Lx*Ly),'uint16');
mov = zeros(numel(ops.yrange), numel(ops.xrange), ops.NavgFramesSVD, 'single');
ij = 0;
ops.mimg1 = zeros(Ly,Lx,'single');
frames_read = 0;
while 1
    % load frames
    %data = fread(fid,  Ly*Lx*nimgbatch, '*int16'); HD 20180717
    %data = fread(fid, Ly*Lx*nimgbatch*ops.nplanes, 'uint16');
    data = read_bin(fid,Lx,Ly,nimgbatch,ops.nplanes,0);
    frames_read = frames_read + size(data,3);
    frames_left = ops.Nframes - frames_read;
    if frames_left < 0
        data(:,:,end+(frames_left+1)) = [];
    end
    
    if isempty(data)
        file_idx = file_idx+1;
        if file_idx <= numel(ops.fsroot)
            fid = fopen(ops.fsroot{file_idx}.name, 'r');
            fread(fid,2+((ops.iplane-1)*Lx*Ly),'uint16');
            frames_read = 0;
            data = read_bin(fid,Lx,Ly,nimgbatch,ops.nplanes,0);
            frames_read = frames_read + size(data,3);
            frames_left = ops.Nframes - frames_read;
            if frames_left < 0
                data(:,:,end+(frames_left+1)) = [];
            end
            if isempty(data)
                break;
            end
        else
            break;
        end
    end
    data = single(data);

    ops.mimg1 = ops.mimg1 + sum(data,3);
    
    % ignore bad frames
    badi = ops.badframes(ix + [1:size(data,3)]);
%     data(:,:, badi) = [];
    
    % subtract off the mean of this batch
    if nargin<=5
        data = bsxfun(@minus, data, mean(data,3));
    end
    %     data = bsxfun(@minus, data, ops.mimg1);
    
    nSlices = nt0*floor(size(data,3)/nt0);
    if nSlices~=size(data,3)
        data = data(:,:, 1:nSlices);
    end
    
    % bin data
    data = reshape(data, Ly, Lx, nt0, []);
    davg = squeeze(mean(data,3));
    
    mov(:,:,ix + (1:size(davg,3))) = davg(ops.yrange, ops.xrange, :);
    
    ix = ix + size(davg,3);
    ij = ij + 1;
end
ops.mimg1 = ops.mimg1 / size(mov,3);
fclose(fid);

mov = mov(:, :, 1:ix);

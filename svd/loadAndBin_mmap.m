% needs ops.RegFile, ops.xrange, ops.yrange, ops.NavgFramesSVD
% Ly, Lx are the size of each frame. nimgbatch: the number of frames loaded per batch
% nt0 is the number of timepoints to bin over. If a sixth argument is
% present, it does not subtract the mean of each batch. 
function [mov,ops] = loadAndBin_mmap(ops, Ly, Lx, nimgbatch, nt0, clustModel)

bytesPerSamp = 2;
ix = 0;
file_idx = 1;

%NB had to flip xrange and yrange order because permuting xy later
mov = zeros(numel(ops.xrange), numel(ops.yrange), ops.NavgFramesSVD, 'single');

ij = 0;
%NB had to flip Lx and Ly order because permuting xy later
ops.mimg1 = zeros(Lx,Ly,'single');

map = memmapfile(ops.fsroot{file_idx}.name,...
    'Offset',2*bytesPerSamp,...
    'Format',{'uint16',[ops.Lx,ops.Ly,ops.nplanes,ops.Nframes(file_idx)],'frames'});
batch = 1:nimgbatch;
frames_read = 0;
totframes = 0;

while 1
    % Load batch of frames (exclude any that go beyond nFramesTot)
    frames2read = batch+frames_read;
    frames2read(frames2read>ops.Nframes(file_idx)) = [];
    data = squeeze(map.Data.frames(:,:,ops.iplane,frames2read));
    frames_read = frames_read + numel(frames2read);
    
    % If loaded all frames from this movie
    if isempty(frames2read)
        file_idx = file_idx+1;
        
        % Map next movie and import frame batches
        if file_idx <= numel(ops.fsroot)
            
            map = memmapfile(ops.fsroot{file_idx}.name,...
                'Offset',2*bytesPerSamp,...
                'Format',{'uint16',[ops.Lx,ops.Ly,ops.nplanes,ops.Nframes(file_idx)],'frames'});
            batch = 1:nimgbatch;
            frames_read = 0;
            
            frames2read = batch+frames_read;
            frames2read(frames2read>ops.Nframes(file_idx)) = [];
            data = squeeze(map.Data.frames(:,:,ops.iplane,frames2read));
            frames_read = frames_read + numel(frames2read);
            
            if isempty(frames2read)
                break;
            end
        else
            break;
        end
    end
    
    % Process imported data
    data = single(data);
    ops.mimg1 = ops.mimg1 + sum(data,3);
    totframes = totframes + size(data,3);
    
    % ignore bad frames
    badi = ops.badframes(ix + [1:size(data,3)]);
    data(:,:, badi==1) = [];
    
    % subtract off the mean of this batch
    if nargin<=5
        data = bsxfun(@minus, data, mean(data,3));
    end
    %     data = bsxfun(@minus, data, ops.mimg1);
    
    nSlices = nt0*floor(size(data,3)/nt0);
    if nSlices~=size(data,3)
        data = data(:,:,1:nSlices);
    end
    
    % bin data
    data = reshape(data, Ly, Lx, nt0, []);
    davg = squeeze(mean(data,3));
    
    mov(:,:,ix + (1:size(davg,3))) = davg(ops.xrange, ops.yrange, :); %NB had to flip xrange and yrange order because permuting xy later
    
    ix = ix + size(davg,3);
    ij = ij + 1;
end
clear map

% Permute dimensions post import
ops.mimg1 = permute(ops.mimg1 / totframes,[2 1]);
mov = permute(mov(:, :, 1:ix),[2 1 3]);

% computes cell and neuropil fluorescence for surround model of neuropil
function [ops, stat, Fcell, FcellNeu] = extractSignalsSurroundNeuropil2_mmap(ops, stat)

Nk       = numel(stat); % all ROIs

Ny = numel(ops.yrange);
Nx = numel(ops.xrange);

stat = getNonOverlapROIs(stat, Ny, Nx);

[Ly, Lx] = size(ops.mimg1);

% create cell masks and cell exclusion areas
[stat, cellPix, cellMasks] = createCellMasks(stat, Ny, Nx);

% create surround neuropil masks
[ops, neuropMasks] = createNeuropilMasks(ops, stat, cellPix);

% add surround neuropil masks to stat
for k = 1:Nk
    stat(k).ipix_neuropil = find(squeeze(neuropMasks(k,:,:))>0);
end

%%
radius0 = 2; % cells you choose
[stat, ~, ~] = createCenterSurroundMasks2(ops, stat, Ny, Nx, 1, radius0);

%%
% convert masks to sparse matrices for fast multiplication
neuropMasks = permute(neuropMasks,[1 3 2]); % HD permute masks, not movie for speed
cellMasks = permute(cellMasks,[1 3 2]); % HD permute masks, not movie for speed

neuropMasks = sparse(double(neuropMasks(:,:))); 
cellMasks   = sparse(double(cellMasks(:,:)));

%% get fluorescence and surround neuropil
nimgbatch = 2000;
bytesPerSamp = 2;
ix = 0;
fclose all;
file_idx = 1;

map = memmapfile(ops.fsroot{file_idx}.name,...
    'Offset',2*bytesPerSamp,...
    'Format',{'uint16',[ops.Lx,ops.Ly,ops.nplanes,ops.Nframes(file_idx)],'frames'});
batch = 1:nimgbatch;
frames_read = 0;

tic
F = NaN(Nk, sum(ops.Nframes), 'single');
Fneu = NaN(Nk, sum(ops.Nframes), 'single');

ops.mimg1 = zeros(Ly,Lx,'single');
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

    ops.mimg1 = ops.mimg1 + sum(data,3);  
 
    NT   = size(data,3);
    data = reshape(data(ops.xrange,ops.yrange,:), [], NT);
    data = double(data);
    
    % compute cell fluorescence
    % each mask is weighted by lam (SUM TO 1)
    F(:,ix + (1:NT)) = cellMasks * data;
    
    % compute neuropil fluorescence
    Fneu(:,ix + (1:NT)) = neuropMasks * data;
    
    ix = ix + NT;
    if rem(ix, 3*NT)==0
        fprintf('Frame %d done in time %2.2f \n', ix, toc)
    end
end

%%
% get activity stats
[stat, F, Fneu] = getActivityStats_HD(ops, stat, F, Fneu);

%
csumNframes = [0 cumsum(ops.Nframes)];
Fcell       = cell(1, length(ops.Nframes));
FcellNeu    = cell(1, length(ops.Nframes));
for i = 1:length(ops.Nframes)
    Fcell{i}     = F(:, csumNframes(i) + (1:ops.Nframes(i)));
    FcellNeu{i}  = Fneu(:, csumNframes(i) + (1:ops.Nframes(i)));
end
ops.mimg1 = ops.mimg1 / sum(ops.Nframes);
ops.mimg1 = permute(ops.mimg1,[2 1]);

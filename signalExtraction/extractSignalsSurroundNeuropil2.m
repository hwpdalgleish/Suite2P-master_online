% computes cell and neuropil fluorescence for surround model of neuropil
function [ops, stat, Fcell, FcellNeu] = extractSignalsSurroundNeuropil2(ops, stat)

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
[stat, centerMasks, surroundMasks] = ...
    createCenterSurroundMasks2(ops, stat, Ny, Nx, 1, radius0);

ivcell = [stat.radius]>=radius0;
Nkv = sum(ivcell);
centerMasks = centerMasks(ivcell, :);
surroundMasks = surroundMasks(ivcell, :);
%%
% convert masks to sparse matrices for fast multiplication
neuropMasks = sparse(double(neuropMasks(:,:)));
cellMasks   = sparse(double(cellMasks(:,:)));
centerMasks = sparse(double(centerMasks(:,:)));
surroundMasks   = sparse(double(surroundMasks(:,:)));

%% get fluorescence and surround neuropil
nimgbatch = 2000;
ix = 0;
fclose all;
file_idx = 1;
fid = fopen(ops.fsroot{file_idx}.name, 'r');
fread(fid,2+((ops.iplane-1)*Lx*Ly),'uint16');

tic
F = NaN(Nk, sum(ops.Nframes), 'single');
Fneu = NaN(Nk, sum(ops.Nframes), 'single');
cF = NaN(Nkv, sum(ops.Nframes), 'single');
sF = NaN(Nkv, sum(ops.Nframes), 'single');

ops.mimg1 = zeros(Ly,Lx,'single');
frames_read = 0;
while 1
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

    ops.mimg1 = ops.mimg1 + sum(data,3);  
    data = data(ops.yrange, ops.xrange, :);
 
    NT   = size(data,3);
    data = reshape(data, [], NT);
    data = double(data);
    
    % process the data
    %data = my_conv2(data, ops.sig, [1 2]);
    
    % compute cell fluorescence
    % each mask is weighted by lam (SUM TO 1)
    F(:,ix + (1:NT)) = cellMasks * data;
    
    % compute neuropil fluorescence
    Fneu(:,ix + (1:NT)) = neuropMasks * data;
    
    % compute neuropil fluorescence
    cF(:,ix + (1:NT)) = centerMasks * data;
    sF(:,ix + (1:NT)) = surroundMasks * data;
    
    ix = ix + NT;
    if rem(ix, 3*NT)==0
        fprintf('Frame %d done in time %2.2f \n', ix, toc)
    end
end
fclose(fid);

%% get z drift
if getOr(ops, 'getZdrift', 0)
    cFt = my_conv2(cF,.5, 2);
    sFt = my_conv2(sF,.5, 2);
    
    cFt = ordfilt2(cFt,1, true(1,100),[], 'symmetric');
    sFt = ordfilt2(sFt,1, true(1,100),[], 'symmetric');
    
    ratCS = log(max(1e-4,cFt )) - log(max(1e-4,sFt));
    ratCS = zscore(ratCS, 1, 2);
    
    [u, s, v] = svdecon(ratCS);
    
    ops.zdrift = v(:,1);
    
    figure(10)
    plot(v(:,1))
    hold all
end
%%
% keyboard;

% get activity stats
[stat, F, Fneu] = getActivityStats(ops, stat, F, Fneu);

%
csumNframes = [0 cumsum(ops.Nframes)];
Fcell       = cell(1, length(ops.Nframes));
FcellNeu    = cell(1, length(ops.Nframes));
for i = 1:length(ops.Nframes)
    Fcell{i}     = F(:, csumNframes(i) + (1:ops.Nframes(i)));
    FcellNeu{i}  = Fneu(:, csumNframes(i) + (1:ops.Nframes(i)));
end
ops.mimg1 = ops.mimg1 / sum(ops.Nframes);

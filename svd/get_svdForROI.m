% compute SVD and project onto normalized data
% save if ops.writeSVDroi
function [ops, U, model, U2] = get_svdForROI(ops, clustModel)

% iplane = ops.iplane;
U = []; Sv = []; V = []; Fs = []; sdmov = [];

%%%% HD 20180717
%[Ly, Lx] = size(ops.mimg1);
Lx = ops.Lx;
Ly = ops.Ly;
%%%%

ntotframes          = ceil(sum(ops.Nframes));
% number of frames to use for SVD
ops.NavgFramesSVD   = min(ops.NavgFramesSVD, ntotframes);
% size of binning (in time)
nt0 = ceil(ntotframes / ops.NavgFramesSVD);


ops.NavgFramesSVD = floor(ntotframes/nt0);
nimgbatch = nt0 * floor(2000/nt0);

[mov,ops] = loadAndBin_mmap(ops, Ly, Lx, nimgbatch, nt0);
if ops.photostim == 1
    z = reshape(mov,size(mov,1)*size(mov,2),size(mov,3));
    mz = max([0 diff(mean(z,1))],0);
    sz = max([0 diff(std(z,[],1))],0);
    sz(sz<0) = 0;
    vals = [sz' mz'];
    figure;
    g = kmeans(vals,2);
    gscatter(sz,mz,g)
    mean_vals = [];
    for i = 1:2
        mean_vals(i) = mean(reshape(vals(g==i,:),[],1));
    end
    [~,idx] = max(mean_vals);
    toRemove = find(g==idx);
    figure
    subplot(2,1,1)
    plot(mz)
    subplot(2,1,2)
    mz(toRemove) = nan;
    plot(mz)
    
    mov(:,:,toRemove) = [];
end
mov0 = mov; % HD - added to avoid having to load in again later

%% SVD options
if nargin==1 || ~strcmp(clustModel, 'CNMF')
    ops.nSVDforROI = min(ops.nSVDforROI, size(mov,3));
    
    % smooth spatially to get high SNR SVD components
    if ops.sig>0.05
        for i = 1:size(mov,3)
            I = mov(:,:,i);
            I = my_conv2(I, ops.sig, [1 2]); %my_conv(my_conv(I',ops.sig)', ops.sig);
            mov(:,:,i) = I;
        end
    end
    
    mov             = reshape(mov, [], size(mov,3));
    % compute noise variance across frames (assumes slow signal)
    if 1
        sdmov           = mean(diff(mov, 1, 2).^2, 2).^.5;
    else
        sdmov           = mean(mov.^2,2).^.5;
    end
    sdmov           = reshape(sdmov, numel(ops.yrange), numel(ops.xrange));
    sdmov           = max(1e-10, sdmov);
    ops.sdmov       = sdmov;
    
    % smooth the variance over space
    %     sdmov           = my_conv2(sdmov.^2, ops.diameter, [1 2]).^.5;
    
    % normalize pixels by noise variance
    mov             = bsxfun(@rdivide, mov, sdmov(:));
    model.sdmov     = sdmov;
    
    % compute covariance of frames
    if ops.useGPU
        COV             = gpuBlockXtX(mov)/size(mov,1);
    else
        COV             = mov' * mov/size(mov,1);
    end
    ops.nSVDforROI = min(size(COV,1)-2, ops.nSVDforROI);
    
    % compute SVD of covariance matrix
    if ops.useGPU && size(COV,1)<1.2e4
        [V, Sv, ~]      = svd(gpuArray(double(COV)));
        V               = single(V(:, 1:ops.nSVDforROI));
        Sv              = single(diag(Sv));
        Sv              = Sv(1:ops.nSVDforROI);
        %
        Sv = gather(Sv);
        V = gather(V);
    else
        [V, Sv]         = eigs(double(COV), ops.nSVDforROI);
        Sv              = single(diag(Sv));
    end
    

    if ops.useGPU
        U               = gpuBlockXY(mov, V);
    else
        U               = mov * V;
    end
    U               = single(U);    
    % reshape U to frame size
    U = reshape(U, numel(ops.yrange), numel(ops.xrange), []);

    % compute spatial masks (U = mov * V)
    %mov = loadAndBin(ops, Ly, Lx, nimgbatch, nt0); HD removed, replaced with line below
    mov             = mov0;
    mov             = reshape(mov, [], size(mov,3));
    
    if ops.useGPU
        U2               = gpuBlockXY(mov, V);
    else
        U2               = mov * V;
    end
    U2               = single(U2);    
    % reshape U to frame size
    U2 = reshape(U2, numel(ops.yrange), numel(ops.xrange), []);

    % write SVDs to disk
    if ~exist(ops.ResultsSavePath, 'dir')
        mkdir(ops.ResultsSavePath);
    end
end

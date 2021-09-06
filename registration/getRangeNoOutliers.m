function ops1 = getRangeNoOutliers(ops, ops1)

for i = 1:numel(ops1)
    if ops.nonrigid
        ops = ops1{i};
        ops.CorrFrame = nanmean(ops.CorrFrame(:,:),2);
        badi = getOutliers(ops);
        %         ops1{i}.badframes = false(sum(ops1{i}.Nframes), 1);
        
        ops1{i}.badframes(badi) = true;
        
        ds = ops1{i}.DS(~ops1{i}.badframes,:,:);
        
        maxDsY = max(reshape(ds(:,1,1:ops.numBlocks(1)), [], 1));
        minDsY = min(reshape(ds(:,1,end-ops.numBlocks(1)+1:end), [], 1));
        maxDsX = max(reshape(ds(:,2,1:ops.numBlocks(1):end), [], 1));
        minDsX = min(reshape(ds(:,2,ops.numBlocks(1):ops.numBlocks(1):end), [], 1));
        if ops.BiDiPhase>0
            maxDsX = max(1+ops.BiDiPhase, maxDsX);
        elseif ops.BiDiPhase<0
            minDsX = min(ops.BiDiPhase, minDsX);
        end
        ops1{i}.yrange = ceil(1 + maxDsY) : floor(ops1{i}.Ly+minDsY);
        ops1{i}.xrange = ceil(1 + maxDsX) : floor(ops1{i}.Lx+minDsX);
        
        
        mimg = zeros(size(ops1{i}.mimg1));
        for ib = 1:prod(ops.numBlocks)
            mimg(ops1{i}.yBL{ib}, ops1{i}.xBL{ib}) = ops1{i}.mimgB{ib};
        end
        ops1{i}.mimg = mimg;
        
    else
        if size(ops1{i}.DS,3) > 1
            % determine bad frames
            ops2 = ops1{i};
            ops2.CorrFrame(~ops2.usedPlanes) = NaN;
            ops2.CorrFrame = nanmean(ops2.CorrFrame,2);
            badi = getOutliers(ops2);
            ops1{i}.badframes(badi) = true;
            
            ind = repmat(~ops1{i}.badframes',1,2,nplanes) & ...
                repmat(permute(ops1{i}.usedPlanes, [1 3 2]),1,2,1);
            ds = ops1{i}.DS;
            ds = ds(ind); % [time x [x,y] x nplanes]
            ds = reshape(permute(ds, [1 3 2]), [], 2);
        else
            % determine bad frames
            badi                    = getOutliers(ops1{i});
            ops1{i}.badframes(badi) = true;
            ds = ops1{i}.DS(~ops1{i}.badframes,:);
        end
        
        minDs = min(ds, [], 1);
        maxDs = max(ds, [], 1);
        disp([minDs(1) maxDs(1) minDs(2) maxDs(2)])
        if ops.BiDiPhase>0
            maxDs(2) = max(1+ops.BiDiPhase, maxDs(2));
        elseif ops.BiDiPhase<0
            minDs(2) = min(ops.BiDiPhase, minDs(2));
        end
        ops1{i}.yrange = ceil(1 + maxDs(1)) : floor(ops1{i}.Ly+minDs(1));
        ops1{i}.xrange = ceil(1 + maxDs(2)) : floor(ops1{i}.Lx+minDs(2));
    end
end

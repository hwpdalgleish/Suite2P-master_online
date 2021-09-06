function  run_pipeline_online(db, ops0)

ops0.splitROIs                      = getOr(ops0, {'splitROIs'}, 1);
ops0.LoadRegMean                    = getOr(ops0, {'LoadRegMean'}, 0);
ops0.getROIs                        = getOr(ops0, {'getROIs'}, 1);   % whether to run the optimization
ops0.getSVDcomps                    = getOr(ops0, {'getSVDcomps'}, 0);   % whether to save SVD components to disk for later processing

ops0                                = build_ops3(db, ops0);
if ~isfield(ops0, 'diameter') || isempty(ops0.diameter)
    warning('you have not specified mean diameter of your ROIs')
    warning('for best performance, please set db(iexp).diameter for each experiment')
end
ops0.diameter                        = getOr(ops0, 'diameter', 8*ops0.zoom);
ops0.clustrules.diameter             = ops0.diameter;
ops0.clustrules                      = get_clustrules(ops0.clustrules);

%% Setup ops1 (HD)
clear ops1
for p = 1:ops0.nplanes
    ops1{p}.fsroot = ops0.fsroot;
    ops1{p}.badframes = [];
    for m = 1:numel(ops0.fsroot)
        if ops0.nplanes == 1
            [x,y,f] = nFramesBin(ops0.fsroot{m}.name);
            ops1{p}.Nframes(m) = floor(f/10)*10;
            ops1{p}.NframesTot(m) = ops1{p}.Nframes(m);
        else
            [x,y,f] = nFramesBin(ops0.fsroot{m}.name);
            ops1{p}.Nframes(m) = floor(f/ops0.nplanes);
            ops1{p}.NframesTot(m) = ops1{p}.Nframes(m) * ops0.nplanes;
        end
        
        % flag bad frames (i.e. photostim artifacts etc.)
        corrFileName = strrep(ops0.fsroot{m}.name,'.bin','_corr.bin');
        if exist(corrFileName,'file') == 2
            corr = load_corr(corrFileName);
            badi = getOutliers_HD(corr(1:ops1{p}.Nframes(m)),ops0.nplanes);
            bf = false(1,sum(ops1{p}.Nframes(m)));
            bf(badi) = true;
            ops1{p}.badframes = [ops1{p}.badframes bf];
        else
            ops1{p}.badframes = [ops1{p}.badframes false(1,ops1{p}.Nframes(m))];
        end
    end
    ops1{p}.badframes = logical(ops1{p}.badframes);
    ops1{p}.Lx = x;
    ops1{p}.Ly = y;
    ops1{p}.xrange = [11:x-10];
    ops1{p}.yrange = [11:y-10];
    %ops1{p}.badframes = false(1,sum(ops1{p}.Nframes));
    ops1{p}.mimg = zeros(y,x,'single');
    ops1{p}.mimg1 = zeros(y,x,'single');
end

%%
parfor i = 1:numel(ops1)
    ops         = ops1{i};    

    % check if settings are different between ops and ops0
    % ops0 settings are chosen over ops settings
    ops         = opsChanges(ops, ops0);    
    
    ops.iplane  = i;
    
    fprintf(['- Processing plane ' num2str(ops.iplane) '\n'])
    
    if numel(ops.yrange)<10 || numel(ops.xrange)<10
        warning('valid range after registration very small, continuing to next plane')
        continue;
    end
    
    if getOr(ops, {'getSVDcomps'}, 0)
        % extract and write to disk SVD comps (raw data)
        ops    = get_svdcomps(ops);
    end
            
    if ops.getROIs
        % get sources in stat, and clustering images in res
        [ops, stat, model]           = sourcery(ops);

        %figure(10); clf;

        % extract dF
        switch getOr(ops, 'signalExtraction', 'surround')
            case 'raw'
                [ops, stat, Fcell, FcellNeu] = extractSignalsNoOverlaps(ops, model, stat);
            case 'regression'
                [ops, stat, Fcell, FcellNeu] = extractSignals(ops, model, stat);
            case 'surround'
                %[ops, stat, Fcell, FcellNeu] = extractSignalsSurroundNeuropil2(ops, stat);
                [ops, stat, Fcell, FcellNeu] = extractSignalsSurroundNeuropil2_mmap(ops, stat);
        end
        
        % apply user-specific clustrules to infer stat.iscell
        stat = classifyROI(stat, ops.clustrules);
        
        if ~exist(ops.ResultsSavePath,'dir')
            mkdir(ops.ResultsSavePath);
        end
        
%%%%%%%%%%%%%%% Commented out to allow parallel processing %%%%%%%%%%%%%%%%
%         save(sprintf('%s/F_%s_%s_plane%d.mat', ops.ResultsSavePath, ops.mouse_name, ops.date, ops.iplane), ...
%             'ops',  'stat',...
%             'Fcell', 'FcellNeu', '-v7.3')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        s2p_parsave(ops,stat,Fcell,FcellNeu)
    end

    fclose('all');
end

% clean up
fclose all;

function s2p_parsave(ops,stat,Fcell,FcellNeu)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

save(sprintf('%s/F_%s_%s_plane%d.mat', ops.ResultsSavePath, ops.mouse_name, ops.date, ops.iplane), ...
            'ops',  'stat',...
            'Fcell', 'FcellNeu', '-v7.3')

end


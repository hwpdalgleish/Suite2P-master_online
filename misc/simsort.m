function [sorted_array,conv_sorted_array,isort,iclustup] = simsort(array,nC,varargin)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

if ~isempty(varargin)
    sig_cells = varargin{1};
else
    sig_cells = round(size(array,1)/200);
end
useGPU = 1; % set this to 1 if you have an Nvidia GPU set up in Matlab

%% 
S = zscore(array, 1, 2);
[NN, NT] = size(S);

if useGPU
    S = gpuArray(single(S));
end

% the top PC is used to initialize the ordering
[U, ~,~] = svdecon(S); % svdecon is contained in the repository
U        = U(:,1); 
[~, isort] = sort(U(:,1)); 

% run the embedding
[iclustup, isort] = embed1D(S, nC, isort, useGPU); % 

%%  this cell plots the cells sorted by the ordering and smoothed over cells
Sm = S;
Sm = Sm(isort, :);

if useGPU
    Sm = gpuArray(Sm);
end

sorted_array = Sm;
conv_sorted_array = my_conv2(Sm, sig_cells, 1); 


end


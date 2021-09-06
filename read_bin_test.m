%%

nFrames = 3000;
iplane = 2;
nPlanes = 4;
Lx = 512;
Ly = 512;

data = zeros(Ly,Lx,nFrames,'uint16');
precision = [num2str(Ly*Lx) '*uint16'];
skip = 2*Ly*Lx*(nPlanes-1);

fname = 'E:\Data\Henry\20180705\20180705_L494_t-006.bin';
fid = fopen(fname);
fread(fid,2,'uint16');

tic
fread(fid,(iplane-1)*Lx*Ly,'uint16');
for i = 1:nFrames
    temp = fread(fid,[Ly,Lx],precision,skip);
    data(:,:,i) = permute(temp, [2 1 3]);
end
toc

%%
fname = 'E:\Data\Henry\20180705\20180705_L494_t-006.bin';
fid = fopen(fname);
fread(fid,2,'uint16');

tic;
temp = fread(fid,Ly*Lx*nFrames*nPlanes,'uint16');
temp = reshape(temp, Lx, Ly, []);
data = permute(temp, [2 1 3]);
data = data(:,:,1:nPlanes:end);
toc

%%
nPlanes = 4;
Lx = 512;
Ly = 512;

figure
for iPlane = 1
    fname = 'E:\Data\Henry\20180705\20180705_L494_t-006.bin';
    fid = fopen(fname);
    fread(fid,2,'uint16');
    
    [data] = read_bin(fid,Lx,Ly,nFrames,iPlane,nPlanes);
    subplot(1,nPlanes,iPlane)
    imshow(mean(data,3),[])
end
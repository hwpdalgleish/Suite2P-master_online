function badi = getOutliers_HD(Corr,nPlanes)

nSDbadregCorr   = 5;
nTbadregWindow  = round(30/nPlanes);
smoothWind      = round(10/nPlanes);

ind = isnan(Corr);
x = 1:length(Corr);
vq = interp1(x(~ind),Corr(~ind),x(ind),'pchip');
Corr(ind) = vq;

mCorr = medfilt1(Corr, nTbadregWindow);
lCorr = movmean(log(max(1e-6, Corr)) - log(max(1e-6, mCorr)),smoothWind);
temp_dist = lCorr;
temp_dist(temp_dist<-prctile(lCorr(lCorr>0),99)) = [];
sd = std(temp_dist);
badi = find(lCorr < -nSDbadregCorr*sd);

end


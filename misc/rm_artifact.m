function [badi,thold,model] = rm_artifact(mov,imageRate)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here


numPx = size(mov,1);
inc = round(numPx/(numPx*0.005));

[y,x,f] = size(mov);
mov = reshape(mov,y*x,[]);
z = mov(1:inc:end,:);
m = mean(z,2);
c = corr(z,m(:));
mCorr = medfilt1(c,round(imageRate)*10);
c = c - mCorr;

model = fitgmdist(c(:),2);
x = [-1:0.01:1]';
pdf = model.pdf(x);
mu = model.mu;
region = x>min(mu) & x<max(mu);
pdf(~region) = nan;
[~,thold] = min(pdf);
thold = x(thold);

if min(model.pdf(mu) > model.pdf(thold)) == 1
    badi = c < thold;
else
    badi = false(1,f);
end

if 0
    figure
    subplot(2,2,1)
    plot(c)
    ylim([-1 1])
    
    subplot(2,2,2)
    temp = c;
    temp(badi) = nan;
    plot(temp);
    ylim([-1 1])
    
    subplot(2,2,3)
    histogram(c,'Normalization','Probability')
    hold on
    line(thold*[1 1],get(gca,'YLim'),'Color',[1 0 0])
    xlim([-1 1])
    
    subplot(2,2,4)
    plot(x,model.pdf(x))
    hold on
    line(thold*[1 1],get(gca,'YLim'),'Color',[1 0 0])
    line(mu(1)*[1 1],get(gca,'YLim'),'Color',[1 0 0])
    line(mu(2)*[1 1],get(gca,'YLim'),'Color',[1 0 0])
    xlim([-1 1])
end

end


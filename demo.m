%	This is a demo for GFEMR.
%	Gaussian Field Estimator with Manifold Regularization for Retinal Image Registration
%	https://authors.elsevier.com/c/1YDGYbZX4vg-J
%	Authors:	Jiahao
%	Date:       06/14/2018

clear; close all;
rand('state', 1);
addpath('./SURF/Utilities');
addpath('./SURF/OpenSURF_version1c');
addpath('./functions');

%% Parameters
iter_num = 1;   %iter number of deterministic annealing
anneal = 0.93;  %annealing rate
sigma0 = 0.3;   %sigma_0
N0 = 15;        %for fast implementation. N0<<N
is_grad = 1;
beta = 0.01;
lambda1 = 0.1;
lambda2 = 0.1;
threshold=0.01; %threshold to remove outliers
normalize = 1;  %normalize X (coordinates of feature points in I1) and Y (in I2)
normal.xm=0; normal.ym=0;
normal.xscale=1; normal.yscale=1;

%% load images
I1=imread('110_a.png');
I2=imread('110_b.png');
scale=1/4;
if size(I1,1)>1000
   I1 = imresize(I1,scale);
   I2 = imresize(I2,scale);
end

%% SURF-PIIFD (Get X and Y)
% [Reference: Gang Wang 2015 BSPC]
p1=[]; p2=[];
Options.upright=true;
Options.tresh=0.00001;
Ipts1=OpenSurf(I1,Options);
Ipts2=OpenSurf(I2,Options);
for iss=1:length(Ipts1)
    p1s=[Ipts1((iss)).x ,Ipts1((iss)).y];
    p1=[p1;p1s];
end
for iss=1:length(Ipts2)
    p2s=[Ipts2((iss)).x ,Ipts2((iss)).y];
    p2=[p2;p2s];
end
p1=round(p1);
p2=round(p2);

% Pre-processing
if size(I1,3)>1
    Im1=I1(:,:,2);
end
if size(I2,3)>1
    Im2=I2(:,:,2);
end
Im1=im2double(Im1);
Im2=im2double(Im2);
Im1=Im1/max(Im1(:));
Im2=Im2/max(Im2(:));
Im1 = Im1*255;
Im2 = Im2*255;

% Remove boundry's points
[msk1,msk2] = rr_msk(Im1,Im2,20);
p1 = rr_removeboundarypoint(p1,msk1,2);
p2 = rr_removeboundarypoint(p2,msk2,2);
cols1 = p1(:,1);
cols2 = p2(:,1);
rws1 = p1(:,2);
rws2 = p2(:,2);   
match = rr_desmatch(Im1,Im2,cols1,cols2,rws1,rws2);   
x1 = match(:,1:2);
x2 = match(:,5:6);
xa = match(:,1)';
ya = match(:,2)';
xb = (match(:,5)+ size(I1,2))' ;
yb = match(:,6)'; 
X = [xa;ya]';
Y = [xb-size(I1,2);yb]';

figure; clf;
idx = 1:length(xa);
plot_matches(I1, I2, X, Y, idx, idx);

%% GFEMR (Outlier removal)
if normalize, [nX, nY, normal]=norm2(X,Y); end
tic;
nV = GFEMR(nX, nY, beta, lambda1, lambda2, anneal, sigma0, iter_num, N0, is_grad);
toc;
if normalize, V=nV*normal.yscale+repmat(normal.ym,size(X,1),1); end 

% Find inliers
delta=sum((nY-nV).^2,2);
idx=find(delta<threshold);
CorrectIndex=idx;

% Plot matches
figure; clf;
plot_matches(I1, I2, X, Y, idx, CorrectIndex);

%% Registration
imNeedsTrans = I1;%(Transfrom I1)
imBase = I2;%(I2 remains unchanged) 
xyinput_out=X(CorrectIndex,:);
xybase_out=Y(CorrectIndex,:);
tform = cp2tform(xyinput_out,xybase_out,'polynomial',2);
imTransformed = imtransform(imNeedsTrans, tform,'XData',[1 size(imBase,2)], 'YData',[1 size(imBase,1)]);
figure, imshow(imBase*0.5+imTransformed*0.5);

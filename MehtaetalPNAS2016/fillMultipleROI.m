function [ img] = fillMultipleROI(filepath,nROI)
% Interactively fill ROI.

hfig=togglefig('Fill ROI',1); colormap gray;
img=imread(filepath);
h=axes('Parent',hfig);
for idR=1:nROI
   clf;
   imagesc(img); axis equal; axis tight;
   img=roifill();
end

[path, name, ext]=fileparts(filepath);
outfile=[path '/' name '_ROIFilled' ext];
imwrite(img,outfile,'Compression','none');
end


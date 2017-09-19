function [mag, orient]=gradcalc(img,sigma)
% [mag orient]=gradcalc(img,sigma) computes the gradient of the image and returns
% the magnitude and orientation. The gradient is computed using a kernel
% that is a derivative of the Gaussian.
% INPUTS    img: image to be processed.
%           sigma: standard deviation (in pixels) of the gaussian kernel
%           that should be used to filter the image before computing the
%           gradient.
% OUTPUTS  mag: magnitude of the image.
%          orient: Orientation in radian range: [pi to -pi).

% Compute the gaussian filter.
fx=-4*sigma:4*sigma;
[xx yy]=meshgrid(fx);
Gx=exp(-fx.^2/(2*sigma^2));
gaussfilt=Gx'*Gx;
% Normalize so that image energy is preserved.
gaussfilt=gaussfilt./sum(gaussfilt(:)); 

% Sample the derivative of the filter along X and Y.
dergaussx=(-xx/sigma^2).*gaussfilt;
dergaussy=(-yy/sigma^2).*gaussfilt;

%Filter the input image to compute gradients.
Gx=imfilter(img,dergaussx,'symmetric','same');
Gy=imfilter(img,dergaussy,'symmetric','same');

orient=atan2(Gy,Gx);  %We don't care about the 'side' of the arrow during NonMaxSuppression, but atan(Gy/Gx) gives NaNs if Gx is zero.
mag=sqrt(Gx.^2+Gy.^2);

end
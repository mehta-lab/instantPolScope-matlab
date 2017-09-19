function [ scale, theta, cormap]=phasecorlogpolar(imref,imreg,cortype,varargin)
% imregscalerotphasecor Register scaling and rotation between 2-D images
% using phase-correlation.

% [IMREGOUT, SCALE, THETA, CORMAP] = phasecorlogpolar(IMREF, IMREG,
% XAXIS, YAXIS, CORRELATIONTYPE) computes the relative rotation and scaling of IMREG with
% respect to IMREF using phase-correlation of magnitude spectrum 
% in log-polar coordinates. Magnitude specrum of the image does not carry
% information about pure translation. Therefore, this function can be used
% to correct for rotation and scaling irrespective of translation. After
% employing this function, one can correct for translation using the
% standard phase-correlation.
% 
% 
% See also:
% phasecor



  if(~strcmpi(cortype, 'pos') && ....
                ~strcmpi(cortype, 'neg') &&...
                ~strcmpi(cortype, 'dxdy'))
            warning('imregphasecor:wrongcorrelationtype',...
                ['Correlation type must be ''pos'', ''neg'', or ''dxdy'','... 
                'but you supplied ' cortype '; I am defaulting to ''pos''.']);
            cortype='pos';
  end
    
  if(strcmpi(cortype,'neg'))
      cortype='pos';
  end
  
% Magnitude spectrum is the same for an inverted image. But is
% |fx||S(fx,fy)| for df/dx and |fy||S(fx,fy)| for df/dy image.
% If the second image, df/dy, is rotated and scaled, what happens to
% log-polar scale??

specref=fftshift(fft2(ifftshift(imref)));
specreg=fftshift(fft2(ifftshift(imreg)));

%Logarithm boosts typically weak high spatial frequencies 
% and allows more sensitive detection of correlation.
magspecref=abs(specref).^0.5;
magspecreg=abs(specreg).^0.5;

% Compute frequency axes.
m=conjaxis(xaxis,1);
n=conjaxis(yaxis,1);
%figure(3); imagecat(m,n,magspecref,magspecreg,'link','equal','xy');

% The log-polar axes NEED NOT be defined such that unity magnification and the
% zero rotation are at the center of the axis at floor(length/2)+1.
% The support of log-polar axis must be such that the entire magnitude
% spectrum is represented without requiring extrapolation. When interp2 has
% to extrapolate, it uses NaN, which messes up computation of
% phase-correlaiton.

% Sample-step in frequency axis is lower end in the spectrum.
dm=m(2)-m(1);   
logrmin=log2(5*dm); % Avoid the spectrum right near DC, because it is not affected much by scale or rotation.

%Restrict the interpolation axis to slightly smaller than the maximum
%support of the spectrum to eliminate the possibility of extrapolation at
%angles of 0 and pi.
% logrmax=log2(max(m)-2*dm); 

% In microscopic applications, higher spatial frequencies typically are
% noisy.
logrmax=log2(0.5*max(m));

% Square grid seems to be most appropriate.
% logrstep=log2(1.01); % We want to be able to discern magnification differences to 1% change.
% thetastep=0.05; %We want to be able to discern orientation differences of 0.1 degree.

lograxis=linspace(logrmin,logrmax,1001); %The amount of shift along this axis identifies relative scale.
thetaaxis=linspace(-pi,pi,1001);  %The amount of shift along this axis identifies relative rotation.
dlogr=lograxis(2)-lograxis(1); dtheta=thetaaxis(2)-thetaaxis(1);
[logrgrid, thetagrid]=meshgrid(lograxis,thetaaxis);

mmi=(2.^logrgrid).*cos(thetagrid);
nni=(2.^logrgrid).*sin(thetagrid);

[mm, nn]=meshgrid(m,n);

lpmagref=gray2norm(interp2(mm,nn,magspecref,mmi,nni));
lpmagreg=gray2norm(interp2(mm,nn,magspecreg,mmi,nni));
[rshift, theta, cormap]=phasecor(lpmagref,lpmagreg,'pos',[dlogr dtheta]);
scale=2^rshift;


end
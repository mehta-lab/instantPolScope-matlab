function [ theta, cormap]=phasecorpolar(imref,imreg,cortype,varargin)
% imregscalerotphasecor Register scaling and rotation between 2-D images
% using phase-correlation.

% [IMREGOUT, SCALE, THETA, CORMAP] = phasecorlogpolar(IMREF, IMREG, CORRELATIONTYPE, <XAXIS>,<YAXIS>) computes the relative rotation and scaling of IMREG with
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
% If the second image, df/dy, is rotated, what happens to
% polar scale??


specref=fftshift(fft2(ifftshift(imref)));
specreg=fftshift(fft2(ifftshift(imreg)));

%Logarithm boosts typically weak high spatial frequencies 
% and allows more sensitive detection of correlation.
magspecref=abs(specref).^0.5;
magspecreg=abs(specreg).^0.5;

% Compute frequency axes.
m=conjaxis(xaxis,1);
n=conjaxis(yaxis,1);
% Sample-step in frequency axis is lower end in the spectrum.
dm=m(2)-m(1);   
%figure(3); imagecat(m,n,magspecref,magspecreg,'link','equal','xy');
% Skip very low and very high spatial frequencies to avoid NaN in
% interpolation by interp2.
rmin=0.1*max(m);
rmax=0.6*max(m); % Optical images are typically sampled twice than Nyquist.

% Square grid seems to be most appropriate.
% logrstep=log2(1.01); % We want to be able to discern magnification differences to 1% change.
% thetastep=0.05; %We want to be able to discern orientation differences of 0.1 degree.

raxis=linspace(rmin,rmax,1001); %The amount of shift along this axis identifies relative scale.
thetaaxis=linspace(-pi,pi,1001);  %The amount of shift along this axis identifies relative rotation.
dr=raxis(2)-raxis(1); dtheta=thetaaxis(2)-thetaaxis(1);
[rgrid, thetagrid]=meshgrid(raxis,thetaaxis);

mmi=rgrid.*cos(thetagrid);
nni=rgrid.*sin(thetagrid);

[mm, nn]=meshgrid(m,n);

lpmagref=gray2norm(interp2(mm,nn,magspecref,mmi,nni));
lpmagreg=gray2norm(interp2(mm,nn,magspecreg,mmi,nni));
[rshift, theta, cormap]=phasecor(lpmagref,lpmagreg,'pos',[dr dtheta]);


end
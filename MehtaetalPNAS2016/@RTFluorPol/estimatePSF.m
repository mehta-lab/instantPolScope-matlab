function estimatePSF(self,beadsfile,varargin)
% RTFluorpol.estimatePSF(beadImage) uses blind deconvolution of images of beads to estimate the
% microscope PSF.

arg.PropertyGrid=0; %If propertygrid is passed as a handle, update it afer computation.
arg.debug=true;
arg.dynamicRange=28000; %Avoid pixels beyond dynamic range that will be non-linear
arg=parsepropval(arg,varargin{:});

% PSF=estimatePSF(self,beadsfile)
TIFFObj=TIFFStack(beadsfile);
rawbeads=mean(double(TIFFObj(:,:,:)),3);
beadsAvg=self.quadstoPolStack(rawbeads,'computeWhat','Average','deconv',false);


initPSF=ones(size(self.PSF));

% Mask image edges and non-linear pixels.
maskPix=ones(size(beadsAvg));
maskPix([1:15 end-(0:15)],:) = 0;
maskPix(:,[1:15 end-(0:15)]) = 0;
maskPix=maskPix.*double(beadsAvg<arg.dynamicRange); 

Pad=1; % Shrink the PSF by these many pixels and pad it back, so that algorithm can converge on the smallest meaningful size.
constraintFun = @(PSF) padarray(PSF(Pad+1:end-Pad,Pad+1:end-Pad),[Pad Pad]);

[beadsDecon,self.PSF]=deconvblind(beadsAvg,initPSF,15,maskPix);

if(isa(arg.PropertyGrid,'PropertyGrid'))
    arg.PropertyGrid.UpdateFieldsFromBoundItem({'PSF'});
end

if(arg.debug)
    hfig=togglefig('PSF estimation',1);
    colormap hot;
    set(hfig,'Position',[50 50 1000 1000],'color','w','defaultaxesfontsize',15);
    ha=tight_subplot(2,2,0.05,[],[],hfig);
    axes(ha(1));
    imshow(beadsAvg,[]); title('raw'); colorbar;
    axes(ha(2));
    imshow(beadsDecon,[]); title('deconvolved'); colorbar;
    
    axes(ha(3));
    imshow(self.PSF,[]); title('estimated PSF'); colorbar;
    
    axes(ha(4));
    imshow(self.PSF-initPSF,[]); title('estimated PSF - initial PSF'); colorbar;
    
    linkaxes([ha(1) ha(2)]);
    
    linkaxes([ha(3) ha(4)]);
end

end
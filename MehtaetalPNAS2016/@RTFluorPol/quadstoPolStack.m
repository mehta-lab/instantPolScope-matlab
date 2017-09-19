function varargout=quadstoPolStack(self,im,varargin)
% RTFP.QuadstoPolStack(rawstack,parameters);
% This is the main function that allows computation of polstack subject to
% various parameters.


if(~isnumeric(im))
    error('quadstoPolStack: the argument passed as image is not numeric.');
end

arg.anisoQ='anisotropy';
arg.anisoCeiling=1;
arg.SmoothFactor=0;
arg.register=true;
arg.normalize=true; % Skip the normalization or not?
arg.PolCorrection=true; % Apply Pol-Correction (ItoSMatrix) or not.
arg.normalizeExcitation=true;
arg.computeWhat='PolStack';
arg.BGiso=0; %Propogated to ComputeFluorAnisotropy.
% Raw intensities (I0,I45,I90,I135) are affected only by blacklevel and normalization.
% Isotropic background and polarization correction affect only the
% anisotropy, orientation, and average intensity. Particle detection
% requires accurate representation of background to work accurately.
arg.deconv=false; 
arg.interpolation='nearest';
% Deconvolution should only be used for visual reasons.
arg=parsepropval(arg,varargin{:});


% How many time-points in the raw series?
tpoints=size(im,3);

% Instantiate output variables.
switch(arg.computeWhat)
    case 'PolStack' % Entire polstack.
    polstack=zeros(self.quadHeight,self.quadWidth,7,tpoints);
    case 'Channels'
    dummy=zeros(self.quadHeight,self.quadWidth,tpoints);    
    I0Stack=dummy; I45Stack=dummy; I90Stack=dummy; I135Stack=dummy; anisoStack=dummy; orientStack=dummy; avgStack=dummy;
    case 'Average'
    avgStack=zeros(self.quadHeight,self.quadWidth,tpoints); 
    otherwise % Just the average image of four quadrants.
    error('quadstoPolStack: Please specify if you want to compute PolStack, Channels, or Average');
end

    %% Iterate over raw frames, process, and output in desired format.

    for idx=1:tpoints
        
        
        %%%%%%% Get quadrants
        [I0, I45, I90, I135]=RTFluorPol.cropQuads(im(:,:,idx),...
            self.BoundingBox, self.BlackLevel);


        if(arg.register)
            %%%%%% Register quadrants
            if(arg.SmoothFactor)       
            % Lowpass filter if asked.
                fcut=(1/arg.SmoothFactor)*2*micdataParams.objectiveNA/(1E-3*micdataParams.wavelength);
                PixSize=micdataParams.PixSize;
                I0filt=opticalLowpassInterpolation(I0,PixSize,fcut,1);
                I45filt=opticalLowpassInterpolation(I45,PixSize,fcut,1);
                I90filt=opticalLowpassInterpolation(I90,PixSize,fcut,1);
                I135filt=opticalLowpassInterpolation(I135,PixSize,fcut,1);

                I0=I0filt;
                I45=imtransformAffineMat(I45filt,self.tformI45,arg.interpolation,'coordinates','centered');
                I90=imtransformAffineMat(I90filt,self.tformI90,arg.interpolation,'coordinates','centered');
                I135=imtransformAffineMat(I135filt,self.tformI135,arg.interpolation,'coordinates','centered');
                
                % Try median filter when noise is very high.
                 %   PSFsupp=(0.5*1E-3*micdataParams.wavelength)/micdataParams.objectiveNA;
                    %nhood=floor(PSFsupp/micdataParams.PixSize);
                 %   I0=medfilt2(I0);
                 %   I45reg=medfilt2(I45reg);
                 %   I90reg=medfilt2(I90reg);
                 %   I135reg=medfilt2(I135reg);
            else
                I45=imtransformAffineMat(I45,self.tformI45,arg.interpolation,'coordinates','centered');
                I90=imtransformAffineMat(I90,self.tformI90,arg.interpolation,'coordinates','centered');
                I135=imtransformAffineMat(I135,self.tformI135,arg.interpolation,'coordinates','centered');
            end
        end

        %%%%%% Normalize quadrants.
        if(arg.normalize)
        % Include excitation-normalization parameters if necessary.
        
            if(arg.normalizeExcitation)
                normI45=self.NormI45*self.NormI45ex;
                normI90=self.NormI90*self.NormI90ex;
                normI135=self.NormI135*self.NormI135ex;
            else
                normI45=self.NormI45;
                normI90=self.NormI90;
                normI135=self.NormI135; 
            end   

            if(numel(normI45)>1)% If normI45 is bigger than a number, assume the image.
                normFactors={ones(size(normI45)),normI45,normI90,normI135};
            else
                normFactors=[1 normI45 normI90 normI135];
            end
            [I0, I45, I90, I135]=normalizeFluorPol(I0, I45, I90, I135,normFactors);  
        end


        %%%% Deconvolve if asked for and if all of the values in PSF are
        %%%% non-zero. Zero values indicate overly fit PSF that can
        %%%% introduce ringing.
        %PSF can be estiamted using deconvblind using registered beads data. PSF changes only due to NA, wavelength, and sampling.
%         if(arg.deconv && all(self.PSF(:))) 
%             I0=deconvlucy(I0,self.PSF,5);
%             I45=deconvlucy(I45,self.PSF,5);
%             I90=deconvlucy(I90,self.PSF,5);
%             I135=deconvlucy(I135,self.PSF,5);
%         end

        %%% Compute what was asked for.
        switch(arg.computeWhat)
            case {'PolStack','Channels'}
                % Compute anisotropy and azimuth with our without Pol-Correctin
                if(arg.PolCorrection)
                    [orient, aniso, avg]=ComputeFluorAnisotropy(I0,I45,I90,I135,arg.anisoQ,...
                        'ItoSMatrix',self.ItoSMatrix,'anisoCeiling',arg.anisoCeiling,'BGiso',arg.BGiso);
                else
                    [orient, aniso, avg]=ComputeFluorAnisotropy(I0,I45,I90,I135,arg.anisoQ,...
                        'anisoCeiling',arg.anisoCeiling,'BGiso',arg.BGiso);                
                end
                
                if(arg.deconv && all(self.PSF(:)))
                    avg=edgetaper(avg,self.PSF);
                    avg=deconvlucy(avg,self.PSF,5);
                end
                
                if(strcmpi(arg.computeWhat,'PolStack'))
                    polstack(:,:,1,idx)=aniso;
                    polstack(:,:,2,idx)=orient;
                    polstack(:,:,3,idx)=avg;
                    polstack(:,:,4,idx)=I0;
                    polstack(:,:,5,idx)=I135;
                    polstack(:,:,6,idx)=I90;
                    polstack(:,:,7,idx)=I45;   
                    
                else
                    I0Stack(:,:,idx)=I0;
                    I45Stack(:,:,idx)=I45;
                    I90Stack(:,:,idx)=I90;
                    I135Stack(:,:,idx)=I135;
                    anisoStack(:,:,idx)=aniso;
                    orientStack(:,:,idx)=orient;
                    avgStack(:,:,idx)=avg;

                end
                
            case 'Average'
                avg=0.25*(I0+I135+I90+I45);
                if(arg.deconv && all(self.PSF(:))) 
                    avg = edgetaper(avg,PSF);
                    avg=deconvlucy(avg,self.PSF,5);
                end
                avgStack(:,:,idx)=avg;
        end

      
%        switch(outputformat)
%         case 'tiff'
%             RTFluorPol.WritePolStack(outputdir,idx,I0,I45reg,I90reg,I135reg,mag,azim);
% 
%         case 'MM5D'
%             self.WriteMM5D(idx,I0,I45,I90,I135,mag,azim,exportfun);
%             
%        otherwise 
%             error('The outputformat argument must be either ''tiff'' or ''MM5D''');
%        end
%     end
    

    end
    
     %%% Assign output to varargout.
     switch(arg.computeWhat)
         case 'PolStack'
             varargout{1}=polstack;
         case 'Channels'
             varargout{1}=I0Stack;
             varargout{2}=I45Stack;
             varargout{3}=I90Stack;
             varargout{4}=I135Stack;
             varargout{5}=anisoStack;
             varargout{6}=orientStack;
             varargout{7}=avgStack;
         case 'Average'
             varargout{1}=avgStack;
     end
             
end



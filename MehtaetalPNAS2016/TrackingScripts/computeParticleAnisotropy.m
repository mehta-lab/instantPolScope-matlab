function [ orientPart,anisoPart,intPart, I0Part, I45Part, I90Part, I135Part, BGPartFit,diffPart, ratioPart ,I0BG,I45BG,I90BG,I135BG,BGPartaround,NPixBG,NPixPart] =...
    computeParticleAnisotropy(I0,I45,I90,I135,xPart,yPart,nPart,psfSigma,varargin)
% [ orientPart,anisoPart,avgPart ] = computeSpeckleAnisotropy(I0,I45,I90,I135,xPart,yPart,nPart,psfSigma,varargin)
% Compute anisotropy of speckles/particles from image data and locations of
% speckles/particles and spread of the PSF.
% Assume intensities are corrected for blacklevel and normalization.
% subtract isotropic background. apply pol-correction.

arg.ItoSMatrix=[0.5 0.5 0.5 0.5; 1 0 -1 0; 0 1 0 -1];
arg.BGiso=0;
arg.satIntensity=10000;
arg.useAmpFromParticleDetection=false; % Use local amplitude output by particle or speckle detection.
arg.movieInfo=NaN;
arg.onlyAverage=false;
arg.BGPartFactor=1; % adjust BGPart factor so that simulated particle anisotropies decays towards 1. Factor of 0.9 meets this requirement, and also that the requirement that sum intensity over 21 pixels is = theoretical integrated intensity over these pixels.
arg.anisoDiff=false;
arg.anisoRatio=false;
arg.BGaround=false;
arg.debug=false;
arg.status=false;
arg.foregroundMask=false(size(I0)); % Foregroud mask can be regions that mark significant signal.
arg.minSNR=0;
arg.anisoBGFactor=1;
arg=parsepropval(arg,varargin{:});

I0Part=NaN(size(xPart));
I45Part=NaN(size(xPart));
I90Part=NaN(size(xPart));
I135Part=NaN(size(xPart));
BGPartFit=NaN(size(xPart));

if(arg.BGaround)
    I0BG=NaN(size(xPart));
    I45BG=NaN(size(xPart));
    I90BG=NaN(size(xPart));
    I135BG=NaN(size(xPart));
    BGPartaround=NaN(size(xPart));
    NPixBG=NaN(size(xPart)); % sdOrient requires knowledge of what pixels contributed to the background calculation.
else
    I0BG=NaN;
    I45BG=NaN;
    I90BG=NaN;
    I135BG=NaN;
    BGPartaround=NaN;    
    NPixBG=NaN;
end

%%% 1. Assign isotropic background for each particle.
%----------------------------------------
if(isscalar(arg.BGiso)) %If supplied background is constant.
    BGamp=repmat(arg.BGiso,size(xPart));
    BGamp(isnan(xPart))=NaN;
elseif(all( size(arg.BGiso) == size(xPart) ))
    BGamp=arg.BGiso;
end

%%% 2. Obtain average intensities for each detected particle.
%-----------------------------------------------------------
yend=size(I0,1); xend=size(I0,2);

maskradius=round(3*psfSigma)+3;
[maskxx,maskyy]=meshgrid(-maskradius:maskradius);
maskR=sqrt(maskxx.^2+maskyy.^2);
partradius=3*psfSigma*0.72;
PSFmask=maskR<=partradius; % Use 21 pixels instead of 37. That reduces the background by almost the half, but integrated intensity only by 3%.
NPixPart=numel(find(PSFmask));

if(arg.BGaround)
    BGaroundMask=maskR>=partradius+2 & maskR<partradius+4;
end

if(arg.status)
    disp('Computing particle/speckle anisotropy:');
end

% Generate a mask of particle indices to be analyzed.
if(isnan(nPart))
    partmask=~isnan(xPart);
elseif(~isscalar(nPart))
    partmask=false(size(xPart));
    for frameno=1:size(I0,3)
        partmask(1:nPart(frameno),frameno)=true;
    end
elseif( all(size(nPart) == size(xPart)) )
    partmask=nPart;
end

for frameno=1:size(I0,3)
     partindices=find(partmask(:,frameno))';
    I0frame=I0(:,:,frameno);
    I135frame=I135(:,:,frameno);
    I90frame=I90(:,:,frameno);
    I45frame=I45(:,:,frameno);
    
    %% Following are multiple attempts at detecting local background. Fitting of Gaussian in u-track works the best.
%    IavgFrame=0.25*(I0frame+I45frame+I90frame+I135frame);
%     switch(arg.BGiso)
%         case 'LocalBackground'
%              BGmask=true(size(I0)); %Assume all pixels except for border belong to background.
%          
%          % Omit borders when estimating background.
% %          BGmask(1:10,1:end)=false;
% %          BGmask(end-10:end,1:end)=false;
% %          BGmask(1:end,1:10)=false;
% %          BGmask(1:end,end-10:end)=false;
% 
%          
%         for idpart=partindices
%             xcen=xPart(idpart,frameno); ycen=yPart(idpart,frameno);
%             particlemask=sqrt((xx-xcen).^2 + (yy-ycen).^2)<=partradius;
%         % Assuming background for each particle results in significant over-estimation when particles overlap.         
%         %   BGmask=xor(particlemask,sqrt((xx-xcen).^2 + (yy-ycen).^2)<=(partradius+1)); 
%         %   BGPart(idpart,frameno)=mean(IavgFrame(BGmask));            
%             BGmask(particlemask)=false;
%         end
%         
%         
%         % Fit a smooth surface to estimate the background image. Doesn't
%         % work well for high background.
%         xaxis=1:size(I0,2);
%         yaxis=1:size(I0,1);
%         [xgrid,ygrid]=meshgrid(xaxis,yaxis);
%           % Ignore the contributions of points outside of the mask to fitting.
%         xgrid(~BGmask)=NaN;
%         ygrid(~BGmask)=NaN;
%         smoothness=10*partradius;
%         BGframe=single(gridfit(xgrid,ygrid,IavgFrame,xaxis,yaxis,'smoothness',smoothness,'regularizer','springs'));
%     case 'WholeCell'
%           % Use the cellmask and BGmask to estimate the background.
%            BGmask=arg.cellMask; %Assume all pixels except for border belong to background.
%         for idpart=partindices
%             xcen=xPart(idpart,frameno); ycen=yPart(idpart,frameno);
%             particlemask=sqrt((xx-xcen).^2 + (yy-ycen).^2)<=partradius;
%         % Assuming background for each particle results in significant over-estimation when particles overlap.         
%         %   BGmask=xor(particlemask,sqrt((xx-xcen).^2 + (yy-ycen).^2)<=(partradius+1)); 
%         %   BGPart(idpart,frameno)=mean(IavgFrame(BGmask));            
%             BGmask(particlemask)=false;
%         end
%         backgroundPixels=IavgFrame(BGmask);
%         BGiso=quantile(backgroundPixels,0.1);
%         BGframe=single(repmat(BGiso,[size(I0,1) size(I0,2)]));
%     otherwise
%          BGframe=single(repmat(arg.BGiso,[size(I0,1) size(I0,2)]));
%     end
%%
        for idpart=partindices
            xcen=round(xPart(idpart,frameno)); ycen=round(yPart(idpart,frameno));
            particlemask=false([yend xend]);
            
            y1=ycen-maskradius;
            y2=ycen+maskradius;
            x1=xcen-maskradius;
            x2=xcen+maskradius;
            
            if(y1>=1 && x1>=1 && y2<=yend  && x2<=xend)

                particlemask(y1:y2,x1:x2)=PSFmask;

                I0Part(idpart,frameno)=sum(I0frame(particlemask));
                I135Part(idpart,frameno)=sum(I135frame(particlemask));
                I90Part(idpart,frameno)=sum(I90frame(particlemask));
                I45Part(idpart,frameno)=sum(I45frame(particlemask));

                % Sum background over number of pixels in the particle by
                % multiplying particle background with # of pixels.
                BGPartFit(idpart,frameno)=arg.BGPartFactor*BGamp(idpart,frameno)*NPixPart;
            else
                I0Part(idpart,frameno)=NaN;
                I135Part(idpart,frameno)=NaN;
                I90Part(idpart,frameno)=NaN;
                I45Part(idpart,frameno)=NaN;
                BGPartFit(idpart,frameno)=NaN;
            end
            
            if(arg.BGaround)
                   BGmask=false([yend xend]);
                    y1=ycen-maskradius;
                    y2=ycen+maskradius;
                    x1=xcen-maskradius;
                    x2=xcen+maskradius;

                    if(y1>=1 && x1>=1 && y2<=yend  && x2<=xend)

                        BGmask(y1:y2,x1:x2)=BGaroundMask;
                        BGmask=BGmask & ~arg.foregroundMask(:,:,frameno);
                        I0BG(idpart,frameno)=mean(I0frame(BGmask))*NPixPart;
                        I135BG(idpart,frameno)=mean(I135frame(BGmask))*NPixPart;
                        I90BG(idpart,frameno)=mean(I90frame(BGmask))*NPixPart;
                        I45BG(idpart,frameno)=mean(I45frame(BGmask))*NPixPart;
                        NPixBG(idpart,frameno)=numel(find(BGmask));

                        % Sum background over number of pixels in the particle by
                        % multiplying particle background with # of pixels.
                        BGPartaround(idpart,frameno)=mean([ I0BG(idpart,frameno) I135BG(idpart,frameno) I90BG(idpart,frameno) I45BG(idpart,frameno)])*arg.BGPartFactor;
                    else
                        I0Part(idpart,frameno)=NaN;
                        I135Part(idpart,frameno)=NaN;
                        I90Part(idpart,frameno)=NaN;
                        I45Part(idpart,frameno)=NaN;
                        BGPartaround(idpart,frameno)=NaN;
                    end
            
            end
            %% Estimate background from neighboring pixels - may be more appropriate for linear structures.
%             particlemaskplus1=sqrt((xx-xcen).^2 + (yy-ycen).^2)<=partradius+1.5;
%             BGmask=xor(particlemask,particlemaskplus1);
%             BGPix=sort(IavgFrame(BGmask)); % Sort background pixels in ascending order.
%             BGPixUse=BGPix(1:ceil(end/2));
%             BGPartNew(idpart,frameno)=mean(BGPixUse)*numel(find(particlemask));
            % There are 29 pixels in the backgound border. If the structure
            % is linear, half of this can lie on bright region. Therefore,
            % I select only dim ones to 
            % Above numbers should be estimated by fitting an anisotropic
            % gaussian.
            % Using this new background provides clearner results.
            %%
        end
    %textprogressbar(frameno/length(nPart)*100);
        
end


% Do not use particles in which any average intesity is above saturation.

Npix=numel(find(PSFmask)); %Number of pixels used in the sum.
DoNotUse=(I0Part/Npix)>arg.satIntensity | (I45Part/Npix)>arg.satIntensity | (I90Part/Npix)>arg.satIntensity | (I135Part/Npix)>arg.satIntensity;
I0Part(DoNotUse)=NaN;
I45Part(DoNotUse)=NaN;
I90Part(DoNotUse)=NaN;
I135Part(DoNotUse)=NaN;


if(arg.BGaround)
    BGuse=BGPartaround;
else
    BGuse=BGPartFit;
end
% NOTE: Isotropic background to estimate intenisty is BGPart, but used to
% compute anisotropy is 0.5*BGPart. I find that 
% (1) background estimated from surrounding pixels is the same as
% background estimated from Gaussian fit (for GFP).
% (2) Gaussian fit correctly retrieves simulated intensities and background
% under Poisson noise.
% (3) But, the anisotropy or polarization factor for GFP excited with XY, Z, or XYZ polarization
% has peak value of >1, even after particles are selected to be high intensity when background is set to BGPart.
% But, setting background to 0.5*BGPart leads to expected anisotropy
% patterns.
% Since, we are using anisotropy/polarization factor more qualitatively
% than quantitatively, I just avoid running into anisotropy ceiling by
% scaling BGPart only during computation of anisotropy.



% Compute average particle intensity and compare to the total background.
avgPart=0.25*(I0Part+I45Part+I90Part+I135Part);
badSNR=(avgPart./BGuse)<arg.minSNR;
avgPart(badSNR)=NaN;

intPart=avgPart-BGuse;
intPart(intPart<0)=0;
[orientPart,anisoPart]=ComputeFluorAnisotropy(I0Part,I45Part,I90Part,I135Part,'anisotropy','ItoSMatrix',arg.ItoSMatrix,'BGiso',arg.anisoBGFactor*BGuse);

if(arg.anisoDiff)
   [~,diffPart,~]=ComputeFluorAnisotropy(I0Part,I45Part,I90Part,I135Part,'difference','ItoSMatrix',arg.ItoSMatrix,'BGiso',arg.anisoBGFactor*BGuse);
else
    diffPart=NaN;
end

if(arg.anisoRatio)
   [~,ratioPart,~]=ComputeFluorAnisotropy(I0Part,I45Part,I90Part,I135Part,'ratio','ItoSMatrix',arg.ItoSMatrix,'BGiso',arg.anisoBGFactor*BGuse);
else
    ratioPart=NaN;
end

if(arg.debug)
    togglefig('debug: particle anisotropy');
    useParts=~isnan(intPart);
    subplot(131);
    hist(orientPart(useParts),100);
    title('orientation');
    
    subplot(132);
    hist(intPart(useParts),100);
    title('intensity');
    
    subplot(133);
    hist(anisoPart(useParts),100);
    title('anisotropy');
end

if(arg.status)
    disp('done');
end
end


 function analyzeParticles(self,I0,I45,I90,I135,savefile,varargin)
 % RTFPObj.analyzeParticles(I0,I45,I90,I135,savefile,varargin)
 %nPart: number of detected particles at each time point.
% Aiming for these Steps in the algorithm:
% Detect particles in average channel: using high density compatible
% algorithm such as DAOSTORM.
% Determine the radiometric balance of particles in each channel by fitting
% only the amplitudes of anisotropic gaussian at detected centers. 

arg.psfSigma = (0.2*self.Wavelength/self.ObjectiveNA)/self.PixSize;
arg.backgroundAverage=300;
arg.backgroundSD=100;
arg.alphaLocalMaxima=0.02;
arg.tempdir=[tempdir '/ParticleDetection/'];
arg.diagnosis=false;
arg.detectionType='load'; %True runs the particle detection, false reads already detected particles and computes the stastistics.
arg.BGiso=0;%'local';
arg.singleMolecule=true;
arg.satIntensity=10000;
arg.Parent=NaN; % Parent canvas on which to draw the images. Useful when calibReg is used as a callback within GUI.
%params.regEndCallBack=NaN; % Function to execute after the registration 'ends'. This is used for updating the calling GUI.
 % Temporary diretory for storing results.

arg=parsepropval(arg,varargin{:});

mkdir(arg.tempdir);
 
[saveResults.dir,saveResults.filename,ext]=fileparts(savefile);
saveResults.filename = [saveResults.filename ext]; %name of file where input parameters and output results are saved


detectionType=arg.detectionType;
psfSigma=arg.psfSigma;

switch(detectionType)
    case 'particles'
    %%% Detect particles in the average channel. 
    %------------------------------------------

    % Export files as needed by u-track

    Iavg=0.25*(I0+I45+I90+I135);
    delete([arg.tempdir '*.tif']);
    
    for frameno=1:size(Iavg,3)    
        Ithis=uint16(Iavg(:,:,frameno));
        imwrite(Ithis,[arg.tempdir 'avg' num2str(frameno,'%04u') '.tif']);
    end

    
    % prepare movie and detection parameters for u-track package.
    % movieParam structure for detection algorithm
    movieParam.imageDir =arg.tempdir; %directory where to save input and output
    movieParam.filenameBase = 'avg'; %image file name base
    movieParam.digits4Enum = 4; %number of digits used for frame enumeration (1-4).
    movieParam.firstImageNum=1;
    movieParam.lastImageNum=size(I0,3);
    
    %Camera bit-depth
    detectionParam.bitDepth = 14;

    %The standard deviation of the point spread function is defined
    %as 0.21*(emission wavelength)/(numerical aperture). If the wavelength is
    %given in nanometers, this will be in nanometers. To convert to pixels,
    %divide by the pixel side length (which should also be in nanometers).
    detectionParam.psfSigma =psfSigma;

    %Number of frames before and after a frame for time averaging
    detectionParam.integWindow = 0;

    %Alpha-value for initial detection of local maxima
    detectionParam.alphaLocMax = arg.alphaLocalMaxima; %Controls how many particles are detected.
    % Higher value means dimmer particles are also counted.

    %Maximum number of iterations for PSF sigma estimation for detected local
    %maxima
    %To use the input sigma without modification, set to 0
    detectionParam.numSigmaIter = 0;

    %1 to attempt to fit more than 1 kernel in a local maximum, 0 to fit only 1
    %kernel per local maximum
    %If psfSigma is < 1 pixel, set doMMF to 0, not 1. There is no point
    %in attempting to fit additional kernels in one local maximum under such
    %low spatial resolution
    
    if(arg.singleMolecule || arg.psfSigma<1.2) 
         detectionParam.doMMF = 0;
    else
        detectionParam.doMMF = 1;
    end

    %Alpha-values for statistical tests in mixture-model fitting step
    detectionParam.testAlpha = struct('alphaR',0.01,'alphaA',0.01,'alphaD',0.01,'alphaF',0);

    %1 to visualize detection results, frame by frame, 0 otherwise. Use 1 only
    %for small movies. In the resulting images, blue dots indicate local
    %maxima, red dots indicate local maxima surviving the mixture-model fitting
    %step, pink dots indicate where red dots overlap with blue dots
    detectionParam.visual = 0;


    %%% run the detection function from u-track, save the results.
    %----------------------------------------------

        disp(['Processing frames: ' int2str(movieParam.firstImageNum) '--' int2str(movieParam.lastImageNum)]);
        [movieInfo]= detectSubResFeatures2D_StandAlone(movieParam,detectionParam,saveResults);

        
    %%% read the results in to reformat information in a consistent format.
    %-----------------------------------------------
     %load([saveResults.dir '/' saveResults.filename]);

    % Creat a NaN array large enough to hold amplitudes and coordinates.

        nPart=arrayfun(@(x) size(x.amp,1),movieInfo);
        xPart=NaN(max(nPart),length(nPart));
        yPart=NaN(max(nPart),length(nPart));
        BGspeckle=NaN(max(nPart),length(nPart)); % Local background detected by the particle detector.
        Ispeckle=NaN(max(nPart),length(nPart));
%         intPart=NaN(max(nPart),length(nPart)); % Second coordinate is frame position, First coordinate is the particle number.        
%         intvarPart=NaN(max(nPart),length(nPart));
%         xwidthPart=NaN(max(nPart),length(nPart));
%         ywidthPart=NaN(max(nPart),length(nPart));


        for frameno=movieParam.firstImageNum:movieParam.lastImageNum
            if nPart(frameno) %It can happen that a specific frame has no particles.
                partindices=1:nPart(frameno);

                % the first column of amp,xCoord,yCoord is the mean value of the
                % quantity.

                xPart(partindices,frameno)=movieInfo(frameno).xCoord(partindices,1);
                yPart(partindices,frameno)=movieInfo(frameno).yCoord(partindices,1);
                Ispeckle(partindices,frameno)=movieInfo(frameno).amp(partindices,1)*(2^detectionParam.bitDepth-1);
                BGspeckle(partindices,frameno)=movieInfo(frameno).bgAmp(partindices,1)*(2^detectionParam.bitDepth-1);
%             % Not using following info. at the moment.
%             intPart(partindices,frameno)=movieInfo(frameno).amp(partindices,1)*(2^16-1);
%             intvarPart(partindices,frameno)=movieInfo(frameno).amp(partindices,2)*(2^16-1);
%             xwidthPart(partindices,frameno)=movieInfo(frameno).xCoord(partindices,2);
%             ywidthPart(partindices,frameno)=movieInfo(frameno).yCoord(partindices,2);
            end
        end
        
        %%% add nPart, xPart, yPart to results.
        %---------------------------------------
        save([saveResults.dir '/' saveResults.filename],'nPart','xPart','yPart','detectionType','-append');
        
    case 'speckles'
   
    Iavg=0.25*(I0+I45+I90+I135);
    % Do not subtract isotropic background here-  will interfere with noise model.
    
    GaussRatio=1.7;% Measure of correlation in background noise.
    % Construct noiseParameters vector from noise model and alpha value
    k = fzero(@(x)diff(normcdf([-Inf,x]))-1+arg.alphaLocalMaxima,1);
    backgroundSD=arg.backgroundSD;
    backgroundAverage=arg.backgroundAverage;
        
    noiseParam = [k/GaussRatio backgroundSD 0 backgroundAverage];
    
    if(arg.singleMolecule)
        paramSpeckles=[0 0]; %Only single iteration. 
    else
       paramSpeckles=[2 0.01]; % 2 levels means 3 iterations, at least 1% new speckles need to be found for iterations to continue.
    end

    textprogressbar('Speckle detection:');   
    locMax=zeros(size(Iavg));
    locBG=zeros(size(Iavg));
    for frameno=1:size(Iavg,3)
        currImage = Iavg(:,:,frameno); 
        currBG=NaN(size(Iavg,1),size(Iavg,2));
        currlocMax=NaN(size(Iavg,1),size(Iavg,2));
        
        filtImage=filterGauss2D(currImage,psfSigma);
        [cands,currILdirect] = detectSpeckles(filtImage,noiseParam,paramSpeckles,arg.psfSigma); 
        % locMax and background image maps are useful for detecting
        % immobile particles.
        status=vertcat(cands.status);
        ILmax=vertcat(cands.ILmax);
        IBkg=vertcat(cands.IBkg); %IBkg is higher of the supplied background or true background.
        Lmax=vertcat(cands.Lmax);
        
        locMaxPartCell{frameno}=ILmax(status);
        BGPartCell{frameno}=IBkg(status);
        xPartCell{frameno}=Lmax(status,2);
        yPartCell{frameno}=Lmax(status,1);
        nPart(frameno)=numel(find(status));
        
        Ilocmax=sub2ind([size(Iavg,1) size(Iavg,2)],yPartCell{frameno},xPartCell{frameno});

        currBG(Ilocmax)=BGPartCell{frameno};
        currlocMax(Ilocmax)=locMaxPartCell{frameno};
        locMax(:,:,frameno)=currlocMax;
        locBG(:,:,frameno)=currBG;
       % [yPartCell{frameno},xPartCell{frameno}]=find(trueSpeckleMask);
%        togglefig('debug',1); 
%        h(1)=subplot(211);
%        imagesc(currImage,[arg.backgroundAverage inf]); colormap parula;
%        axis equal; axis tight; hold on; scatter(xPartCell{frameno},yPartCell{frameno},20,'wo');
%        h(2)=subplot(212);
%        imagesc(locBG(:,:,frameno)); axis equal; axis tight;
%        linkaxes(h);
%        pause(0.1);
       textprogressbar(frameno/size(Iavg,3)*100);    
    end
    
     xPart=NaN(max(nPart),length(nPart));
     yPart=NaN(max(nPart),length(nPart));
     Ispeckle=NaN(max(nPart),length(nPart));
     BGspeckle=NaN(max(nPart),length(nPart)); % Local background detected by the speckle detector.
     
      for frameno=1:size(Iavg,3)
          Ispeckle(1:nPart(frameno),frameno)=locMaxPartCell{frameno};
          BGspeckle(1:nPart(frameno),frameno)=BGPartCell{frameno};
          xPart(1:nPart(frameno),frameno)=xPartCell{frameno};
          yPart(1:nPart(frameno),frameno)=yPartCell{frameno};
      end

    save([saveResults.dir '/' saveResults.filename],'nPart','xPart','yPart','locMax','BGspeckle','detectionType','psfSigma','locBG','backgroundSD','backgroundAverage');
    % cands and locMax will be useful for speckle tracking.
    textprogressbar('');    
    case 'computeAnisotropy' % Do nothing. The piece after this switch-case computes anisotropy.
end

%%% Compute average anisotropy and orientation for detected particles.
%-------------------------------------------

load([saveResults.dir '/' saveResults.filename],'nPart','xPart','yPart','psfSigma');

switch(arg.BGiso)
    case 'local'
        [ orientPart,anisoPart,intPart, I0Part, I45Part, I90Part, I135Part, BGPart ] = computeParticleAnisotropy(I0,I45,I90,I135,xPart,yPart,nPart,...
            psfSigma,'BGiso',BGspeckle,'ItoSMatrix',self.ItoSMatrix,'satIntensity',arg.satIntensity); %#ok<NASGU> 
    otherwise
        [ orientPart,anisoPart,intPart, I0Part, I45Part, I90Part, I135Part, BGPart ] = computeParticleAnisotropy(I0,I45,I90,I135,xPart,yPart,nPart,...
            psfSigma,'BGiso',arg.BGiso,'ItoSMatrix',self.ItoSMatrix,'satIntensity',arg.satIntensity); %#ok<NASGU>
end

% Append the anisotropy results to the particle file.
save([saveResults.dir '/' saveResults.filename],'orientPart','anisoPart','intPart','BGPart',...
    'I0Part', 'I45Part', 'I90Part', 'I135Part','-append');
% Note that intPart is background corrected, I(channel)Part are raw total
% intensities.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Diagnosis.
if(arg.diagnosis)
   
    if(isnan(arg.Parent))
       hfigPart=togglefig('Distribution of detected particles'); colormap hot;    
    else
        hfigPart=arg.Parent;
    end
%      barcode of detected quantities.
%     ha=imagecat(1:TimePoints,1:nPart,xPart,yPart,orientPart,anisoPart,intPart,'colorbar','link',hfigPart);
%     cellfun(@(x) set(x,'String','Frame no.'),get(ha,'XLabel'));
%     cellfun(@(x) set(x,'String','Particle no.'),get(ha,'YLabel'));

    %%% Histogram over time of orientation, anisotropy, average value.
    % 
    TimeWin=1;
    TimeAxis=1:numel(nPart)-TimeWin;
    nBins=100;
    ExcludePix=10;
    [orientHist, orientAxis]=histOverTime(TimeWin,orientPart,xPart,yPart,nBins,[0 pi],ExcludePix,size(I0,1),size(I0,2));
    [anisoHist,anisoAxis]=histOverTime(TimeWin,anisoPart,xPart,yPart,nBins,[0 1],ExcludePix,size(I0,1),size(I0,2));
    [intHist,intAxis]=histOverTime(TimeWin,gray2norm(intPart),xPart,yPart,nBins,[0.2 0.8],ExcludePix,size(I0,1),size(I0,2));

    subplot(3,1,1,'Parent',hfigPart);
    imagesc(TimeAxis,(180/pi)*orientAxis,orientHist); xlabel('Frame no'); ylabel('Orientation degree'); colorbar;
    axis xy;
    
    subplot(3,1,2,'Parent',hfigPart);
    imagesc(TimeAxis,anisoAxis,anisoHist); xlabel('Frame no'); ylabel('Anisotropy'); colorbar;
    axis xy;
    
    subplot(3,1,3,'Parent',hfigPart);
    imagesc(TimeAxis,intAxis,intHist); xlabel('Frame no'); ylabel('Intensity'); colorbar;
    axis xy;
    
end
    
end
 
 
 function [HistOverTime,HistAxis]=histOverTime(TimeWin,statOverTime,xcoordMat,ycoordMat,nBins,dataRange,ExcludePix,ImHeight,ImWidth)
 % Compute the histogram over time from particle information.
 nTime=size(xcoordMat,2);
 % How many pixels to exclude from the edge, to avoid
% non-uniform excitation.
XROI=[1+ExcludePix ImWidth-ExcludePix];
YROI=[1+ExcludePix ImHeight-ExcludePix];
spacemask=xcoordMat > XROI(1) & xcoordMat <=XROI(2) & ycoordMat > YROI(1) & ycoordMat < YROI(2);

% Establish the histogram axes.
HistAxis=linspace(dataRange(1),dataRange(2),nBins);
HistOverTime=NaN(nBins,nTime);

for idT=1+TimeWin:nTime-TimeWin
    curramps=statOverTime(:,idT-TimeWin:idT+TimeWin);
    curramps=curramps(spacemask(:,idT-TimeWin:idT+TimeWin));
    HistOverTime(:,idT)=hist(curramps(:),HistAxis)'; % Store the histogram, y is histogram axis, and x is time. The range of X axis is 1:nTime-TimeWin.
end

 end
 
 function [xPart,yPart,ampSpeckle,BGSpeckle,nPart,movieInfo,FGmask]=detectParticles(Iavg,psfSigma,varargin)
 % [xPart,yPart,ampSpeckle,BGSpeckle,nPart,movieInfo,FGmask]=detectParticles(avg,psfSigma,varargin)
 % Do not subtract isotropic background here-  will interfere with noise model.

 % Anisotropic Gaussian fitting can be done using FITANISOGAUSSIAN2D in
 % u-track package.
 

arg.backgroundAverage=300;
arg.backgroundSD=100;
arg.alphaLocalMaxima=0.05;
arg.tempdir=[tempdir filesep datestr(now,'mmddyyHHMMSS') filesep];
arg.diagnosis=false;
arg.detectionType='particlesDirect'; %True runs the particle detection, false reads already detected particles and computes the stastistics.
arg.BGiso=0;%98;%'local';
arg.singleMolecule=true;
arg.satIntensity=10000;
arg.integWindow=0;
arg.RedundancyRadius=3;
arg.Parent=NaN; % Parent canvas on which to draw the images. Useful when calibReg is used as a callback within GUI.
%params.regEndCallBack=NaN; % Function to execute after the registration 'ends'. This is used for updating the calling GUI.
 % Temporary diretory for storing results.

arg=parsepropval(arg,varargin{:});

mkdir(arg.tempdir);

detectionType=arg.detectionType;

switch(detectionType)
    case 'particlesDirect' 
        % Using Frncois Aguet's sub-resolution detection code.
        % It gives the same info as 'particles' code, but is much cleaner
        % and therefore easy to inteprete the amplitude and background
        % values.
        % But, the tracking code requires a movieInfo structure. So the
        % output of this detector is re-formatted to movieInfo
        % architecture.
        disp('----detecting particles---');
        FGmask=false(size(Iavg));
        for iF=1:size(Iavg,3)    % Iterate over frames.
            if(arg.singleMolecule)
                [pstruct(iF), FGmask(:,:,iF)] = pointSourceDetection(Iavg(:,:,iF), psfSigma,'RedundancyRadius',arg.RedundancyRadius,'FitMixtures',false,'alpha',arg.alphaLocalMaxima);
            else
                [pstruct(iF), FGmask(:,:,iF)] = pointSourceDetection(Iavg(:,:,iF), psfSigma,'RedundancyRadius',arg.RedundancyRadius,'FitMixtures',true,'MaxMixtures',5,'alpha',arg.alphaLocalMaxima);
            end
        end
        
        nPart=arrayfun(@(detinfo) length(detinfo.x),pstruct);
        xPart=NaN(max(nPart),length(nPart));
        yPart=NaN(max(nPart),length(nPart));
        BGSpeckle=NaN(max(nPart),length(nPart)); % Local background detected by the particle detector.
        ampSpeckle=NaN(max(nPart),length(nPart));
    for iF=1:size(Iavg,3)
        if nPart(iF) %It can happen that a specific frame has no particles.
            partindices=1:nPart(iF);

            % the first column of amp,xCoord,yCoord is the mean value of the
            % quantity.

            xPart(partindices,iF)=pstruct(iF).x;
            yPart(partindices,iF)=pstruct(iF).y;
            ampSpeckle(partindices,iF)=pstruct(iF).A;
            BGSpeckle(partindices,iF)=pstruct(iF).c;

           movieInfo(iF)=struct('xCoord',[],'yCoord',[],'amp',[],'bgAmp',[]);
            movieInfo(iF).xCoord=[pstruct(iF).x(:) pstruct(iF).x_pstd(:)];
            movieInfo(iF).yCoord=[pstruct(iF).y(:) pstruct(iF).y_pstd(:)];
            movieInfo(iF).amp=[pstruct(iF).A(:)  pstruct(iF).A_pstd(:)];
            movieInfo(iF).bgAmp=[pstruct(iF).c(:) pstruct(iF).c_pstd(:)];
        end
    end
    disp('---done---');
    case 'particles'
    %%% Detect particles in the average channel. 
    %------------------------------------------

    % Export files as needed by u-track

    
    
    for iF=1:size(Iavg,3)    
        Ithis=uint16(Iavg(:,:,iF));
        imwrite(Ithis,[arg.tempdir 'avg' num2str(iF,'%04u') '.tif']);
    end

    
    % prepare movie and detection parameters for u-track package.
    % movieParam structure for detection algorithm
    movieParam.imageDir =arg.tempdir; %directory where to save input and output
    movieParam.filenameBase = 'avg'; %image file name base
    movieParam.digits4Enum = 4; %number of digits used for frame enumeration (1-4).
    movieParam.firstImageNum=1;
    movieParam.lastImageNum=size(Iavg,3);
    
    %Camera bit-depth
    detectionParam.bitDepth = 14;

    %The standard deviation of the point spread function is defined
    %as 0.21*(emission wavelength)/(numerical aperture). If the wavelength is
    %given in nanometers, this will be in nanometers. To convert to pixels,
    %divide by the pixel side length (which should also be in nanometers).
    detectionParam.psfSigma =psfSigma;

    %Number of frames before and after a frame for time averaging
    detectionParam.integWindow = arg.integWindow;

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
    
    if(arg.singleMolecule || psfSigma<1.2) 
         detectionParam.doMMF = 0;
    else
        detectionParam.doMMF = 1;
    end

    %Alpha-values for statistical tests in mixture-model fitting step
    detectionParam.testAlpha = struct('alphaR',arg.alphaLocalMaxima,'alphaA',arg.alphaLocalMaxima,'alphaD',arg.alphaLocalMaxima,'alphaF',0);

    %1 to visualize detection results, frame by frame, 0 otherwise. Use 1 only
    %for small movies. In the resulting images, blue dots indicate local
    %maxima, red dots indicate local maxima surviving the mixture-model fitting
    %step, pink dots indicate where red dots overlap with blue dots
    detectionParam.visual = 0;


    %%% run the detection function from u-track, save the results.
    %----------------------------------------------

        disp(['Processing frames: ' int2str(movieParam.firstImageNum) '--' int2str(movieParam.lastImageNum)]);
        [movieInfo]= detectSubResFeatures2D_StandAlone(movieParam,detectionParam,0);

        
    %%% read the results in to reformat information in a consistent format.
    %-----------------------------------------------
     %load([saveResults.dir '/' saveResults.filename]);

    % Creat a NaN array large enough to hold amplitudes and coordinates.

        nPart=arrayfun(@(x) size(x.amp,1),movieInfo);
        xPart=NaN(max(nPart),length(nPart));
        yPart=NaN(max(nPart),length(nPart));
        BGSpeckle=NaN(max(nPart),length(nPart)); % Local background detected by the particle detector.
        ampSpeckle=NaN(max(nPart),length(nPart));
%         intPart=NaN(max(nPart),length(nPart)); % Second coordinate is frame position, First coordinate is the particle number.        
%         intvarPart=NaN(max(nPart),length(nPart));
%         xwidthPart=NaN(max(nPart),length(nPart));
%         ywidthPart=NaN(max(nPart),length(nPart));


        for iF=movieParam.firstImageNum:movieParam.lastImageNum
            if nPart(iF) %It can happen that a specific frame has no particles.
                partindices=1:nPart(iF);

                % the first column of amp,xCoord,yCoord is the mean value of the
                % quantity.

                xPart(partindices,iF)=movieInfo(iF).xCoord(partindices,1);
                yPart(partindices,iF)=movieInfo(iF).yCoord(partindices,1);
                ampSpeckle(partindices,iF)=movieInfo(iF).amp(partindices,1)*(2^detectionParam.bitDepth-1);
                BGSpeckle(partindices,iF)=movieInfo(iF).bgAmp(partindices,1)*(2^detectionParam.bitDepth-1);
%             % Not using following info. at the moment.
%             intvarPart(partindices,frameno)=movieInfo(frameno).amp(partindices,2)*(2^detectionParam.bitDepth-1);
%             xwidthPart(partindices,frameno)=movieInfo(frameno).xCoord(partindices,2);
%             ywidthPart(partindices,frameno)=movieInfo(frameno).yCoord(partindices,2);
            end
        end
        
    delete([arg.tempdir '*.tif']);
    rmdir(arg.tempdir);
        
    case 'speckles'
   
    
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
    for iF=1:size(Iavg,3)
        currImage = Iavg(:,:,iF); 
        currBG=NaN(size(Iavg,1),size(Iavg,2));
        currlocMax=NaN(size(Iavg,1),size(Iavg,2));
        
        filtImage=filterGauss2D(currImage,psfSigma);
        [cands,currILdirect] = detectSpeckles(filtImage,noiseParam,paramSpeckles,psfSigma); 
        % locMax and background image maps are useful for detecting
        % immobile particles.
        status=vertcat(cands.status);
        ILmax=vertcat(cands.ILmax);
        IBkg=vertcat(cands.IBkg); %IBkg is higher of the supplied background or true background.
        Lmax=vertcat(cands.Lmax);
        
        locMaxPartCell{iF}=ILmax(status);
        BGPartCell{iF}=IBkg(status);
        xPartCell{iF}=Lmax(status,2);
        yPartCell{iF}=Lmax(status,1);
        nPart(iF)=numel(find(status));
        
        Ilocmax=sub2ind([size(Iavg,1) size(Iavg,2)],yPartCell{iF},xPartCell{iF});

        currBG(Ilocmax)=BGPartCell{iF};
        currlocMax(Ilocmax)=locMaxPartCell{iF};
        locMax(:,:,iF)=currlocMax;
        locBG(:,:,iF)=currBG;
       % [yPartCell{frameno},xPartCell{frameno}]=find(trueSpeckleMask);
%        togglefig('debug',1); 
%        h(1)=subplot(211);
%        imagesc(currImage,[arg.backgroundAverage inf]); colormap parula;
%        axis equal; axis tight; hold on; scatter(xPartCell{frameno},yPartCell{frameno},20,'wo');
%        h(2)=subplot(212);
%        imagesc(locBG(:,:,frameno)); axis equal; axis tight;
%        linkaxes(h);
%        pause(0.1);
       textprogressbar(iF/size(Iavg,3)*100);    
    end
    
     xPart=NaN(max(nPart),length(nPart));
     yPart=NaN(max(nPart),length(nPart));
     ampSpeckle=NaN(max(nPart),length(nPart));
     BGSpeckle=NaN(max(nPart),length(nPart)); % Local background detected by the speckle detector.
     
      for iF=1:size(Iavg,3)
          ampSpeckle(1:nPart(iF),iF)=locMaxPartCell{iF};
          BGSpeckle(1:nPart(iF),iF)=BGPartCell{iF};
          xPart(1:nPart(iF),iF)=xPartCell{iF};
          yPart(1:nPart(iF),iF)=yPartCell{iF};
      end

    %save([saveResults.dir '/' saveResults.filename],'nPart','xPart','yPart','locMax','BGspeckle','detectionType','psfSigma','locBG','backgroundSD','backgroundAverage');
    % cands and locMax will be useful for speckle tracking.
    textprogressbar('');    
    movieInfo=NaN;
    case 'computeAnisotropy' % Do nothing. The piece after this switch-case computes anisotropy.
end


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
 
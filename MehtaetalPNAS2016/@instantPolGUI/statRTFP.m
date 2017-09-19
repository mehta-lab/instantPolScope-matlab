function statRTFP(me,varargin)
% statRTFP: Computes statistics and exports them. The data is exported in the .mat file identified in the property grid. 
% Screenshots of ROI and plotted statistics are exported with the same filename but different suffixes.

% Get the parameters.

    filepath=get(me.hStat.nameFile,'String');
    if(~exist(filepath,'file'))
        error(['Data file: ' filepath ' does not exist.']); 
    end
        
    statParams=me.hStat.PGParams.GetPropertyValues();
    procparams=me.hData.PGParams.GetPropertyValues();
    [exportPath,exportFile,~]=fileparts(statParams.ExportToFile);

% Read the data and check parameters.
%-----------------------------------
    dataTIFF=TIFFStack(filepath);
    tPoints=size(dataTIFF,3);
    startframe=statParams.startframe;
    endframe=statParams.endframe;
    if(endframe>tPoints)
        endframe=tPoints;
        me.hStat.PGParams.UpdateFields({'endframe'},{tPoints});
        warning('The endframe exceeds the number of frames in the series and therefore reduced.');
    end
    if(endframe < startframe)
        error('The endframe occurs before the startframe.');
    end    
     nFrames=endframe-startframe+1;
     I=dataTIFF(:,:,startframe:endframe);
     
% Compute Polstack      
     [I0,I45,I90,I135,Anisotropy,Orientation,Average]=me.RTFP.quadstoPolStack(I,...
                'normalizeExcitation',procparams.normalizeExcitation,...
                'BGiso',procparams.BGiso,...
                'computeWhat','Channels');  
            
switch(statParams.SegmentationMethod)
    case 'roi'
        AverageProj=mean(Average,3);
        hAxis=subplot(1,1,1,'Parent',me.hStat.panelImgs);
        imshow(AverageProj,[]);
        title('Select ROI on the time average of frames:');
        hROI=impoly(hAxis);
        dispXLim=get(gca,'XLim');
        dispYLim=get(gca,'YLim');
        setColor(hROI,'magenta');
        roiMask=repmat(hROI.createMask,[1 1 size(Average,3)]);
        % Export snapshot showing the ROI.     
        drawnow;
        screenShotname=[exportPath '/' exportFile '_ROI.png'];
        screencapture(hAxis,[],screenShotname);
        % Generate label matrix that allows visualization of cells.
        roiLabels=zeros(size(Average),'uint8');
        for idF=1:size(Average,3)
            roiLabels(:,:,idF)=bwlabel(roiMask(:,:,idF));
        end
    case 'label stack'
        ext={'*.tif';'*.tiff'};
        [filename,pathname]=uigetfile(ext,'Select TIFF stack with integer labels for segmented ROIs.');
        TIFFObj=TIFFStack([pathname '/' filename]);   
        roiLabels=TIFFObj(:,:,1:nFrames);
end

% Number of ROIs in each frame.
numROI=zeros(1,nFrames);
for idF=1:nFrames
     numROI(idF)=max(max(roiLabels(:,:,idF)));
end


maxRegions=max(numROI);
I0Ensemble=zeros(maxRegions,nFrames);
I45Ensemble=zeros(maxRegions,nFrames);
I90Ensemble=zeros(maxRegions,nFrames);
I135Ensemble=zeros(maxRegions,nFrames);
OrientROI=zeros(maxRegions,nFrames);

% Compute mean intensities over segmented regions.
for idF=1:nFrames % Iterate over frames. 
    I0this=I0(:,:,idF);
    I45this=I45(:,:,idF);
    I90this=I90(:,:,idF);
    I135this=I135(:,:,idF);
    rpthis=regionprops(roiLabels(:,:,idF),'Orientation','PixelIdxList');
    for idR=1:numROI(idF) % Iterate over each segmented region within the frame.
        indices=(rpthis(idR).PixelIdxList);
        I0Ensemble(idR,idF)=mean(I0this(indices));
        I45Ensemble(idR,idF)=mean(I45this(indices));
        I90Ensemble(idR,idF)=mean(I90this(indices));
        I135Ensemble(idR,idF)=mean(I135this(indices));
        OrientROI(idR,idF)=mod(rpthis(idR).Orientation*(pi/180),pi);
    end
end

% Compute ensemble anisotropies.

[OrientEnsemble,AnisoEnsemble,AvgEnsemble]=ComputeFluorAnisotropy(I0Ensemble,I45Ensemble,I90Ensemble,I135Ensemble,'anisotropy','ItoSMatrix',me.RTFP.ItoSMatrix);

if(statParams.EnsembleOrientationRelativeToROI)
% Reference the measured orientation to orientation of the ROI.
    OrientEnsemble=mod(OrientEnsemble-OrientROI,pi);
end
% Export results.

save(statParams.ExportToFile,'filepath','startframe','endframe','roiLabels','numROI','I0Ensemble','I45Ensemble','I90Ensemble','I135Ensemble','OrientEnsemble','AnisoEnsemble','AvgEnsemble','OrientROI');

% % Display results if asked for.
% if(statParams.displayStatistics)
%     hAxis=subplot(1,1,1,'Parent',me.hStat.panelImgs);
% for idF=1:size(Average,3) % Iterate over frames. 
%     imshow(Average(:,:,idF),[]);
%     hold on;
%      for idR=1:numROI(idF);
%     movStats(idF)=getframe(hAxis);
% 
% end

% Display results as curves and export.
h1=subplot(1,3,1,'Parent',me.hStat.panelImgs);
plot(startframe:endframe,OrientEnsemble*(180/pi),'-*','LineWidth',2); xlabel('Frame #'); ylabel('Ensemble Orientation (degree)');

h2=subplot(1,3,2,'Parent',me.hStat.panelImgs);
plot(startframe:endframe,AnisoEnsemble,'-*','LineWidth',2); xlabel('Frame #'); ylabel('Ensemble Anisotropy');

h3=subplot(1,3,3,'Parent',me.hStat.panelImgs);
plot(startframe:endframe,AvgEnsemble,'-*','LineWidth',2); xlabel('Frame #'); ylabel('Mean Intensity');
drawnow;

screenShotname=[exportPath '/' exportFile '_Stats.png'];
drawnow;
screencapture(me.hStat.panelImgs,[],screenShotname);
delete(get(me.hStat.panelImgs,'Children'));
drawnow;

if(statParams.ExportMovieofROIAndHistogram)
    for idF=1:nFrames % Iterate over frames. 
        h(1)=subplot(1,2,1,'Parent',me.hStat.panelImgs);
        aniso=Anisotropy(:,:,idF);
        orient=Orientation(:,:,idF);
        avg=Average(:,:,idF);
        
        % Display average image and ROI over which stats are displayed.
        imshow(avg,[]);
        title('Fluorescence');
        
        hold on;
        mask=(roiLabels(:,:,idF) == statParams.ROIToDisplay);
        maskOrient=regionprops(mask,'Orientation');
        maskOrient=mod((pi/180)*maskOrient.Orientation,pi);
        poly=edge(mask);
        [ypoly,xpoly]=ind2sub(size(poly),find(poly));
        %[xpoly,ypoly]=points2contour(xpoly,ypoly,1,'cw');
        plot(xpoly,ypoly,'.');
        hold off;
        set(gca,'XLim',dispXLim); set(gca,'YLim',dispYLim);
        
        h(2)=subplot(1,2,2,'Parent',me.hStat.panelImgs);
        polarPlotAnisoStat(aniso(mask),orient(mask),avg(mask),'Nbins',36,'PlotType','Polar','ReferenceOrient',maskOrient,...
        'Statistic','PixelOrientation','orientationRelativeToROI',statParams.EnsembleOrientationRelativeToROI);
        title('Orientation (blue: mask orientation, red: ensemble orientation)');
        
        drawnow; pause(0.001);
        if(idF==1)
            snapshot=screencapture(me.hStat.panelImgs);
            snapshot=repmat(snapshot,[1 1 1 nFrames]);
        else
            snapshot(:,:,:,idF)=screencapture(me.hStat.panelImgs);
        end
    
    end
    % Export the movie.
    options.color=true;
    [exportpath,exportname]=fileparts(statParams.ExportToFile);
    saveastiff(snapshot,[exportpath '/' exportname '.tif'],options); 
end
end


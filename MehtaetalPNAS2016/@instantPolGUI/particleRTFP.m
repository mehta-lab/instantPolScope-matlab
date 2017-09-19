function particleRTFP(me,varargin)

        filepath=get(me.hParticle.nameFile,'String');
        if(~exist(filepath,'file'))
            error(['Data file: ' filepath ' does not exist.']); 
        end
        params=me.hParticle.PGParams.GetPropertyValues();
        procparams=me.hData.PGParams.GetPropertyValues();
        
        % Read the data and check parameters.
        %-----------------------------------
        dataTIFF=TIFFStack(filepath);
        
         switch(procparams.dataFormat)    
            % First channel is orientation, second is intensity.
            case 'dual-Orientation+Intensity'
                data=dataTIFF(:,:,:);
                dataOrient=data(:,:,1:2:end);  
                clear data;
                tPoints=0.5*size(dataTIFF,3);

            % In all other cases.
            otherwise 
                dataOrient=dataTIFF(:,:,:);  
                tPoints=size(dataTIFF,3);
         end

 %% Detect or load particles.
        switch(params.ParticleDetection) 
            
            case {'particles','speckles','computeAnisotropy'}
       
                
                %%% Start and end frame.
                if(strcmpi(params.ParticleDetection,'computeAnisotropy'))
                    load(params.ParticleDetectionFile,'startframe','endframe','psfSigma','xPart','yPart','nPart');
                    me.hParticle.PGParams.UpdateFields({'startframe','endframe','psfSigma'},{startframe,endframe,psfSigma});
                    
                else
                    startframe=params.startframe;
                    endframe=params.endframe;
                    psfSigma=params.psfSigma;
                end
                
                
                if(endframe > tPoints)
                    error(['The endframe exceeds the number of frames in the series=' int2str(tPoints)]);
                end

                if(endframe < params.startframe)
                    error('The endframe occurs before the startframe.');
                end
                
                
                %%% Read the necessary data.
                I=dataOrient(:,:,startframe:endframe);
                [I0,I45,I90,I135]=me.RTFP.quadstoPolStack(I,...
                    'normalizeExcitation',procparams.normalizeExcitation,'computeWhat','Channels');
                        % Always analyze particles with anisotropy and ceiling 1.
                        % Do not subtract isotropic background here. Since
                        % it can interfere with noise model.
        
            
                set(me.hParticle.status,'String','Status: Detecting particles/speckles and computing anisotropy, detailed status is displayed in the command window.'); 
                drawnow update;
                % Run particle detection, currently user has to look at
                % command-window to know the status.

                me.RTFP.analyzeParticles(I0,I45,I90,I135,params.ParticleDetectionFile,'detectionType',params.ParticleDetection,'diagnosis',params.diagnosis,'psfSigma',psfSigma,...
                        'Parent',me.hParticle.panelImgs,...
                        'BGiso','local',... % Subtracting isotropic background adjusts the measured anisotropy.
                        'backgroundAverage',params.backgroundAverage,...
                        'backgroundSD',params.backgroundSD,...
                        'alphaLocalMaxima',params.alphaLocalMaxima,...
                        'singleMolecule',params.singleMolecule);  
                   

                 set(me.hParticle.status,'String','Status: particle/speckle detection completed, statistics computed.'); drawnow update;
                 
                 % Above function stores particle informtaion. metadata
                 % about frame# needs to be added.
                 save(params.ParticleDetectionFile,'startframe','endframe','-append');

                %Finally load all the results.
                load(params.ParticleDetectionFile,'startframe','endframe','psfSigma','nPart','xPart','yPart','orientPart','anisoPart','intPart');

            case 'load'

                
                load(params.ParticleDetectionFile,'startframe','endframe','psfSigma','nPart','xPart','yPart','orientPart','anisoPart','intPart');
                me.hParticle.PGParams.UpdateFields({'startframe','endframe','psfSigma'},{startframe,endframe,psfSigma});

                if(params.startframe>startframe) %If the user selected a startframe later than the start frame in particle analysis results.
                    startframe=params.startframe;
                end
                
                if(params.endframe<endframe) %If the user selected an endframe earlier than the end frame in particle analysis results.
                    endframe=params.endframe;
                end
                
                if(endframe<startframe)
                    errordlg('endframe occurs before start frame.');
                end
                % Read the raw data if selecting ROI or drawing particles.
                if(params.selectROI || strcmpi(params.displayAfterAnalysis,'particles'))
                    set(me.hParticle.status,'String','Status: reading raw data.');  
                    drawnow update;                        
                    I=dataOrient(:,:,startframe:endframe);
                end
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Select the ROI and  particles. %%%%%%%%%%%%%%%%%      
     if(params.selectROI);
         
        Iavg=me.RTFP.quadstoPolStack(I,'computeWhat','Average','BGiso',procparams.BGiso);  
        Iavg=mean(Iavg,3);
        % Allow user to draw the ROI.
        delete(get(me.hParticle.panelImgs,'Children'));
        ha=axes('Parent',me.hParticle.panelImgs);
        imshow(Iavg,[],'Parent',ha);
        hROI=impoly();

        % Identify particles inside the ROI. 
        roiXY=hROI.getPosition();
        roiX=roiXY(:,1); roiY=roiXY(:,2);
        useParticles=inpolygon(xPart,yPart,roiX,roiY); 
        % Above selection is implemented inside
        % overlayPositionOrientationV2, but not overlayPositionOrientation.

        % Obtain the orientation of the ROI.
        histMask=poly2mask(roiX,roiY,size(Iavg,2),size(Iavg,1));
        rpMask=regionprops(histMask,'Orientation');
        maskOrient=mod(rpMask.Orientation*(pi/180),pi);
     else
        useParticles=true(size(xPart));
        histMask=false;
        maskOrient=0;
        roiX=NaN;
        roiY=NaN;
     end

     if(~params.orientationRelativeToROI) 
         %If the user is selecting ROI only for spatial selection, reset the maskOrient.
         maskOrient=0;
     end
     
    xPart(~useParticles)=NaN;
    yPart(~useParticles)=NaN;
    anisoPart(~useParticles)=NaN;    
    orientPart(~useParticles)=NaN;    
    intPart(~useParticles)=NaN;    

    % Finally apply frame selection to particles.
    nFrames=endframe-startframe+1;
    xPart=xPart(:,1:nFrames);
    yPart=yPart(:,1:nFrames);
    anisoPart=anisoPart(:,1:nFrames);
    orientPart=orientPart(:,1:nFrames);
    intPart=intPart(:,1:nFrames);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Display after analysis %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        switch(params.displayAfterAnalysis)
            %%%%%%%%%%%%%%% Display histogram.
            case 'histogram'

                [anisoBin,anisoCount,orientBin,orientCount,intBin,intCount]=particleHistograms(anisoPart,orientPart,intPart,...
                    'Parent',me.hParticle.panelImgs,'nBins',params.nBins,'orientBins',params.nBins,...
                    'intensityRange',params.intensityRange,...
                    'anisotropyRange',params.anisotropyRange,...
                    'orientationRange',params.orientationRange,...
                    'excludeAboveOrientation',params.excludeAboveOrientation,...
                    'histogramType',params.histogramType,...
                    'referenceOrientation',maskOrient,...
                    'orientationHistogramType',params.orientationHistogramType);
                
                set(me.hParticle.status,'String','Status: displaying histograms.');  
                drawnow update;  
                
                if(params.exportHistograms);
                    pause(0.1); % Let figures update before screen capture.
                    exportImg=screencapture(me.hParticle.panelImgs);
                    [dir,fname]=fileparts(params.ParticleDetectionFile);
                    tiffname= [dir '/' fname '_' params.histogramType 'hist.tif'];
                    histTable=[dir '/' fname '_' 'histTable.csv'];
                    histROIName=[dir '/' fname '_' 'histROI.tif'];
                    
                    imwrite(exportImg,tiffname);
                    imwrite(histMask,histROIName);
                    t=table(anisoBin(:),anisoCount(:),orientBin(:),orientCount(:),intBin(:),intCount(:));
                    t.Properties.VariableNames={'anisotropy','Nanisotropy','orientation','Norientation','intensity','Nintensity'};
                    writetable(t,histTable);
                    % Also add the mask to the particle file.
                    save(params.ParticleDetectionFile,'histMask','-append');

                end
                    
            %%%%%%%%%%%%%%%%% Display particles.    
            case 'particles'
        
                set(me.hParticle.status,'String','Status: Computing polstack.');  
                drawnow update;    
                        
                % Subtracting BlackLevel is important. BlackLevel is always subtracted by quadstoPolStack using current value.
                polstack=me.RTFP.quadstoPolStack(I,...
                'anisoQ',procparams.anisoQ,...
                'anisoCeiling',procparams.anisoCeiling,...
                'BGiso',procparams.BGiso,...                
                'normalizeExcitation',procparams.normalizeExcitation);
            
            
             set(me.hParticle.status,'String','Status: displaying particles.');     drawnow update;     
             
            % Make an overlay of particles and data.
            if(strcmpi(params.drawParticlesOn,'selectPath'))
                extensions={'*.tif','*.tiff'};
               [filename,pathname,filterIdx]=uigetfile(extensions,'Select the stack to overlay particles on (same size as original dataset).');
               TIFFObjOverlay=TIFFStack([pathname filename]);
               if(length(TIFFObjOverlay.sImageInfo)>1)
                OverlayStack=TIFFObjOverlay(:,:,startframe:endframe);
               else
                  OverlayStack=TIFFObjOverlay(:,:);
                  OverlayStack=repmat(OverlayStack,[1 1 endframe-startframe+1]);
               end
               params.drawParticlesOn=OverlayStack;
            end
            
            movOrient=overlayPositionOrientation(xPart,yPart,anisoPart,orientPart,intPart,polstack,...
                'delay',params.delayBeforeScreenShot,'drawParticlesOn',params.drawParticlesOn,...
                'lineLength',params.lineLength,'glyphDiameter',params.markerSize,...
                'Parent',me.hParticle.panelImgs,'colorMap',procparams.colorMap,'glyphColor',params.glyphColor,...
                     'intensityRange',params.intensityRange,...
                    'anisotropyRange',params.anisotropyRange,...
                    'orientationRange',params.orientationRange,...
                    'excludeAboveOrientation',params.excludeAboveOrientation,...
                    'referenceOrientation',maskOrient,...
                    'roiX',roiX,'roiY',roiY,...
                    'clims',[-inf inf]);
%             % Export if asked.
            if(params.exportMovie)
                [dir,fname]=fileparts(params.ParticleDetectionFile);
%                movname=[dir '/ParticleDetection/' fname '.avi'];
%                frames2movwrite(movOrient,movname,1,1);
                 tiffname= [dir '/' fname '_particles.tif'];
                options.color=true;
                saveastiff(movOrient,tiffname,options);
                % Add mask to the particle file.
                save(params.ParticleDetectionFile,'histMask','-append');
                
            end
            
            case 'nothing'
                % Do nothing. %delete(get(me.hParticle.panelImgs,'Children'));
            case 'exportForTracking'
                 [dir,fname]=fileparts(params.ParticleDetectionFile);
                trackingfile= [dir '/' fname '_tracking.tif'];  
                set(me.hParticle.status,'String',['Exporting:' trackingfile]);     drawnow update;     
                
              
                particlesToHyperStack(anisoPart,orientPart,intPart,xPart,yPart,trackingfile );
        end
        
set(me.hParticle.status,'String','Status: analysis complete.');  
drawnow update;  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

function checkRTFP(me,eventType,I0in,I45in,I90in,I135in,Anisotropyin,Orientationin,Averagein,varargin)

persistent I0 I45 I90 I135 Anisotropy Orientation Average;

% If error occurs in the very first call to the funciton (when file is selected), these persistent
% variables are not set.
% Also when this file is modified. Persistent variables are cleared.
% Choice of file/plotting of images appears to work. Focus on blinking analysis.

switch(eventType)
    %% Store new data in persistent variables.
    case 'newData'
        I0=I0in;
        I45=I45in;
        I90=I90in;
        I135=I135in;
        Anisotropy=Anisotropyin;
        Orientation=Orientationin;
        Average=Averagein;
        
    %% Respond to updates in the frame counters by drawing images or graphs.
    
    case 'frameUpdate'
        delete(get(me.hQuad.panelImgs,'Children'));

        % Get the parameters.
        frame=get(me.hQuad.frameNo,'Value');
        frame=int16(frame);
        
        if(~frame)
            return;
        end
            
        if isfield(me.hQuad,'blinkRange') && ishandle(me.hQuad.blinkRange)
            framerange=get(me.hQuad.blinkRange,'Value');
        else
            framerange=NaN;
        end
        
        % Parameters may be updated in GUI. Get the latest.
        checkParams=me.hData.PGParams.GetPropertyValues();
        if(checkParams.colorCeiling>checkParams.anisoCeiling)
            checkParams.colorCeiling=checkParams.anisoCeiling;
            me.hData.PGParams.UpdateFields({'colorCeiling'},{checkParams.anisoCeiling});
        end        


    % Execute according to chosen analysis type.


    switch(get(me.hQuad.selectAnalysis,'Value'))

        case 1 %'ROI Histogram'


            histFlag=get(me.hQuad.histMolecule,'value');
            if(histFlag) % If molecular histogram is required, ROI needs to be selected.
                set(me.hQuad.analyzeROI,'value',true);
            end    
            
            roiFlag=get(me.hQuad.analyzeROI,'value');
            
            if(histFlag)
                statType='Molecule';
                radialRange=NaN;
            else
                statType='PixelAnisotropy';
                radialRange=[0 1];
            end                

            hROI=interactivePolHist(I0(:,:,frame),I45(:,:,frame),I90(:,:,frame),I135(:,:,frame),...
                Anisotropy(:,:,frame),Orientation(:,:,frame),Average(:,:,frame),...
                'avgCeiling',checkParams.avgCeiling,'anisoCeiling',checkParams.colorCeiling,...
                'Parent',me.hQuad.panelImgs,'analyzeROI',roiFlag,'Statistic',statType,...
                    'orientationRelativeToROI',get(me.hQuad.orientationRelativeToROI,'value'),'showColorbar',false);


        case 2 %'Blinking'


                % Once working, move the drawing of UI components to
                % setupQuickCheckAnalysis so that these handles persist.
                me.hQuad.axesImage=axes('Parent',me.hQuad.panelImgs,'Position',[0.02 0.02 0.45 0.95]);
                me.hQuad.axesRaw=axes('Parent',me.hQuad.panelImgs,'Position',[0.5 0.5 0.42 0.4]);
                me.hQuad.axesComputed=axes('Parent',me.hQuad.panelImgs,'Position',[0.5 0.05 0.42 0.4]);

                maxframes=get(me.hQuad.frameNo,'Max');

                I0blink=NaN(1,maxframes);
                I45blink=NaN(1,maxframes);
                I90blink=NaN(1,maxframes);
                I135blink=NaN(1,maxframes);   
                Anisoblink=NaN(1,maxframes);   
                Orientblink=NaN(1,maxframes);   
                Iblink=NaN(1,maxframes);   

                % Identify the range to analyze.
                startframe=frame-floor(0.5*framerange);
                endframe=frame+floor(0.5*framerange);

                if(startframe<1);
                    startframe=1;
                end

                if(endframe>maxframes)
                    endframe=maxframes;
                end
                
                ImBlink=Average(:,:,frame);
                Ilims=[quantile(ImBlink(:),0.1) quantile(ImBlink(:),0.98)];
                axes(me.hQuad.axesImage);
                im=imagesc(ImBlink,Ilims); 
                axis equal; axis tight;
                hold on;
                

                resultsTable=table();
                currentresult=table();
                % Compute necessary variables and assign a call back for blink
                % analysis to ButtonDownFcn.
                [xx,yy]=meshgrid(1:size(Average,2),1:size(Average,1));
                psfR=round((0.61*me.RTFP.Wavelength/me.RTFP.ObjectiveNA)/me.RTFP.PixSize);
                set(im,'ButtonDownFcn',@doblinkAnalysis,'hittest','on');

    end

end


    

function doblinkAnalysis(src,evt)
    persistent hLine;
    cp=get(me.hQuad.axesImage,'CurrentPoint');
    xcen=round(cp(1,1));
    ycen=round(cp(1,2));
    set(get(me.hQuad.axesImage,'title'),'string',['(x,y)=' num2str([xcen ycen])]);
    
    % Generate mask the size of PSF around chosen point.
    particleMask=sqrt((xx-xcen).^2 + (yy-ycen).^2)<=psfR+0.5;
    [maskY,maskX]=find(particleMask);
    
    if(ishandle(hLine))
        delete(hLine);
    end
    
    hLine=plot(maskX,maskY,'g.');
    

    % Populate the raw intensities with results.
    for frameno=startframe:endframe
        I0frame=I0(:,:,frameno);
        I135frame=I135(:,:,frameno);
        I90frame=I90(:,:,frameno);
        I45frame=I45(:,:,frameno);

        I0blink(frameno)=sum(I0frame(particleMask));
        I45blink(frameno)=sum(I45frame(particleMask));
        I90blink(frameno)=sum(I90frame(particleMask));
        I135blink(frameno)=sum(I135frame(particleMask));
        
    end
    
    % Compute anisotropy, orientation, and intensity accounting for
    % calibration.
    particleBG=numel(maskY)*checkParams.BGiso;
        [Orientblink,Anisoblink,Iblink]=ComputeFluorAnisotropy(...
            I0blink,I45blink,I90blink,I135blink,'anisotropy','BlackLevel',me.RTFP.BlackLevel,...
            'BGiso',particleBG,'anisoCeiling',checkParams.anisoCeiling,...
            'ItoSMatrix',me.RTFP.ItoSMatrix);
        
     % Update the plots.
     axes(me.hQuad.axesRaw);
     plot(1:maxframes,cat(1,I0blink-I90blink,I45blink-I135blink),...,I90blink-particleBG,I135blink-particleBG),...
         'LineWidth',2);
     set(me.hQuad.axesRaw,'xlim',[startframe-1 endframe+1]);
     %legend({'I0','I45','I90','I135'},'Location','NorthEast');
     legend({'I0-I90','I45-I135'},'Location','NorthEast');
     xlabel('frame #');
     
     axes(me.hQuad.axesComputed);
     anisoPlot=100*Anisoblink/checkParams.anisoCeiling;
     orientPlot=(180/pi)*Orientblink;
     
     plot(1:maxframes,cat(1,anisoPlot,orientPlot),'LineWidth',2);
     set(me.hQuad.axesComputed,'xlim',[startframe-1 endframe+1],'ylim',[0 180]);
     legend({'aniso*100','\phi (degree)'},'Location','NorthEast');
     xlabel('frame #');
     
end



end


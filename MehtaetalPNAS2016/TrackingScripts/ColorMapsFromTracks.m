%% 1.  Maps of flow speed, flow direction, and F-actin orientation. 

ccc;
datafiles={'/home/sanguine/dropbox-gmail/Dropbox/RTFluorPol/TrackingScripts/140213 100x15x15 HaCat 250nM beads lad Alexa488 phal 2% ND 10s int 200ms exp 02/140213 100x15x15 HaCat 250nM beads lad Alexa488 phal 2% ND 10s int 200ms exp 02_MMStack.ome.tif',...
    };

calibfiles={'/home/sanguine/dropbox-gmail/Dropbox/RTFluorPol/TrackingScripts/140213cal_SM20150127.RTFP.mat',...
    };

tPlot=[25, 25, 25]; % time point is 250s.
tInterval=10; % Time interval in s.
psfSigma=1.5;
satIntensity=10000; % Saturation intensity.
cameragain=104;

particleFiles=[]; avgFiles=[]; roiFile=[];
for dataIndex=1:numel(datafiles)
    if(exist(datafiles{dataIndex},'file'))
        [pathstr,filename]=fileparts(datafiles{dataIndex});
        datanames{dataIndex}=filename(1:strfind(filename,'_MMStack')-1);
        [topdir,~]=fileparts(pathstr);
        outputdir=[topdir filesep 'analysis/'];
        particleFiles{dataIndex}=[outputdir filename '_particles.mat'];
        avgFiles{dataIndex}=[outputdir filename '_avg.tif'];
        roiFile{dataIndex}=[outputdir filename '_roi.mat'];
        trackfiles{dataIndex}=[outputdir filesep datanames{dataIndex} '_track.mat'];    
        overlaymovie{dataIndex}=[outputdir filesep datanames{dataIndex} '_overlay.tif'];    
    end
end

exportdir='/home/sanguine/dropbox-gmail/Dropbox/datashare/instapolFiguresFeb2016/';

outputdir=['/media/sanguine/backup/shalin/RTFluorPol/Factin/140213 HACAT Cells/' 'analysis/'];

exportsingleframes=true;
exporttimeprojections=true;
exportstats=true;
trackLength=70;
dataIndex=2;
%% 2. Select one ROI per data to exlclude particles outside of cell.
for dataIndex=1:numel(datafiles)
frame=tPlot(dataIndex);
dataTIFF=TIFFStack(datafiles{dataIndex});
data=dataTIFF(:,:,2:50);   
dataTimeProj=mean(data,3);
load(calibfiles{dataIndex});

timeprojIntensity=RTFPCalib.quadstoPolStack(dataTimeProj,'computeWhat','Average','BGiso',0);
     avgdisp=gray2rgb(timeprojIntensity);
 togglefig('select roi for analysis',1);
imagesc(avgdisp);  axis equal; title('select cell');
roiCell=roipoly();
clf;
imagesc(avgdisp);  axis equal; title('select lamellipodium');
roiLamella=roipoly();
save(roiFile{dataIndex},'roiCell','roiLamella');
end


%% Computation of speed and flow.


% Load masks, compute flow.
ROIs=load(roiFile{dataIndex});
load(trackfiles{dataIndex});
Xplot=trackFP.X;
Yplot=trackFP.Y;
orientplot=trackFP.orientPart;

% Resample X-Y coordinates.

[xLamella,yLamella]=mask2curve(ROIs.roiLamella);
[xCell,yCell]=mask2curve(ROIs.roiCell);
partLamella=inpolygon(Xplot,Yplot,xLamella,yLamella) & trackFP.anisoPart<=0.9;
partCell=inpolygon(Xplot,Yplot,xCell,yCell) & trackFP.anisoPart<=0.9;

% linearly interpolate the flow co-ordinates within gaps.
for iT=1:size(Xplot,1)
      particleIdx=trackFP.Particles(iT,:);
      gapFrames=particleIdx==0;
      nogapTimes=find(~gapFrames);
      gapTimes=find(gapFrames);
      Xplot(iT,gapTimes)=interp1(nogapTimes,Xplot(iT,nogapTimes),gapTimes);
      Yplot(iT,gapTimes)=interp1(nogapTimes,Yplot(iT,nogapTimes),gapTimes);
end

speedX=gradient(Xplot)*70/(tInterval); % speed in nm/s
speedY=gradient(Yplot)*70/(tInterval); % speed in nm/s

% Speed estimates at the edge are not reliable. set them to 0.
% for iT=size(speedX,2)
%    speedX(iT,trackFP.Start(iT))=NaN;
%    speedY(iT,trackFP.Start(iT))=NaN;
%    speedX(iT,trackFP.End(iT))=NaN;
%    speedY(iT,trackFP.End(iT))=NaN;
% end

   flowSpeed=sqrt(speedX.^2+speedY.^2);
   flowDirection=mod(atan2(-speedY,speedX),2*pi); % Need to flip Y axis, since it runs from top to bottom in the image.
 %        usePart=trackFP.anisoPart<=0.9;
%        togglefig('lamellipodium orientation relative to local flow',1);
%        histogram((180/pi)*(orientplot(partLamella)-flowDirection(partLamella)));
%        flowDirectionGlobal=mod(atan2(-nanmean(speedY(:)),nanmean(speedX(:))),2*pi);
%        togglefig('lamellipodium orientation relative to global flow',1);
%        histogram((180/pi)*mod(orientplot(partLamella)-flowDirectionGlobal,pi));

    frame=tPlot(dataIndex);
    dataTIFF=TIFFStack(datafiles{dataIndex});
    data=dataTIFF(:,:,frame);    
    
    % Load corresponding calibration.
    load(calibfiles{dataIndex});

    % Convert quadrants into individual registered/normalized/pol-corrected
    % channels.
    [I0,I45,I90,I135,~,~,iAvg]=RTFPCalib.quadstoPolStack(data,'computeWhat','Channels','BGiso',0);
    avgdisp=gray2rgb(imadjust(gray2norm(iAvg),[0.05 0.95]));
    
%% Export figures: single frame.
    if(exportsingleframes)
   % figures single frame.
    
    hfig=togglefig('image',1);
     pos=[1 1 18 15];
      set(hfig,'color','w','defaultaxesfontsize',14,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)]);
    imagesc(avgdisp); axis equal; axis tight; set(gca,'XTick',[],'YTick',[]);
    addscalebar(0.07,1);
%     hold on;
%     plot(xLamella,yLamella,'r','LineWidth',2);
%     plot(xArc,yArc,'b','LineWidth',2);
    
       
           
    tracksToDraw=partCell(:,frame)'; % Identify particles within specific frame and within cells.
    startTracks=frame-trackLength;
    if(startTracks<1)
        startTracks=1;
    end    
    trackX=trackFP.X(tracksToDraw,startTracks:frame)'; % Draw only those tracks that 
    trackY=trackFP.Y(tracksToDraw,startTracks:frame)';
    line (trackX,trackY,'color','y','LineWidth',2);
     export_fig([exportdir datanames{dataIndex} '_Image.png'],'-r600');

    % flow     
    
     hfig=togglefig('flow',1);
     pos=[1 1 18 15];
      set(hfig,'color','w','defaultaxesfontsize',14,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)]);
    imagesc(avgdisp); axis equal; axis tight; set(gca,'XTick',[],'YTick',[]);
    addscalebar(0.07,1);
    hold on;
    speedXDisp=speedX(:,frame);
    speedYDisp=speedY(:,frame);
     SpeedScale=2;
    Flowq=quiver(Xplot(:,frame),Yplot(:,frame),SpeedScale*speedXDisp,SpeedScale*speedYDisp,'filled','g','AutoScale','off','linewidth',1.5,'AutoScaleFactor',0,'MaxHeadSize',0.5,'Clipping','on');
    xlim([1 size(iAvg,2)]); 
    ylim([1 size(iAvg,1)]);
    
    addscalebar(1,SpeedScale*25,'color','g','yloc',min(get(gca,'ylim'))+10,'xloc',35);

    export_fig([exportdir datanames{dataIndex} '_Flow.png'],'-r600');

    
    % orientation
     hfig=togglefig('orientation',1);
     pos=[1 1 15 15];
      set(hfig,'color','w','defaultaxesfontsize',14,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)],'color','w');
    
    overlayPositionOrientationV2(Xplot(:,frame),Yplot(:,frame),trackFP.anisoPart(:,frame),orientplot(:,frame),trackFP.intPart(:,frame),avgdisp,'lineLength',25,'clims',0,'glyphcolor',[1 0.5 1],'anisoScaleLocation',0);
    addscalebar(1,25,'color',[1 0.2 1],'yloc',min(get(gca,'ylim'))+10,'xloc',36);

    export_fig([exportdir datanames{dataIndex} '_Orientation.png'],'-r600');
    
    end

 %% Export figures: projections.

    if(exporttimeprojections)
   
  
%     plot(xLamella,yLamella,'w--','LineWidth',2);
% Encode time.
    timeColor=NaN(size(Xplot));
     for tN=1:size(Xplot,1)
         timeColor(tN,trackFP.Start(tN):trackFP.End(tN))=(0:(trackFP.End(tN)-trackFP.Start(tN)))*tInterval;
     end
     
       hfig=togglefig('image',1);
     pos=[1 1 15 18];
      set(hfig,'color','w','defaultaxesfontsize',14,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)]);
      cmap=parula(128);
     cmap(1,:)=[0 0 0];
     colormap(cmap);
     
    imagesc(zeros(size(avgdisp)),[0 0.7*nanmax(timeColor(:))]); axis equal; axis tight; set(gca,'XTick',[],'YTick',[]);
    addscalebar(0.07,1);
    hold on;
     scatter(Xplot(partCell),Yplot(partCell),6,timeColor(partCell),'filled');
%      plot(xLamella,yLamella,'w:','LineWidth',3); 
     hold off;
     c=colorbar('location','north','color','w');
       c.Position=[0.2    0.68    0.3    0.0382];
     c.Label.String='Track duration (s)';
     c.Label.Color='w';
     c.Label.FontSize=20;
     c.FontSize=20;
% %       print('-dpdf',[exportdir datanames{dataIndex} '_ImageProjection.pdf']);
      export_fig([exportdir datanames{dataIndex} '_ImageProjectionTime.png'],'-r300');
      
      % Encode intensity.
       intColor=trackFP.intPart;
       intColor(trackFP.anisoPart>0.9)=NaN;
      clf;
      imagesc(zeros(size(avgdisp)),[0 0.6*nanmax(intColor(:))]); axis equal; axis tight; set(gca,'XTick',[],'YTick',[]);
      addscalebar(0.07,1);
      hold on;
     scatter(Xplot(partCell),Yplot(partCell),6,intColor(partCell),'filled');
%      plot(xLamella,yLamella,'w:','LineWidth',3); 
     hold off;
     c=colorbar('location','north','color','w');
       c.Position=[0.2    0.68    0.3    0.0382];
     c.Label.String='Intensity';
     c.Label.FontSize=20;
           c.FontSize=20;
     c.Label.Color='w';
     c.Ticks=[];
% %       print('-dpdf',[exportdir datanames{dataIndex} '_ImageProjection.pdf']);
      export_fig([exportdir datanames{dataIndex} '_ImageProjectionIntensity.png'],'-r300');
      
      
      % Encode polarization factor.
     anisoColor=trackFP.anisoPart;
     anisoColor(trackFP.anisoPart>0.9)=NaN;
      clf;
      imagesc(zeros(size(avgdisp)),[0.1 0.9]); axis equal; axis tight; set(gca,'XTick',[],'YTick',[]);
      addscalebar(0.07,1);
      hold on;
     scatter(Xplot(partCell),Yplot(partCell),6,anisoColor(partCell),'filled');
%      plot(xLamella,yLamella,'w:','LineWidth',3); 
     hold off;
     c=colorbar('location','north','color','w');
       c.Position=[0.2    0.68    0.3    0.0382];
     c.Label.String='Polarization factor';
     c.Label.Color='w';
      c.Label.FontSize=20;
      c.FontSize=20;
     c.Ticks=[0.3 0.6 0.9];
     export_fig([exportdir datanames{dataIndex} '_ImageProjectionPolarization.png'],'-r300');

     % Encode speed.
      speedColor=flowSpeed;
     speedColor(trackFP.anisoPart>0.9)=NaN;
      clf;
      imagesc(zeros(size(avgdisp)),[0 15]); axis equal; axis tight; set(gca,'XTick',[],'YTick',[]);
      addscalebar(0.07,1);
      hold on;
     scatter(Xplot(partCell),Yplot(partCell),6,speedColor(partCell),'filled');
%      plot(xLamella,yLamella,'w:','LineWidth',3); 
     hold off;
     c=colorbar('location','north','color','w');
       c.Position=[0.2    0.68    0.3    0.0382];
%      c.Label.String='Flow speed (nm/s)';
     c.Label.Color='w';
      c.Label.FontSize=20;
      c.FontSize=20;

     c.Ticks=[0  5 10 15];
     export_fig([exportdir datanames{dataIndex} '_ImageProjectionSpeed.png'],'-r300');

      %% time projection: flow direction only.
      flowColor=pol2color(ones(size(flowSpeed(partCell))),flowDirection(partCell),ones(size(flowSpeed(partCell))),'hsv','dataType','direction','legend',false);
      flowColor=squeeze(flowColor);
      
          hfig=togglefig('flow',1);
     pos=[1 1 15 18];
      set(hfig,'color','w','defaultaxesfontsize',14,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)]);
     
       imagesc(zeros(size(avgdisp))); axis equal; axis tight; set(gca,'XTick',[],'YTick',[]);
    addscalebar(0.07,1);
    hold on;
     scatter(Xplot(partCell),Yplot(partCell),6,flowColor,'filled');

%      cmap=hsv(128);
%      colormap(cmap);
%      c=colorbar('location','southoutside');
%      c.Label.String='Flow direction (degree)';
% %       print('-dpdf',[exportdir datanames{dataIndex} '_ImageProjection.pdf']);
      export_fig([exportdir datanames{dataIndex} '_FlowProjection.png'],'-r300');
      
       plot(xLamella,yLamella,'w:','LineWidth',3); 
      hold off;
       export_fig([exportdir datanames{dataIndex} '_FlowProjectionwithROI.png'],'-r300');
       
        [~,flowLegend]=pol2color(iAvg,iAvg,iAvg,'hsv','dataType','direction','legend',true,'legendsize',1);
        imwrite(flowLegend,[exportdir datanames{dataIndex} '_FlowLegend.png']);
        
%         %% flow direction and speed.
%        flowColor=pol2color(ones(size(flowSpeed(partCell))),flowDirection(partCell),ones(size(flowSpeed(partCell))),'hsv','dataType','direction','legend',false,'avgCeiling',10);
%       flowColor=squeeze(flowColor);
%       
%           hfig=togglefig('flow direction/speed',1);
%      pos=[1 1 15 18];
%       set(hfig,'color','w','defaultaxesfontsize',14,'renderer','Painters',...
%    'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)]);
%      
%        imagesc(zeros(size(avgdisp))); axis equal; axis tight; set(gca,'XTick',[],'YTick',[]);
%     addscalebar(0.07,1);
%     hold on;
%      scatter(Xplot(partCell),Yplot(partCell),6,flowColor,'filled');
%      plot(xLamella,yLamella,'w:','LineWidth',3); 
%      hold off;
% %      cmap=hsv(128);
% %      colormap(cmap);
% %      c=colorbar('location','southoutside');
% %      c.Label.String='Flow direction (degree)';
% % %       print('-dpdf',[exportdir datanames{dataIndex} '_ImageProjection.pdf']);
%       export_fig([exportdir datanames{dataIndex} '_FlowSpeedProjection.png'],'-r300');
%       
        [~,flowLegend]=pol2color(iAvg,iAvg,iAvg,'hsv','dataType','direction','legend',true,'legendsize',1);
        imwrite(flowLegend,[exportdir datanames{dataIndex} '_FlowLegend.png']);
%                
      %% time projection: orientation.
      
      plotOrients=orientplot(partCell);
        orientColor=pol2color(ones(size(plotOrients)),plotOrients,ones(size(plotOrients)),'sbm','dataType','orientation','legend',false);
      orientColor=squeeze(orientColor);
      
          hfig=togglefig('orientation',1);
     pos=[1 1 15 18];
      set(hfig,'color','w','defaultaxesfontsize',14,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)]);
     
       imagesc(zeros(size(avgdisp))); axis equal; axis tight; set(gca,'XTick',[],'YTick',[]);
    addscalebar(0.07,1);
    hold on;
     scatter(Xplot(partCell),Yplot(partCell),6,orientColor,'filled');
     
%      cmap=hsv(128);
%      colormap(cmap);
%      c=colorbar('location','southoutside');
%      c.Label.String='Flow direction (degree)';
% %       print('-dpdf',[exportdir datanames{dataIndex} '_ImageProjection.pdf']);
      export_fig([exportdir datanames{dataIndex} '_OrientProjection.png'],'-r300');
      
      plot(xLamella,yLamella,'w:','LineWidth',3); 
     hold off;
           export_fig([exportdir datanames{dataIndex} '_OrientProjectionwithROI.png'],'-r300');

        [~,orientLegend]=pol2color(ones(size(iAvg)),ones(size(iAvg)),ones(size(iAvg)),'sbm','dataType','orientation','legend',true,'legendsize',1);
        imwrite(orientLegend,[exportdir datanames{dataIndex} '_OrientLegend.png']);
        
          
    
     dataTIFF=TIFFStack(datafiles{dataIndex});
    data=dataTIFF(:,:,:);    
    data=data(:,:,2:end);
    avgAll=RTFPCalib.quadstoPolStack(data,'computeWhat','Average','BGiso',0);
    avgMax=max(avgAll,[],3);
    
     hfig=togglefig('maxproj',1);
     pos=[1 1 15 18];
      set(hfig,'color','w','defaultaxesfontsize',14,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)]);
    colormap gray;
    
    imagesc(avgMax,[150 1300]); axis equal; axis tight; set(gca,'XTick',[],'YTick',[]);
%        hold on;
%       plot(xLamella,yLamella,'w:','LineWidth',3); 

    addscalebar(0.07,1);
  
%     hold on;
%     trackX=trackFP.X;
%     trackY=trackFP.Y;
%     trackX(~partCell)=NaN;
%     trackY(~partCell)=NaN;
%     line(trackX',trackY','color','g');
%      cmap=hsv(128);
%      colormap(cmap);
%      c=colorbar('location','southoutside');
%      c.Label.String='Flow direction (degree)';
% %       print('-dpdf',[exportdir datanames{dataIndex} '_ImageProjection.pdf']);
      export_fig([exportdir datanames{dataIndex} '_MaxProjection.png'],'-r300');
    end

%% Export figures: statistics.
    if(exportstats)

       %% Statistics: flow speed and polarization factor in lamella.
      hfig=togglefig('speed',1);
        pos=[1 1 15 15];
      set(hfig,'color','w','defaultaxesfontsize',20,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)],'color','w');
     FlowSpeedLamella=sqrt(speedX(partLamella).^2+speedY(partLamella).^2); % flow speed in nm/s
    histogram(FlowSpeedLamella,1:2:20,'normalization','pdf','FaceAlpha',1);
    xlabel('flow speed (nm/s)'); ylabel('frequency');
    export_fig([exportdir datanames{dataIndex} '_SpeedHistogram.png'],'-r300');

     hfig=togglefig('polarization factor',1);
        pos=[1 1 15 15];
      set(hfig,'color','w','defaultaxesfontsize',20,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)],'color','w');
    histogram(trackFP.anisoPart(partLamella),0.1:0.1:0.9,'normalization','pdf','FaceAlpha',1);
    xlabel('polarization factor'); ylabel('frequency');
    export_fig([exportdir datanames{dataIndex} '_PolarizationFactorHistogram.png'],'-r300');
    
    %% Statistics: Flow direction and F-actin orientation in lamella.

        flowLamella=flowDirection(partLamella);
        orientLamella=orientplot(partLamella);
        [~,~,~,~,thetaorient,historient]=polarPlotAnisoStat(ones(size(orientLamella)),orientLamella,ones(size(orientLamella)),'Statistic','ParticleOrientation','Nbins',18);

        meanXLamella=nanmean(cos(flowDirection(partLamella)));
        meanYLamella=nanmean(sin(flowDirection(partLamella)));
        meanflowdirLamella=mod(atan2(meanYLamella,meanXLamella),pi);
        orientRelativePlot=(orientLamella-meanflowdirLamella);
        orientRelativePlot=0.5*atan2(sin(2*orientRelativePlot),cos(2*orientRelativePlot)); % Map between -90 and +90.

        speedXTrack=nansum(speedX,2);
        speedYTrack=nansum(speedY,2);

        speedXTrack=repmat(speedXTrack,[1 size(speedX,2)]);
        speedXTrack(isnan(speedX))=NaN;
        speedYTrack=repmat(speedYTrack,[1 size(speedY,2)]);
        speedYTrack(isnan(speedY))=NaN;

        flowDirTrack=atan2(-speedYTrack,speedXTrack);
        
       hfig=togglefig('flow/orientation polar',1);
         pos=[1 1 15 15];
      set(hfig,'color','w','defaultaxesfontsize',24,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)],'color','w');
%        [thetaArc,histArc]=rose(flowArc,45);
       [thetaflow,histflow]=rose(flowDirTrack(partLamella),36);
       histflow=histflow/max(histflow);
       hflow=polar(thetaflow,histflow);
       set(hflow,'linewidth',1.5,'color',[0 0.7 0]);
       hold on;       
       historient=historient/max(historient);
        horient(1)=polar(thetaorient,historient); hold on; horient(2)=polar(thetaorient+pi,historient);
        set( horient,'linewidth',1.5,'color','m');
%     export_fig([exportdir datanames{dataIndex} '_FlowOrientationLamella.png'],'-r600');
        legend('flow direction','polarization orientation','location','southoutside');
        print('-dpdf',[exportdir datanames{dataIndex} '_FlowOrientationLamellaPolar.pdf']);
        
        
        hfig=togglefig('flow/orientation linear',1);
         pos=[1 1 22 14];
      set(hfig,'color','w','defaultaxesfontsize',24,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)],'color','w');
        hflow=histogram((flowDirTrack(partLamella)-meanflowdirLamella)*(180/pi),-90:5:90,'normalization','pdf','displaystyle','stairs'); hold on;
        horient=histogram(orientRelativePlot*(180/pi),-90:5:90,'normalization','pdf','displaystyle','stairs'); hold off;
        hflow.EdgeColor=[0 0.7 0];
        hflow.LineWidth=6;
        hflow.FaceColor='none';
        horient.EdgeColor='m';
        horient.LineWidth=6; 
        horient.FaceColor='none';
        hl=line([0 0],[0 0.06],'linewidth',4,'color',[0 0.7 0]);
        hl.LineStyle=':';
        xlabel('F-actin orientation relative to flow (degree)'); ylabel('frequency');
        xlim([-90 90]); set(gca,'xtick',-90:30:90);
%         legend('flow','dipole orientation','location','northwest');
        set(gca,'linewidth',2);

        print('-dpdf',[exportdir datanames{dataIndex} '_FlowOrientationLamellaLinear.pdf']);

        %% Statistics: F-actin orientation relative to local flow.
           % Average the speed over the entire track.
        speedXTrack=nansum(speedX,2);
        speedYTrack=nansum(speedY,2);

        speedXTrack=repmat(speedXTrack,[1 size(speedX,2)]);
        speedXTrack(isnan(speedX))=NaN;
        speedYTrack=repmat(speedYTrack,[1 size(speedY,2)]);
        speedYTrack(isnan(speedY))=NaN;
        
        flowDirTrack=atan2(-speedYTrack,speedXTrack);
        

        orientRelativeLocal=orientplot(partLamella)-flowDirTrack(partLamella);
         orientRelativeLocal=0.5*atan2(sin(2*orientRelativeLocal),cos(2*orientRelativeLocal)); % Map between -90 and +90.
        
     
        
        hfig=togglefig('orient relative to local flow',1);
         pos=[1 1 20 10];
      set(hfig,'color','w','defaultaxesfontsize',16,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)],'color','w');
        horient=histogram(orientRelativeLocal(:)*(180/pi),-90:5:90,'displaystyle','stairs','normalization','pdf');
        horient.EdgeColor='k';
        horient.LineWidth=6; 
        horient.FaceColor='none';
        xlabel('F-actin orientation relative to local flow (degree)'); ylabel('frequency');
    xlim([-90 90]); set(gca,'xtick',-90:30:90);
        print('-dpdf',[exportdir datanames{dataIndex} '_orientRelativeToFlowHistogram.pdf']);
        
        
%% Statistics: time-resolved plots highlighting selected tracks.

    

    speedXTrack=nansum(speedX,2);
    speedYTrack=nansum(speedY,2);

    speedXTrack=repmat(speedXTrack,[1 size(speedX,2)]);
    speedXTrack(isnan(speedX))=NaN;
    speedYTrack=repmat(speedYTrack,[1 size(speedY,2)]);
    speedYTrack(isnan(speedY))=NaN;

    flowDirTrack=atan2(-speedYTrack,speedXTrack);
        
    frame=tPlot(dataIndex);
    dataTIFF=TIFFStack(datafiles{dataIndex});
    data=dataTIFF(:,:,frame);    
    
    % Load corresponding calibration.
    load(calibfiles{dataIndex});

    % Convert quadrants into individual registered/normalized/pol-corrected
    % channels.
    [I0,I45,I90,I135,~,~,iAvg]=RTFPCalib.quadstoPolStack(data,'computeWhat','Channels','BGiso',0);
    avgdisp=gray2rgb(imadjust(gray2norm(iAvg),[0.05 0.9]));
    
    tracksToDraw=find(partCell(:,frame)); % Identify particles within specific frame and within cells.
    startTracks=frame-trackLength;
    if(startTracks<1)
        startTracks=1;
    end    
    trackX=trackFP.X(tracksToDraw,startTracks:frame)'; % Draw only those tracks that 
    trackY=trackFP.Y(tracksToDraw,startTracks:frame)';
    
    
    togglefig('select tracks to highlight',1);
    imagesc(avgdisp); axis equal; axis tight; hold on;
    line (trackX,trackY,'color','y','LineWidth',2);
    for iT=tracksToDraw'
        Xstart=trackFP.X(iT,trackFP.Start(iT));
        Ystart=trackFP.Y(iT,trackFP.Start(iT));
        text(Xstart,Ystart,int2str(iT),'color','b','fontsize',10);
    end


 % Image showing selected tracks.
 tracksToHighlight=[264 201 147];
trackmarkers={'s','o','d'};

    hfig=togglefig('time-resolved tracks highlighted',1);
     pos=[1 1 18 15];
      set(hfig,'color','w','defaultaxesfontsize',14,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)]);
    imagesc(avgdisp); axis equal; axis tight; set(gca,'XTick',[],'YTick',[]); 
    hold on;
    addscalebar(0.07,1);
    line (trackX,trackY,'color','g','LineWidth',2);
    
        for iH=1:3
            iT=tracksToHighlight(iH);
            Xstart=trackFP.X(iT,trackFP.Start(iT));
            Ystart=trackFP.Y(iT,trackFP.Start(iT));
            hline=plot(Xstart,Ystart,trackmarkers{iH},'linewidth',5,'markersize',12);
            hline.MarkerFaceColor='y';
            hline.Color='k';
        end
   
     export_fig([exportdir datanames{dataIndex} '_ImageTracksHighlighted.png'],'-r600');
     
    hfig=togglefig('time-resolved tracks plot',1);
     pos=[1 1 21 13];
      set(hfig,'color','w','defaultaxesfontsize',24,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)]);
    imagesc(avgdisp); axis equal; axis tight; set(gca,'XTick',[],'YTick',[]); 
    for iH=1:3
         iT=tracksToHighlight(iH);
        tS=trackFP.Start(iT);
        tE=trackFP.End(iT)-1;
        tAxis=((tS:tE-1)-tS)*tInterval;
        fN=tS:tE-1;
        flowDirThis=flowDirTrack(iT,fN);
        orientThis=orientplot(iT,fN);
        orientRelativeThis=orientThis-flowDirThis;
        orientRelativeThis=0.5*atan2(sin(2*orientRelativeThis),cos(2*orientRelativeThis));
    %     plot(tAxis,flowDirThis*(180/pi),'g',tAxis,orientThis*(180/pi),'m',tAxis,orientRelativeThis*(180/pi),'k');
       hLine=plot(tAxis,orientRelativeThis*(180/pi),trackmarkers{iH},'linewidth',3,'linestyle','-','MarkerSize',12);
          hLine.MarkerFaceColor='y';
            hLine.Color='k';
        hold on;
    end
    hold off;
    ylabel('\phi-\omega (degree)','FontSize',28); 
    xlabel('Track duration (s)');
    ylim([-90 90]); xlim([0 240]);
    set(gca,'ytick',[-90:30:90],'xtick',[0:30:240],'linewidth',2);
    export_fig([exportdir datanames{dataIndex} '_OrientTracksHighlighted.pdf']);   
     
     % flow  showing selected tracks.
    
     hfig=togglefig('flow tracks highlighted',1);
     pos=[1 1 18 15];
      set(hfig,'color','w','defaultaxesfontsize',24,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)]);
    imagesc(avgdisp); axis equal; axis tight; set(gca,'XTick',[],'YTick',[]);
    addscalebar(0.07,1);
    hold on;
    speedXDisp=speedX(:,frame);
    speedYDisp=speedY(:,frame);
     SpeedScale=2;
    Flowq=quiver(Xplot(:,frame),Yplot(:,frame),SpeedScale*speedXDisp,SpeedScale*speedYDisp,'filled','g','AutoScale','off','linewidth',1.5,'AutoScaleFactor',0,'MaxHeadSize',1,'Clipping','on');
    xlim([1 size(iAvg,2)]); 
    ylim([1 size(iAvg,1)]);
    
    addscalebar(1,SpeedScale*25,'color','g','yloc',min(get(gca,'ylim'))+10,'xloc',35);

       for iH=1:3
            iT=tracksToHighlight(iH);
            Xstart=trackFP.X(iT,trackFP.Start(iT));
            Ystart=trackFP.Y(iT,trackFP.Start(iT));
            hline=plot(Xstart,Ystart,trackmarkers{iH},'linewidth',2,'markersize',11);
            hline.MarkerFaceColor='y';
            hline.Color='k';
            trackX=trackFP.X(iT,trackFP.Start(iT):frame)';
            trackY=trackFP.Y(iT,trackFP.Start(iT):frame)';
            plot(trackX,trackY,'w','linewidth',2);
        end

    
    export_fig([exportdir datanames{dataIndex} '_FlowSelectedTracks.png'],'-r600');

    
    % orientation showing selected tracks.
     hfig=togglefig('orientation tracks highlighted',1);
     pos=[1 1 15 15];
      set(hfig,'color','w','defaultaxesfontsize',14,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)],'color','w');
    
    overlayPositionOrientationV2(Xplot(:,frame),Yplot(:,frame),trackFP.anisoPart(:,frame),orientplot(:,frame),trackFP.intPart(:,frame),avgdisp,'lineLength',25,'clims',0,'glyphcolor',[1 0.5 1],'anisoScaleLocation',0);
    addscalebar(1,25,'color',[1 0.2 1],'yloc',min(get(gca,'ylim'))+10,'xloc',36);
    hold on;
   for iH=1:3
            iT=tracksToHighlight(iH);
            Xstart=trackFP.X(iT,trackFP.Start(iT));
            Ystart=trackFP.Y(iT,trackFP.Start(iT));
            hline=plot(Xstart,Ystart,trackmarkers{iH},'linewidth',2,'markersize',11);
            hline.MarkerFaceColor='y';
            hline.Color='k';
            trackX=trackFP.X(iT,trackFP.Start(iT):frame)';
            trackY=trackFP.Y(iT,trackFP.Start(iT):frame)';
            plot(trackX,trackY,'w','linewidth',2);
   end
        
    export_fig([exportdir datanames{dataIndex} '_OrientationSelectedTracks.png'],'-r600');
     
    
    
 %% Compare orientation spread relative to flow orientation spread.
   flowpm10=abs(flowLamella-meanflowdirLamella)<=(pi/18);
   flowpm20=abs(flowLamella-meanflowdirLamella)<=(pi/9);
   flowpm30=abs(flowLamella-meanflowdirLamella)<=(pi/4.5);
    hfig=togglefig('zoned filament orientation',1);
         pos=[1 1 20 10];
      set(hfig,'color','w','defaultaxesfontsize',16,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)],'color','w');
        horient=histogram((orientLamella(flowpm10))*(180/pi),'displaystyle','stairs','normalization','pdf');
        hold on;
        horient=histogram((orientLamella(flowpm20))*(180/pi),'displaystyle','stairs','normalization','pdf');
        horient=histogram((orientLamella(flowpm30))*(180/pi),'displaystyle','stairs','normalization','pdf');
        legend('\pm10','\pm20','\pm30');
                

            %% Compare local vs.  global flow in lamellipodium only.

            
%             orientLamellavsLocalflow=arrayfun(@(orient,flow) orientRelativeToFlow(orient,flow),orientLamella,flowLamella);
%             orientLamellavsGlobalflow=orientLamella-meanflowdirLamella;
%             orientLamellavsGlobalflow=mod(0.5*atan2(sin(2*orientLamellavsGlobalflow),cos(2*orientLamellavsGlobalflow)),pi);
% % 
%             orientLamellavsLocalflow=0.5*mod(atan2(sin(2*orientLamellavsLocalflow),cos(2*orientLamellavsLocalflow)),2*pi);
%             orientLamellavsGlobalflow=0.5*mod(atan2(sin(2*orientLamellavsGlobalflow),cos(2*orientLamellavsGlobalflow)),2*pi);
% %             
%              hfig=togglefig('lamellipodial orientation vs local and global flow',1);
%              subplot(121);
%              hlocal=histogram(orientLamellavsLocalflow*(180/pi),0:5:180,'Normalization','pdf'); hold on;
%              title('Lamellipodium orientation vs local flow');
%              subplot(122);
%             hglobal=histogram(orientLamellavsGlobalflow*(180/pi),0:5:180,'Normalization','pdf');
%              title('Lamellipodium orientation vs global flow');
%              % Convert above linear histograms on radial axis.
%              
               orientLamellavsLocalflowDirect=orientLamella-flowLamella;
               orientLamellavsGlobalflowDirect=orientLamella-meanflowdirLamella;

               hfig=togglefig('direct subtraction: local',1);
               set(hfig,'position',[50 50 1500 750]);
                 subplot(121);
                 histogram(orientLamellavsLocalflowDirect*(180/pi),'Normalization','pdf');
                 title('F-actin orientation vs local flow');
                 
               hpolar=subplot(122);
                 [thetaRelOrient,histRelOrient]=rose(orientLamellavsLocalflowDirect,30);
                histRelOrient=histRelOrient/sum(histRelOrient);
                hRelOrient(1)=polar(thetaRelOrient,histRelOrient);
                hold on;
                hRelOrient(2)=polar(thetaRelOrient+pi,histRelOrient);
                hold off;
                set(hRelOrient,'linewidth',1.5,'color','k');
                title('F-actin orientation vs local flow');
                 export_fig([exportdir datanames{dataIndex} '__OrientRelativeToLocalFlow.pdf'],hpolar);
               
                    hfig=togglefig('direct subtraction: global',1);
                    set(hfig,'position',[50 50 1500 750]);
                       subplot(121);
                 histogram(orientLamellavsGlobalflowDirect*(180/pi),'Normalization','pdf');
                 title('F-actin orientation vs global flow');

                 
               hPolar=subplot(122);
              histogram(orientLamellavsGlobalflowDirect*(180/pi));
                 [thetaRelOrient,histRelOrient]=rose(orientLamellavsGlobalflowDirect,30);
                histRelOrient=histRelOrient/sum(histRelOrient);
                hRelOrient(1)=polar(thetaRelOrient,histRelOrient);
                hold on;
                hRelOrient(2)=polar(thetaRelOrient+pi,histRelOrient);
                hold off;
                set(hRelOrient,'linewidth',1.5,'color','k');
                              title('F-actin orientation vs global flow');
                 export_fig([exportdir datanames{dataIndex} '__OrientRelativeToGlobalFlow.pdf'],hpolar);
                              

             %% Compare acute angle between flow and orientation.
             flowLamellaAngle=flowDirection(~isnan(flowDirection) & ~isnan(orientplot) & partLamella);
             orientAngle=orientplot(~isnan(flowDirection) & ~isnan(orientplot) & partLamella);
             flowXY=cat(2,cos(flowLamellaAngle),sin(flowLamellaAngle));
             orientXY=cat(2,cos(orientAngle),sin(orientAngle));
             flowNorm=sqrt(flowXY(:,1).^2+flowXY(:,2).^2);
             orientNorm=sqrt(orientXY(:,1).^2+orientXY(:,2).^2);
             dotFlowOrient=dot(flowXY,orientXY,2);
             relativeAngle=acos(dotFlowOrient./(flowNorm.*orientNorm));
             togglefig('relative angle');
             histogram(relativeAngle*(180/pi));
    end   



            
%% Movies: raw data, tracks, flow, and orientation in separate panels.
  hfig=togglefig('movie',1);
 

%movietype='all';
movietype='orient';

switch(movietype)
    case 'all'
            pos=[1 1 20 20];
      set(hfig,'color','w','defaultaxesfontsize',14,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)]);
        ha=tight_subplot(2,2,[],[],[],hfig);
    case 'orient'
     pos=[1 1 30 15];
      set(hfig,'color','w','defaultaxesfontsize',14,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)],'color','k');
        ha=tight_subplot(1,2,[],0,0,hfig);
end
    trackLength=70; 

for dataIndex=[1 3]

    
%% Compute stacks.
    load(calibfiles{dataIndex});

    dataTIFF=TIFFStack(datafiles{dataIndex});
    data=dataTIFF(:,:,:);    
    data=data(:,:,2:end);
    [I0,I45,I90,I135,~,~,iAvg]=RTFPCalib.quadstoPolStack(data,'computeWhat','Channels','BGiso',0);
   
    
    %% Compute flow.

    % Load masks, compute flow.
   
    load(trackfiles{dataIndex});
    Xplot=trackFP.X;
    Yplot=trackFP.Y;
    orientplot=trackFP.orientPart;

   
    % linearly interpolate the flow co-ordinates within gaps.
    for iT=1:size(Xplot,1)
          particleIdx=trackFP.Particles(iT,:);
          gapFrames=particleIdx==0;
          nogapTimes=find(~gapFrames);
          gapTimes=find(gapFrames);
          Xplot(iT,gapTimes)=interp1(nogapTimes,Xplot(iT,nogapTimes),gapTimes);
          Yplot(iT,gapTimes)=interp1(nogapTimes,Yplot(iT,nogapTimes),gapTimes);
    end
    
     ROIs=load(roiFile{dataIndex});
    [xCell,yCell]=mask2curve(ROIs.roiCell);
    partCell=inpolygon(Xplot,Yplot,xCell,yCell);

    speedX=gradient(Xplot)*70/(tInterval); % speed in nm/s
    speedY=gradient(Yplot)*70/(tInterval); % speed in nm/s

    flowSpeed=sqrt(speedX.^2+speedY.^2);
    flowDirection=mod(atan2(-speedY,speedX),2*pi); % Need to flip Y axis, since it runs from top to bottom in the image.

    %% Draw frames.
for frame=1:size(data,3)
    % Load corresponding calibration.

    % Convert quadrants into individual registered/normalized/pol-corrected
    % channels.
    avgdisp=gray2rgb(imadjust(gray2norm(iAvg(:,:,frame)),[0.01 0.85]));
    
    switch(movietype)
        case 'all'
            axes(ha(1)); cla;
            imagesc(avgdisp); axis equal; axis tight; set(gca,'XTick',[],'YTick',[]);
            addscalebar(0.07,1);

            axes(ha(2)); cla;
            imagesc(avgdisp); axis equal; axis tight; set(gca,'XTick',[],'YTick',[]);
            addscalebar(0.07,1);

            tracksToDraw=partCell(:,frame)';
            startTracks=frame-trackLength;
            if(startTracks<1)
                startTracks=1;
            end    
            trackX=Xplot(tracksToDraw,startTracks:frame)';
            trackY=Yplot(tracksToDraw,startTracks:frame)';


                if(frame>1)
                line (trackX,trackY,'color','g','LineWidth',2);
                end


            axes(ha(3)); cla;
            imagesc(avgdisp); axis equal; axis tight; set(gca,'XTick',[],'YTick',[]);
            addscalebar(0.07,1);
            hold on;
            speedXDisp=speedX(:,frame);
            speedYDisp=speedY(:,frame);
             SpeedScale=1.5;
            Flowq=quiver(Xplot(:,frame),Yplot(:,frame),SpeedScale*speedXDisp,SpeedScale*speedYDisp,'filled','g','AutoScale','off','linewidth',1.5,'AutoScaleFactor',0,'MaxHeadSize',0.5,'Clipping','on');
            xlim([1 size(iAvg,2)]); ylim([1 size(iAvg,1)]);
            hold off;
            addscalebar(1,SpeedScale*25,'color','g','yloc',min(get(gca,'ylim'))+10);

             axes(ha(4)); cla;
             overlayPositionOrientationV2(Xplot(:,frame),Yplot(:,frame),trackFP.anisoPart(:,frame),trackFP.orientPart(:,frame),trackFP.intPart(:,frame),avgdisp,...
                 'lineLength',25,'clims',0,'glyphcolor',[1 0.5 1],'Parent',ha(4),'trackLength',0,'anisoScaleLocation',0);
           % Draw tracks showing the history of the particle.
                  addscalebar(1,25,'color',[1 0.5 1],'yloc',min(get(gca,'ylim'))+10,'xloc',36);

             thisframe=frame2im(getframe(hfig)); %getframe is better than screencapture, because it updates the figures before capture.
              movOrient(:,:,:,frame)=uint8(imresize(thisframe,[800 NaN]));
        case 'orient'
            axes(ha(1)); cla;
            imagesc(avgdisp); axis equal; axis tight; set(gca,'XTick',[],'YTick',[]);
            addscalebar(0.07,1,'text','1 \mum'); axis off;
            
            axes(ha(2)); cla;
             overlayPositionOrientationV2(Xplot(:,frame),Yplot(:,frame),trackFP.anisoPart(:,frame),trackFP.orientPart(:,frame),trackFP.intPart(:,frame),avgdisp,...
                 'lineLength',25,'clims',0,'glyphcolor',[1 0.5 1],'Parent',ha(2),'trackLength',0,'anisoScaleLocation',0,'exportmovie',0); axis off;
           % Draw tracks showing the history of the particle.
%                   addscalebar(1,25,'color',[1 0.5 1],'yloc',min(get(gca,'ylim'))+10,'xloc',36);

             thisframe=frame2im(getframe(hfig)); %getframe is better than screencapture, because it updates the figures before capture.
              movOrient(:,:,:,frame)=uint8(imresize(thisframe,[600 NaN]));            
            
    end
  
end
    
    switch(movietype)
        case 'all'
            options.color=true;
            saveastiff(movOrient,[outputdir datanames{dataIndex} '_movPub.tif'],options);
        case 'orient'
              options.color=true;
              saveastiff(movOrient,[outputdir datanames{dataIndex} '_movOrient.tif'],options);
    end
end


 %% Other  statistics: comparing lamella and arc.
    
    % flow
       flowArc=flowDirection(partCell);
       flowLamella=flowDirection(partLamella);
      
       hfig=togglefig('flow direction histogram',1);
         pos=[1 1 15 15];
      set(hfig,'color','w','defaultaxesfontsize',20,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)],'color','w');
%        [thetaArc,histArc]=rose(flowArc,45);
       [thetaLamella,histLamella]=rose(flowLamella,45);
       histArc=histArc/max(histArc);
       histLamella=histLamella/max(histLamella);
       hLamella=polar(thetaLamella,histLamella,'r');
       hold on;
       hArc=polar(thetaArc,histArc,'b');
       set([hArc hLamella],'linewidth',2);

    % orientation
     orientArc=orientplot(partCell);
      orientLamella=orientplot(partLamella);
        hfig=togglefig('F-actin orientation histogram',1);
         pos=[1 1 15 15];
      set(hfig,'defaultaxesfontsize',20,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)],'color','w');
      [~,~,~,~,thetaArc,histArc]=polarPlotAnisoStat(ones(size(orientArc)),orientArc,ones(size(orientArc)),'Statistic','ParticleOrientation');
      [~,~,~,~,thetaLamella,histLamella]=polarPlotAnisoStat(ones(size(orientLamella)),orientLamella,ones(size(orientLamella)),'Statistic','ParticleOrientation');
      
       histArc=histArc/max(histArc);
       histLamella=histLamella/max(histLamella);
       

       hArc(1)=polar(thetaArc,histArc,'b');  hold on; hArc(2)=polar(thetaArc+pi,histArc,'b');
        hLamella(1)=polar(thetaLamella,histLamella,'r'); hold on; hLamella(2)=polar(thetaLamella+pi,histLamella,'r');

        set([hArc hLamella],'linewidth',2);
      
       % orientation relative to local flow.
%       orientArcvsLocalflow=arrayfun(@(orient,flow) orientRelativeToFlow(orient,flow),orientArc,flowArc);
%        orientLamellavsLocalflow=arrayfun(@(orient,flow) orientRelativeToFlow(orient,flow),orientLamella,flowLamella);
          orientArcvsLocalflow=orientArc-flowArc;
          orientLamellavsLocalflow=orientLamella-flowLamella;
         hfig=togglefig('F-actin orientation vs Local flow',1);
         pos=[1 1 20 15];
      set(hfig,'defaultaxesfontsize',18,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)],'color','w');
%       [~,~,~,~,thetaArc,histArc]=polarPlotAnisoStat(ones(size(orientArc)),orientArcvsLocalflow,ones(size(orientArc)),'Statistic','ParticleOrientation','Nbins',15);
%       [~,~,~,~,thetaLamella,histLamella]=polarPlotAnisoStat(ones(size(orientLamella)),orientLamellavsLocalflow,ones(size(orientLamella)),'Statistic','ParticleOrientation','Nbins',15);
%       
%        histArc=histArc/max(histArc);
%        histLamella=histLamella/max(histLamella);
%        
%         hLamella(1)=polar(thetaLamella,histLamella,'r'); hold on; hLamella(2)=polar(thetaLamella+pi,histLamella,'r');
%         hArc(1)=polar(thetaArc,histArc,'b');  hold on; hArc(2)=polar(thetaArc+pi,histArc,'b');
% 
%         set([hArc hLamella],'linewidth',1);

            histogram(orientArcvsLocalflow*(180/pi),-360:20:180,'FaceColor','b','Normalization','pdf'); hold on;
            histogram(orientLamellavsLocalflow*(180/pi),-360:20:180,'FaceColor','r','Normalization','pdf');
            xlim([-360 180]); 
            legend('arc','lamellipodium','location','northwest');
%        print('-dpdf',[exportdir datanames{dataIndex} '_OrientvsFlowHist.pdf']);
%        togglefig('debug',1);
%        h1=histogram((orientArc-flowArc)*(180/pi)); hold on;
%        h2=histogram((orientLamella-flowLamella)*(180/pi));
%        h1.FaceColor='red';
%        h2.FaceColor='blue';
%        legend('actin arcs','lamellipodium');
       
       %   orientation relative to global flow.

            speedXLamella=nanmean(speedX(partLamella));
            speedYLamella=nanmean(speedY(partLamella));
            
            speedXArc=nanmean(speedX(partCell));
            speedYArc=nanmean(speedY(partCell));
            
            flowDirectionLamella=atan2(-speedYLamella,speedXLamella);
            flowDirectionArc=atan2(-speedYArc,speedXArc);

            orientArcvsGlobalflow=orientArc-flowDirectionArc;
            orientLamellavsGlobalflow=orientLamella-flowDirectionLamella;
            
          hfig=togglefig('F-actin orientation vs global flow',1);
         pos=[1 1 15 15];
      set(hfig,'defaultaxesfontsize',20,'renderer','Painters',...
   'Units','centimeters','Position',pos,'PaperPositionMode','Auto','PaperSize',[pos(3) pos(4)],'color','w');
%       [~,~,~,~,thetaArc,histArc]=polarPlotAnisoStat(ones(size(orientArcvsGlobalflow)),orientArcvsGlobalflow,ones(size(orientArc)),'Statistic','ParticleOrientation','Nbins',15);
%       [~,~,~,~,thetaLamella,histLamella]=polarPlotAnisoStat(ones(size(orientArcvsGlobalflow)),orientLamellavsGlobalflow,ones(size(orientLamella)),'Statistic','ParticleOrientation','Nbins',15);
%       
%        histArc=histArc/max(histArc);
%        histLamella=histLamella/max(histLamella);
%        
%         hLamella(1)=polar(thetaLamella,histLamella,'r'); hold on; hLamella(2)=polar(thetaLamella+pi,histLamella,'r');
%         hArc(1)=polar(thetaArc,histArc,'b');  hold on; hArc(2)=polar(thetaArc+pi,histArc,'b');
% 
%         set([hArc hLamella],'linewidth',1);
            histogram(orientArcvsGlobalflow*(180/pi),-360:20:180,'FaceColor','b','Normalization','pdf'); hold on;
            histogram(orientLamellavsGlobalflow*(180/pi),-360:20:180,'FaceColor','r','Normalization','pdf');
            xlim([-360 180]); 
            legend('arc','lamellipodium','location','northwest');
            
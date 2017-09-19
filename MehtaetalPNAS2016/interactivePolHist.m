function hROI=interactivePolHist(I0,I45,I90,I135,aniso,orient,avg,varargin)
% hROI=interactivePolHist(I0,I45,I90,I135,aniso,orient,avg)
% Allows interactive exploration of orientation histogram.
% hROI is the handle of ROI used to display the orientation histogram if
% 'analyzeROI' option is set true. Otherwise hROI is NaN.

arg.avgCeiling=NaN;
arg.anisoCeiling=NaN;
arg.Statistic='PixelAnisotropy';
arg.analyzeROI=true;
arg.Parent=NaN;
arg.orientationRelativeToROI=true;
arg.scaleLUTtoROI=false;
arg.exportPath=[]; %If export path is set, export the current image and also the statistics.
arg.showColorbar=false;
arg.getDirection=false;
arg.radialRange=NaN;
arg=parsepropval(arg,varargin{:});

if(ishandle(arg.Parent))
    hfig=arg.Parent;
else
hfig=togglefig('Interactive orientation histogram',1);
clf(hfig);
set(hfig,'color','w','defaultaxesfontsize',15,'Units','Normalized','Position',[0.05 0.05 0.9 0.9]);
colormap gray;    
end

% Calculate the ceiling if not set.
if(isnan(arg.avgCeiling) || arg.avgCeiling == 0)
    arg.avgCeiling=max(avg(:));
end

% Calculate the ceiling if not set.
if(isnan(arg.anisoCeiling) || arg.anisoCeiling == 0)
    arg.anisoCeiling=max(aniso(:));
end

avgDisp=avg;
avgDisp(avg>arg.avgCeiling)=arg.avgCeiling;

OrientationMap=pol2color(aniso,orient,avgDisp,'sbm','border',15,'legend',true,'avgCeiling',arg.avgCeiling,'anisoCeiling',arg.anisoCeiling);
if(arg.showColorbar)
    ha=imagecat(I0,I45,I90,I135,OrientationMap,aniso,avg,'link','equal','off','colorbar',hfig);
else
    ha=imagecat(I0,I45,I90,I135,OrientationMap,aniso,avg,'link','equal','off',hfig);
end

set(ha(6),'clim',[0 arg.anisoCeiling]);
set(ha(7),'clim',[0 arg.avgCeiling]);
if(arg.analyzeROI)
    % Draw the ROI interactively.
    set(get(ha(7),'Title'),'String','Average (select ROI)');
    hROI=impoly(ha(7));
    setColor(hROI,'magenta');

    % Setup a callback to update the histogram everytime ROI is updated.
    addNewPositionCallback(hROI,@(p) updatePolHist(p,ha,hfig,I0,I45,I90,I135,aniso,orient,avg,arg));

    % Constrain the ROI's boundaries.
    fcn = makeConstrainToRectFcn('impoly',get(ha(7),'XLim'),get(ha(7),'YLim'));
    setPositionConstraintFcn(hROI,fcn);

    % Draw the histogram for the first time.
    updatePolHist(hROI.getPosition(),ha,hfig,I0,I45,I90,I135,aniso,orient,avg,arg);
else
    hROI=NaN;
end

end


function updatePolHist(p,ha,hfig,I0,I45,I90,I135,aniso,orient,avg,params)
persistent  hLineROI hLineOrient;
% p is ROI, ha is handles to the axes.
    histMask=poly2mask(p(:,1),p(:,2),size(I0,2),size(I0,1));
   rpMask=regionprops(histMask,'Orientation','MajorAxisLength','Centroid','MinorAxisLength');
   Lm=rpMask.MajorAxisLength; % Length of line indicating orientation of the mask.
   maskCen=rpMask.Centroid;
   maskOrient=mod(rpMask.Orientation*(pi/180),pi);
   
   if(params.getDirection)
       % Assign the direction consistent with the order of the points.
       % Point-1 to point-2 is reference direction.
   end
    % Determine the display limits after ignoring the
    % border.
    I0crop=I0(histMask);
    I135crop=I135(histMask);
    I90crop=I90(histMask);
    I45crop=I45(histMask);
    OrientationCrop=orient(histMask);
    AnisotropyCrop=aniso(histMask);
    AverageCrop=avg(histMask);
    maxAniso=max(AnisotropyCrop(:));
    Ivec=[I0crop(:); I135crop(:); I90crop(:); I45crop(:)];
    Ilims=[min(Ivec) 0.5*max(Ivec)];
      
    subplot(2,4,8,'Parent',hfig); 
    
    
    [meanAniso,meanOrient]=anisoStats(AnisotropyCrop,OrientationCrop,AverageCrop);
    polarPlotAnisoStat(AnisotropyCrop,OrientationCrop,AverageCrop,'PlotType','Polar','ReferenceOrient',maskOrient,...
        'Statistic',params.Statistic,'orientationRelativeToROI',params.orientationRelativeToROI,'anisoCeiling',params.anisoCeiling);
    


    
   %[meanOrient,meanAniso]=ComputeFluorAnisotropy(mean(I0crop),mean(I45crop),mean(I90crop),mean(I135crop),'anisotropy');
   Lf=Lm*meanAniso; % Scale down the length of line indicating orientation of fluorophore depending on the anisotropy.
   
   if(params.scaleLUTtoROI)
       set([ha(1:4); ha(7)],'Clim',Ilims);
       set(ha(6),'Clim',[0 maxAniso]);
   end
   %%% Label anisotropy display.

    axes(ha(6)); title(['anisotropy: max ' num2str(maxAniso,2) ',mean ' num2str(meanAniso,2)]);
 
    %%% Label intensity display.
    axes(ha(7));
    TotalI=sum(AverageCrop(:));
    MeanI=mean(AverageCrop(:));
    title(['total:' num2str(TotalI,3) ', mean:' num2str(MeanI,3) ]);

    
    if(ishandle(hLineROI))
        delete(hLineROI);
    end
    if(ishandle(hLineOrient))
        delete(hLineOrient);
    end

    % Note that order of Y-coordinates is flipped because the Y-axis used
    % by image processing toolbox is top to bottom, whereas visually and in
    % polarization computations it is bottom to top.
    hLineROI=line([maskCen(1)-0.5*Lm*cos(maskOrient) maskCen(1)+0.5*Lm*cos(maskOrient)],...
        [maskCen(2)+0.5*Lm*sin(maskOrient) maskCen(2)-0.5*Lm*sin(maskOrient)],'LineWidth',2,'Color','k');
    
    % Draw a line indicating the polarization orientation.
    hLineOrient=line([maskCen(1)-0.5*Lf*cos(meanOrient) maskCen(1)+0.5*Lf*cos(meanOrient)],...
        [maskCen(2)+0.5*Lf*sin(meanOrient) maskCen(2)-0.5*Lf*sin(meanOrient)],'LineWidth',2,'Color','b');
    
   
  
%     [counts,levels]=hist(mod(OrientwrtMask,180),0:0.5:180);
%     stem(levels,counts);
%    
%     xlim([0 180]); 
%     

end    

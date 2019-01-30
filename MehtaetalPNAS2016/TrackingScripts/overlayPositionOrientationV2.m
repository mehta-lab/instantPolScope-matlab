function [movOrient,LineXstart,LineYstart,LineXend,LineYend]=overlayPositionOrientationV2(xPart,yPart,anisoPart,orientPart,intPart,drawParticlesOn,varargin)
% [movOrient,hAxisOverlay,hAxisIntensity,xstart,ystart,xend,yend]=overlayPositionOrientation(xPart,yPart,anisoPart,orientPart,intPart,drawParticlesOn,varargin)
% Simpler version that just draws particles on specified axes. Useful when
% called from scripts.
% Function that overlays positon and orientation information on image.
arg.Parent=NaN;
arg.delay=0.01;
arg.glyphDiameter=6;
arg.lineLength=50; % Line-length corresponding to anisotropy of 1 when length is set proportional to anisotropy. If this is set to zero, no line is drawn.
arg.lineLengthProp=true;
arg.intensityRange=[0 0];
arg.anisotropyRange=[0 1];
arg.orientationRange=[0 180];
arg.excludeAboveOrientation=false;
arg.referenceOrientation=0;
arg.glyphColor='green';
arg.glyphLineWidth=2;
arg.roiX=0; % roiX is an array of X-coordinates that define polygon.
arg.roiY=0; % roiY is Y-coordinates of the polygon.
arg.zoomROI=false;
arg.scalePix=1/0.07;
arg.xdata=[1  size(drawParticlesOn,2)];
arg.ydata=[1 size(drawParticlesOn,1)];
arg.anisoScaleLocation=10;
arg.anisoScaleFont=20;
arg.clims=NaN; % display range for intensity image. Auto: NaN, RGB: 0, quantile of intensity data: [lowerfraction upperfraction], absolute intensity range: [lowerIntensity upperIntensity].
arg.exportMovie=true;
arg.simulatedData=false;
arg.trackLength=0; % If 0, no track is shown. If N, positions of particles over last N frames are plotted as tracks. If inf, all past positions 
arg.trackColor='magenta';
arg.highlightTrack=NaN;
arg.frameRange=1:size(xPart,2);
arg.hAxisIntensity=NaN;

arg.cmap=gray(512);
arg=parsepropval(arg,varargin{:});

if( ishandle(arg.Parent) )
        hAxisOverlay=arg.Parent;
else    
      hAxisOverlay=axes();
      set(gcf,'color','w');
end


cla;
% Select particles based on intensity.

if all(arg.intensityRange)
    intensityMask=intPart>arg.intensityRange(1) & intPart<arg.intensityRange(2);
else
    intensityMask=~isnan(intPart); %NaNs in intPart matrix are excluded.
    arg.intensityRange=[min(~isnan(intPart)) max(~isnan(intPart))];
end

% Select based on anisotropy.
anisotropyMask=(anisoPart >= arg.anisotropyRange(1) ) & ...
    (anisoPart <= arg.anisotropyRange(2) );

% Select based on orientation.
% Convert to radians.
arg.orientationRange=arg.orientationRange*(pi/180); 

orientPartFilter=mod(orientPart-arg.referenceOrientation,pi);

% The orientation w.r.t. reference is used to select what particles are
% drawn.
% But, the particle orientation must not be changed.

orientationMask= (orientPartFilter > arg.orientationRange(1)) & ...
                 (orientPartFilter < arg.orientationRange(2));   
             
if(arg.excludeAboveOrientation) % Exclude above orientation.
    orientationMask=~orientationMask;
end

if(all(arg.roiX) && all(arg.roiY))
    roiMask=inpolygon(xPart,yPart,arg.roiX,arg.roiY); 
else
    roiMask=true(size(xPart));
end

% 
useParticles=intensityMask & anisotropyMask & orientationMask & roiMask;
xPart(~useParticles)=NaN;
yPart(~useParticles)=NaN;
anisoPart(~useParticles)=NaN;
orientPart(~useParticles)=NaN;


if(isnan(arg.clims)) % determine the clims from data.
    if(size(drawParticlesOn,3)==3)
        warning('Assuming 3 frames and not a single RGB frame. If particles are to be drawn on RBG data, use ''clims'',0.');
    end
    clims=[quantile(drawParticlesOn(:),0.001) quantile(drawParticlesOn(:),0.9995)];
elseif(length(arg.clims)==2 && all(arg.clims<=1)) % clims are quantile range.
    clims=[quantile(drawParticlesOn(:),arg.clims(1)) quantile(drawParticlesOn(:),arg.clims(2))];
else  
    clims=arg.clims;
end

for frameno=arg.frameRange
 
    if(any(clims)) % gray image.
        [xlims,ylims]=drawImage(arg.xdata,arg.ydata,drawParticlesOn(:,:,frameno),[hAxisOverlay arg.hAxisIntensity],arg.roiX,arg.roiY,clims,arg.scalePix,arg.zoomROI,arg.simulatedData,arg.cmap);  
    else %color image.
         [xlims,ylims]=drawImage(arg.xdata,arg.ydata,drawParticlesOn(:,:,:,frameno),[hAxisOverlay arg.hAxisIntensity],arg.roiX,arg.roiY,clims,arg.scalePix,arg.zoomROI,arg.simulatedData,arg.cmap);  
    end
    
    particlesToDraw=useParticles(:,frameno)';
    xcen=xPart(:,frameno)'.*particlesToDraw;
    ycen=yPart(:,frameno)'.*particlesToDraw;
    orientcen=orientPart(:,frameno)'.*particlesToDraw;
    % intead of (X-,Y-) to (X+,Y+) we need to do (X-,Y+), (X+,Y-), since Y
    % axis runs from top to bottom, whereas we perceive and measure angle
    % assuming Y running from bottom to top.
    
     axes(hAxisOverlay); % Draw the particles on overlay axes.
    hold on;
    
   % Draw tracks.
    
    if(arg.trackLength && frameno>2)
        startTracks=frameno-arg.trackLength;
        if(startTracks<1)
            startTracks=1;
        end
        
        tracksX=xPart(particlesToDraw,startTracks:frameno)';
        tracksY=yPart(particlesToDraw,startTracks:frameno)';
        line (tracksX,tracksY,'color',arg.trackColor,'LineWidth',arg.glyphLineWidth);
        
%         if(~isnan(arg.highlightTrack))
%                tracksX=xPart(arg.highlightTrack,startTracks:frameno)';
%                tracksY=yPart(arg.highlightTrack,startTracks:frameno)';
%                 line (tracksX,tracksY,'color',arg.trackColor,'LineWidth',2*arg.glyphLineWidth);
%         end
    end
    
    % Draw particles and anisotropy lines.
    if(arg.lineLength) 
        %  since particles can have a wide range of intensities, it is not a
        %  good idea to scale line lengths with intensity.
        lineL=0.5*arg.lineLength; % Half the line length;
        if(arg.lineLengthProp)
            lineLParticles=bsxfun(@times,lineL,anisoPart(:,frameno)');
        end
        
        LineXstart=xcen-lineLParticles.*cos(orientcen); LineXend=xcen+lineLParticles.*cos(orientcen);
       
        if(arg.simulatedData) % For simulated data, images are plotted in XY grid and there is no need to flip the Y axis.
            LineYstart=ycen-lineLParticles.*sin(orientcen); LineYend=ycen+lineLParticles.*sin(orientcen);
        else % For experimental data, Y-axis runs from top to bottom, but we read orientaiton bottom to top. So flip the Y-axis when calculatint line.
            LineYstart=ycen+lineLParticles.*sin(orientcen); LineYend=ycen-lineLParticles.*sin(orientcen); 
        end
        %%quiver(xcen,ycen,cos(orientcen),sin(orientcen),0,'ShowArrowHead','off','AutoScale','on','Marker','o');
%         if(isempty(arg.glyphColor))
%                 line([LineXstart;LineXend],[LineYstart;LineYend],'LineWidth',arg.glyphLineWidth); % Auto-color the lines.
%         else
            line([LineXstart;LineXend],[LineYstart;LineYend],'color',arg.glyphColor,'LineWidth',arg.glyphLineWidth);

%         end
        
        if(arg.anisoScaleLocation) 
%             line([2 2*lineL+2],[2 2],'color',arg.glyphColor,'LineWidth',4);
%             text(2,-8,'polarization factor=1','FontSize',arg.anisoScaleFont);
            line([xlims(1)+1 2*lineL+xlims(1)+1],[ylims(1)+arg.anisoScaleLocation  ylims(1)+arg.anisoScaleLocation],'color',arg.glyphColor,'LineWidth',4);
        end
    end
    plot(xcen,ycen,'.','MarkerEdgeColor',arg.glyphColor,'MarkerSize',arg.glyphDiameter,'LineWidth',arg.glyphLineWidth); %'LineWidth',arg.glyphLineWidth
    if(~isnan(arg.highlightTrack))
            plot(xcen(arg.highlightTrack),ycen(arg.highlightTrack),'*','MarkerEdgeColor',arg.glyphColor,'MarkerSize',2*arg.glyphDiameter,'LineWidth',arg.glyphLineWidth); %'LineWidth',arg.glyphLineWidth
    end
 

   % drawnow; % Make sure figure is updated, before taking a screenshot.
    hold off;
       if(arg.exportMovie && ishandle(arg.hAxisIntensity))
        pause(arg.delay); % Delay so that figure is updated.
        axes(hAxisOverlay);
        frameOrient=frame2im(getframe(gca)); %getframe is better than screencapture, because it updates the figures before capture.
        
        axes(arg.hAxisIntensity);
        frameIntensity=frame2im(getframe(gca));
        
        frameOrient=uint8(imresize(frameOrient,[600 NaN]));
        frameIntensity=uint8(imresize(frameIntensity,[600 NaN]));
        movOrient(:,:,:,frameno)=cat(2,frameIntensity,frameOrient);
            %thisframe=frame2im(getframe(hfigOrient));
       elseif(arg.exportMovie)
         axes(hAxisOverlay);
         frameOrient=frame2im(getframe(gca)); %getframe is better than screencapture, because it updates the figures before capture.
           
         frameOrient=uint8(imresize(frameOrient,[600 NaN]));
         movOrient(:,:,:,frameno)=frameOrient;           
       end
end
   
end



function [xlims,ylims]=drawImage(xdata,ydata,img,haxes,roiX,roiY,clims,scalePix,zoomROI,simulatedData,cmap,tStamp)
if(all(roiX) && all(roiY) && zoomROI)
    xlims=[min(roiX) max(roiX)]; ylims=[min(roiY) max(roiY)];
else
    xlims=xdata; ylims=ydata;
end
     for idx=1:numel(haxes)
         if(ishandle(haxes(idx)))

%              imshow(squeeze(img),'XData',xdata,'YData',ydata,'Parent',haxes(idx),'InitialMagnification','fit'); 
%              colormap(cmap);
              imagesc(squeeze(img),'Parent',haxes(idx));
             if(any(clims)) % For gray image.
                 set(haxes(idx),'CLim',clims);
             end
             if(simulatedData)
                 axis xy;
             end
             ylim([ydata(1)-20 ydata(end)]); 
             set(haxes(idx),'XTick',[],'YTick',[]);
             hold on;
             if(~zoomROI)
                plot([roiX; roiX(1)],[roiY; roiY(1)],'--w','Linewidth',1.5);
             end
             xlim(xlims); ylim(ylims);
             set(haxes(idx),'xlim',xlims,'ylim',ylims);
             if(scalePix)
%                 line([xlims(1)+2  xlims(1)+2+scalePix],[ylims(2)-2 ylims(2)-2],'color','w','LineWidth',5,'Parent',haxes(idx));
                    addscalebar(1,scalePix,'Parent',haxes(idx));
             end
             hold off;
         end
     end

end
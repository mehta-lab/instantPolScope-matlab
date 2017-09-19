function [movOrient,hAxisOverlay,hAxisIntensity,xstart,ystart,xend,yend]=overlayPositionOrientation(xPart,yPart,anisoPart,orientPart,intPart,polstack,varargin)
% [movOrient,hAxisOverlay,hAxisIntensity,xstart,ystart,xend,yend]=overlayPositionOrientation(xPart,yPart,anisoPart,orientPart,intPart,polstack,varargin)
% Function that overlays positon and orientation information on image.
params.Parent=NaN; % Set to NaN to create new figure. Set to 0 to use the axes handles supplied below.
params.IntensityAxes=NaN; % If Parent is NaN of if the handle is valid, intensity image is drawn.
params.OrientationAxes=NaN;
params.drawParticlesOn='average';
%params.intensityImage=params.drawParticlesOn;
params.delay=0.05;
params.glyphDiameter=6;
params.lineLength=50; % Line-length corresponding to anisotropy of 1 when length is set proportional to anisotropy. If this is set to zero, no line is drawn.
params.lineLengthProp=true;
params.intensityRange=[0 0];
params.anisotropyRange=[0 1];
params.orientationRange=[0 180];
params.excludeAboveOrientation=false;
params.referenceOrientation=0;
params.colorMap='sbm';
params.glyphColor='green';
params.glyphLineWidth=2;
params.roiX=NaN;
params.roiY=NaN;
params.scalePix=1/0.07;
params.xdata=[1  size(polstack,2)];
params.ydata=[1 size(polstack,1)];
params.anisoScale=true;
params.clims=NaN;
params=parsepropval(params,varargin{:});
 


 if(isnan(params.Parent))
           hfigOrient=togglefig('Overlay of images and particles.'); 
           set(hfigOrient,'Position',[100 100 1400 700],'color','w'); colormap gray;
           delete(get(hfigOrient,'Children'));
           hAxisIntensity=axes('Parent',hfigOrient,'Position',[0.1 0.1 0.4 0.9]);
           hAxisOverlay=axes('Parent',hfigOrient,'Position',[0.5 0.1 0.4 0.9]);    
           linkaxes([hAxisIntensity hAxisOverlay]);
           
 elseif(ishandle(params.Parent) && params.Parent>0)
           hfigOrient=params.Parent;
           delete(get(hfigOrient,'Children'));
           hAxisIntensity=axes('Parent',hfigOrient,'Position',[0.1 0.1 0.4 0.9]);
           hAxisOverlay=axes('Parent',hfigOrient,'Position',[0.5 0.1 0.4 0.9]);    
           linkaxes([hAxisIntensity hAxisOverlay]);

 else % If params.Parent is 0, assume that required axes are supplied independently.
     hAxisIntensity=params.IntensityAxes;
     hAxisOverlay=params.OrientationAxes;
     if(ishandle(hAxisIntensity) && ishandle(hAxisOverlay))
         linkaxes([hAxisIntensity hAxisOverlay]);
     end
         
 end
 
    


% Select particles based on intensity.

if all(params.intensityRange)
    intensityMask=intPart>params.intensityRange(1) & intPart<params.intensityRange(2);
else
    intensityMask=~isnan(intPart); %NaNs in intPart matrix are excluded.
    params.intensityRange=[min(~isnan(intPart)) max(~isnan(intPart))];
end

% Select based on anisotropy.
anisotropyMask=(anisoPart >= params.anisotropyRange(1) ) & ...
    (anisoPart <= params.anisotropyRange(2) );

% Select based on orientation.
% Convert to radians.
params.orientationRange=params.orientationRange*(pi/180); 

orientPartFilter=mod(orientPart-params.referenceOrientation,pi);

% The orientation w.r.t. reference is used to select what particles are
% drawn.
% But, the particle orientation must not be changed.

orientationMask= (orientPartFilter > params.orientationRange(1)) & ...
                 (orientPartFilter < params.orientationRange(2));   
             
if(params.excludeAboveOrientation) % Exclude above orientation.
    orientationMask=~orientationMask;
end

useParticles=intensityMask & anisotropyMask & orientationMask;

% Determine display limits
if(isnumeric(params.drawParticlesOn)) % If 3D matrix.
    % Reshape into 4D matrix to match with format of polstack and orientationmap.
   drawParticlesOn=reshape(params.drawParticlesOn,size(params.drawParticlesOn,1),size(params.drawParticlesOn,2),[],size(params.drawParticlesOn,3));
elseif(ischar(params.drawParticlesOn)) % If string
    switch(params.drawParticlesOn)
        case 'average'
            drawParticlesOn= polstack(:,:,3,:);
        case 'anisotropy'
           drawParticlesOn=polstack(:,:,1,:);
        case 'orientation'
            drawParticlesOn= polstack(:,:,2,:);
        case 'orientationmap'
          drawParticlesOn=pol2color(squeeze(polstack(:,:,1,:)),...
          squeeze(polstack(:,:,2,:)),...
          squeeze(polstack(:,:,3,:)),...
          params.colorMap,'legend',false,'avgCeiling',params.intensityRange(2),'anisoCeiling',params.anisotropyRange(2));
    end
end

% if(isnumeric(params.intensityImage)) % If 3D matrix.
%     % Reshape into 4D matrix to match with format of polstack and orientationmap.
%    intensityImage=reshape(params.intensityImage,size(params.intensityImage,1),size(params.intensityImage,2),[],size(params.intensityImage,3));
% elseif(ischar(params.intensityImage)) % If string
%     switch(params.intensityImage)
%         case 'average'
%             intensityImage= polstack(:,:,3,:);
%         case 'anisotropy'
%            intensityImage=polstack(:,:,1,:);
%         case 'orientation'
%             intensityImage= polstack(:,:,2,:);
%         case 'orientationmap'
%           intensityImage=pol2color(squeeze(polstack(:,:,1,:)),...
%           squeeze(polstack(:,:,2,:)),...
%           squeeze(polstack(:,:,3,:)),...
%           params.colorMap,'legend',false,'avgCeiling',params.intensityRange(2),'anisoCeiling',params.anisotropyRange(2));
%     end
% end

if(isnan(params.clims))
    clims=[min(drawParticlesOn(:)) max(drawParticlesOn(:))];
else
    clims=params.clims;
end

for frameno=1:size(drawParticlesOn,4)
    hold off;
%     if(isnumeric(params.drawParticlesOn)) % If 3D matrix.
%             drawImage(xdata,ydata,params.drawParticlesOn(:,:,frameno),[hImg hOverlay],params.roiX,params.roiY,clims);
%     elseif(ischar(params.drawParticlesOn)) % If string
%         switch(params.drawParticlesOn)
%             case 'average'
%              drawImage(xdata,ydata,polstack(:,:,3,frameno),[hImg hOverlay],params.roiX,params.roiY,clims);     
%             case 'anisotropy'
%              drawImage(xdata,ydata,polstack(:,:,1,frameno),[hImg hOverlay],params.roiX,params.roiY,clims);
%             case 'orientation'
%              drawImage(xdata,ydata,polstack(:,:,2,frameno),[hImg hOverlay],params.roiX,params.roiY,clims);
%             case 'orientationmap'
%               colormap=pol2color(polstack(:,:,1,frameno),polstack(:,:,2,frameno),polstack(:,:,3,frameno),params.colorMap,'legend',true);
%               drawImage(xdata,ydata,colormap,[hImg hOverlay],params.roiX,params.roiY,clims);
%         end
%     end
    drawImage(params.xdata,params.ydata,drawParticlesOn(:,:,:,frameno),hAxisOverlay,params.roiX,params.roiY,clims,params.scalePix);  
    drawImage(params.xdata,params.ydata,drawParticlesOn(:,:,:,frameno),hAxisIntensity,params.roiX,params.roiY,clims,params.scalePix);      
    particlesToDraw=useParticles(:,frameno)';
    xcen=xPart(:,frameno)'.*particlesToDraw;
    ycen=yPart(:,frameno)'.*particlesToDraw;
    orientcen=orientPart(:,frameno)'.*particlesToDraw;
    % intead of (X-,Y-) to (X+,Y+) we need to do (X-,Y+), (X+,Y-), since Y
    % axis runs from top to bottom, whereas we perceive and measure angle
    % assuming Y running from bottom to top.

    axes(hAxisOverlay); % Draw the particles on overlay axes.
    hold on;

    if(params.lineLength) 
        %  since particles can have a wide range of intensities, it is not a
        %  good idea to scale line lengths with intensity.
        lineL=0.5*params.lineLength; % Half the line length;
        if(params.lineLengthProp)
            lineLParticles=bsxfun(@times,lineL,anisoPart(:,frameno)');
        end

        xstart=xcen-lineLParticles.*cos(orientcen); xend=xcen+lineLParticles.*cos(orientcen);
        ystart=ycen+lineLParticles.*sin(orientcen); yend=ycen-lineLParticles.*sin(orientcen); 
        %%quiver(xcen,ycen,cos(orientcen),sin(orientcen),0,'ShowArrowHead','off','AutoScale','on','Marker','o');
        line([xstart;xend],[ystart;yend],'color',params.glyphColor,'LineWidth',params.glyphLineWidth);
        
        if(params.anisoScale)
            line([2 2*lineL+2],[2 2],'color',params.glyphColor,'LineWidth',4);
            text(2,-5,'anisotropy=1','FontSize',18,'color',params.glyphColor);
        end
    end
    plot(xcen,ycen,'o','MarkerEdgeColor',params.glyphColor,'LineWidth',params.glyphLineWidth,'MarkerSize',params.glyphDiameter);
   % drawnow; % Make sure figure is updated, before taking a screenshot.
    pause(params.delay); % Delay so that figure is updated.

    frameOrient=frame2im(getframe(hAxisOverlay)); %getframe is better than screencapture, because it updates the figures before capture.
    if(ishandle(hAxisIntensity))
        frameImg=frame2im(getframe(hAxisIntensity));
       % Construct the frame 
        frameImg=imresize(frameImg,[size(frameOrient,1) size(frameOrient,2)]);
        thisframe=cat(2,frameImg,frameOrient);
        movOrient(:,:,:,frameno)=imresize(thisframe,[600 NaN]);
    else
        movOrient(:,:,:,frameno)=imresize(frameOrient,[600 NaN]);
        %thisframe=frame2im(getframe(hfigOrient));
    end
   
end


end

function drawImage(xdata,ydata,img,haxes,roiX,roiY,clims,scalePix)
if(~isnan(roiX) && ~isnan(roiY))
    xlims=[min(roiX) max(roiX)]; ylims=[min(roiY) max(roiY)];
else
    xlims=xdata; ylims=ydata;
end
     for idx=1:numel(haxes)
         if(ishandle(haxes(idx)))
             axes(haxes(idx));
             imagesc(xdata,ydata,squeeze(img),clims); 
             axis equal; axis tight;
             ylim([ydata(1)-20 ydata(end)]); 
             set(gca,'XTick',[],'YTick',[]);
             hold on;
             plot([roiX; roiX(1)],[roiY; roiY(1)],'--w','Linewidth',1.5);
             xlim(xlims); ylim(ylims)
             if(scalePix)
                line([xlims(1)+2  xlims(1)+2+scalePix],[ylims(2)-2 ylims(2)-2],'color','w','LineWidth',5);
             end
             hold off;
         end
     end

end
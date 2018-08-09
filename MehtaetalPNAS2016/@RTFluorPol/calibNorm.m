function calibNorm(self,Inorm,varargin)
% calibNorm(self,Inorm,'property',value)
% Property: 'normMethod'
%   'reset': reset normalization factors.
%   'manual': bring up the GUI that allows manual adjustment of normalization
%   factors.
%   'fromImage': Estimate from image,  uses ROI specified in the property normROILeftTop, if it is set. normROILeftTop is assumed to have
%   been read from ImageJ's status bar.
%   'normRange': Range of value that normalization factors can assume.
% Property: 'normROILeftTop'
%           4-element vector [LeftTopX LeftTopY Width Height] of a ROI over
%           isotropic region of the specimen in the left-top quadrant.
% Calibrates either excitation imbalance or detection imbalance.

normParams.normMethod='manual'; 

normParams.normROITopLeft=[self.cornerTopLeft self.quadWidth self.quadHeight];
normParams.diagnosis=true;
normParams.normRange=[0.8 1.2];
normParams.normalizeExcitation=false;
% These parameters are useful when calibNorm is called from a parent GUI.
normParams.Parent=NaN; % Parent canvas.
normParams.normEndCallBack=NaN; % Callback to execute at the end of normalization. Typically to update the parameters in GUI based on the results of normalization.
normParams=parsepropval(normParams,varargin{:});
% Calculate the ROI in the cropped and registered quadrants, from the ROI
% in top-left of quad image.
normROI=normParams.normROITopLeft-[self.cornerTopLeft 0 0]+[1 1 0 0]; 

if(isempty(Inorm))
    if(normParams.normalizeExcitation)
        self.NormI45ex=1; 
        self.NormI90ex=1;
        self.NormI135ex=1;
    else
        self.NormI45=1; 
        self.NormI90=1;
        self.NormI135=1;
    end
    return;
    
elseif(ismatrix(Inorm))
      if(normParams.normalizeExcitation)
          % Normalize with detection path normalization.
       [I0, I45, I90, I135]=self.quadstoPolStack(Inorm,'computeWhat','Channels','normalize',true,'normalizeExcitation',false);
      else
          % When detection path normalization is changed, reset the
          % excitation normalization.
        [I0, I45, I90, I135]=self.quadstoPolStack(Inorm,'computeWhat','Channels','normalize',false);    
        self.NormI45ex=1; 
        self.NormI90ex=1;
        self.NormI135ex=1;
      end
else
    error('Inorm must be either empty (to reset normalization) or an image');
end


switch(normParams.normMethod)
    case {'reset','RESET','Reset'}
        if(normParams.normalizeExcitation)
            self.NormI45ex=1; 
            self.NormI90ex=1;
            self.NormI135ex=1;
        else
            self.NormI45=1; 
            self.NormI90=1;
            self.NormI135=1;
        end
        
    case {'manual','MANUAL','Manual'}
    %if(normParams.normalizeExcitation)
        error('Under testing: manual normalization of excitation efficiency.');
   % else        
     %   normQuadsManual(self,I0,I45,I90,I135,'normROI',normROI,'normRange',...
     %       normParams.normRange,'Parent',normParams.Parent,'normEndCallBack',normParams.normEndCallBack,...
     %       'normalizeExcitation',normParams.normalizeExcitation);
    %end
    
    case {'fromImage','FromImage','fromimage','FROMIMAGE'}
        
%            freqcut=params.objectiveNA/(1E-3*params.wavelength);
%            I0normfilt=opticalLowpassInterpolation(...
%                 I0,params.PixSize,freqcut,1);
%            I45normfilt= opticalLowpassInterpolation(...
%                 I45,params.PixSize,freqcut,1);
%            I90normfilt= opticalLowpassInterpolation(...
%                 I90,params.PixSize,freqcut,1);
%            I135normfilt= opticalLowpassInterpolation(...
%                 I135,params.PixSize,freqcut,1);
%           I find that the equalization factor across the field of view is quite similar.

    if(~ishandle(normParams.Parent))
        hnorm=togglefig('Before and after normalization',1); 
        maximizefig(hnorm);
        set(hnorm,'color','white','defaultaxesfontsize',15); colormap gray;
    else
        hnorm=normParams.Parent;
        delete(get(hnorm,'Children'));
    end
    
    % Ask the user to specify the normalization ROI (for both detection
    % and excitation).
        
    haxes=axes('Parent',hnorm);
    imshow(0.25*(I0+I45+I90+I135),[]); 
    title('Select ROI for normalization');
    normROI=impoly(haxes);
    normMask=normROI.createMask();
    normROIpos=normROI.getPosition();
    
    if(normParams.normalizeExcitation)
        
        I0crop=I0(normMask);
        I45crop=I45(normMask);
        I90crop=I90(normMask);
        I135crop=I135(normMask);
        I0mean=mean(I0crop(:));
        self.NormI45ex=I0mean/mean(I45crop(:));
        self.NormI90ex=I0mean/mean(I90crop(:));
        self.NormI135ex=I0mean/mean(I135crop(:));
        
        
    else   
%%%% Smooth the normalization image by filtering.      
%         ballR=2;
%         FiltGauss=fspecial('gaussian',round(7*ballR),ballR);
        % se=strel('ball',ballR,ballR);
        % Bottom hat transformation identifies regions that are bellow the
        % surroundings and smaller than specified structuring element.
        % Adding bottom-hat to the image 'in-paint' the debris on the slide or camera.
        
%         I0bot=imbothat(I0,se); 
%         I45bot=imbothat(I45,se);
%         I90bot=imbothat(I90,se);
%         I135bot=imbothat(I135,se);
%         
%         I0Filt=imfilter(I0+I0bot,FiltGauss,'replicate','same');
%         I45Filt=imfilter(I45+I45bot ,FiltGauss,'replicate','same');
%         I90Filt=imfilter(I90+I90bot,FiltGauss,'replicate','same');
%         I135Filt=imfilter(I135+I135bot,FiltGauss,'replicate','same');

%         I0Filt=imfilter(I0,FiltGauss,'replicate','same');
%         I45Filt=imfilter(I45,FiltGauss,'replicate','same');
%         I90Filt=imfilter(I90,FiltGauss,'replicate','same');
%         I135Filt=imfilter(I135,FiltGauss,'replicate','same');
%         
%         self.NormI45=I0Filt./I45Filt;
%         self.NormI90=I0Filt./I90Filt;
%         self.NormI135=I0Filt./I135Filt;
%         
%         self.NormI45(~normMask)=1;
%         self.NormI90(~normMask)=1;
%         self.NormI135(~normMask)=1;
      
            %%% Smooth the normalization image by fitting.
            xaxis=1:size(I0,2);
            yaxis=1:size(I0,1);
            [xgrid,ygrid]=meshgrid(xaxis,yaxis);
            % Ignore the contributions of points outside of the mask to fitting.
            xgrid(~normMask)=NaN;
            ygrid(~normMask)=NaN;

            smoothness=250;
            NormI45=I0./I45; NormI90=I0./I90; NormI135=I0./I135;

            self.NormI45=gridfit(xgrid,ygrid,NormI45,xaxis,yaxis,'smoothness',smoothness,'regularizer','springs');
            self.NormI90=gridfit(xgrid,ygrid,NormI90,xaxis,yaxis,'smoothness',smoothness,'regularizer','springs');
            self.NormI135=gridfit(xgrid,ygrid,NormI135,xaxis,yaxis,'smoothness',smoothness,'regularizer','springs');
        
    end
end

% Normalization complete, run the callback. 
if(isa(normParams.normEndCallBack,'function_handle'))
    normParams.normEndCallBack();
end

      
if(normParams.diagnosis && ~strcmpi(normParams.normMethod,'manual'))
    if(~ishandle(normParams.Parent))
        hnorm=togglefig('Before and after normalization',1); 
        maximizefig(hnorm);
        set(hnorm,'color','white','defaultaxesfontsize',15); colormap gray;
    else
        hnorm=normParams.Parent;
        delete(get(hnorm,'Children'));
    end
    
    [OrientBefore, AnisoBefore]=ComputeFluorAnisotropy(I0,I45,I90,I135,'anisotropy','ItoSMatrix',self.ItoSMatrix);
    [~,~,~,~,AnisoAfter,OrientAfter]=self.quadstoPolStack(Inorm,'computeWhat','Channels',...
        'normalize',true,'normalizeExcitation',true);

    
    OrientBefore=(180/pi)*OrientBefore;
    OrientAfter=(180/pi)*OrientAfter;
    

     OrientBeforeCrop=OrientBefore(normMask);
     OrientBeforeHist=hist(OrientBeforeCrop(:),0:180);
     OrientAfterCrop=OrientAfter(normMask);
     OrientAfterHist=hist(OrientAfterCrop(:),0:180);
     AnisoBeforeCrop=AnisoBefore(normMask);
     maxAniso=max(AnisoBeforeCrop(:));
     minAniso=min(AnisoBeforeCrop(:));
     
    
     normROI=cat(1,normROIpos,normROIpos(1,:));
    ha(1)=subplot(2,3,1,'Parent',hnorm);
    imagesc(AnisoBefore,[minAniso maxAniso]);
    axis equal; axis tight; colorbar;
    title('Anisotropy before normalization'); set(gca,'XTick',[],'YTick',[]);
%     rectangle('Position',normROI,'EdgeColor','Blue');
    hold on; plot(normROI(:,1),normROI(:,2));
    
    ha(2)=subplot(2,3,2,'Parent',hnorm);
    imagesc(OrientBefore); 
    axis equal; axis tight; colorbar;
    title('Orientation before normalization');  set(gca,'XTick',[],'YTick',[]);
    hold on; plot(normROI(:,1),normROI(:,2));

    
    subplot(2,3,3,'Parent',hnorm);
    stem(0:180,OrientBeforeHist); xlabel('Orientation (deg)'); title('Histogram of orientation before normalization within ROI');

    ha(3)=subplot(2,3,4,'Parent',hnorm);
    imagesc(AnisoAfter,[minAniso maxAniso]);
    axis equal; axis tight; colorbar;
    title('Anisotropy after normalization'); set(gca,'XTick',[],'YTick',[]);
    hold on; plot(normROI(:,1),normROI(:,2));
 
%     rectangle('Position',normROI,'EdgeColor','Blue');
    ha(4)=subplot(2,3,5,'Parent',hnorm);
    imagesc(OrientAfter); 
    axis equal; axis tight; colorbar;
    title('Orientation after normalization');  set(gca,'XTick',[],'YTick',[]);
       hold on; plot(normROI(:,1),normROI(:,2));
 
%     rectangle('Position',normROI,'EdgeColor','Blue');
    subplot(2,3,6,'Parent',hnorm);
    stem(0:180,OrientAfterHist); xlabel('Orientation (deg)'); title('Histogram of orientation after normalization within ROI');

   linkaxes(ha);
%     
%     
%     
%     
%     hnormImg=imagecat(I0,I45After,I90After,I135After,...
%         OrientBefore,OrientAfter,AnisoBefore,AnisoAfter,'equal','link','colorbar',hnorm);
%     % Set the same gray scale on intensity images. 
%     climsIntensity=get(hnormImg(1:4),'clim');
%     climsIntensity=cell2mat(climsIntensity);
%     set(hnormImg(1:4),'clim',[min(climsIntensity(:)) max(climsIntensity(:))]);
%     
%     % Set the gray scale on anisotropy images so that details in the chosen
%     % ROI are emphasized.
% 
%     set(hnormImg(7:8),'clim',[minAniso maxAniso]);
%     rectangle('Position',normROI,'Parent',hnormImg(7),'EdgeColor','Blue');
%    rectangle('Position',normROI,'Parent',hnormImg(8),'EdgeColor','Blue');

end
    

end


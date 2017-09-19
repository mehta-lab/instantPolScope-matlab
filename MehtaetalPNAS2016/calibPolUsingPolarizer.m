function [StoIMatrix,ItoSMatrix,varargout] = calibPolUsingPolarizer(polstack,varargin)%polParams.polType,polParams.center,polParams.maxRadius,polParams.diagnosis)
%[StoIMatrix,ItoSMatrix] = calibPolUsingPolarizer(polstack,varargin)
% caibPolUsingPolarizer, accepts polstack of polarizer as an input and
% outputs the instrument matrices. Useful for RTFluorPol and when the
% liquid crystal is used in epi-path.




polParams.polType='tangential';
polParams.center=[]; % The empty center triggers a GUI to select the center. 
polParams.maxRadius=100; % The quadrant size is 250, so 100 is typically safe radius to assume.
polParams.diagnosis=false;
polParams.linpolOrient=NaN;
polParams.Parent=NaN; % Handle of parent uipanel or figure on which images are drawn.

%Run at the end. One can pass a handle to a function that refreshes GUI
%with new calibration.
% polParams.polEndCallBack=NaN;
% Not required, because the function does not continuously update
% calibration.

polParams=parsepropval(polParams,varargin{:});

if(isempty(polstack))
    StoIMatrix=[0.5 0.5 0; 0.5 0 0.5; 0.5 -0.5 0; 0.5 0 -0.5];
    ItoSMatrix=[0.5 0.5 0.5 0.5; 1 0 -1 0; 0 1 0 -1];
    return;
end

% When multiple linear polarizers are used for calibration, we may have a
% series of polstacks. The time or series dimension is 4th dimension.
Anisotropy=squeeze(polstack(:,:,1,:));
Orientation=squeeze(polstack(:,:,2,:));
Average=squeeze(polstack(:,:,3,:));   
I0=squeeze(polstack(:,:,4,:));
I135=squeeze(polstack(:,:,5,:));
I90=squeeze(polstack(:,:,6,:));
I45=squeeze(polstack(:,:,7,:));


if(isnan(polParams.Parent))
% Compare the results before and after calibration.
    hTanPol=togglefig(['Calibration of polarization properties using ' polParams.polType ' polarizer'],1); 
    maximizefig(hTanPol);
    set(hTanPol,'defaultaxesfontsize',15,'Color','white'); 
    colormap gray;
else
    hTanPol=polParams.Parent;
    delete(get(hTanPol,'children'));
end

switch(polParams.polType)
    case {'radial','tangential'}

    
    if(isempty(polParams.center))
        delete(get(hTanPol,'Children')); % Clear the figure or panel.
        axes('Units','Normalized','Position',[0 0 1 0.95],'Parent',hTanPol);
        imagesc(Orientation); axis equal; colorbar; axis tight;
        hTitle=title('Select the center of the following orientation image');
        set(hTitle,'FontSize',15,'FontWeight','bold');
        [centerX,centerY]=myginput(1,'cross');
        polParams.center=[centerX,centerY];
    end
    % Azimuthally resample the intensities. Transmission orientation is
    % perpendicular to azimuth from center.

    xaxis=(0:size(polstack,2)-1)-polParams.center(1);
    yaxis=(0:size(polstack,1)-1)-polParams.center(2);
    [xx, yy]=meshgrid(xaxis,yaxis);
    rAxis=linspace(0.25*polParams.maxRadius,polParams.maxRadius,51);
    thetaAxis=linspace(0,2*pi,180*4+1);
    [rr, theta]=meshgrid(rAxis,thetaAxis);
    xxi=rr.*cos(theta);
    yyi=-rr.*sin(theta); % Flip the Y-axis because MATLAB does so.

    I0var=interp2(xx,yy,I0,xxi,yyi);
    I45var=interp2(xx,yy,I45,xxi,yyi);
    I90var=interp2(xx,yy,I90,xxi,yyi);
    I135var=interp2(xx,yy,I135,xxi,yyi);

    switch(polParams.polType)
        case 'radial'
            localangles=mod(theta,pi);
        case 'tangential'
            localangles=mod(theta+pi/2,pi);
    end
    
    % Convert measurements into vectors.
    % In CalibrateInstrumentMatrix function, the angles are mapped to rows
    % and intensities to columns.
    I=[I0var(:) I45var(:) I90var(:) I135var(:)]';

    [StoIMatrix,ItoSMatrix]=CalibrateInstrumentMatrix(localangles(:)',I);

    [azimvar,anisovar,avgvar]=ComputeFluorAnisotropy(I0var,I45var,I90var,I135var,'anisotropy');
    [azimvarCorr,anisovarCorr,avgvarCorr]=ComputeFluorAnisotropy(I0var,I45var,I90var,I135var,...
    'anisotropy','ItoSMatrix',ItoSMatrix);
    varargout{1}=localangles;
    varargout{2}=azimvar;
    varargout{3}=azimvarCorr;

    if(polParams.diagnosis)

        hDebug=togglefig(['Debug information for calibration:' polParams.polType]);
        maximizefig(hDebug);
        set(hDebug,'color','white','defaultaxesfontsize',15); colormap gray;

    imagecat(rAxis,thetaAxis,I0var,I45var,I90var,I135var,localangles,azimvarCorr,anisovar,anisovarCorr,...
        avgvar,avgvarCorr,'link','colorbar',hDebug);

    end

    
    % Calculate corrected pol-outputs.
    [CorrectedOrientation, CorrectedAnisotropy, CorrectedAverage]=...
        ComputeFluorAnisotropy(I0,I45,I90,I135,'anisotropy','ItoSMatrix',ItoSMatrix);

    hTanPolImg=imagecat(Orientation,Anisotropy,Average,...
        CorrectedOrientation,CorrectedAnisotropy,CorrectedAverage,'equal','link','colorbar','off',hTanPol);
    % Set the color limits of outputs before and after
    % calibration to be identical.


    minAnisotropy=min(Anisotropy(:));
    maxAnisotropy=max(Anisotropy(:));
    if(minAnisotropy<0) 
        minAnisotropy=0; 
    end;
    
    if(maxAnisotropy>1) 
        maxAnisotropy=1; 
    end;

    % The variation is higher before correction is applied.
    set(hTanPolImg([1 4]),'clim',[min(Orientation(:)) max(Orientation(:))]);
    set(hTanPolImg([2 5]),'clim',[minAnisotropy maxAnisotropy]);
    set(hTanPolImg([3 6]),'clim',[min(Average(:)) max(Average(:))]);


    case 'linearRotated'
       % If images of multiple polarizers at different orientations is
       % supplied. The input must be a series of polstacks. A vector that
       % specifies the orientation of the polarizer must be supplied as
       % optional argument.
       if(size(polstack,4)~=length(polParams.linpolOrient))
           error('Data from linear polarizer at multiple angles (at least 4) is required. The length of the linpolOrient must be the same as number of measurements.');
       end
       
       % Avoid border pixels without accurate information.
       border=30/2;
       I0=I0(border:end-border,border:end-border,:);
       I45=I45(border:end-border,border:end-border,:);
       I90=I90(border:end-border,border:end-border,:);
       I135=I135(border:end-border,border:end-border,:);
       
       I0var=squeeze(mean(mean(I0,2),1)); % Third dimension is orientation.
       I45var=squeeze(mean(mean(I45,2),1));
       I90var=squeeze(mean(mean(I90,2),1));
       I135var=squeeze(mean(mean(I135,2),1));
       
       % In CalibrateInstrumentMatrix function, the angles are mapped to rows
        % and intensities to columns.
       if(isrow(polParams.linpolOrient))
           localangles=polParams.linpolOrient*pi/180;
       elseif(iscolumn(polParams.linpolOrient))
           localangles=polParams.linpolOrient'*pi/180;
       else
           error('The linpolOrient needs to be a vector.');
       end
        % Convert measurements into matrix.
        I=[I0var(:) I45var(:) I90var(:) I135var(:)]';       
        [StoIMatrix,ItoSMatrix]=CalibrateInstrumentMatrix(localangles,I);
        
        % Display the diagnotic information.
        [OrientBefore,AnisoBefore,AvgBefore]=ComputeFluorAnisotropy(I0var,I45var,I90var,I135var,'anisotropy');
        [OrientAfter,AnisoAfter,AvgAfter]=ComputeFluorAnisotropy(I0var,I45var,I90var,I135var,'anisotropy','ItoSMatrix',ItoSMatrix);
        
        delete(get(hTanPol,'children'));
        subplot(1,3,1,'Parent',hTanPol);
        plot(localangles*(180/pi),OrientBefore*(180/pi),'o',localangles*(180/pi),OrientAfter*(180/pi),'x','markersize',8,'LineWidth',2);
        xlabel('Orientation of linear polarizer'); legend('before','after','Position','Best');
        title('Measured orientation'); 
        xlim([0 180]); ylim([0 180]); axis square;
        
        subplot(1,3,2,'Parent',hTanPol);
        plot(localangles*(180/pi),AnisoBefore,'o',localangles*(180/pi),AnisoAfter,'x','markersize',8,'LineWidth',2);
        xlabel('Orientation of linear polarizer'); legend('before','after','Position','Best');
        title('Measured anisotropy'); 
        xlim([0 180]); ylim([0 1]); axis square;
        
        subplot(1,3,3,'Parent',hTanPol);
        plot(localangles*(180/pi),AvgBefore,'o',localangles*(180/pi),AvgAfter,'x','markersize',8,'LineWidth',2);
        xlabel('Orientation of linear polarizer'); legend('before','after','Position','Best');
        title('Measured average');
        xlim([0 180]); axis square;
                
    case 'reset'
        StoIMatrix=[0.5 0.5 0; 0.5 0 0.5; 0.5 -0.5 0; 0.5 0 -0.5];
        ItoSMatrix=[0.5 0.5 0.5 0.5; 1 0 -1 0; 0 1 0 -1];
    otherwise
        error(['PolType' polParams.polType ' not recognized.']);
end



% if(isa(polParams.polEndCallBack,'function_handle'))
%     polParams.polEndCallBack();
% end  

end
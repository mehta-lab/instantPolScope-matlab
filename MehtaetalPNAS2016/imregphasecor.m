function [moving_reg, affinemat, varargout]=...
    imregphasecor(fixed, moving, xaxis, yaxis, transformtype, varargin)
% imregphasecor Register images using phase-correlation.
% [moving_reg, affinemat, varargout]=...
%    imregphasecor(fixed, moving, xaxis, yaxis, transformtype, varargin)

%% Parsing of optional arguments. 
% Default optional arguments.
optargs={'pos','pixel',0};
% [cortype, corres, fillval]=optargs{:};  

% Three optional arguments. First is the correlation type and the second is
% the resolution.
if(length(varargin)>3)
    error('imregphasecor:argChk','The function accepts only three optional arguments.');
end

% Check that optional arguments are OK.
if(length(varargin)>0) %#ok<ISMT>
        if(~strcmpi(varargin{1}, 'pos') && ....
                ~strcmpi(varargin{1}, 'neg') &&...
                ~strcmpi(varargin{1}, 'dxdy'))
            warning('imregphasecor:wrongcorrelationtype',...
                'Correlation type must be ''pos'', ''neg'', or ''dxdy'', defaulting to ''pos''. ');
        else
            optargs(1)=varargin(1);
        end        
end

if(length(varargin)>1)
    
        if(~strcmpi(varargin{2}, 'pixel') && ....
                ~strcmpi(varargin{1}, 'subpixel'))
            warning('imregphasecor:wrongcorrelationtype',...
                'The second optional argument is either ''pixel''or ''subpixel'', defaulting to ''pixel''. ');
        else
           optargs(2)=varargin(2);
        end
end
 
if(length(varargin)>2)
    
        if(~isscalar(varargin{3}))
            warning('imregphasecor:wrongfillvalue',...
                'The third optional argument is the scalar fill value, defaulting to 0. ');
        else
            optargs(3)=varargin(3);
        end
end
 
% Assign the optional arguments
[cortype, corres, fillval]=optargs{:};  
% At this point phase-correlation only works at pixel resolution. Sub-pixel
% resolutin to be added to the phasecor function.


%% Write-out affine matrices for different transformations as function handles.
% I=[1 0 0;0 1 0; 0 0 1];
T=@(xt,yt) [1 0 0;0 1 0; xt yt 1];
R=@(theta) [cos(theta) -sin(theta) 0; sin(theta) cos(theta) 0; 0 0 1];
S=@(scale) [scale 0 0; 0 scale 0; 0 0 1];


% sampling in x and y.
xs=xaxis(2)-xaxis(1); ys=yaxis(2)-yaxis(1);
xdata=[xaxis(1) xaxis(end)]; ydata=[yaxis(1) yaxis(end)];
switch(transformtype)
    case 'translation' 
        %% Just the translation.
        switch(cortype)
            case {'pos','neg'}
              [xshift, yshift, cormap]=phasecor(fixed,moving,cortype,[xs ys]);
              varargout{1}=xshift;
              varargout{2}=yshift;
              varargout{3}=cormap;
            case {'dxdy'}
              [xshift, yshift, cormap, cormapOrig]=phasecor(fixed,moving,cortype,[xs ys]);
              varargout{1}=xshift;
              varargout{2}=yshift;
              varargout{3}=cormap;
              varargout{4}=cormapOrig;
        end
         affinemat=T(-xshift,-yshift);

    case 'similarity' 
        %% Combination of rotation, translation, scaling.
        
        if(strcmpi(cortype,'dxdy'))
             warning('Registration of rotation and scale between gradient images is not tested.');
        end
 

            % Register scaling and rotation.

            [scalecorr, thetacorr, cormapscalerot]=phasecorlogpolar(fixed,moving,xaxis,yaxis,cortype);
            affinemat_RS=R(thetacorr)*S(scalecorr);
            movingRS=imtransform(moving,maketform('affine',affinemat_RS),...
            'XData',xdata,'YData',ydata,'UData',xdata,'VData',ydata,...
            'FillValues',fillval); 
        %Notice that it is important to transform the image using correct domain (UData and VData).


            % Now register translation.
            [xshift,yshift,cormaptrans]=phasecor(fixed,movingRS,cortype,...
            [xs,ys]);
            varargout{1}=scalecorr;
            varargout{2}=thetacorr;
            varargout{3}=xshift;
            varargout{4}=yshift;
            varargout{5}=cormapscalerot;
            varargout{6}=cormaptrans;

            affinemat_T=T(-xshift,-yshift);

            affinemat=affinemat_RS*affinemat_T;
    case 'rigid'
        % combination of rotation and translation
            [thetacorr, cormaprot]=phasecorpolar(fixed,moving,xaxis,yaxis,cortype);
            affinemat_R=R(thetacorr);
            movingR=imtransform(moving,maketform('affine',affinemat_R),...
            'XData',xdata,'YData',ydata,'UData',xdata,'VData',ydata,...
            'FillValues',fillval);     
           
            % Now register translation.
            [xshift,yshift,cormaptrans]=phasecor(fixed,movingR,cortype,...
            [xs,ys]);
            varargout{1}=thetacorr;
            varargout{2}=xshift;
            varargout{3}=yshift;
            varargout{4}=cormaprot;
            varargout{5}=cormaptrans;

            affinemat_T=T(-xshift,-yshift);

            affinemat=affinemat_R*affinemat_T;
        
end

moving_reg=imtransformAffineMat(moving,affinemat,'cubic','coordinates','centered');

end

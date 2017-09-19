function out=imtransformAffineMat(in,affinemat,interpolation,varargin)
% out=imtransformAffineMat(in,affinemat,interpolation)
% Wrapper around imtransform that ensures that result of affine transform
% is in the same frame of reference as the input.

% Author and Copyright: Shalin Mehta, HFSP Postdoctoral Fellow
%                           Marine Biological Laboratory, Woods Hole, MA
%                           http://www.mshalin.com
% 

optargs.coordinates='centered';
optargs.PixSize=1;
if(~isempty(varargin))
    optargs=parsepropval(optargs,varargin{:});
end

switch(optargs.coordinates)
    case 'centered'
%         xdata=0.5*[-size(in,2) size(in,2)]*optargs.PixSize;
%         ydata=0.5*[-size(in,1) size(in,1)]*optargs.PixSize;
          xLims=0.5*[-size(in,2) size(in,2)];
          yLims=0.5*[-size(in,1) size(in,1)];
          R=imref2d(size(in),xLims,yLims);
    case 'matlab'
%         xdata=[1 size(in,2)]*optargs.PixSize;
%         ydata=[1 size(in,1)]*optargs.PixSize;
        R=imref2d(size(in));
end

fillval=min(in(:));
% out=imtransform(in,maketform('affine',affinemat),interpolation,...
%                 'XData',xdata,'YData',ydata,'UData',xdata,'VData',ydata,...
%                 'Size',size(in),'FillValues',fillval);
out=imwarp(in,R,affine2d(affinemat),interpolation,'Outputview',R,'FillValues',fillval);

%TODO: Find out why negative intensity occurs.
out(out<=0)=fillval;
end

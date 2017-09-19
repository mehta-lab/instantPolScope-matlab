function [x, y, cormap, varargout]=phasecor(imref,imreg,posneg,varargin)
% [ShiftX ShiftY CorMap <CorMapHilbert>]= phasecor(imref,imreg,posneg,<pixel size>)
% Using phase-correlation method, estimate translation (ShiftX, ShiftY) of
% image imreg with respect to imref. 
% posneg = 'pos' looks for maximum positive correlation
% and 'neg' looks for minimum correlation (useful when images are to be
% registed using strong negative corre    lation).
% Correlation map is returned as the third argument.
% To register the images apply (-ShiftX,-ShiftY) to imreg.
% <CoreMapHilbert> is an optional output argument that gives the original
% 'quad-peak' correlation map for gradient-registration.

% Limitations: Does not work properly with highly symmetric patterns such as
% checkerboard as the correlation map has multiple identical peaks.
% Check-out imregphasecorEvaluation script for development process behind
% this function.

% Enforce that both images are of the same size.
if(size(imref)~=size(imreg))
    error('phasecor:sizemismatch',...
        'Both images must be of the same size. I could pad them to be equal, but it is hard to judge what type of padding is apporpriate.');
end

% Set defaults for arguments that can be modified with varargin.

optargs.xs=1;
optargs.ys=1;
optargs.range=[0 0]; % 0 implies that any shift is acceptable. 
optargs.precision=1; %Precision for registration as a fraction of pixel size.

% If the first variable argument is numbers, assume that they are sampling
% distances in x and y directions.
if(~isempty(varargin))
    if (isvector(varargin{1}))
        optargs.xs=varargin{1}(1);
        optargs.ys=varargin{1}(2);
    else
        optargs=parsepropval(varargin{:});
    end
end




[h, w]=size(imref);
fftref=fft2(imref,optargs.precision*h,optargs.precision*w);
fftreg=fft2(imreg,optargs.precision*h,optargs.precision*w);
crossspec=fftreg.*conj(fftref); 
%The order matters. It decides whose shift we are computing. 
% Using imreg spectrum and conjugate of imref spectrum gives shift of imreg with
% respect to imref.

% IN REGISTERING df/dx and df/dy, we make use of the fact that spatial
% frequency variables cause odd magnitude in frequency domain after differentiation in space domain, and we
% divide by even symmetric absolute value. Thus, the resultant spectrum is
% sgn(fx)sgn(fy)exp(i2pi (fx x + fy y)).
absval=abs(crossspec);
absval(absval == 0) = eps; %Avoid divide by zero as it leads to NaNs.
crossspec=crossspec./absval;
%Move the zero to center so that we can compute positive and negative
%shifts easily.
cormap=real(fftshift(ifft2(crossspec))); 
%Occasionally correlation may not be entirely real. Taking absolute value
%is right as we want to be able to check for negative correlation.


% figure(1); 
% subplot(221); imagesc(imref); axis image; title('Reference image');
% subplot(222); imagesc(imreg); axis image; title('To be registered');
% subplot(223); imagesc(cormap); axis equal;

switch(posneg)
    case 'pos' %Find the maximum in the last row of the sortedcormap.
        [peaksrow, rowidx]=max(cormap,[],1);
        [~, colidx]=max(peaksrow);
        rowidx=rowidx(colidx);
        % Output the indices as variable arguments
        varargout{1}=colidx; % Index of peak along X.
        varargout{2}=rowidx; %Index of peak along Y.
    case 'neg'
        [peaksrow, rowidx]=min(cormap,[],1);
        [~, colidx]=min(peaksrow);
        rowidx=rowidx(colidx);
        % Output the indices as variable arguments
        varargout{1}=colidx; % Index of peak along X.
        varargout{2}=rowidx; %Index of peak along Y.        
    case 'dxdy'
        
        %Try detecting four peaks.
%         [sortedcormap rowsrtidx]=sort(cormap); 
% %Sorts cormap columnwise in ascending order. srtidx is the permutation vector along
% %columns.
%         colmin=sortedcormap(1,:);
%         colmax=sortedcormap(end,:);
%         % Separate min and max rows. The goal is to find pixel positions of
%         % two minimum values and two maximum values.
%         [sortrowmin colminsrtidx]=sort(colmin);
%         [sortrowmax colmaxsrtidx]=sort(colmax);
%         %Find positions of two maximas and two minimas.
%         cmin=colminsrtidx(1:2);
%         cmax=colmaxsrtidx(end-1:end); %Maximum values come last.
%         rmin=rowsrtidx(1,cmin);
%         rmax=rowsrtidx(end,cmax);
%         
%         %Compute row and column index of the translation individually using
%         %minimas and maximas.
%         rowidxmin=mean(rmin); 
%         colidxmin=mean(cmin); 
%         rowidxmax=mean(rmax);
%         colidxmax=mean(cmax);
%         
%         %Average to obtain better estimate.
%         rowidx=round(0.5*(rowidxmin+rowidxmax));
%         colidx=round(0.5*(colidxmin+colidxmax));
        
        % Try undoing the filtering as per equation. Divide by sign(x)sign(y).
        [h, w]=size(crossspec);
        hcen=floor(h/2)+1;
        wcen=floor(w/2)+1;
        hilb2dmask=ones(h,w); %Set all quadrants to 1.
        hilb2dmask(hcen,:)=0;
        hilb2dmask(:,wcen)=0;
        hilb2dmask(1:hcen-1,wcen+1:end) = -1; %Set second quadrant to -1.
        hilb2dmask(hcen+1:end,1:wcen-1)=-1; %Set fourth quadrant to -1.
        crossspech=crossspec.* ifftshift(hilb2dmask);
        varargout{1}=cormap; %Assign original correlationmap to variable argument.
        cormap=real(fftshift(ifft2(crossspech)));
        [peaksrow, rowidx]=max(cormap,[],1);
        [~, colidx]=max(peaksrow);
        rowidx=rowidx(colidx);
        % Output the indices as variable arguments
        varargout{2}=colidx; % Index of peak along X.
        varargout{3}=rowidx; %Index of peak along Y.
end



%Now compute position of min/max peak which directly gives shift of imreg
%w.r.t imref.

%X is along columns and Y is along rows.
xcenter=floor(w/2)+1; %Center of the sepctrum irrespective of whether h and w are odd or even.
ycenter=floor(h/2)+1;
x=optargs.xs*(colidx-xcenter); 
y=optargs.ys*(rowidx-ycenter);

%title(['xshift=' num2str(x) ',yshift=' num2str(y)]);
end
function [I0, I45, I90, I135]=...
    cropQuads(im,BoundingBox,BlackLevel)
% Crops and normalizes a quadrant image from real-time fluorescence
% polariztion microscop into individual polarization channels.

% Author and Copyright: Shalin Mehta, HFSP Postdoctoral Fellow
%                           Marine Biological Laboratory, Woods Hole, MA
%                           http://www.mshalin.com
% 
% License: Restricted academic use. 
% This software is free to use, but only with explicit permission by the
% author and only for academic purpose. This software constitutes a part of
% unpublished method for measuring orientation of single and ensemble of
% fluorophores.

    % Crop
    [idx, idy]=BoundingBoxToIndices(BoundingBox.I0);
    I0=im(idy,idx,:);
    [idx,idy]=BoundingBoxToIndices(BoundingBox.I45);
    I45=im(idy,idx,:);
    [idx,idy]=BoundingBoxToIndices(BoundingBox.I90);
    I90=im(idy,idx,:);
    [idx,idy]=BoundingBoxToIndices(BoundingBox.I135);
    I135=im(idy,idx,:);

%     minI0=min(I0(:));
%     minI45=min(I45(:));
%     minI90=min(I90(:));
%     minI135=min(I135(:));
%     
%     if (BlackLevel>minI0 || BlackLevel>minI45 || BlackLevel>minI90 || BlackLevel>minI135)
%         warning('RTFluorPol.cropQuads: The black level you have chosen leads to negative intensity, which are clipped.');
%     end

    BlackLevel=double(BlackLevel);
    I0=double(I0)-BlackLevel;
    I45=double(I45)-BlackLevel;
    I90=double(I90)-BlackLevel;
    I135=double(I135)-BlackLevel;
    
    I0(I0<1)=1; I45(I45<1)=1;
    I90(I90<1)=1; I135(I135<1)=1;

end


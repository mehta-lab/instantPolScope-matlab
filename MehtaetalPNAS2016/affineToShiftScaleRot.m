function [xshift,yshift, xscale,yscale,rotation] = affineToShiftScaleRot( affinemat )
% [xshift,yshift, xscale,yscale,rotation] = affineToShiftScaleRot( affinemat )
% It is assumed that co-efficients of the affine matrix represent the
% transformation in the order: Rotation, Scaling, Translation.
% That is the affine matrix is assumed to be R*S*T
% R.S.T=
% ( sxCost	-sySint	0
%   sxSint	syCost	0
%   xt      yt      1)

% We retrieve sx,sy,t,xt,yt based on above equation.

rotation=atan2(affinemat(2,1),affinemat(1,1));
xscale=sqrt(affinemat(1,1)^2+affinemat(2,1)^2);
yscale=sqrt(affinemat(1,2)^2+affinemat(2,2)^2);
xshift=affinemat(3,1);
yshift=affinemat(3,2);

end


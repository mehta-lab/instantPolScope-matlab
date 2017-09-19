function Mi=vectorFieldAdaptInterp(M,Pg,d0,polygon,mode,alpha)
% vectorFieldAdaptInterp interpolates a vector field on a user-specified grid with adaptive kernel support
%  
%   For a vector field v:  
%      Interpolation with a correlation matrix K : <v> = K * v      (convolution)
%      where:  K = sG*exp(-(dx^2+dy^2)/d0^2), sG = weigth vector
%  
%   SYNOPSIS   Mi=vectorFieldAdaptInterp(M,Pg,d0,polygon,mode)
%  
%   INPUT      M       : vector field, stored in a (nx4)-matrix of the form [y0 x0 y x]n
%                        (where (y0,x0) is the base and (y,x) is the tip of
%                        the vector).
%              Pg      : regular grid points, stored in a (mx2)-matrix of the form [yg xg]m.
%              d0      : parameter for the weight function G=exp(-D.^2/(1+d0^2)),
%                        where D is the distance matrix between all grid
%                        points and all vector (base) positions.
%                        d0 must be a scalar.
%              polygon : (optional - pass polygon=[] to disable). The interpolated vector
%                        can be cropped to remove vectors outside a given region of interest.
%                        To create the polygon use the functions ROIPOLY or
%                        GETLINE. These functions return the polygon vertices
%                        stored in two vectors y and x. Set polygon=[x y] to
%                        use with vectorFieldInterp.
%              mode    : [ 'div' | 'strain' ].
%                        If 'div' is passed, the divergence of the vector field is used to 
%                        locally adapt the value of d0; if 'strain' is passed, the Frobenius norm
%                        of the strain tensor of the vector field is used.
%              alpha   : (optional, default = 1) d0 is locally adapted as d0(x)/(1+alpha*(m(x)/max(m)), 
%                        where m(x) is either the divergence or the norm of the strain tensor at position x.
%  
%   OUTPUT     Mi      : interpolated vector field.
%  
%   DEPENDENCES          vectorFieldAdaptInterp uses { vectorFieldDiv;
%                                                      vectorFieldStrainTensor;
%                                                      updateD0FromDiv;
%                                                      vectorFieldInterp}
%                        vectorFieldAdaptInterp is used by { }
%  
%   Aaron Ponti, 08/23/2004
%
% Copyright (C) 2012 LCCB 
%
% This file is part of QFSM.
% 
% QFSM is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% QFSM is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with QFSM.  If not, see <http://www.gnu.org/licenses/>.
% 
% 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%
% CHECK INPUT PARAMETERS
%
% More accurate tests on the input parameters are performed by the called functions.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5

if nargin<5 | nargin>6
    error('Either 5 or 6 input parameters expected.');
end

if nargin==5
    alpha=1;
end

if prod(size(d0))~=1
    error('d0 must be a scalar.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%
% ADAPTIVE AVERAGE OF VECTOR FIELD
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5

if strcmp(mode,'div')
    
    % Calculate divergence of the vector field
    divM=vectorFieldDiv(M,Pg,d0,polygon);
    
    % Update d0 from local divergence
    d0Adapt=updateD0FromDiv(divM,d0,alpha,size(M,1),size(Pg,1));
    
elseif strcmp(mode,'strain')
    
    % Calculate strain tensor of the vector field
    [R,S]=vectorFieldStrainTensor(M,Pg,d0,polygon);
    
    % Calculate the Frobenius norm of the strain tensor S
    normS=zeros(size(S,3),3);
    for i=1:length(S)
        normS(i,1:3)=[Pg(i,:) norm(S(:,:,i),'fro')];
    end
    
    % Update d0 from local norm of strain tensor
    d0Adapt=updateD0FromDiv(normS,d0,alpha,size(M,1),size(Pg,1));
    
else
    error('''mode'' must be either ''div'' or ''strain''.');
end

% Interpolate vector field
Mi=vectorFieldInterp(M,Pg,d0Adapt,[]);


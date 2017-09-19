function d0=updateD0FromDiv(divM,d0in,alpha,nPi,nPg)
% updateD0FromDiv creates the matrix d0 to be used with the interpolator
%
% SYNOPSIS   d0=updateD0FromDiv(divM,d0,alpha,nPi,nPg)
%
% INPUT      divM : divergence as calculated by vectorFieldDiv; alternatively,
%                   the Frobenius norm of the strain tensor can be used as well 
%                   (see vectorFieldAdaptInterp).
%            d0in : initial d0. It can be a scalar or a (nPg x 1) vector 
%                   (as returned by this function).
%            alpha: see OUTPUT. alpha SHOULD be 0 < alpha <= 1, but may also 
%                   be set higher.
%            nPi  : OBSOLETE - this parameter is no longer used, it is maintained
%                   to assure compatibility.
%                   number of vectors prior of interpolation (raw data)
%                   (see vectorFieldInterp).
%            nPg  : number of grid points for interpolation
%                   (see vectorFieldInterp).
%
% OUTPUT    d0    : parameter d0 for the interpolator 
%                   (see vectorFieldInterpolator).
%                   At each position, d0 will be equal to 
%                   d0/(1+alpha/max(divM(all))*divM),
%                   where alpha is a parameter defining the range of
%                   variation possible for divM.
%                   d0 has size (nPg x 1).
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

% Check input parameters
if nargin~=5
    error('The function expects 5 input parameters.');
end
if size(divM,1)~=nPg
    error('Parameter nPg does not match the number of rows of divM');
end
if size(d0in)~=[1 1] & size(d0in)~=[nPg 1]
    error('The dimensions of d0 are wrong');
end
if alpha<=0
    error('The parameter alpha must be positive');
end

% Initialize d0
d0=zeros(nPg,1);

% Fill d0 to be used in the correlation matrix for the interpolator

divMax=max(abs(divM(:,3))); % Maximum (absolute) vector field divergence

if size(d0in,1)==1
    for i=1:nPg
        if divM(i,3)==0
            d0(i)=d0in;
        else
            d0(i)=d0in/(1+alpha*(abs(divM(i,3))/divMax));
        end
    end
else
    for i=1:nPg
        if divM(i,3)==0
            d0(i)=d0in(i);
        else
            d0(i)=doin(i)/(1+alpha*(abs(divM(i,3))/divMax));
        end
    end
end    

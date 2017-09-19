function pSpPos=propagateSpecklePositions(spPos,Mi,varargin)
% propagateSpecklePositions propagates speckle positions based on an interpolated vector field
%
% SYNOPSIS      pSpPos=propagateSpecklePositions(spPos,Mi,mode)
%
% INPUT         spPos      : n speckle positions saved in an (nx2) matrix [y x]n
%               Mi         : interpolated vector field saved in a (mx4) matrix
%                            [y0 x0 y x]m, where [y0 x0]m are the coordinates of 
%                            the interpolation points (see vectorFieldInterp)
%               mode       : (optional) either 'forward' or 'backward',
%                            defines whether the positions have to be forward 
%                            (next frame)- or backward (previous
%                            frame)-propagated.
%                            Default is 'forward'.
%
% OUTPUT        pSpPos     : propagated speckle positions [y x]n
%
% DEPENDENCES   propagateSpecklePositions uses { }
%               propagateSpecklePositions is used by { } 
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

% Aaron Ponti, January 3rd, 2003
% Sebastien Besson, June 2011
% Adapted from fsmTrackPropSpecklePos

% Check input parameters
ip = inputParser;
ip.addRequired('spPos',@(x) size(x,2)==2);
ip.addRequired('Mi',@(x) size(x,2)==4);
modes = {'backward','forward'};
ip.addOptional('mode','forward',@(x) any(strcmpi(x,modes)));
ip.addOptional('corLen',Inf,@isscalar);
ip.parse(spPos,Mi,varargin{:});
mode = ip.Results.mode;
corLen = ip.Results.corLen;

% Calculate vectors
v=[Mi(:,3)-Mi(:,1) Mi(:,4)-Mi(:,2)];
if strcmpi(mode,'backward'), v=-v; end

% Calculate all distances between speckles and interpolation points
D=KDTreeBallQuery(Mi(:,1:2),spPos,corLen);

% Initialize output pSpPos
pSpPos=zeros(size(spPos));

% Find points with no closest interpolation point 
emptyIndx = cellfun(@isempty,D);
pSpPos(emptyIndx,1:2)=spPos(emptyIndx,1:2);

% Propagate point using the coordinate of the closest interpolation point
pos = cellfun(@(x) x(1),D(~emptyIndx));
pSpPos(~emptyIndx,1:2)=spPos(~emptyIndx,1:2)+v(pos,:);

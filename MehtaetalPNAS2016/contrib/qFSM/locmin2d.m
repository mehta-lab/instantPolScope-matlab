function fImg = locmin2d(img, mask, keepFlat)
%LOCMIN2D searches for local minima in an image
%
%    SYNOPSIS fImg = locmin2d(img, mask, keepFlat)
%
%    INPUT    img    image matrix
%             mask   EITHER a scalar that defines the window dimensions
%                    OR a vector [m n] that defines the window dimensions
%                    OR a binary (0/1) structural element (matrix).
%                    Structural elements such as discs can be defined
%                    using the built-in matlab function "strel".
%                    The input matrix must have an odd number of columns and rows. 
%             keepFlat Optional input variable to choose whether to remove
%                      "flat" maxima or to keep them. Default is 0, to remove them.
%
%    OUTPUT   fImg   image with local minima (original values) and zeros elsewhere.
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

if nargin < 3 || isempty(keepFlat)
    keepFlat = 0;
end

fImg = -locmax2d(-img, mask, keepFlat);

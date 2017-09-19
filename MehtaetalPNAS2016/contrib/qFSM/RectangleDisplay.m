classdef RectangleDisplay < MovieDataDisplay
    %Concrete display class for displaying errors as circles
    % Adapated from fsmVectorAnalysis
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
    properties
        Color='r'; 
        LineStyle='-';
        LineWidth=2;
        Curvature=[0 0];
    end
    methods
        function obj=RectangleDisplay(varargin)
            obj@MovieDataDisplay(varargin{:})
        end
        function h=initDraw(obj,data,tag,varargin)
            h = arrayfun(@(i) rectangle('Position', [data(i,2)-data(i,4) data(i,1)-data(i,3) 2*data(i,4) 2*data(i,3)],...
                'Curvature', obj.Curvature, 'LineWidth',obj.LineWidth, 'EdgeColor',obj.Color,...
                'LineStyle', obj.LineStyle,varargin{:}), 1:size(data,1));
            set(h,'Tag',tag);
        end
        function updateDraw(obj,h,data)
            % Retrieve the tag
            tag=get(h(1),'Tag');
            
            % Delete extra plots handles
            delete(h(size(data,1)+1:end));
            h(size(data,1)+1:end)=[];
            
            % Update existing handles
            for i=1:min(numel(h),size(data,1))
                set(h(i),'Position',[data(i,2)-data(i,4) data(i,1)-data(i,3) 2*data(i,4) 2*data(i,3)]);
            end
            
            % Plot additional circles
            addIndx= min(numel(h),size(data,1))+1:size(data,1);
            h(addIndx) = arrayfun(@(i) rectangle('Position', [data(i,2)-data(i,4) data(i,1)-data(i,3) 2*data(i,4) 2*data(i,3)],...
                'Curvature', obj.Curvature, 'LineWidth',obj.LineWidth, 'EdgeColor',obj.Color,...
                'LineStyle', obj.LineStyle), addIndx);

            % Set tag
            set(h,'Tag',tag);
        end

    end    
    
    methods (Static)
        function params=getParamValidators()
            params(1).name='Color';
            params(1).validator=@ischar;
            params(2).name='LineStyle';
            params(2).validator=@ischar;
            params(3).name='LineWidth';
            params(3).validator=@isscalar;
            params(4).name='Curvature';
            params(4).validator=@isvector;
        end
        function f=getDataValidator()
            f=@(x) isempty(x) || size(x,2)==4 ;
        end
    end    
end

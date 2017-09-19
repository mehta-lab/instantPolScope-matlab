classdef SpeckleDisplay < MovieDataDisplay
    %Concreate display class for displaying speckles
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
        Markers={'o','^','s','d'};
        MarkerSize = 6;
        Color='r';        
    end
    methods
        function obj=SpeckleDisplay(varargin)
            obj@MovieDataDisplay(varargin{:})
        end
        function h=initDraw(obj,data,tag,varargin)
            pos = vertcat(data.Lmax);
            order = [data.speckleType];
            h=-ones(numel(unique(order)),1);
            for i=unique(order)
                h(i)=plot(pos(order==i,2),pos(order==i,1),obj.Markers{i},...
                   'MarkerSize',obj.MarkerSize,'MarkerEdgeColor',obj.Color);%,'MarkerFaceColor',colors(i,:));
            end
            set(h,'Tag',tag);
        end
        function updateDraw(obj,h,data)
            tag=get(h(1),'Tag');
            pos = vertcat(data.Lmax);
            order = [data.speckleType];
            orderMax=max(unique(order));
            for i=1:min(numel(h),orderMax)
                set(h(i),'XData',pos(order==i,2),'YData',pos(order==i,1),...
                    'Marker',obj.Markers{i});%,'MarkerFaceColor',colors(i,:))
            end
            
            for i=numel(h)+1:orderMax
                h(i)=plot(pos(order==i,2),pos(order==i,1),obj.Markers{i},...
                    'MarkerSize',obj.MarkerSize,'MarkerEdgeColor',obj.Color);%,'MarkerFaceColor',colors(i,:));
                set(h,'Tag',tag);
            end           
            
            delete(h(orderMax+1:end));
        end
    end    
    
    methods (Static)
        function params=getParamValidators()
            params(1).name='Markers';
            params(1).validator=@iscell;
            params(2).name='Color';
            params(2).validator=@ischar;
            params(3).name='MarkerSize';
            params(3).validator=@isscalar;
        end

        function f=getDataValidator()
            f=@isstruct;
        end
    end    
end

function p = panel(fig, copy)

% p = panel(fig[, copy])
%
% construct a panel as the root panel of the specified
% figure, overwriting any existing panels associated with
% that figure. if copy is passed and evaluates to true, a
% panel pointing at the root panel associated with that
% figure is returned (rather than generating a new one that
% overwrites existing ones) - this is used by
% panel_resizefcn.m.

% IMPLEMENTATION NOTES
%
% due to the deficiencies in matlab's OO implementation,
% it is not possible to generate a true object that honors
% a sensible syntax yet allows full object functionality.
% specifically, member functions cannot operate on the
% object itself, only on a copy of it, so a call such as:
%
%   ax = panel.axis
%
% cannot affect the state of the object "panel". to get
% round this, this implementation stores all data in the
% UserData of the targeted figure, and only stores a
% reference to that data in the object itself. for the
% sake of code brevity, it is not possible (sort of
% therefore) to delete a panel object, only to discard a
% reference to it. this is not a problem.




% default panel reference
p = [];
p.fig = 0;
p.id = [];

% default panel object
[P, panelroot] = default;



% TWO CASES - are specified by matlab's class implementation

% NO ARGUMENTS - return a default panel (invalid, because
% it's not attached to a figure...) or attach to current
% figure if there is one
if nargin == 0
	fig = get(0,'CurrentFigure');
	if ~isempty(fig)
		p = panel(fig, false);
	else
		p = class(p, 'panel');
	end
	return
end

% PANEL OBJECT ARGUMENT - return the panel object
if nargin == 1 && isa(fig, 'panel')
	p = fig;
	return
end

% OTHER CASE - specified by us
if ~(isnumeric(fig) && isscalar(fig) && ishandle(fig) && strcmp(get(fig,'type'), 'figure'))
	error(['first argument must be a figure handle'])
end

% either get a reference to the figure's root panel...
if nargin >= 2 && copy
	p.fig = fig;
	ud = get(fig, 'UserData');
	if ~isfield(ud, 'panels')
		error('that figure has no panel objects');
	end
	p.id = ud.panels{1}.panel.id;

% or create the figure's root panel, overwriting anything
% already there...
else
	p.fig = fig;

	% clear anything already there
	ud = get(fig, 'UserData');
	if isfield(ud, 'panels')
		ud = rmfield(ud, 'panels');
	end
	set(fig, 'UserData', ud);

	% set new panel
	p = setpanel(p, P);
	
	% and lay in the extras
	set(gcf,'ResizeFcn',@panel_resizefcn)
	ud = get(fig, 'UserData');
	ud.panelroot = panelroot;
	set(gcf,'UserData',ud)

end

% make into a class
p = class(p, 'panel');

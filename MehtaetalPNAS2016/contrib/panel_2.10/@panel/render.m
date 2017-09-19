function render(p)

% render(p)
%
% render the panel "p" (which must be a root panel). if
% "autorender" is on, this is called automatically with
% every change to a panel. if not, you will need to call
% this manually once you have finished building your figure,
% before your changes will be rendered.

% data we'll compute once and pass to sub-render
renderer = [];

% if figure has been destroyed, don't bother
if ~ishandle(p.fig)
	warning('not rendering deleted figure panels');
	return
end

% get figure width and height on screen
switch get(p.fig,'Units')
	case 'pixels'
		dpi = 96;
		pp = get(p.fig,'position');
		renderer.size_fig_mm = pp(3:4) / dpi * 25.4;
	otherwise
		error(['case not coded (Units=' get(gcf,'Units') ')']);
end

% can only call render on root panel
[P, root] = getpanel(p);
if P.panel.parent
	error('can only call render() on root panel');
end

if root.print
	% render for printing rather than for screen display
	switch get(p.fig, 'PaperUnits')
		case 'inches'
			conv = 25.4;
		case 'centimeters'
			conv = 10;
		case 'points'
			conv = 0.35278;
		otherwise
			error(['case not coded (PaperUnits=' get(gcf,'PaperUnits') ')']);
	end
	pp = get(p.fig, 'PaperPosition');
	renderer.size_fig_mm = pp(3:4) * conv;
end

% start by rendering into whole client area [l b w h]
renderer.into = [0 0 1 1];

% get units
renderer.units = subsref(p, 'units');

% call subroutine
P = getpanel(p);
subrender(p, P, renderer)


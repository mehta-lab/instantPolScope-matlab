function out = setpanel(p, P, panelroot)

% set a panel object from the panel reference
u = get(p.fig, 'UserData');

% if nothing there, or we're overwriting, set to empty array
% of panels
if ~isfield(u, 'panels')
	u.panels = {};
end

% if index unspecified, generate new unique index
if isempty(p.id)
	id = 1;
	for n = 1:length(u.panels)
		if u.panels{n}.panel.id >= id
			id = u.panels{n}.panel.id + 1;
		end
	end
	p.id = id;
	P.panel.id = id;
end

% find index amongst existing panels
index = length(u.panels) + 1;
for n = 1:length(u.panels)
	if u.panels{n}.panel.id == p.id
		index = n;
		break
	end
end

% lay it in to the UserData
u.panels{index} = P;

% lay in root data
if nargin >= 3
	u.panelroot = panelroot;
end

% lay in to figure
set(p.fig, 'UserData', u);

% return it
if nargout
	out = p;
end

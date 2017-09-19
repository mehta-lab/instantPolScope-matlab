function [P, panelroot] = getpanel(p)

% get a panel object from the panel reference
u = get(p.fig, 'UserData');
if ~isfield(u, 'panels')
	error(['panel "' int2str(p.id) '" not found in figure "' num2str(p.fig) '"'])
end

% find index amongst existing panels
index = length(u.panels) + 1;
for n = 1:length(u.panels)
	if u.panels{n}.panel.id == p.id
		P = u.panels{n};
		panelroot = u.panelroot;
		return
	end
end

% else error
error(['panel "' int2str(p.id) '" not found in figure "' num2str(p.fig) '"'])

function delete(p)

% delete(p)
%
% clear all contents of the panel, p, and delete p, too.

% access parent object
P = getpanel(p);

% delete children
q = p;
for ch = P.panel.children
	q.id = ch;
	delete(q);
end
P.panel.children = [];

% delete axis
if P.panel.axis && ishandle(P.panel.axis)
	delete(P.panel.axis)
end

% access its parent
if P.panel.parent
	
	% delete me in my parent
	q = p;
	q.id = P.panel.parent;
	Q = getpanel(q);
	f = Q.panel.children == p.id;
	if sum(f) ~= 1
		error('internal error');
	end
	Q.panel.children = Q.panel.children(~f);
	setpanel(q, Q);
	
	% delete me in the panels array
	u = get(p.fig, 'UserData');
	index = [];
	for n = 1:length(u.panels)
		if u.panels{n}.panel.id == p.id
			index = n;
			break
		end
	end
	if isempty(index)
		error('internal error')
	end
	u.panels = u.panels([1:index-1 index+1:end]);
	set(p.fig, 'UserData', u);
	
else
	
	% else, we're deleting the root panel for this figure
	set(p.fig, 'ResizeFcn', '');
	ud = get(p.fig, 'UserData');
	ud = rmfield(ud, 'panels');
	set(p.fig, 'UserData', ud);
	
end




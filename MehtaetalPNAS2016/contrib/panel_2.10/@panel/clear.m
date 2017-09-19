function clear(p)

% clear(p)
%
% clear all contents of the panel, p.

% access parent object
P = getpanel(p);

% delete children
q = p;
for ch = P.panel.children
	q.id = ch;
	delete(q);
end
P.panel.children = [];

% clear axis
if P.panel.axis && ishandle(P.panel.axis)
	delete(P.panel.axis)
end

% return parent object
setpanel(p, P);

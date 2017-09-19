function ax_out = select(p)

% select(p)
%
% make axis associated with this panel the active axis for
% plotting. if no axis is associated, create one if valid.
% that is, calling select on an "uncommitted" panel commits
% that panel as an "axis panel".

P = getpanel(p);

if P.panel.axis
	
	% return existing axis
	ax = P.panel.axis;
	set(0,'CurrentFigure',p.fig)
	set(p.fig,'CurrentAxes',ax);

else

% 	% illegal if root
% 	if ~P.panel.parent
% 		error('cannot add axis to root panel (pack a child panel and select that instead)');
% 	end

	% illegal if children
	if ~isempty(P.panel.children)
		error('cannot add axis to panel with children');
	end

	% create axis
	ax = axes('fontname', subsref(p,'fontname'), 'fontsize', subsref(p,'fontsize'));
	set(0,'CurrentFigure',p.fig)
	set(p.fig,'CurrentAxes',ax);
	P.panel.axis = ax;
	setpanel(p, P);

end

if nargout
	ax_out = ax;
end


% autorender
if subsref(p, 'autorender')
	p.id = 1;
	render(p)
end

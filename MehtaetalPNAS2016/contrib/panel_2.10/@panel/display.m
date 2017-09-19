function display(p)

% disp([10 'panel: (' num2str(p.fig) ', ' int2str(p.id) ')' 10])
disp([10 '(Panel Object)'])

if isnumeric(p.fig) && isscalar(p.fig) && ishandle(p.fig) && strcmp(get(p.fig,'type'), 'figure')

	[P, panelroot] = getpanel(p);
	
	sect('Figure Properties');
	disp(panelroot)
	
	sect('Panel Logical Properties');
	disp(P.panel)
	
	sect('Panel Render Properties (inherited)');
	disp(P.render_inh)
	
	sect('Panel Render Properties (not inherited)');
	disp(P.render_notinh)
	
	disp(' ')
	
else
	
	warning('panel is not attached to an existing figure')
	disp(' ')
	
end


function sect(msg)

disp(' ')
disp([msg ':'])
% disp('________________________________');
% disp(' ')

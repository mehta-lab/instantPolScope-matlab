function p = subsasgn(p, s, val)

if ischar(s)
	s = struct('type','.','subs',s);
end

switch s(1).type
	
	case '.'
		
		key = s(1).subs;
		[P, panelroot] = getpanel(p);
	
		switch key
			
			case 'fontsize'
				
				% must be right
				if ~isnumeric(val) || ~isscalar(val) || val < 1 || val > 100
					error('invalid value for "fontsize"');
				end
				
				P.render_inh.fontsize = val;
				setpanel(p, P);
			
			case {'fontname' 'fontweight'}
				
				if ~ischar(val) || (ndims(val)~=2) || (size(val,1)~=1)
					error(['invalid value for "' key '"']);
				end
				
				P.render_inh.(key) = val;
				setpanel(p, P);
			
			case 'edge'
				
				% must be right
				if ~ischar(val) || ~isscalar(val) || ~any(val == 'lrtb')
					error('invalid value for "edge"');
				end
				
				P.render_inh.edge = val;
				setpanel(p, P);
			
			% margins must be translated into mm for storage
			case {'axismargin' 'parentmargin'}
				
				u = subsref(p, 'units');
				switch u
					case 'mm'
						% no change
					case 'cm'
						val = val * 10;
					case 'in'
						val = val * 25.4;
				end
				P.render_inh.(key) = val;
				setpanel(p, P);
				
			% properties that are *not* inherited
			case {'title', 'xlabel', 'ylabel', 'xscale', 'yscale'}
				
				P.render_notinh.(key) = val;
				setpanel(p, P);
				
			case {'autorender' 'units' 'rootmargin' 'print'}
				
				if P.panel.parent
					error(['the property "' key '" is only of the root panel']);
				end
				
				switch key
					case {'autorender' 'print'}
						if ~islogical(val) || ~isscalar(val)
							error(['invalid value for "' key '"']);
						end
					case 'units'
						switch val
							case {'mm', 'in', 'cm'}
								% ok
							otherwise
								error(['invalid value for "' key '"']);
						end
					case {'rootmargin'}
						u = subsref(p, 'units');
						switch u
							case 'mm'
								% no change
							case 'cm'
								val = val * 10;
							case 'in'
								val = val * 25.4;
						end
				end
				
				panelroot.(key) = val;
				setpanel(p, P, panelroot);

				
				
			otherwise
				error(['unrecognised subsasgn "' s(1).subs '"']);
			
		end
	
end


% autorender
if subsref(p, 'autorender')
	q = p;
	q.id = 1;
	render(q)
end

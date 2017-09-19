function val = subsref(p, s, inheritation)

% special case for our subsref, we allow passing a
% string as s which is just the fieldname
if ischar(s)
	s = struct('type', '.', 'subs', s);
end

% we set a field when we call recursively
if nargin < 3
	inheritation = false;
end

% get a panel object from the panel reference
[P, panelroot] = getpanel(p);

% get whether the object is a parent or an axis
isparent = ~isempty(P.panel.children);
isaxis = P.panel.axis ~= 0;
isroot = P.panel.parent == 0;

% construct parent
if ~isroot
	parent = p;
	parent.id = P.panel.parent;
end

% all margins are % [l/b r/t] or [l b r t],
% like ordering to [x y w h] for abs
% positioning
default = [];
default.autorender = true;
default.units = 'mm';
default.rootmargin = [0 0 5 5];
default.axismargin = [15 15 0 0];
default.parentmargin = [0 0 0 0];
default.edge = 't';
default.fontname = 'arial';
default.fontsize = 10;
default.fontweight = 'normal';

% switch on key
switch s(1).type
	
	case '.'
		
		key = s(1).subs;
	
		switch key
			
			case 'figure'
				
				val = p.fig;
			
			case 'axis'
				
				val = P.panel.axis;
				
			case 'children'
				val = {};
				for c = 1:length(P.panel.children)
					p.id = P.panel.children(c);
					val{c} = p;
				end
			
			case 'select'
				if length(s)~=1
					error('invalid usage');
				end
				val = select(p);
				
			case 'render'
				if length(s)~=1
					error('invalid usage');
				end
				render(p);
				
			case 'pack'
				if length(s)~=2 || ~strcmp(s(2).type,'()')
					error('invalid usage');
				end
				val = pack(p, s(2:end).subs);
				return
				
			case 'export'
				if length(s)~=2 || ~strcmp(s(2).type,'()')
					error('invalid usage');
				end
				export(p, s(2:end).subs{:});
				return
				
			case {'axismargin' 'parentmargin'}
				
				val = P.render_inh.(key);
				
				% if no value yet, inherit further, or resort to default
				if isempty(val)
					if isroot
						val = default.(key);
					else
						val = subsref(parent, s, true);
					end
				end
				
				% if this is the final return value
				if ~inheritation
					
					% convert to interface units (all values stored in mm)
					u = subsref(p, 'units');
					switch u
						case 'mm'
							% no change
						case 'cm'
							val = val / 10;
						case 'in'
							val = val / 25.4;
					end
					
				end
				
				
			% properties that are inherited
			case {'edge', 'fontname', 'fontsize', 'fontweight'}

				val = P.render_inh.(key);
				if isempty(val)
					if isroot
						val = default.(key);
					else
						val = subsref(parent, s, true);
					end
				end
			
			% properties that are *not* inherited
			case {'title', 'xlabel', 'ylabel', 'xscale', 'yscale'}
				val = P.render_notinh.(key);
			
			% properties of the root panel
			case {'autorender' 'units' 'rootmargin'}

				val = panelroot.(key);
				if isempty(val)
					val = default.(key);
				end

				if strcmp(key, 'rootmargin')
					% convert to interface units (all values stored in mm)
					u = subsref(p, 'units');
					switch u
						case 'mm'
							% no change
						case 'cm'
							val = val / 10;
						case 'in'
							val = val / 25.4;
					end
				end

				
			otherwise
				error(['unrecognised operation "' s(1).subs '"']);
			
		end
	
		if length(s) > 1
			val = subsref(val, s(2:end));
		end
		
end


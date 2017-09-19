



%% SUBRENDER

function subrender(p, P, renderer)

% get specific margin
if P.panel.axis
	margin = subsref(p, 'axismargin');
else
	margin = subsref(p, 'parentmargin');
end

% root has extra margin
if ~P.panel.parent
	rootmargin = subsref(p, 'rootmargin');
	margin = margin + rootmargin;
end

% get fractional margin
size_panel_mm = renderer.size_fig_mm .* renderer.into(3:4); % size in mm of the panel we're rendering into
margin_as_panel_frac = tofrac(margin, size_panel_mm, renderer.units);

% reduce "into" by margin
renderer.into(1:2) = renderer.into(1:2) ...
	+ margin_as_panel_frac(1:2) .* renderer.into(3:4);
renderer.into(3:4) = renderer.into(3:4) ...
	- margin_as_panel_frac(1:2) .* renderer.into(3:4) ...
	- margin_as_panel_frac(3:4) .* renderer.into(3:4);

% handle separately parent panels and axis panels
if P.panel.axis
	subrender_axis(p, P, renderer);
else
	subrender_parent(p, P, renderer);
end









%% SUBRENDER_AXIS
%
% function returns the amount of space this axis needs
% on each side (in mm) to render all its parts (labels,
% etc.) in addition, it does all the layout for those
% labels. returns margin as [l b r t].

function margin = subrender_axis(p, P, renderer)

% metrics
label_c = 1; % fixed gap associated with title
label_m = 1.5;

% assume zero
margin = [0 0 0 0];

% font metrics
fontname = subsref(p, 'fontname');
fontsize = subsref(p, 'fontsize');
fontweight = subsref(p, 'fontweight');
set(P.panel.axis, 'fontname', fontname);
set(P.panel.axis, 'fontsize', fontsize);
set(P.panel.axis, 'fontweight', fontweight);

% title
title = P.render_notinh.title;
h = get(P.panel.axis, 'title');
set(h, 'FontName', fontname, ...
	'FontSize', fontsize, ...
	'FontWeight', fontweight, ...
	'string', title);
% if ~isempty(title)
% 	margin(4) = margin(4) + fontsize * label_m / 72 * 25.4 + label_c;
% end

% render specials
for xy = 'xy'

	suffix = P.render_notinh.([xy 'scale']);
	tick = get(P.panel.axis, [xy 'tick']);
	tickLabelSuffix = '';

	if any(suffix == '$')
		useSuffixOnTickLabels = true;
		suffix = suffix(suffix ~= '$');
	else
		useSuffixOnTickLabels = false;
	end

	if isempty(suffix)

		mult = 1;

	else

		if length(suffix) ~= 1
			error(['error in scale argument "' suffix '"']);
		end

		suffixes = 'yzafpnum kMGTPEZY';

		if suffix == '?'

			% auto scale
			m = floor(log10(max(abs(tick))) / 3);
			m = m + 9;
			if m < 1 m = 1; end
			if m > length(suffixes) m = length(suffixes); end
			suffix = suffixes(m);

		end

		i = find(suffixes == suffix);
		if isempty(i)
			error(['error in scale argument "' suffix '"']);
		end
		mult = 1000 ^ (i - 9);

		if useSuffixOnTickLabels
			tickLabelSuffix = suffix;
		end

	end

	tick = tick / mult;
	ticklabel = {};
	longestticklabel = 0;
	for n = 1:length(tick)
		ticklabel{n} = [sprintf('%g', tick(n)) tickLabelSuffix];
		if length(ticklabel{n}) > longestticklabel
			longestticklabel = length(ticklabel{n});
		end
	end
	set(P.panel.axis, [xy 'ticklabel'], ticklabel);

	h = get(P.panel.axis, [xy 'label']);
	label = subsref(p, [xy 'label']);
	s = strfind(label, '$');
	if ~isempty(s)
		if suffix == 'u'
			suffix = '\mu';
		end
		label = strrep(label, '$', suffix);
	end
	set(h, 'FontName', fontname, ...
				 'FontSize', fontsize, ...
				 'FontWeight', fontweight, ...
				 'string', label);

%  if ~isempty(label)
% 		switch xy
% 			case 'x'
% 				ax = 2;
% 			case 'y'
% 				ax = 1;
% 				ticklabelspace = longestticklabel * fontsize * 0.4 * label_m / 72 * 25.4;
% 				labelspace = fontsize * label_m / 72 * 25.4 + label_c;
% 				margin(ax) = ticklabelspace + labelspace;
% 		end
% 	end

end


%%%% could return the margin at this point (end first pass)
%%%% so that caller could calculate margins across a whole
%%%% packed panel, and then call us back to do the second
%%%% pass, below:


% check we've space to render and do so
if renderer.into(1) >= 0 & renderer.into(1) < 1 & renderer.into(2) >= 0 & renderer.into(2) < 1 & renderer.into(3) > 0 & renderer.into(3) <= 1 & renderer.into(4) > 0 & renderer.into(4) <= 1
	set(P.panel.axis, 'position', renderer.into);
else
	disp('WARNING (panel): failed to render an axis due to size limitations')
end







%% SUBRENDER_PARENT

function subrender_parent(p, P, renderer)

% if any child uses absolute positioning, all must
used_abs = false;
used_rel = false;
N = length(P.panel.children);
c = p;
C = {};
for n = 1:N
	c.id = P.panel.children(n);
	C{n} = getpanel(c);
	if isscalar(C{n}.panel.pack)
		used_rel = true;
	else
		used_abs = true;
	end
end
if used_rel && used_abs
	error('cannot use relative and absolute positioning amongst the children of a single panel');
end

% assign space to each of its children
if used_abs

	% do assignments
	renderer2 = renderer;
	for n = 1:N
		pack = tofrac(C{n}.panel.pack, renderer.size_fig_mm, renderer.units); % convert percentage to fraction
		packed = [];
		packed(1:2) = renderer.into(1:2) + pack(1:2) .* renderer.into(3:4);
		packed(3:4) = renderer.into(3:4) .* pack(3:4);
		c.id = P.panel.children(n);
		renderer2.into = packed;
		subrender(c, C{n}, renderer2)
	end
	
end

if used_rel

	% convert edge to axis and end
	edges = 'lbrt';
	edge = find(P.render_inh.edge == edges);
	if isempty(edge)
		error(['unrecognised packing edge "' P.render_inh.edge '" (use l, r, t or b)']);
	end
	axs = [1 2 1 2];
	ax = axs(edge);
	eds = [1 1 2 2];
	ed = eds(edge);
	
% 	% ask each axis child to render (first pass)
% 	% maximise margins that match up (if packing on top or
% 	% bottom edge, that's the left and right margins, and vice
% 	% versa).
% 	max_margin = [0 0];
% 	margins = {};
% 	match_indices = {[2 4] [1 3]};
% 	for n = 1:N
% 		if C{n}.panel.axis
% 			margin = subrender_axis_first(c, C{n});
% 			margins{n} = margin;
% 			match_margin = margin(match_indices{ax});
% 			max_margin = max(max_margin, match_margin);
% 		else
% 			margins{n} = [0 0 0 0];
% 		end
% 	end
	
	% size in mm of the "into" space we're rendering into
	size_into_mm = renderer.size_fig_mm .* renderer.into(3:4);
	
	% assignments
	assignments = zeros(1,N);
	
	% assign to each child
	for n = 1:N
		pack = C{n}.panel.pack;
		assignments(n) = tofrac(pack, renderer.size_fig_mm(ax), renderer.units);
	end

	% divvy up remaining space
	n = find(assignments == 0);
	if ~isempty(n)
		S = sum(assignments);
		M = length(n);
		if S >= 1
			warning('no space left to divvy up');
		else
			assignments(n) = (1 - S) / M;
		end
	end

	% convert to scale of parent position
	assignments = assignments * renderer.into(ax + 2);

	% pack from near edge
	if ed == 1
		for n = 1:N
			renderer.into(ax + 2) = assignments(n);
			c.id = P.panel.children(n);
			subrender(c, C{n}, renderer);
			renderer.into(ax) = renderer.into(ax) + assignments(n);
		end
	end
	
	% pack from far edge
	if ed == 2
		renderer.into(ax) = renderer.into(ax) + renderer.into(ax + 2);
		for n = 1:N
			renderer.into(ax) = renderer.into(ax) - assignments(n);
			renderer.into(ax + 2) = assignments(n);
			c.id = P.panel.children(n);
			subrender(c, C{n},renderer);
		end
	end
	
end






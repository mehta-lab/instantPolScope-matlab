function q = pack(p, args)

% q = pack(p, args)
%
% pack a new panel, q, into an existing panel, p. q can be
% packed "relatively", in which case it takes up some of p
% along the edge specified in "p.edge", and the amount of
% space it takes up away from that edge is specified (either
% as a percentage or as an absolute value). or, q can be
% packed "absolutely", in which case you specify it's absolute
% positioning within p in your desired units.
%
% "args", a cell array, may include, in any order:
%
% 'mm', 'in', 'cm', '%': specify units to use when interpreting numeric
%   packing argument (default '%')
%
% [<numeric>]: (scalar numeric) amount of parent panel to
%   use for child panel (e.g. [50] to use half, assuming
%   percentage packing).
%
% [<numeric>]: (1x4 numeric) amount of parent panel to use
%   for child panel, specified in absolute terms as [l b w h].
%
% note that, when using percentage packing, numbers between
% 0 and 1 are automatically interpreted as fractions, rather
% than percentages (i.e. they are multiplied by 100 before
% use).

% access parent object
P = getpanel(p);
if P.panel.axis
	error('cannot pack panel that already has an axis');
end

% create child object
Q = default;
Q.panel.parent = p.id;
Q.panel.pack = 0; % zero means auto-pack

% default argument form
form = '%';
flags = 'sf';

% interpret arguments
for n = 1:length(args)
	
	arg = args{n};
	
	% form
	if ischar(arg) && ~islogical(getform(arg))
		form = getform(arg);
		continue
	end
	
	% packing space specified relatively
	if isnumeric(arg) && isscalar(arg)
		if Q.panel.pack
			error('packing specified twice');
		end
		Q.panel.pack = storeform(arg, form, flags);
		continue
	end
	
	% packing space specified absolutely
	if isnumeric(arg) && ndims(arg)==2 && all(size(arg) == [1 4])
		if Q.panel.pack
			error('packing specified twice');
		end
		Q.panel.pack = storeform(arg, form, flags);
		continue
	end
	
	% unrecognised
	disp(arg)
	error('unrecognised argument above')
	
end

% create child reference
q = p;
q.id = [];

% add child to figure
q = setpanel(q, Q);

% add child to parent
P.panel.children(end+1) = q.id;
setpanel(p, P);

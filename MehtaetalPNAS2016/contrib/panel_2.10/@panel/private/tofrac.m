function f = tofrac(val, space_mm, units)


% convert a value as a percentage or in some
% real-world units into a fraction of the
% specified space. if val is +ve, it is
% interpreted as being in the units of this
% context. if it is -ve, it is interpreted as a
% percentage. if it is imaginary, it is
% interpreted as being in mm, regardless of the
% context units.
%
% if value is more than scalar, space_mm will be
% iterated over, e.g.
%
% tofrac([10 20 30 40], [50 100])
%
% will return...
%
% f = [0.2 0.2 0.6 0.4]


f = val;

for n = 1:length(f)
	if f(n) < 0
		f(n) = -f(n) / 100;
	elseif imag(f(n))
		f(n) = imag(f(n)) / space_mm(mod(n-1,length(space_mm))+1);
	else
		switch units
			case 'mm'
				f(n) = f(n) / space_mm(mod(n-1,length(space_mm))+1);
			case 'cm'
				f(n) = (f(n) * 10) / space_mm(mod(n-1,length(space_mm))+1);
			case 'in'
				f(n) = (f(n) * 25.4) / space_mm(mod(n-1,length(space_mm))+1);
			otherwise
				error('internal error - unrecognised units')
		end
	end
end

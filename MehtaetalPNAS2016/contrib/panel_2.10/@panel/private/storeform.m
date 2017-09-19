function f = storeform(val, form, flags)


% convert a value in some form (%, mm, cm, in)
% into a storable form (either -ve for percentages
% or +ve for mm).
%
% flags can include any of:
%
%   's'trict (don't allow percentages outside
%     0-100)
%
%   'f'ractions (allow percentages less than or
%     equal to 1% to be interpreted as fractions)


switch(form)

	case 'mm'
		f = val;
		
	case 'cm'
		f = val * 10;
		
	case 'in'
		f = val * 25.4;
		
	case '%'
		if any(flags == 's')
			if any(val < 0) || any(val > 100)
				error(['invalid percentage "' num2str(val) '"']);
			end
		end
		if any(flags == 'f')
			if all(val <= 1)
				val = val * 100;
			end
		end
		f = -val;
	
	otherwise
		error('case not coded')
	
end

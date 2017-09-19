function form = getform(arg)

switch arg
	case 'mm'
		form = 'mm';
	case 'in'
		form = 'in';
	case 'cm'
		form = 'cm';
	case '%'
		form = '%';
	otherwise
		form = false;
end

function export(p, varargin)

% export(p, ...)
%
% export the panel "p" to an image file.
% additional arguments may be the filename (any
% string not beginning "-") or an option string,
% beginning with a "-" character, followed by an
% option character, followed by the option data.
% if you do not specify the filename extension,
% one will be added for you suitable to the output
% format. if you do not specify a filename, the
% name "export" will be used.
%
% export sizing should usually be achieved using
% the "paper model". therein, you specify the
% target (how much of one column on a piece of
% paper), the orientation, and the resolution
% (dpi), and the size is worked out for you
% automagically. options concerned with
% controlling the paper model are as follows.
%
% PAPER MODEL:
%
% -p paper type, A2-A6, letter (default is A4)
% -l landscape mode (default is portrait)
% -m margins in mm [specify 1 (all), 2 (x and y)
%    or 4 (left, bottom, right, top)] (default is 20mm all
%    round)
% -i inter-column space in mm (default is 5mm)
% -c number of columns (default is 1)
% -f fill [(w)hole, (tt)wo thirds, (h)alf,
%    (t)hird, (q)uarter, (s)quare, or -f.<number>]
%    to fill a specified fractional part of the
%    available space (default is whole)
%
% the procedure is to choose the size of paper
% that is targeted (and its orientation), to
% specify the unused margins around the edge (if
% you specify 4 margins, the left-right and
% top-bottom sums will be the figures used to
% deduce the size of the "printable" paper
% region), to specify the number of columns (and
% inter-columns space if more than one), and
% finally to dictate how much of the height of one
% of those columns you want the figure to occupy.
% note that no room is left automatically for a
% caption. if the paper model is unsatisfactory,
% you can specify the width and height explicitly,
% in which case all paper model options are
% ignored.
%
% ALTERNATIVE TO PAPER MODEL:
%
% -w explicit width (default is to use paper model)
% -h explicit height (default is to use paper model)
%
% finally, a few options are provided to control
% how the prepared figure is exported. note that
% dpi below 150 is not recommended except for
% sizing drafts, since font and line sizes are not
% rendered even vaguely accurately in some cases.
%
% EXPORT:
%
% -rd (draft) 75 dpi
% -rn (normal) 150 dpi (default)
% -rf (final) 300 dpi
% -rx (extreme) 600 dpi
% -r# (custom) as specified, must be 75-2400
%    note that extreme is probably overkill even for
%    camera-ready, hence the name.
% -s print sideways (default is to print upright)
% -o output format [eps, png (default)]
%
% EXAMPLES:
%
% simple export of a sizing draft (75dpi) to fill
% a page of A4 leaving no room for a caption, as a
% png file:
%
% export(p, '-rd', 'myfig')
%
% default export of a figure that is targeted to
% fill all of one of two columns on a piece of
% landscape A5, leaving 15% of the column for the
% caption:
%
% export(p, '-pA5', '-l', '-c2', '-f.85')

P = getpanel(p);

% default arguments
pars = [];
pars.fmt = 'png';
pars.dpi = 150;
pars.paper = 'A4';
pars.landscape = false;
pars.fill = 1;
pars.cols = 1;
pars.intercolumnspacing = 5;
pars.margins = 20;
pars.file = 'export';
pars.sideways = false;
pars.width = 0;
pars.height = 0;

% interpret arguments
for n = 2:nargin
	
	arg = varargin{n-1};
	
	if ischar(arg)
		
		if arg(1) == '-'
			switch arg(2)
				
				case 'p'
					% paper type
					switch(arg(3:end))
						case {'A0', 'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'letter'}
							pars.paper = arg(3:end);
							continue
					end
					
				case 'l'
					% landscape paper mode
					pars.landscape = true;
					continue
				
				case 'f'
					% fill
					switch(arg(3:end))
						case 'w' % whole
							pars.fill = 1;
							continue
						case 'tt' % two thirds
							pars.fill = 2/3;
							continue
						case 'h' % half
							pars.fill = 1/2;
							continue
						case 't' % third
							pars.fill = 1/3;
							continue
						case 'q' % quarter
							pars.fill = 1/4;
							continue
						case 's' % square
							pars.fill = 0;
							continue
					end
					if arg(3) == '.'
						pars.fill = str2num(arg(3:end));
						continue
					end
					
				case 'c'
					% number of columns
					pars.cols = str2num(arg(3:end));
					continue
					
				case 'm'
					% margins (mm)
					pars.margins = str2num(arg(3:end));
					sz = size(pars.margins);
					if ~(ndims(sz) == 2 && sz(1) == 1 && (sz(2) == 1 || sz(2) == 2 || sz(2) == 4))
						error('invalid margins (should be 1x1, 2, or 4)')
					end
					continue
					
				case 'i'
					% inter-column space (mm)
					pars.intercolumnspacing = str2num(arg(3:end));
					continue
					
				case 'r'
					% resolution
					if length(arg) == 3
						f = find('dnfx' == arg(3));
						if ~isempty(f)
							dpis = [75 150 300 600];
							pars.dpi = dpis(f);
							continue
						end
					else
						pars.dpi = str2num(arg(3:end));
						if pars.dpi < 75 | pars.dpi > 2400
							error(['illegal DPI (must be 75-2400)']);
						end
						continue
					end
					
				case 'w'
					% explicit width
					pars.width = str2num(arg(3:end));
					continue
				
				case 'h'
					% explicit height
					pars.height = str2num(arg(3:end));
					continue
				
				case 's'
					% print sideways
					pars.sideways = true;
					continue
					
				case 'o'
					% output format
					pars.fmt = arg(3:end);
					continue

			end
		else
			pars.file = arg;
			continue
		end

		error(['unrecognised argument "' arg '"']);
		
		end

end

% make sure filename has extension
if ~any(pars.file == '.')
	pars.file = [pars.file '.' pars.fmt];
end

% get space for figure
switch pars.paper
	case 'A0'
		sz = [841 1189];
	case 'A1'
		sz = [594 841];
	case 'A2'
		sz = [420 594];
	case 'A3'
		sz = [297 420];
	case 'A4'
		sz = [210 297];
	case 'A5'
		sz = [148 210];
	case 'A6'
		sz = [105 148];
	case 'letter'
		sz = [216 279];
	otherwise
		error(['unrecognised paper size "' pars.paper '"'])
end

% orientation of paper
if pars.landscape
	sz = fliplr(sz);
end

% paper margins (can be specified as singlet, doublet, or
% quadruplet)
if length(pars.margins) == 1
	margins = [2 2] * pars.margins;
elseif length(pars.margins) == 2
	margins = 2 * pars.margins;
elseif length(pars.margins) == 4
	margins = pars.margins(1:2) + pars.margins(3:4);
else
	error('invalid margins');
end
sz = sz - margins;

% divide by columns
w = (sz(1) + pars.intercolumnspacing) / pars.cols - pars.intercolumnspacing;
sz(1) = w;

% divide by fill
if pars.fill
	% ratio
	sz(2) = sz(2) * pars.fill;
else
	% square
	sz(2) = sz(1);
end

% orientation of figure is upright, unless printing
% sideways, in which case the printing space is rotated
% too
if pars.sideways
	set(p.fig, 'PaperOrientation', 'landscape')
	sz = fliplr(sz);
else
	set(p.fig, 'PaperOrientation', 'portrait')
end

% explicit measurements override automatics
if pars.width
	sz(1) = pars.width;
end
if pars.height
	sz(2) = pars.height;
end

% set size of figure
set(p.fig, 'PaperUnits', 'centimeters');
set(p.fig, 'PaperPosition', [0 0 sz] / 10);
psz = sz / 25.4 * pars.dpi;
disp(['exporting to ' int2str(sz(1)) 'x' int2str(sz(2)) 'mm (' int2str(psz(1)) 'x' int2str(psz(2)) 'px)'])

% get output flag for print
switch pars.fmt
	case 'png'
		dev = '-dpng';
	case 'eps'
		dev = '-depsc2';
end

% print to file
ar = subsref(p, 'autorender');
subsasgn(p, 'autorender', false);
subsasgn(p, 'print', true); % renderer will know to do anything print-specific (resets automatically to false after one use)
w = warning('off');
render(p)
print(dev, ['-r' int2str(pars.dpi)], pars.file)
warning(w);
subsasgn(p, 'print', false);
render(p)
drawnow
subsasgn(p, 'autorender', ar);

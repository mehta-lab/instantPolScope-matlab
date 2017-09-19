function maximizefig(fig)
% MAXIMIZE Size a window to fill the entire screen.
%
% maximize(HANDLE fig)
%  Will size the window with handle fig such that it fills the entire screen.
%

% Author: Shalin Mehta, shalin.mehta@gmail.com
% Marine Biological Laboratory, Woods Hole, MA 02543.

if nargin==0, fig=gcf; end

jFrame = get(fig,'JavaFrame');
jFrame.setMaximized(true);

end
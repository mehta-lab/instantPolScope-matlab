function panel_resizefcn(varargin)

% this stub gets the root panel from the callback
% figure and calls render() on it

p = panel(gcbo, true);
render(p);

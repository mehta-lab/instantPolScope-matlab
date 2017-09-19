function [P, panelroot] = default

% default panel object
P = [];

% default root object



%% ROOT PROPERTIES

panelroot.autorender = [];
panelroot.units = [];            % interface units ('cm'entimetres, 'mm'illimetres, 'in'ches)
panelroot.rootmargin = [];       % extra margins around root panel [l b r t]

% internal states
panelroot.print = false;				% if true, render appropriately (might not do anything currently, but is set in export.m)



%% PANEL PROPERTIES

P.panel.id = '';

% all panels except the root have a parent panel and
% packing instructions into their parent
P.panel.parent = 0;        % index of parent in panels array of this figure (zero for root panel)
P.panel.pack = 0;          % packing parameters for this panel within its parent (zero means auto-pack)

% a panel either has an associated axis, children, or
% neither (but not both!)
P.panel.axis = 0;          % handle to associated axis or zero if no axis
P.panel.children = [];     % list of children or empty if no children



%% RENDER PROPERTIES (INHERITED)

% inherited properties that are distance metrics
P.render_inh.axismargin = [];
P.render_inh.parentmargin = [];

% inherited properties
P.render_inh.edge = 't';        % edge to pack on (l, b, r or t)
P.render_inh.fontname = [];
P.render_inh.fontsize = [];
P.render_inh.fontweight = [];



%% RENDER PROPERTIES (NOT INHERITED)

% axis properties
P.render_notinh.title = '';
P.render_notinh.xlabel = '';
P.render_notinh.ylabel = '';
P.render_notinh.xscale = '';
P.render_notinh.yscale = '';




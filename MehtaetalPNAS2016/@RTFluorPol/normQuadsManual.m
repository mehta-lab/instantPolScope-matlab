function normQuadsManual(self,I0,I45,I90,I135,varargin)
% normQuadsManual(RTFluorPol Object,I0,I45,I90,I135,'Parameter',value)
% Optional arguments 
%   Parameter           Value
%   'normRange'        2-value vector [minNorm maxNorm].
%   'normROI'          Isotropic ROI known to have low anisotropy.



%% Assign defaults to optional arguments
optargs.normRange=[0.8 1.2];
optargs.normROI=[1 1 self.quadWidth self.quadHeight];
optargs.Parent=NaN; % Parent UIPanel or 
optargs.normEndCallBack=NaN; % Specifying this callback allows custom action - such as updating of GUI, when normalization is over.
optargs.normalizeExcitation=false; % This option is silently ignored.
optargs.WaitForClose=false; % Set true if running from script and need to wait for user to finish normalizaiton step manually.
optargs=parsepropval(optargs,varargin{:});

% If no callback is specified, the figure is closed when Done button is pressed.
if(~isa(optargs.normEndCallBack, 'function_handle'))
    optargs.normEndCallBack=@closefunction;
end
if(optargs.normalizeExcitation)
    error('Manual normalization of excitation is not implemented so far');
end
%% Initialize variables here so that they are accessible to all nested callbacks. and handles accessible to all callbacks.
I0=double(I0); I45=double(I45); I90=double(I90); I135=double(I135);

Inorm45=I45*self.NormI45;
Inorm90=I90*self.NormI90;
Inorm135=I135*self.NormI135;
[Orient,Aniso]=ComputeFluorAnisotropy(I0,Inorm45,Inorm90,Inorm135,'anisotropy','ItoSMatrix',self.ItoSMatrix);
Orient=(180/pi)*Orient;

%% Draw the UI elements and initialize normalization factors to those found in the object.
if(isnan(optargs.Parent))
    hdl.mainfig = togglefig('Manual adjustment to normalization',1);
    jFrame = get(handle(hdl.mainfig),'JavaFrame');
    jFrame.setMaximized(true);
    set(hdl.mainfig,'CloseRequestFcn',@closefunction,...
        'defaultaxesfontsize',12,'Units','normalized','Toolbar','figure');
else
    hdl.mainfig=optargs.Parent;
    delete(get(hdl.mainfig,'Children'));
end

hdl.a45=axes('Units','normalized','Position',[0.02 0.5 0.25 0.4],'Parent',hdl.mainfig);
hdl.a90=axes('Units','normalized','Position',[0.3 0.5 0.25 0.4],'Parent',hdl.mainfig);
hdl.a135=axes('Units','normalized','Position',[0.6 0.5 0.25 0.4],'Parent',hdl.mainfig);
hdl.aAniso=axes('Units','normalized','Position',[0.02 0.01 0.25 0.4],'Parent',hdl.mainfig);
hdl.aOrient=axes('Units','normalized','Position',[0.3 0.01 0.25 0.4],'Parent',hdl.mainfig);
hdl.aOrientHist=axes('Units','normalized','Position',[0.6 0.01 0.25 0.4],'Parent',hdl.mainfig);


hdl.CmapTitle=uicontrol('Parent',hdl.mainfig,...
    'Style', 'text',...
    'String','Colormap',...
    'Units','normalized',...
    'Position',[0.86 0.88 0.05 0.02],...
    'FontSize',12);

hdl.popCmap=uicontrol('Parent',hdl.mainfig,...
    'Style', 'popupmenu',...
       'String', {'gray','hot','cool','bone','jet'},...
       'Units','normalized',...
       'Position', [0.86 0.84 0.06 0.04],...
        'FontSize',12,...
       'Callback', @setcmap);  


 [hdl.I45ControlS,hdl.I45ControlP,hdl.I45ControlE]=sliderPanel(...
    'Parent',hdl.mainfig,...
    'Title','Norm factor: I45',...
    'Position',[0.86 0.7 0.12 0.1],...
    'Min',optargs.normRange(1),...
    'Max',optargs.normRange(2),...
    'Value',self.NormI45,...
    'SliderStep',[0.005 0.005],...
    'FontSize',12,...
    'Callback',@updatenorm);

[hdl.I90ControlS,hdl.I90ControlP,hdl.I90ControlE]=sliderPanel(...
    'Parent',hdl.mainfig,...
    'Title','Norm factor: I90',...
    'Position',[0.86 0.55 0.12 0.1],...
    'Min',optargs.normRange(1),...
    'Max',optargs.normRange(2),...
    'Value',self.NormI90,...
    'SliderStep',[0.005 0.005],...
    'FontSize',12,...
    'Callback',@updatenorm);

[hdl.I135ControlS,hdl.I135ControlP,hdl.I135ControlE]=sliderPanel(...
    'Parent',hdl.mainfig,...
    'Title','Norm factor: I135',...
    'Position',[0.86 0.4 0.12 0.1],...
    'Min',optargs.normRange(1),...
    'Max',optargs.normRange(2),...
    'Value',self.NormI135,...
    'SliderStep',[0.005 0.005],...
    'FontSize',12,...
    'Callback',@updatenorm);

   hdl.buttondone=uicontrol('Parent',hdl.mainfig,...
       'Style','pushbutton',...
       'String','Done',...
       'Units','normalized',...
       'Position',[0.86 0.02 0.04 0.04],...
        'FontSize',12,...
       'Callback',optargs.normEndCallBack);

%% Initialize the axes.
setcmap();

% Initialize color limits and keep them constant.
Ilims= @(I)[min(abs(I(:))) max(abs(I(:)))]; 
Alims=Ilims(imcrop(Aniso,optargs.normROI));
DiffPer=@(I1,I2) 100*abs((I2-I1)./I1);

axes(hdl.a45);
hdl.I45=imagesc(DiffPer(I0,Inorm45),[0 5]); axis equal; 
title('$\frac{I45-I0}{I0} \,\%$','interpreter','latex'); 
colorbar;
rectangle('Position',optargs.normROI,'EdgeColor','Blue');

axes(hdl.a90);
hdl.I90=imagesc(DiffPer(I0,Inorm90),[0 5]); axis equal; 
title('$\frac{I90-I0}{I0} \,\%$','interpreter','latex'); 
 colorbar;
rectangle('Position',optargs.normROI,'EdgeColor','Blue');

axes(hdl.a135);
hdl.I135=imagesc(DiffPer(I0,Inorm135),[0 5]); axis equal; 
title('$\frac{I135-I0}{I0} \,\%$','interpreter','latex'); 
 colorbar;
rectangle('Position',optargs.normROI,'EdgeColor','Blue');

axes(hdl.aAniso);
hdl.IAniso=imagesc(Aniso,Alims); axis equal;
title('Anisotropy'); colorbar;
rectangle('Position',optargs.normROI,'EdgeColor','Blue');

axes(hdl.aOrient);
hdl.IOrient=imagesc(Orient,[0 180]); axis equal;
title('Orientation'); colorbar;

axes(hdl.aOrientHist);
[counts,levels]=hist(Orient(:),180);
hdl.histOrient=stem(levels,counts);
title('Histogram of orientation image'); axis tight;

linkaxes([hdl.a45 hdl.a90 hdl.a135 hdl.aAniso hdl.aOrient ]);

%%%%%%%%%%    Callbacks  %%%%%%%%%%%%

%% update: callback for all controls, update the object and axes.
function updatenorm(~,~,~) 
%update is the callback for all sliders.

% Update normalization factors.
self.NormI45=get(hdl.I45ControlS,'value');
self.NormI90=get(hdl.I90ControlS,'value');
self.NormI135=get(hdl.I135ControlS,'value');

% update the images displayed on axes.
Inorm45=I45*self.NormI45;
Inorm90=I90*self.NormI90;
Inorm135=I135*self.NormI135;
[Orient,Aniso]=ComputeFluorAnisotropy(I0,Inorm45,Inorm90,Inorm135,'anisotropy','ItoSMatrix',self.ItoSMatrix);
Orient=(180/pi)*Orient;

% I set Cdata instead of redrawing images so that any axes properties
% set by the user are not reset.
set(hdl.I45,'CData',DiffPer(I0,Inorm45));
set(hdl.I90,'CData',DiffPer(I0,Inorm90));
set(hdl.I135,'CData',DiffPer(I0,Inorm135));
set(hdl.IAniso,'CData',Aniso);
set(hdl.IOrient,'CData',Orient);
[counts,levels]=hist(Orient(:),180);
set(hdl.histOrient,'XData',levels,'YData',counts);

end

%% setcmap: set the colormap for figure.
    function setcmap(~,~,~) 
        list=get(hdl.popCmap,'String');
        value=get(hdl.popCmap,'value');
         colormap(eval(list{value}));
    end
%% closefunction: closes the figure.
function closefunction(~,~,~)
  % close GUI
  delete(hdl.mainfig); 
end

if(optargs.WaitForClose)
 waitfor(hdl.mainfig);
end

end
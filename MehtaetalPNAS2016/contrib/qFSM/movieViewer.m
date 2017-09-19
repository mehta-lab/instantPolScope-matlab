function mainFig = movieViewer(MO,varargin)

ip = inputParser;
ip.addRequired('MO',@(x) isa(x,'MovieObject'));
ip.addOptional('procId',[],@isnumeric);
ip.addParamValue('movieIndex',0,@isscalar);
ip.parse(MO,varargin{:});

% Check existence of viewer
%
% Copyright (C) 2012 LCCB 
%
% This file is part of QFSM.
% 
% QFSM is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% QFSM is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with QFSM.  If not, see <http://www.gnu.org/licenses/>.
% 
% 
h=findobj(0,'Name','Viewer');
if ~isempty(h), delete(h); end
mainFig=figure('Name','Viewer','Position',[0 0 200 200],...
    'NumberTitle','off','Tag','figure1','Toolbar','none','MenuBar','none',...
    'Color',get(0,'defaultUicontrolBackgroundColor'),'Resize','off',...
    'DeleteFcn', @(h,event) deleteViewer());
userData=get(mainFig,'UserData');

if isa(ip.Results.MO,'MovieList')
    userData.ML=ip.Results.MO;
    userData.movieIndex=ip.Results.movieIndex;
    if userData.movieIndex~=0
        userData.MO=ip.Results.MO.getMovies{userData.movieIndex};
    else
         userData.MO=ip.Results.MO;
    end
        
    userData.procId = ip.Results.procId;
    if ~isempty(ip.Results.procId)
        procId = userData.MO.getProcessIndex(class(userData.ML.processes_{ip.Results.procId}));
    else
        procId = ip.Results.procId;
    end
else
    userData.MO=ip.Results.MO;
%     userData.MO=ip.Results.MO;
    procId=ip.Results.procId;
end

% Classify movieData processes by type (image, overlay, movie overlay or
% graph)
validProcId= find(cellfun(@(x) ismember('getDrawableOutput',methods(x)) &...
    x.success_,userData.MO.processes_));
validProc=userData.MO.processes_(validProcId);

getOutputType = @(type) cellfun(@(x) any(~cellfun(@isempty,regexp({x.getDrawableOutput.type},type,'once','start'))),...
    validProc);

isImageProc =getOutputType('image');
imageProc=validProc(isImageProc);
imageProcId = validProcId(isImageProc);
isOverlayProc =getOutputType('[oO]verlay');
overlayProc=validProc(isOverlayProc);
overlayProcId = validProcId(isOverlayProc);
isGraphProc =getOutputType('[gG]raph');
graphProc=validProc(isGraphProc);
graphProcId = validProcId(isGraphProc);

% Create series of anonymous function to generate process controls
createProcText= @(panel,i,j,pos,name) uicontrol(panel,'Style','text',...
    'Position',[10 pos 250 20],'Tag',['text_process' num2str(i)],...
    'String',name,'HorizontalAlignment','left','FontWeight','bold');
createOutputText= @(panel,i,j,pos,text) uicontrol(panel,'Style','text',...
    'Position',[40 pos 200 20],'Tag',['text_process' num2str(i) '_output'...
    num2str(j)],'String',text,'HorizontalAlignment','left');
createProcButton= @(panel,i,j,k,pos) uicontrol(panel,'Style','radio',...
    'Position',[200+30*k pos 20 20],'Tag',['radiobutton_process' num2str(i) '_output'...
    num2str(j) '_channel' num2str(k)]);
createChannelBox= @(panel,i,j,k,pos,varargin) uicontrol(panel,'Style','checkbox',...
    'Position',[200+30*k pos 20 20],'Tag',['checkbox_process' num2str(i) '_output'...
    num2str(j) '_channel' num2str(k)],varargin{:});
createMovieBox= @(panel,i,j,pos,name,varargin) uicontrol(panel,'Style','checkbox',...
    'Position',[40 pos 200 25],'Tag',['checkbox_process' num2str(i) '_output'...
    num2str(j)],'String',[' ' name],varargin{:});
createInputBox= @(panel,i,j,k,pos,name,varargin) uicontrol(panel,'Style','checkbox',...
    'Position',[40 pos 200 25],'Tag',['checkbox_process' num2str(i) '_output'...
    num2str(j) '_input' num2str(k)],'String',[' ' name],varargin{:});
createInputInputBox= @(panel,i,j,k,l,pos,varargin) uicontrol(panel,'Style','checkbox',...
    'Position',[200+30*l pos 20 20],'Tag',['checkbox_process' num2str(i) '_output'...
    num2str(j) '_input' num2str(k) '_input' num2str(l)],varargin{:});


panel1 = uipanel('Parent',mainFig,'BorderType','none');
panel2 = uipanel('Parent',panel1,'BorderType','none');
s=uicontrol('Style','Slider','Parent',mainFig,...
'Units','normalized','Position',[0.95 0 0.05 1],...
'Value',1,'SliderStep',[.02,.2],'Callback',{@slider_callback,panel2});

%% Image panel creation

if isa(userData.MO,'MovieData')
    imagePanel = uibuttongroup(panel2,'Position',[0 0 1/2 1],...
        'Title','Image','BackgroundColor',get(0,'defaultUicontrolBackgroundColor'),...
        'Units','pixels','Tag','uipanel_image');
    
    hPosition=createImageOptions(imagePanel,userData);
    
    % Create controls for switching between process image output
    hPosition=hPosition+50;
    nProc = numel(imageProc);
    for iProc=nProc:-1:1;
        output=imageProc{iProc}.getDrawableOutput;
        validChan = imageProc{iProc}.checkChannelOutput;
        validOutput = find(strcmp({output.type},'image'));
        for iOutput=validOutput(end:-1:1)
            createOutputText(imagePanel,imageProcId(iProc),iOutput,hPosition,output(iOutput).name);
            arrayfun(@(x) createProcButton(imagePanel,imageProcId(iProc),iOutput,x,hPosition),...
                find(validChan));
            hPosition=hPosition+20;
        end
        createProcText(imagePanel,imageProcId(iProc),iOutput,hPosition,imageProc{iProc}.getName);
        hPosition=hPosition+20;
    end
    
    % Create controls for selecting channels (raw image)
    hPosition=hPosition+10;
    uicontrol(imagePanel,'Style','radio','Position',[10 hPosition 200 20],...
        'Tag','radiobutton_channels','String',' Raw image','Value',1,...
        'HorizontalAlignment','left','FontWeight','bold');
    arrayfun(@(i) uicontrol(imagePanel,'Style','checkbox',...
        'Position',[200+30*i hPosition 20 20],...
        'Tag',['checkbox_channel' num2str(i)],'Value',i<4,...
        'Callback',@(h,event) redrawChannel(h,guidata(h))),...
        1:numel(userData.MO.channels_));
    
    hPosition=hPosition+20;
    uicontrol(imagePanel,'Style','text','Position',[120 hPosition 100 20],...
        'Tag','text_channels','String','Channels');
    arrayfun(@(i) uicontrol(imagePanel,'Style','text',...
        'Position',[200+30*i hPosition 20 20],...
        'Tag',['text_channel' num2str(i)],'String',i),...
        1:numel(userData.MO.channels_));    
else
    imagePanel=-1;
end

%% Overlay panel creation
if ~isempty(overlayProc)
    overlayPanel = uipanel(panel2,'Position',[1/2 0 1/2 1],...
        'Title','Overlay','BackgroundColor',get(0,'defaultUicontrolBackgroundColor'),...
        'Units','pixels','Tag','uipanel_overlay');
    
    % Create overlay options
    hPosition=10;
    hPosition=createVectorFieldOptions(overlayPanel,userData,hPosition);
    hPosition=createTrackOptions(overlayPanel,userData,hPosition);
    hPosition=createWindowsOptions(overlayPanel,userData,hPosition);
    
    % Create controls for selecting overlays
    hPosition=hPosition+50;
    nProc = numel(overlayProc);
    for iProc=nProc:-1:1;
        output=overlayProc{iProc}.getDrawableOutput;
        
        % Create checkboxes for movie overlays
        validOutput = find(strcmp({output.type},'movieOverlay'));
        for iOutput=validOutput(end:-1:1)
            createMovieBox(overlayPanel,overlayProcId(iProc),iOutput,hPosition,output(iOutput).name,...
                'Callback',@(h,event) redrawOverlay(h,guidata(h)));
            hPosition=hPosition+20;
        end
        
        % Create checkboxes for channel-specific overlays
        validOutput = find(strcmp({output.type},'overlay'));
        for iOutput=validOutput(end:-1:1)
            validChan = overlayProc{iProc}.checkChannelOutput;
            createOutputText(overlayPanel,overlayProcId(iProc),iOutput,hPosition,output(iOutput).name);
            arrayfun(@(x) createChannelBox(overlayPanel,overlayProcId(iProc),iOutput,x,hPosition,...
                'Callback',@(h,event) redrawOverlay(h,guidata(h))),find(validChan));
            hPosition=hPosition+20;
        end
        createProcText(overlayPanel,overlayProcId(iProc),iOutput,hPosition,overlayProc{iProc}.getName);
        hPosition=hPosition+20;
    end
    
    if ~isempty(overlayProc)
        uicontrol(overlayPanel,'Style','text','Position',[120 hPosition 100 20],...
            'Tag','text_channels','String','Channels');
        arrayfun(@(i) uicontrol(overlayPanel,'Style','text',...
            'Position',[200+30*i hPosition 20 20],...
            'Tag',['text_channel' num2str(i)],'String',i),...
            1:numel(userData.MO.channels_));
    end
else
    overlayPanel=-1;
end

%% Add additional panel for independent graphs
if ~isempty(graphProc) 
    graphPanel = uipanel(panel2,'Position',[0 0 1 1],...
        'Title','Graph','BackgroundColor',get(0,'defaultUicontrolBackgroundColor'),...
        'Units','pixels','Tag','uipanel_graph');
    hPosition3=10;
    
    hPosition3 = createScalarMapOptions(graphPanel,userData,hPosition3);

    hPosition3=hPosition3+50;

    % Create controls for selecting all other graphs
    nProc = numel(graphProc);
    for iProc=nProc:-1:1;
        output=graphProc{iProc}.getDrawableOutput;
        if isa(graphProc{iProc},'SignalProcessingProcess');
            input=graphProc{iProc}.getInput;
            nInput=numel(input);
            
            % Create set of boxes for correlation graphs (input/input)
            validOutput = graphProc{iProc}.checkOutput;
            for iOutput=size(validOutput,3):-1:1
                for iInput=nInput:-1:1
                    createOutputText(graphPanel,graphProcId(iProc),iInput,hPosition3,input(iInput).name);
                    for jInput=1:iInput
                        if validOutput(iInput,jInput,iOutput)
                            createInputInputBox(graphPanel,graphProcId(iProc),iOutput,iInput,jInput,hPosition3,...
                                'Callback',@(h,event) redrawSignalGraph(h,guidata(h)));
                        end
                    end
                    hPosition3=hPosition3+20;
                end
                createProcText(graphPanel,graphProcId(iProc),iInput,hPosition3,output(iOutput).name);
                hPosition3=hPosition3+20;
            end

        else   
            % Create boxes for movie -specific graphs
            validOutput = find(strcmp({output.type},'movieGraph'));
            for iOutput=validOutput(end:-1:1)
                createMovieBox(graphPanel,graphProcId(iProc),iOutput,hPosition3,...
                    output(iOutput).name,'Callback',@(h,event) redrawGraph(h,guidata(h)));
                hPosition3=hPosition3+20;
            end
            
            % Create boxes for channel-specific graphs
            validOutput = find(strcmp({output.type},'graph'));
            for iOutput=validOutput(end:-1:1)
                validChan = graphProc{iProc}.checkChannelOutput();
                createOutputText(graphPanel,graphProcId(iProc),iOutput,hPosition3,output(iOutput).name);
                arrayfun(@(x) createChannelBox(graphPanel,graphProcId(iProc),iOutput,x,hPosition3,...
                    'Callback',@(h,event) redrawGraph(h,guidata(h))),find(validChan));
                hPosition3=hPosition3+20;
            end
            
            % Create boxes for sampled graphs
            validOutput = find(strcmp({output.type},'sampledGraph'));
            for iOutput=validOutput(end:-1:1)
                validChan = graphProc{iProc}.checkChannelOutput();
                createOutputText(graphPanel,graphProcId(iProc),iOutput,hPosition3,output(iOutput).name);
                arrayfun(@(x) createChannelBox(graphPanel,graphProcId(iProc),iOutput,x,hPosition3,...
                    'Callback',@(h,event) redrawGraph(h,guidata(h))),find(validChan(iOutput,:)));
                hPosition3=hPosition3+20;
            end
            
            % Create boxes for sampled graphs
            validOutput = find(strcmp({output.type},'signalGraph'));
            for iOutput=validOutput(end:-1:1)
                input=graphProc{iProc}.getInput;      
                validInput = find(graphProc{iProc}.checkOutput());
%                 createOutputText(graphPanel,graphProcId(iProc),iOutput,hPosition3,output(iOutput).name);
                for iInput=fliplr(validInput)
                    createInputBox(graphPanel,graphProcId(iProc),iOutput,iInput,hPosition3,...
                        input(iInput).name,'Callback',@(h,event) redrawGraph(h,guidata(h)));
                    hPosition3=hPosition3+20;
                end
            end
            
            createProcText(graphPanel,graphProcId(iProc),iOutput,hPosition3,graphProc{iProc}.getName);
            hPosition3=hPosition3+20;
        end
       
    end
    
    if ~isempty(graphProc) && isa(userData.MO,'MovieData')
        uicontrol(graphPanel,'Style','text','Position',[120 hPosition3 100 20],...
            'Tag','text_channels','String','Channels');
        arrayfun(@(i) uicontrol(graphPanel,'Style','text',...
            'Position',[200+30*i hPosition3 20 20],...
            'Tag',['text_channel' num2str(i)],'String',i),...
            1:numel(userData.MO.channels_));
    end
else
    graphPanel=-1;
end

%% Get image/overlay panel size and resize them
imagePanelSize = getPanelSize(imagePanel);
overlayPanelSize = getPanelSize(overlayPanel);
graphPanelSize = getPanelSize(graphPanel);
panelsLength = max(500,imagePanelSize(1)+overlayPanelSize(1)+graphPanelSize(1));
panelsHeight = max([imagePanelSize(2),overlayPanelSize(2),graphPanelSize(2)]);

% Resize panel
if ishandle(imagePanel)
    set(imagePanel,'Position',[10 panelsHeight-imagePanelSize(2)+10 ...
        imagePanelSize(1) imagePanelSize(2)],...
        'SelectionChangeFcn',@(h,event) redrawImage(guidata(h)))
end
if ishandle(overlayPanel)
    set(overlayPanel,'Position',[imagePanelSize(1)+10 panelsHeight-overlayPanelSize(2)+10 ...
        overlayPanelSize(1) overlayPanelSize(2)]);
end
if ishandle(graphPanel)
    set(graphPanel,'Position',[imagePanelSize(1)+overlayPanelSize(1)+10 ...
        panelsHeight-graphPanelSize(2)+10 ...
        graphPanelSize(1) graphPanelSize(2)])
end

%% Create movie panel
moviePanel = uipanel(panel2,...
    'Title','','BackgroundColor',get(0,'defaultUicontrolBackgroundColor'),...
    'Units','pixels','Tag','uipanel_movie','BorderType','none');

hPosition=10;

if isa(userData.MO,'MovieData')
    % Create control button for exporting figures and movie (cf Francois' GUI)
    uicontrol(moviePanel, 'Style', 'togglebutton','String', 'Run movie',...
        'Position', [10 hPosition 100 20],'Callback',@(h,event) runMovie(h,guidata(h)));
    uicontrol(moviePanel, 'Style', 'checkbox','Tag','checkbox_saveFrames',...
        'Value',0,'String', 'Save frames','Position', [150 hPosition 100 20]);
    uicontrol(moviePanel, 'Style', 'checkbox','Tag','checkbox_saveMovie',...
        'Value',0,'String', 'Save movie','Position', [250 hPosition 100 20]);
    uicontrol(moviePanel, 'Style', 'popupmenu','Tag','popupmenu_movieFormat',...
        'Value',1,'String', {'MOV';'AVI'},'Position', [350 hPosition 100 20]);
    

    
    % Create controls for scrollling through the movie
    hPosition = hPosition+30;
    uicontrol(moviePanel,'Style','text','Position',[10 hPosition 50 15],...
        'String','Frame','Tag','text_frame','HorizontalAlignment','left');
    uicontrol(moviePanel,'Style','edit','Position',[70 hPosition 30 20],...
        'String','1','Tag','edit_frame','BackgroundColor','white',...
        'HorizontalAlignment','left',...
        'Callback',@(h,event) redrawScene(h,guidata(h)));
    uicontrol(moviePanel,'Style','text','Position',[100 hPosition 40 15],...
        'HorizontalAlignment','left',...
        'String',['/' num2str(userData.MO.nFrames_)],'Tag','text_frameMax');
    
    uicontrol(moviePanel,'Style','slider',...
        'Position',[150 hPosition panelsLength-160 20],...
        'Value',1,'Min',1,'Max',userData.MO.nFrames_,...
        'SliderStep',[1/double(userData.MO.nFrames_)  5/double(userData.MO.nFrames_)],...
        'Tag','slider_frame','BackgroundColor','white',...
        'Callback',@(h,event) redrawScene(h,guidata(h)));
end
% Create movie location edit box
hPosition = hPosition+30;
uicontrol(moviePanel,'Style','text','Position',[10 hPosition 40 20],...
    'String','Movie','Tag','text_movie');


if isa(ip.Results.MO,'MovieList')
    moviePaths = cellfun(@getDisplayPath,userData.ML.getMovies,'UniformOutput',false);
    movieIndex=0:numel(moviePaths);
    
    uicontrol(moviePanel,'Style','popupmenu','Position',[60 hPosition panelsLength-110 20],...
        'String',vertcat(getDisplayPath(ip.Results.MO),moviePaths'),'UserData',movieIndex,...
        'Value',find(userData.movieIndex==movieIndex),...
        'HorizontalAlignment','left','BackgroundColor','white','Tag','popup_movie',...
        'Callback',@(h,event) switchMovie(h,guidata(h)));
    if userData.movieIndex==0, set(findobj(moviePanel,'Tag','text_movie'),'String','List'); end
    
else
    uicontrol(moviePanel,'Style','edit','Position',[60 hPosition panelsLength-110 20],...
        'String',getDisplayPath(ip.Results.MO),...
        'HorizontalAlignment','left','BackgroundColor','white','Tag','edit_movie');

end

% Add help button
hAxes = axes('Units','pixels','Position',[panelsLength-50 hPosition  48 48],...
    'Tag','axes_help', 'Parent', moviePanel);
icons = loadLCCBIcons();
Img = image(icons.questIconData);
set(hAxes, 'XLim',get(Img,'XData'),'YLim',get(Img,'YData'), 'visible','off','YDir','reverse');
set(Img,'ButtonDownFcn',@icon_ButtonDownFcn, 'UserData', struct('class','movieViewer'));

% Add copyrigth
hPosition = hPosition+30;
uicontrol(moviePanel,'Style','text','Position',[10 hPosition panelsLength-100 20],...
    'String',userfcn_softwareConfig(),'Tag','text_copyright',...
    'HorizontalAlignment','left');



% Get overlay panel size
moviePanelSize = getPanelSize(moviePanel);
moviePanelHeight =moviePanelSize(2);

%% Resize panels and figure
sz=get(0,'ScreenSize');
maxWidth = panelsLength+20;
maxHeight = panelsHeight+moviePanelHeight;
figWidth = min(maxWidth,.75*sz(3));
figHeight=min(maxHeight,.75*sz(4));
set(mainFig,'Position',[sz(3)/50 (sz(4)-maxHeight)/2 figWidth+20 figHeight]);
set(panel1,'Units','Pixels','Position',[0 0 figWidth figHeight]);
panelRatio=maxHeight/figHeight;
set(moviePanel,'Position',[10 panelsHeight+10 panelsLength moviePanelHeight]);
set(panel2,'Position',[0 1-panelRatio 1 panelRatio]);
if panelRatio==1, set(s,'Enable','off'); end

% Update handles structure and attach it to the main figure
handles = guihandles(mainFig);
guidata(handles.figure1, handles);

set(handles.figure1,'UserData',userData);

%% Set up default parameters
% Auto check input process
for i=intersect(procId,validProcId)
    h=findobj(mainFig,'-regexp','Tag',['(\w)_process' num2str(i)  '_output1.*'],...
        '-not','Style','text');
    set(h,'Value',1);
    for j=find(arrayfun(@(x)isequal(get(x,'Parent'),graphPanel),h))'
        callbackFcn = get(h(j),'Callback');
        callbackFcn(h(j),[]);
    end
end

% Update the image and overlays
if isa(userData.MO,'MovieData'), redrawScene(handles.figure1, handles); end

function hPosition=createImageOptions(imagePanel,userData)
% First create image option (timestamp, scalebar, image scaling)
% Timestamp
hPosition=10;
if isempty(userData.MO.timeInterval_),
    timeStampStatus = 'off';
else
    timeStampStatus = 'on';
end
uicontrol(imagePanel,'Style','checkbox',...
    'Position',[10 hPosition 200 20],'Tag','checkbox_timeStamp',...
    'String',' Time stamp','HorizontalAlignment','left',...
    'Enable',timeStampStatus,'Callback',@(h,event) setTimeStamp(guidata(h)));
uicontrol(imagePanel,'Style','popupmenu','Position',[130 hPosition 120 20],...
    'String',{'NorthEast', 'SouthEast', 'SouthWest', 'NorthWest'},'Value',4,...
    'Tag','popupmenu_timeStampLocation','Enable',timeStampStatus,...
    'Callback',@(h,event) setTimeStamp(guidata(h)));

% Scalebar
hPosition=hPosition+30;
if isempty(userData.MO.pixelSize_), scBarstatus = 'off'; else scBarstatus = 'on'; end
uicontrol(imagePanel,'Style','edit','Position',[30 hPosition 50 20],...
    'String','1','BackgroundColor','white','Tag','edit_imageScaleBar',...
    'Enable',scBarstatus,...
    'Callback',@(h,event) setScaleBar(guidata(h),'imageScaleBar'));
uicontrol(imagePanel,'Style','text','Position',[85 hPosition-2 70 20],...
    'String','microns','HorizontalAlignment','left');
uicontrol(imagePanel,'Style','checkbox',...
    'Position',[150 hPosition 100 20],'Tag','checkbox_imageScaleBarLabel',...
    'String',' Show label','HorizontalAlignment','left',...
    'Enable',scBarstatus,...
    'Callback',@(h,event) setScaleBar(guidata(h),'imageScaleBar'));

hPosition=hPosition+30;
uicontrol(imagePanel,'Style','checkbox',...
    'Position',[10 hPosition 200 20],'Tag','checkbox_imageScaleBar',...
    'String',' Scalebar','HorizontalAlignment','left',...
    'Enable',scBarstatus,...
    'Callback',@(h,event) setScaleBar(guidata(h),'imageScaleBar'));
uicontrol(imagePanel,'Style','popupmenu','Position',[130 hPosition 120 20],...
    'String',{'NorthEast', 'SouthEast', 'SouthWest', 'NorthWest'},'Value',3,...
    'Tag','popupmenu_imageScaleBarLocation','Enable',scBarstatus,...
    'Callback',@(h,event) setScaleBar(guidata(h),'imageScaleBar'));

hPosition=hPosition+30;
uicontrol(imagePanel,'Style','text',...
    'Position',[20 hPosition 100 20],'Tag','text_imageScaleFactor',...
    'String',' Scaling factor','HorizontalAlignment','left');
uicontrol(imagePanel,'Style','edit','Position',[120 hPosition 50 20],...
    'String','1','BackgroundColor','white','Tag','edit_imageScaleFactor',...
    'Callback',@(h,event) setScaleFactor(guidata(h)));

% Colormap control
hPosition=hPosition+30;
uicontrol(imagePanel,'Style','text','Position',[20 hPosition-2 100 20],...
    'String','Color limits','HorizontalAlignment','left');
uicontrol(imagePanel,'Style','edit','Position',[150 hPosition 50 20],...
    'String','','BackgroundColor','white','Tag','edit_cmin',...
    'Callback',@(h,event) setCLim(guidata(h)));
uicontrol(imagePanel,'Style','edit','Position',[200 hPosition 50 20],...
    'String','','BackgroundColor','white','Tag','edit_cmax',...
    'Callback',@(h,event) setCLim(guidata(h)));

hPosition=hPosition+30;
uicontrol(imagePanel,'Style','text','Position',[20 hPosition-2 80 20],...
    'String','Colormap','HorizontalAlignment','left');
uicontrol(imagePanel,'Style','popupmenu',...
    'Position',[130 hPosition 120 20],'Tag','popupmenu_colormap',...
    'String',{'Gray','Jet','HSV','Custom'},'Value',1,...
    'HorizontalAlignment','left','Callback',@(h,event) setColormap(guidata(h)));

% Colorbar 
hPosition=hPosition+30;
uicontrol(imagePanel,'Style','checkbox',...
    'Position',[10 hPosition 120 20],'Tag','checkbox_colorbar',...
    'String',' Colorbar','HorizontalAlignment','left',...
    'Callback',@(h,event) setColorbar(guidata(h)));
findclass(findpackage('scribe'),'colorbar');
locations = findtype('ColorbarLocationPreset');
locations = locations.Strings;
uicontrol(imagePanel,'Style','popupmenu','String',locations,...
    'Position',[130 hPosition 120 20],'Tag','popupmenu_colorbarLocation',...
    'HorizontalAlignment','left','Callback',@(h,event) setColorbar(guidata(h)));

hPosition=hPosition+20;
uicontrol(imagePanel,'Style','text','Position',[10 hPosition 200 20],...
    'String','Image options','HorizontalAlignment','left','FontWeight','bold');

function hPosition=createVectorFieldOptions(overlayPanel,userData,hPosition)
% First create overlay option (vectorField)
if isempty(userData.MO.pixelSize_) || isempty(userData.MO.timeInterval_),
    scaleBarStatus = 'off';
else
    scaleBarStatus = 'on';
end
uicontrol(overlayPanel,'Style','text','Position',[20 hPosition-2 100 20],...
    'String','Color limits','HorizontalAlignment','left');
uicontrol(overlayPanel,'Style','edit','Position',[150 hPosition 50 20],...
    'String','','BackgroundColor','white','Tag','edit_vectorCmin',...
    'Callback',@(h,event) redrawOverlays(guidata(h)));
uicontrol(overlayPanel,'Style','edit','Position',[200 hPosition 50 20],...
    'String','','BackgroundColor','white','Tag','edit_vectorCmax',...
    'Callback',@(h,event) redrawOverlays(guidata(h)));

hPosition=hPosition+30;
uicontrol(overlayPanel,'Style','edit','Position',[30 hPosition 50 20],...
    'String','1000','BackgroundColor','white','Tag','edit_vectorFieldScaleBar',...
    'Enable',scaleBarStatus,...
    'Callback',@(h,event) setScaleBar(guidata(h),'vectorFieldScaleBar'));
uicontrol(overlayPanel,'Style','text','Position',[85 hPosition-2 70 20],...
    'String','nm/min','HorizontalAlignment','left');
uicontrol(overlayPanel,'Style','checkbox',...
    'Position',[150 hPosition 100 20],'Tag','checkbox_vectorFieldScaleBarLabel',...
    'String',' Show label','HorizontalAlignment','left',...
    'Enable',scaleBarStatus,...
    'Callback',@(h,event) setScaleBar(guidata(h),'vectorFieldScaleBar'));

hPosition=hPosition+30;
uicontrol(overlayPanel,'Style','checkbox',...
    'Position',[20 hPosition 100 20],'Tag','checkbox_vectorFieldScaleBar',...
    'String',' Scalebar','HorizontalAlignment','left',...
    'Enable',scaleBarStatus,...
    'Callback',@(h,event) setScaleBar(guidata(h),'vectorFieldScaleBar'));
uicontrol(overlayPanel,'Style','popupmenu','Position',[130 hPosition 120 20],...
    'String',{'NorthEast', 'SouthEast', 'SouthWest', 'NorthWest'},'Value',3,...
    'Tag','popupmenu_vectorFieldScaleBarLocation','Enable',scaleBarStatus,...
    'Callback',@(h,event) setScaleBar(guidata(h),'vectorFieldScaleBar'));

hPosition=hPosition+30;
uicontrol(overlayPanel,'Style','text',...
    'Position',[20 hPosition 100 20],'Tag','text_vectorFieldScale',...
    'String',' Display scale','HorizontalAlignment','left');
uicontrol(overlayPanel,'Style','edit','Position',[120 hPosition 50 20],...
    'String','1','BackgroundColor','white','Tag','edit_vectorFieldScale',...
    'Callback',@(h,event) redrawOverlays(guidata(h)));

hPosition=hPosition+20;
uicontrol(overlayPanel,'Style','text',...
    'Position',[10 hPosition 200 20],'Tag','text_vectorFieldOptions',...
    'String','Vector field options','HorizontalAlignment','left','FontWeight','bold');

function hPosition=createTrackOptions(overlayPanel,userData,hPosition)

hPosition=hPosition+30;
uicontrol(overlayPanel,'Style','text',...
    'Position',[20 hPosition 100 20],'Tag','text_dragtailLength',...
    'String',' Dragtail length','HorizontalAlignment','left');
uicontrol(overlayPanel,'Style','edit','Position',[120 hPosition 50 20],...
    'String','10','BackgroundColor','white','Tag','edit_dragtailLength',...
    'Callback',@(h,event) redrawOverlays(guidata(h)));

hPosition=hPosition+20;
uicontrol(overlayPanel,'Style','checkbox',...
    'Position',[20 hPosition 150 20],'Tag','checkbox_showLabel',...
    'String',' Show track number','HorizontalAlignment','left',...
    'Callback',@(h,event) redrawOverlays(guidata(h)));

hPosition=hPosition+20;
uicontrol(overlayPanel,'Style','text',...
    'Position',[10 hPosition 200 20],'Tag','text_trackOptions',...
    'String','Track options','HorizontalAlignment','left','FontWeight','bold');
    

function hPosition=createWindowsOptions(overlayPanel,userData,hPosition)


hPosition=hPosition+30;
uicontrol(overlayPanel,'Style','text',...
    'Position',[20 hPosition 100 20],'Tag','text_faceAlpha',...
    'String',' Alpha value','HorizontalAlignment','left');
uicontrol(overlayPanel,'Style','edit','Position',[120 hPosition 50 20],...
    'String','.3','BackgroundColor','white','Tag','edit_faceAlpha',...
    'Callback',@(h,event) redrawOverlays(guidata(h)));

hPosition=hPosition+20;
uicontrol(overlayPanel,'Style','text',...
    'Position',[10 hPosition 200 20],'Tag','text_windowsOptions',...
    'String','Windows options','HorizontalAlignment','left','FontWeight','bold');

function hPosition=createScalarMapOptions(graphPanel,userData,hPosition)


hPosition=hPosition+30;
uicontrol(graphPanel,'Style','text',...
    'Position',[20 hPosition 200 20],'Tag','text_UpSample',...
    'String',' Upsampling Factor','HorizontalAlignment','left');
uicontrol(graphPanel,'Style','edit','Position',[220 hPosition 50 20],...
    'String','1','BackgroundColor','white','Tag','edit_UpSample',...
    'Callback',@(h,event) redrawGraphs(guidata(h)));

hPosition=hPosition+20;
uicontrol(graphPanel,'Style','text',...
    'Position',[20 hPosition 200 20],'Tag','text_SmoothParam',...
    'String',' Smoothing Parameter','HorizontalAlignment','left');
uicontrol(graphPanel,'Style','edit','Position',[220 hPosition 50 20],...
    'String','.99','BackgroundColor','white','Tag','edit_SmoothParam',...
    'Callback',@(h,event) redrawGraphs(guidata(h)));

hPosition=hPosition+20;
uicontrol(graphPanel,'Style','text',...
    'Position',[10 hPosition 200 20],'Tag','text_scalarMapOptions',...
    'String','Scalar Map options','HorizontalAlignment','left','FontWeight','bold');
    


function slider_callback(src,eventdata,panel)
pos=get(panel,'Position');
pos(2)=(1-pos(4))*get(src,'Value');
set(panel,'Position',pos)
uistack(panel,'top');


function displayPath= getDisplayPath(movie)
[~,endPath] = fileparts(movie.getPath);
displayPath = fullfile(endPath,movie.getFilename);

function switchMovie(hObject,handles)
userData=get(handles.figure1,'UserData');
props=get(hObject,{'UserData','Value'});
if isequal(props{1}(props{2}), userData.movieIndex),return;end
movieViewer(userData.ML,userData.procId,'movieIndex',props{1}(props{2}));

function size = getPanelSize(hPanel)
if ~ishandle(hPanel), size=[0 0]; return; end
a=get(get(hPanel,'Children'),'Position');
P=vertcat(a{:});
size = [max(P(:,1)+P(:,3))+10 max(P(:,2)+P(:,4))+20];

function runMovie(hObject,handles)

userData = get(handles.figure1, 'UserData');
nFrames = userData.MO.nFrames_;
startFrame = get(handles.slider_frame,'Value');
if startFrame == nFrames, startFrame =1; end;
if get(hObject,'Value'), action = 'Stop'; else action = 'Run'; end
set(hObject,'String',[action ' movie']);

% Get frame/movies export status
saveMovie = get(handles.checkbox_saveMovie,'Value');
saveFrames = get(handles.checkbox_saveFrames,'Value');
props = get(handles.popupmenu_movieFormat,{'String','Value'});
movieFormat = props{1}{props{2}};

if saveMovie,
    moviePath = fullfile(userData.MO.outputDirectory_,['Movie.' lower(movieFormat)]);
end

% Initialize movie output
if saveMovie && strcmpi(movieFormat,'mov')
    MakeQTMovie('start',moviePath);
    MakeQTMovie('quality',.9)
end

if saveMovie && strcmpi(movieFormat,'avi')
    movieFrames(1:nFrames) = struct('cdata', [],'colormap', []);
end

% Initialize frame output
if saveFrames;
    fmt = ['%0' num2str(ceil(log10(nFrames))) 'd'];
    frameName = @(frame) ['frame' num2str(frame, fmt) '.tif'];
    fpath = [userData.MO.outputDirectory_ filesep 'Frames'];
    mkClrDir(fpath);
    fprintf('Generating movie frames:     ');
end

for iFrame = startFrame : nFrames
    if ~get(hObject,'Value'), return; end % Handle pushbutton press
    set(handles.slider_frame, 'Value',iFrame);
    redrawScene(hObject, handles);    
    drawnow;
    
    % Get current frame for frame/movie export
    hFig = getFigure(handles,'Movie');
    if saveMovie && strcmpi(movieFormat,'mov'), MakeQTMovie('addfigure'); end
    if saveMovie && strcmpi(movieFormat,'avi'), movieFrames(iFrame) = getframe(hFig); end
    if saveFrames
        print(hFig, '-dtiff', fullfile(fpath,frameName(iFrame)));
        fprintf('\b\b\b\b%3d%%', round(100*iFrame/(nFrames)));
    end
end

% Finish frame/movie creation
if saveFrames; fprintf('\n'); end
if saveMovie && strcmpi(movieFormat,'mov'), MakeQTMovie('finish'); end
if saveMovie && strcmpi(movieFormat,'avi'), movie2avi(movieFrames,moviePath); end

% Reset button
set(hObject,'String', 'Run movie', 'Value', 0);

function redrawScene(hObject, handles)

userData = get(handles.figure1, 'UserData');
% Retrieve the value of the selected image
if strcmp(get(hObject,'Tag'),'edit_frame')
    frameNumber = str2double(get(handles.edit_frame, 'String'));
else
    frameNumber = get(handles.slider_frame, 'Value');
end
frameNumber=round(frameNumber);
frameNumber = min(max(frameNumber,1),userData.MO.nFrames_);

% Set the slider and editboxes values
set(handles.edit_frame,'String',frameNumber);
set(handles.slider_frame,'Value',frameNumber);

% Update the image and overlays
redrawImage(handles);
redrawOverlays(handles);

function h= getFigure(handles,figName)

h = findobj(0,'-regexp','Name',['^' figName '$']);
if ~isempty(h), figure(h); return; end

%Create a figure
if strcmp(figName,'Movie')
    userData = get(handles.figure1,'UserData');
    sz=get(0,'ScreenSize');
    nx=userData.MO.imSize_(2);
    ny=userData.MO.imSize_(1);
    sc = max(1, max(nx/(.9*sz(3)), ny/(.9*sz(4))));
    h = figure('Position',[sz(3)*.2 sz(4)*.2 nx/sc ny/sc],...
        'Name',figName,'NumberTitle','off','Tag','viewerFig',...
        'UserData',handles.figure1);
    
    % figure options for movie export
    iptsetpref('ImShowBorder','tight');
    set(h, 'InvertHardcopy', 'off');
    set(h, 'PaperUnits', 'Points');
    set(h, 'PaperSize', [nx ny]);
    set(h, 'PaperPosition', [0 0 nx ny]); % very important
    set(h, 'PaperPositionMode', 'auto');
    % set(h,'DefaultLineLineSmoothing','on');
    % set(h,'DefaultPatchLineSmoothing','on');
    
    axes('Parent',h,'XLim',[0 userData.MO.imSize_(2)],...
        'YLim',[0 userData.MO.imSize_(1)],'Position',[0.05 0.05 .9 .9]);
    set(handles.figure1,'UserData',userData);
    
    % Set the zoom properties
    hZoom=zoom(h);
    hPan=pan(h);
    set(hZoom,'ActionPostCallback',@(h,event)panZoomCallback(h));
    set(hPan,'ActionPostCallback',@(h,event)panZoomCallback(h));
else
    h = figure('Name',figName,'NumberTitle','off','Tag','viewerFig');
end


function redrawChannel(hObject,handles)

% Callback for channels checkboxes to avoid 0 or more than 4 channels
channelBoxes = findobj(handles.figure1,'-regexp','Tag','checkbox_channel*');
nChan=numel(find(arrayfun(@(x)get(x,'Value'),channelBoxes)));
if nChan==0, set(hObject,'Value',1); elseif nChan>3, set(hObject,'Value',0); end

redrawImage(handles)

function setScaleBar(handles,type)
% Remove existing scalebar of given type
h=findobj('Tag',type);
if ~isempty(h), delete(h); end

% If checked, adds a new scalebar using the width as a label input
userData=get(handles.figure1,'UserData');
if ~get(handles.(['checkbox_' type]),'Value'), return; end
getFigure(handles,'Movie');

scale = str2double(get(handles.(['edit_' type]),'String'));
if strcmp(type,'imageScaleBar')
    width = scale *1000/userData.MO.pixelSize_;
    label = [num2str(scale) ' \mum'];
else
    displayScale = str2double(get(handles.edit_vectorFieldScale,'String'));
    width = scale*displayScale/(userData.MO.pixelSize_/userData.MO.timeInterval_*60);
    label= [num2str(scale) ' nm/min'];
end
if ~get(handles.(['checkbox_' type 'Label']),'Value'), label=''; end
props=get(handles.(['popupmenu_' type 'Location']),{'String','Value'});
location=props{1}{props{2}};
hScaleBar = plotScaleBar(width,'Label',label,'Location',location);
set(hScaleBar,'Tag',type);

function setTimeStamp(handles)
% Remove existing timestamp of given type
h=findobj('Tag','timeStamp');
if ~isempty(h), delete(h); end

% If checked, adds a new scalebar using the width as a label input
userData=get(handles.figure1,'UserData');
if ~get(handles.checkbox_timeStamp,'Value'), return; end
getFigure(handles,'Movie');

frameNr=get(handles.slider_frame,'Value');
time= (frameNr-1)*userData.MO.timeInterval_;
p=sec2struct(time);
props=get(handles.popupmenu_timeStampLocation,{'String','Value'});
location=props{1}{props{2}};
hTimeStamp = plotTimeStamp(p.str,'Location',location);
set(hTimeStamp,'Tag','timeStamp');

function setCLim(handles)
clim=[str2double(get(handles.edit_cmin,'String')) ...
    str2double(get(handles.edit_cmax,'String'))];
redrawImage(handles,'CLim',clim)

function setScaleFactor(handles)
scaleFactor=str2double(get(handles.edit_imageScaleFactor,'String'));
redrawImage(handles,'ScaleFactor',scaleFactor)

function setColormap(handles)
allCmap=get(handles.popupmenu_colormap,'String');
selectedCmap = get(handles.popupmenu_colormap,'Value');
redrawImage(handles,'Colormap',allCmap{selectedCmap})

function setColorbar(handles)
cbar=get(handles.checkbox_colorbar,'Value');
props = get(handles.popupmenu_colorbarLocation,{'String','Value'});
if cbar, cbarStatus='on'; else cbarStatus='off'; end 
redrawImage(handles,'Colorbar',cbarStatus,'ColorbarLocation',props{1}{props{2}})

function redrawImage(handles,varargin)
frameNr=get(handles.slider_frame,'Value');
imageTag = get(get(handles.uipanel_image,'SelectedObject'),'Tag');

% Get the figure handle
drawFig = getFigure(handles,'Movie');
userData=get(handles.figure1,'UserData');

% Use corresponding method depending if input is channel or process output
channelBoxes = findobj(handles.figure1,'-regexp','Tag','checkbox_channel*');
[~,index]=sort(arrayfun(@(x) get(x,'Tag'),channelBoxes,'UniformOutput',false));
channelBoxes =channelBoxes(index);
if strcmp(imageTag,'radiobutton_channels')
    set(channelBoxes,'Enable','on');
    chanList=find(arrayfun(@(x)get(x,'Value'),channelBoxes));
    userData.MO.channels_(chanList).draw(frameNr,varargin{:});
    displayMethod = userData.MO.channels_(chanList(1)).displayMethod_;
else
    set(channelBoxes,'Enable','off');
    % Retrieve the id, process nr and channel nr of the selected imageProc
    tokens = regexp(imageTag,'radiobutton_process(\d+)_output(\d+)_channel(\d+)','tokens');
    procId=str2double(tokens{1}{1});
    outputList = userData.MO.processes_{procId}.getDrawableOutput;
    iOutput = str2double(tokens{1}{2});
    output = outputList(iOutput).var;
    iChan = str2double(tokens{1}{3});
    userData.MO.processes_{procId}.draw(iChan,frameNr,'output',output,varargin{:});
    displayMethod = userData.MO.processes_{procId}.displayMethod_{iOutput,iChan};
end


% Set the color limits properties
clim=displayMethod.CLim;
if isempty(clim)
    hAxes=findobj(drawFig,'Type''axes','-not','Tag','Colorbar');
    clim=get(hAxes,'Clim');
end
if ~isempty(clim)
    set(handles.edit_cmin,'Enable','on','String',clim(1));
    set(handles.edit_cmax,'Enable','on','String',clim(2));
end

set(handles.edit_imageScaleFactor,'Enable','on','String',displayMethod.ScaleFactor);
% Set the colorbar properties
cbar=displayMethod.Colorbar;
cbarLocation = find(strcmpi(displayMethod.ColorbarLocation,get(handles.popupmenu_colorbarLocation,'String')));
set(handles.checkbox_colorbar,'Value',strcmp(cbar,'on'));
set(handles.popupmenu_colorbarLocation,'Enable',cbar,'Value',cbarLocation);

% Set the colormap properties
cmap=displayMethod.Colormap;
allCmap=get(handles.popupmenu_colormap,'String');
iCmap = find(strcmpi(cmap,allCmap),1);

if isempty(iCmap), 
    iCmap= numel(allCmap); 
    enableState = 'off';
else
    enableState = 'on';
end
set(handles.popupmenu_colormap,'Value',iCmap,'Enable',enableState);
    
% Reset the scaleBar
setScaleBar(handles,'imageScaleBar');
setTimeStamp(handles);

function panZoomCallback(h)

% Reset the scaleBar
handles=guidata(get(h,'UserData'));
setScaleBar(handles,'imageScaleBar');
setTimeStamp(handles);

function redrawOverlays(handles)
if ~isfield(handles,'uipanel_overlay'), return; end

overlayBoxes = findobj(handles.uipanel_overlay,'-regexp','Tag','checkbox_process*');
checkedBoxes = logical(arrayfun(@(x) get(x,'Value'),overlayBoxes));
overlayTags=arrayfun(@(x) get(x,'Tag'),overlayBoxes(checkedBoxes),...
    'UniformOutput',false);
for i=1:numel(overlayTags),
    redrawOverlay(handles.(overlayTags{i}),handles)
end

% Reset the scaleBar
if get(handles.checkbox_vectorFieldScaleBar,'Value'),
    setScaleBar(handles,'vectorFieldScaleBar');
end

function redrawOverlay(hObject,handles)
userData=get(handles.figure1,'UserData');
frameNr=get(handles.slider_frame,'Value');
overlayTag = get(hObject,'Tag');

% Get figure handle or recreate figure
movieFig = findobj(0,'Name','Movie');
if isempty(movieFig),  redrawScene(hObject, handles); return; end
figure(movieFig);
% Retrieve the id, process nr and channel nr of the selected imageProc
tokens = regexp(overlayTag,'^checkbox_process(\d+)_output(\d+)','tokens');
procId=str2double(tokens{1}{1});
outputList = userData.MO.processes_{procId}.getDrawableOutput;
iOutput = str2double(tokens{1}{2});
output = outputList(iOutput).var;

% Discriminate between channel-specific processes annd movie processes
tokens = regexp(overlayTag,'_channel(\d+)$','tokens');
if ~isempty(tokens)
    iChan = str2double(tokens{1}{1});
    inputArgs={iChan,frameNr};
    graphicTag =['process' num2str(procId) '_channel'...
        num2str(iChan) '_output' num2str(iOutput)];
else
    iChan = [];
    inputArgs={frameNr};
    graphicTag = ['process' num2str(procId) '_output' num2str(iOutput)];
end

% Draw or delete the overlay depending on the checkbox value
if get(hObject,'Value')
    vectorScale = str2double(get(handles.edit_vectorFieldScale,'String'));
    dragtailLength = str2double(get(handles.edit_dragtailLength,'String'));    
    showLabel = get(handles.checkbox_showLabel,'Value');
    faceAlpha = str2double(get(handles.edit_faceAlpha,'String'));
    clim=[str2double(get(handles.edit_vectorCmin,'String')) ...
        str2double(get(handles.edit_vectorCmax,'String'))];
    if ~isempty(clim) && all(~isnan(clim)), cLimArgs={'CLim',clim}; else cLimArgs={}; end
    userData.MO.processes_{procId}.draw(inputArgs{:},'output',output,...
        'vectorScale',vectorScale,'dragtailLength',dragtailLength,...
        'faceAlpha',faceAlpha,'showLabel',showLabel,cLimArgs{:});
else
    h=findobj('Tag',graphicTag);
    if ~isempty(h), delete(h); end
end

% Get display method and update option status
if isempty(iChan),
    displayMethod = userData.MO.processes_{procId}.displayMethod_{iOutput};
else
    displayMethod = userData.MO.processes_{procId}.displayMethod_{iOutput,iChan};
end
if isa(displayMethod,'VectorFieldDisplay') && ~isempty(displayMethod.CLim)
    set(handles.edit_vectorCmin,'String',displayMethod.CLim(1));
    set(handles.edit_vectorCmax,'String',displayMethod.CLim(2));
end

function redrawGraphs(handles)
if ~isfield(handles,'uipanel_graph'), return; end

graphBoxes = findobj(handles.uipanel_graph,'-regexp','Tag','checkbox_process*');
checkedBoxes = logical(arrayfun(@(x) get(x,'Value'),graphBoxes));
graphTags=arrayfun(@(x) get(x,'Tag'),graphBoxes(checkedBoxes),...
    'UniformOutput',false);
for i=1:numel(graphTags),
    redrawGraph(handles.(graphTags{i}),handles)
end

function redrawGraph(hObject,handles)
graphTag = get(hObject,'Tag');
userData=get(handles.figure1,'UserData');

% Retrieve the id, process nr and channel nr of the selected graphProc
tokens = regexp(graphTag,'^checkbox_process(\d+)_output(\d+)','tokens');
procId=str2double(tokens{1}{1});
outputList = userData.MO.processes_{procId}.getDrawableOutput;
iOutput = str2double(tokens{1}{2});
output = outputList(iOutput).var;

% Discriminate between channel-specific and movie processes
tokens = regexp(graphTag,'_channel(\d+)$','tokens');
if ~isempty(tokens)
    iChan = str2double(tokens{1}{1});
    figName = [outputList(iOutput).name ' - Channel ' num2str(iChan)];
    if strcmp({outputList(iOutput).type},'sampledGraph')
        inputArgs={iChan,iOutput};
    else
        inputArgs={iChan};
    end
else
    tokens = regexp(graphTag,'_input(\d+)$','tokens');
    if ~isempty(tokens)
        iInput = str2double(tokens{1}{1});
        figName = [outputList(iOutput).name ' - ' ...
            userData.MO.processes_{procId}.getInput(iInput).name];
        inputArgs={iInput};
    else
        inputArgs={};
        figName = outputList(iOutput).name;
    end
end

% Draw or delete the graph figure depending on the checkbox value
h = getFigure(handles,figName);
if ~get(hObject,'Value'),delete(h); return; end

upSample = str2double(get(handles.edit_UpSample,'String'));
smoothParam = str2double(get(handles.edit_SmoothParam,'String'));
userData.MO.processes_{procId}.draw(inputArgs{:}, 'output', output,...
    'UpSample', upSample,'SmoothParam', smoothParam);
set(h,'DeleteFcn',@(h,event)closeGraphFigure(hObject));


function redrawSignalGraph(hObject,handles)
graphTag = get(hObject,'Tag');
userData=get(handles.figure1,'UserData');

% Retrieve the id, process nr and channel nr of the selected graphProc
tokens = regexp(graphTag,'^checkbox_process(\d+)_output(\d+)_input(\d+)_input(\d+)','tokens');
procId=str2double(tokens{1}{1});
iOutput = str2double(tokens{1}{2});
iInput1 = str2double(tokens{1}{3});
iInput2 = str2double(tokens{1}{4});

signalProc = userData.MO.processes_{procId};
figName = signalProc.getOutputTitle(iInput1,iInput2,iOutput);

% Draw or delete the graph figure depending on the checkbox value
h = getFigure(handles,figName);
if ~get(hObject,'Value'),delete(h); return; end

signalProc.draw(iInput1,iInput2,iOutput);
set(h,'DeleteFcn',@(h,event)closeGraphFigure(hObject));

function closeGraphFigure(hObject)
set(hObject,'Value',0);

function deleteViewer()

h = findobj(0,'-regexp','Tag','viewerFig');
if ~isempty(h), delete(h); end

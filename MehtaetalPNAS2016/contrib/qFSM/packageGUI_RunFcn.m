function packageGUI_RunFcn(hObject,eventdata,handles)
% Run the selected processes in the packageGUI interface
%
% This is a common section of code called by pushbutton_run_Callback
% when user click the "Run" button on package control panels.
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

% Chuangang Ren 11/2010
% Sebastien Besson 5/2011 (last modified Oct 2011)

ip = inputParser;
ip.addRequired('hObject',@ishandle);
ip.addRequired('eventdata',@(x) isstruct(x) || isempty(x));
ip.addRequired('handles',@isstruct);
ip.parse(hObject,eventdata,handles);

%% Initialization

% Get check box status of current movie and update user data
userData = get(handles.figure1,'UserData');
userData.statusM(userData.id).Checked = userfcn_saveCheckbox(handles);
set(handles.figure1, 'UserData', userData)

% Determine the movie(s) to be processed
if ~isempty(userData.MD), field='MD'; else field = 'ML'; end
nMovies = length(userData.(field)); % number of movies
if get(handles.checkbox_runall, 'Value')
    movieList = circshift(1:nMovies,[0 -(userData.id-1)]);
else
    movieList=userData.id;
end
% Get the list of valid movies (with processes to run)
hasValidProc = arrayfun(@(x) any(userData.statusM(x).Checked),movieList);
movieRun=movieList(hasValidProc);

procCheck=cell(1,numel(nMovies));
procCheck(movieRun)=arrayfun(@(x) find(userData.statusM(x).Checked),movieRun,...
    'UniformOutput',false);

% Throw warning dialog if no movie
if isempty(movieRun)
    warndlg('No step is selected, please select a step to process.',...
        'No Step Selected','modal');
    return
end

%% Pre-processing examination

% movie exception (same length of movie data)
movieException = cell(1, nMovies);
procRun = cell(1, nMovies);%  id of processes to run

% Find unset processes
isProcSet=@(x,y)~isempty(userData.package(x).processes_{y});
isMovieProcSet = @(x) all(arrayfun(@(y)isProcSet(x,y),procCheck{x}));
invalidMovies=movieRun(~arrayfun(isMovieProcSet,movieRun));

for i = invalidMovies
    invalidProc = procCheck{i}(arrayfun(@(y)~isProcSet(i,y),procCheck{i}));
    for j=invalidProc
        ME = MException('lccb:run:setup', ['Step %d : %s is not set up yet.\n'...
            '\nTip: when step is set up successfully, the step name becomes bold.'],j,...
            eval([userData.package(i).getProcessClassNames{j} '.getName']));
        movieException{i} = cat(2, movieException{i}, ME);
    end
end

validMovies=movieRun(arrayfun(isMovieProcSet,movieRun));
for iMovie = validMovies   
    % Check if selected processes have alrady be successfully run
    % If force run, re-run every process that is checked
    if ~get(handles.checkbox_forcerun, 'Value')
        
        k = true;
        for i = procCheck{iMovie}
            
            if  ~( userData.package(iMovie).processes_{i}.success_ && ...
                    ~userData.package(iMovie).processes_{i}.procChanged_ ) || ...
                    ~userData.package(iMovie).processes_{i}.updated_
                
                k = false;
                procRun{iMovie} = cat(2, procRun{iMovie}, i);
            end
        end
        if k
            movieRun = setdiff(movieRun, iMovie);
            continue
        end
    else
        procRun{iMovie} = procCheck{iMovie};
    end    
    
    % Package full sanity check. Sanitycheck every checked process
    [status procEx] = userData.package(iMovie).sanityCheck(true, procRun{iMovie});
    
    % Return user data !!!
    set(handles.figure1, 'UserData', userData)
    invalidProcEx = procRun{iMovie}(~cellfun(@isempty,procEx(procRun{iMovie})));
    for i = invalidProcEx
        % Check if there is fatal error in exception array
        if strcmp(procEx{i}(1).identifier, 'lccb:set:fatal') || ...
                strcmp(procEx{i}(1).identifier, 'lccb:input:fatal')
            
            % Sanity check error - switch GUI to the x th movie
            if iMovie ~= userData.id
                set(handles.popupmenu_movie, 'Value', iMovie)
                % Update the movie pop-up menu in the main package GUI
                packageGUI('switchMovie_Callback',handles.popupmenu_movie, [], handles)
            end
            
            userfcn_drawIcon(handles,'error', i, procEx{i}(1).message, true);
            
            ME = MException('lccb:run:sanitycheck','Step %d %s: \n%s',...
                i,userData.package(iMovie).processes_{i}.getName, procEx{i}(1).message);
            movieException{iMovie} = cat(2, movieException{iMovie}, ME);
                
        end
    end
    
    % Refresh user data !!!
    userData = get(handles.figure1, 'UserData');
end

%% Pre-processing exception report
if isempty(movieRun)
    warndlg('All selected steps have been processed successfully. Please check the ''Force Run'' check box if you want to re-process the successful steps.','No Step Selected','modal');
    return
end

status = generateReport(movieException,userData,'preprocessing');
if ~status, return; end

%% Start processing
if strcmp(get(handles.menu_debug_enter,'Checked'),'on'), dbstop if caught error; end
for i=1:length(movieRun)
    iMovie = movieRun(i);
   
    if iMovie ~= userData.id
        % Update the movie pop-up menu in the main package GUI
        set(handles.figure1, 'UserData', userData)
        set(handles.popupmenu_movie, 'Value', iMovie)
        
        % Update the movie pop-up menu in the main package GUI
        packageGUI('switchMovie_Callback',handles.popupmenu_movie, [], handles)
        userData = get(handles.figure1, 'UserData');
    end
    
    % Clear icons of selected processes
    % Return user data !!!
    set(handles.figure1, 'UserData', userData)
    userfcn_drawIcon(handles,'clear',procRun{iMovie},'',true); % user data is retrieved, updated and submitted
    % Refresh user data !!!
    userData = get(handles.figure1, 'UserData');
    
    % Disable 'Run' button
%     set(handles.pushbutton_run, 'Enable', 'off')
%     set(handles.checkbox_forcerun, 'Enable', 'off')
%     set(handles.checkbox_runall, 'Enable', 'off')
    set(handles.text_status, 'Visible', 'on')
    
    % Run algorithms!
    try
        % Return user data !!!
        set(handles.figure1, 'UserData', userData)
        
        for procID = procRun{iMovie}
            set(handles.text_status, 'String', ...
                sprintf('Step %d - Processing %d of %d movies total ...', procID, i, length(movieRun)) )
            userfcn_runProc_dfs(procID, procRun{iMovie}, handles); % user data is retrieved, updated and submitted
        end
        
    catch ME
        
        % Save the error into movie Exception cell array
        ME2 = MException('lccb:run:error','Step %d: %s',...
            procID,userData.package(iMovie).processes_{procID}.getName);
        movieException{iMovie} = cat(2, movieException{iMovie}, ME2);
        movieException{iMovie}=movieException{iMovie}.addCause(ME);
        
        procRun{iMovie} = procRun{iMovie}(procRun{iMovie} < procID);
    end
    
    % Refresh user data !!!
    userData = get(handles.figure1, 'UserData');
    set(handles.pushbutton_run, 'Enable', 'on')
    set(handles.checkbox_forcerun, 'Enable', 'on')
    set(handles.checkbox_runall, 'Enable', 'on')
    set(handles.text_status, 'Visible', 'off')

    % Return user data !!!
    set(handles.figure1, 'UserData', userData)
end
if strcmp(get(handles.menu_debug_enter,'Checked'),'on'), dbclear if caught error; end

%% Post-processing exception report
status = generateReport(movieException,userData,'postprocessing');
if status
    successMsg = 'Your movie(s) have been processed successfully.';
    userData.iconHelpFig = helpdlg(successMsg, [userData.crtPackage.getName]);
    set(handles.figure1, 'UserData', userData)
end

% Delete waitbars
hWaitbar = findall(0,'type','figure','tag','TMWWaitbar');
delete(hWaitbar);
end

function userfcn_runProc_dfs (procID, procRun, handles)  % throws exception

% Set user Data
userData = get(handles.figure1, 'UserData');

parentRun = [];
parentID=userData.crtPackage.getParent(procID);

% if current process procID have dependency processes    
for j = parentID
    % if parent process is one of the processes need to be run
    % if parent process has already run successfully
    if any(j == procRun) && ~userData.crtPackage.processes_{j}.success_
        parentRun = horzcat(parentRun,j); %#ok<AGROW>
    end
end

% if above assumptions are yes, recursively run parent process' dfs fcn
for j = parentRun
    userfcn_runProc_dfs (j, procRun, handles)
end

try
    userData.crtPackage.processes_{procID}.run(); % throws exception
catch ME
    rethrow(ME)
end

% Refresh wall status
packageGUI_RefreshFcn(handles,'initialize');
end

function status = generateReport(movieException,userData,reportType)
% Generate report from movie exception cell array

% Check exception status
errorMovies = find(~cellfun(@isempty, movieException, 'UniformOutput', true));
status =1;

if isempty(errorMovies), return; end
status = 0;

% Create log message
basicLogMsg = cell(size(movieException));
extendedLogMsg = cell(size(movieException));
for i = errorMovies
    % Format movie log message
    if ~isempty(userData.MD), 
        field = 'MD';
        type = 'Movie'; 
    else
        field = 'ML';
        type = 'Movie list'; 
    end
    basicLogMsg{i} = sprintf('%s %d - %s:\n\n', type, i, userData.(field)(i).getFullPath);
    extendedLogMsg{i}=basicLogMsg{i};
    
    % Read exception message and add causes message if any
    for j = 1:length(movieException{i})
        basicLogMsg{i} = [basicLogMsg{i} '--'  ...
            movieException{i}(j).getReport('basic','hyperlinks','off') sprintf('\n')];
        extendedLogMsg{i} = [extendedLogMsg{i} sprintf('-- %s\n\n', movieException{i}(j).message)];
        if ~isempty(movieException{i}(j).cause)
            basicLogMsg{i} = [basicLogMsg{i},sprintf('\nCaused by:\n%s\n',...
                movieException{i}(j).cause{1}.getReport('basic','hyperlinks','off'))];
            extendedLogMsg{i} = [extendedLogMsg{i},...
                movieException{i}(j).cause{1}.getReport('extended','hyperlinks','off')];
        end
    end
    basicLogMsg{i}=sprintf('%s\n',basicLogMsg{i});
    extendedLogMsg{i}=sprintf('%s\n',extendedLogMsg{i});
end

% Add report information
if strcmpi(reportType,'preprocessing'), 
    additionalText=['Please solve the above problems before continuing.'...
        '\n\nThe movie(s) could not be processed.'];
elseif strcmpi(reportType,'postprocessing'), 
    additionalText=...
        ['Please verify your settings are correct. '...
        'Feel free to contact us if you have question regarding this error.'...
        '\n\nPlease help us improve the software by clearly reporting the '...
        'scenario when this error occurs, and the above error information '...
        'to us (error information is also displayed in Matlab command line).'...
        '\n\nFor contact information please refer to the following URL:'...
        '\nhttp://lccb.hms.harvard.edu/software.html'];

end

% Display general MATLAB installation information as a header
% Copied from ver.m

% find platform OS
if ispc
   platform = [system_dependent('getos'),' ',system_dependent('getwinsys')];
elseif ismac
    [fail, input] = unix('sw_vers');
    if ~fail
        platform = strrep(input, 'ProductName:', '');
        platform = strrep(platform, sprintf('\t'), '');
        platform = strrep(platform, sprintf('\n'), ' ');
        platform = strrep(platform, 'ProductVersion:', ' Version: ');
        platform = strrep(platform, 'BuildVersion:', 'Build: ');
    else
        platform = system_dependent('getos');
    end
else    
   platform = system_dependent('getos');
end
   
% display platform type
matlabInfo = sprintf(['MATLAB Version %s\nMATLAB License Number: %s\n'...
    'Operating System: %s\nJava VM Version: %s\n'],...
    version,license,platform,char(strread(version('-java'),'%s',1,'delimiter','\n'))); %#ok<REMFF1>

basicReport = [basicLogMsg{:}, sprintf(additionalText)];
extendedReport =[matlabInfo, extendedLogMsg{:}, sprintf(additionalText)];

% Create title
title='The processing of following movie(s)';
if strcmpi(type,'preprocessing'), 
    title=[title ' could not be continued:'];
elseif  strcmpi(type,'postprocessing'), 
    title=[title ' was terminated by run time error:'];
end

% Check messagebox existence and generate report using msgboxGUI
if isfield(userData, 'msgboxGUI') && ishandle(userData.msgboxGUI)
    delete(userData.msgboxGUI)
end
if isequal(basicReport,extendedReport)
    userData.msgboxGUI = msgboxGUI('title',title,'text', basicReport,...
        'name','Error report');
else
    userData.msgboxGUI = msgboxGUI('title',title,'text', basicReport,...
        'extendedText',extendedReport,'name','Error report');
end
end

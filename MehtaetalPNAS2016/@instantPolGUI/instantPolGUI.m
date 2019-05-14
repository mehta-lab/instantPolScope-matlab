classdef instantPolGUI<hgsetget
    
    %% Data properties and calibration related variables.
    properties
        % Both RTFP and TanPol are objects of RTFluorPol Class. The TanPol
        % object will be used only when the Tangential Polarizer needs to
        % have different registration than the data.
        RTFP 
        TanPol
        paramsN
        paramsR
        dataFolder=pwd;
    end
    
    %% GUI properties.
    properties 
        % GUI handles
        hMain % main window
        hPG   % property grid
        hTabs % Tabbed pane
        % All of the following are nested structures that allow sharing of
        % variables.
        hData % Data tab: Folder selection, Import/Export calibration, Batch processing with current parameters.
        hQuad %  quadrant verification tab and children.
        hReg  % registration tab and children.
        hNorm % normalization 
        hPol % Pol-calibration.
        hParticle %Particle Analysis.
        hStat %Statistics.
        hAbout
    end
    
    methods
        function me=instantPolGUI()
            %% Global parameters.
             
            me.paramsN.normRange=[0.66 1.5];
            me.paramsR.scaleRange=[0.66 1.5];
            me.paramsR.shiftRange=[-25 25];
            me.paramsR.rotRange=[-15 15];
            
            %% Main GUI: 
            % This initialization suppresses the licensing error when
            % deploying the application.
             com.mathworks.mwswing.MJUtilities.initJIDE;

            fontSize=12;
            hFig=togglefig('instantaneousPolScope calibration and analysis.',1);
            set(hFig,'Position',[10 10 1430 890],...
                'defaultaxesfontsize',fontSize,'color','white');
            % Main box: Property grid on the left, everything else on the right.
            me.hMain=uiextras.HBoxFlex('Parent',hFig,'Padding',5,'Spacing',5);

            %% Set-up property grid linked to RTFP object.

            % PropertyGrid can be laid only on a uipanel.
            hPGPanel=uipanel('Parent',me.hMain,'Title','RTFluorPol Settings',...
                'FontWeight','bold','BackgroundColor','w','FontSize',fontSize);
            me.hPG=PropertyGrid(hPGPanel); % Instantiate property grid.
            me.RTFP=RTFluorPol(); % Instantiate RTFluorPol Object.
            instantPolGUI.setupRTFPPropertyGrid(me.hPG,me.RTFP,me.paramsN,me.paramsR);
            % Setup the property grid using a static method. The same
            % method is called when new calibration is imported.

            %% Set up tab panel that allows execution of different calibration/analysis steps.
            me.hTabs=uiextras.TabPanel('Parent',me.hMain,'Padding',5,...
                'TabSize',150,'FontSize',fontSize,'FontWeight','bold','BackgroundColor','w');
            
            me.hMain.Sizes=[-0.2 -1];

            % Data tab
            me.hData.top=uipanel('Parent',me.hTabs,'BackgroundColor','w');
            setupDataTab();
            
             % Quadrant verification tab
            me.hQuad.top=uipanel('Parent',me.hTabs,'BackgroundColor','w');
            setupQuickCheckTab();
            
            % Registration tab. 
            me.hReg.top=uipanel('Parent',me.hTabs,'BackgroundColor','w');
            setupRegistrationTab();
            
            % Normalization tab.
            me.hNorm.top=uipanel('Parent',me.hTabs,'BackgroundColor','w');
            setupNormalizationTab();
            
            % Pol-calibration tab.
            me.hPol.top=uipanel('Parent',me.hTabs,'BackgroundColor','w');
            setupPolTab();
   
             me.hStat.top=uipanel('Parent',me.hTabs,'BackgroundColor','w');
             setupStatTab();
            
            me.hParticle.top=uipanel('Parent',me.hTabs,'BackgroundColor','w');
            setupParticleTab();
            
            me.hAbout.top=uipanel('Parent',me.hTabs,'BackgroundColor','w');
            setupAboutTab();
            
            
            %me.hTabs.TabNames={'Data/Batch analysis','Quick check','Registration','Normalization','Pol-calibration','Particle Analysis','Statistics','About'};
             me.hTabs.TabNames={'Data/Batch analysis','Quick check','Registration','Normalization','Pol-calibration','Ensemble stats','Particle Analysis','About'};
          %  me.hTabs.TabNames={'Batch analysis','Quick check','Registration','Normalization','Pol-calibration','Particle Analysis','About'};


            %% GUI setup helpers.
            % These functions are nested to allow access to all class properties.
            % Until the constructor is done, the callbacks do not have
            % access to the properties of the class.
            function setupDataTab()
                % VBox: folder and colormap selection, calibration
                % import/export,  analysis queue, progress.
                me.hData.VBox=uiextras.VBox('Parent',me.hData.top,'BackgroundColor','w','Padding',5,'Spacing',5);
                % Top folder.
                me.hData.HBoxFolder=uiextras.HBox('Parent',me.hData.VBox,'BackgroundColor','w','Padding',5,'Spacing',5);
                % import/export calibration.
                me.hData.HBoxCalib=uiextras.HBox('Parent',me.hData.VBox,'BackgroundColor','w',...
                    'Padding',5,'Spacing',5);
                % Parameters.
                me.hData.panelParams=uipanel('Parent',me.hData.VBox,'BackgroundColor','w',...
                    'Title','Global processing parameters','FontWeight','Bold','FontSize',fontSize);
                                      
                % Batch analysis
                me.hData.VBoxBatch=uiextras.VBox('Parent',me.hData.VBox,'BackgroundColor','w','Padding',5,'Spacing',5);
                
                me.hData.VBox.Sizes=[50 50 -0.5 -1];

                me.hData.HBoxBatchAnalyze=uiextras.HBox('Parent',me.hData.VBoxBatch,'BackgroundColor','w','Padding',5,'Spacing',5);                            
                me.hData.VBoxBatchFiles=uiextras.VBox('Parent',me.hData.VBoxBatch,'BackgroundColor','w','Padding',5,'Spacing',5);
                me.hData.VBoxBatch.Sizes=[50 -1];
                
                % Setup batch processing property grid.

                batchprops=[...
                PropertyGridField('exportPolStack',true,...
                'Type',PropertyType('logical','scalar'),'DisplayName','Export polstack?'),...
                PropertyGridField('exportColorMap',true,...
                'Type',PropertyType('logical','scalar'),'DisplayName','Export colormap?'),...
                PropertyGridField('colorLegend',true,...
                'Type',PropertyType('logical','scalar'),'DisplayName','Display orientation color legend?'),...
                PropertyGridField('anisoQ','anisotropy',...
                    'Type',PropertyType('char','row',{'anisotropy','ratio','difference'}),'DisplayName','anisotropy quantity'),...
                PropertyGridField('colorMap','sbm',...
                    'Type',PropertyType('char','row',{'sbm','hsv'}),'DisplayName','Which colormap to use?'),...
                PropertyGridField('anisoCeiling',1,...
                     'Type',PropertyType('denserealdouble','scalar'),'DisplayName','polstack anisotropy ceiling',...
                     'Description','anisotropy/ratio/difference above chosen ceiling are clipped'),...
                PropertyGridField('colorCeiling',1,...
                     'Type',PropertyType('denserealdouble','scalar'),'DisplayName','colormap anisotropy ceiling',...
                     'Description','chosen ceiling of anisotropy/ratio/difference is mapped to the most saturated color.'),...
                PropertyGridField('avgCeiling',0,...
                     'Type',PropertyType('denserealdouble','scalar'),'DisplayName','colormap intensity ceiling',...
                     'Description','chosen ceiling of intensity is mapped to the brightest pixel.'),...                     
                PropertyGridField('BGiso',0,...
                     'Type',PropertyType('denserealdouble','scalar'),'DisplayName','isotropic background',...
                     'Description','Isotropic background subtracted after calibration.'),...
                PropertyGridField('normalizeExcitation',true,...
                'Type',PropertyType('logical','scalar'),'DisplayName','Apply excitation normalization?'),...
                PropertyGridField('dataFormat','single-Orientation',...
                'Type',PropertyType('char','row',{'single-Orientation','dual-Orientation+Intensity','single-Intensity'}),'DisplayName','No. and type of channels','Description', 'Tip: MetaMorph stores data in straight TIFF files, MicroManager stores in OME-TIFFs in a folder.'),...
                PropertyGridField('IsotropicBackground','none',...
                     'Type',PropertyType('char','row',{'none','auto','roi','label stack'}),...
                     'Description','Select the ROI over isotropic background used for background subtraction.')... 
                     ];

                me.hData.PGParams=PropertyGrid(me.hData.panelParams,'Properties',batchprops);
                
                
                % Layout HBoxFolder: button, datapath, colormap
                me.hData.buttonFolder=uicontrol('Parent',me.hData.HBoxFolder,'Style','pushbutton',...
                    'String','Choose data folder...','Callback',@me.changeFolder,'FontWeight','bold','FontSize',fontSize);
                me.hData.nameFolder=uicontrol('Parent',me.hData.HBoxFolder,'Style','text',...
                    'String',me.dataFolder,'BackgroundColor','White','FontSize',fontSize,'FontWeight','bold');
                
                me.hData.cmaptitle=uicontrol('Parent',me.hData.HBoxFolder,...
                    'Style','text','String','Colormap selection','FontSize',fontSize,...
                    'BackgroundColor','w','FontWeight','bold');
                me.hData.cmap=uicontrol('Parent',me.hData.HBoxFolder,...
                        'Style', 'popupmenu',...
                           'String', {'gray','hot','cool','bone','jet','hsv'},...
                           'Tag','Color map',...
                            'FontSize',fontSize,...
                            'BackgroundColor','w','FontWeight','bold',...
                           'Callback', @me.setcmap);  
                colormap gray;
                me.hData.HBoxFolder.Sizes=[-0.25 -1 -0.2 -0.2];
                
                % Layout: Import/Export calibration buttons: 
                
                me.hData.ExportCalib=uicontrol('String','Export Calibration','Parent',me.hData.HBoxCalib,...
                    'FontSize',fontSize,'Callback',@me.exportCalib);
                me.hData.ImportCalib=uicontrol('String','Import Calibration','Parent',me.hData.HBoxCalib,...
                    'FontSize',fontSize,'Callback',@me.importCalib);
                me.hData.ExportCalibforMM=uicontrol('String','Export Calibration for Micro-manager','Parent',me.hData.HBoxCalib,...
                    'FontSize',fontSize,'Callback',@me.exportCalibMM);
                
                
                
                % File selector for batch processing.
                
                me.hData.batchSelect=uicontrol('String','<html> Add files to analysis queue &darr;','Parent',me.hData.VBoxBatchFiles,...
                    'FontSize',fontSize,'Callback',@me.chooseBatch);
                me.hData.batchFileList=uicontrol('Style','text','Parent',me.hData.VBoxBatchFiles,'max',2); 
                me.hData.batchClear=uicontrol('String','Clear analysis queue','Parent',me.hData.VBoxBatchFiles,...
                    'FontSize',fontSize,'Callback',@me.clearBatch);
                me.hData.VBoxBatchFiles.Sizes=[30 -1 30];
                 
                
                % Batch analysis.
                me.hData.batchrun=uicontrol('String','<html> Process analysis queue <br> with current calibration','Parent',me.hData.HBoxBatchAnalyze,...
                    'FontSize',fontSize,'Callback',@me.runBatch,'HorizontalAlignment','center');
                uicontrol('Style','text','String','Status:', 'Parent',me.hData.HBoxBatchAnalyze,'FontSize',fontSize,'BackgroundColor','w','FontWeight','bold');
                me.hData.batchStatus=uicontrol('Style','text','String','', 'Parent',me.hData.HBoxBatchAnalyze,'FontSize',fontSize,'FontWeight','bold');
                me.hData.HBoxBatchAnalyze.Sizes=[-0.25 -0.2 -1];
            end
                
            function setupQuickCheckTab()
                me.hQuad.VBox=uiextras.VBox('Parent',me.hQuad.top,'BackgroundColor','w','Padding',5,'Spacing',5);

                 % Quick check.
                me.hQuad.HBoxQuick=uiextras.HBox('Parent',me.hQuad.VBox,'BackgroundColor','w');   
                me.hQuad.HBoxOptions=uiextras.HBox('Parent',me.hQuad.VBox,'BackgroundColor','w');   
                
                % Layout: Quick check
                me.hQuad.buttonFile=uicontrol('Parent',me.hQuad.HBoxQuick,'Style','pushbutton',...
                    'String','Select File...','Callback',@me.getQuickCheckFile,'FontWeight','Bold','FontSize',fontSize);
                me.hQuad.nameFile=uicontrol('Parent',me.hQuad.HBoxQuick,'Style','text',...
                    'String','','BackgroundColor','White','FontSize',fontSize,'FontWeight','bold');
                me.hQuad.selectAnalysis=uicontrol('Parent',me.hQuad.HBoxQuick,'Style','popupmenu',...
                    'String',{'Images/ROI','Blinking'},'Callback',@me.setupQuickCheckAnalysis,'FontWeight','Bold','FontSize',fontSize);
                

               
                me.hQuad.frameLabel=uicontrol('Parent',me.hQuad.HBoxQuick,'Style','text',...
                    'String','Frame #' ,'FontWeight','Bold','FontSize',fontSize-2,'BackgroundColor','w');
                me.hQuad.frameNo=uicontrol('Parent',me.hQuad.HBoxQuick,'Style','slider',...
                    'Value',uint16(1),'Min',0,'Max',1,'SliderStep',[1 1],'Callback',@me.updateQuickCheckFrame,'FontSize',fontSize-2,'BackgroundColor','w');
                me.hQuad.frameNoText=uicontrol('Parent',me.hQuad.HBoxQuick,'Style','text',...
                    'String',int2str(get(me.hQuad.frameNo,'Value')),'FontWeight','Bold','FontSize',fontSize-2,'BackgroundColor','w');
                me.hQuad.HBoxQuick.Sizes=[-0.2 -1 -0.2 100 100 100];                    
                
                me.hQuad.panelImgs=uipanel('Parent',me.hQuad.VBox,'BackgroundColor','w');
                me.hQuad.VBox.Sizes=[40 30 -1];
                me.setupQuickCheckAnalysis();
            end
            
            function setupRegistrationTab()
                % Layout VBox: Button HBox, parameters panel, image panel.
                me.hReg.VBox=uiextras.VBox('Parent',me.hReg.top,'BackgroundColor','w','Padding',5,'Spacing',5);
                me.hReg.HBoxButton=uiextras.HBox('Parent',me.hReg.VBox,'BackgroundColor','w');                
                me.hReg.panelParams=uipanel('Parent',me.hReg.VBox,'BackgroundColor','w',...
                    'Title','Registration parameters','FontWeight','Bold','FontSize',fontSize);
                me.hReg.panelImgs=uipanel('Parent',me.hReg.VBox,'BackgroundColor','w');
                me.hReg.VBox.Sizes=[30 -0.2  -1];   

                % Layout HBoxButton: action, filename.                

                me.hReg.buttonFile=uicontrol('Parent',me.hReg.HBoxButton,'Style','pushbutton',...
                    'String','Select file...','Callback',@me.getRegFile,'FontWeight','bold','FontSize',fontSize);
                me.hReg.nameFile=uicontrol('Parent',me.hReg.HBoxButton,'Style','text',...
                    'String','','BackgroundColor','White','FontSize',fontSize,'FontWeight','bold');
                me.hReg.buttonRun=uicontrol('Parent',me.hReg.HBoxButton,'Style','pushbutton',...
                    'String','Run','Callback',@me.regRTFP,'FontWeight','bold','FontSize',fontSize);
                me.hReg.HBoxButton.Sizes=[-0.2 -1 -0.2];   
                
                % Property grid that allows control of registration
                % parameters.

                regprops=[...
                    PropertyGridField('regMethod','auto',...
                    'Type',PropertyType('char','row',{'manual','reset','auto'}),'DisplayName','Registration method',...
                    'Description','manual: adjust all registration parameters manually, reset: clear registration parameters.'),...
                PropertyGridField('preProcReg','none',...
                     'Type',PropertyType('char','row',{'none','lowpass','edge'}),'DisplayName','Pre-process before registration',...
                     'Description','none: no filter, lowpass: useful to remove edges and debris, edge: useful for uniform specimens (e.g., isotropic solution)')...
                %PropertyGridField('regType','similarity',...
                %'Type',PropertyType('char','row',{'translation','rigid','similarity'}),'DisplayName','Type of spatial transformation',...
                %'Description','translation: shift in X and Y, rigid: shift and rotation, similarity: shift, rotation, and uniform scaling. Ignored for manual registration.')
                ];

                me.hReg.PGParams=PropertyGrid(me.hReg.panelParams,'Properties',regprops);


            end
            
            function setupNormalizationTab()
                % Layout VBox: Button HBox, parameters panel, image panel.
                me.hNorm.VBox=uiextras.VBox('Parent',me.hNorm.top,'BackgroundColor','w','Padding',5,'Spacing',5);
                me.hNorm.HBoxButton=uiextras.HBox('Parent',me.hNorm.VBox,'BackgroundColor','w');
                me.hNorm.panelParams=uipanel('Parent',me.hNorm.VBox,'BackgroundColor','w',...
                    'Title','Normalization parameters','FontWeight','Bold','FontSize',fontSize);
                me.hNorm.panelImgs=uipanel('Parent',me.hNorm.VBox,'BackgroundColor','w');
                me.hNorm.VBox.Sizes=[30 -0.3 -1];   

                % Layout HBoxButton: action, filename.                
                
                me.hNorm.buttonFile=uicontrol('Parent',me.hNorm.HBoxButton,'Style','pushbutton',...
                    'String','Select file...','Callback',@me.getNormFile,'FontWeight','bold','FontSize',fontSize);
                me.hNorm.nameFile=uicontrol('Parent',me.hNorm.HBoxButton,'Style','text',...
                    'String','','BackgroundColor','White','FontSize',fontSize,'FontWeight','bold');
                me.hNorm.buttonRun=uicontrol('Parent',me.hNorm.HBoxButton,'Style','pushbutton',...
                    'String','Run','Callback',@me.normRTFP,'FontWeight','bold','FontSize',fontSize);
                me.hNorm.HBoxButton.Sizes=[-0.2 -1 -0.2];   
                
                % Property grid that allows control of registration
                % parameters.

                normprops=[...
                    PropertyGridField('normMethod','fromImage',...
                    'Type',PropertyType('char','row',{'manual','reset','fromImage'}),'DisplayName','Normalization method'),...
                PropertyGridField('normROI',round([0.25*me.RTFP.quadWidth 0.25*me.RTFP.quadHeight 0.5*me.RTFP.quadWidth 0.5*me.RTFP.quadHeight]),...
                    'Type',PropertyType('denserealdouble','row'),'DisplayName','ROI to use for manual normalization',...
                    'Description','Fromat: [xTopLeft yTopLeft Width Height], all in pixels.')...
                PropertyGridField('normalizeExcitation',false,...
                     'Type',PropertyType('logical','scalar'),'DisplayName','Normalize specimen-depedent excitation imbalance?',...
                     'Description','Each execution either normalizes excitation imbalance or detection imbalance.')...
                ];

                me.hNorm.PGParams=PropertyGrid(me.hNorm.panelParams,'Properties',normprops);
            end
            
            function setupPolTab()
               % Layout VBox: Button HBox, parameters panel, image panel.
                me.hPol.VBox=uiextras.VBox('Parent',me.hPol.top,'BackgroundColor','w','Padding',5,'Spacing',5);
                me.hPol.HBoxButton=uiextras.HBox('Parent',me.hPol.VBox,'BackgroundColor','w');
                me.hPol.panelParams=uipanel('Parent',me.hPol.VBox,'BackgroundColor','w',...
                    'Title','Pol-calibration parameters','FontWeight','Bold','FontSize',fontSize);
                me.hPol.panelImgs=uipanel('Parent',me.hPol.VBox,'BackgroundColor','w');
                me.hPol.VBox.Sizes=[30 -0.3 -1];   

                % Layout HBoxButton: action, filename.                
                
                me.hPol.buttonFile=uicontrol('Parent',me.hPol.HBoxButton,'Style','pushbutton',...
                    'String','Select file ...','Callback',@me.getPolFile,'FontWeight','bold','FontSize',fontSize);
                me.hPol.nameFile=uicontrol('Parent',me.hPol.HBoxButton,'Style','text',...
                    'String','','BackgroundColor','White','FontSize',fontSize,'FontWeight','bold');
                me.hPol.buttonRun=uicontrol('Parent',me.hPol.HBoxButton,'Style','pushbutton',...
                    'String','Run','Callback',@me.polRTFP,'FontWeight','bold','FontSize',fontSize);                
                me.hPol.HBoxButton.Sizes=[-0.2 -1 -0.2];   
                
                % Property grid that allows control of pol-calibration parameters.

                polprops=[...
                    PropertyGridField('polType','tangential',...
                    'Type',PropertyType('char','row',{'tangential','radial','linearRotated','reset'}),'DisplayName','Calibrate using',...
                    'Description','Type determined by pattern of transmission axis of polarizer. reset removes the current pol-calibration.'),...
                    PropertyGridField('center',[],...
                     'Type',PropertyType('denserealdouble','row'),'DisplayName','Center of tangential or radial polarizer',...
                     'Description','Center of polarizer [x y] in pixels. Leaving this value empty [] allows you to select the center.'),...
                    PropertyGridField('linpolOrient',0:45:135,...
                     'Type',PropertyType('denserealdouble','row'),'DisplayName','Orientations of linear polarizer',...
                     'Description','Orientation at which the linear polarizer was placed in the specimen/primary image plane. A vector the same size as number of slices in the pol-calibration stack.'),...
                    PropertyGridField('maxRadius',0.5*0.707*me.RTFP.quadWidth,...
                     'Type',PropertyType('denserealdouble','scalar',[10 0.5*0.707*me.RTFP.quadWidth]),...
                     'Description',' Radius (pixels) up to which intensity variations are accurate')... 
                    PropertyGridField('NeedsSeparateReg',false,...
                     'Type',PropertyType('logical','scalar'),...
                     'Description','Setting true allows you to select a calibration .mat file from which registration parameters for tangential polarizer are used.')... 
                     ];

                me.hPol.PGParams=PropertyGrid(me.hPol.panelParams,'Properties',polprops);                
            end
            
            function setupAboutTab()
                % VBox: quick-start, license, author and copyright.
                me.hAbout.VBox=uiextras.VBox('Parent',me.hAbout.top,'BackgroundColor','w','Padding',5,'Spacing',5);
                licenseFile=fopen('RTFluorPolLicense.txt');
                licenseText=textscan(licenseFile,'%s','delimiter','\n');
                fclose(licenseFile);
                helpFile=fopen('RTFluorPolQuickStart.txt');
                helpText=textscan(helpFile,'%s','delimiter','\n');
                fclose(helpFile);
               
                helpTitle=helpText{1}{1};
                helpText=helpText{1}(2:end);
                licenseTitle=licenseText{1}{1};
                licenseText=licenseText{1}(2:end);
                me.hAbout.helpPanel=uipanel('Parent',me.hAbout.VBox,...
                    'Title',helpTitle,'BackgroundColor','w','FontSize',fontSize,'FontWeight','bold');
                me.hAbout.licensePanel=uipanel('Parent',me.hAbout.VBox,...
                    'Title',licenseTitle,'BackgroundColor','w','FontSize',fontSize,'FontWeight','bold');
                
                me.hAbout.help=uicontrol('Parent',me.hAbout.helpPanel,'Style','text','max',2',...
                    'String',helpText,'BackgroundColor','w','FontSize',fontSize,'HorizontalAlignment','left','Units','Normalized','Position',[0 0 1 1]);  
                me.hAbout.license=uicontrol('Parent',me.hAbout.licensePanel,'Style','text','max',2',...
                    'String',licenseText,'BackgroundColor','w','FontSize',fontSize,'HorizontalAlignment','left','Units','Normalized','Position',[0 0 1 1]);

                me.hAbout.VBox.Sizes=[-1 -0.3];
            end   
            
            function setupParticleTab()
              % Layout VBox: Button HBox, parameters panel, image panel.
                me.hParticle.VBox=uiextras.VBoxFlex('Parent',me.hParticle.top,'BackgroundColor','w','Padding',5,'Spacing',5);
                me.hParticle.HBoxButton=uiextras.HBox('Parent',me.hParticle.VBox,'BackgroundColor','w');
                me.hParticle.panelParams=uipanel('Parent',me.hParticle.VBox,'BackgroundColor','w',...
                    'Title','Particle analysis parameters','FontWeight','Bold','FontSize',fontSize);
                me.hParticle.panelImgs=uipanel('Parent',me.hParticle.VBox,'BackgroundColor','w');
                me.hParticle.HBoxStatus=uiextras.HBox('Parent',me.hParticle.VBox,'BackgroundColor','w','Padding',5,'Spacing',5);
                me.hParticle.VBox.Sizes=[30 -0.45 -1 -0.05];   

                % Layout HBoxButton: action, filename.                
                
                me.hParticle.buttonFile=uicontrol('Parent',me.hParticle.HBoxButton,'Style','pushbutton',...
                    'String','Select file ...','Callback',@me.getParticleFile,'FontWeight','bold','FontSize',fontSize);
                me.hParticle.nameFile=uicontrol('Parent',me.hParticle.HBoxButton,'Style','text',...
                    'String','','BackgroundColor','White','FontSize',fontSize,'FontWeight','bold');
                me.hParticle.buttonRun=uicontrol('Parent',me.hParticle.HBoxButton,'Style','pushbutton',...
                    'String','Run','Callback',@me.particleRTFP,'FontWeight','bold','FontSize',fontSize);                
                me.hParticle.HBoxButton.Sizes=[-0.2 -1 -0.2];   
                
                % Layout HBoxStatus: Status message for particle
                % analysis/display.
                me.hParticle.status=uicontrol('Parent',me.hParticle.HBoxStatus,'Style','text',...
                    'String','','BackgroundColor','White','FontSize',fontSize,'FontWeight','bold');
                % Property grid that allows control of particle analysis
                % parameters.
                
                particleprops=[...   
                    PropertyGridField('ParticleDetectionFile','',...
                     'Type',PropertyType('char','row'),...
                     'Description','.mat file for saving/loading the results of particle detection.','Category','Analysis'),...                     
                    PropertyGridField('ParticleDetection','speckles',...
                     'Type',PropertyType('char','row',{'particles','speckles','computeAnisotropy','load'}),...
                     'Description','run particle detection or load from file the specified .mat file.','Category','Analysis'),...                     
                    PropertyGridField('psfSigma',(0.2*me.RTFP.Wavelength/me.RTFP.ObjectiveNA)/me.RTFP.PixSize,...
                     'Type',PropertyType('denserealdouble','scalar'),'Description','Standard deviation of the Gaussian (default: 0.25*Wavelength/NA expressed in pixels).','Category','Analysis'),...
                    PropertyGridField('startframe',uint16(1),...
                     'Type',PropertyType('denserealdouble','scalar',[1 inf]),...
                     'Description',' Start particle analysis at frame.','Category','Analysis'),... 
                    PropertyGridField('endframe',uint16(1),...
                     'Type',PropertyType('denserealdouble','scalar',[1 inf]),...
                     'Description',' End particle analysis at frame.','Category','Analysis'),...
                    PropertyGridField('backgroundAverage',300,...
                     'Type',PropertyType('denserealdouble','scalar',[1 2^16-1]),...
                     'Description',' Average background intensity.','Category','Analysis'),...
                    PropertyGridField('backgroundSD',100,...
                     'Type',PropertyType('denserealdouble','scalar',[1 2^16-1]),...
                     'Description','Standard deviation of the background intensity (without perceptible fluorescence).','Category','Analysis'),...
                    PropertyGridField('alphaLocalMaxima',0.05,...
                     'Type',PropertyType('denserealdouble','scalar',[0.01 1]),...
                     'Description','alpha-value for statistical test of local maxima relative to background (0.01 to 1).','Category','Analysis'),...                     
                    PropertyGridField('diagnosis',false,...
                     'Type',PropertyType('logical','scalar'),...
                     'Description','Setting true generates a ''barcode'' of particles found in each frame.','Category','Analysis'),...
                    PropertyGridField('singleMolecule',true,...
                     'Type',PropertyType('logical','scalar'),...
                     'Description','If the single molecule flag is set, the detection does not attempt to find multiple maxima within diffraction-limited region.','Category','Analysis'),...                       
                    ....................................................................................................
                    PropertyGridField('displayAfterAnalysis','histogram',...
                     'Type',PropertyType('char','row',{'nothing','exportForTracking','histogram','particles'}),...
                     'Description','What to do/show after analysis?','Category','Display'),...  
                    PropertyGridField('selectROI',false,...
                     'Type',PropertyType('logical','scalar'),...
                     'Description','If true, you can select ROI over which particles are analyzed.','Category','Display'),...                      
                   PropertyGridField('orientationRelativeToROI',false,...
                     'Type',PropertyType('logical','scalar'),...
                     'Description','Subtract orientation of ROI from measured orientation.','Category','Display'),...                      
                    PropertyGridField('intensityRange',uint16([0 0]),...
                     'Type',PropertyType('denserealdouble','row'),...
                     'Description','[0 0] sets range automatically.','Category','Display'),...
                    PropertyGridField('anisotropyRange',[0 1],...
                     'Type',PropertyType('denserealdouble','row'),...
                     'Description','Threshold particles based on anisotropy.','Category','Display'),...
                    PropertyGridField('orientationRange',[0 180],...
                     'Type',PropertyType('denserealdouble','row'),...
                     'Description','Threshold particles based on orientation.','Category','Display'),...
                    PropertyGridField('excludeAboveOrientation',false,...
                     'Type',PropertyType('logical','scalar'),...
                     'Description','Display particles outside of above orientation range.','Category','Display'),...                                                                
                     .................................................................................................
                     PropertyGridField('nBins',uint16(30),...
                     'Type',PropertyType('denserealdouble','scalar'),...
                     'Description','Number of bins in the histogram.','Category','Histogram'),...
                     PropertyGridField('exportHistograms',true,...
                     'Type',PropertyType('logical','scalar'),...
                     'Description','Setting true exports the image of histograms and adds the bins/counts to the .mat file with particle information.','Category','Histogram'),... 
                    PropertyGridField('histogramType','individual',...
                     'Type',PropertyType('char','row',{'individual','joint'}),...
                     'Description','individual: Display histograms of intensity/anisotropy/orientation separately. joint: anisotropy/orientation as a function of intensity.','Category','Histogram'),...  
                    PropertyGridField('orientationHistogramType','xy',...
                     'Type',PropertyType('char','row',{'xy','polar'}),...
                     'Description','','Category','Histogram'),...                       
                      ...........................................................................                  
                    PropertyGridField('drawParticlesOn','average',...
                    'Type',PropertyType('char','row',{'average','anisotropy','orientation','orientationmap','selectPath'}),...
                    'Description','Choose the chanel on which particles are overlaid.','Category','Particles'),...
                     PropertyGridField('exportMovie',true,...
                     'Type',PropertyType('logical','scalar'),...
                     'Description','Setting true generates a movie in ParticleAnalysis folder inside datafolder.','Category','Particles'),... 
                    PropertyGridField('delayBeforeScreenShot',0.05,...
                     'Type',PropertyType('denserealdouble','scalar'),...
                     'Description','Delay in seconds between display of successive frames.','Category','Particles'),... 
                     PropertyGridField('lineLength',50,...
                     'Type',PropertyType('denserealdouble','scalar'),...
                     'Description','Length of the line that shows the orientation of the particle.','Category','Particles'),...                      
                     PropertyGridField('markerSize',6,...
                     'Type',PropertyType('denserealdouble','scalar'),...
                     'Description','Size of the marker that identifies the particle.','Category','Particles'),... 
                      PropertyGridField('glyphColor','green',...
                     'Type',PropertyType('char','row',{'red','green','blue','white','black','magenta','yellow','cyan'}),...
                     'Description','Color of the glyph','Category','Particles'),... 
                     ];

                me.hParticle.PGParams=PropertyGrid(me.hParticle.panelParams,'Properties',particleprops);                               
            end
            
        function setupStatTab()
              % Layout VBox: Button HBox, parameters panel, image panel.
                me.hStat.VBox=uiextras.VBoxFlex('Parent',me.hStat.top,'BackgroundColor','w','Padding',5,'Spacing',5);
                me.hStat.HBoxButton=uiextras.HBox('Parent',me.hStat.VBox,'BackgroundColor','w');
                me.hStat.panelParams=uipanel('Parent',me.hStat.VBox,'BackgroundColor','w',...
                    'Title','Statistical analysis parameters','FontWeight','Bold','FontSize',fontSize);
                me.hStat.panelImgs=uipanel('Parent',me.hStat.VBox,'BackgroundColor','w');
                me.hStat.HBoxStatus=uiextras.HBox('Parent',me.hStat.VBox,'BackgroundColor','w','Padding',5,'Spacing',5);
                me.hStat.VBox.Sizes=[30 -0.45 -1 -0.05];   

                % Layout HBoxButton: action, filename.                
                
                me.hStat.buttonFile=uicontrol('Parent',me.hStat.HBoxButton,'Style','pushbutton',...
                    'String','Select file ...','Callback',@me.getStatsFile,'FontWeight','bold','FontSize',fontSize);
                me.hStat.nameFile=uicontrol('Parent',me.hStat.HBoxButton,'Style','text',...
                    'String','','BackgroundColor','White','FontSize',fontSize,'FontWeight','bold');
                me.hStat.buttonRun=uicontrol('Parent',me.hStat.HBoxButton,'Style','pushbutton',...
                    'String','Run','Callback',@me.statRTFP,'FontWeight','bold','FontSize',fontSize);                
                me.hStat.HBoxButton.Sizes=[-0.2 -1 -0.2];   
                
                % Layout HBoxStatus: Status message for particle
                % analysis/display.
                me.hStat.status=uicontrol('Parent',me.hStat.HBoxStatus,'Style','text',...
                    'String','','BackgroundColor','White','FontSize',fontSize,'FontWeight','bold');
                % Property grid that allows control of particle analysis
                % parameters.
                
                statprops=[...   
                    PropertyGridField('ExportToFile','',...
                     'Type',PropertyType('char','row'),...
                     'Description','.mat file for saving/loading the results of ensemble statistics.','Category','Analysis'),...                     
                   PropertyGridField('SegmentationMethod','roi',...
                     'Type',PropertyType('char','row',{'roi','label stack'}),...
                     'Description','Select a ROI or a TIFF stack with labeled masks for regions','Category','Analysis'),...                     
                    PropertyGridField('startframe',uint16(1),...
                     'Type',PropertyType('denserealdouble','scalar',[1 inf]),...
                     'Description',' Start statistical analysis at frame.','Category','Analysis'),... 
                    PropertyGridField('endframe',uint16(1),...
                     'Type',PropertyType('denserealdouble','scalar',[1 inf]),...
                     'Description',' End statistical analysis at frame.','Category','Analysis'),...  
                 PropertyGridField('EnsembleOrientationRelativeToROI',true,...
                     'Type',PropertyType('logical','scalar'),...
                     'Description',' Compute ensemble orientation relative to the long axis of the ROI.','Category','Analysis'),...  
                 PropertyGridField('ExportMovieofROIAndHistogram',true,...
                     'Type',PropertyType('logical','scalar'),...
                     'Description',' Exports a movie showing the image, ROI, and the molecular histogram.','Category','Analysis'),...  
                PropertyGridField('ROIToDisplay',uint8(1),...
                     'Type',PropertyType('uint8','scalar'),...
                     'Description',' If label stack is passed, select a ROI to use for display.','Category','Analysis'),...  
                     ];
                 

                me.hStat.PGParams=PropertyGrid(me.hStat.panelParams,'Properties',statprops);                               
            end
            
            
            
            
        end
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%  Callbacks %%%%%%%%%%%%%%%%%%%%%%%%
        % Most of the callbacks are methods within the RTFluorPol which can
        % draw on a parent canvas when specified and on a new figure when
        % not specified.
        function changeFolder(me,varargin)
            changeDir=uigetdir();
            if(changeDir)
                me.dataFolder=changeDir;
                cd(changeDir);
                set(me.hData.nameFolder,'String',changeDir);
            end
        end
        
        function setcmap(me,varargin)
            % Set colormap.
            list=get(me.hData.cmap,'String');
            value=get(me.hData.cmap,'value');
            colormap(eval(list{value}));
        end
        
        function getRegFile(me,varargin)
            % Get registration file.
            [filename,pathname]=uigetfile({'*.tif','*.tiff'},'Select registration image.');
            if(filename)
                set(me.hReg.nameFile,'String',[pathname filename]);
            end
        end
        
        
        function updateQuickCheckFrame(me,varargin)
            % Callback for frameNo slider on quick check tab. Simply
            % updates the text.
            set(me.hQuad.frameNoText,'String',int2str(get(me.hQuad.frameNo,'Value')));
            % Call the function to plot the results.
             me.checkRTFP('frameUpdate',NaN,NaN,NaN,NaN,NaN,NaN,NaN);
        end
        
        function updateQuickCheckFrameRange(me,varargin)
            % Callback for frameNo slider on quick check tab. Simply
            % updates the text.
            set(me.hQuad.blinkRangeText,'String',int2str(get(me.hQuad.blinkRange,'Value')));
            % Call the function to plot the results.
             me.checkRTFP('frameUpdate',NaN,NaN,NaN,NaN,NaN,NaN,NaN);
        end
        
        function setupQuickCheckAnalysis(me,varargin)
            fontSize=12;
            datafile=get(me.hQuad.nameFile,'string');
            if(exist(datafile,'file'))
                switch(get(me.hQuad.selectAnalysis,'Value'))
                    case 1 %'Images/ROI Histogram'
                        delete(get(me.hQuad.HBoxOptions,'Children'));
                        me.hQuad.dummyText=uicontrol('Parent',me.hQuad.HBoxOptions,'Style','text',...
                            'String','' ,'FontWeight','Bold','FontSize',fontSize-2,'BackgroundColor','w');
                        me.hQuad.analyzeROI=uicontrol('Parent',me.hQuad.HBoxOptions,'Style','checkbox',...
                            'String',{'ROI histogram?'},'value',false,'FontWeight','Bold','FontSize',fontSize-2,'BackgroundColor','w');                    
                        me.hQuad.histMolecule=uicontrol('Parent',me.hQuad.HBoxOptions,'Style','checkbox',...
                        'String',{'Molecular histogram?'},'value',false,'FontWeight','Bold','FontSize',fontSize-2,'BackgroundColor','w');
                        me.hQuad.orientationRelativeToROI=uicontrol('Parent',me.hQuad.HBoxOptions,'Style','checkbox',...
                        'String',{'Orientation relative to the long axis of ROI?'},'value',false,'FontWeight','Bold','FontSize',fontSize-2,'BackgroundColor','w');
                        me.hQuad.HBoxOptions.Sizes=[-0.3 -0.2 -0.2 -0.3];

                    case 2 %'Blinking'
                        delete(get(me.hQuad.HBoxOptions,'Children'));
                        me.hQuad.dummyText=uicontrol('Parent',me.hQuad.HBoxOptions,'Style','text',...
                            'String','' ,'FontWeight','Bold','FontSize',fontSize-2,'BackgroundColor','w');

                        me.hQuad.blinkLabel=uicontrol('Parent',me.hQuad.HBoxOptions,'Style','text',...
                            'String','Span around current frame' ,'FontWeight','Bold','FontSize',fontSize-2,'BackgroundColor','w');                    
                        maxRange=get(me.hQuad.frameNo,'Max');
                        me.hQuad.blinkRange=uicontrol('Parent',me.hQuad.HBoxOptions,'Style','slider',...
                            'Value',uint16(1),'Min',0,'Max',maxRange,'SliderStep',[1 5]/maxRange,'Callback',@me.updateQuickCheckFrameRange,'FontSize',fontSize-2,'BackgroundColor','w');
                        me.hQuad.blinkRangeText=uicontrol('Parent',me.hQuad.HBoxOptions,'Style','text',...
                            'String',int2str(get(me.hQuad.blinkRange,'Value')),'FontWeight','Bold','FontSize',fontSize-2,'BackgroundColor','w');
                        me.hQuad.HBoxOptions.Sizes=[-1 200 100 100];
                end
            else
                delete(get(me.hQuad.HBoxOptions,'Children'));
            end
        end
        
        function getNormFile(me,varargin)
            [filename,pathname]=uigetfile({'*.tif','*.tiff'},'Select normalization image.');
            if(filename)
                set(me.hNorm.nameFile,'String',[pathname filename]);
            end
        end

        function getPolFile(me,varargin)
            [filename,pathname]=uigetfile({'*.tif','*.tiff'},'Select image of a polarizer.');
            if(filename)
                set(me.hPol.nameFile,'String',[pathname filename]);
            end
        end 
        

        function getParticleFile(me,varargin)
            [filename,pathname]=uigetfile({'*.tif','*.tiff'},'Select the series for particle analysis.');
            if(filename)
                set(me.hParticle.nameFile,'String',[pathname filename]);
                [~,dataname]=fileparts([pathname filename]);
                
                % If the data comes from micro-manager, omit _MMStack.ome
                % from the filename of particles.
                MMstart=strfind(dataname,'MMStack');
                if(MMstart)
                    dataname=dataname(1:MMstart-2);
                end
                
                mkdir([pathname filesep 'ParticleDetection']);
                particlefile=[pathname 'ParticleDetection' filesep dataname '.mat'];
                me.hParticle.PGParams.UpdateFields({'ParticleDetectionFile'},{particlefile});
                
            end
        end 
        
        function getStatsFile(me,varargin)
            [filename,pathname]=uigetfile({'*.tif','*.tiff'},'Select the series for statistical analysis.');
            if(filename) %filename has extension.
                set(me.hStat.nameFile,'String',[pathname filename]);
                [~,dataname]=fileparts([pathname filename]);        
                
                % If the data comes from micro-manager, omit _MMStack.ome
                % from the filename of statistics.
                MMstart=strfind(dataname,'MMStack');
                if(MMstart)
                    dataname=dataname(1:MMstart-2);
                end
                                
                mkdir([pathname filesep 'Statistics']);
                statsfile=[pathname 'Statistics' filesep dataname '.mat'];
                me.hStat.PGParams.UpdateFields({'ExportToFile'},{statsfile});
            end
        end        
        
        checkRTFP(me,varargin)
        regRTFP(me,varargin)
        updateRegPG(me,varargin) 
        normRTFP(me,varargin)
        updateNormPG(me,varargin)      
        polRTFP(me,varargin)
        particleRTFP(me,varargin)
        statRTFP(me,varargin)
        runBatch(me,varargin)
        
        function exportCalib(me,varargin)

            
            [calibFile, folder]=uiputfile('*.mat','Select a file to store calibration information',[me.dataFolder]);
            if(calibFile)
                % Export MATLAB file suitable for import.
                RTFPCalib=me.RTFP;
                save([folder calibFile],'RTFPCalib');
            end
                

        end
            
        function exportCalibMM(me,varargin)        % Export parameters for Pol-Acquisition/Micro-manager.
            folder=[me.dataFolder '/calib/'];
            [success,message]=mkdir(folder);
            if(~success)
                error(message);
            end
                folder=uigetdir(folder,'Select a folder to store calibration for Micro-Manager as text files');
                
                if(folder)
                    dlmwrite([folder '/tformI45.txt'],MAT2IJaffine(me.RTFP.tformI45),'\t');
                    dlmwrite([folder '/tformI90.txt'],MAT2IJaffine(me.RTFP.tformI90),'\t');
                    dlmwrite([folder '/tformI135.txt'],MAT2IJaffine(me.RTFP.tformI135),'\t');
                    
                    dlmwrite([folder '/BlackLevel.txt'],me.RTFP.BlackLevel,'\t');

                    NormI45mean=me.RTFP.NormI45(me.RTFP.NormI45~=1);
                    NormI45mean=mean(NormI45mean);
                  
                    NormI90mean=me.RTFP.NormI90(me.RTFP.NormI90~=1);
                    NormI90mean=mean(NormI90mean);

                    NormI135mean=me.RTFP.NormI135(me.RTFP.NormI135~=1);
                    NormI135mean=mean(NormI135mean);
                    
                    dlmwrite([folder '/NormI45.txt'],NormI45mean,'\t');
                    dlmwrite([folder '/NormI90.txt'],NormI90mean,'\t');
                    dlmwrite([folder '/NormI135.txt'],NormI135mean,'\t');
                    
                    imwrite2tif(me.RTFP.NormI45,'',[folder '/NormI45.tif'],'single');
                    imwrite2tif(me.RTFP.NormI90,'',[folder '/NormI90.tif'],'single');
                    imwrite2tif(me.RTFP.NormI135,'',[folder '/NormI135.tif'],'single');
                    
                    dlmwrite([folder '/ItoSMatrix.txt'],me.RTFP.ItoSMatrix,'\t');
                    dlmwrite([folder '/I0.txt'],me.RTFP.BoundingBox.I0-[1 1 0 0],'\t');
                    dlmwrite([folder '/I45.txt'],me.RTFP.BoundingBox.I45-[1 1 0 0],'\t');
                    dlmwrite([folder '/I90.txt'],me.RTFP.BoundingBox.I90-[1 1 0 0],'\t');
                    dlmwrite([folder '/I135.txt'],me.RTFP.BoundingBox.I135-[1 1 0 0],'\t');
                    dlmwrite([folder '/quadWidth.txt'],me.RTFP.quadWidth);
                    dlmwrite([folder '/quadHeight.txt'],me.RTFP.quadHeight);
                end
                
            function IJaffine=MAT2IJaffine(MATaffine)
                % Function that converts a MATLAB 2D affine matrix into
                % ImageJ's TransformJ pluglin's 3D affine format.
                % ImageJ uses a transposed version of MATLAB's
                % transformation matrix.
                
                MATaffine=MATaffine';
                IJaffine=eye(4);
                IJaffine(1:2,1:2)=MATaffine(1:2,1:2);
                IJaffine(1,end)=MATaffine(1,end);
                IJaffine(2,end)=MATaffine(2,end);
                
            end
        end
            
        function importCalib(me,varargin)
            [calibFile, folder]=uigetfile('*.mat','Select a file with calibration information',[me.dataFolder]);
            if(calibFile)
                load([folder calibFile],'RTFPCalib');
                if(isequal(RTFPCalib.tformI45,eye(3))) 
                    % If the registration parameters are not set, the data may be from older RTFluorPol class, in which these properties were dependent. 
                    % Need to update them in the UI and in the file. 
                  RTFPCalib.tformI45=ShiftScaleRotToaffine(RTFPCalib.I45xShift,RTFPCalib.I45yShift,...
                      RTFPCalib.I45xScale,RTFPCalib.I45yScale,RTFPCalib.I45Rotation);
                  RTFPCalib.tformI90=ShiftScaleRotToaffine(RTFPCalib.I90xShift,RTFPCalib.I90yShift,...
                      RTFPCalib.I90xScale,RTFPCalib.I90yScale,RTFPCalib.I90Rotation);
                  RTFPCalib.tformI135=ShiftScaleRotToaffine(RTFPCalib.I135xShift,RTFPCalib.I135yShift,...
                      RTFPCalib.I135xScale,RTFPCalib.I135yScale,RTFPCalib.I135Rotation);  
                  save([folder calibFile],'RTFPCalib');
                end
                
                me.RTFP=RTFPCalib;
                instantPolGUI.setupRTFPPropertyGrid(me.hPG,me.RTFP,me.paramsN,me.paramsR);
            end
        end
        
        function chooseBatch(me,varargin)
            [fileList, folder]=uigetfile({'*.tif','*.tiff'},'Select the file(s) to process',me.dataFolder,'MultiSelect','on');
            if(ischar(fileList))
                fileList={[folder  fileList]};
                currentList=get(me.hData.batchFileList,'String');
                updatedList=[currentList; fileList'];
            elseif(iscellstr(fileList))
                fileList=cellfun(@(x) [folder  x],fileList,'UniformOutput',false);
                currentList=get(me.hData.batchFileList,'String');
                updatedList=[currentList; fileList'];
            end
                set(me.hData.batchFileList,'String',updatedList);            
        end
        
        function clearBatch(me,varargin)
            set(me.hData.batchFileList,'String','');
        end

    end
    
    methods (Static) 
        setupRTFPPropertyGrid(hPG,RTFPObject,paramsN,paramsR)
    end
end
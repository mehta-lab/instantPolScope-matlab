function regQuadsManual(self,I0,I45,I90,I135,varargin)
% [tformI45,tformI90,tformI135]=regQuadsManual(I0,I45,I90,I135)
% Optional arguments 
%   Parameter           Value
%   'ShiftRange'        2-value vector [minshift maxshift] in pixels.
%   'RotationRange'     2-value vector [minrotation maxrotation] in deg.
%   'ScaleRange'        2-value vector [minscale maxscale].



%% Assign defaults to optional arguments
optargs.ShiftRange=[-25 25];
optargs.RotationRange=[-50 50];
optargs.ScaleRange=[1/1.5 1.5];
optargs.Parent=NaN;
optargs.regEndCallBack=NaN; % Handle to the function that is executed when Done button is pressed.
optargs.WaitForClose=false; % Set true if running from script and need to wait for user to finish registration step manually.
optargs=parsepropval(optargs,varargin{:});

if(~isa(optargs.regEndCallBack, 'function_handle'))
    optargs.regEndCallBack=@closefunction;
end
%% Declare variables and handles accessible to all callbacks.
I0=double(I0); I45=double(I45); I90=double(I90); I135=double(I135);
I45reg=imtransformAffineMat(I45,self.tformI45,'cubic','coordinates','centered');
I90reg=imtransformAffineMat(I90,self.tformI90,'cubic','coordinates','centered');
I135reg=imtransformAffineMat(I135,self.tformI135,'cubic','coordinates','centered');
xshift=0; yshift=0; rotation=0; xscale=1; yscale=1; % Values of controls in the UI.


%% Initialize main figure
if(isnan(optargs.Parent))
    hdl.mainfig = togglefig('Manual adjustment to registration',1);
        jFrame = get(handle(hdl.mainfig),'JavaFrame');
    jFrame.setMaximized(true);
    set(hdl.mainfig,'CloseRequestFcn',@closefunction,...
        'defaultaxesfontsize',15,'Units','normalized','Toolbar','figure');
else
    hdl.mainfig=optargs.Parent;
    delete(get(hdl.mainfig,'Children'));
end


hdl.a0=axes('Units','normalized','Position',[0.02 0.5 0.25 0.4],'Parent',hdl.mainfig);
hdl.diff=axes('Units','normalized','Position',[0.02 0.01 0.25 0.4],'Parent',hdl.mainfig);
hdl.moving=axes('Units','normalized','Position',[0.3 0.5 0.25 0.4],'Parent',hdl.mainfig);
hdl.pair=axes('Units','normalized','Position',[0.3 0.01 0.25 0.4],'Parent',hdl.mainfig);
hdl.aAniso=axes('Units','normalized','Position',[0.6 0.5 0.25 0.4],'Parent',hdl.mainfig);
hdl.aOrient=axes('Units','normalized','Position',[0.6 0.01 0.25 0.4],'Parent',hdl.mainfig);


hdl.CmapTitle=uicontrol('Parent',hdl.mainfig,...
    'Style', 'text',...
    'String','Colormap',...
    'Units','normalized',...
    'Position',[0.86 0.88 0.05 0.02],...
    'FontSize',10);

hdl.popCmap=uicontrol('Parent',hdl.mainfig,...
    'Style', 'popupmenu',...
       'String', {'gray','hot','cool','bone','jet'},...
       'Units','normalized',...
       'Position', [0.86 0.84 0.06 0.04],...
        'FontSize',10,...
       'Callback', @setcmap);  

   hdl.popImageTitle=uicontrol('Parent',hdl.mainfig,...
    'Style', 'text',...
    'String','Select Image',...
    'Units','normalized',...
    'Position',[0.92 0.88 0.07 0.02],...
    'FontSize',10);


% This control selects the image to be adjusted.
    ImageLabelList= {'I0','I45','I90','I135'};
    % Titles to place on top of the axes.
   ImageTitleList={'Displaying I0',...
                    'Adjusting I45',...
                    'Adjusting I90',...
                    'Adjusting I135'};
   hdl.popImage=uicontrol('Parent',hdl.mainfig,...
    'Style', 'popupmenu',...
       'String',ImageLabelList,...
       'Units','normalized',...
       'Position', [0.92 0.84 0.07 0.04],...
        'FontSize',10,...
       'Callback', @selectimage);  

   [hdl.rControlS,hdl.rControlP,hdl.rControlE]=sliderPanel(...
    'Parent',hdl.mainfig,...
    'Title','Rotation',...
    'Position',[0.86 0.7 0.12 0.12],...
    'Min',optargs.RotationRange(1),...
    'Max',optargs.RotationRange(2),...
    'Value',mean(optargs.RotationRange),...
    'SliderStep',[0.001 0.001],...
    'FontSize',10,...
    'Callback',@rControl);

[hdl.sxControlS,hdl.sxControlP,hdl.sxControlE]=sliderPanel(...
    'Parent',hdl.mainfig,...
    'Title','Horizontal Scaling',...
    'Position',[0.86 0.55 0.12 0.12],...
    'Min',optargs.ScaleRange(1),...
    'Max',optargs.ScaleRange(2),...
    'Value',mean(optargs.ScaleRange),...
    'SliderStep',[0.001 0.001],...
    'FontSize',10,...
    'Callback',@sxControl);

[hdl.syControlS,hdl.syControlP,hdl.syControlE]=sliderPanel(...
    'Parent',hdl.mainfig,...
    'Title','Vertical Scaling',...
    'Position',[0.86 0.4 0.12 0.12],...
    'Min',optargs.ScaleRange(1),...
    'Max',optargs.ScaleRange(2),...
    'Value',mean(optargs.ScaleRange),...
    'SliderStep',[0.001 0.001],...
    'FontSize',10,...
    'Callback',@syControl);

[hdl.xControlS,hdl.xControlP,hdl.xControlE]=sliderPanel(...
    'Parent',hdl.mainfig,...
    'Title','Horizontal Shift',...
    'Position',[0.86 0.25 0.12 0.12],...
    'Min',optargs.ShiftRange(1),...
    'Max',optargs.ShiftRange(2),...
    'Value',mean(optargs.ShiftRange),...
    'SliderStep',[0.001 0.001],...
    'FontSize',10,...
    'Callback',@xControl);

[hdl.yControlS,hdl.yControlP,hdl.yControlE]=sliderPanel(...
    'Parent',hdl.mainfig,...
    'Title','Vertical Shift',...
    'Position',[0.86 0.1 0.12 0.12],...
    'Min',optargs.ShiftRange(1),...
    'Max',optargs.ShiftRange(2),...
    'Value',mean(optargs.ShiftRange),...
    'SliderStep',[0.001 0.001],...
    'FontSize',10,...
    'Callback',@yControl);


   hdl.buttondone=uicontrol('Parent',hdl.mainfig,...
       'Style','pushbutton',...
       'String','Done',...
       'Units','normalized',...
       'Position',[0.86 0.02 0.04 0.04],...
        'FontSize',10,...
       'Callback',optargs.regEndCallBack);

   setcmap();    
   initializeimages();
%%%%%%%%% All callbacks are written as nested functions %%%%%%

%% Initial computation and output.
function initializeimages()


  [Orient,Aniso]=ComputeFluorAnisotropy(I0,I45reg,I90reg,I135reg,'anisotropy','ItoSMatrix',self.ItoSMatrix);
  Ivec=[I0(:); I45reg(:); I90reg(:); I135reg(:)];  
  Ilim=[min(Ivec) max(Ivec)];
  I45Diff=abs(I0-I45reg); I90Diff=abs(I0-I90reg); I135Diff=abs(I0-I135reg);
  Diffvec=[I45Diff(:); I90Diff(:); I135Diff(:)];
  Difflim=[min(Diffvec) max(Diffvec)];
    
    axes(hdl.a0);
    hdl.I0=imagesc(I0); axis equal;
    set(hdl.a0,'Clim',Ilim);
    title('I0'); colorbar;

    axes(hdl.moving);
    hdl.Imoving=imagesc(I0); axis equal;
    set(hdl.moving,'Clim',Ilim);
    hdl.Tmoving=title(ImageTitleList{1}); colorbar;
    hidecontrols();

    axes(hdl.diff);
    hdl.Idiff=imagesc(abs(I0-I0)); axis equal; 
    % Fix the limits of difference.
    set(hdl.diff,'Clim',Difflim);
    title('Difference'); colorbar;

    axes(hdl.pair);
    hdl.Ipair=imagesc(imfuse(I0,I0)); axis equal; 
    title('Fused image'); 

    axes(hdl.aAniso);
    hdl.IAniso=imagesc(Aniso); axis equal;
    set(hdl.aAniso,'Clim',[0 1]);
    title('Anisotropy'); 

    axes(hdl.aOrient);
    hdl.IOrient=imagesc(Orient,[0 pi]); axis equal;
    title('Orientation'); 

    linkaxes([ hdl.a0 hdl.diff hdl.moving hdl.pair hdl.aAniso hdl.aOrient ]);
end

function updatecontrols()
    set([hdl.xControlS, hdl.yControlS, hdl.rControlS, hdl.sxControlS, hdl.syControlS,...
         hdl.xControlE, hdl.yControlE, hdl.rControlE, hdl.sxControlE, hdl.syControlE,...
         hdl.xControlP, hdl.yControlP, hdl.rControlP, hdl.sxControlP, hdl.syControlP],'Visible','on');        
    % Update controls with current statis settings for registration and
    % make them visible.
    set(hdl.xControlS,'Value',xshift);
    set(hdl.yControlS,'Value',yshift);
    set(hdl.rControlS,'Value',rotation);
    set(hdl.sxControlS,'Value',xscale);
    set(hdl.syControlS,'Value',yscale);


    set(hdl.xControlE,'String',num2str(xshift));
    set(hdl.yControlE,'String',num2str(yshift));
    set(hdl.rControlE,'String',num2str(rotation));
    set(hdl.sxControlE,'String',num2str(xscale));
    set(hdl.syControlE,'String',num2str(yscale));

end

function hidecontrols()
    set([hdl.xControlS, hdl.yControlS, hdl.rControlS, hdl.sxControlS, hdl.syControlS,...
         hdl.xControlE, hdl.yControlE, hdl.rControlE, hdl.sxControlE, hdl.syControlE,...
         hdl.xControlP, hdl.yControlP, hdl.rControlP, hdl.sxControlP, hdl.syControlP],'Visible','off');    
end
%% updateimages displays updated images and also assigns the outputs.
function updateimages() 
    %update images is called by the callbacks for image selector and by
    %the callbacks for registration sliders.
    popImageValue=get(hdl.popImage,'value');
    % Update the registration parameters based on chosen image.
    switch(popImageValue)
        case 1
            % Don't do anything for I0.
        case 2
            self.I45xShift=xshift; 
            self.I45yShift=yshift; 
            self.I45Rotation=rotation*(pi/180); % Angles are displayed in degree, stored in radians.
            self.I45xScale=xscale;
            self.I45yScale=yscale;
            self.tformI45=ShiftScaleRotToaffine(xshift,yshift,xscale,yscale,rotation*(pi/180));
        case 3
            self.I90xShift=xshift; 
            self.I90yShift=yshift; 
            self.I90Rotation=rotation*(pi/180); 
            self.I90xScale=xscale;
            self.I90yScale=yscale;
            self.tformI90=ShiftScaleRotToaffine(xshift,yshift,xscale,yscale,rotation*(pi/180));

        case 4
            self.I135xShift=xshift; 
            self.I135yShift=yshift; 
            self.I135Rotation=rotation*(pi/180); 
            self.I135xScale=xscale;
            self.I135yScale=yscale;
            self.tformI135=ShiftScaleRotToaffine(xshift,yshift,xscale,yscale,rotation*(pi/180));

    end
    
    % calculate the transformed images.

    I45reg=imtransformAffineMat(I45,self.tformI45,'cubic','coordinates','centered');
    I90reg=imtransformAffineMat(I90,self.tformI90,'cubic','coordinates','centered');
    I135reg=imtransformAffineMat(I135,self.tformI135,'cubic','coordinates','centered');

    % Calculate registered images.
  [Orient,Aniso]=ComputeFluorAnisotropy(I0,I45reg,I90reg,I135reg,'anisotropy','ItoSMatrix',self.ItoSMatrix);

  % Assign a moving image for display purpose.
  switch(popImageValue)
      case 1
          MovingImage=I0;
      case 2
          MovingImage=I45reg;
      case 3
          MovingImage=I90reg;
      case 4
          MovingImage=I135reg;
  end



  % I set Cdata instead of redrawing images so that any axes properties
  % set by the user are not reset.
   set(hdl.Idiff,'CData',abs(I0-MovingImage));
   set(hdl.Imoving,'CData',MovingImage);
   set(hdl.Ipair,'CData',imfuse(I0,MovingImage));
   set(hdl.IAniso,'CData',Aniso);
   set(hdl.IOrient,'CData',Orient);
   set(hdl.Tmoving,'String',ImageTitleList{popImageValue}); %Set the title on the moving image.

end


    
%% callbacks for controls.
    function xControl(~,~,~)
        xshift=get(hdl.xControlS,'Value');
        updateimages();
    end

    function yControl(~,~,~)
        yshift=get(hdl.yControlS,'Value');     
        updateimages();
    end

    function rControl(~,~,~)
        rotation=get(hdl.rControlS,'Value');
        updateimages();
    end

    function sxControl(~,~,~)
        xscale=get(hdl.sxControlS,'Value');
        updateimages();
    end

    function syControl(~,~,~)
        yscale=get(hdl.syControlS,'Value');
        updateimages();
    end


    function setcmap(~,~,~) 
        list=get(hdl.popCmap,'String');
        value=get(hdl.popCmap,'value');
         colormap(eval(list{value}));
    end

%% selectimage assigns the values to controls based on the selected image.
    function selectimage(~,~,~)
        % restore the registration parameters based on chosen image and
        % refresh the display.
        popImageValue=get(hdl.popImage,'value');
        switch(popImageValue)
            case 1 % For I0, do nothing and hide the registration controls.
                hidecontrols();
            case 2
                xshift=self.I45xShift; 
                yshift=self.I45yShift; 
                rotation=self.I45Rotation*(180/pi); % Angles are stored in radians inside the object, but displayed in degree in the GUI.
                xscale=self.I45xScale;
                yscale=self.I45yScale;
                updatecontrols();                
            case 3
                xshift=self.I90xShift; 
                yshift=self.I90yShift; 
                rotation=self.I90Rotation*(180/pi); 
                xscale=self.I90xScale;
                yscale=self.I90yScale;
                updatecontrols();   
            case 4
                xshift=self.I135xShift; 
                yshift=self.I135yShift; 
                rotation=self.I135Rotation*(180/pi); 
                xscale=self.I135xScale;
                yscale=self.I135yScale;                
                updatecontrols();   
        end
        
        updateimages();
    end

    % closefunction makes sure that the images are updated when figure is closed.
    function closefunction(~,~,~)
      % Executed only when no parent canvas is specified.  
      % updateimages(); % Update the images.
      % close GUI
        delete(hdl.mainfig); 
      
    end


if optargs.WaitForClose
    waitfor(hdl.mainfig);
end

end
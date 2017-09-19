function getQuickCheckFile(me,varargin)
% Select the file for analysis and compute channels.
   fontSize=12;
   [filename,pathname]=uigetfile({'*.tif','*.tiff'},'Select raw quadrant image to analyze');
    delete(get(me.hQuad.panelImgs,'Children')); 
    delete(get(me.hQuad.HBoxOptions,'Children'));
  % Load contents.
    statusString=uicontrol('Parent',me.hQuad.HBoxOptions,'Style','text',...
                'String','Loading and analyzing the data...' ,...
                'FontWeight','Bold','FontSize',fontSize-2,'BackgroundColor','w');

    drawnow;
            
    if(filename)
        fullpath=[pathname filename];
        set(me.hQuad.nameFile,'String',fullpath);        

  
        checkParams=me.hData.PGParams.GetPropertyValues();
        if(checkParams.colorCeiling>checkParams.anisoCeiling)
            checkParams.colorCeiling=checkParams.anisoCeiling;
            me.hData.PGParams.UpdateFields({'colorCeiling'},{checkParams.anisoCeiling});
        end

            TIFFObj=TIFFStack(fullpath);
            I=TIFFObj(:,:,:);
            [I0,I45,I90,I135,Anisotropy,Orientation,Average]=me.RTFP.quadstoPolStack(I,...
            'anisoQ',checkParams.anisoQ,...
            'anisoCeiling',checkParams.anisoCeiling,...
            'normalizeExcitation',checkParams.normalizeExcitation,...
            'BGiso',checkParams.BGiso,...
            'computeWhat','Channels');  
        
        % Call checkRTFP. Let it know that persistent variables need to be
        % updated. 
        me.checkRTFP('newData',I0,I45,I90,I135,Anisotropy,Orientation,Average);
        
        info=imfinfo([pathname filename]);
        set(me.hQuad.frameNo,'min',0,'max',numel(info),'sliderStep',[1 5]/numel(info),'Value',0);
        set(me.hQuad.frameNoText,'String',int2str(get(me.hQuad.frameNo,'Value')));
        me.setupQuickCheckAnalysis(); % Setup options for analysis.
    end

end
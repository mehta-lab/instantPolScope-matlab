function runBatch(me,varargin)

    batchParams=me.hData.PGParams.GetPropertyValues();
    if(batchParams.colorCeiling>batchParams.anisoCeiling)
        batchParams.colorCeiling=batchParams.anisoCeiling;
        me.hData.PGParams.UpdateFields({'colorCeiling'},{batchParams.anisoCeiling});
    end
    dataFiles=get(me.hData.batchFileList,'String');
    if(isempty(dataFiles))
        set(me.hData.batchStatus,'String','No file in the analysis queue.');
        return;
    elseif(ischar(dataFiles)) 
        dataFiles={dataFiles};
    end
    
    
    for dataIdx=1:length(dataFiles)
        currentfile=dataFiles{dataIdx};
        set(me.hData.batchStatus,'String',['reading #' int2str(dataIdx) ' ' currentfile]);
        drawnow update;
       
        dataTIFF=TIFFStack(currentfile);
  
        switch(batchParams.dataFormat)    
            % First channel is orientation, second is intensity.
            case 'dual-Orientation+Intensity'
                data=dataTIFF(:,:,:);
                dataOrient=data(:,:,1:2:end);  
                dataIntensity=data(:,:,2:2:end);
                clear data;
            % In all other cases.
            case 'single-Orientation' 
                dataOrient=dataTIFF(:,:,:);  
                dataIntensity=NaN;
            case 'single-Intensity'
                dataOrient=NaN;
                dataIntensity=dataTIFF(:,:,:);
        end
        
        set(me.hData.batchStatus,'String',['processing #' int2str(dataIdx) ' ' currentfile]);
        drawnow update; 
        
        if(~isnan(dataOrient))
            % First process and export orientation channel.
            polstack=me.RTFP.quadstoPolStack(dataOrient,...
                'anisoQ',batchParams.anisoQ,...
                'anisoCeiling',batchParams.anisoCeiling,...
                'normalizeExcitation',batchParams.normalizeExcitation,...
                'BGiso',batchParams.BGiso);
        

            if(batchParams.exportPolStack)
                set(me.hData.batchStatus,'String',['exporting #' int2str(dataIdx) ' ' currentfile]);
                drawnow update;
                writePolStack(polstack,currentfile,'PolStack','anisoCeiling',batchParams.anisoCeiling,...
                    'order','XYZTC','bitDepth','uint16'); % The channels are represented as slices so that ImageJ applies the same look up table when browsing the stack.
            end

            if(batchParams.exportColorMap)
                writePolStack(polstack,currentfile,'OrientationMap','colorCeiling',batchParams.colorCeiling,'avgCeiling',batchParams.avgCeiling,...
                    'legend',batchParams.colorLegend,'colorMap',batchParams.colorMap);
            end
        end
        % Export average intensity of 2nd channel if present.
        
         if(~isnan(dataIntensity))
             dataI=me.RTFP.quadstoPolStack(dataIntensity,'computeWhat','Average');
             [pathstr, name, ext]=fileparts(currentfile);
             name(name == ' ')='_';
             stacknameI=[pathstr '/' name   'Intensity'  ext];
         %    dimensions=size(dataI);
         % dataI=typecast(dataI(:),class(dataIntensity));
         %  dataI=reshape(dataI,dimensions);
             dataI=reshape(single(dataI),size(dataI,1),size(dataI,2),1,1,size(dataI,3)); % Reformat according to XYCZT order required by exportHyperSTack.
             exportHyperStack(dataI,stacknameI);
         end
         
    end

    set(me.hData.batchStatus,'String',['Analyzed ' int2str(dataIdx) ' files.']);

end
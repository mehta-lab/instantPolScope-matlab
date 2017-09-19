function normRTFP(me,varargin)
        filepath=get(me.hNorm.nameFile,'String');
        normParams=me.hNorm.PGParams.GetPropertyValues();

        if(strcmpi(normParams.normMethod,'reset'))
           me.RTFP.calibNorm([],'normalizeExcitation',normParams.normalizeExcitation); 
           delete(get(me.hNorm.panelImgs,'Children'));
           me.updateNormPG(); 
        else        
        Inorm=imread(filepath); 
        me.RTFP.calibNorm(Inorm,...
            'normMethod',normParams.normMethod,...% 'reset' will  reset the registration.
            'normROI',normParams.normROI,...
            'normalizeExcitation',normParams.normalizeExcitation,...
            'diagnosis',true,...
            'Parent',me.hNorm.panelImgs,...
            'normEndCallBack',@me.updateNormPG);            
        end

end
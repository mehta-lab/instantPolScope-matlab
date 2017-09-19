function regRTFP(me,varargin)
    filepath=get(me.hReg.nameFile,'String');
    regParams=me.hReg.PGParams.GetPropertyValues();
    
    if(isempty(filepath))
            Ireg=NaN;
    else
            Ireg=imread(filepath); 
    end
    
    me.RTFP.calibReg(Ireg,...
        'regMethod',regParams.regMethod,...% 'reset' will  reset the registration.
        'preProcReg',regParams.preProcReg,...
        'diagnosis',true,...
        'Parent',me.hReg.panelImgs,...
        'regEndCallBack',@me.updateRegPG);
         
end
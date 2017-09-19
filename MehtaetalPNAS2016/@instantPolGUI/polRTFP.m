function polRTFP(me,varargin)

        polParams=me.hPol.PGParams.GetPropertyValues();
        if(strcmp(polParams.polType,'reset'))
            [~,me.RTFP.ItoSMatrix]=calibPolUsingPolarizer([]);
            delete(get(me.hPol.panelImgs,'Children'));
        else
            
        filepath=get(me.hPol.nameFile,'String');
        TIFFObj=TIFFStack(filepath);
        Ipol=TIFFObj(:,:,:);

            %calibPolUsingPolarizer takes polstack as an input. If
            %separate registration is needed, it needs to be handled
            %before computation of the polstack. This part is modeled
            %after quadsToPolStack.m
            if(polParams.NeedsSeparateReg)
                [tanPolCalibFile, tanPolPath]=uigetfile({'*.mat'},'Select MAT file with registration information about the polarizer.');
                load([tanPolPath tanPolCalibFile],'RTFPCalib');

                % Get crop and registration information from custom
                % registration.
               [I0, I45, I90, I135]=RTFluorPol.cropNormalizeQuads(Ipol,...
                RTFPCalib.BoundingBox,[1 me.RTFP.NormI45 me.RTFP.NormI90 me.RTFP.NormI135],...
                me.RTFP.BlackLevel);
                I45reg=imtransformAffineMat(I45,RTFPCalib.tformI45,'cubic','coordinates',RTFPCalib.coordinates);
                I90reg=imtransformAffineMat(I90,RTFPCalib.tformI90,'cubic','coordinates',RTFPCalib.coordinates);
                I135reg=imtransformAffineMat(I135,RTFPCalib.tformI135,'cubic','coordinates',RTFPCalib.coordinates);
                    [azim, mag, avg]=ComputeFluorAnisotropy(I0,I45reg,I90reg,I135reg,'anisotropy','ItoSMatrix',me.RTFP.ItoSMatrix);

                mag(mag>1)=1;
                polstack(:,:,1)=mag;
                polstack(:,:,2)=azim;
                polstack(:,:,3)=avg;
                polstack(:,:,4)=I0;
                polstack(:,:,5)=I135reg;
                polstack(:,:,6)=I90reg;
                polstack(:,:,7)=I45reg;

            else
             polstack=me.RTFP.quadstoPolStack(Ipol);

            end

        [~,me.RTFP.ItoSMatrix]=calibPolUsingPolarizer(polstack,...
            'polType',polParams.polType,...
            'center',polParams.center,...
            'maxRadius',polParams.maxRadius,...
            'linpolOrient',polParams.linpolOrient,...
            'Parent',me.hPol.panelImgs);
        end
        
        me.hPG.UpdateFieldsFromBoundItem({'ItoSMatrix'});

end

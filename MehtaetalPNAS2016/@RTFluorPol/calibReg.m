function  calibReg(self,Ireg,varargin)
% calibReg(RTFluorPolObject,Ireg,'Property','value')
% Property      Possible values (Default in bracket)
% 'regMethod'   ('manual'),'matlab','phasecor','reset'
% 'preProcReg'  ('none'),'lowpass','edge'
% 'diagnosis'   (true), false.
% 'regType'     'translation',('rigid'),'similarity' (valid only for
% automated regMethods)



%% Process optional parameters.
params.regMethod='auto';
params.preProcReg='none';
params.diagnosis=true;
params.regType='similarity';
params.Parent=NaN; % Parent canvas on which to draw the images. Useful when calibReg is used as a callback within GUI.
params.regEndCallBack=NaN; % Function to execute after the registration 'ends'. This is used for updating the calling GUI.
params=parsepropval(params,varargin{:});


%% See if the registration should be reset.
if(isempty(Ireg) || any(isnan(Ireg(:)))) % Reset registration.
  self.tformI45=eye(3);
  self.tformI90=eye(3);
  self.tformI135=eye(3);
  
  %return;
end

%% Crop and normalize. 

  switch(params.regMethod)
      case {'AUTO','auto','reset'}
          % Starting with current registration typically leads to better
          % registration when performing auto-reg.
          [I0, I45, I90, I135]=self.quadstoPolStack(Ireg,'computeWhat','Channels');
      case 'manual'
          % Manual registration function always uses un-registered images
          % as reference. It does use current registration stored in the
          % class.
          [I0, I45, I90, I135]=self.quadstoPolStack(Ireg,'computeWhat','Channels','register',false);
  end

  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
    switch(params.preProcReg)
        case 'none' % No filtering is good for punctate images like beads.
            I0BeforeReg=I0;
            I45BeforeReg=I45;
            I90BeforeReg=I90;
            I135BeforeReg=I135;
            
        case 'lowpass' % Lowpass is good for noisy images.
            
         freqcut=self.ObjectiveNA/(self.Wavelength);
         I0BeforeReg=opticalLowpassInterpolation(I0,self.PixSize,freqcut,1);
         I45BeforeReg=opticalLowpassInterpolation(I45,self.PixSize,freqcut,1);
         I90BeforeReg=opticalLowpassInterpolation(I90,self.PixSize,freqcut,1);
         I135BeforeReg=opticalLowpassInterpolation(I135,self.PixSize,freqcut,1);
         
        case 'edge' % Edge is good for transmission image and 
        % Compute gradients of registration data to enhance sensitivity to
        % registration mismatch.
       % sigma=(0.5*self.Wavelength/self.objectiveNA)/self.PixSize;
       % At this sigma, anisotropic intensity distribution at the
       % sub-resolution scale is smoothed out, leaving only the
       % above-resolution mismatches in location.

        sigma=(0.2*self.Wavelength/self.ObjectiveNA)/self.PixSize;
        % Use this sigma for isotropic specimens to improve the registration.
        I0BeforeReg=gradcalc(I0,sigma);
        I45BeforeReg=gradcalc(I45,sigma);
        I90BeforeReg=gradcalc(I90,sigma);
        I135BeforeReg=gradcalc(I135,sigma);
        otherwise
            error('filterReg parameter should be :''none'', ''lowpass'', or ''edge''');
    end

%% Calculate registration. 
    switch(params.regMethod)
        case {'AUTO','auto'}
            
%             self.coordinates='centered';
%             x=self.xaxis/self.PixSize; y=1:self.quadHeight;
%             [I90RegToI0, tformI90toI0,I90x,I90y,I90cor]=imregphasecor(I0BeforeReg,I90BeforeReg,...
%                 x,y,'rigid','pos','pixel',min(I90BeforeReg(:))); %#ok<ASGLU,NASGU>
%             [I135RegToI45, tformI135toI45,I135x,I135y,I135cor]=imregphasecor(I45BeforeReg,I135BeforeReg,...
%                 x,y,'rigid','pos','pixel',min(I90BeforeReg(:))); %#ok<ASGLU,NASGU>
%             S2=I45BeforeReg-I135RegToI45;
%             S1=I0BeforeReg-I90RegToI0;
%             [S2RegToS1, tformS2toS1,S2x,S2y,S2cor]=imregphasecor(S1,S2,...
%                 x,y,'rigid','pos','pixel',min(I135BeforeReg(:))); %#ok<ASGLU,NASGU>
% 

        if verLessThan('images','9.0')
            error('Optimization-based registration is available only for Image Processing Toolbox ver 9.0 (release 2014a) or later.');
        end
      
        % I90 and I0 share the splitter, so do I135 and I45.
          xLims=0.5*[-size(I0BeforeReg,2) size(I0BeforeReg,2)];
          yLims=0.5*[-size(I0BeforeReg,1) size(I0BeforeReg,1)];
          R=imref2d(size(I0BeforeReg),xLims,yLims);
        [optimizer, metric] = imregconfig('monomodal');
        optimizer.MaximumStepLength=0.05;
        optimizer.MinimumStepLength=1E-6;
        optimizer.MaximumIterations = 500;
         
        [tformI90,I90RegToI0] = regQuads(I90BeforeReg,I0BeforeReg,R,optimizer,metric);
        [tformI45,I45RegToI0] = regQuads(I45BeforeReg,I0BeforeReg,R,optimizer,metric);
        [tformI135,I135RegToI0] = regQuads(I135BeforeReg,I0BeforeReg,R,optimizer,metric);
        
%         S2=I45BeforeReg-I135RegToI45;
%         S1=I0BeforeReg-I90RegToI0;
%         
%         [tformS2toS1,S2RegToS1]=regQuads(S2,S1,R,optimizer,metric);
% 
%         self.tformI45=tformS2toS1;
%         self.tformI90=tformI90toI0;
%         self.tformI135=tformS2toS1*tformI135toI45;
        
        self.tformI90=tformI90.T*self.tformI90;
        self.tformI45=tformI45.T*self.tformI45;
        self.tformI135=tformI135.T*self.tformI135;

                 % Important to sync the shifts with transform matrix.     
        [self.I45xShift, self.I45yShift,self.I45xScale, self.I45yScale,  self.I45Rotation ]=affineToShiftScaleRot(self.tformI45); 
        [self.I90xShift, self.I90yShift, self.I90xScale, self.I90yScale,  self.I90Rotation]=affineToShiftScaleRot(self.tformI90); 
        [self.I135xShift, self.I135yShift, self.I135xScale, self.I135yScale, self.I135Rotation]=affineToShiftScaleRot(self.tformI135); 

        
%         case {'MATLAB','matlab'} 
%             %Note: MATLAB computes registration in non-centered frame,
%             %whereas we assume centered frame for manual registration and
%             %phase-corraltion based registration.
% 
%             if verLessThan('images','9.0')
%                 error('Optimization-based registration is available only for Image Processing Toolbox ver 9.0 (release 2014a) or later.');
%             end
%             self.coordinates='matlab';
%             [optimizer,metric]=imregconfig('monomodal');
%             optimizer.MaximumIterations = 500;
%             optimizer.MinimumStepLength = 5e-6;
%              tform=imregtform(I90BeforeReg,I0BeforeReg,params.regType,optimizer,metric);
%              tformI90toI0=tform.tdata.T;
%              I90RegToI0=imtransformAffineMat(I90BeforeReg, tformI90toI0, 'linear');
% 
%              tform=imregtform(I135BeforeReg,I45BeforeReg,params.regType,optimizer,metric);
%              tformI135toI45=tform.tdata.T;
%              I135RegToI45=imtransformAffineMat(I135BeforeReg, tformI135toI45, 'linear');
% 
%              S2=abs(I45BeforeReg- I135RegToI45);
%              S1=abs(I0BeforeReg-I90RegToI0);
%              tform=imregtform(S2,S1,params.regType,optimizer,metric);
%              tformS2toS1=tform.tdata.T;
%             % S2RegToS1=imtransformAffineMat(S2, tformS2toS1, 'linear');
% 
%             self.tformI45=tformS2toS1;
%             self.tformI90=tformI90toI0;
%             self.tformI135=tformS2toS1*tformI135toI45;

        case 'manual'
            self.regQuadsManual(...
                        I0BeforeReg,I45BeforeReg,I90BeforeReg,I135BeforeReg,...
                        'Parent',params.Parent,'regEndCallBack',params.regEndCallBack);
        case 'reset'
              self.tformI45=eye(3);
              self.tformI90=eye(3);
              self.tformI135=eye(3);   
         % Important to sync the shifts with transform matrix.     
        [self.I45xShift, self.I45yShift,self.I45xScale, self.I45yScale,  self.I45Rotation ]=affineToShiftScaleRot(self.tformI45); 
        [self.I90xShift, self.I90yShift, self.I90xScale, self.I90yScale,  self.I90Rotation]=affineToShiftScaleRot(self.tformI90); 
        [self.I135xShift, self.I135yShift, self.I135xScale, self.I135yScale, self.I135Rotation]=affineToShiftScaleRot(self.tformI135);               
        otherwise 
            error(['Registration function ' params.regMethod ' not implemented.']);
    end
    
    % Registration complete. Run the end callback.
  if(isa(params.regEndCallBack,'function_handle'))  
        params.regEndCallBack();  
  end

%% Generate a diagnostic plot if user asked for it. No need to generate diagnostic plots for manual registration.
    if(params.diagnosis && ~strcmpi(params.regMethod,'manual'))
        % Obtain the images after registration.
        [I0AfterReg, I45AfterReg, I90AfterReg, I135AfterReg]=self.quadstoPolStack(Ireg,'computeWhat','Channels');
     
    switch(params.preProcReg)
        case 'none' % No filtering is good for punctate images like beads.
            
        case 'lowpass' % Lowpass is good for noisy images.
            
         freqcut=self.ObjectiveNA/(self.Wavelength);
         I0AfterReg=opticalLowpassInterpolation(I0AfterReg,self.PixSize,freqcut,1);
         I45AfterReg=opticalLowpassInterpolation(I45AfterReg,self.PixSize,freqcut,1);
         I90AfterReg=opticalLowpassInterpolation(I90AfterReg,self.PixSize,freqcut,1);
         I135AfterReg=opticalLowpassInterpolation(I135AfterReg,self.PixSize,freqcut,1);
         
        case 'edge' % Edge is good for transmission image and 
            % Compute gradients of registration data to enhance sensitivity to
            % registration mismatch.
           % sigma=(0.5*self.Wavelength/self.objectiveNA)/self.PixSize;
           % At this sigma, anisotropic intensity distribution at the
           % sub-resolution scale is smoothed out, leaving only the
           % above-resolution mismatches in location.

            sigma=(0.2*self.Wavelength/self.ObjectiveNA)/self.PixSize;
            % Use this sigma for isotropic specimens to improve the registration.
            I0AfterReg=gradcalc(I0AfterReg,sigma);
            I45AfterReg=gradcalc(I45AfterReg,sigma);
            I90AfterReg=gradcalc(I90AfterReg,sigma);
            I135AfterReg=gradcalc(I135AfterReg,sigma);
        otherwise
            error('filterReg parameter should be :''none'', ''lowpass'', or ''edge''');
    end
   

        % Orientation and anisotropy before and after registration.
        [OrientationBefore,AnisotropyBefore]=ComputeFluorAnisotropy...
            (I0BeforeReg,I45BeforeReg,I90BeforeReg,I135BeforeReg,'anisotropy');
        [OrientationAfter,AnisotropyAfter]=ComputeFluorAnisotropy...
            (I0AfterReg,I45AfterReg,I90AfterReg,I135AfterReg,'anisotropy');
        
        % If no parent canvas has been provided.
        if(~ishandle(params.Parent))
            hfigreg=togglefig('Before and after registration',1); 
            set(hfigreg,'Units','Normalized','Position',[0.05 0.05 0.9 0.9],...
                'defaultaxesfontsize',15,'Color','white');
            colormap gray; 
        else
            hfigreg=params.Parent;
            delete(get(hfigreg,'Children'));
        end



        hReg=imagecat(self.xaxis,self.yaxis,...
            I0BeforeReg,I45AfterReg,I90AfterReg,I135AfterReg,...
            OrientationBefore,OrientationAfter,AnisotropyBefore,AnisotropyAfter,...
            'equal','link','colorbar',hfigreg);
        Ivec=[I0BeforeReg(:);I45BeforeReg(:);I90BeforeReg(:);I135BeforeReg(:)];
        set(hReg(1:4),'clim',[min(Ivec) max(Ivec)]);
        set(hReg(5:6),'clim',[min(OrientationBefore(:)) max(OrientationBefore(:))]);

        minAnisotropy=min(AnisotropyBefore(:));
        if(minAnisotropy<0) 
            minAnisotropy =0; 
        end;
        maxAnisotropy=max(AnisotropyBefore(:));
        if(maxAnisotropy>1) 
            maxAnisotropy=1; 
        end;
        set(hReg(7:8),'clim',[minAnisotropy maxAnisotropy]);

    end
            
end

function [tform,movingreg]=regQuads(moving,fixed,R,optimizer,metric)

  % imregcorr cannot detect scaling less than 1/4 or larger than 4.
        % Our images have very small scaling.
% tformEstimate=imregcorr(moving,fixed,'translation');
% movingApproxReg=imwarp(moving,tformEstimate,'OutputView',R);

% Small changes in magnification can be accounted for by similarity
% transformation.

tform=imregtform(moving,R,fixed,R, 'affine', optimizer, metric);%,'InitialTransformation',tformEstimate);
movingreg=imtransformAffineMat(moving,tform.T,'cubic','coordinates','centered');
end






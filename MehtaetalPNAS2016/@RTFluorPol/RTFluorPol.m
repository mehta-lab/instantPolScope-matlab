classdef RTFluorPol < handle
% RTFluorPol class provides methods for calibrating the real-time
% fluorescence polarization microscope and for processing the images
% acquired with it.
%
% The object does not store any pixel data, but stores all the information
% required to reproduce the computed results from the raw images. In other
% words all metadata is stored in the object, but no pixel data.
%



properties 

   % Size of the pixel at the specimen plane in um.
   PixSize=0.0709;
   % NA of the objective.
   ObjectiveNA=1.49;
   % Emission wavelength in um.
   Wavelength=0.525;
   % Intensity recorded by camera when the light source is turned off.
   BlackLevel=uint16(0);
   % Transmission axis of the top-left quadrant.
   quadTopLeft='I0';
   quadTopRight='I45';
   quadBottomLeft='I135';
   quadBottomRight='I90';
   quadWidth=256;
   quadHeight=256;
   cornerTopLeft=[1 1];
   cornerTopRight=[257 1];
   cornerBottomLeft=[1 257];
   cornerBottomRight=[257 257];

   I45xShift=0;
   I45yShift=0;
   I45Rotation=0;
   I45xScale=1;
   I45yScale=1;
   
   I90xShift=0;
   I90yShift=0;
   I90Rotation=0;
   I90xScale=1;
   I90yScale=1;
   
   I135xShift=0;
   I135yShift=0;
   I135Rotation=0;
   I135xScale=1;
   I135yScale=1;

   
   % Detector throughput parameters.
   NormI45=1;
   NormI90=1;
   NormI135=1;
    
   % Illumination imbalance parameters.
   NormI45ex=1;
   NormI90ex=1;
   NormI135ex=1;
   
   ItoSMatrix=[0.5 0.5 0.5 0.5; 1 0 -1 0; 0 1 0 -1]; % Matrix that converts intensities into Stokes parameters.
      
   BoundingBox;
   tformI45=eye(3);
   tformI90=eye(3);
   tformI135=eye(3);
   PSF=zeros(7);
end

properties(Dependent)
   xaxis
   yaxis
end


methods
    %%%%%%%% Constructor.
    function self=RTFluorPol(varargin)
    % Constructor of RTFluorPol class. Initializes the class with minimal
    % required parameters and optionally brings up GUI that allows
    % calibration and processing.
    %
    % Author and Copyright: Shalin Mehta, HFSP Postdoctoral Fellow
    %                           Marine Biological Laboratory, Woods Hole, MA
    %                           http://www.mshalin.com
    % 
    % License: Restricted academic use. 
    % This software is free to use, but only with explicit permission by the
    % author and only for academic purpose. This software constitutes a part of
    % unpublished method for measuring orientation of single and ensemble of
    % fluorophores.

    parsepropval(self,varargin{:}); % Since self is passed by reference, there is no need to assign the output of parsepropval.
    
    
    end


    %%%%%%%%%% get methods for dependent properties.
%     function tformI45=get.tformI45(self)
%         %Whenever tformI45 is required, it is computed from the parameters
%         %stored in the object.
%         tformI45=...
%             ShiftScaleRotToaffine(self.I45xShift,self.I45yShift,self.I45xScale,self.I45yScale,self.I45Rotation);
%         % This function and its dual affineToShiftScaleRot are always used
%         % in registration routines to ensure consistency of convention.
%     end
%     
%     function set.tformI45(self,tform)
%         Whenever tformI45 is assigned, the parameters stored in the object
%         are updated.
%        [self.I45xShift,self.I45yShift,self.I45xScale,self.I45yScale,self.I45Rotation]=...
%         affineToShiftScaleRot(tform);
%     end
%     
%     function tformI90=get.tformI90(self)
%         tformI90=...
%             ShiftScaleRotToaffine(self.I90xShift,self.I90yShift,self.I90xScale,self.I90yScale,self.I90Rotation);
%     end
%     
%     function set.tformI90(self,tform)
%        [self.I90xShift,self.I90yShift,self.I90xScale,self.I90yScale,self.I90Rotation]=...
%         affineToShiftScaleRot(tform);
%     end
%     
%     function tformI135=get.tformI135(self)
%         tformI135=...
%             ShiftScaleRotToaffine(self.I135xShift,self.I135yShift,self.I135xScale,self.I135yScale,self.I135Rotation);
%     end
%     
%     function set.tformI135(self,tform)
%        [self.I135xShift,self.I135yShift,self.I135xScale,self.I135yScale,self.I135Rotation]=...
%         affineToShiftScaleRot(tform);
%     end
    
    function BoundingBox=get.BoundingBox(self)
        % Ensure that two quadratns are not assigned the same identity.
        if(any(strcmp(self.quadTopLeft,{self.quadTopRight,self.quadBottomLeft,self.quadBottomRight})) ||...
            any(strcmp(self.quadTopRight,{self.quadBottomLeft,self.quadBottomRight})) ||...
            strcmp(self.quadBottomLeft,self.quadBottomRight))
        errordlg('Two quadrants assigned the same identity. Please correct. ');
        
        else
        
        BoundingBox.(self.quadTopLeft)= ...
            [self.cornerTopLeft self.quadWidth self.quadHeight];
        BoundingBox.(self.quadTopRight)= ...
            [self.cornerTopRight self.quadWidth self.quadHeight];
        BoundingBox.(self.quadBottomLeft)= ...
            [self.cornerBottomLeft self.quadWidth self.quadHeight];
        BoundingBox.(self.quadBottomRight)= ...
            [self.cornerBottomRight self.quadWidth self.quadHeight];
        end
    end
    
    function xaxis=get.xaxis(self)
        xaxis=self.PixSize*...
            linspace(-0.5*self.quadWidth,0.5*self.quadWidth,self.quadWidth);
    end
    
    function yaxis=get.yaxis(self)
        yaxis=self.PixSize*...
            linspace(-0.5*self.quadHeight,0.5*self.quadHeight,self.quadHeight);
    end
    

    %%%%%%%%%%%%%% Processing functions.
    varargout=calibNorm(self, varargin)
    varargout=calibReg (self, varargin)
    varargout=regQuadsManual(self, varargin)
    varargout=normQuadsManual(self, varargin)
    varargout=quadstoPolStack(self,varargin) 
    varargout=analyzeParticles(self,varargin)
    varargout=estimatePSF(self,varargin)
end

methods (Static) %Static methods that can be used without creating an object.
    % Class defnitions are written to match anything while methods evolve.
    % Use the final definitions when the class stabilizes.
    %
    varargout=identifyQuads( varargin )
    varargout=cropQuads(varargin)
  %  varargout=readRTFPdata(varargin)

end


end
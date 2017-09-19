function   writePolStack(polstack,datafile,what,varargin)
% This function writes-out the polstack in uint16 format.
% The order of dimensions is assumed to be XYCT.


% Format of FluorPol stack expected by Rudolf's plugins:
% - Ratio/Anisotropy (scaled to be 12-bits).
% - Orientation (angle in degrees*10)
% - I0
% - I135
% - I90
% - I45
% - I0 (optional)
% - Total image

% Author and Copyright: Shalin Mehta, HFSP Postdoctoral Fellow
%                           Marine Biological Laboratory, Woods Hole, MA
%                           http://www.mshalin.com
% 
% License: Restricted academic use. 
% This software is free to use, but only with explicit permission by the
% author and only for academic purpose. This software constitutes a part of
% unpublished method for measuring orientation of single and ensemble of
% fluorophores.

% Ceiling is mapped to the highest value in dynamic range only during
% export.
arg.anisoCeiling=NaN;
arg.colorCeiling=1;
arg.suffix=what;
arg.bitDepth=16;
arg.invertIntensity=false; % Used only for colormaps.
arg.legend=false;
arg.order='XYZTC';
arg.colorMap='hsv';
arg.avgCeiling=NaN;
arg=parsepropval(arg,varargin{:});

if(size(polstack,3)~=7 && size(polstack,3)~=8 )
    error('3rd dimension of Polstack must equal 7 or 8.');
end
X=size(polstack,2);
Y=size(polstack,1);
C=size(polstack,3);
Z=size(polstack,4);
T=size(polstack,5);

[pathstr, name, ext]=fileparts(datafile);
name(name == ' ')='_';
polStackName=[pathstr filesep name   arg.suffix  ext];
orientfileName=[pathstr filesep name  arg.suffix ext];
XYprojName=[pathstr filesep name '_XY' arg.suffix ext];
YZprojName=[pathstr filesep name '_YZ' arg.suffix ext];
XZprojName=[pathstr filesep name '_XZ' arg.suffix ext];
XvecName=[pathstr filesep name '_X' arg.suffix ext];
YVecName=[pathstr filesep name '_Y' arg.suffix ext];
IVecName=[pathstr filesep name '_intensity' ext];
AVecName=[pathstr filesep name '_aniso' ext];

    
switch(what)
%     case ('OME-TIFF')
%         % OME-TIFF is much (>10x) slower than the saveastiff call below.
%         
%         polstack(:,:,1,:)=((2^16-1)/arg.anisoCeiling)*polstack(:,:,1,:);
%         polstack(:,:,2,:)=100*(180/pi)*polstack(:,:,2,:);
%         bfsave(uint16(polstack),polStackName,arg.order);
    case('PolStack')
        % In PolStack, anisoCeiling is interpreted quantitatively and histogram
        % can be adjusted during view. When exporting color or vectors, it
        % is has more visual purpose and therefore should be comptued from
        % the data to provide clear contrast.
        
        if isnan(arg.anisoCeiling)
            anisoCeiling=1;
        else
            anisoCeiling=arg.anisoCeiling;
        end
        
        switch(arg.bitDepth)
            case {8,'uint8'}
                polstack(:,:,1,:)=((2^8-1)/anisoCeiling)*polstack(:,:,1,:);
                polstack(:,:,2,:)=(180/pi)*polstack(:,:,2,:);
                exportFormat='uint8';
                
            case {10,12,14,16,'uint16'}
                polstack(:,:,1,:)=((2^16-1)/anisoCeiling)*polstack(:,:,1,:);
                polstack(:,:,2,:)=100*(180/pi)*polstack(:,:,2,:);
                exportFormat='uint16';
               
            case {'single','double'}
                    exportFormat='single'; % Don't need double-precision for our measurements. 
                    % saveastiff can write single stacks.
                     % Data can stay in floating point.
                polstack(:,:,2,:)=(180/pi)*polstack(:,:,2,:);
            otherwise
                error('Bit-depth can be 8,10,12,14, 16, uint8, uint16, single or double.');
        end
            polstack=cast(polstack,exportFormat);
            
            % Export data as ImageJ hyperstack.
            
           %Write correct metadata tag.
           switch(arg.order)
                case 'XYCTZ' % Use for Instantaneous PolScope: channels have different histogram in ImageJ.
                   xN=size(polstack,2); yN=size(polstack,1); channelsN=size(polstack,3); framesN=size(polstack,4); slicesN=1;
               case 'XYZTC' % Use for Instantaneous PolScope: channels mapped to slices to use the same histogram.
                   xN=size(polstack,2); yN=size(polstack,1); slicesN=size(polstack,3); framesN=size(polstack,4); channelsN=1;
                case 'XYCZT' % Use for Confocal PolScope.
                   xN=size(polstack,2); yN=size(polstack,1);  channelsN=size(polstack,3); slicesN=size(polstack,4); framesN=1;
               
           end

           exportHyperStack(reshape(polstack,[yN xN channelsN slicesN framesN]),polStackName);
           
        case('OrientationMap')

            aniso=squeeze(polstack(:,:,1,:));
            azim=squeeze(polstack(:,:,2,:));
            avg=squeeze(polstack(:,:,3,:));
           
            OrientationMap=pol2color(aniso,azim,avg,arg.colorMap,'legend',arg.legend,'anisoCeiling',arg.anisoCeiling,'avgCeiling',arg.avgCeiling);
            options.color=true;
            saveastiff(uint8(255*OrientationMap),orientfileName,options);
            
    case 'Projections'
            aniso=squeeze(polstack(:,:,1,:));
            % Clip the anisotropy to colorCeiling.
            aniso(aniso>arg.colorCeiling)=arg.colorCeiling;
            azim=squeeze(polstack(:,:,2,:));
            avg=squeeze(polstack(:,:,3,:));
            if(isnan(arg.avgCeiling))
                avgCeiling=max(avg(:)); %2^arg.bitDepth-1;
            else
                avgCeiling=arg.avgCeiling;
            end
            
            avg(avg>avgCeiling)=avgCeiling;
            avg=avg/avgCeiling; % Normalize the intensity to 1.            
            
            options.color=true;
            
            [XYavg,Zidx]=max(avg,[],3); % Obtain the XY projection of avg and indices along Z.
            [Xidx,Yidx]=meshgrid(1:size(avg,2),1:size(avg,1));
            XYidx=sub2ind(size(avg),Yidx,Xidx,Zidx); % Obtain matrix of linear indices. Notice that Yidx is the first index.
            XYaniso=aniso(XYidx); % Extract anisotropy and azimuth at correct pixels.
            XYazim=azim(XYidx);
            XYOrient=pol2color(XYaniso,XYazim,XYavg,arg.colorMap,'legend',true);
            saveastiff(uint8(255*XYOrient),XYprojName,options);


            [XZavg,Yidx]=max(avg,[],1); % Obtain the XY projection of avg and indices along Z.
            [Zidx,Xidx]=meshgrid(1:size(avg,3),1:size(avg,2));
            XZidx=sub2ind(size(avg),squeeze(Yidx),Xidx,Zidx); % Obtain matrix of linear indices. Notice that Yidx is the first index.
            XZaniso=aniso(XZidx); % Extract anisotropy and azimuth at correct pixels.
            XZazim=azim(XZidx);
            XZOrient=pol2color(XZaniso,XZazim,squeeze(XZavg),arg.colorMap,'legend',false);
            saveastiff(uint8(255*XZOrient),XZprojName,options);
            
            [YZavg,Xidx]=max(avg,[],2); % Obtain the XY projection of avg and indices along Z.
            [Zidx,Yidx]=meshgrid(1:size(avg,3),1:size(avg,1));
            YZidx=sub2ind(size(avg),Yidx,squeeze(Xidx),Zidx); % Obtain matrix of linear indices. Notice that Yidx is the first index.
            YZaniso=aniso(YZidx); % Extract anisotropy and azimuth at correct pixels.
            YZazim=azim(YZidx);
            YZOrient=pol2color(YZaniso,YZazim,squeeze(YZavg),arg.colorMap,'legend',false);
            saveastiff(uint8(255*YZOrient),YZprojName,options);
            
    case 'Vector'
        
            aniso=squeeze(polstack(:,:,1,:));
            % Clip the anisotropy to colorCeiling.
            
            azim=squeeze(polstack(:,:,2,:));
            avg=squeeze(polstack(:,:,3,:));
           
            [Xvector,Yvector,anisoVector,avgVector]=pol2vectors(aniso,azim,avg,'avgCeilig',arg.avgCeiling,'anisoCeiling',arg.anisoCeiling);
            saveastiff(single(Xvector),XvecName);
            saveastiff(single(Yvector),YVecName);
            saveastiff(single(avgVector),IVecName);
            saveastiff(single(anisoVector),AVecName);
    otherwise 
        error(['Export format:' what ' not recognized.']); 
end


end


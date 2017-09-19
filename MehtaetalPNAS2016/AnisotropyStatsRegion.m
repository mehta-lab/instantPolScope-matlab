function [ anisoMean,orientMean, fluorMean, registeredFluor ] = ...
    AnisotropyStatsRegion( PolStack, regionMask, quantity,registerAcrossTime)
%[ anisoMean,orientMean, fluorMean, registeredAnisoStack ] =
% AnisotropyStatsRegion (PolStack, regions) returns statistics for PolStack
% computed from regions specified by regions (which can be BW image, label
% matrix, or connected components). The stage drift in PolStack is
% registered based on the anisotropy image.



T=size(PolStack,4);
x=1:size(PolStack,2);
y=1:size(PolStack,1);
nRegions=regionprops(regionMask); 
nR=length(nRegions);

anisoMean=zeros(nR,T);
orientMean=zeros(nR,T);
fluorMean=zeros(nR,T);
 % Arrange the regions along the column, i.e., Y direction; and time along
 % the row, i.e., X direction.
 
% A stack of registered anisotropy images for diagnosis.
registeredFluor=zeros(size(PolStack,1),size(PolStack,2),size(PolStack,4));
tformPresent=[1 0 0;0 1 0; 0 0 1];
for t=1:T
    if(registerAcrossTime && t>1) 
        [~,tform]=imregphasecor(PolStack(:,:,1,t-1),PolStack(:,:,1,t),x,y,'translation');
        tformPresent=tformPresent*tform;
        % Register the anisotropy channel of current time-point to the
        % anisotropy channel of the previous time-point. Apply the same
        % registration to all raw images.
        I0=imtransformAffineMat(PolStack(:,:,4,t),tformPresent,'cubic','coordinates','centered');
        I135=imtransformAffineMat(PolStack(:,:,5,t),tformPresent,'cubic','coordinates','centered');
        I90=imtransformAffineMat(PolStack(:,:,6,t),tformPresent,'cubic','coordinates','centered');
        I45=imtransformAffineMat(PolStack(:,:,7,t),tformPresent,'cubic','coordinates','centered');
        registeredFluor(:,:,t)=imtransformAffineMat(PolStack(:,:,1,t),tformPresent,'cubic','coordinates','centered');
    else
        registeredFluor(:,:,t)=PolStack(:,:,1,t);
        I0=PolStack(:,:,4,t);
        I135=PolStack(:,:,5,t);
        I90=PolStack(:,:,6,t);
        I45=PolStack(:,:,7,t);
    end
    
        I0mean=regionprops(regionMask,I0,'MeanIntensity');
        I0mean=struct2array(I0mean)'; 
        
        I45mean=regionprops(regionMask,I45,'MeanIntensity');
        I45mean=struct2array(I45mean)';        
        
        I90mean=regionprops(regionMask,I90,'MeanIntensity');
        I90mean=struct2array(I90mean)';
        
        I135mean=regionprops(regionMask,I135,'MeanIntensity');
        I135mean=struct2array(I135mean)';
    
        [orientMean(:,t),anisoMean(:,t), fluorMean(:,t)]=...
            ComputeFluorAnisotropy(I0mean,I45mean,I90mean,I135mean,quantity);

end
end


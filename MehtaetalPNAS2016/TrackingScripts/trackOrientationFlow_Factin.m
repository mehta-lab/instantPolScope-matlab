%% Track F-actin retrograde flow.
% Imaging properties: 
% EM gain: 1000
% Preamp: 5x, readout: 3MHz
% Offset: 98
% DN per electron (gain from photon transfer): 104
% Readnoise in N: 22
% Readnoise in e: 0.21
% Shot noise limited range: 25 to 10000
% Exposure: 100ms, 10s interval.


%% 1. Setup analysis parameters and filename.

 clear all; 


satIntensity=10000; % Saturation intensity.
cameragain=104;

psfSigma=1.5;

% List data
topdir='/Users/shalin.mehta/Documents/images/MehtaetalPNAS2016FactinRetrograde/';
outputdir=[topdir 'analysis/'];
mkdir(outputdir);

datafiles={...
   [topdir '140213 100x15x15 HaCat 250nM beads lad Alexa488 phal 2% ND 10s int 200ms exp 02_MMStack.ome.tif'],... 
   % Add more lines like above  for batch analysis of data taken with same calibration.
   };

particleFiles=[]; avgFiles=[]; roiFile=[];
for dataIndex=1:numel(datafiles)
    if(exist(datafiles{dataIndex},'file'))
       calibfiles{dataIndex}=[topdir '140213cal_SM20150127.RTFP.mat']; 
        [pathstr,filename]=fileparts(datafiles{dataIndex});
        datanames{dataIndex}=filename(1:strfind(filename,'_MMStack')-1);
        particleFiles{dataIndex}=[outputdir filename '_particles.mat'];
        avgFiles{dataIndex}=[outputdir filename '_avg.tif'];
        roiFile{dataIndex}=[outputdir filename '_roi.mat'];
        trackfiles{dataIndex}=[outputdir filesep datanames{dataIndex} '_track.mat'];    
        overlaymovie{dataIndex}=[outputdir filesep datanames{dataIndex} '_overlay.tif'];    
    end
end

exportsuffix='HaCat140213';
tInterval=10;
%% 2. Detect and track particles.

for dataIndex=1:numel(datafiles)
    
disp(datanames{dataIndex});

% Read the raw quadrant data.
    dataTIFF=TIFFStack(datafiles{dataIndex});
    data=dataTIFF(:,:,:);    
    data=data(:,:,2:end); % Ignore the first frame that may be transmission.
    
    % Load corresponding calibration.
    load(calibfiles{dataIndex});

    % Convert quadrants into individual registered/normalized/pol-corrected
    % channels.
    [I0,I45,I90,I135,~,~,iAvg]=RTFPCalib.quadstoPolStack(data,'computeWhat','Channels','BGiso',0);
     saveastiff(uint16(iAvg),avgFiles{dataIndex});


% Detect particles.
[xPart,yPart,ampFit,BGampFit,nPart,movieInfo,FGmask]=detectParticles(iAvg,psfSigma,'singleMolecule',true,'alphaLocalMaxima',0.05,'RedundancyRadius',3);
save( particleFiles{dataIndex},'xPart','yPart','ampFit','BGampFit','nPart','movieInfo','FGmask','psfSigma');

% Track particles and visualize the tracks over intensity image.
load( particleFiles{dataIndex},'xPart','yPart','ampFit','BGampFit','nPart','movieInfo','FGmask','psfSigma');
[  ~,trackFP,trackStartIndx,numSegments,trackedFeatureIndx] = trackerFluorPolV2( particleFiles{dataIndex},'dataType','actin');
%togglefig('track summary'); imagecat(trackFP.X,trackFP.Y,trackFP.Amp,trackFP.BGAmp,trackFP.Particles==0,trackFP.Particles-trackedFeatureIndx,'link','colorbar',gcf);
save(trackfiles{dataIndex},'trackFP','trackStartIndx','numSegments');

% Anisotropy calculation based on final tracks.
load(trackfiles{dataIndex},'trackFP','trackStartIndx','numSegments');
 FGmask2=imdilate(FGmask,strel('disk',2));
[trackFP.orientPart,trackFP.anisoPart,trackFP.intPart, trackFP.I0Part, trackFP.I45Part, trackFP.I90Part, trackFP.I135Part, ~,~, ~,...
    trackFP.I0BG,trackFP.I45BG,trackFP.I90BG,trackFP.I135BG,trackFP.BGPart,trackFP.NPixBG,trackFP.NPixPart]=...
 computeParticleAnisotropy(I0,I45,I90,I135,trackFP.X,trackFP.Y,NaN,psfSigma,...
 'BGiso',trackFP.BGAmp,'BGPartFactor',1,'BGaround',true,'foregroundMask',FGmask2,'anisoBGFactor',1);
save(trackfiles{dataIndex},'trackFP','trackStartIndx','numSegments');

% 
hfig=togglefig('overlay',1); colormap gray;
set(hfig,'color','w','position',[50 50 1024 512]);
ha=tight_subplot(1,2,[],[],[],hfig);
hAxisIntensity=ha(1); hAxisOverlay=ha(2);
% Display results and export.
movOrient=overlayPositionOrientationV2(trackFP.X,trackFP.Y,...
    trackFP.anisoPart,trackFP.orientPart,trackFP.intPart,iAvg,'delay',0,'lineLength',25,'glyphColor',[1 0.5 1],'trackLength',100,'trackColor','g','Parent',hAxisOverlay,'hAxisIntensity',hAxisIntensity);
    options.color=true;
    saveastiff(movOrient,overlaymovie{dataIndex},options);
end
disp('---- done ----');


function [anisoBin,anisoCount,orientBin,orientCount,intBin,intCount]=particleHistograms(anisoPart,orientPart,intPart,varargin)
% Function that displays histograms of anisotropy, orientation, and
% intensity.

params.Parent=NaN; 
params.intensityRange=[0 0];
params.anisotropyRange=[0 1];
params.orientationRange=[0 180];
params.excludeAboveOrientation=false;
params.referenceOrientation=0;
params.nBins=180/5;
params.orientBins=180/5;
params.histogramType='individual';
params.orientationHistogramType='xy';
params.radialRange=NaN; %If not NaN, the radial range is fixed to this value.
params=parsepropval(params,varargin{:});

% Identify parent panel.
if(isnan(params.Parent))
   hfig=togglefig('Particle histograms.'); 

else
   hfig=params.Parent;
end

% Setup three axes on the parent. 
delete(get(hfig,'Children'));


% Select particles based on intensity.

if any((params.intensityRange)>0) %If any of the two values in the range are above zero.
    intensityMask=intPart>params.intensityRange(1) & intPart<params.intensityRange(2);
else
    intensityMask=~isnan(intPart); %NaNs in intPart matrix are excluded.
end

% Select based on anisotropy.
anisotropyMask=(anisoPart > params.anisotropyRange(1) ) & ...
    (anisoPart < params.anisotropyRange(2) );

if(strcmpi(params.orientationHistogramType,'polar') && any(params.orientationRange<0))
    errordlg('For polar histograms, there is no need to use angular range of [-90 90]','Check settings','modal');
    return;
end


% Convert to radians.
params.orientationRange=params.orientationRange*(pi/180); 

if(any(params.orientationRange<0)) % If user requests orientation going negative, assume the display range of -90 to 90.
orientPart=orientPart-params.referenceOrientation;
orientPart=atan(sin(orientPart)./cos(orientPart));
else
orientPart=mod(orientPart-params.referenceOrientation,pi); % Mod pi is needed. Particles out of [0 180] range are filtered.    
end

    
orientationMask= (orientPart > params.orientationRange(1)) & ...
                 (orientPart < params.orientationRange(2));   
             
if(params.excludeAboveOrientation)
    orientationMask=~orientationMask;
end

useParticles=intensityMask & anisotropyMask & orientationMask;


anisoBin=linspace(0,1,params.nBins);
if(any(params.orientationRange<0)) 
    orientBin=linspace(-90,90,params.orientBins);
else
    orientBin=linspace(0,180,params.orientBins);
end

Imax=max(intPart(useParticles));
Imin=min(intPart(useParticles));
intBin=linspace(Imin,Imax,params.nBins);


anisoCount=hist(anisoPart(useParticles),anisoBin);
orientCount=hist((180/pi)*orientPart(useParticles),orientBin);
intCount=hist(intPart(useParticles),intBin);
[~, ~, ~, circStd]= anisoStats(anisoPart(useParticles),orientPart(useParticles),intPart(useParticles));
N=numel(anisoPart(useParticles));
if(strcmpi(params.histogramType,'individual'))
    subplot(1,3,1,'Parent',hfig);

    bar(anisoBin,anisoCount,0.8,'k','edgecolor','w'); 
    title('Histogram of anisotropy of particles');
    xlabel('anisotropy'); ylabel('count');
    xlim([-inf 1]);
    
    subplot(1,3,2,'Parent',hfig);
    
    switch(params.orientationHistogramType)
        case 'xy'
            bar(orientBin,orientCount,1,'k','edgecolor','w');
            xlabel('orientation'); ylabel('count'); 
            xlim([min(orientBin) max(orientBin)]);
        case 'polar'

            polarPlotAnisoStat(anisoPart(useParticles),orientPart(useParticles),intPart(useParticles),...
                'ReferenceOrient',NaN,'showMeanOrient',false,...
                'Statistic','ParticleAnisotropy','Nbins',params.orientBins,'anisoCeiling',max(params.anisotropyRange));
            
    end

    title(['Orientation histogram: \sigma_c=' num2str(circStd,4) ',N=' int2str(N)] );

    subplot(1,3,3,'Parent',hfig);
    bar(intBin,intCount,0.8,'k','edgecolor','w');
    title('Histogram of intensity of particles');
    xlabel('intensity'); ylabel('count');
    xlim([-Inf Inf]);
    
elseif(strcmpi(params.histogramType,'joint'))
 

    subplot(1,2,1,'Parent',hfig);
    NIntOrient=hist3([ intPart(useParticles) (180/pi)*orientPart(useParticles)],{intBin,orientBin});
    imagesc(orientBin,intBin,NIntOrient); xlabel('Orientation (Degree)'); ylabel('Intensity (AU)');
    axis xy; 
    
    subplot(1,2,2,'Parent',hfig);
    NIntAniso=hist3([intPart(useParticles) anisoPart(useParticles) ],{intBin,anisoBin});
    imagesc(anisoBin,intBin,NIntAniso); xlabel('Anisotropy'); ylabel('Intensity (AU)');
    axis xy;

else
    error('Histogram type should either be individual or joint.');
end


end

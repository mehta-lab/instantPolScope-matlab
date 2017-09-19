function [ histEdges,histHeight, meanAniso, meanOrient] = polarPlotAnisoStat(aniso,orient,avg,varargin)

args.Parent=gca;
args.Nbins=18; %  Number of bins.
args.PlotType='Polar';
args.ReferenceOrient=0; %Reference theta and anisotropy. Set NaN to assume 0 reference and not draw the line. Set 'mean' to subtract mean orientation.
args.orientationRelativeToROI=false;
args.Statistic='PixelAnisotropy';
args.showMeanOrient=true;
args.anisoCeiling=NaN; % The radial range is constrained to either anisoCeiling or avgCeiling depending on the type of histogram.
args.LineWidth=2;
args=parsepropval(args,varargin{:});

if(any(size(aniso)~= size(orient)) || any(size(avg)~=size(orient) ))
    error('Anisotropy, Orientation, and Average variables must be the same size.');
end

% Bin edges and center.
histEdges=(pi/180)*linspace(0,180,args.Nbins+1); % The last count by histc is the number of values that are exactly 180 degree.

[meanAniso, meanOrient]=anisoStats(aniso,orient,avg);

if(strcmpi(args.ReferenceOrient,'mean'))
    args.ReferenceOrient=meanOrient;
end

if(args.orientationRelativeToROI)
    orient=mod(orient-args.ReferenceOrient,pi);
    meanOrient=mod(meanOrient-args.ReferenceOrient,pi);
    refOrient=0;
else
    refOrient=args.ReferenceOrient;
end

% Obtain bin heights.
switch(args.Statistic)
    case {'PixelOrientation','ParticleOrientation'} % Plain histogram of orientation. Does not account for intensity or anisotropy.
         histHeight=histc(orient,histEdges);
         radialRange=NaN;
    case {'Pixel','Particles'} % Sum the intensities of pixels that have specific orientation. Equivalent to joint histogram of intensity and orientation.
        % Counts
        [~,indices]=histc(orient,histEdges);

        % Calculate bin-height by combining counts and weights.
        histHeight=zeros(size(histEdges));

        for idBin=1:numel(histEdges)
           % histHeight(idBin)=counts(idBin)*mean(weights(indices == idBin));
           histHeight(idBin)=sum(avg(indices == idBin)); % counts are accounted for by the sum of intensities.
        end
        radialRange=NaN;
    case {'PixelAnisotropy','ParticleAnisotropy'} % Dominant anisotropy in each bin. Equivalent to joint histogram of anisotropy and orientation.
         % Counts
        [~,indices]=histc(orient,histEdges);
        
        % Calculate bin-height by combining counts and weights.
        histHeight=zeros(size(histEdges));
        for idBin=1:numel(histEdges)
            % Perform vector averaging in each bin.
            meanAniso=anisoStats(aniso(indices == idBin),orient(indices == idBin),avg(indices == idBin));
            histHeight(idBin)=meanAniso; % counts are accounted for by the sum of intensities.
        end
        radialRange=args.anisoCeiling;
    case 'MedianAnisotropy'
        [~,indices]=histc(orient,histEdges);
        histHeight=zeros(size(histEdges));
        for idBin=1:numel(histEdges)
            % Perform vector averaging in each bin.
            histHeight(idBin)=median(aniso(indices == idBin)); % counts are accounted for by the sum of intensities.
        end
        radialRange=args.anisoCeiling;        
    case 'Molecule'
        % Compute intensity distribution as a function of angle in three
        % steps for all pixels. 
        % The equation for each pixel is:
        % avg*(1+aniso*cos(2*theta-orient)).
        Iorient= @(histEdges,orient) cos(2*(histEdges-orient));
        Ianiso= @(Iorient,aniso) 1+(aniso.*Iorient);
        
        OrientDistrib = bsxfun(Iorient,histEdges,orient(:));
        AnisoDistrib= bsxfun(Ianiso,aniso(:),OrientDistrib);
        IDistrib= bsxfun(@times,AnisoDistrib,avg(:));
        
        % Sum intensities to get a histogram.
        histHeight=sum(IDistrib,1);
        radialRange=NaN;
end

   
% theta and r are variables used for plotting. 
theta=zeros(1,3*length(histEdges));
r=zeros(1,3*length(histEdges));

theta(1:3:end)=histEdges; % Make sure that first bin of histogram is displayed around 0.
theta(2:3:end)=theta(1:3:end);
theta(3:3:end)=theta(1:3:end);
r(3:3:end)=histHeight;
r(4:3:end)=histHeight(1:end-1);

% Pad theta and r so that full circle is drawn.

switch(args.PlotType)
    case 'XY'
        plot(theta,r);
    case 'Polar'

        % Plot a fake polar plot to fix the radial range and then hide
        % the plot.
        if(~isnan(radialRange))
            theta_fake  = linspace(0,2*pi,100);
            r_max  = max(radialRange);
            h_fake = polar(theta_fake,r_max*ones(size(theta_fake)));
            set(h_fake, 'Visible', 'Off','LineWidth',args.LineWidth);
            hold on;
        end
        
        hHistReal=polar(theta,r,'k');
        set(hHistReal,'LineWidth',args.LineWidth);
        hold on;
        
        hHistReflected=polar(theta+pi,r);
        set(hHistReflected,'LineWidth',args.LineWidth,'Color',[0.5 0.5 0.5]);

        XRange=get(gca,'XLim');
        XMax=XRange(2);
        if(args.showMeanOrient)
           hMean(1)=polar([meanOrient meanOrient],[0 XMax],'b--');
           hMean(2)=polar([meanOrient+pi meanOrient+pi],[0 XMax],'b--');
           set(hMean,'LineWidth',args.LineWidth);
        end
        
        if(~isnan(args.ReferenceOrient))
            hRef(1)=polar([refOrient refOrient],[0 XMax],'k--');
            hRef(2)=polar([refOrient+pi refOrient+pi],[0 XMax],'k--');
            set(hRef,'LineWidth',args.LineWidth);
        end
        hold off;
        
        % correct the orientation markers.
        for orientationMarker=185:5:360 % The angles can be safely assumed to be marked every 5 degrees at the most.
            changeThisText=int2str(orientationMarker);
            changeTo=int2str(orientationMarker-180);
            set(findall(gcf,'String', changeThisText),'String',changeTo); 
        end
       % polarticks(18,[p hMean hRef]);
       

end

if(strcmp(args.Statistic,'Molecule'))
    title(['Dipole density distribution' '(\theta_{net}:' num2str(meanOrient*180/pi,4) ')']);
elseif(strfind(args.Statistic,'Anisotropy'))
    title(['Anisotropy vs. Orientation' '(\theta_{net}:' num2str(meanOrient*180/pi,4) ')']);
else
    title(['Intensity vs. Orientation' '(\theta_{net}:' num2str(meanOrient*180/pi,4) ')'] ); 
end  
% 
% t=(pi/180)*(0:0.1*optargs.Interval:180)'; % t variable for polar plot. 
% r=zeros(size(t));
% 
% rho=zeros(size(histEdges));
% for idt=1:numel(histEdges)
%     rho(idt)=counts(idt)*mean(weights(indices==idt));
% end
% polar(optargs.Parent,histEdges,rho,'k-');
% 


end


function [ tracksFinal,trackFP,trackStartIndx,numSegments,trackedFeatureIndx] =...
    trackerFluorPolV2( particleFile,varargin)
% This function tracks particles right after detection. It converts
% tracking results into a matrix format. It optionally fills the gaps in
% tracks and extends them by chosen # of frames.

opt.dataType='bleaching'; %'actin', %'septin', %'PH-GFP'.
opt.loadTracksFrom='';
opt.fillGaps=true; % Intensity and background are set equal to average of gap edges. 
opt.psfSigma=1.5;
opt=parsepropval(opt,varargin{:});

% load detection info.
load(particleFile,'xPart','yPart','ampFit','BGampFit','nPart','movieInfo','FGmask','psfSigma');

if(ischar(opt.loadTracksFrom) && exist(opt.loadTracksFrom,'file'))
    % Load tracks, skip analysis
    load(opt.loadTracksFrom,'tracksFinal');
elseif(isstruct(opt.loadTracksFrom))
    tracksFinal=opt.loadTracksFrom;
else
    
    switch(opt.dataType)
        
        case {'InvitroFilament'}
                        %% general gap closing parameters
            
            gapCloseParam.timeWindow = 15; %maximum allowed time gap (in frames) between a track segment end and a track segment start that allows linking them.
            gapCloseParam.mergeSplit = 3; %1 if merging and splitting are to be considered, 2 if only merging is to be considered, 3 if only splitting is to be considered, 0 if no merging or splitting are to be considered.
            gapCloseParam.minTrackLen = 5; %minimum length of track segments from linking to be used in gap closing.
            
            %optional input:
            gapCloseParam.diagnostics = 0; %1 to plot a histogram of gap lengths in the end; 0 or empty otherwise.
            
            %%% cost matrix for frame-to-frame linking
            
            %function name
            costMatrices(1).funcName = 'costMatRandomDirectedSwitchingMotionLink';
            
            %parameters
            
            parameters.linearMotion = 0; %use linear motion Kalman filter.
            parameters.minSearchRadius = 0; %minimum allowed search radius. The search radius is calculated on the spot in the code given a feature's motion parameters. If it happens to be smaller than this minimum, it will be increased to the minimum.
            parameters.maxSearchRadius = 3; %maximum allowed search radius. Again, if a feature's calculated search radius is larger than this maximum, it will be reduced to this maximum.
            parameters.brownStdMult = 3; %multiplication factor to calculate search radius from standard deviation.
            
            parameters.useLocalDensity = 0; %1 if you want to expand the search radius of isolated features in the linking (initial tracking) step.
            parameters.nnWindow = gapCloseParam.timeWindow; %number of frames before the current one where you want to look to see a feature's nearest neighbor in order to decide how isolated it is (in the initial linking step).
            
            parameters.kalmanInitParam = []; %Kalman filter initialization parameters.
            % parameters.kalmanInitParam.searchRadiusFirstIteration = 10; %Kalman filter initialization parameters.
            
            %optional input
            parameters.diagnostics = []; %if you want to plot the histogram of linking distances up to certain frames, indicate their numbers; 0 or empty otherwise. Does not work for the first or last frame of a movie.
            
            costMatrices(1).parameters = parameters;
            clear parameters
            
            %%% cost matrix for gap closing
            
            %function name
            costMatrices(2).funcName = 'costMatRandomDirectedSwitchingMotionCloseGaps';
            
            %parameters
            
            %needed all the time
            parameters.linearMotion = 0; %use linear motion Kalman filter.
            
            parameters.minSearchRadius = 0; %minimum allowed search radius.
            parameters.maxSearchRadius = 3; %maximum allowed search radius.
            parameters.brownStdMult = 3; %multiplication factor to calculate Brownian search radius from standard deviation.
            
            parameters.brownScaling = [0 0.01]; %power for scaling the Brownian search radius with time, before and after timeReachConfB (next parameter).
            % parameters.timeReachConfB = 3; %before timeReachConfB, the search radius grows with time with the power in brownScaling(1); after timeReachConfB it grows with the power in brownScaling(2).
            parameters.timeReachConfB = gapCloseParam.timeWindow; %before timeReachConfB, the search radius grows with time with the power in brownScaling(1); after timeReachConfB it grows with the power in brownScaling(2).
            
            parameters.ampRatioLimit = [0.2 5]; %for merging and splitting. Minimum and maximum ratios between the intensity of a feature after merging/before splitting and the sum of the intensities of the 2 features that merge/split.
            
            parameters.lenForClassify = 5; %minimum track segment length to classify it as linear or random.
            
            parameters.useLocalDensity = 1; %1 if you want to expand the search radius of isolated features in the gap closing and merging/splitting step.
            parameters.nnWindow = gapCloseParam.timeWindow; %number of frames before/after the current one where you want to look for a track's nearest neighbor at its end/start (in the gap closing step).
            
            parameters.linStdMult = 1*ones(gapCloseParam.timeWindow,1); %multiplication factor to calculate linear search radius from standard deviation.
            
            parameters.linScaling = [0.25 0.01]; %power for scaling the linear search radius with time (similar to brownScaling).
            % parameters.timeReachConfL = 4; %similar to timeReachConfB, but for the linear part of the motion.
            parameters.timeReachConfL = gapCloseParam.timeWindow; %similar to timeReachConfB, but for the linear part of the motion.
            
            parameters.maxAngleVV = 90; %maximum angle between the directions of motion of two tracks that allows linking them (and thus closing a gap). Think of it as the equivalent of a searchRadius but for angles.
            
            %optional; if not input, 1 will be used (i.e. no penalty)
            parameters.gapPenalty =1; %penalty for increasing temporary disappearance time (disappearing for n frames gets a penalty of gapPenalty^n).
            
            %optional; to calculate MS search radius
            %if not input, MS search radius will be the same as gap closing search radius
           % parameters.resLimit =3*psfSigma; %resolution limit, which is generally equal to 3 * point spread function sigma.
            
            costMatrices(2).parameters = parameters;
            clear parameters
            
        case {'bleaching','GFP'}
            %% general gap closing parameters
            
            gapCloseParam.timeWindow = 2; %maximum allowed time gap (in frames) between a track segment end and a track segment start that allows linking them.
            gapCloseParam.mergeSplit = 0; %1 if merging and splitting are to be considered, 2 if only merging is to be considered, 3 if only splitting is to be considered, 0 if no merging or splitting are to be considered.
            gapCloseParam.minTrackLen = 3; %minimum length of track segments from linking to be used in gap closing.
            
            %optional input:
            gapCloseParam.diagnostics = 1; %1 to plot a histogram of gap lengths in the end; 0 or empty otherwise.
            
            %%% cost matrix for frame-to-frame linking
            
            %function name
            costMatrices(1).funcName = 'costMatRandomDirectedSwitchingMotionLink';
            
            %parameters
            
            parameters.linearMotion = 0; %use linear motion Kalman filter.
            parameters.minSearchRadius = 0; %minimum allowed search radius. The search radius is calculated on the spot in the code given a feature's motion parameters. If it happens to be smaller than this minimum, it will be increased to the minimum.
            parameters.maxSearchRadius = 3; %maximum allowed search radius. Again, if a feature's calculated search radius is larger than this maximum, it will be reduced to this maximum.
            parameters.brownStdMult = 3; %multiplication factor to calculate search radius from standard deviation.
            
            parameters.useLocalDensity = 0; %1 if you want to expand the search radius of isolated features in the linking (initial tracking) step.
            parameters.nnWindow = gapCloseParam.timeWindow; %number of frames before the current one where you want to look to see a feature's nearest neighbor in order to decide how isolated it is (in the initial linking step).
            
            parameters.kalmanInitParam = []; %Kalman filter initialization parameters.
            % parameters.kalmanInitParam.searchRadiusFirstIteration = 10; %Kalman filter initialization parameters.
            
            %optional input
            parameters.diagnostics = []; %if you want to plot the histogram of linking distances up to certain frames, indicate their numbers; 0 or empty otherwise. Does not work for the first or last frame of a movie.
            
            costMatrices(1).parameters = parameters;
            clear parameters
            
            %%% cost matrix for gap closing
            
            %function name
            costMatrices(2).funcName = 'costMatRandomDirectedSwitchingMotionCloseGaps';
            
            %parameters
            
            %needed all the time
            parameters.linearMotion = 0; %use linear motion Kalman filter.
            
            parameters.minSearchRadius = 0; %minimum allowed search radius.
            parameters.maxSearchRadius = 3; %maximum allowed search radius.
            parameters.brownStdMult = 3; %multiplication factor to calculate Brownian search radius from standard deviation.
            
            parameters.brownScaling = [0 0.01]; %power for scaling the Brownian search radius with time, before and after timeReachConfB (next parameter).
            % parameters.timeReachConfB = 3; %before timeReachConfB, the search radius grows with time with the power in brownScaling(1); after timeReachConfB it grows with the power in brownScaling(2).
            parameters.timeReachConfB = gapCloseParam.timeWindow; %before timeReachConfB, the search radius grows with time with the power in brownScaling(1); after timeReachConfB it grows with the power in brownScaling(2).
            
            parameters.ampRatioLimit = [0.2 5]; %for merging and splitting. Minimum and maximum ratios between the intensity of a feature after merging/before splitting and the sum of the intensities of the 2 features that merge/split.
            
            parameters.lenForClassify = 5; %minimum track segment length to classify it as linear or random.
            
            parameters.useLocalDensity = 0; %1 if you want to expand the search radius of isolated features in the gap closing and merging/splitting step.
            parameters.nnWindow = gapCloseParam.timeWindow; %number of frames before/after the current one where you want to look for a track's nearest neighbor at its end/start (in the gap closing step).
            
            parameters.linStdMult = 1*ones(gapCloseParam.timeWindow,1); %multiplication factor to calculate linear search radius from standard deviation.
            
            parameters.linScaling = [0.25 0.01]; %power for scaling the linear search radius with time (similar to brownScaling).
            % parameters.timeReachConfL = 4; %similar to timeReachConfB, but for the linear part of the motion.
            parameters.timeReachConfL = gapCloseParam.timeWindow; %similar to timeReachConfB, but for the linear part of the motion.
            
            parameters.maxAngleVV = 90; %maximum angle between the directions of motion of two tracks that allows linking them (and thus closing a gap). Think of it as the equivalent of a searchRadius but for angles.
            
            %optional; if not input, 1 will be used (i.e. no penalty)
            parameters.gapPenalty = 1.5; %penalty for increasing temporary disappearance time (disappearing for n frames gets a penalty of gapPenalty^n).
            
            %optional; to calculate MS search radius
            %if not input, MS search radius will be the same as gap closing search radius
            parameters.resLimit =3*1.33; %resolution limit, which is generally equal to 3 * point spread function sigma.
            
            costMatrices(2).parameters = parameters;
            clear parameters
        case {'PHGFP','septin'}
             
            %%% gap closing parameters: These parameters deciaff
            
            gapCloseParam.timeWindow = 5; %maximum allowed time gap (in frames) between a track segment end and a track segment start that allows linking them.
            gapCloseParam.mergeSplit = 3; %1 if merging and splitting are to be considered, 2 if only merging is to be considered, 3 if only splitting is to be considered, 0 if no merging or splitting are to be considered.
            gapCloseParam.minTrackLen = 5; %minimum length of track segments from linking to be used in gap closing.
            
            %optional input:
            gapCloseParam.diagnostics = 0; %1 to plot a histogram of gap lengths in the end; 0 or empty otherwise.
            
            %%% cost matrix for frame-to-frame linking
            
            %function name
            costMatrices(1).funcName = 'costMatRandomDirectedSwitchingMotionLink';
            
            %parameters
            
            parameters.linearMotion = 0; %use linear motion Kalman filter.
            parameters.minSearchRadius = 0; %minimum allowed search radius. The search radius is calculated on the spot in the code given a feature's motion parameters. If it happens to be smaller than this minimum, it will be increased to the minimum.
            parameters.maxSearchRadius = 3; %maximum allowed search radius. Again, if a feature's calculated search radius is larger than this maximum, it will be reduced to this maximum.
            parameters.brownStdMult = 3; %multiplication factor to calculate search radius from standard deviation.
            
            parameters.useLocalDensity = 1; %1 if you want to expand the search radius of isolated features in the linking (initial tracking) step.
            parameters.nnWindow = gapCloseParam.timeWindow; %number of frames before the current one where you want to look to see a feature's nearest neighbor in order to decide how isolated it is (in the initial linking step).
            
            parameters.kalmanInitParam = []; %Kalman filter initialization parameters.
            % parameters.kalmanInitParam.searchRadiusFirstIteration = 10; %Kalman filter initialization parameters.
            
            %optional input
            parameters.diagnostics = []; %if you want to plot the histogram of linking distances up to certain frames, indicate their numbers; 0 or empty otherwise. Does not work for the first or last frame of a movie.
            
            costMatrices(1).parameters = parameters;
            clear parameters
            
            %%% cost matrix for gap closing
            
            %function name
            costMatrices(2).funcName = 'costMatRandomDirectedSwitchingMotionCloseGaps';
            
            %parameters
            
            %needed all the time
            parameters.linearMotion = 0; %use linear motion Kalman filter.
            
            parameters.minSearchRadius = 0; %minimum allowed search radius.
            parameters.maxSearchRadius = 3; %maximum allowed search radius.
            parameters.brownStdMult = 3; %multiplication factor to calculate Brownian search radius from standard deviation.
            
            parameters.brownScaling = [0 0.01]; %power for scaling the Brownian search radius with time, before and after timeReachConfB (next parameter).
            % parameters.timeReachConfB = 3; %before timeReachConfB, the search radius grows with time with the power in brownScaling(1); after timeReachConfB it grows with the power in brownScaling(2).
            parameters.timeReachConfB = gapCloseParam.timeWindow; %before timeReachConfB, the search radius grows with time with the power in brownScaling(1); after timeReachConfB it grows with the power in brownScaling(2).
            
            parameters.ampRatioLimit = [0.2 5]; %for merging and splitting. Minimum and maximum ratios between the intensity of a feature after merging/before splitting and the sum of the intensities of the 2 features that merge/split.
            
            parameters.lenForClassify = 3; %minimum track segment length to classify it as linear or random.
            
            parameters.useLocalDensity = 0; %1 if you want to expand the search radius of isolated features in the gap closing and merging/splitting step.
            parameters.nnWindow = gapCloseParam.timeWindow; %number of frames before/after the current one where you want to look for a track's nearest neighbor at its end/start (in the gap closing step).
            
            parameters.linStdMult = 1*ones(gapCloseParam.timeWindow,1); %multiplication factor to calculate linear search radius from standard deviation.
            
            parameters.linScaling = [0.25 0.01]; %power for scaling the linear search radius with time (similar to brownScaling).
            % parameters.timeReachConfL = 4; %similar to timeReachConfB, but for the linear part of the motion.
            parameters.timeReachConfL = gapCloseParam.timeWindow; %similar to timeReachConfB, but for the linear part of the motion.
            
            parameters.maxAngleVV = 90; %maximum angle between the directions of motion of two tracks that allows linking them (and thus closing a gap). Think of it as the equivalent of a searchRadius but for angles.
            
            %optional; if not input, 1 will be used (i.e. no penalty)
            parameters.gapPenalty = 1; %penalty for increasing temporary disappearance time (disappearing for n frames gets a penalty of gapPenalty^n).
            
            %optional; to calculate MS search radius
            %if not input, MS search radius will be the same as gap closing search radius
            parameters.resLimit =3*1.5; %resolution limit, which is generally equal to 3 * point spread function sigma.
            
            costMatrices(2).parameters = parameters;
            clear parameters
            
           case 'actin'
             
           %%% gap closing parameters: These parameters deciaff
            
            gapCloseParam.timeWindow = 5; %maximum allowed time gap (in frames) between a track segment end and a track segment start that allows linking them.
            gapCloseParam.mergeSplit = 0; %1 if merging and splitting are to be considered, 2 if only merging is to be considered, 3 if only splitting is to be considered, 0 if no merging or splitting are to be considered.
            gapCloseParam.minTrackLen = 5; %minimum length of track segments from linking to be used in gap closing.
            
            %optional input:
            gapCloseParam.diagnostics = 0; %1 to plot a histogram of gap lengths in the end; 0 or empty otherwise.
            
            %%% cost matrix for frame-to-frame linking
            
            %function name
            costMatrices(1).funcName = 'costMatRandomDirectedSwitchingMotionLink';
            
            %parameters
            
            parameters.linearMotion = 0; %use linear motion Kalman filter.
            parameters.minSearchRadius = 0; %minimum allowed search radius. The search radius is calculated on the spot in the code given a feature's motion parameters. If it happens to be smaller than this minimum, it will be increased to the minimum.
            parameters.maxSearchRadius = 3; %maximum allowed search radius. Again, if a feature's calculated search radius is larger than this maximum, it will be reduced to this maximum.
            parameters.brownStdMult = 3; %multiplication factor to calculate search radius from standard deviation.
            
            parameters.useLocalDensity = 1; %1 if you want to expand the search radius of isolated features in the linking (initial tracking) step.
            parameters.nnWindow = gapCloseParam.timeWindow; %number of frames before the current one where you want to look to see a feature's nearest neighbor in order to decide how isolated it is (in the initial linking step).
            
            parameters.kalmanInitParam = []; %Kalman filter initialization parameters.
            % parameters.kalmanInitParam.searchRadiusFirstIteration = 10; %Kalman filter initialization parameters.
            
            %optional input
            parameters.diagnostics = []; %if you want to plot the histogram of linking distances up to certain frames, indicate their numbers; 0 or empty otherwise. Does not work for the first or last frame of a movie.
            
            costMatrices(1).parameters = parameters;
            clear parameters
            
            %%% cost matrix for gap closing
            
            %function name
            costMatrices(2).funcName = 'costMatRandomDirectedSwitchingMotionCloseGaps';
            
            %parameters
            
            %needed all the time
            parameters.linearMotion = 0; %use linear motion Kalman filter.
            
            parameters.minSearchRadius = 0; %minimum allowed search radius.
            parameters.maxSearchRadius = 3; %maximum allowed search radius.
            parameters.brownStdMult = 3; %multiplication factor to calculate Brownian search radius from standard deviation.
            
            parameters.brownScaling = [0 0.01]; %power for scaling the Brownian search radius with time, before and after timeReachConfB (next parameter).
            % parameters.timeReachConfB = 3; %before timeReachConfB, the search radius grows with time with the power in brownScaling(1); after timeReachConfB it grows with the power in brownScaling(2).
            parameters.timeReachConfB = gapCloseParam.timeWindow; %before timeReachConfB, the search radius grows with time with the power in brownScaling(1); after timeReachConfB it grows with the power in brownScaling(2).
            
            parameters.ampRatioLimit = [0.2 5]; %for merging and splitting. Minimum and maximum ratios between the intensity of a feature after merging/before splitting and the sum of the intensities of the 2 features that merge/split.
            
            parameters.lenForClassify = 3; %minimum track segment length to classify it as linear or random.
            
            parameters.useLocalDensity = 0; %1 if you want to expand the search radius of isolated features in the gap closing and merging/splitting step.
            parameters.nnWindow = gapCloseParam.timeWindow; %number of frames before/after the current one where you want to look for a track's nearest neighbor at its end/start (in the gap closing step).
            
            parameters.linStdMult = 1*ones(gapCloseParam.timeWindow,1); %multiplication factor to calculate linear search radius from standard deviation.
            
            parameters.linScaling = [0.25 0.01]; %power for scaling the linear search radius with time (similar to brownScaling).
            % parameters.timeReachConfL = 4; %similar to timeReachConfB, but for the linear part of the motion.
            parameters.timeReachConfL = gapCloseParam.timeWindow; %similar to timeReachConfB, but for the linear part of the motion.
            
            parameters.maxAngleVV = 90; %maximum angle between the directions of motion of two tracks that allows linking them (and thus closing a gap). Think of it as the equivalent of a searchRadius but for angles.
            
            %optional; if not input, 1 will be used (i.e. no penalty)
            parameters.gapPenalty = 1; %penalty for increasing temporary disappearance time (disappearing for n frames gets a penalty of gapPenalty^n).
            
            %optional; to calculate MS search radius
            %if not input, MS search radius will be the same as gap closing search radius
            parameters.resLimit =3*1.5; %resolution limit, which is generally equal to 3 * point spread function sigma.
            
            costMatrices(2).parameters = parameters;
            clear parameters;
    end
    %%% Kalman filter function names
    
    kalmanFunctions.reserveMem  = 'kalmanResMemLM';
    kalmanFunctions.initialize  = 'kalmanInitLinearMotion';
    kalmanFunctions.calcGain    = 'kalmanGainLinearMotion';
    kalmanFunctions.timeReverse = 'kalmanReverseLinearMotion';
    
    %%% additional input
    
    %saveResults
    % saveResults.dir = [directory '\ParticleDetection\']; %directory where to save input and output
    % saveResults.filename = '140213 100x15x15 HaCat 250nM beads lad Alexa488 phal 2% ND 10s int 200ms exp 02_BG125_Tracks.mat'; %name of file where input and output are saved
    saveResults = 0; %don't save results
    
    %verbose state
    verbose = 1;
    
    %problem dimension
    probDim = 2;
    
    
    %% tracking function call after loading the movieInfo.
    
    [tracksFinal,kalmanInfoLink,errFlag] = trackCloseGapsKalmanSparse(movieInfo,...
        costMatrices,gapCloseParam,kalmanFunctions,probDim,saveResults,verbose);
    
end
% Convert tracks into matrix format. Split/merge information is lost, but
% the segments of the compound track are clear.
    [~,trackedFeatureIndx,trackStartIndx,numSegments] = ...
    convStruct2MatIgnoreMS(tracksFinal);
    
    %% Restructure all tracks into track# vs. frame# matrix with particle index
    % as an entry.
    frameN=size(xPart,2);
    trackN=size(trackedFeatureIndx,1);
    trackFP.Start=NaN(trackN,1);
    trackFP.End=NaN(trackN,1);
    trackFP.Particles=NaN(trackN,frameN);
    trackFP.X=NaN(trackN,frameN);
    trackFP.Y=NaN(trackN,frameN);
    trackFP.Amp=NaN(trackN,frameN);
    trackFP.BGAmp=NaN(trackN,frameN);

    
    for iCompound=1:numel(tracksFinal)
        % identify track start and end.
        currtrack=tracksFinal(iCompound);
        
        for iSeg=1:numSegments(iCompound)
            iT=trackStartIndx(iCompound)+iSeg-1;
           segStartRow=find(currtrack.seqOfEvents(:,2)==1 & currtrack.seqOfEvents(:,3)==iSeg);
                                             % Format: 1st column: frame no., 2nd column: start/end, 3rd
                                             % column: segment Index.
            segEndRow=find(currtrack.seqOfEvents(:,2)==2 & currtrack.seqOfEvents(:,3)==iSeg);
                                             
            trackFP.Start(iT)=currtrack.seqOfEvents(segStartRow,1); % seqOfEvents has 2x the number of track segments.
            trackFP.End(iT)=currtrack.seqOfEvents(segEndRow,1);
            frameIdx=trackFP.Start(iT):trackFP.End(iT);
        
            % Place feature indices into the trackmatrix.
%             partIdx=tracksFeatIndxCG(iT,:);
            trackFP.Particles(iT,frameIdx)=trackedFeatureIndx(iT,frameIdx); % Encode gap by keeping partIdx=0, and frames before/after track NaN. All non-NaN entries same as trackedFeatureIndx.

            % Use the feature indices to read X,Y, intensity, and background.
            partIdx=trackFP.Particles(iT,frameIdx);
            notGap=partIdx>0; 
            IdxIntoParticleDetection=sub2ind(size(xPart),partIdx(notGap),frameIdx(notGap));

            % Construct track information matrices.
            trackFP.X(iT,frameIdx(notGap))=xPart(IdxIntoParticleDetection); % As long as idT is scalar, this kind of assignment works.
            trackFP.Y(iT,frameIdx(notGap))=yPart(IdxIntoParticleDetection);
            trackFP.Amp(iT,frameIdx(notGap))=ampFit(IdxIntoParticleDetection);
            trackFP.BGAmp(iT,frameIdx(notGap))=BGampFit(IdxIntoParticleDetection);
         


            % Fill gaps if asked.
            if(opt.fillGaps)
                gapFrames=trackFP.Particles(iT,:)==0;
                beforeGap=find(diff(gapFrames)==1);
                afterGap=find(diff(gapFrames)==-1)+1;
                for iG=1:numel(beforeGap)
                     thisGap=beforeGap(iG)+1:afterGap(iG)-1;
                     trackFP.X(iT,thisGap)=0.5*( trackFP.X(iT,beforeGap(iG)) +trackFP.X(iT,afterGap(iG))  );
                     trackFP.Y(iT,thisGap)=0.5*( trackFP.Y(iT,beforeGap(iG)) +trackFP.Y(iT,afterGap(iG))  );
                     trackFP.Amp(iT,thisGap)=0.5*( trackFP.Amp(iT,beforeGap(iG)) +trackFP.Amp(iT,afterGap(iG)) );
                     trackFP.BGAmp(iT,thisGap)=0.5*( trackFP.BGAmp(iT,beforeGap(iG)) +trackFP.BGAmp(iT,afterGap(iG)) );
                end
                
            end
                
        end
        
    end

    % Update anisotropy of all tracks.
% [ orientTracks,anisoTracks,intTracks, I0PartTracks, I45PartTracks, I90PartTracks, I135PartTracks, ~,~, ~,~,~,~,~,BGPartTracks]=...
%                  computeParticleAnisotropy(opt.I0,opt.I45,opt.I90,opt.I135,trackFP.X,trackFP.X(idT,tEnd+1:tTracks),nPartTrack,opt.psfSigma,'BGPartFactor',1,'BGaround',true);

end


function MD = bfImport(dataPath,varargin)
% BFIMPORT imports movie files into MovieData objects using Bioformats 
%
% MD = bfimport(dataPath)
%
% Load proprietary files using the Bioformats library. Read the metadata
% that is associated with the movie and the channels and set them into the
% created movie objects. Optionally images can be extracted and saved as
% individual TIFF files.
%
% Input:
% 
%   dataPath - A string containing the full path to the movie file.
%
%   extractImages - Optional. If true, individual images will be extracted
%   and saved as TIF images.
%
% Output:
%
%   MD - A MovieData object
%
% Copyright (C) 2012 LCCB 
%
% This file is part of QFSM.
% 
% QFSM is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% QFSM is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with QFSM.  If not, see <http://www.gnu.org/licenses/>.
% 
% 

% Sebastien Besson, Dec 2011

status = bfCheckJavaPath();
assert(status, 'Bioformats library missing');

% Input check
ip=inputParser;
ip.addRequired('dataPath',@ischar);
ip.addOptional('extractImages',false,@islogical);
ip.addParamValue('outputDirectory',[],@ischar);
ip.parse(dataPath,varargin{:});
extractImages = ip.Results.extractImages;

assert(exist(dataPath,'file')==2,'File does not exist'); % Check path

try
    % Retrieve movie reader and metadata
    r=bfGetReader(dataPath);
    r.setSeries(0);
catch bfException
    ME = MException('lccb:import:error','Import error');
    ME = ME.addCause(bfException);
    throw(ME);
end

% Read number of series and initialize movies
nSeries = r.getSeriesCount();
MD(1, nSeries) = MovieData();

% Set output directory (based on image extraction flag)
[mainPath,movieName,movieExt]=fileparts(dataPath);
token = regexp([movieName,movieExt],'(\w+)\.ome\.tiff','tokens');
if ~isempty(token), movieName = token{1}{1}; end

if ~isempty(ip.Results.outputDirectory)
    mainOutputDir = ip.Results.outputDirectory;
else
    mainOutputDir = fullfile(mainPath, movieName);
end

% Create movie channels
nChan = r.getSizeC();
channelPath = cell(nSeries, nChan);
movieChannels(nSeries, nChan) = Channel();

for i = 1:nSeries
    fprintf(1,'Creating movie %g/%g\n',i,nSeries);
    iSeries = i-1;
    movieArgs = getMovieMetadata(r, iSeries);
    
    % Read number of channels, frames and stacks
    nChan =  r.getMetadataStore().getPixelsSizeC(iSeries).getValue;
    
    if nSeries>1
        sString = num2str(i, ['_s%0' num2str(floor(log10(nSeries))+1) '.f']);
        outputDir = [mainOutputDir sString];
        movieFileName = [movieName sString '.mat'];
    else
        outputDir = mainOutputDir;
        movieFileName = [movieName '.mat'];
    end
    
    % Create output directory
    if ~isdir(outputDir), mkdir(outputDir); end

    for iChan = 1:nChan
        
        channelArgs = getChannelMetadata(r, iSeries, iChan-1);        
        
        % Create new channel
        if extractImages
            % Read channelName
            chanName=r.getMetadataStore().getChannelName(iSeries, iChan-1);
            if isempty(chanName),
                chanName = ['Channel_' num2str(iChan)];
            else
                chanName = char(chanName.toString);
            end
            channelPath{i, iChan} = fullfile(outputDir, chanName);
        else
            channelPath{i, iChan} = dataPath;
        end
        movieChannels(i, iChan) = Channel(channelPath{i, iChan}, channelArgs{:});
        
    end
    
    % Create movie object
    MD(i) = MovieData(movieChannels(i, :), outputDir, movieArgs{:});
    MD(i).setPath(outputDir);
    MD(i).setFilename(movieFileName);
    if ~extractImages, MD(i).setSeries(iSeries); end
    
    if extractImages
        nFrames =  r.getMetadataStore().getPixelsSizeT(iSeries).getValue;
        nZ =  r.getMetadataStore().getPixelsSizeZ(iSeries).getValue;

        % Create anonymous functions for reading files
        tString=@(t)num2str(t, ['%0' num2str(floor(log10(nFrames))+1) '.f']);
        zString=@(z)num2str(z, ['%0' num2str(floor(log10(nZ))+1) '.f']);
        imageName = @(c,t,z) [movieName '_w' num2str(movieChannels(i, c).emissionWavelength_) ...
            '_z' zString(z),'_t' tString(t),'.tif'];
        
        % Clean channel directories and save images as TIF files
        for iChan = 1:nChan, mkClrDir(channelPath{i, iChan}); end
        for iPlane = 1:r.getImageCount()
            index = r.getZCTCoords(iPlane - 1);
            imwrite(bfGetPlane(r, iPlane),[channelPath{i, index(2) + 1} filesep ...
                imageName(index(2) + 1, index(3) + 1, index(1) + 1)],'tif');
        end
    end
    
    % Close reader and check movie sanity
    MD(i).sanityCheck;

end
% Close reader
r.close;

function movieArgs = getMovieMetadata(r, iSeries)

% Create movie metadata cell array using read metadata
movieArgs={};

pixelSizeX = r.getMetadataStore().getPixelsPhysicalSizeX(iSeries);
% Pixel size might be automatically set to 1.0 by @#$% Metamorph
hasValidPixelSize = ~isempty(pixelSizeX) && pixelSizeX.getValue ~= 1;
if hasValidPixelSize
    % Convert from microns to nm and check x and y values are equal
    pixelSizeX= pixelSizeX.getValue*10^3;
    pixelSizeY= r.getMetadataStore().getPixelsPhysicalSizeY(iSeries).getValue*10^3;
    assert(isequal(pixelSizeX,pixelSizeY),'Pixel size different in x and y');
    movieArgs=horzcat(movieArgs,'pixelSize_',pixelSizeX);
end

% Camera bit depth
camBitdepth = r.getBitsPerPixel();
hasValidCamBitDepth = ~isempty(camBitdepth) && mod(camBitdepth, 2) == 0;
if hasValidCamBitDepth
    movieArgs=horzcat(movieArgs,'camBitdepth_',camBitdepth);
end

% Time interval
timeInterval = r.getMetadataStore().getPixelsTimeIncrement(iSeries);
if ~isempty(timeInterval)
    movieArgs=horzcat(movieArgs,'timeInterval_',double(timeInterval));
end

% Lens numerical aperture
try % Use a try-catch statement because property is not always defined
    lensNA=r.getMetadataStore().getObjectiveLensNA(0,0);
    if ~isempty(lensNA)
        movieArgs=horzcat(movieArgs,'numAperture_',double(lensNA));
    elseif ~isempty(r.getMetadataStore().getObjectiveID(0,0))
        % Hard-coded for deltavision files. Try to get the objective id and
        % read the objective na from a lookup table
        tokens=regexp(char(r.getMetadataStore().getObjectiveID(0,0).toString),...
            '^Objective\:= (\d+)$','once','tokens');
        if ~isempty(tokens)
            [na,mag]=getLensProperties(str2double(tokens),{'na','magn'});
            movieArgs=horzcat(movieArgs,'numAperture_',na,'magnification_',mag);
        end
    end
end

function channelArgs = getChannelMetadata(r, iSeries, iChan)

channelArgs={};

% Read excitation wavelength
exwlgth=r.getMetadataStore().getChannelExcitationWavelength(iSeries, iChan);
if ~isempty(exwlgth)
    channelArgs=horzcat(channelArgs, 'excitationWavelength_', exwlgth.getValue);
end

% Fill emission wavelength
emwlgth=r.getMetadataStore().getChannelEmissionWavelength(iSeries, iChan);
if isempty(emwlgth)
    try
        emwlgth= r.getMetadataStore().getChannelLightSourceSettingsWavelength(iSeries, iChan);
    end
end
if ~isempty(emwlgth)
    channelArgs = horzcat(channelArgs, 'emissionWavelength_', emwlgth.getValue);
end

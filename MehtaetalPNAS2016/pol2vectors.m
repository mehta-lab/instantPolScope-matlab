function [ xvec,yvec,anisovec,avgvec ] = pol2vectors(aniso,orient,avg,varargin)
% [ xvec,yvec ]=pol2vectors(aniso,orient,avg,varargin) returns vector
% representation of anisotropy according to options. orient is assumed in
% radian. anisotropy and average are assumed between 0 and 1.
arg.lengthPropToavg=true;
arg.lengthPropToaniso=true;
arg.border=15; % If avgCeiling and anisoCeiling are set to NaN, this value is used to compute the ceilings.
arg.anisoCeiling=NaN; %If anisoCeiling is NaN, set it to max of the data within border.
arg.avgCeiling=NaN; %If avgCeiling is NaN, set it to max of the data within border.
arg=parsepropval(arg,varargin{:});

border=round(arg.border);

% Use the ceilings that have been supplied or compute them from data for
% good contrast.
if isnan(arg.avgCeiling) 
    avgcrop=avg(border:end-border,border:end-border,:);
    avgCeiling=max(avgcrop(:));
else
    avgCeiling=arg.avgCeiling;
end

if isnan(arg.anisoCeiling)
    anisocrop=aniso(border:end-border,border:end-border,:);
    anisoCeiling=max(anisocrop(:));   
else
   anisoCeiling=arg.anisoCeiling;
end

            

% Apply ceilings, normalize, then convert to vectors.
anisovec=aniso/anisoCeiling;
avgvec=avg/avgCeiling;
anisovec(anisovec>1)=1;
avgvec(avgvec>1)=1;

xvec=cos(orient);
yvec=sin(orient);

if(arg.lengthPropToavg)
    xvec=anisovec.*xvec;
    yvec=anisovec.*yvec;
end

if(arg.lengthPropToaniso)
    xvec=avgvec.*xvec;
    yvec=avgvec.*yvec;
end

end


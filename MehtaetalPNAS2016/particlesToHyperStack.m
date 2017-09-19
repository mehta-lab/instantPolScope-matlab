function hyperstack = particlesToHyperStack(anisoPart,orientPart,intPart,xPart,yPart,hyperstackfile,varargin)
% Export details (anisotropy, orientation, intensity, X, Y) about particles
% as a hyperstack for tracking by hand.
args.ImSize=256;
args.nFrames=size(xPart,2);
args=parsepropval(args,varargin{:});

hyperstack=zeros(args.ImSize,args.ImSize,5,args.nFrames,'uint16');

for idF=1:args.nFrames
    xPartThis=xPart(:,idF); 
    yPartThis=yPart(:,idF);
    anisoThis=anisoPart(:,idF); 
    orientThis=orientPart(:,idF);
    intThis=intPart(:,idF);
    
    realParticles=~isnan(xPartThis);
    xPos=round(xPartThis(realParticles)); 
    yPos=round(yPartThis(realParticles));
    
                                %Subscript order: Y,X, Channel, Frame.
    iAniso=sub2ind(size(hyperstack),yPos,xPos,1*ones(size(xPos)),idF*ones(size(xPos)));
    hyperstack(iAniso)=(2^16-1)*anisoThis(realParticles);
    
    
    iOrient=sub2ind(size(hyperstack),yPos,xPos,2*ones(size(xPos)),idF*ones(size(xPos)));
    hyperstack(iOrient)=100*(180/pi)*orientThis(realParticles);
    
    iInt=sub2ind(size(hyperstack),yPos,xPos,3*ones(size(xPos)),idF*ones(size(xPos)));
    hyperstack(iInt)=intThis(realParticles);    
    
    iX=sub2ind(size(hyperstack),yPos,xPos,4*ones(size(xPos)),idF*ones(size(xPos)));
    hyperstack(iX)=100*xPartThis(realParticles);
    
    iY=sub2ind(size(hyperstack),yPos,xPos,5*ones(size(xPos)),idF*ones(size(xPos)));
    hyperstack(iY)=100*yPartThis(realParticles);
        
end

if(~isempty(hyperstackfile))
    hyperstack=reshape(hyperstack,args.ImSize,args.ImSize,5,1,args.nFrames);
    exportHyperStack(hyperstack,hyperstackfile);
end

end


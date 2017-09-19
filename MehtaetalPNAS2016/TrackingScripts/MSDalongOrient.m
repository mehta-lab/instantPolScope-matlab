function [SDpar,SDper,SD,SDdirection,tauAxis]=MSDalongOrient(X,Y,refOrient,varargin)
    opt.dt=1;
    opt.dx=1;
    opt.debug=false;
    opt.refPos=1;
    opt=parsepropval(opt,varargin{:});

    % speedscale=opt.dx/opt.dt;
     SDx=opt.dx*(X-X(opt.refPos)).^2;
     SDy=opt.dx*(Y-Y(opt.refPos)).^2;
     SD=SDx+SDy;
     SDdirection=atan2(SDy,SDx);
     refOrient=repmat(refOrient,[1 numel(SDdirection)]);
     
      vec1=[cos(SDdirection); -sin(SDdirection)]; % Orientation is measured with Y going up, and displacement with Y going down. I correct this difference in convention by reversing Y direciton here.
      vec2=[cos(refOrient); sin(refOrient)];
      SDorientRelativetoRef=acos(dot(vec1,vec2,1));
        
     SDpar=abs(SD.*cos(SDorientRelativetoRef));
     SDper=abs(SD.*sin(SDorientRelativetoRef));
     tauAxis=(0:length(X)-1)*opt.dt;
     
     if(opt.debug);
         togglefig('MSDalongOrient',1);
        
         plot(tauAxis,SD,tauAxis,SDpar,tauAxis,SDper);
         xlabel('\tau (s)'); ylabel('SD (\mum^2)');
         legend('MSD','MSD||','MSD\perp');
     end
 
end
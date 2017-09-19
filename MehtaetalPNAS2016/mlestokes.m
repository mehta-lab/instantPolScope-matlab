function S_mle=mlestokes(ItoSMatrix,Inoisy,varargin)
% Inputs: ItoSMatrix is 3x4 matrix and Ivector is 4x1 vector.
% output MLE estimate of S=3x1 vector.
% Initial estimate of S.
arg.maxIter=5; % Simulation with photoelectrons 
arg=parsepropval(arg,varargin{:});
StoIMatrix=pinv(ItoSMatrix);

% Initial value of s_mle
S_mle=ItoSMatrix*Inoisy;
%disp(['I:' num2str(Inoisy'));

for iter=0:arg.maxIter
   % disp(['itr:' int2str(iter) ',S=' num2str(S_mle')]);
    Iestimate=StoIMatrix*S_mle;
    
    %%  How to vectorize these two steps
    
    D=diag(1./Iestimate,0);
    F= StoIMatrix' * D * StoIMatrix;
    %%%% 
    
    Z=(Inoisy./Iestimate)-1; 
    V=StoIMatrix' * Z;
    S_mle=S_mle+ pinv(F)*V;%F\V; %pinv(F)*V; %%inv(F)* V; % F is well-conditioned, don't need pinv
    
end
    %disp('-------------------');

end
function [ StoIMat,ItoSMat ] = CalibrateInstrumentMatrix(localangles,I,varargin)
% Calibrate the instrument matrix for 4-quadrant system assuming the
% following:
% 1. Local angle of the polarizer is known.
% 2. Anisotropy is the same among all measurements.
% First dimension (column) is assumed to be intensities measured at 4
% polarization angles and the second dimension (row) is assumed to be angle
% of the linear polarizer.

% First eliminate any angle-independent variations in intensity, which may
% be due to differential transmission etc.
IAngleIndependent=mean(I,2);
Ibalanced=I;
Ibalanced(2,:)=(IAngleIndependent(1)/IAngleIndependent(2))*Ibalanced(2,:);
Ibalanced(3,:)=(IAngleIndependent(1)/IAngleIndependent(3))*Ibalanced(3,:);
Ibalanced(4,:)=(IAngleIndependent(1)/IAngleIndependent(4))*Ibalanced(4,:);

% Normalization by the isotropic intensity ensures that the matrix
% multiplication maintains the dynamic range of the input intensity.

Itotal=0.5*sum(Ibalanced,1,'double'); %Total intensity of fluorophore is I0+I90 or I45+I135.
Iisotropic=mean(Itotal);
Inorm=Ibalanced/Iisotropic;

% The best guess for true anisotropy is the mean of all measured
% anisotropies.
ItoSMatNominal=[0.5 0.5 0.5 0.5; 1 0 -1 0; 0 1 0 -1];
SNominal=ItoSMatNominal*Ibalanced;
anisomeas=sqrt(SNominal(3,:).^2 + SNominal(2,:).^2)./SNominal(1,:);
anisoBestEstimate=mean(anisomeas(:));

S=[ones(size(localangles)); anisoBestEstimate*cos(2*localangles); anisoBestEstimate*sin(2*localangles)];


% Compute the matrices.

StoIMat=(Inorm)*pinv(S); % I= FS.
%ItoSMat=S*pinv(Inorm); % S= F^-1I.
ItoSMat=pinv(StoIMat); % This approach provides more balanced use of intensities as compared to above.

% Make a plot showing values if X-axis is supplied.
if(~isempty(varargin))
    xaxis=varargin{1};

    subplot(121);
    plot(xaxis,ItoSMatNominal*I,'.',xaxis,ItoSMat*I,'x');
    xlabel(varargin{2});
    title('Uncalibrated stokes parameters');
    
    Sretrieve=ItoSMat*I;
    azimuthRetrieve=0.5*atan2(Sretrieve(3,:),Sretrieve(2,:));
    subplot(122);
    plot(xaxis,[Sretrieve;azimuthRetrieve],'.');
    legend('S0','S1','S2','Azimuth');
    xlabel(varargin{2});
    title('Calibrated stokes parameters');
end

end


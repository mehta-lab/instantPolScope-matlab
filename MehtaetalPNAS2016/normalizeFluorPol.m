function [I0norm,I45norm,I90norm,I135norm] = normalizeFluorPol(I0,I45,I90,I135,eqfactors)
% Normalize intensity images for polarized fluorescence computation.

    % Normalize
if(isnumeric(eqfactors))
    I0norm=I0*eqfactors(1);
    I45norm=I45*eqfactors(2);
    I90norm=I90*eqfactors(3);
    I135norm=I135*eqfactors(4);    

elseif(iscell(eqfactors))
    if(~ (ismatrix(eqfactors{1}) && ismatrix(eqfactors{2})  && ismatrix(eqfactors{3})  && ismatrix(eqfactors{4})) )
        error('Normalization factors expected to be 2D images of the same size as data.');
    end
    dim1=size(I0,1); dim2=size(I0,2); dim3=size(I0,3); dim4=size(I0,4); dim5=size(I0,5); % Dimensions of hyperstack.
    
    eqfactorI0=imresize(eqfactors{1},[dim1 dim2],'bilinear');
    eqfactorI0=repmat(eqfactorI0,1,1,dim3,dim4,dim5);
    
    eqfactorI45=imresize(eqfactors{2},[dim1 dim2],'bilinear');
    eqfactorI45=repmat(eqfactorI45,1,1,dim3,dim4,dim5);
    
    eqfactorI90=imresize(eqfactors{3},[dim1 dim2],'bilinear');
    eqfactorI90=repmat(eqfactorI90,1,1,dim3,dim4,dim5);
    
    eqfactorI135=imresize(eqfactors{4},[dim1 dim2],'bilinear');
    eqfactorI135=repmat(eqfactorI135,1,1,dim3,dim4,dim5);
    
    I0norm=eqfactorI0.*I0;
    I45norm=eqfactorI45.*I45;
    I90norm=eqfactorI90.*I90;
    I135norm=eqfactorI135.*I135;    
else
    error('Normalization factors should either be scalar factors or the cell array of normalizing images.');
end

end


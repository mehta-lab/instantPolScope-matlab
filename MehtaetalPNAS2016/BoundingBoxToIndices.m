function [idx,idy] = BoundingBoxToIndices( BB )
% BoundingBoxToIndices Function to obtain X and Y indices from bounding box.
idx=floor(BB(1)): floor(BB(1)) + BB(3)-1; 
idy=floor(BB(2)) : floor(BB(2))+ BB(4)-1; 

end


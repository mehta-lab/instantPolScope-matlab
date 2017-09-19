function BB = identifyQuads(im)
%IdentifyQuads Identify the quadrants by thresholding above background.


if(isnan(im)) %If the input is not a calibration image,  use default quadrants.
   % Bounding boxes are written in a format compatible with regionprops
   % output.
   % [ul_corner(x) ul_corner(y) width height].
   % Order in which regionprops returns the quadrants.
    % 1: bottom-left, 2: top-left, 3: bottom-right, 4: top-right
    % quadrant arrangement as on June 5, 2012.

    quadBB(1).BoundingBox=[1 257 255 255];
    quadBB(2).BoundingBox=[1 1 255 255];
    quadBB(3).BoundingBox=[257 257 255 255];
    quadBB(4).BoundingBox=[257 1 255 255];
else
    
    quads=im>blackLevel; %Single blacklevel does not work because of large dynamic range differences between quadrants.
    quadconn=bwconncomp(quads);
    
    % We must have 4 components in the image.
    if(quadconn.NumObjects ~= 4)
        error('QFPregEqualize:geteqmasks:quadrants',...
            'The computed threshold didnt cut it right. Sorry...');
    end

    % bwconncomp labels bottom to top and left to right.
    quadBB=regionprops(quadconn,'BoundingBox');
end       

    BB.(LeftBottom)=quadBB(1).BoundingBox; %bottom-left
    BB.(LeftTop)=quadBB(2).BoundingBox; %top-left
    BB.(RightBottom)=quadBB(3).BoundingBox; %bottom-right
    BB.(RightTop)=quadBB(4).BoundingBox; %top-right


    
end
  
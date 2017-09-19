function exportHyperStack(stackData, filename,varargin)
% exportHyperStack(stackData, filename) exports multi-D data as ImageJ
% hyperstack assuming XYCZT order of the dimensions.

% Usage:
% teststack=zeros(100,100,8,5,'uint16');
% exportHyperStack(teststack,'test_hyperstack.tif');
%
%
% arg=parsepropval(arg,varargin{:});

% parse image dimentions & type
channelsN = size(stackData,3);
slicesN = size(stackData,4);
framesN = size(stackData,5);
imagesN = channelsN * slicesN * framesN;
xN=size(stackData,2); yN=size(stackData,1);
% % loop dims
% for t=1:framesN
%     for s=1:slicesN
%         for c=1:channelN
%             if (t==1 && s==1 && c==1)
%                 imwrite(stackData(:,:,c,s,t),fullfile(filename),'tiff','Compression','none','WriteMode','overwrite');
%             else
%                 imwrite(stackData(:,:,c,s,t),fullfile(filename),'tiff','Compression','none','WriteMode','append');
%             end
%         end
%     end
% end

% Or use saveastiff to write the entire stack - allows writing double/single stacks.
saveastiff(reshape(stackData,[yN xN imagesN]),filename);

% Now write metadata that allows ImageJ to open the file correctly.
writeHyperStackTag(filename,xN,yN,channelsN,slicesN,framesN)

end

function writeHyperStackTag(filename,xN,yN,channelsN,slicesN,framesN)
% Writing following Metadata entry to TIFF stack converts it into
% Hyperstack. The default write order in hyperstack is XYCZT.
% This function contributed by Amitabh Verma.

imagesN=channelsN*slicesN*framesN;
% http://metarabbit.wordpress.com/2014/04/30/building-imagej-hyperstacks-from-python/
metadata_text = char([
                ['ImageJ=1.48o', 10],...
                ['ImageLength=', num2str(yN), 10],...
                ['ImageWidth=', num2str(xN), 10],...
                ['images=', num2str(imagesN), 10],...
                ['channels=', num2str(channelsN), 10],...                
                ['slices=', num2str(slicesN), 10],...
                ['frames=', num2str(framesN), 10],...
                ['hyperstack=true', 10],...
                ['mode=grayscale', 10],...                
                ['loop=false', 10],...
                ['IsInterleaved=false',10],...
                ]);
        
    t = Tiff(fullfile(filename), 'r+');
    % Modify the value of a tag.
    % http://www.digitalpreservation.gov/formats/content/tiff_tags.shtml
    % t.setTag('Software',['OI-DIC',' ',num2str(version_number),'x']);
    % t.setTag('Model', 'Lumenera Infinity 3M');
    
    % set tag
    t.setTag('ImageDescription', metadata_text);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Orientation tag is critical for ImageJ to display the hyperstack correctly.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    t.setTag('Orientation',Tiff.Orientation.TopLeft); 
    % write tag to file
    t.rewriteDirectory();
    
    % close tiff
    t.close()
end
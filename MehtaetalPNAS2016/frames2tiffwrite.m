function frames2tiffwrite(frames,fname)
% frames2tiffwrite(frames,fname)
% This function writes out MATLAB movie frames to an RGB TIFF Stack.

% Setup a stack.
oneIm=frame2im(frames(1));
im=zeros([size(oneIm) length(frames)],class(oneIm));
for ii=1:length(frames) 
    im(:,:,:,ii)=imresize(frame2im(frames(ii)),[size(oneIm,1) size(oneIm,2)]);
end
options.color=true;
saveastiff(im,fname,options);
end
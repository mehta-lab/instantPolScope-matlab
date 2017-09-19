function frames2movwrite(frames,fname,fps,framerep)
% frames2movwrite(frames,filename,fps,framerep)
% This function writes out MATLAB movie frames to a MPEG compressed AVI
% file.

vh=VideoWriter(fname);
vh.FrameRate=fps;
open(vh);
for i=1:length(frames)
    %frm=frame2im(frames(i));
    frm=frames(i);
    for j=1:framerep
        writeVideo(vh,frm);
    end
end
close(vh);
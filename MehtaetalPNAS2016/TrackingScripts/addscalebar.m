function addscalebar(pixsize,scalesize,varargin)
% Utility function to add scalebar to current axes at the bottom-left corner. Scalebar location and width can be adjusted by using optional arguments. 
% addscalebar(PixelSize,ScaleBarLength,<'xloc',XLocation,'yloc',YLocation,'Parent',ChosenAxes,'scalewidth',ScaleWidth>)
opt.Parent=gca;
opt.scalewidth=5;
opt.xloc=min(get(gca,'xlim'))+5; % Place the scale bar on the bottom left corner by default.
opt.yloc=max(get(gca,'ylim'))-5;
opt.color='w';
opt.text='';
opt=parsepropval(opt,varargin{:});

scalePix=scalesize/pixsize;
line([opt.xloc opt.xloc+scalePix],[opt.yloc opt.yloc],'color',opt.color,'LineWidth',opt.scalewidth,'Parent',opt.Parent);
text(opt.xloc,opt.yloc-opt.scalewidth-2,opt.text,'color',opt.color');


end


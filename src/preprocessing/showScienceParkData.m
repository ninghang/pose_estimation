%% load from raw data
vidFolderIdx = 4;
camFolder = '/media/Hitachi/ScienceParkNewData/fisheye1';
% camFolder = '/media/Hitachi/ScienceParkNewData/fisheye2';
data = ScienceParkData(camFolder,vidFolderIdx);

%% load from annotated data
clear all
load matlab.mat

%% plot frames

for i = 1:length(data.Imagelist)
  data.Now = i;
  visualizeSkeleton(data);
  title(data.Now)
  hold off
  pause
%   waitfor(30)
  drawnow
end

% given a raw image and skeleton points, refine the points 
% crop the image containing only one person
% transform skeleton points to person image
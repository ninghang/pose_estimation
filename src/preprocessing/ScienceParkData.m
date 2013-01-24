classdef ScienceParkData
  % SCIENCEPARKDATA load the data collected with Kinect and two fisheye
  % cameras
  
  properties
    Now = 1; % current data item being processed
    Points % skeleton points
    Imagelist % list of imagefiles
    Timestamp % timestamp
    CamFolder %
    VidFolderIdx % video index in the camera folder
  end
  
  properties (Constant)
    SkeletonLabels = {...
      'head_1' 'neck_1' 'torso_1' ...
      'left_shoulder_1' 'left_elbow_1' 'left_hand_1' ...
      'right_shoulder_1' 'right_elbow_1' 'right_hand_1' ...
      'left_hip_1' 'left_knee_1' 'left_foot_1' ...
      'right_hip_1' 'right_knee_1' 'right_foot_1'};
  end
  
  methods
    
    function spd = ScienceParkData(camFolder,vidFolderIdx)
      
      spd.CamFolder = camFolder;
      spd.VidFolderIdx = vidFolderIdx;
      
      % concatenate video path from video idx
      dirlist = dir(fullfile(camFolder, '/*retopic'));
      if isempty(dirlist)
        error('%s does not exist\n',fullfile(camFolder, '/*retopic'))
      end
      vidFolder = fullfile(camFolder,dirlist(vidFolderIdx).name);
      
      % load skeleton points
      addpath('/home/ninghang/workspace/mexopencv/cv') % OpenCV xml loader
      skel_pts = FileStorage(fullfile(vidFolder, 'skeletons.yaml'));
      spd.Points = zeros([size(skel_pts.head_1) length(spd.SkeletonLabels)]);
      for j = 1:length(spd.SkeletonLabels)
        spd.Points(:,:,j) = skel_pts.(spd.SkeletonLabels{j});
      end
      
      % load image frame names
      imlist = dir(fullfile(vidFolder, '*.jpg'));
      imTimeStamp = zeros(size(imlist));
      for i = 1 : size(imlist,1)
        imFile = imlist(i).name;
        imTimeStamp(i) = str2double(imFile(1:end-4));
      end
      
      % intersection between the skeleton points and image frames
      [spd.Timestamp,sidx,iidx] = intersect(skel_pts.timestamp,imTimeStamp);
      spd.Points = spd.Points(sidx,:,:);
      spd.Imagelist = cell(length(spd.Timestamp),1);
      for i = 1:length(spd.Timestamp)
        spd.Imagelist{i} = fullfile(vidFolder,imlist(iidx(i)).name);
      end
      
    end
%     
%     function initPerElement(now,points,imagelist,timestamp,camFolder,vidFolderIdx)
%       spd.Now = now;
%       spd.Points = points;
%       spd.Imagelist = imagelist;
%       spd.Timestamp = timestamp;
%       spd.CamFolder = camFolder;
%       spd.VidFolderIdx = vidFolderIdx;
%     end
    
  end
  
end
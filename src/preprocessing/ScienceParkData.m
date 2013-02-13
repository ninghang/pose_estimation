classdef ScienceParkData < handle
  % SCIENCEPARKDATA load the data collected with Kinect and two fisheye
  % cameras
  
  properties
    Now = 1;  % current data item being processed
    Points    % skeleton points
    Imagelist % list of imagefiles
    Timestamp % timestamp
    CamFolder %
    VidFolderIdx % video index in the camera folder
    ActionID    % action labels
  end
  
  properties (Constant)
    ActionLabels = {...
      'standing' 'bending' 'sitting' 'pointing' 'waving' 'drinking' 'stretching' 'walking'}
    SkeletonLabels = {...
      'head_1' 'neck_1' 'torso_1' ...
      'left_shoulder_1' 'left_elbow_1' 'left_hand_1' ...
      'right_shoulder_1' 'right_elbow_1' 'right_hand_1' ...
      'left_hip_1' 'left_knee_1' 'left_foot_1' ...
      'right_hip_1' 'right_knee_1' 'right_foot_1'};
  end
  
  methods
    
    % constructor
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
      
      % init action labels as zero matrix
      spd.ActionID = zeros(length(spd.Imagelist),length(spd.ActionLabels));
      
    end
    
    function append(spd,A)
      
      spd.Points = cat(1,spd.Points,A.Points);
      spd.Imagelist = cat(1,spd.Imagelist,A.Imagelist);
      spd.Timestamp = cat(1,spd.Timestamp,A.Timestamp);
      spd.ActionID = cat(1,spd.ActionID,A.ActionID);
      
    end
    
    % select subset by action label
    function B = selectLabel(spd,label)
      
      c = strcmp(label,spd.ActionLabels);
      if c == 0
        disp(spd.ActionLabels);
        error('incorrect action label, recheck.');
      else
        dataIdx = (spd.ActionID(:,c) == 1);
        B = spd.selectRow(dataIdx);
      end
      
    end
    
    % select subset by row index
    function B = selectRow(spd,idx)
      B = spd;
      B.Points = spd.Points(idx,:,:);
      B.Imagelist = spd.Imagelist(idx);
      B.Timestamp = spd.Timestamp(idx);
      B.ActionID = spd.ActionID(idx,:);
      
    end
  end
  
end
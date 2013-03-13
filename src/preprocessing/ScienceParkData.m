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
    function this = ScienceParkData(varargin)
      
      if nargin == 1 || nargin > 2
        
        error('incorrect number of input arguments in constructor')

      elseif nargin == 2
        
        camFolder = varargin{1};
        vidFolderIdx = varargin{2};
        
        this.CamFolder = camFolder;
        this.VidFolderIdx = vidFolderIdx;
        
        % concatenate video path from video idx
        dirlist = dir(fullfile(camFolder, '/*retopic'));
        if isempty(dirlist)
          error('%s does not exist\n',fullfile(camFolder, '/*retopic'))
        end
        vidFolder = fullfile(camFolder,dirlist(vidFolderIdx).name);
        
        % load skeleton points
        addpath('/home/ninghang/workspace/mexopencv/cv') % OpenCV xml loader
        skel_pts = FileStorage(fullfile(vidFolder, 'skeletons.yaml'));
        this.Points = zeros([size(skel_pts.head_1) length(this.SkeletonLabels)]);
        for j = 1:length(this.SkeletonLabels)
          this.Points(:,:,j) = skel_pts.(this.SkeletonLabels{j});
        end
        
        % load image frame names
        imlist = dir(fullfile(vidFolder, '*.jpg'));
        imTimeStamp = zeros(size(imlist));
        for i = 1 : size(imlist,1)
          imFile = imlist(i).name;
          imTimeStamp(i) = str2double(imFile(1:end-4));
        end
        
        % intersection between the skeleton points and image frames
        [this.Timestamp,sidx,iidx] = intersect(skel_pts.timestamp,imTimeStamp);
        this.Points = this.Points(sidx,:,:);
        this.Imagelist = cell(length(this.Timestamp),1);
        for i = 1:length(this.Timestamp)
          this.Imagelist{i} = fullfile(vidFolder,imlist(iidx(i)).name);
        end
        
        % init action labels as zero matrix
        this.ActionID = zeros(length(this.Imagelist),length(this.ActionLabels));
      
      end
      
    end
    
    % append new data to the end
    function append(this,A)
      
      this.Points = cat(1,this.Points,A.Points);
      this.Imagelist = cat(1,this.Imagelist,A.Imagelist);
      this.Timestamp = cat(1,this.Timestamp,A.Timestamp);
      this.ActionID = cat(1,this.ActionID,A.ActionID);
      this.VidFolderIdx = 0;
      
      this.clean;
      
    end
    
    % select subset by action label
    function dataIdx = selectByLabel(this,label)
      
      c = strcmp(label,this.ActionLabels);
      if c == 0
        disp(this.ActionLabels);
        error('incorrect action label, recheck.');
      else
        dataIdx = (this.ActionID(:,c) == 1);
        this.selectByRow(dataIdx);
      end
      
    end
    
    % select subset by row index
    function selectByRow(this,idx)
      
      this.Points = this.Points(idx,:,:);
      this.Imagelist = this.Imagelist(idx);
      this.Timestamp = this.Timestamp(idx);
      this.ActionID = this.ActionID(idx,:);
      
    end
    
    % clone this instance
    function new = clone(this)
      
      % Instantiate new object of the same class.
      new = ScienceParkData();
      new.Points = this.Points;
      new.Imagelist = this.Imagelist;
      new.Timestamp = this.Timestamp;
      new.ActionID = this.ActionID;
      new.CamFolder = this.CamFolder;
      new.VidFolderIdx = this.VidFolderIdx;
      
    end
    
    % data info
    function info(this)
      
      disp(this.ActionLabels);
      disp(sum(this.ActionID));
      
    end
    
    % remove duplicate data
    function clean(this)
      
      len = length(this.Timestamp);
      [C,IdxA] = unique(this.Timestamp,'rows');
      this.Imagelist = this.Imagelist(IdxA);
      this.Points = this.Points(IdxA,:,:);
      this.Timestamp = C;
      this.ActionID = this.ActionID(IdxA,:);
      
      if len > length(IdxA)
        fprintf('Removed Duplicate Data: %d -> %d, %d were removed\n',...
          len, length(IdxA), len - length(IdxA));
      end
      
    end

  end
  
end
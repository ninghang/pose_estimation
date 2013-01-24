function varargout = gui(varargin)
  
  % Begin initialization code - DO NOT EDIT
  gui_Singleton = 1;
  gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @gui_OpeningFcn, ...
    'gui_OutputFcn',  @gui_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
  if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
  end
  
  if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
  else
    gui_mainfcn(gui_State, varargin{:});
  end
  % End initialization code - DO NOT EDIT
end

% --- Executes just before gui is made visible.
function gui_OpeningFcn(hObject, eventdata, handles, varargin)
  
  % Choose default command line output for gui
  handles.output = hObject;
  
  % Update handles structure
  guidata(hObject, handles);
  
  %%%%%%%%%% INIT %%%%%%%%%%%%%
  %   camFolder = '/media/Hitachi/ScienceParkNewData/fisheye2';
  clear data ph;
  global data ph;
  vidFolderIdx = 5;
  camFolder = '/media/Hitachi/ScienceParkNewData/fisheye1';
  data = ScienceParkData(camFolder,vidFolderIdx);
  ph = visualizeSkeleton(data);
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

% --- Outputs from this function are returned to the command line.
function varargout = gui_OutputFcn(hObject, eventdata, handles)
  varargout{1} = handles.output;
end


% --- Executes on selection change in pushbutton_next.
function pushbutton_next_Callback(hObject, eventdata, handles)
  global data ph
  
  % update current points
  for i = 1:length(ph)
    p = ph{i}.getPosition;
    data.Points(data.Now,1,i) = p(1);
    data.Points(data.Now,2,i) = p(2);
  end
  save(sprintf('%d.mat',data.VidFolderIdx),'data')
  
  % remove skipped frames
  if data.Now + 10  > size(data.Points,1)
    d = size(data.Points,1);
  else
    d = data.Now + 10;
  end
  data.Points(data.Now+1 : d,:,:) = [];
  data.Imagelist(data.Now+1 : d,:) = [];
  data.Timestamp(data.Now+1 : d,:) = [];
  if data.Now == size(data.Points,1)
    disp('Video all finished. Done.');
    info(data);
    save(sprintf('%d.mat',vidFolderIdx),'data');
    return
  else
    % go to the next frame
    info(data);
    data.Now = data.Now + 1;
    ph = visualizeSkeleton(data);
  end
end

% --- Executes on button press in pushbutton_redo.
function pushbutton_redo_Callback(hObject, eventdata, handles)
  global data ph;
  info(data)
  ph = visualizeSkeleton(data);
end

% --- Executes on button press in pushbutton_skip.
function pushbutton_skip_Callback(hObject, eventdata, handles)
  
  global data ph;
  
  % remove current frames
  data.Points(data.Now,:,:) = [];
  data.Imagelist(data.Now,:) = [];
  data.Timestamp(data.Now,:) = [];
  
  info(data);
  ph = visualizeSkeleton(data);
  
end
% --- Executes on button press in pushbutton_save.
function pushbutton_save_Callback(hObject, eventdata, handles)
  
  global data;
  time = clock;
  filename = sprintf('%d_%d%02d%02d%02d%02d.mat',data.VidFolderIdx,time(1),time(2),time(3),time(4),time(5));
  save(filename,'data')
  
end
% --- Executes on button press in pushbutton_load.
function pushbutton_load_Callback(hObject, eventdata, handles)
  clear data ph
  global data ph
  filename = input('specify the .mat file to load\n', 's');
  load(filename)
  str = input('From which frame to start? (default - value in the data)\n', 's');
  if ~isempty(str)
    data.Now = str2double(str);
  end
  info(data)
  ph = visualizeSkeleton(data);
end

% --- Executes on button press in pushbutton_Check.
function pushbutton_Check_Callback(hObject, eventdata, handles)
  
  global ph data
  
  % update current points
  for i = 1:length(ph)
    p = ph{i}.getPosition;
    data.Points(data.Now,1,i) = p(1);
    data.Points(data.Now,2,i) = p(2);
  end
  save(sprintf('%d.mat',data.VidFolderIdx),'data')
  
  if data.Now == size(data.Points,1)
    disp('Video all finished. Done.');
    info(data);
    save(sprintf('%d.mat',vidFolderIdx),'data');
    return
  else
    % go to the next frame
    info(data);
    data.Now = data.Now + 1;
    ph = visualizeSkeleton(data);
  end
end

function info(data)
  str = sprintf('%d / %d', data.Now, size(data.Points,1));
  disp(str);
end
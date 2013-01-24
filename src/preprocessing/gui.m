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


% --- Executes just before gui is made visible.
function gui_OpeningFcn(hObject, eventdata, handles, varargin)

  % Choose default command line output for gui
  handles.output = hObject;

  % Update handles structure
  guidata(hObject, handles);

  % INIT
%   camFolder = '/media/Hitachi/ScienceParkNewData/fisheye2';
  global id pa points imls colors ts vidFolderIdx camFolder;
  
  vidFolderIdx = 5;
  camFolder = '/media/Hitachi/ScienceParkNewData/fisheye1';
  id = 1;
  pa = [0 1 2 2 4 5 2 7 8 3 10 11 3 13 14]; % tree
  colors = 'rrrbbbgggyyyccc'; % skeleton colors
  [points,imls,ts] = loadData(camFolder,vidFolderIdx);
  annotateSkeleton;
  
  %%%

% --- Outputs from this function are returned to the command line.
function varargout = gui_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;



% --- Executes on selection change in pushbutton_next.
function pushbutton_next_Callback(hObject, eventdata, handles)
  global id ph points imls ts camFolder vidFolderIdx;
  % update current points
  for i = 1:length(ph)
    p = ph{i}.getPosition;
    points(id,1,i) = p(1);
    points(id,2,i) = p(2);
  end
  filename = fprintf('%d.mat',vidFolderIdx);
  save(filename,'points','imls','ts', 'id','camFolder','vidFolderIdx')
  
  % remove skipped frames
  if id + 10  > size(points,1)
    d = size(points,1);
  else
    d = id + 10;
  end
  points(id+1 : d,:,:) = [];
  imls(id+1 : d,:) = [];
  ts(id+1 : d,:) = [];
  if id == size(points,1) 
    disp('Annotating reached the end of the video');
    fprintf('%d / %d', id, size(points,1));
    filename = fprintf('%d.mat',vidFolderIdx);
    save(filename,'points','imls','ts', 'id','camFolder','vidFolderIdx');
    return
  else
    % go to next frame
    fprintf('%d / %d', id, size(points,1))
    id = id + 1;
    annotateSkeleton;
  end

% --- Executes on button press in pushbutton_redo.
function pushbutton_redo_Callback(hObject, eventdata, handles)
  global id points;
  fprintf('%d / %d', id, size(points,1))
  annotateSkeleton;
  
% --- Executes on button press in pushbutton_skip.
function pushbutton_skip_Callback(hObject, eventdata, handles)
  
  global id points imls ts;
  
  % remove skipped frames
  points(id,:,:) = [];
  imls(id,:) = [];
  ts(id,:) = [];

%   id = id + 1;
  fprintf('%d / %d', id, size(points,1))
  annotateSkeleton;


% --- Executes on button press in pushbutton_save.
function pushbutton_save_Callback(hObject, eventdata, handles)
    
  global id points imls ts camFolder vidFolderIdx;
  time = clock;
  filename = fprintf('%d_%d%02d%02d%02d%02d.mat',vidFolderIdx,time(1),time(2),time(3),time(4),time(5));
  save(filename,'points','imls','ts', 'id','camFolder','vidFolderIdx')


% --- Executes on button press in pushbutton_load.
function pushbutton_load_Callback(hObject, eventdata, handles)
  global points id
  filename = input('specify the .mat file to load\n', 's');
  load(filename);
  fprintf('%d / %d', id, size(points,1))
  annotateSkeleton;

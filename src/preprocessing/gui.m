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
  vidFolderIdx = 4;
  camFolder = '/media/Hitachi/ScienceParkNewData/fisheye1';
  data = ScienceParkData(camFolder,vidFolderIdx);
  ph = visualizeSkeleton(data);
  getActionLabel(data,handles);
  info(data);

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
    getActionLabel(data,handles)

  end
end

% --- Executes on button press in pushbutton_redo.
function pushbutton_redo_Callback(hObject, eventdata, handles)
  global data ph;
  info(data)
  ph = visualizeSkeleton(data);
  getActionLabel(data,handles)
end

% --- Executes on button press in pushbutton_skip.
function pushbutton_skip_Callback(hObject, eventdata, handles)
  
  global data ph;
  
  % remove current frames
  data.Points(data.Now,:,:) = [];
  data.Imagelist(data.Now,:) = [];
  data.Timestamp(data.Now,:) = [];
  data.ActionID(data.Now,:) = [];
  
  info(data);
  ph = visualizeSkeleton(data);
  getActionLabel(data,handles)

  
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
  getActionLabel(data,handles)
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
  
  getActionLabel(data,handles)
  save(sprintf('%d.mat',data.VidFolderIdx),'data')
  
  if data.Now == size(data.Points,1)
    disp('Video all finished. Done.');
    time = clock;
    filename = sprintf('%d_%d%02d%02d%02d%02d.mat',data.VidFolderIdx,time(1),time(2),time(3),time(4),time(5));
    save(filename,'data')
    return
  else
    % go to the next frame
    data.Now = data.Now + 1; 
    info(data);
    ph = visualizeSkeleton(data);
    getActionLabel(data,handles)
  end
end

% --- Executes on button press in pushbutton_skip_all.
function pushbutton_skip_all_Callback(hObject, eventdata, handles)
  % hObject    handle to pushbutton_skip_all (see GCBO)
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  global data;
  
  % remove current frames
  data.Points(data.Now:end,:,:) = [];
  data.Imagelist(data.Now:end,:) = [];
  data.Timestamp(data.Now:end,:) = [];
  data.ActionID(data.Now:end,:) = [];
  
  data.Now = data.Now - 1;
  info(data);
  %   ph = visualizeSkeleton(data);
  disp('Skipped all. Video all finished. Done.');
  time = clock;
  filename = sprintf('%d_%d%02d%02d%02d%02d.mat',data.VidFolderIdx,time(1),time(2),time(3),time(4),time(5));
  save(filename,'data')
  
  return
  
end


% --- Executes on button press in radiobutton_standing.
function radiobutton_standing_Callback(hObject, eventdata, handles)
  % hObject    handle to radiobutton_standing (see GCBO)
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  
  % Hint: get(hObject,'Value') returns toggle state of radiobutton_standing
  
  global data
  data.ActionID(data.Now,1) = get(hObject,'Value');
end

% --- Executes on button press in radiobutton_bending.
function radiobutton_bending_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_bending (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton_bending

  global data
  data.ActionID(data.Now,2) = get(hObject,'Value');

end

% --- Executes on button press in radiobutton_sitting.
function radiobutton_sitting_Callback(hObject, eventdata, handles)
  % hObject    handle to radiobutton_sitting (see GCBO)
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  
  % Hint: get(hObject,'Value') returns toggle state of radiobutton_sitting
  global data
  data.ActionID(data.Now,3) = get(hObject,'Value');
end

% --- Executes on button press in radiobutton_pointing.
function radiobutton_pointing_Callback(hObject, eventdata, handles)
  % hObject    handle to radiobutton_pointing (see GCBO)
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  
  % Hint: get(hObject,'Value') returns toggle state of radiobutton_pointing
  global data
  data.ActionID(data.Now,4) = get(hObject,'Value');
end

% --- Executes on button press in radiobutton_waving.
function radiobutton_waving_Callback(hObject, eventdata, handles)
  % hObject    handle to radiobutton_waving (see GCBO)
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  
  % Hint: get(hObject,'Value') returns toggle state of radiobutton_waving
  global data
  data.ActionID(data.Now,5) = get(hObject,'Value');
end

% --- Executes on button press in radiobutton_drinking.
function radiobutton_drinking_Callback(hObject, eventdata, handles)
  % hObject    handle to radiobutton_drinking (see GCBO)
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  
  % Hint: get(hObject,'Value') returns toggle state of radiobutton_drinking
  
  global data
  data.ActionID(data.Now,6) = get(hObject,'Value');
end

% --- Executes on button press in radiobutton_stretching.
function radiobutton_stretching_Callback(hObject, eventdata, handles)
  % hObject    handle to radiobutton_stretching (see GCBO)
  % eventdata  reserved - to be defined in a future version of MATLAB
  % handles    structure with handles and user data (see GUIDATA)
  
  % Hint: get(hObject,'Value') returns toggle state of radiobutton_stretching
  
  global data
  data.ActionID(data.Now,7) = get(hObject,'Value');
end

% --- Executes on button press in radiobutton_walking.
function radiobutton_walking_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton_walking (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton_walking
  global data
  data.ActionID(data.Now,8) = get(hObject,'Value');
end

function getActionLabel(data,handles)
  
  l = data.ActionID(data.Now,1);
  set(handles.radiobutton_standing,'Value',l);

  l = data.ActionID(data.Now,2);
  set(handles.radiobutton_bending,'Value',l);
  
  l = data.ActionID(data.Now,3);
  set(handles.radiobutton_sitting,'Value',l);
  
  l = data.ActionID(data.Now,4);
  set(handles.radiobutton_pointing,'Value',l);

  l = data.ActionID(data.Now,5);
  set(handles.radiobutton_waving,'Value',l);
  
  l = data.ActionID(data.Now,6);
  set(handles.radiobutton_drinking,'Value',l);
  
  l = data.ActionID(data.Now,7);
  set(handles.radiobutton_stretching,'Value',l);
  
  l = data.ActionID(data.Now,8);
  set(handles.radiobutton_walking,'Value',l);
  
end


function info(data)
  fprintf('%d / %d: vid%d\n', data.Now, size(data.Points,1),data.VidFolderIdx);
end

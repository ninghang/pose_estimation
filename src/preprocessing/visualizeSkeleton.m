function ph = visualizeSkeleton(data)
  
  pa = [0 1 2 2 4 5 2 7 8 3 10 11 3 13 14]; % tree
  colorset = 'rrrbbbgggyyyccc'; % skeleton colors
  
  if nargin ~= 1
    error('One input argument expected. [ScienceParkData]');
  end
  
  idx = data.Now;
  im = data.Imagelist{idx};
  pts = squeeze(data.Points(data.Now,:,:))';
  
  if ishold
    hold off
  end
  imh = imshow(im);
  hold on
  
  % set view region
  shift = 50; % region + 50x2 pixels
  maxX = max(pts(:,1)) + shift;
  minX = min(pts(:,1)) - shift;
  maxY = max(pts(:,2)) + shift;
  minY = min(pts(:,2)) - shift;
  xlim([minX,maxX]);
  ylim([minY,maxY]);
  
  % initialize skeleton pts and lines
  ph = cell(size(pa)); % point handler buffer
  lh = zeros(size(pa)); % line handler buffer
  for i = 1:length(pa)
    ph{i} = impoint(gca,pts(i,:));
    setColor(ph{i},colorset(i));
    if pa(i) ~= 0
      lh(i) = plot(pts([pa(i),i],1),pts([pa(i),i],2),colorset(i));
      uistack(lh(i),'bottom')
    end
  end
  
  % add listeners
  for i = 1:length(pa)
    addNewPositionCallback(ph{i},@(h) update(pa, lh, ph));
  end
  uistack(imh,'bottom')

end

function update(pa, lh, ph)
  
  % update vertices
  pts = updatePoints(ph,pa);
  
  % update lines
  updateLines(lh,pa,pts)
  
end

% update skeleton vertices
function pts = updatePoints(ph,pa)
  
  pts = zeros(length(ph),2);
  for i = 1:length(pa)
    pts(i,:) = ph{i}.getPosition;
  end
  
end

% update skeleton edges
function updateLines(lh,pa,pts)
  
  for i = 1:length(pa)
    if pa(i) ~= 0
      set(lh(i), 'XData', pts([pa(i),i],1), 'YData', pts([pa(i),i],2));
    end
  end
  
end

function drawBoxes(data,pa,colorset)
  
  for i = 1:length(pa)
    w = data.x2(i) - data.x1(i);
    h = data.y2(i) - data.y1(i);
    rectangle('Position',[data.x1(i),data.y1(i),w,h],'EdgeColor',colorset(i))
  end
  
end
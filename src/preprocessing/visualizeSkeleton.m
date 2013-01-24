function ph = visualizeSkeleton(data)
  
  pa = [0 1 2 2 4 5 2 7 8 3 10 11 3 13 14]; % tree
  colors = 'rrrbbbgggyyyccc'; % skeleton colors
  
  if ishold
    hold off
  end
  
  im = data.Imagelist{data.Now};
  pts = squeeze(data.Points(data.Now,:,:))';
  
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
    setColor(ph{i},colors(i));
    if pa(i) ~= 0
      lh(i) = plot(pts([pa(i),i],1),pts([pa(i),i],2),colors(i));
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
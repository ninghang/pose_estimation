# timeout time
t=1800

# set path
res_path=~/workspace/pose_estimation/res

# for camera 1 and 3
for idx in 1 3
do
  cam=camera$idx
  echo $cam

  vid_path=$res_path/videos/$cam
  frame_path=$res_path/frame_images/$cam

  mkdir -p $frame_path

  # list of videos
  cd $vid_path
  vid_list=`ls 2012*.bag | grep -v retopic`

  cnt=0

  # for each video in camera
  for vid in $vid_list
  do

    cnt=`expr $cnt + 1`

    # avoid background videos 
    if [ $cnt -lt 4 ]
    then
      continue
    fi

    # get video name base
    base="${vid%.*}"
    echo $base
    mkdir -p $frame_path/$base

    # check if retopic exists
    if [ ! -f $vid_path/${base}-retopic.bag ]
    then
      # retopic video 
      python ~/workspace/pose_estimation/src/retopicBag.py $vid_path/$vid $vid_path/${base}-retopic.bag /$cam
    fi

    # localization
    timeout $t roslaunch accompany_uva save_all_results_test.launch param_path:=/home/ninghang/workspace/ros/accompany/accompany_uva/res/testRobotHouse/$cam video_file:=$vid_path/${base}-retopic.bag dst_path:=$frame_path/$base camera:=$cam camera:=$cam

  done
done

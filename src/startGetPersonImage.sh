res_path=~/workspace/pose_estimation/res

# for camera 1 and 3
for idx in 1 3
do

  cam=camera$idx
  dst_path=$res_path/human_images/$cam
  mkdir -p $dst_path
  echo $cam

  # source video frames
  frame_path=$res_path/frame_images/$cam
  cd $frame_path
  vid_list=`ls`

  cnt=0
  # for each video in camera
  for vid in $vid_list
  do

    cnt=`expr $cnt + 1`

    # get video name base
    base="${vid%.*}"
    echo $base

    mkdir -p $dst_path/$base

   /home/ninghang/workspace/pose_estimation/src/getPersonImage -f $frame_path/$vid -d $dst_path/$vid 
  done
done

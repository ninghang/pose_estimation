# check arugments
if [ $# -eq 0 ]
then
    echo usage $0 [video index to show]
    exit
fi
vid_idx=$1 # video to show

# set path
cam1=/media/Hitachi/ScienceParkNewData/fisheye1
cam2=/media/Hitachi/ScienceParkNewData/fisheye2
cam3=/media/Hitachi/ScienceParkNewData/kinect

# retopic all videos

for cam in $cam1 $cam2
do
    dirbase=`basename $cam`
    echo $dirbase

    vidlist=`ls $cam/*.bag | grep -v retopic`

    for vid in $vidlist
    do
        vidbase="${vid%.*}"

        if [ -f ${vidbase}-retopic.bag ]
        then
            echo ${vidbase}-retopic.bag exist. skip.
            continue
        else
            echo mv from $vid to ${vidbase}-retopic.bag
            python ~/workspace/pose_estimation/src/retopicBag.py $vid ${vidbase}-retopic.bag /$dirbase
        fi
    done
done

# looking for time shift for synchronization
sync_path="/media/Hitachi/ScienceParkNewData/timeDiffInfo.txt"
c_fisheye1=`awk 'NR==var1 {print $1}' var1="$vid_idx" $sync_path`
c_fisheye2=`awk 'NR==var1 {print $2}' var1="$vid_idx" $sync_path`

# play videos

list1=`ls $cam1/*retopic.bag`
list2=`ls $cam2/*retopic.bag`
list3=`ls $cam3/*.bag`

arr1=($list1)
arr2=($list2)
arr3=($list3)
num=${#arr1[*]}

echo starting video $vid_idx of $num

if [ $num -lt $vid_idx ]
then
    echo error: maximal $num videos, get $vid_idx
    exit
else
    vid_idx=$(expr $vid_idx - 1)
    vid1=${arr1[$vid_idx]}
    vid2=${arr2[$vid_idx]}
    vid3=${arr3[$vid_idx]}
    echo loading $vid1
    echo loading $vid2
    echo loading $vid3

    vid1base="${vid1%.*}"
    vid2base="${vid2%.*}"
    vid3base="${vid3%.*}"

    mkdir -p $vid1base $vid2base $vid3base

    roslaunch saveSciencePark.launch vid1:=$vid1 vid2:=$vid2 vid3:=$vid3 path_fisheye1:=$vid1base path_fisheye2:=$vid2base path_kinect:=$vid3base compensate_fisheye1:=$c_fisheye1 compensate_fisheye2:=$c_fisheye2

fi
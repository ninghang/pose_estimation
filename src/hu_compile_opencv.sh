# check argument number
if [ $# -eq 0 ] || [ $# -gt 1 ]
then
  echo "exit: expect one argument"
  exit
fi

# find file extension
file=$1
ext="${file##*.}"

if [ ! -z $ext ]
then
  file="$1.cpp"
fi

# attach extension if missing
ext="${file##*.}"
base="${file%.*}"
if [ "$ext" != "cpp" ]
then
  echo "unable to compile .$ext for now"
  exit
fi

# compile file
echo "compiling $file..."
g++ -o $base $file $(pkg-config --libs --cflags opencv)
if [ $? -gt 0 ]
then
  echo "compile failed"
  exit
else
  echo "compile done"
fi

# run executable
echo "running..."
./$base

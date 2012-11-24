# check argument number
if [ $# -eq 0 ] || [ $# -gt 1 ]
then
  echo "exit: expect one argument"
  exit
fi

# find file extension
filename=$1
base="${filename%.*}"
ext="${filename##*.}"

if [ -n $ext ]
then
  ext="cpp"
fi

# reject if not cpp
if [ "$ext" != "cpp" ]
then
  echo "unable to compile .$ext for now"
  exit
fi

filename=$base.$ext

# compile file
echo "compiling $filename..."
g++ -o $base $filename $(pkg-config --libs --cflags opencv) -lboost_program_options

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
if [ $? -eq 0 ]
then
  echo "running done"
fi

# @echo ffmpeg.exe -f gdigrab -framerate 15 -offset_x 10 -offset_y 20 -i desktop -vcodec libx264 -f flv  %1   >b.log 2>&1
# @ffmpeg.exe -f gdigrab -framerate 15 -offset_x 10 -offset_y 20 -i desktop -vcodec libx264 -f flv  %1   >>b.log 2>&1

if [ -z $root_dir ]; then
  root_dir=$(cd `dirname $0`; pwd)
fi
export LD_LIBRARY_PATH=$root_dir/ffmpeg/lib/
mkdir -p $root_dir/images/
$root_dir/ffmpeg/bin/ffmpeg -f x11grab -framerate 25 -video_size 800*600 -i :0.0 -vcodec libx264 -f flv  $1
$root_dir/ffmpeg/bin/ffmpeg -f x11grab -framerate 25 -video_size 1024x768 -i :0.0 -vcodec libx264 -f flv  $1
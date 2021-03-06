# ffmpeg.exe -f gdigrab -framerate 15 -offset_x 10 -offset_y 20 -i desktop -r 25  -q:v 2 -vframes 200 -y -f image2 images/image-%%d.jpg >a.log 2>&1
# @rem ffmpeg -f dshow -i video="USB2.0 VGA UVC WebCam" -r 1  -q:v 2 -vframes 1 -y -f image2 images/image-1.jpg  >a.log 2>&1
# @rem ffmpeg -t 200 -f vfwcap -i 0 -r 25 -f -y -f image2 images/image-%%d.jpg  >a.log 2>&1

if [ -z $root_dir ]; then
  root_dir=$(cd `dirname $0`; pwd)
fi
export LD_LIBRARY_PATH=$root_dir/ffmpeg/lib/
mkdir -p $root_dir/images/
$root_dir/ffmpeg/bin/ffmpeg  -f v4l2 -r 25 -i /dev/video0 -vframes 200 -s 640x480 -f image2 $root_dir/images/image-%d.jpg
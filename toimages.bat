@rem ffmpeg.exe -f gdigrab -framerate 15 -offset_x 10 -offset_y 20 -i desktop -r 25  -q:v 2 -vframes 1000 -y -f image2 images/image-%%d.jpg >a.log 2>&1
@rem ffmpeg -f dshow -i video="USB2.0 VGA UVC WebCam" -r 1  -q:v 2 -vframes 1 -y -f image2 images/image-1.jpg  >a.log 2>&1
ffmpeg -t 1000 -f vfwcap -i 0 -r 25 -f -y -f image2 images/image-%%d.jpg  >a.log 2>&1
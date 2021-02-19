@rem ffmpeg.exe -f gdigrab -framerate 15 -i desktop -r 25  -q:v 2 -vframes 200 -y -f image2 images/image-%%d.jpg >a.log 2>&1
@rem ffmpeg -f dshow -i video="USB2.0 VGA UVC WebCam" -r 1  -q:v 2 -vframes 1 -y -f image2 images/image-1.jpg  >a.log 2>&1
ffmpeg -f vfwcap -i 0 -r 25 -y -f image2 images/image-%%d.jpg  >a.log 2>&1
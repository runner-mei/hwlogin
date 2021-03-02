@rem ffmpeg.exe -f gdigrab -framerate 15 -i desktop -r 25  -q:v 2 -vframes 200 -y -f image2 images/image-%%d.jpg
@rem ffmpeg -f dshow -i video="USB2.0 VGA UVC WebCam" -r 1  -q:v 2 -vframes 1 -y -f image2 images/image-1.jpg
ffmpeg -f vfwcap -i 0 -r 25 -y -f image2 images/image-%%d.jpg
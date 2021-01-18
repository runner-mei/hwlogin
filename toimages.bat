D:\Desktop\rtsp\ffmpeg\bin\ffmpeg.exe -f gdigrab -framerate 15 -offset_x 10 -offset_y 20 -i desktop -r 1  -q:v 2 -vframes 1 -y -f image2 images/image-%%d.jpg >a.log 2>&1

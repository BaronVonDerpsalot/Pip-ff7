# Lock each frame's coarse colour to the still, keep fine motion. Usage: python3 flow_loop_colourlock.py a.mp4 b.mp4 still.jpg out.ogv
import sys, subprocess, numpy as np
from PIL import Image
a,b,still,out=sys.argv[1:5]; W,H=1920,1080; LW,LH=96,54
def low(img):  # coarse colour field, as float array at full size
    s=Image.fromarray(img).resize((LW,LH),Image.BOX).resize((W,H),Image.BICUBIC)
    return np.asarray(s,np.float32)
S=np.asarray(Image.open(still).convert('RGB').resize((W,H),Image.LANCZOS))
SL=low(S)
dec=subprocess.Popen(['ffmpeg','-v','error','-i',a,'-i',b,'-filter_complex','[0:v][1:v]concat=n=2:v=1:a=0,scale=%d:%d:flags=lanczos[v]'%(W,H),'-map','[v]','-f','rawvideo','-pix_fmt','rgb24','-'],stdout=subprocess.PIPE)
enc=subprocess.Popen(['ffmpeg','-v','error','-y','-f','rawvideo','-pix_fmt','rgb24','-s','%dx%d'%(W,H),'-r','24','-i','-','-an','-c:v','libtheora','-q:v','8',out],stdin=subprocess.PIPE)
n=0
while True:
    buf=dec.stdout.read(W*H*3)
    if len(buf)<W*H*3: break
    f=np.frombuffer(buf,np.uint8).reshape(H,W,3)
    o=np.clip(f.astype(np.float32)+(SL-low(f)),0,255).astype(np.uint8)
    enc.stdin.write(o.tobytes()); n+=1
enc.stdin.close(); enc.wait(); dec.wait(); print('frames',n)

"""Original, deterministic Foley source files for Roblox import. This does not fabricate uploaded asset IDs."""
import math,random,struct,wave
from pathlib import Path
root=Path(__file__).resolve().parents[1]/'assets/audio';root.mkdir(parents=True,exist_ok=True)
rate=44100
def write(name,duration,sample):
    random.seed(47);out=[];filtered=0
    for i in range(int(duration*rate)):
        t=i/rate;noise=random.uniform(-1,1);filtered=.88*filtered+.12*noise
        value=sample(t,duration,noise,filtered)
        out.append(struct.pack('<h',int(max(-1,min(1,value))*.65*32767)))
    with wave.open(str(root/(name+'.wav')),'wb')as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(b''.join(out))
write('door-slide',.72,lambda t,d,n,f:(math.sin(math.pi*t/d)**.7)*(.45*f+.055*math.sin(2*math.pi*(112+20*t)*t)))
write('glass-latch',.23,lambda t,d,n,f:math.exp(-t*32)*(.18*math.sin(2*math.pi*2183*t)+.1*math.sin(2*math.pi*3291*t)+.14*n*math.exp(-t*100)))
write('ceramic-touch',.32,lambda t,d,n,f:math.exp(-t*18)*(.16*math.sin(2*math.pi*1307*t)+.12*math.sin(2*math.pi*2471*t)))
write('coin-clink',.28,lambda t,d,n,f:math.exp(-t*24)*(.2*math.sin(2*math.pi*2890*t)+.09*math.sin(2*math.pi*4231*t)))
write('paper-rustle',.42,lambda t,d,n,f:math.sin(math.pi*t/d)*(.21*n+.2*f)*(.6+.4*math.sin(t*51)**2))
write('receipt-stamp',.16,lambda t,d,n,f:math.exp(-t*47)*(.33*n+.3*math.sin(2*math.pi*113*t)))
print('Generated six original WAV Foley files. Upload them and set Config.Audio IDs to use the originals in Roblox.')

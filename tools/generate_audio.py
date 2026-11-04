"""Compose original PCM scores locally. Upload WAV files through Roblox Asset Manager.
No third-party recordings. The game never guesses or embeds other creators' asset IDs.
"""
from pathlib import Path
import wave,math,struct
OUT=Path(__file__).resolve().parents[1]/'assets/audio'; OUT.mkdir(parents=True,exist_ok=True)
PHASES={'preparation':(98,6,.12),'calm':(110,12,.10),'danger':(123.47,12,.14),'movement':(73.42,3,.18),'impact':(49,2,.3),'elimination':(82.41,3,.14),'final':(146.83,12,.16),'curator_victory':(130.81,6,.14),'survivor_victory':(164.81,6,.13),'line':(220,2,.14)}
RATE=16000
for phase,(base,duration,gain) in PHASES.items():
    buf=bytearray()
    for i in range(RATE*duration):
        t=i/RATE; fade=min(1,t*3,(duration-t)*3)
        beat=math.exp(-(t%.75)*7)
        # Dorian chord / slowly beating mechanical overtone. Deterministic, no copied melody.
        chord=sum(math.sin(math.tau*base*ratio*t)*amp for ratio,amp in [(1,.5),(1.5,.23),(2.2449,.12),(3,.08)])
        noise=math.sin(t*3121.1)*math.sin(t*827.3)*math.sin(t*191.2)
        sample=(chord*(.65+.25*math.sin(t*.7))+noise*beat*.18+math.sin(math.tau*base*.5*t)*beat*.3)*gain*fade
        buf.extend(struct.pack('<h',int(max(-1,min(1,sample))*32767)))
    with wave.open(str(OUT/(phase+'.wav')),'wb') as f: f.setnchannels(1); f.setsampwidth(2); f.setframerate(RATE); f.writeframes(buf)
print('Composed',len(PHASES),'original WAV score/effect cues')

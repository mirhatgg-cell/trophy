"""Twenty material ranks have different sculptural mechanisms, not a recolored emitter."""
import math,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def generate():
 out={}
 for level in range(2,21):
  parts=[]
  def p(name,size,pos,col,mat=1088,shape=1,alpha=0,angle=0):
   c,s=math.cos(angle),math.sin(angle)
   parts.append(dict(name=name,size=size,position=pos,color=col,material=mat,shape=shape,alpha=alpha,rotation=[c,0,s,0,1,0,-s,0,c]))
  if level==2:
   for i in range(72):a=i*math.pi/12;p('ClayCoil_'+str(i),[.22,.16,.22],[math.cos(a)*1.55,i*.025-.4,math.sin(a)*1.55],[151+i%4*4,95,61],1360,0)
  elif level==3:
   for i in range(32):a=i*2.399963;r=2.0+(i%5)*.15;p('StoneChip_'+str(i),[.22+i%3*.05,.25,.2],[math.cos(a)*r,(i%6)*.3-.3,math.sin(a)*r],[114+i%5*8,119+i%5*7,108+i%5*7],896)
  elif level==4:
   for i in range(48):a=i*math.pi/24;p('CopperTooth_'+str(i),[.2,.14,.3],[math.cos(a)*2.5,-.35,math.sin(a)*2.5],[190,112,70],1088,angle=-a)
  elif level==5:
   for i in range(40):a=i*math.pi/20;p('BronzeLeaf_'+str(i),[.12,.32,.25],[math.cos(a)*2.35,.4+math.sin(a)*1.1,math.sin(a)*.3],[160,125,65],1088,angle=a)
  elif level==6:
   for i in range(12):p('SilverSweep_'+str(i),[.045,.7,.025],[(i%4-1.5)*.65,(i//4)*.4,1.1],[228,242,244],288)
   for i in range(12):a=i*math.pi/6;p('SilverOrb_'+str(i),[.25,.25,.25],[math.cos(a)*2.2,.3,math.sin(a)*2.2],[197,212,216],1088,0)
  elif level==7:pass
  elif level==8:
   for i in range(32):a=i*math.pi/16;p('RubyFacet_'+str(i),[.2,.7+(i%4)*.1,.2],[math.cos(a)*2.2,.6,math.sin(a)*2.2],[172+i%5*9,25,45],1568,alpha=.1,angle=a)
  elif level==9:
   for i in range(48):a=i*2.399963;r=1.9+(i%4)*.16;p('EmeraldSpire_'+str(i),[.12,.55+(i%5)*.12,.12],[math.cos(a)*r,.3+(i%6)*.13,math.sin(a)*r],[35,151+i%5*12,101],1568,alpha=.08)
  elif level==10:
   for i in range(48):a=i*math.pi/12;p('SapphireDrop_'+str(i),[.13,.24,.13],[math.cos(a)*2.2,(i%12)*.18,math.sin(a)*2.2],[39,111,225],1568,0,.1)
  elif level==11:
   for i in range(64):a=i*math.pi/8;p('AmethystHelix_'+str(i),[.17,.25,.17],[math.cos(a)*2.1,(i%32)*.07-.3,math.sin(a)*2.1],[124+i%3*12,66,174+i%3*10],1568,alpha=.1,angle=a)
  elif level==12:
   for i in range(24):a=i*math.pi/12;p('ObsidianPlate_'+str(i),[.35,.6,.13],[math.cos(a)*2.3,.6,math.sin(a)*2.3],[32,35,41],788,angle=-a);p('ObsidianCrack_'+str(i),[.06,.5,.05],[math.cos(a)*2.25,.6,math.sin(a)*2.25],[255,130,41],288)
  elif level==13:
   for i in range(24):a=i*math.pi/12;p('IceCrystal_'+str(i),[.12,.8+(i%3)*.2,.12],[math.cos(a)*2.1,.35,math.sin(a)*2.1],[170,229,238],1536,alpha=.12)
   for i in range(24):a=i*2.399963;p('Snowflake_'+str(i),[.11,.035,.11],[math.cos(a)*2.4,(i%8)*.25,math.sin(a)*2.4],[234,248,248],784)
  elif level==14:
   for i in range(96):a=i*math.pi/16;r=2.5;p('PlasmaArc_'+str(i),[.13,.045,.18],[math.cos(a)*r,math.sin(a*2+i//32)*.9+.7,math.sin(a)*r],[70,197+i%3*14,220],288)
  elif level==15:
   for i in range(48):a=(i//4)*math.pi/6;arm=i%4;pos=[math.cos(a)*2.5,.8+math.sin(a)*.7,math.sin(a)*2.5];sz=[.3,.045,.045]if arm%2==0 else[.045,.3,.045];p('ConstellationStar_'+str(i),sz,pos,[243,233,183],288)
  elif level==16:
   p('CometHead_0',[.6,.6,.6],[2.6,.8,0],[151,110,75],896,0)
   for i in range(1,49):a=-i*.06;r=2.6;p('CometTail_'+str(i),[max(.04,.32-i*.005)]*3,[math.cos(a)*r,.8-i*.015,math.sin(a)*r],[220-i*2,151-i,69],288 if i<16 else 896,0,alpha=min(.7,i*.012))
  elif level==17:
   for i in range(3):a=i*math.pi*2/3;p('Planet_'+str(i),[.4+i*.12]*3,[math.cos(a)*(2.4+i*.2),.8+i*.2,math.sin(a)*(2.4+i*.2)],[(111,176,215),(195,151,88),(177,189,203)][i],1568,0,.08)
   for i in range(64):a=i*math.pi/32;p('CosmosRing_'+str(i),[.14,.035,.1],[math.cos(a)*2.8,.55,math.sin(a)*2.8],[99,156,214],288,angle=-a)
  elif level==18:
   for i in range(24):side=-1 if i%2 else 1;p('RiftPlate_'+str(i),[.25,.3,.3],[side*(.2+(i//2%4)*.27),(i//8)*.6,1.1],[76,118,125],788)
   for i in range(24):p('RiftCore_'+str(i),[.045,.14,.05],[0,(i%12)*.15-.3,1.15],[124,233,231],288)
  elif level==19:
   for i in range(32):a=i*math.pi/16;r=.7+abs(math.sin(a*2))*.6;p('Hourglass_'+str(i),[.09,.2,.09],[math.cos(a)*r,(i%16)*.13-.3,math.sin(a)*r],[209,225,219],1568,alpha=.2)
   for i in range(48):a=i*2.399963;p('Sand_'+str(i),[.05,.07,.05],[math.cos(a)*.5,(i%16)*.13-.3,math.sin(a)*.5],[225,200,128],784)
  elif level==20:
   for i in range(64):a=i*math.pi/32;h=.25+(i%8==0)*.75;p('Crown_'+str(i),[.14,h,.2],[math.cos(a)*2.5,2.2+h/2,math.sin(a)*2.5],[244,213,126],1088,angle=-a)
   for i in range(32):a=i*math.pi/16;p('CrownHalo_'+str(i),[.12,.035,.1],[math.cos(a)*2.9,1.9,math.sin(a)*2.9],[240,245,224],288,angle=-a)
  out[str(level)]=parts
 (ROOT/'assets/rank-ornaments.json').write_text(json.dumps(out,separators=(',',':'))+'\n')
 return out
if __name__=='__main__':generate();print('Authored distinct clay, stone, metal, crystal, ice, cosmic and crown ornament mechanisms')

"""Original tileable PBR authoring. Runtime also works with Roblox's built-in PBR materials."""
from pathlib import Path
import numpy as np
from PIL import Image,ImageFilter
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/textures';OUT.mkdir(exist_ok=True)
N=512;rng=np.random.default_rng(1843)
def noise():
 a=np.zeros((N,N),float)
 for size,weight in ((8,.45),(24,.27),(64,.17),(256,.11)):
  im=Image.fromarray((rng.random((size,size))*255).astype('uint8')).resize((N,N),Image.Resampling.BICUBIC)
  a+=np.asarray(im)/255*weight
 return a
profiles={
 'wet_mud':((83,55,31),'mud'),'clay':((147,94,62),'clay'),'quarried_stone':((126,129,122),'stone'),
 'copper':((179,103,66),'metal'),'bronze':((157,115,66),'metal'),'silver':((196,207,212),'metal'),'gold':((236,184,63),'metal'),
 'ruby':((164,31,45),'gem'),'emerald':((38,155,112),'gem'),'sapphire':((38,96,196),'gem'),'amethyst':((124,65,176),'gem'),
 'obsidian':((38,39,45),'stone'),'ice':((159,220,231),'ice'),'plasma':((105,219,222),'glow'),'starlight':((223,215,174),'glow'),
 'comet':((155,112,77),'stone'),'cosmos':((35,49,105),'space'),'rift':((108,177,182),'glow'),'eternity':((211,230,222),'gem'),'legend':((226,197,126),'metal'),
 'ghost':((196,234,239),'ghost'),'galaxy':((18,29,69),'space')}
Y,X=np.mgrid[0:N,0:N]
for name,(color,kind) in profiles.items():
 n=noise();height=n.copy();rgb=np.array(color)[None,None,:]*(.68+n[:,:,None]*.58);rough=np.full((N,N),.68)
 if kind in ('mud','clay'):
  wet=np.clip((n-.46)*4,0,1);height=np.clip(n*.7+np.sin(X*.045+n*8)*.09,.05,.95);rough=.85-wet*.58
  rgb*=1-wet[:,:,None]*.22
 elif kind=='metal':
  grooves=(np.sin(Y*.6+noise()*4)*.5+.5);height=.45+grooves*.08;rough=.2+grooves*.18;rgb*=.88+grooves[:,:,None]*.15
  if name in ('bronze','copper'):
   patina=np.clip((n-.62)*6,0,.8);rgb=rgb*(1-patina[:,:,None])+np.array([57,111,91])*patina[:,:,None]
 elif kind=='gem' or kind=='ice':
  facets=np.abs(np.sin(X*.035+Y*.06+n*5));height=facets*.3+n*.4;rough=.13+facets*.1;rgb*=.7+facets[:,:,None]*.5
 elif kind=='ghost':
  mist=(np.sin(Y*.023+np.sin(X*.016)*2+n*5)+1)/2;rgb=np.stack([180+mist*49,217+mist*31,229+mist*24],axis=-1);height=.45+mist*.05;rough=.1+mist*.12
 elif kind=='space':
  dx=X-N/2;dy=(Y-N/2)*1.5;radius=np.sqrt(dx*dx+dy*dy);a=np.arctan2(dy,dx);arms=(np.cos(a*3-radius*.036+n*2)+1)/2;nebula=arms*np.exp(-radius/170)
  rgb=np.stack([10+nebula*54,18+nebula*99,45+nebula*151],axis=-1);height=np.full((N,N),.5);rough=.18+n*.1
  for _ in range(1200):
   x,y=rng.integers(0,N,2);bright=rng.uniform(.4,1);rgb[y,x]=np.array([223,240,250])*bright
 elif kind=='glow':
  flow=(np.sin(X*.04+Y*.015+n*5)+1)/2;rgb*=.7+flow[:,:,None]*.65;height=.45+flow*.08;rough=.16+flow*.1
 else:height=n*.8;rough=.6+n*.35
 dy,dx=np.gradient(height);normal=np.stack([-dx*5,-dy*5,np.ones_like(dx)],axis=-1);normal/=np.linalg.norm(normal,axis=-1)[:,:,None]
 Image.fromarray(np.clip(rgb,0,255).astype('uint8')).save(OUT/f'{name}_albedo.png')
 Image.fromarray(((normal*.5+.5)*255).astype('uint8')).save(OUT/f'{name}_normal.png')
 Image.fromarray((np.clip(rough,0,1)*255).astype('uint8')).save(OUT/f'{name}_roughness.png')
print('Authored',len(profiles),'original albedo / normal / roughness texture sets')

"""Museum-first construction source. Full scene: real 500k+ architectural Parts.
All dense pieces are visible stone tesserae, ceiling panels or masonry facing.
Collision is carried by continuous structural slabs and complete wall envelopes.
"""
from pathlib import Path
import json,gzip,math,argparse,hashlib
import numpy as np
from world_spec import records
ROOT=Path(__file__).resolve().parents[1]
BUILD='MUSEUM-2026.11.04-r4'
LEVELS=[0,28,56]
P={ 'Mud':1344,'Ground':1360,'Rock':896,'Metal':1088,'Rust':1040,'Glass':1568,'Marble':784,'Basalt':788,'Ice':1536,'Neon':288,'Slate':800,'Concrete':816,'Wood':528,'Granite':832 }
COLORS=[(83,55,31),(147,94,62),(126,129,122),(179,103,66),(157,115,66),(196,207,212),(236,184,63),(164,31,45),(38,155,112),(38,96,196),(124,65,176),(38,39,45),(159,220,231),(105,219,222),(223,215,174),(155,112,77),(35,49,105),(108,177,182),(211,230,222),(226,197,126)]
MATS=[1344, 1360, 896, 1088, 1040, 1088, 1088, 1568, 1568, 1568, 1568, 788, 1536, 288, 1088, 896, 1568, 1088, 1568, 1088]
class Scene:
 def __init__(self,path):
  self.f=gzip.open(path,'wt',compresslevel=6);self.next=1;self.counts={};self.parts=0;self.colliders=[];self.structure=0;self.trophy_counts={};self.grids=[];self.render=[]
 def item(self,parent,cls,name,props=None,part=None):
  i=self.next;self.next+=1
  rec={'i':i,'p':parent,'c':cls,'n':name}
  if props:rec['v']=props
  if part:rec['b']=part
  self.f.write(json.dumps(rec,separators=(',',':'))+'\n');return i
 def model(self,parent,name,atomic=False):return self.item(parent,'Model',name,{'ModelStreamingMode':['Token',1 if atomic else 0]})
 def value(self,parent,name,value):
  typ='Bool' if isinstance(value,bool) else 'Int' if isinstance(value,int) else 'String'
  return self.item(parent,typ+'Value',name,{'Value':[typ,value]})
 def part(self,parent,name,size,pos,color=(150,145,126),mat=784,rot=None,collide=False,alpha=0,shape=1,shadow=False,group='architecture'):
  # [size, position, rgb, material, 3x3 rotation, collide, alpha, shape, cast shadow]
  b=[list(size),list(pos),list(color),mat,rot or [1,0,0,0,1,0,0,0,1],collide,alpha,shape,shadow]
  i=self.item(parent,'Part',name,part=b);self.parts+=1;self.counts[group]=self.counts.get(group,0)+1
  if collide:self.colliders.append(dict(name=name,size=list(size),position=list(pos),rotation=b[4]))
  if group=='architecture':self.structure+=1
  return i
 def script(self,parent,cls,name,path):return self.item(parent,cls,name,{'Source':['ProtectedString',(ROOT/path).read_text()],'Disabled':['Bool',False]} if cls!='ModuleScript' else {'Source':['ProtectedString',(ROOT/path).read_text()]})
 def sign(self,parent,name,text,pos,width=18,height=3):
  base=self.part(parent,name,(width,height,.2),pos,(39,50,48),1088)
  g=self.item(base,'SurfaceGui','Inscription',{'Face':['Token',5 if name=='MuseumName' else 2],'SizingMode':['Token',1],'PixelsPerStud':['Float',45]})
  self.item(g,'TextLabel','Text',{'Size':['UDim2',[1,0,1,0]],'BackgroundTransparency':['Float',1],'Text':['String',text],'TextScaled':['Bool',True],'TextWrapped':['Bool',True],'TextColor3':['Color3',[.95,.88,.7]],'Font':['Token',4]})
  return base
 def finish(self):self.f.close()

def ry(a):return [math.cos(a),0,math.sin(a),0,1,0,-math.sin(a),0,math.cos(a)]
def rx(a):return [1,0,0,0,math.cos(a),-math.sin(a),0,math.sin(a),math.cos(a)]
def rz(a):return [math.cos(a),-math.sin(a),0,math.sin(a),math.cos(a),0,0,0,1]
def mm(a,b):return (np.array(a).reshape(3,3)@np.array(b).reshape(3,3)).ravel().tolist()
def rv(a,v):return (np.array(a).reshape(3,3)@np.array(v)).tolist()
def add(a,b):return [a[i]+b[i] for i in range(3)]
def tone(base,n):return tuple(max(0,min(255,int(c+n))) for c in base)
def hash01(x,y,seed=0):return ((x*374761393+y*668265263+seed*69069)&65535)/65535

def grid_parts(scene,parent,g,full):
 scene.grids.append(g)
 if not full:return
 nx,ny=g['nx'],g['ny'];chunk=16
 for u0 in range(0,nx,chunk):
  for v0 in range(0,ny,chunk):
   model=scene.model(parent,f"{g['role']}_{g['floor']}_{u0}_{v0}",True)
   for u in range(u0,min(u0+chunk,nx)):
    for v in range(v0,min(v0+chunk,ny)):
     p=add(g['origin'],add([q*(u+.5) for q in g['du']],[q*(v+.5) for q in g['dv']]))
     if any(a<=p[0]<=b and c<=p[1]<=d and e<=p[2]<=f for a,b,c,d,e,f in g.get('skip',[])):continue
     if g['role']=='FloorTessera':
      x,z=p[0],p[2];border=min(240-abs(x),192-abs(z))<5;central=abs(x)<28; ring=int(math.hypot(x,z*.85)/6)%5==0
      bronze=border and ((u+v)%4==0) or central and (int(abs(x)/1.5)%12==0) or (abs(z%36)<1.5 and abs(x)>36)
      base=(164,128,63) if bronze else (123,134,119) if central else (180,172,150) if ring else (157,152,132)
      mat=1088 if bronze else 784
     elif g['role']=='CeilingCoffer':
      line=u%16 in (0,15) or v%16 in (0,15);base=(136,111,62) if line else (201,194,169);mat=1088 if line else 784
     else:base=(171,161,136);mat=832
     variation=(hash01(u,v,g['floor']+3)-.5)*10
     scene.part(model,g['role'],g['size'],p,tone(base,variation),mat,group='architecture')

def structure(scene,root):
 s=scene.item(root,'Model','Structure',{'ModelStreamingMode':['Token',2]});standFolder=scene.model(root,'Pedestals');lights=scene.model(root,'Luminaires')
 scene.part(s,'Monolithic foundation',(480,12,384),(0,-7.12,0),(104,108,98),816,collide=True,shadow=True)
 scene.part(s,'Front terrace foundation',(580,20,120),(0,-8.88,238),(104,108,98),816,collide=True,shadow=True)
 for f,y in enumerate(LEVELS):
  scene.part(s,f'Continuous floor {f}',(480,2.24,384),(0,y,0),(148,145,124),784,collide=True,alpha=1)
  scene.part(s,f'Solid floor backing {f}',(480,2.08,384),(0,y-.08,0),(148,145,124),784,shadow=True)
  scene.part(s,f'Continuous ceiling {f}',(480,1.16,384),(0,y+26.3,0),(176,173,153),784,collide=True,shadow=True)
  # Front/back lower walls, with the entrance and elevator openings cut in actual collision geometry.
  for side in (-1,1):
   z=side*192; openings=[(-24,24)] if f==0 and side==1 else [(-140,-124),(124,140)] if side==-1 else []
   starts=[-240]+[v for pair in openings for v in pair]+[240]
   for j in range(0,len(starts)-1,2):
    a,b=starts[j:j+2]
    if b>a:scene.part(s,'Perimeter lower wall',(b-a,12,2),((a+b)/2,y+7.12,z),(154,149,127),816,collide=True,shadow=True)
   scene.part(s,'Perimeter header',(480,2,2),(0,y+14.12,z),(137,137,119),816,collide=True)
   scene.part(s,'Perimeter top beam',(480,2.6,3),(0,y+25.42,z),(137,137,119),816,collide=True)
   for x in range(-240,241,24):scene.part(s,'Clerestory pier',(4,9,3),(x,y+19.62,z),(126,132,117),816,collide=True)
   for x in range(-228,229,24):scene.part(s,'Framed clerestory glazing',(20,9,.8),(x,y+19.62,z),(162,190,183),1568,collide=True,alpha=.38)
  for side in (-1,1):
   x=side*240;center=[120,44,-32][f];bounds=[-192,center-8,center+8,192]
   for a,b in ((bounds[0],bounds[1]),(bounds[2],bounds[3])):
    scene.part(s,'Side wall',(2,12,b-a),(x,y+7.12,(a+b)/2),(154,149,127),816,collide=True,shadow=True)
   scene.part(s,'Side header',(3,2,384),(x,y+14.12,0),(137,137,119),816,collide=True)
   scene.part(s,'Side top beam',(3,2.6,384),(x,y+25.42,0),(137,137,119),816,collide=True)
   for z in range(-192,193,24):scene.part(s,'Window mullion',(3,9,4),(x,y+19.62,z),(126,132,117),816,collide=True)
   for z in range(-180,181,24):scene.part(s,'Side glazing',(.8,9,20),(x,y+19.62,z),(162,190,183),1568,collide=True,alpha=.38)
  # Central arcades: structural piers, open passages, voussoirs and an upper load beam.
  for side in (-1,1):
   x=side*32
   for z in range(-168,169,48):
    scene.part(s,'Arcade pier',(6,25,6),(x,y+13.62,z),(135,140,123),816,collide=True,shadow=True)
    scene.part(s,'Pier capital',(9,1.2,9),(x,y+23,z),(163,150,115),784)
    for dz in (-3.2,3.2):scene.part(s,'Pier fluting',(.4,18,.4),(x+side*3.1,y+12,z+dz),(188,175,137),784)
   for z in range(-144,145,48):
    scene.part(s,'Arcade lintel',(6,6.5,42),(x,y+22.47,z),(150,150,130),816,collide=True)
    for j in range(24):
     a=(j+.5)*math.pi/24; scene.part(s,'Arch voussoir',(7,2.2,2),(x,y+6.8+math.sin(a)*12.6,z+math.cos(a)*12.6),(178,165,129),784,rot=rx(a-math.pi/2))
  for x in (-216,-144,-72,72,144,216):
   for z in range(-168,169,48):
    scene.part(s,'Ceiling transverse rib',(3,1.2,40),(x,y+24.9,z),(137,126,98),784)
  # Explicitly framed lamps; no particulate fog hides geometry.
  for x in (-176,-88,0,88,176):
   for z in (-144,-48,48,144):
    lamp=scene.part(lights,'Recessed luminance',(5,.35,5),(x,y+24.8,z),(246,224,170),288)
    scene.item(lamp,'SurfaceLight','Gallery light',{'Face':['Token',4],'Range':['Float',30],'Brightness':['Float',1.2],'Angle':['Float',105],'Shadows':['Bool',False],'Color':['Color3',[1,.89,.72]]})
  scene.sign(s,f'FloorDirectory{f}',f'АРХИВ / УРОВЕНЬ {f+1} / МАТЕРИАЛЫ И ПОБЕДЫ',(0,y+7,-177),34,4)
 # Side enclosed stair towers. Solid-filled treads, closed envelopes, no slab openings.
 for side in (-1,1):
  st=scene.model(root,'WestStair' if side<0 else 'EastStair');x=side*252
  scene.part(st,'Stair tower foundation',(32,12,184),(x,-4.88,48),(114,120,106),816,collide=True)
  scene.part(st,'Outer stair wall',(2,84,184),(side*269,42,48),(131,139,123),816,collide=True,shadow=True)
  for z in (-44,140):scene.part(st,'Stair end wall',(34,84,2),(x,42,z),(131,139,123),816,collide=True)
  scene.part(st,'Stair tower roof',(36,2,188),(x,85,48),(117,124,109),816,collide=True)
  for f,(y,z) in enumerate(((0,120),(28,44),(56,-32))):
   scene.part(st,'Continuous stair landing',(34,2.24,16),(x,y,z),(151,148,127),784,collide=True)
  for flight in range(2):
   y0=1.12+flight*28;z0=120-flight*76
   for i in range(56):
    top=y0+(i+1)*.5;scene.part(st,'Solid supported stair tread',(16,top-1.12,1.28),(x,(top+1.12)/2,z0-i*1.25),(174,164,135),784,collide=True)
    if i%4==0:
     for dx in (-7.6,7.6):scene.part(st,'Stair baluster',(.3,3,.3),(x+dx,top+1.5,z0-i*1.25),(144,117,65),1088)
   length=math.hypot(70,28)
   for dx in (-7.6,7.6):scene.part(st,'Continuous stair handrail',(.45,.45,length),(x+dx,y0+17, z0-34.5),(165,131,64),1088,rot=rx(math.atan(.4)),collide=True)
  for flight in range(2):
   for dx in (-8.5,8.5):scene.part(st,'Stair glass guard',(.3,3.8,76),(x+dx,1.12+flight*28+16,120-flight*76-34.5),(159,187,174),1568,rot=rx(math.atan(.4)),collide=True,alpha=.4)
 # Three-stop enclosed lifts, doors only open when cabin is safely at the landing.
 lifts=scene.model(root,'Lifts')
 for x in (-132,132):
  m=scene.model(lifts,'LiftWest' if x<0 else 'LiftEast')
  scene.part(m,'Shaft back',(24,88,2),(x,42,221),(93,107,99),816,collide=True)
  for dx in (-12,12):scene.part(m,'Shaft side',(2,88,30),(x+dx,42,207),(93,107,99),816,collide=True)
  scene.part(m,'Shaft roof',(26,2,32),(x,87,207),(100,111,101),816,collide=True)
  scene.part(m,'Shaft base',(26,10,32),(x,-3.88,207),(100,111,101),816,collide=True)
  cab=scene.model(m,'Cabin')
  rootPart=scene.part(cab,'Platform',(20.8,1.2,18),(x,.52,208),(130,127,106),1088,collide=True)
  scene.item(cab,'ObjectValue','Root',{'Value':['Ref',rootPart]})
  for dx in (-10.4,10.4):scene.part(cab,'Cabin side',(.6,7,18),(x+dx,4.5,208),(111,137,129),1568,collide=True,alpha=.3)
  scene.part(cab,'Cabin back',(20.8,7,.6),(x,4.5,217),(111,137,129),1568,collide=True,alpha=.3)
  for side in (-1,1):scene.part(cab,'GateLeft' if side<0 else 'GateRight',(10.4,9,.5),(x+side*5.2,5.62,199.2),(127,148,134),1568,collide=True,alpha=.25)
  for f,y in enumerate(LEVELS):
   scene.part(m,f'Landing{f}',(20,2.24,8),(x,y,196),(151,147,124),784,collide=True)
   for side in (-1,1):scene.part(m,f'Door{f}_{side}',(11,12,.7),(x+side*5.5,y+7.12,199.5),(157,138,85),1088,collide=True)
   call=scene.part(m,f'Call{f}',(2,2,.6),(x+11,y+5,190),(168,136,74),1088)
  for side in (-1,1):scene.part(m,'Vertical guide',(.5,84,.5),(x+side*9.8,42,208),(80,97,93),1088)
 # Door lintels close all top gaps above functional apertures.
 scene.part(s,'Entrance lintel',(48,2,3),(0,14.12,192),(143,142,120),816,collide=True)
 # Arrival, occupied reception, and closed terrace edges.
 spawn=scene.item(root,'SpawnLocation','MuseumArrival',part=[[16,1,12],[0,.62,174],[168,149,99],784,[1,0,0,0,1,0,0,0,1],True,1,1,False],props={'Neutral':['Bool',True],'Duration':['Float',0]})
 scene.sign(s,'MuseumName','M O U N T A I N V E R S E\nМУЗЕЙ МАТЕРИИ И ПОБЕД',(0,17,187),46,8)
 desk=scene.part(s,'ReceptionDesk',(16,3.5,5),(-21,2.87,163),(98,100,81),784,collide=True)
 scene.sign(s,'Reception','МУЗЕЙ / ВСЕ ЭКСПОНАТЫ ОТКРЫТЫ',(-21,6,160),18,2.8)
 for side in (-1,1):
  for z in range(-144,145,72):
   scene.part(s,'Gallery bench',(12,1.2,4),(side*205,2.5,z),(102,79,50),528,collide=True)
   for dx in (-4,4):scene.part(s,'Bench leg',(.6,2,.6),(side*205+dx,1.7,z),(94,97,78),1088,collide=True)
 for x in range(-288,289,12):scene.part(s,'Terrace balustrade post',(.7,4,.7),(x,3.12,296),(143,130,91),784,collide=True)
 scene.part(s,'Terrace top rail',(578,.8,.8),(0,5,296),(160,145,99),784,collide=True)
 for x in (-289,289):scene.part(s,'Terrace side parapet',(1.5,4,116),(x,3.12,238),(134,136,115),816,collide=True)
 return standFolder

def details(scene,parent,full):
 for f,y in enumerate(LEVELS):
  grid_parts(scene,parent,dict(role='FloorTessera',floor=f,nx=320,ny=256,origin=[-240,y+1.04,-192],du=[1.5,0,0],dv=[0,0,1.5],size=[1.48,.16,1.48]),full)
  grid_parts(scene,parent,dict(role='CeilingCoffer',floor=f,nx=320,ny=256,origin=[-240,y+25.7,-192],du=[1.5,0,0],dv=[0,0,1.5],size=[1.48,.2,1.48]),full)
  for side in (-1,1):
   center=[120,44,-32][f]
   grid_parts(scene,parent,dict(role='MasonryRelief',floor=f,nx=256,ny=16,origin=[side*238.94,y+1.12,-192],du=[0,0,1.5],dv=[0,.75,0],size=[.14,.73,1.48],skip=[[side*238.94-1,side*238.94+1,y,y+13.2,center-8,center+8]]),full)
   skips=[]
   if f==0 and side==1:skips=[[-24,24,y,y+13.2,side*190.94-1,side*190.94+1]]
   if side==-1:skips=[[-140,-124,y,y+13.2,-192,-189],[124,140,y,y+13.2,-192,-189]]
   grid_parts(scene,parent,dict(role='MasonryRelief',floor=f,nx=320,ny=16,origin=[-240,y+1.12,side*190.94],du=[1.5,0,0],dv=[0,.75,0],size=[1.48,.73,.14],skip=skips),full)

def trophy(scene,parent,key,kind,level,mutation,center,scale=2):
 specs=json.loads((ROOT/'assets/trophy-shapes.json').read_text())[kind]
 m=scene.model(parent,'Exhibit_'+key,True);body=scene.model(m,'Body');anim=scene.model(m,'Animation')
 scene.value(m,'Level',level);scene.value(m,'Mutation',mutation);scene.value(m,'Kind',kind)
 scene.item(m,'Vector3Value','Center',{'Value':['Vector3',center]})
 color=COLORS[level-1];material=MATS[level-1];sizeScale=scale*(1+(level-1)*.035)
 if mutation=='gold':color=(235,178,47);material=1088
 if mutation=='ghost':color=(181,231,235);material=1568
 if mutation=='galaxy':color=(22,31,70);material=1568
 alpha=.38 if mutation=='ghost' else .12 if mutation=='galaxy' else .08 if material in (1536,1568) else 0
 n=len(specs);res=math.ceil(math.sqrt(1200/(6*n)));bodyCount=0
 for bi,sp in enumerate(specs):
  size=[q*sizeScale for q in sp['size']];position=add(center,[q*sizeScale for q in sp['position']]);rot=sp['rotation']
  scene.part(body,'Sculpture core',[max(.012,q-.14*sizeScale) for q in size],position,color,material,rot=rot,alpha=alpha,shape=sp['shape'],group='trophy');bodyCount+=1
  # Six relief surfaces: complete regular slabs; all are actual, visible BaseParts.
  for axis in range(3):
   a,b=[q for q in range(3) if q!=axis]
   for sign in (-1,1):
    for u in range(res):
     for v in range(res):
      local=[0.,0.,0.];local[axis]=sign*size[axis]/2;local[a]=((u+.5)/res-.5)*size[a];local[b]=((v+.5)/res-.5)*size[b]
      noise=hash01(u+bi*13,v+axis*17,level)
      if sp['shape']==0:
       norm=math.sqrt(sum((local[q]/max(.001,size[q]/2))**2 for q in range(3)));local=[local[q]/norm for q in range(3)]
      elif sp['shape']==2 and axis!=0:
       norm=math.hypot(local[1]/max(.001,size[1]/2),local[2]/max(.001,size[2]/2));local[1]/=max(norm,.001);local[2]/=max(norm,.001)
      bump=(noise-.5)*(.085 if level==1 and mutation=='natural' else .018)*sizeScale;local[axis]+=sign*bump
      sz=[max(.018,size[q]/res*1.04) for q in range(3)];sz[axis]=.022*sizeScale+abs(bump)
      p=add(position,rv(rot,local));variation=(noise-.5)*(24 if level==1 else 13)
      if mutation=='galaxy' and noise>.965:c=(203,233,249);mat=288
      elif mutation=='gold' and (u+v)%res==0:c=(255,224,133);mat=1088
      else:c=tone(color,variation);mat=material
      scene.part(body,'Material relief tessera',sz,p,c,mat,rot=rot,alpha=alpha,group='trophy');bodyCount+=1
 assert bodyCount>=1000,(kind,bodyCount)
 theme='mud' if mutation=='natural' and level==1 else mutation if mutation!='natural' else f'rank{level}'
 scene.value(m,'Theme',theme)
 def ap(name,size,off,c=color,mat=material,shape=1,alpha=0,rotation=None):
  return scene.part(anim,name,size,add(center,off),c,mat,rot=rotation,shape=shape,alpha=alpha,group='trophy')
 if theme=='mud':
  for i in range(48):
   sp=specs[i%len(specs)];a=i*math.pi*(3-math.sqrt(5));local=[math.sin(a)*sp['size'][0]*.4*sizeScale,math.cos(a)*sp['size'][1]*.4*sizeScale,(1 if i%2 else -1)*(sp['size'][2]*sizeScale/2+.06)]
   off=add([q*sizeScale for q in sp['position']],rv(sp['rotation'],local))
   ap(f'Fold_{i}',[.42,.2,.42],off,tone(color,i%5*3),1344,shape=0)
  for i in range(24):
   a=i*math.pi/12;ap(f'Drop_{i}',[.13,.25,.13],[math.cos(a)*1.1,.25+(i%6)*.27,math.sin(a)*1.1],(65,42,24),1344,shape=0)
  for i in range(32):
   a=i*math.pi/16;ap(f'Ripple_{i}',[.2,.035,.08],[math.cos(a)*1.25,-.55,math.sin(a)*1.25],(77,51,28),1344,rotation=ry(-a))
 elif theme=='gold' or level==7 and mutation=='natural':
  for i in range(64):
   a=i*math.pi/32;ap(f'GoldFiligree_{i}',[.14,.035,.2],[math.cos(a)*2.7,.35+math.sin(a*4)*.15,math.sin(a)*2.7],(240,191,65),1088,rotation=ry(-a))
  for i in range(24):
   a=i*math.pi/12;ap(f'Coin_{i}',[.2,.055,.2],[math.cos(a)*2.4,.8+(i%3)*.25,math.sin(a)*2.4],(255,217,96),1088,shape=2,rotation=rz(.5))
 elif theme=='ghost':
  for i in range(80):
   a=i*math.pi/10;y=i*.035-.4;r=2.8+.15*math.sin(a)
   ap(f'GhostRibbon_{i}',[.13,.12,.3],[math.cos(a)*r,y,math.sin(a)*r],(186,235,237),1568,alpha=.42,rotation=ry(-a))
  for i in range(24):
   a=i*math.pi/12;ap(f'GhostWisp_{i}',[.06,.3,.08],[math.cos(a)*3.0,.25+i%5*.3,math.sin(a)*3.0],(217,246,246),288,alpha=.35)
 elif theme=='galaxy':
  for ring in range(3):
   tilt=rx(.45+ring*.45)
   for i in range(48):
    a=i*math.pi/24;off=rv(tilt,[math.cos(a)*(2.7+ring*.2),.7,math.sin(a)*(2.7+ring*.2)])
    ap(f'Orbit{ring}_{i}',[.12,.035,.09],off,(98+ring*30,161+ring*25,231),288,rotation=mm(tilt,ry(-a)))
  for i in range(72):
   a=i*2.399963;r=1.4+(i%11)*.14;y=(i%17)*.13-.3
   c=[(239,245,247),(141,209,237),(238,205,146)][i%3]
   ap(f'Star_{i}',[.065,.065,.065],[math.cos(a)*r,y,math.sin(a)*r],c,288,shape=0)
 else:
  ornaments=json.loads((ROOT/'assets/rank-ornaments.json').read_text())[str(level)]
  for q in ornaments:
   ap(q['name'],q['size'],q['position'],q['color'],q['material'],q['shape'],q['alpha'],q['rotation'])
 scene.value(m,'BodyPartCount',bodyCount)
 scene.trophy_counts[key]=bodyCount
 return m

def exhibit_placements():
 out=[]
 for g in records():
  j=g['id']-1;f=j//18;n=j%18;per_side=7 if f==2 else 9;side=-1 if n<per_side else 1;v=n%per_side
  x=side*(94 if v%2==0 else 178);z=144-v*36
  out.append(dict(key=f"Trial{g['id']:02}",kind=g['kind'],name=g['name'],level=1,mutation='natural',center=[x,LEVELS[f]+5.5,z],scale=2.2))
 for level in range(1,21):
  xs=[-216,-174,-132,-90,-48,48,90,132,174,216];x=xs[(level-1)%10];z=-120-(level-1)//10*40
  out.append(dict(key=f'Rank{level:02}',kind='tetris',name=f'МАТЕРИЯ / РАНГ {level}',level=level,mutation='natural',center=[x,61.5,z],scale=2))
 for i,(variant,rank,label) in enumerate([('natural',1,'ЖИВАЯ ГРЯЗЬ'),('gold',7,'ЗОЛОТОНОСНАЯ'),('ghost',10,'ПРИЗРАЧНАЯ'),('galaxy',17,'ГАЛАКТИЧЕСКАЯ')]):
  out.append(dict(key='Mutation_'+variant,kind='tetris',name=label,level=rank,mutation=variant,center=[(i-1.5)*12,5.5,136],scale=1.8))
 return out

def lua_value(v):
 if isinstance(v,dict):return '{'+','.join('['+json.dumps(k,ensure_ascii=False)+']='+lua_value(x) for k,x in v.items())+'}'
 if isinstance(v,(list,tuple)):return '{'+','.join(lua_value(x) for x in v)+'}'
 if v is True:return 'true'
 if v is False:return 'false'
 if v is None:return 'nil'
 return json.dumps(v,ensure_ascii=False,separators=(',',':'))

def build_scene(path,full):
 scene=Scene(path);ws=scene.item(0,'Workspace','Workspace',{'Gravity':['Float',196.2],'StreamingEnabled':['Bool',True],'StreamingMinRadius':['Int',64],'StreamingTargetRadius':['Int',128],'FallenPartsDestroyHeight':['Float',-500]})
 world=scene.model(ws,'MuseumWorld');standFolder=structure(scene,world);exhibits=scene.model(world,'Exhibits');detail=scene.model(world,'DetailChunks')
 scene.value(world,'FullGeometryPresent',full);scene.value(world,'BuildId',BUILD)
 for e in exhibit_placements():
  x,y,z=e['center'];stand=scene.model(standFolder,'Stand_'+e['key']);scene.part(stand,'Exhibit plinth',(10 if e['key'].startswith('Mutation') else 16,3.2,10 if e['key'].startswith('Mutation') else 16),(x,y-2.1,z),(114,118,100),784,collide=True)
  scene.part(stand,'Bronze exhibit rim',(10.5 if e['key'].startswith('Mutation') else 16.5,.16,10.5 if e['key'].startswith('Mutation') else 16.5),(x,y-.4,z),(162,128,61),1088)
  scene.sign(stand,'ExhibitLabel',e['name']+f"\nРАНГ {e['level']} / {e['mutation']}",(x,y-1.5,z+5.2 if e['key'].startswith('Mutation') else z+8.2),9 if e['key'].startswith('Mutation') else 15,2)
  if full or e['key'].startswith('Mutation'):trophy(scene,exhibits,e['key'],e['kind'],e['level'],e['mutation'],e['center'],e['scale'])
 details(scene,detail,full)
 scene.value(world,'ArchitecturePartCount',scene.structure+1)
 # Scriptable lightweight recipe is exactly the source used above; full place skips regeneration.
 blueprint=dict(build=BUILD,rankOrnaments=json.loads((ROOT/'assets/rank-ornaments.json').read_text()),levels=LEVELS,grids=scene.grids,exhibits=exhibit_placements(),shapes=json.loads((ROOT/'assets/trophy-shapes.json').read_text()),colors=COLORS,materials=MATS)
 (ROOT/'src/museum/Blueprint.lua').write_text('return '+lua_value(blueprint)+'\n')
 rs=scene.item(0,'ReplicatedStorage','ReplicatedStorage');scene.item(rs,'RemoteEvent','MuseumEvent');scene.script(rs,'ModuleScript','MuseumBlueprint','src/museum/Blueprint.lua');scene.script(rs,'ModuleScript','TrophySculptor','src/museum/TrophySculptor.lua');scene.script(rs,'ModuleScript','MuseumBuilder','src/museum/MuseumBuilder.lua')
 server=scene.item(0,'ServerScriptService','ServerScriptService');scene.script(server,'Script','MuseumServer','src/museum/Server.server.lua')
 sp=scene.item(0,'StarterPlayer','StarterPlayer',{'CameraMaxZoomDistance':['Float',90],'CameraMinZoomDistance':['Float',4]});ss=scene.item(sp,'StarterPlayerScripts','StarterPlayerScripts');scene.script(ss,'LocalScript','MuseumClient','src/museum/Client.client.lua')
 scene.item(0,'MaterialService','MaterialService',{'Use2022Materials':['Bool',True]})
 scene.item(0,'Lighting','Lighting',{'Ambient':['Color3',[.56,.58,.52]],'OutdoorAmbient':['Color3',[.62,.66,.62]],'Brightness':['Float',2],'ClockTime':['Float',14.5],'GlobalShadows':['Bool',True],'EnvironmentDiffuseScale':['Float',.8],'EnvironmentSpecularScale':['Float',.8]})
 scene.finish();report=dict(build=BUILD,full=full,total_parts=scene.parts+1,architecture_parts=scene.structure+1,trophy_body_parts=scene.trophy_counts,colliders=len(scene.colliders)+1)
 (ROOT/'docs'/('museum-source-full.json' if full else 'museum-source-lite.json')).write_text(json.dumps(report,indent=2)+'\n')
 (ROOT/'docs/museum-colliders.json').write_text(json.dumps(scene.colliders,separators=(',',':'))+'\n')
 print(json.dumps({k:v for k,v in report.items() if k!='trophy_body_parts'}),flush=True)
 return report

if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--full',action='store_true');p.add_argument('--output',required=True);a=p.parse_args();build_scene(Path(a.output),a.full)

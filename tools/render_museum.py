"""Blender preview of authored scene geometry; this is NOT a Roblox Studio screenshot.
Run: blender -b --threads 4 --python tools/render_museum.py -- /tmp/mv-museum-full.jsonl.gz
"""
import bpy,sys,gzip,json,math
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[1];sceneFile=Path(sys.argv[sys.argv.index('--')+1])
OUT=ROOT/'docs/previews';OUT.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
sc=bpy.context.scene;sc.render.engine='CYCLES';sc.cycles.samples=48;sc.cycles.use_denoising=False;sc.render.resolution_x=1440;sc.render.resolution_y=900;sc.render.resolution_percentage=100
sc.world.use_nodes=True;sc.world.node_tree.nodes['Background'].inputs['Color'].default_value=(.65,.68,.64,1);sc.world.node_tree.nodes['Background'].inputs['Strength'].default_value=.5;sc.view_settings.view_transform='AgX'
records={};meta={};batches={};animations=[];labels=[]
T=Matrix(((1,0,0),(0,0,-1),(0,1,0)))
verts0=[Vector((x,y,z))for x,y,z in ((-.5,-.5,-.5),(.5,-.5,-.5),(.5,.5,-.5),(-.5,.5,-.5),(-.5,-.5,.5),(.5,-.5,.5),(.5,.5,.5),(-.5,.5,.5))]
faces0=[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
def srgb(v):return (v/255)**2.2
def material(key):
 mat,alpha=key;m=bpy.data.materials.new('RobloxMaterial_'+str(mat)+'_'+str(alpha));m.use_nodes=True;n=m.node_tree.nodes;links=m.node_tree.links;bs=n.get('Principled BSDF');attr=n.new('ShaderNodeAttribute');attr.attribute_name='PartColor';links.new(attr.outputs['Color'],bs.inputs['Base Color']);bs.inputs['Roughness'].default_value=.7
 if mat in (1088,1040):bs.inputs['Metallic'].default_value=1;bs.inputs['Roughness'].default_value=.24
 elif mat==1568:bs.inputs['Transmission Weight'].default_value=0;bs.inputs['Roughness'].default_value=.14;bs.inputs['Alpha'].default_value=1-alpha
 elif mat==1536:bs.inputs['Transmission Weight'].default_value=.25;bs.inputs['Roughness'].default_value=.2
 elif mat==288:links.new(attr.outputs['Color'],bs.inputs['Emission Color']);bs.inputs['Emission Strength'].default_value=3
 noise=n.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=13 if mat==1344 else 25;noise.inputs['Detail'].default_value=4 if mat==1344 else 2
 bump=n.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.55 if mat==1344 else .16;bump.inputs['Distance'].default_value=.075 if mat==1344 else .025;links.new(noise.outputs['Fac'],bump.inputs['Height']);links.new(bump.outputs['Normal'],bs.inputs['Normal'])
 return m
materials={}
def mesh_object(name,vs,fs,colors,key):
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(vs,[],fs);mesh.update();obj=bpy.data.objects.new(name,mesh);sc.collection.objects.link(obj)
 col=mesh.color_attributes.new(name='PartColor',type='FLOAT_COLOR',domain='POINT')
 flat=[]
 for c in colors:flat.extend((*[srgb(q)for q in c],1))
 col.data.foreach_set('color',flat)
 if key not in materials:materials[key]=material(key)
 obj.data.materials.append(materials[key]);return obj
with gzip.open(sceneFile,'rt')as f:
 for line in f:
  r=json.loads(line);records[r['i']]={'p':r['p'],'n':r['n'],'c':r['c']}
  if r['n']=='Center':meta[r['p']]=r['v']['Value'][1]
  if 'b' in r:
   b=r['b'];size,pos,col,mat,rot,collide,alpha,shape,shadow=b
   if alpha>=.99 or not(-78<pos[0]<78 and -198<pos[2]<202 and -.5<pos[1]<29):continue
   R=Matrix((rot[:3],rot[3:6],rot[6:]));p=Vector(pos);coords=[tuple(T@(p+R@Vector((v.x*size[0],v.y*size[1],v.z*size[2]))))for v in verts0]
   key=(mat,round(alpha,2));parent=records.get(r['p'],{})
   if parent.get('n')=='Animation':
    obj=mesh_object(r['n'],coords,faces0,[col]*8,key);animations.append((obj,r,rot))
   else:
    batch=batches.setdefault(key,{'v':[],'f':[],'c':[]});offset=len(batch['v']);batch['v'].extend(coords);batch['f'].extend(tuple(offset+i for i in face)for face in faces0);batch['c'].extend([col]*8)
   records[r['i']]['b']=b
  if r['c']=='SurfaceLight':
   parent=records.get(r['p'],{});b=parent.get('b')
   if b:
    light=bpy.data.lights.new('Authored gallery light','AREA');light.energy=18000;light.shape='DISK';light.size=10;light.color=(1,.88,.67);obj=bpy.data.objects.new(light.name,light);sc.collection.objects.link(obj);obj.location=T@Vector(b[1]);obj.rotation_euler=(0,0,0)
  if r['c']=='TextLabel':
   gui=records.get(r['p'],{});plate=records.get(gui.get('p'));b=plate and plate.get('b')
   if b and b[1][2]<177:labels.append((r['v']['Text'][1],b))
for key,b in batches.items():mesh_object('Serialized architecture '+str(key),b['v'],b['f'],b['c'],key)
fontpath=Path('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf');font=bpy.data.fonts.load(str(fontpath))if fontpath.exists()else None
for text,b in labels:
 curve=bpy.data.curves.new('Actual inscription','FONT');curve.body=text;curve.align_x='CENTER';curve.align_y='CENTER';curve.size=min(.48,b[0][1]/max(2,len(text.splitlines()))*.45)
 if font:curve.font=font
 obj=bpy.data.objects.new('Actual inscription',curve);sc.collection.objects.link(obj);obj.location=(b[1][0],-b[1][2]-.13,b[1][1]);obj.rotation_euler=(math.pi/2,0,0)
 ma=bpy.data.materials.get('Plaque lettering')or bpy.data.materials.new('Plaque lettering');ma.diffuse_color=(.85,.72,.44,1);obj.data.materials.append(ma)
# Window daylight fill approximates the real scene's neutral afternoon environment.
light=bpy.data.lights.new('Daylight through arrival','AREA');light.energy=9000;light.size=28;lo=bpy.data.objects.new(light.name,light);sc.collection.objects.link(lo);lo.location=(0,-194,18);direction=Vector((0,-140,7))-lo.location;lo.rotation_euler=direction.to_track_quat('-Z','Y').to_euler()
sc.use_nodes=True;nodes=sc.node_tree.nodes;links=sc.node_tree.links;nodes.clear();r=nodes.new('CompositorNodeRLayers');g=nodes.new('CompositorNodeGlare');g.glare_type='FOG_GLOW';g.quality='HIGH';g.threshold=2;c=nodes.new('CompositorNodeComposite');links.new(r.outputs['Image'],g.inputs['Image']);links.new(g.outputs['Image'],c.inputs['Image'])
camD=bpy.data.cameras.new('Camera');cam=bpy.data.objects.new('Camera',camD);sc.collection.objects.link(cam);sc.camera=cam
cam.location=(0,-177,8.5);target=Vector((0,-130,8));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=23
sc.render.image_settings.file_format='PNG';sc.render.filepath=str(OUT/'museum-gallery.png');bpy.ops.render.render(write_still=True)
if '--still-only' in sys.argv:
 print('Still geometry preview complete');sys.exit(0)
# Actual animation geometry is transformed about the authored exhibit center.
originals={obj:(obj.location.copy(),obj.rotation_euler.copy(),[v.co.copy()for v in obj.data.vertices])for obj,_,_ in animations}
sc.render.resolution_x=1440;sc.render.resolution_y=640;sc.cycles.samples=12;cam.location=(0,-170,10);target=Vector((0,-136,6.5));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.lens=28
for frame in range(8):
 t=frame/5
 for obj,r,rot in animations:
  name=r['n'];b=r['b'];center=meta.get(r['p'],None)
  if center is None:
   exhibit=records.get(r['p'],{}).get('p');center=meta.get(exhibit,[0,5.5,136])
  C=T@Vector(center);i=int(name.rsplit('_',1)[-1])if name.rsplit('_',1)[-1].isdigit()else 0
  obj.matrix_world=Matrix.Identity(4)
  if name.startswith('Fold_'):
   delta=Vector((math.sin(t*1.7+i)*.025,0,math.sin(t*2+i)*.06));obj.location=delta;obj.scale=(1+(math.sin(t*2+i)*.04),1,1+math.sin(t*2+i)*.08)
  elif name.startswith('Drop_'):obj.location=(0,0,-((t*.65+i*.13)%1)*1.3)
  elif name.startswith('Ghost'):
   angle=-t*.23;obj.matrix_world=Matrix.Translation(C)@Matrix.Rotation(angle,4,'Z')@Matrix.Translation(-C);obj.location.z+=math.sin(t*1.4+i*.16)*.18
  elif name.startswith('Orbit')or name.startswith('Coin_')or name.startswith('GoldFiligree_'):
   speed=.18 if name.startswith('Orbit0')else .32;obj.matrix_world=Matrix.Translation(C)@Matrix.Rotation(t*speed,4,'Z')@Matrix.Translation(-C)
  elif name.startswith('Star_'):obj.location.z=math.sin(t*.7+i)*.055
 sc.render.filepath=str(OUT/f'mutation-frame-{frame:02}.png');bpy.ops.render.render(write_still=True)
print('GEOMETRY PREVIEW COMPLETE — not a Roblox Studio execution')

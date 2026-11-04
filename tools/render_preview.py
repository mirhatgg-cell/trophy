"""Optional Blender renderer for inspecting the generated geometry. Images are offline previews, not Studio screenshots."""
import json, math, sys
from pathlib import Path
import bpy
from mathutils import Vector, Matrix

root=Path(__file__).resolve().parents[1]
mode=sys.argv[sys.argv.index('--')+1] if '--' in sys.argv else 'architecture'
scene=json.loads((root/'build/scene.json').read_text())
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
materials={}
groups={}

def point(v):return (v[0],-v[2],v[1])
def mat(color,alpha,material):
    key=(color,round(alpha,1),material)
    if key not in materials:
        m=bpy.data.materials.new(str(key));m.diffuse_color=(((color>>16)&255)/255,((color>>8)&255)/255,(color&255)/255,1)
        m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=m.diffuse_color
        p.inputs['Roughness'].default_value=.35 if material==1088 else .7
        p.inputs['Metallic'].default_value=.55 if material==1088 else 0
        if material==1568:p.inputs['Alpha'].default_value=.2;p.inputs['Roughness'].default_value=.18
        materials[key]=m
    return key

cube_vertices=[(-.5,-.5,-.5),(.5,-.5,-.5),(.5,.5,-.5),(-.5,.5,-.5),(-.5,-.5,.5),(.5,-.5,.5),(.5,.5,.5),(-.5,.5,.5)]
cube_faces=[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
for p in scene:
    if p['material']==1568:continue
    key=mat(p['color'],p['alpha'],p['material']);verts,faces=groups.setdefault(key,([],[]))
    base=len(verts);size=p['size'];r=Matrix(p['rotation']);pos=Vector(p['position'])
    if p['shape']==0:
        v=[];f=[];segments=12;rings=7
        for j in range(rings+1):
            phi=math.pi*j/rings
            for i in range(segments):
                t=2*math.pi*i/segments;v.append((math.sin(phi)*math.cos(t)*.5,math.cos(phi)*.5,math.sin(phi)*math.sin(t)*.5))
        for j in range(rings):
            for i in range(segments):f.append((j*segments+i,j*segments+(i+1)%segments,(j+1)*segments+(i+1)%segments,(j+1)*segments+i))
    elif p['shape']==2:
        v=[];f=[];segments=16
        for x in (-.5,.5):
            for i in range(segments):t=2*math.pi*i/segments;v.append((x,math.cos(t)*.5,math.sin(t)*.5))
        f.append(tuple(range(segments-1,-1,-1)));f.append(tuple(range(segments,2*segments)))
        for i in range(segments):f.append((i,(i+1)%segments,(i+1)%segments+segments,i+segments))
    else:v=cube_vertices;f=cube_faces
    for vtx in v:verts.append(point(r@Vector(tuple(vtx[i]*size[i] for i in range(3)))+pos))
    for face in f:faces.append(tuple(base+i for i in face))
for key,(vertices,faces) in groups.items():
    mesh=bpy.data.meshes.new('DistrictMesh');mesh.from_pydata(vertices,[],faces);mesh.materials.append(materials[key]);mesh.update()
    obj=bpy.data.objects.new('Architecture',mesh);bpy.context.collection.objects.link(obj)
world=bpy.context.scene.world;world.use_nodes=True;world.node_tree.nodes['Background'].inputs[0].default_value=(.66,.75,.78,1);world.node_tree.nodes['Background'].inputs[1].default_value=.65
light_data=bpy.data.lights.new('LateAfternoon','SUN');light=bpy.data.objects.new('LateAfternoon',light_data);bpy.context.collection.objects.link(light);light.rotation_euler=(math.radians(30),math.radians(-22),math.radians(-30));light_data.energy=3;light_data.angle=.12
camera_data=bpy.data.cameras.new('PreviewCamera');camera=bpy.data.objects.new('PreviewCamera',camera_data);bpy.context.collection.objects.link(camera)
camera.location=point((38,82,-315));target=Vector(point((-80,8,-112)));camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();camera_data.type='PERSP';camera_data.lens=38
if mode=='interior':
    camera.location=point((-100,11,-137));target=Vector(point((-125,5,-162)))
    camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();camera_data.lens=24
    for xx in (-137,-118,-99):
        ld=bpy.data.lights.new('InteriorLamp','AREA');lo=bpy.data.objects.new('InteriorLamp',ld);bpy.context.collection.objects.link(lo)
        lo.location=point((xx,14,-160));ld.energy=2200;ld.size=7
sc=bpy.context.scene;sc.camera=camera;sc.render.engine='CYCLES';sc.cycles.samples=96 if mode=='interior' else 24;sc.cycles.use_denoising=False
for layer in sc.view_layers:layer.cycles.use_denoising=False
sc.render.resolution_x=1600;sc.render.resolution_y=1000;sc.render.resolution_percentage=100
sc.view_settings.view_transform='AgX';sc.render.image_settings.file_format='PNG';sc.render.filepath=str(root/f'build/{mode}-preview.png')
bpy.ops.render.render(write_still=True)

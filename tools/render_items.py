"""Offline contact sheet of actual exported item parts, including wedge facets.

Run: blender -b --python tools/render_items.py -- gems|all
This approximates materials/light; it is not a Roblox engine screenshot.
"""
import json, math, sys
from pathlib import Path
import bpy
from mathutils import Vector, Matrix

ROOT=Path(__file__).resolve().parents[1]
mode=sys.argv[sys.argv.index('--')+1]if '--'in sys.argv else'gems'
items=json.loads((ROOT/'build/item-scene.json').read_text())
catalog={d['id']:d for d in json.loads((ROOT/'content/items.json').read_text())}
ids=list(catalog)if mode=='all'else['j12','j07','j08','j09','j06','j15','j20','h02','a01','a02','a03','a14']
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
normal=Vector((.18,.83,.558)).normalized();orientation=(-normal).to_track_quat('-Z','Y')
right=orientation@Vector((1,0,0));up=orientation@Vector((0,1,0))
materials={}

def material(p):
    key=(p['color'],p['material'])
    if key not in materials:
        c=p['color'];m=bpy.data.materials.new(str(key));m.use_nodes=True
        shader=m.node_tree.nodes.get('Principled BSDF')
        def linear(v):
            v=v/255
            return v/12.92 if v<=.04045 else((v+.055)/1.055)**2.4
        shader.inputs['Base Color'].default_value=(linear((c>>16)&255),linear((c>>8)&255),linear(c&255),1)
        shader.inputs['Roughness'].default_value=.17 if p['material']==1568 else .3 if p['material']==1088 else .60
        shader.inputs['Metallic'].default_value=.6 if p['material']==1088 else .03
        if p['material']==1568:shader.inputs['Coat Weight'].default_value=.6
        materials[key]=m
    return materials[key]

def primitive(p):
    if p['class']=='WedgePart':
        return[(-.5,-.5,-.5),(.5,-.5,-.5),(-.5,-.5,.5),(.5,-.5,.5),(-.5,.5,.5),(.5,.5,.5)],[(0,2,3,1),(2,4,5,3),(0,1,5,4),(0,4,2),(1,3,5)]
    if p['shape']==0:
        v=[];f=[];segments=14;rings=9
        for j in range(rings+1):
            phi=math.pi*j/rings
            for i in range(segments):
                t=2*math.pi*i/segments;v.append((math.sin(phi)*math.cos(t)*.5,math.cos(phi)*.5,math.sin(phi)*math.sin(t)*.5))
        for j in range(rings):
            for i in range(segments):f.append((j*segments+i,j*segments+(i+1)%segments,(j+1)*segments+(i+1)%segments,(j+1)*segments+i))
        return v,f
    if p['shape']==2:
        v=[];f=[];segments=24
        for x in (-.5,.5):
            for i in range(segments):t=2*math.pi*i/segments;v.append((x,math.cos(t)*.5,math.sin(t)*.5))
        f=[tuple(range(segments-1,-1,-1)),tuple(range(segments,2*segments))]
        for i in range(segments):f.append((i,(i+1)%segments,(i+1)%segments+segments,i+segments))
        return v,f
    return[(-.5,-.5,-.5),(.5,-.5,-.5),(.5,.5,-.5),(-.5,.5,-.5),(-.5,-.5,.5),(.5,-.5,.5),(.5,.5,.5),(-.5,.5,.5)],[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]

columns=10 if mode=='all'else 4;rows=math.ceil(len(ids)/columns);step=3.9
font=bpy.data.fonts.load('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf')
textmat=bpy.data.materials.new('Caption');textmat.diffuse_color=(.78,.86,.98,1)
for index,identity in enumerate(ids):
    meshes=[];bounds=[]
    for p in items[identity]:
        v,f=primitive(p);r=Matrix(p['rotation']);pos=Vector(p['position']);s=p['size']
        v=[r@Vector((x*s[0],y*s[1],z*s[2]))+pos for x,y,z in v]
        meshes.append((p,v,f));bounds.extend(v)
    low=Vector(tuple(min(v[i]for v in bounds)for i in range(3)));high=Vector(tuple(max(v[i]for v in bounds)for i in range(3)))
    center=(low+high)*.5;factor=2.65/max(high-low)
    offset=right*((index%columns-(columns-1)/2)*step)+up*(((rows-1)/2-index//columns)*step)
    for p,vertices,faces in meshes:
        v=[]
        for point in vertices:
            x,y,z=(point-center)*factor;v.append(Vector((x,-z,y))+offset)
        mesh=bpy.data.meshes.new(p['name']);mesh.from_pydata(v,[],faces);mesh.materials.append(material(p));mesh.update()
        ob=bpy.data.objects.new(p['name'],mesh);bpy.context.collection.objects.link(ob)
    curve=bpy.data.curves.new('Name','FONT');curve.body=identity+' · '+catalog[identity]['name'];curve.font=font;curve.align_x='CENTER';curve.size=.14 if mode=='all'else .16
    ob=bpy.data.objects.new('ItemName',curve);bpy.context.collection.objects.link(ob);ob.location=offset-up*1.68;ob.rotation_euler=orientation.to_euler();ob.data.materials.append(textmat)

scene=bpy.context.scene;scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.12,.16,.23,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.65
for name,location,energy,size in [('Key',(0,-12,20),4200,18),('Rim',(-10,10,12),3800,15)]:
    light=bpy.data.lights.new(name,'AREA');light.energy=energy;light.shape='DISK';light.size=size
    ob=bpy.data.objects.new(name,light);bpy.context.collection.objects.link(ob);ob.location=location;ob.rotation_euler=(-ob.location).to_track_quat('-Z','Y').to_euler()
camera=bpy.data.cameras.new('Camera');ob=bpy.data.objects.new('Camera',camera);bpy.context.collection.objects.link(ob)
ob.location=normal*80;ob.rotation_euler=orientation.to_euler();camera.type='ORTHO';camera.ortho_scale=columns*step
scene.camera=ob;scene.render.engine='CYCLES';scene.cycles.samples=16 if mode=='all'else 64;scene.cycles.use_denoising=False
for layer in scene.view_layers:layer.cycles.use_denoising=False
scene.render.resolution_x=3600 if mode=='all'else 1600;scene.render.resolution_y=round(scene.render.resolution_x*rows/columns)
scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG'
scene.render.filepath=str(ROOT/f'build/items-{mode}.png');bpy.ops.render.render(write_still=True)

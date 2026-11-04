#!/usr/bin/env python3
"""Validate serialization, source freshness, assembly, floor coverage and sampled navigation clearances."""
import json, math, os, sys
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
path=ROOT/'build/PROBA.rbxlx'
xml=ET.parse(path).getroot()
nodes=list(xml.iter('Item'))
refs={n.get('referent'):n for n in nodes}
assert len(refs)==len(nodes),'Duplicate instance referent'
parents={c:p for p in xml.iter() for c in p}
checks=0

def require(condition,reason):
    global checks
    checks+=1
    assert condition,reason

def prop(n,name,default=None):
    p=n.find(f"Properties/*[@name='{name}']")
    return p if p is not None else default

def name(n):return prop(n,'Name').text
def children(n):return n.findall('Item')
def child(n,wanted):return next(c for c in children(n) if name(c)==wanted)
def descendants(n,wanted=None):return [c for c in n.iter('Item') if c is not n and (wanted is None or name(c)==wanted)]
def position(n):return tuple(float(prop(n,'CFrame').find(k).text) for k in ('X','Y','Z'))
def size(n):return tuple(float(prop(n,'size').find(k).text) for k in ('X','Y','Z'))
def matrix(n):return tuple(tuple(float(prop(n,'CFrame').find(f'R{i}{j}').text) for j in range(3)) for i in range(3))
def is_part(n):return n.get('class') in ('Part','WedgePart','SpawnLocation')
def collides(n):return prop(n,'CanCollide') is not None and prop(n,'CanCollide').text=='true'

for n in nodes:
    for p in n.findall('Properties/Ref'):
        require(p.text in refs or p.text in ('null','nil',None),f'Broken reference {p.text}')
    if is_part(n):
        s=size(n);r=matrix(n)
        require(all(math.isfinite(x) and .001<=x<=2048 for x in s),f'Invalid dimensions: {name(n)} {s}')
        require(all(math.isfinite(x) for x in position(n)),f'Invalid transform: {name(n)}')
        for i in range(3):
            for j in range(3):require(abs(sum(r[k][i]*r[k][j] for k in range(3))-(i==j))<1e-5,f'Non-orthonormal transform: {name(n)}')

ws=next(n for n in nodes if n.get('class')=='Workspace')
server=next(n for n in nodes if n.get('class')=='ServerScriptService')
rep=next(n for n in nodes if n.get('class')=='ReplicatedStorage')
storage=next(n for n in nodes if n.get('class')=='ServerStorage')
models=child(rep,'ItemModels');buildings=child(storage,'Buildings')
definitions=json.loads((ROOT/'content/items.json').read_text())
require(len(children(models))==100,'Exactly 100 physical item models required')
require({name(m) for m in children(models)}=={d['id'] for d in definitions},'Catalog and physical models differ')
require(len(children(child(ws,'Plots')))==6,'Six assignable plots required')
require(len(children(buildings))==3,'Exactly three functional base stages required')
for m in children(models):
    require(prop(m,'PrimaryPart').text in refs,f'Missing model pivot for {name(m)}')
    require(len([p for p in descendants(m) if is_part(p)])>=4,f'Missing authored geometry for {name(m)}')
    require(all(not collides(p) for p in descendants(m) if is_part(p)),f'Inventory detail colliders enabled: {name(m)}')

expected_sources={}
for folder in ('Shared','Server'):
    for f in (ROOT/'src'/folder).glob('*.luau'):
        expected_sources[f.name.replace('.server.luau','').replace('.luau','')]=f.read_text()
expected_sources['ProbaClient']=(ROOT/'src/Client/Main.client.luau').read_text()
actual_scripts=[n for n in nodes if n.get('class') in ('Script','LocalScript','ModuleScript')]
require(len(actual_scripts)==len(expected_sources),'Unexpected or missing scripts in built place')
for n in actual_scripts:require(prop(n,'Source').text==expected_sources[name(n)],f'Out-of-date embedded script {name(n)}')

for n in descendants(ws):
    if is_part(n):require(prop(n,'Anchored').text=='true',f'Unanchored static environment object: {name(n)}')
rig=child(child(storage,'Templates'),'BaconCustomer')
require(len([n for n in rig.iter('Item') if n.get('class')=='Motor6D'])==6,'Fallback customer needs a complete articulated R6 rig')
require(any(n.get('class')=='Humanoid' for n in rig.iter('Item')),'Fallback customer lacks a humanoid')
ground=next(p for p in descendants(ws,'ContinuousTownGround'))
require(size(ground)==(560.,16.,800.),'Ground must cover the complete playable quarter continuously')

def hit(box,x,y,z,expand=.0):
    c,s,r=box
    delta=(x-c[0],y-c[1],z-c[2])
    local=tuple(sum(r[j][i]*delta[j] for j in range(3)) for i in range(3))
    return all(abs(local[i])<s[i]/2+expand-1e-5 for i in range(3))

def geometry(model):return [(p,(position(p),size(p),matrix(p))) for p in descendants(model) if is_part(p) and collides(p)]

def check_route(model,points,label):
    candidates=[]
    for p,box in geometry(model):
        if label=='stair approach' and name(p) in ('StairTread','StairRiser'):continue
        if name(p) in ('Left','Right') and parents.get(parents.get(p)) is not None:
            # Sensor-operated leaves open before a character enters the doorway.
            continue
        c,s,r=box
        extent_y=sum(abs(r[1][i])*s[i]/2 for i in range(3))
        if c[1]+extent_y<=1.15 or c[1]-extent_y>=6.5:continue
        extent_x=sum(abs(r[0][i])*s[i]/2 for i in range(3))
        extent_z=sum(abs(r[2][i])*s[i]/2 for i in range(3))
        candidates.append((p,box,(c[0]-extent_x-1.1,c[0]+extent_x+1.1,c[2]-extent_z-1.1,c[2]+extent_z+1.1)))
    for a,b in zip(points,points[1:]):
        steps=max(1,math.ceil(math.dist(a,b)/.5))
        for i in range(steps+1):
            x=a[0]+(b[0]-a[0])*i/steps;z=a[1]+(b[1]-a[1])*i/steps
            for p,box,bounds in candidates:
                if not(bounds[0]<x<bounds[1] and bounds[2]<z<bounds[3]):continue
                for dx,dz in ((0,0),(-1.1,0),(1.1,0),(0,-1.1),(0,1.1),(-.78,-.78),(-.78,.78),(.78,-.78),(.78,.78)):
                    for y in (1.3,2.2,3.7,5.3,6.3):
                        require(not hit(box,x+dx,y,z+dz),f'{name(model)} blocked {label} at ({x:.2f},{z:.2f}) by {name(p)}')

for base in children(buildings):
    for marker in ('AppraisalPrompt','RegistryPrompt','Tool_loupe','Tool_scale','Tool_uv','Tool_spectro','Tool_diagnostic'):
        require(len(descendants(base,marker))==1,f'Missing or duplicated runtime marker: {name(base)} {marker}')
    check_route(base,[(46,-94),(0,-48),(0,-20),(0,-1)],'customer arrival')
    check_route(base,[(46,-94),(-18,-72),(-18,-48)],'waiting queue')
    check_route(base,[(-18,-48),(0,-48),(0,-20),(0,-1)],'queue promotion')
    doorway=child(base,'DoorAssembly')
    require({name(c) for c in children(doorway)}=={'Rail','RailBracket','Left','Right','Sensor'},'Door drive or leaves missing')
    floor=next(p for p in descendants(base,'GroundFloor'))
    require(size(floor)[1]==.5 and collides(floor),'Each base needs a continuous solid ground floor')

upper_base=child(buildings,'Level3');upper=child(upper_base,'UpperGallery')
slabs=[(position(p),size(p),matrix(p)) for p in descendants(upper) if name(p).endswith('Slab')]
for x in range(-52,53):
    for z in range(-40,41):
        intended_void=(-16<x<16 and -12<z<23) or (36<x<47.5 and -24<z<23)
        if not intended_void:require(any(hit(b,x,20.1,z,expand=.001) for b in slabs),f'Uncovered gallery floor at {x},{z}')
require(len(descendants(upper,'SafetyGlass'))>=7,'Atrium and stairwell voids must be guarded')
treads=descendants(upper_base,'StairTread')
require(len(treads)==36,'Gallery flight needs all thirty-six treads')
tops=sorted(position(p)[1]+size(p)[1]/2 for p in treads)
require(abs(tops[-1]-20.6)<1e-6 and max(b-a for a,b in zip(tops,tops[1:]))<=.55,'Stair risers must meet the gallery and remain climbable')
check_route(upper_base,[(14,10),(26,5),(33,-23),(42,-23),(42,-21)],'stair approach')
require(prop(child(ws,'Camera'),'CameraType').text=='5','Player camera must remain Custom, not a saved fixed editor camera')

api_path=Path(os.environ.get('ROBLOX_API_DUMP','/tmp/proba-api-dump.json'))
if api_path.exists():
    api=json.loads(api_path.read_text());classes={c['Name']:c for c in api['Classes']};enums={e['Name']:{v['Value'] for v in e['Items']} for e in api['Enums']}
    aliases={'size':'Size','shape':'Shape','Color3uint8':'Color'}
    def inherited(cls):
        c=classes[cls];p=inherited(c['Superclass']) if c['Superclass'] in classes else {}
        p.update({m['Name']:m for m in c['Members'] if m['MemberType']=='Property'});return p
    cache={c:inherited(c) for c in classes}
    for n in nodes:
        cls=n.get('class');require(cls in classes,f'Unknown Roblox class {cls}')
        for p in n.find('Properties'):
            prop_name=aliases.get(p.get('name'),p.get('name'))
            require(prop_name in cache[cls],f'Unknown Roblox property {cls}.{prop_name}')
            dt=cache[cls][prop_name]['ValueType']
            if p.tag=='token' and dt['Category']=='Enum':require(int(p.text) in enums[dt['Name']],f'Invalid enum {cls}.{prop_name}={p.text}')
    for method in ('GetFriendsAsync','GetHumanoidDescriptionFromUserIdAsync','CreateHumanoidModelFromDescriptionAsync'):
        require(any(m['Name']==method for m in classes['Players']['Members']),f'Unavailable avatar API: {method}')
    import re
    enum_names={e['Name']:{v['Name'] for v in e['Items']} for e in api['Enums']}
    for source in expected_sources.values():
        for typ,value in re.findall(r'Enum\.(\w+)\.(\w+)',source):require(typ in enum_names and value in enum_names[typ],f'Unavailable script enum Enum.{typ}.{value}')
    print('PASS current Roblox API schema and enum validation')
else:print('SKIP optional API schema check (set ROBLOX_API_DUMP to an API-Dump.json)')

print(f'PASS place/source/geometry: {checks} assertions; {len(nodes)} instances; 100 item models; 3 base stages')

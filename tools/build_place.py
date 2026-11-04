#!/usr/bin/env python3
"""Build a deterministic Roblox XML place using only Python's standard library."""
from pathlib import Path
import xml.etree.ElementTree as ET
import argparse
import math
from architecture import Architect
from world_spec import records

ROOT = Path(__file__).resolve().parents[1]

def build():
    root = ET.Element('roblox', {'version':'4'})
    ET.SubElement(root, 'External').text = 'null'
    ET.SubElement(root, 'External').text = 'nil'
    serial = 0

    def item(parent, cls, name, props=()):
        nonlocal serial
        serial += 1
        obj = ET.SubElement(parent, 'Item', {'class':cls, 'referent':f'RBX{serial:08d}'})
        properties = ET.SubElement(obj, 'Properties')
        ET.SubElement(properties, 'string', {'name':'Name'}).text = name
        for typ, key, value in props:
            field = ET.SubElement(properties, typ, {'name':key})
            if typ == 'Vector3':
                for axis, num in zip(('X','Y','Z'), value): ET.SubElement(field,axis).text = str(num)
            elif typ == 'Color3':
                for axis, num in zip(('R','G','B'), value): ET.SubElement(field,axis).text = str(num/255)
            elif typ == 'CoordinateFrame':
                for axis, num in zip(('X','Y','Z'),value[:3]): ET.SubElement(field,axis).text = str(num)
                for row in range(3):
                    for col in range(3): ET.SubElement(field,f'R{row}{col}').text = str(((math.cos(value[3]) if row==col and row!=1 else 1 if row==col else math.sin(value[3]) if row==0 and col==2 else -math.sin(value[3]) if row==2 and col==0 else 0) if len(value)>3 else (1 if row==col else 0)))
            elif typ == 'UDim2':
                for axis, num in zip(('XS','XO','YS','YO'),value): ET.SubElement(field,axis).text = str(num)
            else: field.text = str(value).lower() if isinstance(value,bool) else str(value)
        return obj

    workspace = item(root,'Workspace','Workspace', [('float','Gravity',196.2), ('float','FallenPartsDestroyHeight',-10000),('bool','StreamingEnabled',True),('int','StreamingMinRadius',256),('int','StreamingTargetRadius',1024)])
    world=item(workspace,'Folder','WorldMap')
    architect=Architect(item)
    architect.landscape(world)
    architect.lobby(world)
    for g in records():
        architect.mountain(world,g)
        architect.horizon(world,g)
    storage=item(root,'ServerStorage','ServerStorage')
    architect.museum(storage)
    public=architect.museum(world)
    public.find("Properties/string[@name='Name']").text='PublicArchive'
    for cf in public.findall(".//CoordinateFrame[@name='CFrame']"):
        cf.find('X').text=str(float(cf.find('X').text)-1000)
        cf.find('Z').text=str(float(cf.find('Z').text)+700)
    item(root,'Lighting','Lighting',[
        ('Color3','Ambient',(135,145,153)),('Color3','OutdoorAmbient',(145,154,162)),('float','Brightness',2),
        ('float','ClockTime',14.7),('bool','GlobalShadows',True),('float','EnvironmentDiffuseScale',.6),('float','EnvironmentSpecularScale',.7)])
    # Services and scripts are embedded: the rbxlx runs without plugins or downloads.
    rs=item(root,'ReplicatedStorage','ReplicatedStorage')
    item(rs,'RemoteEvent','TrophyEvent')
    for module in ('Catalog','TrophyIcons','Trials','Elimination','Infrastructure'):
        item(rs,'ModuleScript',module,[('ProtectedString','Source',(ROOT/f'src/{module}.lua').read_text())])
    server=item(root,'ServerScriptService','ServerScriptService')
    item(server,'Script','TrophyServer',[('ProtectedString','Source',(ROOT/'src/Server.server.lua').read_text()),('bool','Disabled',False)])
    starter=item(root,'StarterPlayer','StarterPlayer',[('float','CameraMaxZoomDistance',180),('float','CameraMinZoomDistance',5)])
    scripts=item(starter,'StarterPlayerScripts','StarterPlayerScripts')
    item(scripts,'LocalScript','TrophyClient',[('ProtectedString','Source',(ROOT/'src/Client.client.lua').read_text()),('bool','Disabled',False)])
    ET.indent(root,space='  ')
    return ET.tostring(root,encoding='utf-8',xml_declaration=True)+b'\n'

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--check',action='store_true',help='Fail if the committed place differs from source')
    args=parser.parse_args()
    target=ROOT/'Mountainverse.rbxlx'
    data=build()
    if args.check:
        if not target.exists() or target.read_bytes()!=data: raise SystemExit('Mountainverse.rbxlx is stale; run python3 tools/build_place.py')
        print('OK: Mountainverse.rbxlx matches source and parses as XML')
    else:
        target.write_bytes(data)
        print(f'Built {target.name}: {len(data):,} bytes')

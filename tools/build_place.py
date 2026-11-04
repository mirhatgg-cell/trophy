#!/usr/bin/env python3
"""Build a deterministic Roblox XML place using only Python's standard library."""
from pathlib import Path
import xml.etree.ElementTree as ET
import argparse

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
                for axis, num in zip(('X','Y','Z'),value): ET.SubElement(field,axis).text = str(num)
                for row in range(3):
                    for col in range(3): ET.SubElement(field,f'R{row}{col}').text = '1' if row==col else '0'
            elif typ == 'UDim2':
                for axis, num in zip(('XS','XO','YS','YO'),value): ET.SubElement(field,axis).text = str(num)
            else: field.text = str(value).lower() if isinstance(value,bool) else str(value)
        return obj

    workspace = item(root,'Workspace','Workspace', [('float','Gravity',196.2), ('float','FallenPartsDestroyHeight',-500)])
    preview = item(workspace,'Folder','PreviewScene')
    def part(name, size, position, color, material=256, transparency=0, cls='Part'):
        return item(preview,cls,name,[('Vector3','size',size),('CoordinateFrame','CFrame',position),('Color3','Color',color),('bool','Anchored',True),('token','Material',material),('float','Transparency',transparency),('token','TopSurface',0),('token','BottomSurface',0)])
    def label(parent, value, width=450):
        gui=item(parent,'BillboardGui','Sign',[('UDim2','Size',(0,width,0,100)),('Vector3','StudsOffset',(0,5,0)),('float','MaxDistance',300)])
        item(gui,'TextLabel','Text',[('UDim2','Size',(1,0,1,0)),('float','BackgroundTransparency',1),('string','Text',value),('Color3','TextColor3',(225,255,246)),('float','TextSize',24),('bool','TextWrapped',True),('float','TextStrokeTransparency',.4)])
    part('MuseumIsland',(120,3,100),(0,-1.5,0),(28,33,48))
    part('LobbySpawn',(10,1,10),(0,.5,12),(89,255,195),288,cls='SpawnLocation')
    sign=part('TROPHY',(46,8,2),(0,9,-43),(35,43,65))
    label(sign,'TROPHY // 50 МИРОВ\n5 испытаний → твоя коллекция')
    colors=[(239,62,92),(49,220,144),(54,128,255),(177,91,255)]
    for i,color in enumerate(colors):
        x=(i-1.5)*25
        part(f'PartyPad{i+1}',(18,1,18),(x,.6,-18),color,288)
        cube=part(f'PartyCube{i+1}',(17,12,17),(x,7,-18),color,1568,.8)
        label(cube,f'КУБ {i+1}\nВЫБЕРИ КОМАНДУ',230)
    for i in range(1,10): part('NeonPath',(1,.12,70),(-48+i*10,.06,0),(61,117,130),288)
    label(part('Shop',(12,8,8),(-43,4,25),(144,88,225)),'ЛАВКА КУРАТОРА',240)
    label(part('Museum',(12,8,8),(43,4,25),(72,183,155)),'ТВОЙ МУЗЕЙ',240)
    item(root,'Lighting','Lighting',[
        ('Color3','Ambient',(83,92,121)),('Color3','OutdoorAmbient',(95,103,135)),('float','Brightness',2),
        ('float','ClockTime',19.2),('bool','GlobalShadows',True),('float','EnvironmentDiffuseScale',.6),('float','EnvironmentSpecularScale',.7)])
    # Services and scripts are embedded: the rbxlx runs without plugins or downloads.
    rs=item(root,'ReplicatedStorage','ReplicatedStorage')
    item(rs,'RemoteEvent','TrophyEvent')
    item(rs,'ModuleScript','Catalog',[('ProtectedString','Source',(ROOT/'src/Catalog.lua').read_text())])
    server=item(root,'ServerScriptService','ServerScriptService')
    item(server,'Script','TrophyServer',[('ProtectedString','Source',(ROOT/'src/Server.server.lua').read_text()),('bool','Disabled',False)])
    starter=item(root,'StarterPlayer','StarterPlayer',[('float','CameraMaxZoomDistance',90),('float','CameraMinZoomDistance',5)])
    scripts=item(starter,'StarterPlayerScripts','StarterPlayerScripts')
    item(scripts,'LocalScript','TrophyClient',[('ProtectedString','Source',(ROOT/'src/Client.client.lua').read_text()),('bool','Disabled',False)])
    ET.indent(root,space='  ')
    return ET.tostring(root,encoding='utf-8',xml_declaration=True)+b'\n'

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--check',action='store_true',help='Fail if the committed place differs from source')
    args=parser.parse_args()
    target=ROOT/'Trophy.rbxlx'
    data=build()
    if args.check:
        if not target.exists() or target.read_bytes()!=data: raise SystemExit('Trophy.rbxlx is stale; run python3 tools/build_place.py')
        print('OK: Trophy.rbxlx matches source and parses as XML')
    else:
        target.write_bytes(data)
        print(f'Built {target.name}: {len(data):,} bytes')

#!/usr/bin/env python3
"""Verify packaging, compile Luau and run server logic in a deterministic mock harness.
Usage: python3 tools/check.py --luau /path/to/luau --compiler /path/to/luau-compile
The harness does not substitute for Studio physics and multiplayer playtests.
"""
import argparse
import subprocess
import tempfile
from pathlib import Path
import xml.etree.ElementTree as ET
from build_place import build, ROOT

parser=argparse.ArgumentParser()
parser.add_argument('--luau',required=True)
parser.add_argument('--compiler',required=True)
args=parser.parse_args()
place=ROOT/'Trophy.rbxlx'
assert place.read_bytes()==build(), 'Rebuild Trophy.rbxlx'
xml=ET.parse(place)
expected={'Catalog':'Catalog.lua','TrophyServer':'Server.server.lua','TrophyClient':'Client.client.lua'}
seen=set()
for item in xml.iter('Item'):
    props=item.find('Properties')
    name=props.find("string[@name='Name']").text
    if name in expected:
        assert props.find("ProtectedString[@name='Source']").text==(ROOT/'src'/expected[name]).read_text()
        seen.add(name)
assert seen==expected.keys()
subprocess.run([args.compiler,'--null',*[str(ROOT/'src'/p) for p in expected.values()]],check=True)
fixture=(ROOT/'tools/runtime_fixture.luau').read_text()
catalog=(ROOT/'src/Catalog.lua').read_text()
server=(ROOT/'src/Server.server.lua').read_text()
checks=(ROOT/'tools/runtime_checks.luau').read_text()
invariants='''
assert(#C.Games==50 and #C.LevelWins==20 and #C.Shop>=8 and #C.Achievements>=8)
local names,kinds={},{}
for id,g in ipairs(C.Games) do assert(g.id==id and not names[g.name]); names[g.name]=true; kinds[g.kind]=(kinds[g.kind] or 0)+1 end
local count=0; for _,n in pairs(kinds) do assert(n==5); count+=1 end; assert(count==10)
assert(C.Level(0)==0 and C.Level(1)==1 and C.Level(2)==1 and C.Level(3)==2 and C.Level(100000)==20)
for i,n in ipairs(C.LevelWins) do assert(C.Level(n)==i); if i>1 then assert(C.Level(n-1)==i-1 and n>C.LevelWins[i-1]) end end
assert(C.MutationChance==0.001 and not C.PublicTestAdmin)
local ids={}; for _,item in ipairs(C.Shop) do assert(not ids[item.id] and item.price>0); ids[item.id]=true end
print('PASS: 50 catalog entries, 10 families, 20 upgrade boundaries, shop IDs, rare mutation rate')
'''
source=fixture+'\nlocal C=(function()\n'+catalog+'\nend)()\n'+invariants+'\nlocal require=function() return C end\nlocal function boot()\n'+server+'\nend\nboot()\n'+checks
with tempfile.TemporaryDirectory(prefix='trophy-check-') as folder:
    script=Path(folder)/'server_check.luau'
    script.write_text(source)
    subprocess.run([args.luau,str(script)],check=True)
print('PASS: rbxlx structure, embedded script equality, deterministic rebuild, Luau compilation')

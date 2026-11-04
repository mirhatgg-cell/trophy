#!/usr/bin/env python3
"""Compile, validate serialized geometry and run real server sources against API doubles.
This checks logic, never claims to test Roblox physics, Studio rendering or live services.
"""
import argparse,subprocess,tempfile,xml.etree.ElementTree as ET
from pathlib import Path
from build_place import build,ROOT
from world_spec import records
p=argparse.ArgumentParser();p.add_argument('--luau',required=True);p.add_argument('--compiler',required=True);args=p.parse_args()
place=ROOT/'Mountainverse.rbxlx';assert place.read_bytes()==build(),'Place is stale'
assert (ROOT/'Trophy.rbxlx').read_bytes()==place.read_bytes(),'Old download link must serve the same current game'
xml=ET.parse(place)
expected={k:k+'.lua' for k in ('Catalog','TrophyIcons','Trials','Elimination','Infrastructure')}
expected.update(TrophyServer='Server.server.lua',TrophyClient='Client.client.lua')
seen=set();names=[];parts=0;refs=set()
for item in xml.iter('Item'):
 props=item.find('Properties');name=props.find("string[@name='Name']").text;names.append(name)
 assert item.attrib['referent'] not in refs;refs.add(item.attrib['referent'])
 if item.attrib['class'] in ('Part','SpawnLocation'): parts+=1
 if name in expected:
  assert props.find("ProtectedString[@name='Source']").text==(ROOT/'src'/expected[name]).read_text();seen.add(name)
assert seen==expected.keys();assert parts>4000
assert any(x.find("Properties/string[@name='Name']").text=='MountainverseBuildId' for x in xml.iter('Item')),'Visible build identity is missing'
for i in range(1,51):assert f'TrialGate{i}' in names and f'Stand{i}' in names
assert len(records())==50 and len({r['kind'] for r in records()})==50
subprocess.run([args.compiler,'--null',*[str(ROOT/'src'/f) for f in expected.values()]],check=True)
fixture=(ROOT/'tools/runtime_fixture.luau').read_text().replace('-- ROBLOX_MATH_INSERT',(ROOT/'tools/roblox_math.luau').read_text())
modules='\nlocal modules={}\n'
for name in ('Catalog','TrophyIcons','Trials','Elimination','Infrastructure'):
 modules+='modules.'+name+'=(function()\n'+(ROOT/'src'/expected[name]).read_text()+'\nend)()\n'
# All require targets must exist. The catalog is real; no substitute rules or fake game engine.
modules+="local C=modules.Catalog\nfor _,name in ipairs({'TrophyIcons','Trials','Elimination','Infrastructure'}) do local m=Instance.new('ModuleScript',RS); m.Name=name end\nlocal require=function(m) return assert(modules[m.Name],m.Name) end\n"
for offline in (False,True):
 source=fixture+'\n'+modules+'\nlocal OFFLINE='+str(offline).lower()+'\nDS.fail=OFFLINE\nlocal function boot()\n'+(ROOT/'src/Server.server.lua').read_text()+'\nend\nboot()\n'+(ROOT/'tools/engine_checks.luau').read_text()
 with tempfile.TemporaryDirectory(prefix='mountainverse-check-') as folder:
  file=Path(folder)/'check.luau';file.write_text(source);subprocess.run([args.luau,str(file)],check=True)
print(f'PASS: XML refs, embedded source equality, {parts:,} physical parts, 50 mountain contracts, 50 museum exhibits, deterministic build')

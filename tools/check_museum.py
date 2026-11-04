#!/usr/bin/env python3
"""Verify the actual binary, geometry routes, script compilation and runtime sculpture generator."""
from pathlib import Path
import argparse,json,subprocess,collections,tempfile,hashlib
import numpy as np
from build_place import ROOT,check
from test_museum_sculptor import run as test_sculptor

def geometry_checks(r):
 boxes=r['collision_geometry'];floors=[b for b in boxes if b['name'].startswith('Continuous floor')]
 assert len(floors)==3
 def a(b,k):return np.array([b[k][q]for q in ('X','Y','Z')])
 for f in floors:
  sz=a(f,'size');assert abs(sz[0]-480)<.01 and abs(sz[2]-384)<.01
  assert np.allclose(f['rotation'],[1,0,0,0,1,0,0,0,1]),'Continuous floor rotated'
 xs=np.arange(-236,237,2);zs=np.arange(-188,189,2);X,Z=np.meshgrid(xs,zs,indexing='ij')
 from museum_scene import exhibit_placements
 routes=0
 for level in range(3):
  foot=level*28+1.12;blocked=np.zeros(X.shape,bool)
  for box in boxes:
   pos=a(box,'position');half=np.abs(np.array(box['rotation']).reshape(3,3))@(a(box,'size')/2)
   if pos[1]+half[1]<=foot+.03 or pos[1]-half[1]>=foot+5.2:continue
   blocked|=(abs(X-pos[0])<half[0]+1.15)&(abs(Z-pos[2])<half[2]+1.15)
  def cell(x,z):return int(np.argmin(abs(xs-x))),int(np.argmin(abs(zs-z)))
  start=cell(0,174);assert not blocked[start],'Arrival blocked';seen={start};queue=collections.deque([start])
  while queue:
   i,j=queue.popleft()
   for q in ((i-1,j),(i+1,j),(i,j-1),(i,j+1)):
    if 0<=q[0]<len(xs)and 0<=q[1]<len(zs)and not blocked[q]and q not in seen:seen.add(q);queue.append(q)
  for e in exhibit_placements():
   if round((e['center'][1]-5.5)/28)==level:
    assert cell(e['center'][0],e['center'][2]+12)in seen,'Exhibit approach blocked: '+e['key'];routes+=1
  for side in (-1,1):assert cell(side*234,[120,44,-32][level])in seen,'Stair approach blocked'
 treads=[b for b in boxes if b['name']=='Solid supported stair tread'];assert len(treads)==224
 for side in (-1,1):
  for flight in (0,1):
   row=sorted([b for b in treads if (b['position']['X']>0)==(side>0)and((b['position']['Z']>48)==(flight==0))],key=lambda b:-b['position']['Z'])
   assert len(row)==56
   for previous,current in zip(row,row[1:]):
    rise=(current['position']['Y']+current['size']['Y']/2)-(previous['position']['Y']+previous['size']['Y']/2)
    assert .49<rise<.51 and abs(previous['position']['Z']-current['position']['Z'])<1.28
 platforms=[b for b in boxes if b['name']=='Platform'];assert len(platforms)==2 and all(b['size']['X']>20 for b in platforms)
 doors=[b for b in boxes if b['name'].startswith('Door')];assert len(doors)==12 and all(b['size']['X']>=11 for b in doors)
 print('PASS: 3 uninterrupted floor slabs, '+str(routes)+' reachable exhibit approaches, two connected 0.5-Stud stair routes and protected elevator openings')

def main():
 p=argparse.ArgumentParser();p.add_argument('--codec',default='/tmp/mv-placecodec');p.add_argument('--luau',default='/tmp/trophy-luau/luau');p.add_argument('--compiler',default='/tmp/trophy-luau/luau-compile');a=p.parse_args();check()
 with tempfile.TemporaryDirectory(prefix='museum-readback-')as d:
  report=Path(d)/'report.json';subprocess.run([a.codec,'--read',str(ROOT/'Museum.rbxl'),'--report',str(report)],check=True);r=json.loads(report.read_text())
 assert r['architecture_parts']>500000 and len(r['trophy_body_parts'])==74 and min(r['trophy_body_parts'].values())>=1000
 files={'MuseumBlueprint':'Blueprint.lua','TrophySculptor':'TrophySculptor.lua','MuseumBuilder':'MuseumBuilder.lua','MuseumServer':'Server.server.lua','MuseumClient':'Client.client.lua'}
 for name,file in files.items():
  source=ROOT/'src/museum'/file;assert hashlib.sha256(source.read_bytes()).hexdigest()==r['source_sha256'][name],'Embedded script stale: '+name
  result=subprocess.run([a.compiler,'--null',str(source)],capture_output=True,text=True)
  assert result.returncode==0 and 'SyntaxError'not in result.stdout+result.stderr,str(source)+'\n'+result.stdout+result.stderr
 geometry_checks(r);test_sculptor(a.luau)
 print('PASS: independent Roblox binary readback, 500000+ architectural Parts, all trophy bodies 1000+, actual embedded scripts and compatibility downloads')
if __name__=='__main__':main()

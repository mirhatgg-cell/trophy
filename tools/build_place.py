#!/usr/bin/env python3
"""Museum-first artifacts, including a complete static binary place and an XML bootstrap."""
from pathlib import Path
import argparse,subprocess,shutil,hashlib,json,tempfile
ROOT=Path(__file__).resolve().parents[1]
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def sources():
 paths=[ROOT/'tools/museum_scene.py',ROOT/'assets/trophy-shapes.json',ROOT/'assets/rank-ornaments.json',*sorted((ROOT/'src/museum').glob('*.lua'))]
 return {str(p.relative_to(ROOT)):digest(p)for p in paths}
def metadata():
 for alias in ('Mountainverse.rbxlx','Trophy.rbxlx'):shutil.copyfile(ROOT/'Museum.rbxlx',ROOT/alias)
 r=json.loads((ROOT/'docs/museum-readback-report.json').read_text())
 files=['Museum.rbxl','Museum.rbxlx','Museum.Full.rbxlx.gz','Mountainverse.rbxlx','Trophy.rbxlx']
 data={'build_id':'MUSEUM-2026.11.04-r4','primary_file':'Museum.rbxl','architecture_parts':r['architecture_parts'],'total_parts':r['parts'],'exhibits':len(r['trophy_body_parts']),'smallest_trophy_body':min(r['trophy_body_parts'].values()),'files':{f:digest(ROOT/f)for f in files},'sources':sources(),'formats':{'Museum.rbxl':'Complete static place, all 500000+ architectural Parts exist before Play','Museum.Full.rbxlx.gz':'Same complete static place as compressed XML; decompress before opening','Museum.rbxlx':'Light XML: complete collidable structure and mutation samples; remaining sculptural and surface detail is generated at Play'}}
 (ROOT/'build-info.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
def check():
 info=json.loads((ROOT/'build-info.json').read_text());assert info['build_id']=='MUSEUM-2026.11.04-r4'
 assert info['sources']==sources(),'Museum source changed since export'
 for file,sha in info['files'].items():assert digest(ROOT/file)==sha,'Artifact mismatch: '+file
 assert (ROOT/'Museum.rbxlx').read_bytes()==(ROOT/'Mountainverse.rbxlx').read_bytes()==(ROOT/'Trophy.rbxlx').read_bytes()
 r=json.loads((ROOT/'docs/museum-readback-report.json').read_text())
 assert r['architecture_parts']>500000 and len(r['trophy_body_parts'])==74 and min(r['trophy_body_parts'].values())>=1000
 print('PASS: artifact hashes, source fingerprints, both legacy download paths, architecture budget and per-trophy budget')
def build(codec):
 from museum_scene import build_scene
 with tempfile.TemporaryDirectory(prefix='museum-export-')as d:
  lite=Path(d)/'lite.jsonl.gz';full=Path(d)/'full.jsonl.gz'
  build_scene(lite,False);build_scene(full,True)
  subprocess.run([codec,'--input',str(lite),'--xml',str(ROOT/'Museum.rbxlx'),'--report',str(ROOT/'docs/museum-lite-codec-report.json')],check=True)
  subprocess.run([codec,'--input',str(full),'--output',str(ROOT/'Museum.rbxl'),'--xml',str(ROOT/'Museum.Full.rbxlx.gz'),'--report',str(ROOT/'docs/museum-encoded-report.json')],check=True)
  subprocess.run([codec,'--read',str(ROOT/'Museum.rbxl'),'--report',str(ROOT/'docs/museum-readback-report.json')],check=True)
 metadata();check()
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--codec',default='/tmp/mv-placecodec');p.add_argument('--check',action='store_true');p.add_argument('--metadata-only',action='store_true');a=p.parse_args()
 if a.check:check()
 elif a.metadata_only:metadata();check()
 else:build(a.codec)

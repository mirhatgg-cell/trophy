#!/usr/bin/env python3
"""Compile Luau, exercise the real economy/server modules and validate the built place."""
import argparse, json, os, shutil, subprocess, sys, tempfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--luau',default=os.environ.get('LUAU_BIN') or shutil.which('luau') or '/tmp/trophy-luau/luau')
parser.add_argument('--compiler',default=os.environ.get('LUAU_COMPILE_BIN') or shutil.which('luau-compile') or '/tmp/trophy-luau/luau-compile')
args=parser.parse_args()

def run(argv,**kw):
    r=subprocess.run(argv,cwd=ROOT,**kw)
    if r.returncode:raise SystemExit(r.returncode)

for path in sorted((ROOT/'src').rglob('*.luau')):
    run([args.compiler,str(path)],stdout=subprocess.DEVNULL)
print('PASS Luau compilation',flush=True)
run([args.luau,'tests/economy.spec.luau'])
run([args.luau,'tests/visits.spec.luau'])
run([args.luau,'tests/challenges.spec.luau'])
run([args.luau,'tests/rarity.spec.luau'])
run([args.luau,'tests/tutorial.spec.luau'])
bundle=(ROOT/'tests/roblox_mock.luau').read_text()+'\n'
for path in sorted((ROOT/'src/Shared').glob('*.luau')):
    bundle+='register('+json.dumps(path.stem)+',function()\n'+path.read_text()+'\nend, shared)\n'
for path in sorted((ROOT/'src/Server').glob('*.luau')):
    name=path.name.replace('.server.luau','').replace('.luau','')
    bundle+='register('+json.dumps(name)+',function()\n'+path.read_text()+'\nend, services.ServerScriptService)\n'
bundle+=(ROOT/'tests/server_flow.spec.luau').read_text()
with tempfile.NamedTemporaryFile('w',suffix='.luau',prefix='proba-server-',delete=False) as f:f.write(bundle);temporary=f.name
try:run([args.luau,temporary])
finally:Path(temporary).unlink(missing_ok=True)
run([sys.executable,'tools/validate_place.py'])

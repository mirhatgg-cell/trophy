"""Run the real client with UI/service substitutes and save constructor snapshots for offline inspection."""
import argparse,json,subprocess,tempfile
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--luau',default='/tmp/trophy-luau/luau');p.add_argument('--motion-preview',action='store_true');a=p.parse_args()
bundle=(root/'tests/roblox_mock.luau').read_text()+'\n'+(root/'tests/client_mock.luau').read_text()+'\n'
from build_place import lua_literal
from preview_fonts import prepare,metrics
fonts=prepare()
if fonts:
    measured=metrics(fonts,['red_blink','PROBA Player','Mira','Rowan','Оценщик','مرحبا','Aqua'])
    bundle+='previewFontMetrics='+lua_literal(measured)+'\n'
art=json.loads((root/'content/identity_art.json').read_text())
bundle+='local artFolder=node("Folder","IdentityArt",rep)\nlocal artValues={}\n'
for key,data in art.items():
    bundle+='artValues['+json.dumps(key)+']='+lua_literal(data)+'\n'
    bundle+='node("StringValue",'+json.dumps(key)+',artFolder).Value='+json.dumps(key)+'\n'
bundle+='local priorJSONDecode=services.HttpService.JSONDecode\nservices.HttpService.JSONDecode=function(self,value)if artValues[value]then return deepCopy(artValues[value])end;return priorJSONDecode(self,value)end\n'
for path in sorted((root/'src/Shared').glob('*.luau')):
    bundle+='register('+json.dumps(path.stem)+',function()\n'+path.read_text()+'\nend,shared)\n'
path=root/'src/Server/Catalog.luau'
bundle+='register("Catalog",function()\n'+path.read_text()+'\nend,services.ServerScriptService)\n'
for path in sorted((root/'src/Client').glob('*.luau')):
    name='ProbaClient' if path.name=='Main.client.luau' else path.stem
    bundle+='register('+json.dumps(name)+',function()\n'+path.read_text()+'\nend,clientScripts)\n'
if a.motion_preview:bundle+=(root/'tests/cosmetic_preview.luau').read_text()
else:
    bundle+=(root/'tests/client_flow.spec.luau').read_text()
    bundle+=(root/'tests/artwork.spec.luau').read_text()
    bundle+=(root/'tests/cosmetic_motion.spec.luau').read_text()
with tempfile.NamedTemporaryFile('w',suffix='.luau',prefix='proba-client-',delete=False)as f:f.write(bundle);temporary=Path(f.name)
try:result=subprocess.run([a.luau,str(temporary)],cwd=root,text=True,capture_output=True)
finally:temporary.unlink(missing_ok=True)
snapshots=[]
for line in result.stdout.splitlines():
    if line.startswith('UI_SNAPSHOT '):snapshots.append(json.loads(line[len('UI_SNAPSHOT '):]))
    else:print(line)
if result.returncode:print(result.stderr);raise SystemExit(result.returncode)
(root/('build/cosmetic-motion.json'if a.motion_preview else'build/ui-state.json')).write_text(json.dumps(snapshots,ensure_ascii=False))

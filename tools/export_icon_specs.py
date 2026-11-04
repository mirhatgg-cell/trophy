from pathlib import Path
import subprocess,json
ROOT=Path(__file__).resolve().parents[1]
math=(ROOT/'tools/roblox_math.luau').read_text()
source=math+"\nlocal Enum={PartType={Ball=0,Block=1,Cylinder=2}}\nlocal Icons=(function()\n"+(ROOT/'src/TrophyIcons.lua').read_text()+"\nend)()\n"
source+='''
local kinds={KINDS}
for _,kind in ipairs(kinds) do
 local specs={}
 Icons.build(kind,function(pos,size)
  local b={CFrame=CFrame.new(pos),Size=size,Shape=1,Transparency=0}; table.insert(specs,b); return b
 end)
 for _,s in ipairs(specs) do
  local c=s.CFrame; local v=s.Size
  print(string.format('%s|%.9g,%.9g,%.9g|%.9g,%.9g,%.9g|%s|%s|%s',kind,v.X,v.Y,v.Z,c.Position.X,c.Position.Y,c.Position.Z,table.concat(c.r,','),tostring(s.Shape),tostring(s.Transparency)))
 end
end
'''
import sys
sys.path.insert(0,str(ROOT/'tools'))
from world_spec import records
source=source.replace('KINDS',','.join(json.dumps(g['kind']) for g in records()))
f=Path('/tmp/mv-export-icons.luau');f.write_text(source)
output=subprocess.check_output(['/tmp/trophy-luau/luau',str(f)],text=True)
result={}
for line in output.splitlines():
 kind,size,pos,rot,shape,alpha=line.split('|')
 result.setdefault(kind,[]).append(dict(size=list(map(float,size.split(','))),position=list(map(float,pos.split(','))),rotation=list(map(float,rot.split(','))),shape=int(shape),alpha=float(alpha)))
assert len(result)==50
(ROOT/'assets/trophy-shapes.json').write_text(json.dumps(result,separators=(',',':'))+'\n')
print('Exported 50 trophy skeletons from the actual Luau icon source')

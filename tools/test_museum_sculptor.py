"""Exercise real runtime trophy construction in Luau API doubles, distinct from physics tests."""
from pathlib import Path
import subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]
def run(luau):
 fixture=(ROOT/'tools/runtime_fixture.luau').read_text().replace('-- ROBLOX_MATH_INSERT',(ROOT/'tools/roblox_math.luau').read_text())
 # Matrix constructor and transform methods used by the museum sculptor.
 fixture=fixture.replace('function CFrame.new(x,y,z) return cf(type(x)==\'table\' and x or Vector3.new(x,y,z)) end',"function CFrame.new(x,y,z,...) local r={...}; return cf(type(x)=='table' and x or Vector3.new(x,y,z),#r==9 and r or nil) end")
 fixture=fixture.replace("if k=='Position' then return v.p end", "if k=='Position' then return v.p end\n if k=='VectorToWorldSpace' then return function(a,b) return rotate(a.r,b) end end")
 source=fixture+'\nlocal B=(function()\n'+(ROOT/'src/museum/Blueprint.lua').read_text()+'\nend)()\n'
 source+='''
Enum.Material={GetEnumItems=function() local t={};for _,v in ipairs({1344,1360,896,1088,1040,1568,784,788,1536,288,800,816,528,832})do table.insert(t,{Value=v})end;return t end}
local script={Parent={WaitForChild=function()return 'Blueprint'end}}
local require=function()return B end
local Sculpt=(function()
'''+(ROOT/'src/museum/TrophySculptor.lua').read_text()+'''\nend)()
local collection=Instance.new('Folder')
local count=0;local minimum=100000;local maximum=0
for _,e in ipairs(B.exhibits)do
 local model=Sculpt.build(collection,e)
 local body=#model.Body:GetChildren();assert(body>=1000,'Body below minimum: '..e.key)
 assert(body==model.BodyPartCount.Value,'Body metadata does not match physical construction')
 assert(#model.Animation:GetChildren()>0,'Missing geometric animation layer')
 minimum=math.min(minimum,body);maximum=math.max(maximum,body);count+=1
 if e.mutation=='ghost'then assert(model.Body:GetChildren()[1].Color.B>model.Body:GetChildren()[1].Color.R,'Ghost must be pale blue, not pink')end
 if e.mutation=='galaxy'then assert(#model.Animation:GetChildren()>=200,'Galaxy needs physical orbits and stars')end
 model:Destroy()
end
assert(count==74,'Exhibit catalog incomplete')
print('PASS: real runtime sculptor builds '..count..' distinct exhibits; body count '..minimum..'–'..maximum..'; geometric animation layers and separate mutations')
'''
 with tempfile.TemporaryDirectory(prefix='museum-luau-')as d:
  f=Path(d)/'sculptor.luau';f.write_text(source);subprocess.run([luau,str(f)],check=True)
if __name__=='__main__':run('/tmp/trophy-luau/luau')

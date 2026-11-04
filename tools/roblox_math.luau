-- Mathematical Roblox types for logic tests. No collision solver or rendering.
local Vector3={}; local vmt={}
function Vector3.new(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vmt) end
Vector3.zero=Vector3.new(); Vector3.one=Vector3.new(1,1,1)
vmt.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vmt.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vmt.__mul=function(a,b) if type(a)=='number' then a,b=b,a end; return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
vmt.__div=function(a,b) return a*(1/b) end
vmt.__unm=function(a) return a*(-1) end
vmt.__index=function(v,k)
 if k=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
 if k=='Unit' then return v.Magnitude==0 and Vector3.zero or v/v.Magnitude end
 if k=='Dot' then return function(a,b) return a.X*b.X+a.Y*b.Y+a.Z*b.Z end end
 if k=='Lerp' then return function(a,b,t) return a+(b-a)*t end end
end
local CFrame={}; local cmt={}; local identity={1,0,0,0,1,0,0,0,1}
local function cf(p,r) return setmetatable({p=p,r=r or table.clone(identity)},cmt) end
function CFrame.new(x,y,z) return cf(type(x)=='table' and x or Vector3.new(x,y,z)) end
local function rotate(r,v) return Vector3.new(r[1]*v.X+r[2]*v.Y+r[3]*v.Z,r[4]*v.X+r[5]*v.Y+r[6]*v.Z,r[7]*v.X+r[8]*v.Y+r[9]*v.Z) end
function CFrame.Angles(x,y,z)
 local cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
 return cf(Vector3.zero,{cy*cz,-cy*sz,sy,cx*sz+sx*sy*cz,cx*cz-sx*sy*sz,-sx*cy,sx*sz-cx*sy*cz,sx*cz+cx*sy*sz,cx*cy})
end
function CFrame.lookAt(pos,target) local d=target-pos; local yaw=math.atan2(-d.X,-d.Z); local a=CFrame.Angles(0,yaw,0); a.p=pos; return a end
cmt.__mul=function(a,b)
 local r={}; for row=0,2 do for col=0,2 do local n=0; for k=0,2 do n+=a.r[row*3+k+1]*b.r[k*3+col+1] end; r[row*3+col+1]=n end end
 return cf(a.p+rotate(a.r,b.p),r)
end
cmt.__add=function(a,b) return cf(a.p+b,a.r) end
cmt.__index=function(v,k)
 if k=='Position' then return v.p end
 if k=='LookVector' then return Vector3.new(-v.r[3],-v.r[6],-v.r[9]) end
 if k=='PointToWorldSpace' then return function(a,b) return a.p+rotate(a.r,b) end end
 if k=='PointToObjectSpace' then return function(a,b) local p=b-a.p; return Vector3.new(p.X*a.r[1]+p.Y*a.r[4]+p.Z*a.r[7],p.X*a.r[2]+p.Y*a.r[5]+p.Z*a.r[8],p.X*a.r[3]+p.Y*a.r[6]+p.Z*a.r[9]) end end
 if k=='Lerp' then return function(a,b,t) return cf(a.p:Lerp(b.p,t),t>.5 and b.r or a.r) end end
end

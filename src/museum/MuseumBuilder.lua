local B=require(script.Parent:WaitForChild('MuseumBlueprint'))
local Sculpt=require(script.Parent:WaitForChild('TrophySculptor'))
local M={}
local mats={};for _,m in ipairs(Enum.Material:GetEnumItems()) do mats[m.Value]=m end
local function v(t)return Vector3.new(t[1],t[2],t[3])end
local function h(x,y,s)return ((x*374761393+y*668265263+s*69069)%65536)/65535 end
function M.build(world,progress)
 if world:WaitForChild('FullGeometryPresent').Value then return 0 end
 local created=0;local last=0;local architectureCreated=0
 local function yieldParts(n)
  created+=n
  if created-last>=512 then last=created;progress(created);task.wait() end
 end
 for _,e in ipairs(B.exhibits) do if not world.Exhibits:FindFirstChild('Exhibit_'..e.key) then Sculpt.build(world.Exhibits,e,yieldParts) end end
 for _,g in ipairs(B.grids) do
  local origin,du,dv=v(g.origin),v(g.du),v(g.dv)
  for u0=0,g.nx-1,16 do for v0=0,g.ny-1,16 do
   local chunk=Instance.new('Model');chunk.Name=g.role..'_'..g.floor..'_'..u0..'_'..v0;chunk.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
   for u=u0,math.min(u0+15,g.nx-1) do for w=v0,math.min(v0+15,g.ny-1) do
    local pos=origin+du*(u+.5)+dv*(w+.5);local skip=false
    for _,r in ipairs(g.skip or {}) do if pos.X>=r[1] and pos.X<=r[2] and pos.Y>=r[3] and pos.Y<=r[4] and pos.Z>=r[5] and pos.Z<=r[6] then skip=true;break end end
    if not skip then
     local base,material
     if g.role=='FloorTessera' then
      local border=math.min(240-math.abs(pos.X),192-math.abs(pos.Z))<5;local central=math.abs(pos.X)<28;local ring=math.floor(math.sqrt(pos.X^2+(pos.Z*.85)^2)/6)%5==0
      local bronze=border and (u+w)%4==0 or central and math.floor(math.abs(pos.X)/1.5)%12==0 or math.abs(pos.Z%36)<1.5 and math.abs(pos.X)>36
      base=bronze and {164,128,63} or central and {123,134,119} or ring and {180,172,150} or {157,152,132};material=bronze and 1088 or 784
     elseif g.role=='CeilingCoffer' then local line=u%16==0 or u%16==15 or w%16==0 or w%16==15;base=line and {136,111,62} or {201,194,169};material=line and 1088 or 784
     else base={171,161,136};material=832 end
     local variation=(h(u,w,g.floor+3)-.5)*10;local p=Instance.new('Part');p.Name=g.role;p.Size=v(g.size);p.Position=pos;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Material=mats[material];p.Color=Color3.fromRGB(math.clamp(base[1]+variation,0,255),math.clamp(base[2]+variation,0,255),math.clamp(base[3]+variation,0,255));p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=chunk;architectureCreated+=1;yieldParts(1)
    end
   end end
   chunk.Parent=world.DetailChunks
  end end
 end
 world.ArchitecturePartCount.Value+=architectureCreated;world.FullGeometryPresent.Value=true;progress(created,true);return created
end
return M

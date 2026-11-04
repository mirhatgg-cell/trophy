-- A small deterministic harness for server lifecycle checks, NOT Roblox physics.
local clock=0
local queue={}
local failures={}
local sequence=0
local function schedule(co,at,...)
 sequence+=1; table.insert(queue,{co=co,at=at,args={...},order=sequence})
end
local task={}
function task.spawn(fn,...) schedule(coroutine.create(fn),clock,...) end
function task.delay(delay,fn,...) schedule(coroutine.create(fn),clock+delay,...) end
function task.wait(delay) return coroutine.yield(delay or .03) end
local function advance(duration)
 local deadline=clock+duration
 while true do
  table.sort(queue,function(a,b) return a.at==b.at and a.order<b.order or a.at<b.at end)
  if not queue[1] or queue[1].at>deadline then break end
  local job=table.remove(queue,1); clock=job.at
  local ok,delay=coroutine.resume(job.co,table.unpack(job.args))
  if not ok then error(delay) end
  if coroutine.status(job.co)~='dead' then schedule(job.co,clock+(delay or .03)) end
 end
 clock=deadline
end
local os={clock=function() return clock end}
local function signal()
 local handlers={}
 return {Connect=function(_,fn) table.insert(handlers,fn); return {Disconnect=function() end} end,
 Fire=function(_,...) for _,fn in ipairs(handlers) do fn(...) end end,
 Wait=function() task.wait(.01) end}
end
local Vector3={}
local vmt={}
function Vector3.new(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vmt) end
Vector3.zero=Vector3.new()
vmt.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vmt.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vmt.__mul=function(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
vmt.__index=function(v,key)
 if key=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
 if key=='Unit' then return v*(1/v.Magnitude) end
end
local CFrame={new=function(v) return v end}
local Color3={fromRGB=function(r,g,b) return {R=r/255,G=g/255,B=b/255} end,new=function(r,g,b) return {R=r,G=g,B=b} end}
local ColorSequence={new=function(x) return x end}
local NumberSequence={new=function(x) return x end}
local NumberSequenceKeypoint={new=function(...) return {...} end}
local NumberRange={new=function(...) return {...} end}
local UDim2={fromOffset=function(...) return {...} end,fromScale=function(...) return {...} end}
local Enum=setmetatable({},{__index=function(t,k) local v=setmetatable({},{__index=function(_,n) return n end}); rawset(t,k,v); return v end})
local TweenInfo={new=function(...) return {...} end}
-- Luau CLI has no Roblox Random; provide reproducible next methods.
local Random={new=function() return {
 NextNumber=function(_,a,b) local r=math.random(); return a and (a+(b-a)*r) or r end,
 NextInteger=function(_,a,b) return math.random(a,b) end,
} end}
math.randomseed(27)
local objects={}
local methods={}
local mt={__index=function(o,k)
 if methods[k]~=nil then return methods[k] end
 if o._props[k]~=nil then return o._props[k] end
 for _,child in ipairs(o._children) do if child.Name==k then return child end end
end,
 __newindex=function(o,k,v)
  if k=='Parent' then
   local old=o._props.Parent
   if old then local i=table.find(old._children,o); if i then table.remove(old._children,i) end end
   o._props.Parent=v; if v then table.insert(v._children,o) end
  else o._props[k]=v end
 end}
local Instance={new=function(class,parent)
 local obj=setmetatable({_props={ClassName=class,Name=class,Size=Vector3.new(1,1,1),Position=Vector3.zero,CanCollide=true,Health=100,MaxHealth=100,AssemblyLinearVelocity=Vector3.zero},_attributes={},_children={}},mt)
 for _,name in ipairs({'Touched','Triggered','CharacterAdded','OnServerEvent','Heartbeat','PlayerAdded','PlayerRemoving'}) do obj[name]=signal() end
 table.insert(objects,obj); obj.Parent=parent; return obj
end}
function methods:GetChildren() return table.clone(self._children) end
function methods:GetDescendants() local result={}; for _,o in ipairs(self:GetChildren()) do table.insert(result,o); for _,d in ipairs(o:GetDescendants()) do table.insert(result,d) end end; return result end
function methods:FindFirstChild(name) for _,o in ipairs(self:GetChildren()) do if o.Name==name then return o end end end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name),'Missing '..name) end
function methods:FindFirstChildWhichIsA(class) for _,o in ipairs(self:GetChildren()) do if o:IsA(class) then return o end end end
methods.FindFirstChildOfClass=methods.FindFirstChildWhichIsA
function methods:IsA(class) return self.ClassName==class or class=='BasePart' and (self.ClassName=='Part' or self.ClassName=='SpawnLocation') end
function methods:SetAttribute(k,v) self._attributes[k]=v end
function methods:GetAttribute(k) return self._attributes[k] end
function methods:ClearAllChildren() for _,o in ipairs(self:GetChildren()) do o:Destroy() end end
function methods:Destroy() self:ClearAllChildren(); self.Parent=nil end
function methods:PivotTo(pos)
 if self.ClassName=='Model' then
  local anchor=self.PrimaryPart or self:FindFirstChild('HumanoidRootPart') or self:FindFirstChildWhichIsA('BasePart')
  if anchor then local delta=pos-anchor.Position; for _,o in ipairs(self:GetDescendants()) do if o:IsA('BasePart') then o.Position+=delta end end end
 else self.Position=pos end
end
function methods:GetPivot() return self.PrimaryPart and self.PrimaryPart.Position or Vector3.zero end
function methods:TakeDamage(n) self.Health=math.max(0,self.Health-n) end
function methods:IsFriendsWithAsync() return false end
local Players=Instance.new('Players')
local RS=Instance.new('ReplicatedStorage')
local workspace=Instance.new('Workspace')
local remote=Instance.new('RemoteEvent',RS); remote.Name='TrophyEvent'; remote.messages={}
function methods:FireClient(player,kind,data) table.insert(self.messages,{player=player,kind=kind,data=data}) end
local catalogInstance=Instance.new('ModuleScript',RS); catalogInstance.Name='Catalog'
local RunService={Heartbeat=signal(),studio=true,IsStudio=function(self) return self.studio end}
local store={data={}}
function store:GetAsync(key) return self.data[key] end
function store:UpdateAsync(key,fn) self.data[key]=fn(self.data[key]); return self.data[key] end
local DS={GetDataStore=function() return store end}
local TweenService={Create=function(_,obj,_,props) return {Play=function() for k,v in pairs(props) do obj[k]=v end end,Completed=signal()} end}
local Debris={AddItem=function(_,obj,delay) task.delay(delay,function() obj:Destroy() end) end}
function methods:GetPlayers() return self:GetChildren() end
function methods:GetPlayerByUserId(id) for _,p in ipairs(self:GetPlayers()) do if p.UserId==id then return p end end end
function methods:GetPlayerFromCharacter(char) for _,p in ipairs(self:GetPlayers()) do if p.Character==char then return p end end end
function methods:LoadCharacterAsync()
 local char=Instance.new('Model',workspace); self.Character=char
 local root=Instance.new('Part',char); root.Name='HumanoidRootPart'; root.Position=Vector3.new(0,5,0)
 local head=Instance.new('Part',char); head.Name='Head'; head.Position=Vector3.new(0,7,0)
 Instance.new('Humanoid',char)
 self.CharacterAdded:Fire(char)
 return char
end
local services={Players=Players,ReplicatedStorage=RS,DataStoreService=DS,RunService=RunService,TweenService=TweenService,Debris=Debris}
local game={CreatorType='User',CreatorId=42,GetService=function(_,name) return assert(services[name],name) end,BindToClose=function() end}
local function warn(message) table.insert(failures,message) end

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
 Fire=function(_,...) for _,fn in ipairs(handlers) do task.spawn(fn,...) end end,
 Wait=function() task.wait(.01) end}
end
-- ROBLOX_MATH_INSERT
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
  elseif k=='Position' then o._props.Position=v; local old=o._props.CFrame or CFrame.new(); o._props.CFrame=CFrame.new(v)*CFrame.Angles(0,0,0); o._props.CFrame.r=old.r
  elseif k=='CFrame' then o._props.CFrame=v; o._props.Position=v.Position
  else o._props[k]=v end
 end}
local Instance={new=function(class,parent)
 local obj=setmetatable({_props={ClassName=class,Name=class,Size=Vector3.new(1,1,1),Position=Vector3.zero,CanCollide=true,Health=100,MaxHealth=100,CFrame=CFrame.new(),AssemblyLinearVelocity=Vector3.zero},_attributes={},_children={}},mt)
 for _,name in ipairs({'Touched','Triggered','CharacterAdded','OnServerEvent','Heartbeat','PlayerAdded','PlayerRemoving','Activated'}) do obj[name]=signal() end
 table.insert(objects,obj); obj.Parent=parent; return obj
end}
function methods:GetChildren() return table.clone(self._children) end
function methods:GetDescendants() local result={}; for _,o in ipairs(self:GetChildren()) do table.insert(result,o); for _,d in ipairs(o:GetDescendants()) do table.insert(result,d) end end; return result end
function methods:FindFirstChild(name,recursive) for _,o in ipairs(recursive and self:GetDescendants() or self:GetChildren()) do if o.Name==name then return o end end end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name),'Missing '..name) end
function methods:FindFirstChildWhichIsA(class) for _,o in ipairs(self:GetChildren()) do if o:IsA(class) then return o end end end
methods.FindFirstChildOfClass=methods.FindFirstChildWhichIsA
function methods:IsA(class) return self.ClassName==class or class=='BasePart' and (self.ClassName=='Part' or self.ClassName=='SpawnLocation') end
function methods:SetAttribute(k,v) self._attributes[k]=v end
function methods:GetAttribute(k) return self._attributes[k] end
function methods:ClearAllChildren() for _,o in ipairs(self:GetChildren()) do o:Destroy() end end
function methods:Destroy() self:ClearAllChildren(); self.Parent=nil end
function methods:PivotTo(pos)
 local cf=pos; pos=pos.Position
 if self.ClassName=='Model' then
  local anchor=self.PrimaryPart or self:FindFirstChild('HumanoidRootPart') or self:FindFirstChildWhichIsA('BasePart')
  if anchor then local delta=pos-anchor.Position; for _,o in ipairs(self:GetDescendants()) do if o:IsA('BasePart') then o.Position+=delta end end end
 else self.Position=pos end
end
function methods:GetPivot() local anchor=self.PrimaryPart or self:FindFirstChild('HumanoidRootPart'); return anchor and anchor.CFrame or CFrame.new() end
function methods:Clone()
 local map={}
 local function clone(old,parent) local c=Instance.new(old.ClassName,parent); map[old]=c; for k,v in pairs(old._props) do if k~='Parent' and k~='PrimaryPart' and k~='Touched' and k~='Triggered' and k~='CharacterAdded' and k~='OnServerEvent' and k~='Heartbeat' and k~='PlayerAdded' and k~='PlayerRemoving' then c[k]=v end end; for _,child in ipairs(old:GetChildren()) do clone(child,c) end; return c end
 local result=clone(self); for old,c in pairs(map) do if old.PrimaryPart then c.PrimaryPart=map[old.PrimaryPart] end end; return result
end
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
local DS={fail=false,GetDataStore=function(self) if self.fail then error('Publish this place before accessing DataStore') end; return store end}
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
local ServerStorage=Instance.new('ServerStorage')
local worldMap=Instance.new('Folder',workspace); worldMap.Name='WorldMap'
local lobbyFixture=Instance.new('Model',worldMap); lobbyFixture.Name='Lobby'
for i=1,4 do local pad=Instance.new('Part',lobbyFixture); pad.Name='Queue'..i; pad.Position=Vector3.new((i-2.5)*25,0,-18) end
local liftFixture=Instance.new('Model',lobbyFixture); liftFixture.Name='Lift'
local cabFixture=Instance.new('Part',liftFixture); cabFixture.Name='Cabin'; cabFixture.Position=Vector3.new(0,.5,0); cabFixture.Size=Vector3.new(12,1,12)
local upperFixture=Instance.new('Part',liftFixture); upperFixture.Name='UpperStop'; upperFixture.Position=Vector3.new(16,31,0)
local lowerFixture=Instance.new('Part',liftFixture); lowerFixture.Name='LowerStop'; lowerFixture.Position=Vector3.new(16,0,0)
local museumFixture=Instance.new('Model',ServerStorage); museumFixture.Name='MuseumTemplate'
local anchor=Instance.new('Part',museumFixture); anchor.Name='MuseumAnchor'; museumFixture.PrimaryPart=anchor
local exit=Instance.new('Part',museumFixture); exit.Name='MuseumExit'
for i=1,50 do local stand=Instance.new('Part',museumFixture); stand.Name='Stand'..i; stand.Position=Vector3.new(i,0,0) end
local services={ServerStorage=ServerStorage,Players=Players,ReplicatedStorage=RS,DataStoreService=DS,RunService=RunService,TweenService=TweenService,Debris=Debris}
local game={CreatorType='User',CreatorId=42,GetService=function(_,name) return assert(services[name],name) end,BindToClose=function() end}
local function warn(message) table.insert(failures,message) end

local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local B=require(RS:WaitForChild('MuseumBlueprint'))
local Builder=require(RS:WaitForChild('MuseumBuilder'))
local remote=RS:WaitForChild('MuseumEvent')
local world=workspace:WaitForChild('MuseumWorld')
local activeFloor={}
local lastRequest={}
local function root(p)return p.Character and p.Character:FindFirstChild('HumanoidRootPart')end
local function toast(p,text)if p.Parent==Players then remote:FireClient(p,'toast',text)end end
local function state(p)
 remote:FireClient(p,'state',{build=B.build,ready=world.FullGeometryPresent.Value,created=world:GetAttribute('CreatedDetailParts') or 0,architecture=world:FindFirstChild('ArchitecturePartCount') and world.ArchitecturePartCount.Value or 0,trophies=#world.Exhibits:GetChildren()})
end
local function travel(p,pos)
 local r=root(p);local hum=p.Character and p.Character:FindFirstChildOfClass('Humanoid');if not r or not hum or hum.Health<=0 then return end
 r.Anchored=true
 if workspace.StreamingEnabled then pcall(function()p:RequestStreamAroundAsync(pos,4)end)end
 if not r.Parent then return end
 p.Character:PivotTo(CFrame.new(pos)*CFrame.Angles(0,0,0));r.AssemblyLinearVelocity=Vector3.zero;r.Anchored=false
end
local function prompt(part,text,fn)
 local q=Instance.new('ProximityPrompt');q.Name='MuseumInteraction';q.ActionText=text;q.ObjectText=part.Name;q.MaxActivationDistance=12;q.HoldDuration=0;q.RequiresLineOfSight=false;q.Parent=part
 q.Triggered:Connect(function(p)local r=root(p);if r and (r.Position-part.Position).Magnitude<=16 then fn(p)end end)
 return q
end
for _,lift in ipairs(world.Lifts:GetChildren())do
 local cabin=lift:WaitForChild('Cabin');local platform=cabin:WaitForChild('Platform');local bottom=platform.Position;local at=0;local busy=false
 local function gates(floor,open)
  for _,side in ipairs({-1,1})do
   local door=lift:FindFirstChild('Door'..floor..'_'..side)
   if door then Tween:Create(door,TweenInfo.new(.3),{CFrame=CFrame.new(bottom.X+side*(open and 17.5 or 5.5),floor*28+7.12,199.5)}):Play()end
  end
 end
 local function cabinGate(open)
  for _,v in ipairs({{'GateLeft',-1},{'GateRight',1}})do local door=cabin:FindFirstChild(v[1]);if door then Tween:Create(door,TweenInfo.new(.3),{CFrame=CFrame.new(platform.Position.X+v[2]*(open and 16.6 or 5.2),platform.Position.Y+5.1,199.2)}):Play()end end
 end
 local function doorwayClear(floor)
  for _,p in ipairs(Players:GetPlayers())do local r=root(p)
   if r and math.abs(r.Position.X-bottom.X)<9 and math.abs(r.Position.Z-199.5)<2.5 and math.abs(r.Position.Y-(floor*28+4))<5 then return false end
  end;return true
 end
 local function move(p,target)
  if busy or target<0 or target>2 then return end
  if target==at then gates(at,true);cabinGate(true);return end
  if not doorwayClear(at)then toast(p,'Освободите дверной проём лифта');return end
  busy=true;gates(at,false);cabinGate(false)
  task.spawn(function()
   task.wait(.4)
   local from=platform.Position;local to=bottom+Vector3.new(0,target*28,0);local duration=math.max(3,(to-from).Magnitude/10);local start=os.clock();local originals={}
   for _,part in ipairs(cabin:GetChildren())do if part:IsA('BasePart')then originals[part]=platform.CFrame:ToObjectSpace(part.CFrame)end end
   local riders={}
   for _,who in ipairs(Players:GetPlayers())do local r=root(who)
    if r and math.abs(r.Position.X-from.X)<9.9 and math.abs(r.Position.Z-from.Z)<8.6 and r.Position.Y>from.Y and r.Position.Y<from.Y+8 then riders[who]=true end
   end
   while platform.Parent and os.clock()-start<duration do
    local a=math.clamp((os.clock()-start)/duration,0,1);a=a*a*(3-2*a);local pos=from:Lerp(to,a);local delta=pos-platform.Position
    for who in pairs(riders)do local r=root(who);if r and math.abs(r.Position.X-platform.Position.X)<10 and math.abs(r.Position.Z-platform.Position.Z)<8.7 then who.Character:PivotTo(who.Character:GetPivot()+delta)end end
    local base=CFrame.new(pos);for part,relative in pairs(originals)do if part.Parent then part.CFrame=base*relative end end
    Run.Heartbeat:Wait()
   end
   local delta=to-platform.Position
   for who in pairs(riders)do if root(who)then who.Character:PivotTo(who.Character:GetPivot()+delta)end end
   for part,relative in pairs(originals)do if part.Parent then part.CFrame=CFrame.new(to)*relative end end
   at=target;activeFloor[p]=target;gates(at,true);cabinGate(true);busy=false
  end)
 end
 for floor=0,2 do local call=lift:FindFirstChild('Call'..floor);if call then prompt(call,'Вызвать лифт / этаж '..(floor+1),function(p)move(p,floor)end)end end
 for floor=0,2 do
  local button=Instance.new('Part');button.Name='FloorButton'..floor;button.Size=Vector3.new(.2,1,1);button.CFrame=CFrame.new(bottom.X+8.6,2.5+floor*1.4,212);button.Anchored=true;button.CanCollide=false;button.CanTouch=false;button.Color=Color3.fromRGB(204,171,91);button.Material=Enum.Material.Metal;button.Parent=cabin
  local q=prompt(button,'Этаж '..(floor+1)..' / клавиша '..(floor+1),function(p)move(p,floor)end)
  q.KeyboardKeyCode=({Enum.KeyCode.One,Enum.KeyCode.Two,Enum.KeyCode.Three})[floor+1];q.Exclusivity=Enum.ProximityPromptExclusivity.AlwaysShow;q.UIOffset=Vector2.new(0,(floor-1)*54)
 end
 gates(0,true);cabinGate(true)
end
local function bindExhibit(model)
 local key=string.sub(model.Name,9);local stand=world.Pedestals:FindFirstChild('Stand_'..key);local plate=stand and stand:FindFirstChild('ExhibitLabel')
 if plate then prompt(plate,'Осмотреть экспонат',function(p)
  remote:FireClient(p,'inspect',{name=key,kind=model.Kind.Value,level=model.Level.Value,mutation=model.Mutation.Value,bodyParts=model.BodyPartCount.Value})
 end)end
end
for _,m in ipairs(world.Exhibits:GetChildren())do bindExhibit(m)end
world.Exhibits.ChildAdded:Connect(bindExhibit)
local destinations={entry=Vector3.new(0,5,174),floor1=Vector3.new(0,5,150),floor2=Vector3.new(0,33,150),floor3=Vector3.new(0,61,150),tiers=Vector3.new(0,61,-90),mutations=Vector3.new(0,5,153)}
remote.OnServerEvent:Connect(function(p,action,data)
 if type(action)~='string'then return end
 local now=os.clock();local rate=lastRequest[p]or{};lastRequest[p]=rate;if now-(rate[action]or-10)<.5 then return end;rate[action]=now
 if action=='sync'then state(p)
 elseif action=='travel'and type(data)=='string'and destinations[data]then travel(p,destinations[data])end
end)
local function joined(p)
 p.CharacterAdded:Connect(function(char)
  local r=char:WaitForChild('HumanoidRootPart',12);if not r then return end
  local hum=char:FindFirstChildOfClass('Humanoid');if hum then hum.WalkSpeed=20;hum.UseJumpPower=true;hum.JumpPower=50 end
  task.wait(.1);travel(p,destinations.entry);state(p)
 end)
 if p.Character then travel(p,destinations.entry)end
end
Players.PlayerAdded:Connect(joined);for _,p in ipairs(Players:GetPlayers())do joined(p)end
Players.PlayerRemoving:Connect(function(p)lastRequest[p]=nil;activeFloor[p]=nil end)
task.spawn(function()
 local ok,err=pcall(function()Builder.build(world,function(created,done)
  world:SetAttribute('CreatedDetailParts',created)
  for _,p in ipairs(Players:GetPlayers())do state(p)end
 end)end)
 if not ok then warn('Museum detail builder: '..tostring(err));world:SetAttribute('BuildError',tostring(err));for _,p in ipairs(Players:GetPlayers())do toast(p,'Ошибка детализации: '..tostring(err))end end
end)
task.spawn(function()while true do task.wait(1);for _,p in ipairs(Players:GetPlayers())do local r=root(p);if r and r.Position.Y< -15 then travel(p,destinations.entry);toast(p,'Возврат на входную площадку')end end end end)
workspace:SetAttribute('MuseumBuild',B.build);workspace:SetAttribute('MuseumReady',true)
print(B.build..' museum-only scene ready; no trial scripts running')

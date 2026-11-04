local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local DS = game:GetService('DataStoreService')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local Debris = game:GetService('Debris')
local C = require(RS:WaitForChild('Catalog'))
local remote = RS:WaitForChild('TrophyEvent')
local TrophyIcons=require(RS:WaitForChild('TrophyIcons'))
local Trials=require(RS:WaitForChild('Trials'))
local Elimination=require(RS:WaitForChild('Elimination'))
local Infrastructure=require(RS:WaitForChild('Infrastructure'))
local ServerStorage=game:GetService('ServerStorage')
local rng = Random.new()
local profiles, bases, sessions, pods, cooldowns, loading = {}, {}, {}, {}, {}, {}
local store
local storeOK, storeResult=pcall(function() return DS:GetDataStore('Mountainverse_v1') end)
if storeOK then store=storeResult else warn('Persistence unavailable; offline play remains enabled: '..tostring(storeResult)) end
local preview=workspace:FindFirstChild('PreviewScene'); if preview then preview:Destroy() end
local world = Instance.new('Folder',workspace); world.Name='MountainverseRuntime'
local map=workspace:WaitForChild('WorldMap')
local lobby=map:WaitForChild('Lobby')
local matches = Instance.new('Folder',world); matches.Name='Matches'
local baseSlot, matchId = 0,0
local activeSlots={}
local startMatch, joinPod, updateBase, sync, achievements
local function part(parent,name,size,pos,color,material)
 local p=Instance.new('Part'); p.Name=name; p.Size=size; p.Position=pos; p.Color=color or Color3.fromRGB(60,70,93)
 p.Anchored=true; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
 p.Material=material or Enum.Material.SmoothPlastic; p.Parent=parent; return p
end
local function label(p,text,size)
 local gui=Instance.new('BillboardGui'); gui.Name='Label'; gui.Size=UDim2.fromOffset(math.min(size or 180,200),48)
 gui.StudsOffset=Vector3.new(0,p.Size.Y/2+2,0); gui.MaxDistance=45; gui.Parent=p
 local t=Instance.new('TextLabel',gui); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1
 t.Text=text; t.TextColor3=Color3.new(1,1,1); t.TextStrokeTransparency=.45; t.TextSize=12; t.Font=Enum.Font.GothamBold; t.TextWrapped=true
 return t
end
local function prompt(p,text,callback)
 local q=Instance.new('ProximityPrompt',p); q.ActionText=text; q.ObjectText=p.Name; q.HoldDuration=0; q.MaxActivationDistance=15
 q.Triggered:Connect(function(player)
  local r=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
  if r and (r.Position-p.Position).Magnitude<18 then callback(player) end
 end); return q
end
local function send(p,kind,data) if p and p.Parent==Players then remote:FireClient(p,kind,data) end end
local function toast(p,text) send(p,'toast',text) end
local function admin(p)
 if RunService:IsStudio() or C.PublicTestAdmin then return true end
 if game.CreatorType==Enum.CreatorType.User and p.UserId==game.CreatorId then return true end
 return table.find(C.AdminUserIds,p.UserId)~=nil
end
local function newProfile()
 return {coins=0,wins=0,runs=0,trophies={},owned={},equipped={},achievements={},titles={},title='',mutationCount=0}
end
local function sanitize(data)
 local p=newProfile()
 if type(data)~='table' then return p end
 for _,key in ipairs({'coins','wins','runs','mutationCount'}) do
  if type(data[key])=='number' and data[key]==data[key] then p[key]=math.clamp(math.floor(data[key]),0,100000000) end
 end
 for i=1,#C.Games do
  local t=type(data.trophies)=='table' and data.trophies[tostring(i)]
  if type(t)=='table' then
   local w=tonumber(t.wins) or 0
   if w==w then p.trophies[tostring(i)]={wins=math.clamp(math.floor(w),0,1000000),mutation=table.find({'Золотоносная','Призрачная','Галактическая'},t.mutation) and t.mutation or nil} end
  end
 end
 for _,item in ipairs(C.Shop) do if type(data.owned)=='table' and data.owned[item.id]==true then p.owned[item.id]=true end end
 for _,a in ipairs(C.Achievements) do
  if type(data.achievements)=='table' and data.achievements[a.id]==true then p.achievements[a.id]=true; p.titles[a.title]=true end
 end
 for _,item in ipairs(C.Shop) do if item.kind=='title' and p.owned[item.id] then p.titles[item.text]=true end end
 if type(data.equipped)=='table' then
  for _,item in ipairs(C.Shop) do if p.owned[item.id] and data.equipped[item.kind]==item.id then p.equipped[item.kind]=item.id end end
 end
 if p.titles[data.title] then p.title=data.title end
 return p
end
sync=function(p)
 local d=profiles[p]; if not d then return end
 local stats=p:FindFirstChild('leaderstats')
 if stats then stats['Победы'].Value=d.wins; stats['Монеты'].Value=d.coins end
 send(p,'profile',{data=d,admin=admin(p),persistent=p:GetAttribute('Persistence')==true})
end
achievements=function(p)
 local d=profiles[p]; if not d then return end
 local unique=0; for _,t in pairs(d.trophies) do if t.wins>0 then unique+=1 end end
 local values={wins=d.wins,runs=d.runs,unique=unique,mutations=d.mutationCount}
 for _,a in ipairs(C.Achievements) do
  if not d.achievements[a.id] and values[a.field]>=a.goal then
   d.achievements[a.id]=true; d.titles[a.title]=true; d.coins+=a.reward; toast(p,'Достижение: '..a.name..'  +'..a.reward)
  end
 end
end
local function applyCosmetics(p)
 local d=profiles[p]; local char=p.Character
 if not d or not char then return end
 local old=char:FindFirstChild('TrophyCosmetics'); if old then old:Destroy() end
 local folder=Instance.new('Folder',char); folder.Name='TrophyCosmetics'
 local root=char:FindFirstChild('HumanoidRootPart'); local head=char:FindFirstChild('Head')
 if not root or not head then return end
 for kind,id in pairs(d.equipped) do
  local item; for _,v in ipairs(C.Shop) do if v.id==id then item=v; break end end
  if item and kind=='trail' then
   local a=Instance.new('Attachment',folder); a.Parent=root; a.Name='TrophyTrailA'; a.Position=Vector3.new(-.6,0,0)
   local b=Instance.new('Attachment',folder); b.Parent=root; b.Name='TrophyTrailB'; b.Position=Vector3.new(.6,0,0)
   local tr=Instance.new('Trail',folder); tr.Attachment0=a; tr.Attachment1=b; tr.Color=ColorSequence.new(item.color); tr.Lifetime=.6
   -- Attachments are removed explicitly before each cosmetic refresh.
  elseif item and kind=='hat' then
   local hat=part(folder,item.name,Vector3.new(2.5,.45,2.5),head.Position+Vector3.new(0,1.2,0),item.color,Enum.Material.Neon)
   if id=='hat_orbit' then hat.Shape=Enum.PartType.Ball; hat.Size=Vector3.new(.9,.9,.9) end
   hat.Anchored=false; hat.CanCollide=false; hat.Massless=true
   local weld=Instance.new('WeldConstraint',hat); weld.Part0=head; weld.Part1=hat
  elseif item and kind=='aura' then
   local spark=Instance.new('Sparkles',folder); spark.Parent=root; spark.Name='TrophySparkles'; spark.SparkleColor=item.color
  end
 end
 local name=label(head,d.title~='' and (p.DisplayName..' · '..d.title) or p.DisplayName); name.Parent.Name='TrophyName'
end
local function refreshCosmetics(p)
 if p.Character then
  for _,v in ipairs(p.Character:GetDescendants()) do
   if v.Name=='TrophyTrailA' or v.Name=='TrophyTrailB' or v.Name=='TrophySparkles' or v.Name=='TrophyName' then v:Destroy() end
  end
 end
 applyCosmetics(p)
end
local function teleport(p,pos)
 local char=p.Character; local root=char and char:FindFirstChild('HumanoidRootPart'); local hum=char and char:FindFirstChildOfClass('Humanoid')
 if root and hum and hum.Health>0 then
  if workspace.StreamingEnabled then pcall(function() p:RequestStreamAroundAsync(pos,3) end) end
  if p.Character~=char or not root.Parent then return false end
  char:PivotTo(CFrame.new(pos)); root.AssemblyLinearVelocity=Vector3.zero; return true end
 return false
end
local function home(p)
 local b=bases[p]; teleport(p,b and b.spawn or Vector3.new(0,6,120))
end
-- Bind the actual architectural map. It exists in edit mode and is not replaced by a square.
Infrastructure.bind(map,prompt)
local publicGate=lobby:FindFirstChild('PublicArchiveGate',true)
if publicGate then prompt(publicGate,'Visit public archive',function(p) if not sessions[p] then teleport(p,Vector3.new(-1000,5,840)) end end) end
local publicArchive=map:FindFirstChild('PublicArchive')
if publicArchive then local exit=publicArchive:FindFirstChild('MuseumExit',true); if exit then prompt(exit,'Central plaza',function(p) teleport(p,Vector3.new(0,6,120)) end) end end
local inspection=lobby:FindFirstChild('AdminConsole',true)
if inspection then prompt(inspection,'Inspection controls',function(p) if admin(p) then send(p,'open','admin') else toast(p,'Owner / Studio inspection only') end end) end
local shop=lobby:FindFirstChild('ShopCounter',true)
if shop then prompt(shop,'Curator market',function(p) send(p,'open','shop') end) end
for i=1,4 do
 local pad=lobby:FindFirstChild('Queue'..i,true)
 local text=label(pad,'ASSEMBLY '..i..' / 0 players')
 pods[i]={id=i,members={},max=4,difficulty=2,access='all',part=pad,text=text,starting=false}
 prompt(pad,'Assemble a team',function(p) joinPod(p,i) end)
end
for _,g in ipairs(C.Games) do
 local gate=lobby:FindFirstChild('TrialGate'..g.id,true)
 local a=(g.id-1)*math.pi*2/50; local radius=3900+(g.id%3)*700
 local entry=Vector3.new(math.cos(a)*radius,5,math.sin(a)*radius+(g.depth+40)/2+14)
 if gate then prompt(gate,'Visit '..g.name,function(p) if not sessions[p] then teleport(p,entry) end end) end
 local mount=map:FindFirstChild(string.format('Mountain%02d_%s',g.id,g.kind),true)
 if mount then
  local entrance=mount:FindFirstChild('Entry'..g.id,true); local exit=mount:FindFirstChild('Exit'..g.id,true)
  if entrance then prompt(entrance,'Trial / form party at Assembly',function(p)
   if sessions[p] then return end
   joinPod(p,1); if pods[1].members[1]==p then pods[1].gameId=g.id; toast(p,'Selected '..g.name..'. Start at Assembly / team menu.') end
  end) end
  if exit then prompt(exit,'Return to central plaza',function(p) teleport(p,Vector3.new(0,6,120)) end) end
 end
end
local function trophyModel(parent,g,t,position)
 local level=C.Level(t.wins); if level==0 then return end
 local model=Instance.new('Model',parent); model.Name='Trophy_'..g.id
 local color=t.mutation=='Золотоносная' and C.Palette[7] or C.Palette[level]; local material=level>=13 and Enum.Material.Neon or (level>=4 and Enum.Material.Metal or Enum.Material.Slate)
 local function block(offset,size)
  local scale=1+(level-1)*.045
  local b=part(model,'Figure',(size or Vector3.new(.9,.9,.9))*scale,position+offset*scale,color,material); b.CanCollide=false; return b
 end
 TrophyIcons.build(g.kind,block)
 local anchor=model:FindFirstChildWhichIsA('BasePart'); model.PrimaryPart=anchor
 label(anchor,C.Tiers[level]..' '..level..'/20\n'..(t.mutation or (t.wins..' побед')),170)
 if level==1 then
  local mud=Instance.new('ParticleEmitter',anchor); mud.Name='Живая грязь'; mud.Texture='rbxasset://textures/particles/smoke_main.dds'; mud.Color=ColorSequence.new(color)
  mud.Rate=4; mud.Lifetime=NumberRange.new(.4,.8); mud.Speed=NumberRange.new(.1,.5); mud.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.3),NumberSequenceKeypoint.new(1,0)})
 end
 if t.mutation then
  local spark=Instance.new('Sparkles',anchor); spark.SparkleColor=t.mutation=='Золотоносная' and C.Palette[7] or C.Palette[14]
  if t.mutation=='Призрачная' then for _,v in ipairs(model:GetChildren()) do if v:IsA('BasePart') then v.Transparency=.5 end end end
  if t.mutation=='Галактическая' then local light=Instance.new('PointLight',anchor); light.Color=C.Palette[17]; light.Range=8; light.Brightness=2 end
 end
 model:SetAttribute('Bob',level==1 or t.mutation~=nil); model:SetAttribute('Origin',position)
end
updateBase=function(p)
 local b=bases[p]; local d=profiles[p]; if not b or not d then return end
 b.figures:ClearAllChildren()
 for _,g in ipairs(C.Games) do
  local stand=b.folder:FindFirstChild('Stand'..g.id,true)
  local pos=stand and stand.Position+Vector3.new(0,4,0) or b.origin
  local t=d.trophies[tostring(g.id)]
  if t then trophyModel(b.figures,g,t,pos) end
 end
end
local function createBase(p)
 baseSlot+=1
 local origin=Vector3.new(1000+(baseSlot-1)*440,0,700)
 local folder=ServerStorage:WaitForChild('MuseumTemplate'):Clone(); folder.Name='Museum_'..p.UserId; folder.Parent=world; folder:PivotTo(CFrame.new(origin))
 local door=folder:FindFirstChild('MuseumExit',true)
 if door then prompt(door,'Central plaza',function(who) teleport(who,Vector3.new(0,6,120)) end) end
 local figures=Instance.new('Folder',folder); figures.Name='Figures'
 bases[p]={folder=folder,figures=figures,origin=origin,spawn=door.Position+Vector3.new(0,4,-10)}
 local directory=part(lobby,p.DisplayName..' archive',Vector3.new(9,3,3),Vector3.new(204,2,-130+((baseSlot-1)%24)*11),Color3.fromRGB(137,127,98),Enum.Material.Marble)
 label(directory,p.DisplayName..' / ARCHIVE')
 prompt(directory,'Visit '..p.DisplayName,function(visitor) if not sessions[visitor] and bases[p] then teleport(visitor,bases[p].spawn) end end)
 folder:SetAttribute('Footprint',115200); folder:SetAttribute('InternalFloorArea',161188)
 bases[p].directory=directory
 Infrastructure.bind(folder,prompt); updateBase(p)
end
local function award(p,id,debugMutation)
 local d=profiles[p]; if not d then return end
 local key=tostring(id); local t=d.trophies[key] or {wins=0}; d.trophies[key]=t
 t.wins+=1; d.wins+=1; d.coins+=60
 if not t.mutation and (debugMutation or rng:NextNumber()<C.MutationChance) then
  t.mutation=debugMutation or ({'Золотоносная','Призрачная','Галактическая'})[rng:NextInteger(1,3)]
  d.mutationCount+=1; toast(p,'АНОМАЛИЯ! '..t.mutation..' фигурка')
 end
 achievements(p); updateBase(p); sync(p)
end
local function podUpdate(pod)
 pod.text.Text='КУБ '..pod.id..'\n'..#pod.members..' / '..pod.max..' · '..({'Легко','Обычно','Хардкор'})[pod.difficulty]
 local names={}; for _,p in ipairs(pod.members) do table.insert(names,{id=p.UserId,name=p.DisplayName}) end
 for _,p in ipairs(pod.members) do send(p,'pod',{id=pod.id,members=names,max=pod.max,difficulty=pod.difficulty,access=pod.access,leader=pod.members[1].UserId}) end
end
local function leavePod(p)
 for _,pod in ipairs(pods) do
  local i=table.find(pod.members,p)
  if i then table.remove(pod.members,i); if i==1 then pod.invited={} end; send(p,'pod',false); podUpdate(pod) end
 end
end
joinPod=function(p,id)
 local pod=pods[id]; if not profiles[p] or not pod or sessions[p] or pod.starting then return end
 if table.find(pod.members,p) then podUpdate(pod); return end
 if #pod.members>=pod.max then toast(p,'Куб заполнен'); return end
 local leader=pod.members[1]
 if leader and pod.access=='friends' then
  local ok,isFriend=pcall(function() return p:IsFriendsWithAsync(leader.UserId) end)
  if not ok or not isFriend then toast(p,'Этот куб открыт только друзьям лидера'); return end
 end
 if leader and pod.access=='invite' and not (pod.invited and pod.invited[p.UserId]) then toast(p,'Нужно приглашение лидера'); return end
 leavePod(p); table.insert(pod.members,p); teleport(p,pod.part.Position+Vector3.new(0,4,0)); podUpdate(pod)
end
local function aliveList(s)
 local list={}
 for p,a in pairs(s.alive) do if a and p.Parent==Players then table.insert(list,p) end end
 return list
end
local function root(p) return p.Character and p.Character:FindFirstChild('HumanoidRootPart') end
local function damage(s,p,n)
 if not s.alive[p] then return end
 local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid'); if h then h:TakeDamage(n) end
end
local function announce(s,extra)
 for _,p in ipairs(s.players) do
  send(p,'round',{name=s.game and s.game.name or '',rules=s.game and s.game.rules or '',round=s.round or 0,total=5,time=math.max(0,math.ceil(s.endsAt and s.endsAt-os.clock() or 0)),hint=s.hint or '',scores=s.scores and s.scores[p] or 0,alive=s.alive and s.alive[p] or false,controller=s.controller==p,gameId=s.game and s.game.id,extra=extra})
 end
end
local function audio(s,phase,position)
 for _,p in ipairs(s.players) do send(p,'sound',{phase=phase,gameId=s.game.id,position=position or s.origin,asset=C.AudioAssets[phase]}) end
end
local function kill(s,p,cause,contact) Elimination.play(s,p,cause or 'combat',contact) end
local function trialDamage(s,p,n,cause,contact)
 if not s.alive[p] or s.state.deadPending[p] then return end
 local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
 if h then
  if os.clock()-(s.lastImpact or -10)>.6 then s.lastImpact=os.clock(); audio(s,'impact',contact and contact.Position) end
  if h.Health<=n then kill(s,p,cause,contact) else h:TakeDamage(n) end end
end
local trialAPI={part=part,prompt=prompt,alive=aliveList,root=root,teleport=teleport,kill=kill,damage=trialDamage,audio=audio,send=send}
startMatch=function(members,difficulty,forced,debugSolo)
 local ready={}
 for _,p in ipairs(members) do if profiles[p] and not sessions[p] and p.Parent==Players then table.insert(ready,p) end end
 if #ready==0 then return false end
 if forced and not debugSolo then local g=C.Games[forced]; if #ready<g.minPlayers or #ready>g.players then
  for _,p in ipairs(ready) do toast(p,g.name..': '..g.minPlayers..'–'..g.players..' players required. Use admin solo test for inspection.') end; return false
 end end
 matchId+=1
 local slot=1; while activeSlots[slot] do slot+=1 end; activeSlots[slot]=true
 local s={id=matchId,slot=slot,players=ready,difficulty=difficulty,origin=Vector3.new((matchId%8)*180,100,1000+math.floor(matchId/8)*180),alive={},scores={},running=false,forceGame=forced,round=0}
 for _,p in ipairs(ready) do leavePod(p); sessions[p]=s; send(p,'match',true) end
 task.spawn(function()
  local ok,err=xpcall(function()
   local pool={}; for i,g in ipairs(C.Games) do if debugSolo or (#ready>=g.minPlayers and #ready<=g.players) then table.insert(pool,i) end end
   for round=1,C.RoundsPerRun do
    if s.cancelled then break end
    local present={}; for _,p in ipairs(s.players) do if p.Parent==Players and sessions[p]==s then table.insert(present,p) end end; s.players=present
    if #present==0 then break end
    s.round=round; s.preparing=true; s.spawnByPlayer={}; s.controller=nil; s.hint=''; s.finish=false; s.scores={}; s.alive={}
    local index=rng:NextInteger(1,#pool); local gameId=table.remove(pool,index)
    if s.forceGame then gameId=s.forceGame; local j=table.find(pool,gameId); if j then table.remove(pool,j) end; s.forceGame=nil end
    s.game=C.Games[gameId]
    local mountainAngle=(gameId-1)*math.pi*2/50; local mountainRadius=3900+(gameId%3)*700
    s.origin=Vector3.new(math.cos(mountainAngle)*mountainRadius,-300-(s.slot-1)*220,math.sin(mountainAngle)*mountainRadius)
    s.arena=Instance.new('Folder',matches); s.arena.Name='Match_'..s.id..'_Round_'..round
    for _,p in ipairs(present) do
     if not p.Character or not p.Character:FindFirstChildOfClass('Humanoid') or p.Character:FindFirstChildOfClass('Humanoid').Health<=0 then p:LoadCharacterAsync(); task.wait(.35) end
     s.scores[p]=0; s.alive[p]=true
     local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
     if h then h.MaxHealth=100; h.Health=100; h.BreakJointsOnDeath=false; h.WalkSpeed=16; h.JumpPower=50; h.UseJumpPower=true end
    end
    Trials.setup(s,trialAPI)
    for i,p in ipairs(present) do
     local destination=p==s.controller and s.state.console.Position+Vector3.new(0,4,5) or s.spawnPositions[(i-1)%#s.spawnPositions+1]+Vector3.new(math.floor((i-1)/#s.spawnPositions)*3,0,0)
     s.spawnByPlayer[p]=destination; teleport(p,destination)
    end
    s.startedAt=os.clock(); s.endsAt=s.startedAt+3; audio(s,'preparation'); announce(s); task.wait(3)
    s.startedAt=os.clock(); s.endsAt=s.startedAt+s.game.duration; s.preparing=false; s.running=true
    local last=os.clock(); local nextSend=0
    while os.clock()<s.endsAt and not s.finish do
     local now=os.clock(); local dt=math.min(.15,now-last); last=now
     for _,p in ipairs(aliveList(s)) do
      local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid'); local r=root(p)
      if not h or h.Health<=0 or not r then
       s.alive[p]=false; toast(p,'Eliminated / next trial soon'); home(p)
      elseif r.Position.Y<s.origin.Y-15 or (Vector3.new(r.Position.X,0,r.Position.Z)-Vector3.new(s.origin.X,0,s.origin.Z)).Magnitude>math.max(s.game.width,s.game.depth) then
       kill(s,p,'fall',r)
      elseif not s.state.deadPending[p] then s.scores[p]=(s.scores[p] or 0)+dt*2 end
     end
     if #aliveList(s)==0 then break end
     Trials.step(s,dt,now)
     if now>=nextSend then nextSend=now+.5; announce(s); audio(s,#aliveList(s)==1 and 'final' or now-s.startedAt>s.game.duration*.6 and 'danger' or 'calm') end
     task.wait(.05)
    end
    s.running=false
    task.wait(1.2)
    local best=-1; local winners={}
    -- Eliminated players retain points but cannot win, except the architect role.
    for _,p in ipairs(present) do
     if p.Parent==Players and Trials.eligibleWinner(s,p) then
      local score=math.floor(s.scores[p] or 0)
      if score>best then best=score; winners={p} elseif score==best then table.insert(winners,p) end
     end
    end
    local winner=#winners>0 and winners[rng:NextInteger(1,#winners)] or nil
    local awarded={}
    if s.state.completed and (s.game.kind=='teamescape' or s.game.kind=='balance') then
     for _,p in ipairs(present) do if Trials.eligibleWinner(s,p) then table.insert(awarded,p) end end
    elseif winner then table.insert(awarded,winner) end
    local winnerNames={}
    for _,p in ipairs(awarded) do award(p,gameId); if profiles[p] then profiles[p].coins+=s.game.reward-60; sync(p) end; table.insert(winnerNames,p.DisplayName) end
    audio(s,winner==s.controller and 'curator_victory' or 'survivor_victory')
    for _,p in ipairs(present) do
     if profiles[p] then profiles[p].coins+=15; sync(p) end
     send(p,'result',{name=s.game.name,winner=#winnerNames>0 and table.concat(winnerNames,' + ') or 'No qualifying finish',score=best,round=round}); home(p)
    end
    task.wait(4); Trials.cleanup(s); s.arena:Destroy(); s.arena=nil
   end
   for _,p in ipairs(s.players) do if profiles[p] and not s.cancelled then profiles[p].runs+=1; profiles[p].coins+=40; achievements(p); sync(p); toast(p,'Заход завершён! +40 монет'); end end
  end,debug.traceback)
  activeSlots[s.slot]=nil
  s.running=false; s.preparing=false; if s.state then Trials.cleanup(s) end; if s.arena then s.arena:Destroy() end
  for _,p in ipairs(s.players) do if sessions[p]==s then sessions[p]=nil; send(p,'match',false); home(p) end end
  if not ok then warn('Trophy match failure: '..tostring(err)); for _,p in ipairs(s.players) do toast(p,'Сбой испытания. Команда возвращена в лобби.') end end
 end)
 return true
end
local function save(p)
 if not store or not profiles[p] or p:GetAttribute('Persistence')~=true then return end
 local snapshot=profiles[p]
 local ok,err=pcall(function() store:UpdateAsync('u'..p.UserId,function() return snapshot end) end)
 if not ok then warn('Trophy save failed for UserId '..p.UserId..': '..tostring(err)); toast(p,'Сохранение временно недоступно; следующая попытка автоматически.') end
end
local function playerAdded(p)
 if loading[p] or profiles[p] then return end; loading[p]=true
 local d=newProfile(); local loaded=false
 for attempt=1,(store and 3 or 0) do
  local ok,data=pcall(function() return store:GetAsync('u'..p.UserId) end)
  if ok then d=sanitize(data); loaded=true; break end
  if RunService:IsStudio() then break end
  task.wait(attempt)
 end
 if p.Parent~=Players then loading[p]=nil; return end
 -- Never overwrite an existing cloud save after a failed load.
 profiles[p]=d; loading[p]=nil; p:SetAttribute('Persistence',loaded)
 if not loaded then toast(p,'Локальная сессия: DataStore недоступен. Прогресс этой сессии не сохранится.') end
 local stats=Instance.new('Folder',p); stats.Name='leaderstats'
 local w=Instance.new('IntValue',stats); w.Name='Победы'
 local coins=Instance.new('IntValue',stats); coins.Name='Монеты'
 createBase(p)
 p.CharacterAdded:Connect(function(char)
  local r=char:WaitForChild('HumanoidRootPart',10); if not r then return end
  task.wait(.2); if p.Parent~=Players then return end
  local s=sessions[p]
  if s and s.preparing then if s.spawnByPlayer[p] then teleport(p,s.spawnByPlayer[p]) end; refreshCosmetics(p); return end
  if s and s.running then s.alive[p]=false end
  teleport(p,Vector3.new(0,6,120)); refreshCosmetics(p)
 end)
 if p.Character then teleport(p,Vector3.new(0,6,120)); refreshCosmetics(p) end
 achievements(p); sync(p)
end
remote.OnServerEvent:Connect(function(p,action,data)
 if type(action)~='string' or not profiles[p] then return end
 local now=os.clock(); local limits=cooldowns[p] or {}; cooldowns[p]=limits
 local gap=action=='control' and .12 or .25
 if now-(limits[action] or -100)<gap then return end; limits[action]=now
 data=type(data)=='table' and data or {}
 if action=='sync' then sync(p)
 elseif action=='join' then local id=tonumber(data.id); if id and id%1==0 then joinPod(p,id) end
 elseif action=='leave' then leavePod(p)
 elseif action=='home' then if not sessions[p] then leavePod(p); home(p) end
 elseif action=='lobby' then if not sessions[p] then leavePod(p); teleport(p,Vector3.new(0,6,120)) end
 elseif action=='configure' then
  for _,pod in ipairs(pods) do if pod.members[1]==p and not pod.starting then
   if type(data.max)=='number' and data.max==data.max then pod.max=math.clamp(math.floor(data.max),1,8) end
   if type(data.difficulty)=='number' and data.difficulty==data.difficulty then pod.difficulty=math.clamp(math.floor(data.difficulty),1,3) end
   if table.find({'all','friends','invite'},data.access) then pod.access=data.access end
   if type(data.invite)=='number' and data.invite==data.invite and data.invite%1==0 then local target=Players:GetPlayerByUserId(data.invite); if target then pod.invited=pod.invited or {}; pod.invited[target.UserId]=true; send(target,'invite',{id=pod.id,name=p.DisplayName}) end end
   pod.max=math.max(pod.max,#pod.members); podUpdate(pod)
  end end
 elseif action=='start' then
  for _,pod in ipairs(pods) do if pod.members[1]==p and not pod.starting then
   pod.starting=true; local members=table.clone(pod.members); local launched=startMatch(members,pod.difficulty,pod.gameId); if launched~=false then pod.gameId=nil end; pod.starting=false; pod.invited={}; podUpdate(pod)
  end end
 elseif action=='buy' or action=='equip' then
  local d=profiles[p]
  for _,item in ipairs(C.Shop) do if data.id==item.id then
   if action=='buy' and not d.owned[item.id] then
    if d.coins<item.price then toast(p,'Не хватает монет'); return end
    d.coins-=item.price; d.owned[item.id]=true; if item.kind=='title' then d.titles[item.text]=true end
   end
   if d.owned[item.id] then
    if item.kind=='title' then d.title=item.text else d.equipped[item.kind]=d.equipped[item.kind]==item.id and nil or item.id end
    refreshCosmetics(p); sync(p)
   end
   break
  end end
 elseif action=='title' then
  local d=profiles[p]; if type(data.title)=='string' and (data.title=='' or d.titles[data.title]) then d.title=data.title; refreshCosmetics(p); sync(p) end
 elseif action=='attack' then local s=sessions[p]; if s and s.running then Trials.attack(s,p) end
 elseif action=='control' then
  local s=sessions[p]
  if s and s.running then Trials.control(s,p,data); send(p,'control',{column=s.state.column or 4,rotation=s.state.rotation or 0}) end
 elseif action=='admin' and admin(p) then
  local d=profiles[p]; local id=tonumber(data.id) or 1
  if id~=id then return end; id=math.clamp(math.floor(id),1,#C.Games)
  if data.command=='coins' then d.coins+=10000; sync(p)
  elseif data.command=='win' then award(p,id)
  elseif data.command=='level' then
   local level=tonumber(data.level) or 1; if level~=level then return end; level=math.clamp(math.floor(level),1,20)
   local key=tostring(id); local t=d.trophies[key] or {wins=0}; local delta=math.max(0,C.LevelWins[level]-t.wins); t.wins+=delta; d.wins+=delta; d.trophies[key]=t; achievements(p); updateBase(p); sync(p)
  elseif data.command=='mutation' then
   local names={'Золотоносная','Призрачная','Галактическая'}; local which=tonumber(data.mutation) or 1; if which~=which then return end
   local m=names[math.clamp(math.floor(which),1,3)]
   award(p,id,m)
   local t=d.trophies[tostring(id)]; t.mutation=m; updateBase(p); sync(p)
  elseif data.command=='unlock' then
   for _,item in ipairs(C.Shop) do d.owned[item.id]=true; if item.kind=='title' then d.titles[item.text]=true end end; sync(p)
  elseif data.command=='play' then if not sessions[p] then startMatch({p},2,id,true) else toast(p,'Сначала закончи текущий заход') end
  elseif data.command=='stop' then local s=sessions[p]; if s then s.cancelled=true; s.finish=true end
  elseif data.command=='line' then local s=sessions[p]; if s and s.running then Trials.debugLine(s) end
  elseif data.command=='next' then local s=sessions[p]; if s then s.finish=true end
  elseif data.command=='force' then local s=sessions[p]; if s then s.forceGame=id; toast(p,'Следующая игра: '..C.Games[id].name) end
  elseif data.command=='heal' then local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid'); if h then h.Health=h.MaxHealth end
  elseif data.command=='achievements' then d.wins=math.max(d.wins,100); d.runs=math.max(d.runs,10); for i=1,50 do d.trophies[tostring(i)]=d.trophies[tostring(i)] or {wins=1} end; d.mutationCount=math.max(d.mutationCount,1); d.trophies['1'].mutation='Галактическая'; achievements(p); updateBase(p); sync(p)
  end
 end
end)
Players.PlayerAdded:Connect(playerAdded)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(playerAdded,p) end
Players.PlayerRemoving:Connect(function(p)
 leavePod(p); local s=sessions[p]; if s then s.alive[p]=false; if s.controller==p then s.controller=nil end end
 save(p); profiles[p]=nil; sessions[p]=nil; cooldowns[p]=nil; loading[p]=nil
 if bases[p] then bases[p].directory:Destroy(); bases[p].folder:Destroy(); bases[p]=nil end
end)
game:BindToClose(function()
 local left=0
 for p in pairs(profiles) do left+=1; task.spawn(function() save(p); left-=1 end) end
 local deadline=os.clock()+25; while left>0 and os.clock()<deadline do task.wait(.1) end
end)
task.spawn(function() while true do task.wait(60); for p in pairs(profiles) do save(p) end end end)
local animTick=0
RunService.Heartbeat:Connect(function(dt)
 animTick+=dt; if animTick<.12 then return end; animTick=0
 for _,b in pairs(bases) do
  local nearby=false
  for _,viewer in ipairs(Players:GetPlayers()) do local r=root(viewer); if r and (r.Position-b.origin).Magnitude<300 then nearby=true; break end end
  if nearby then for _,m in ipairs(b.figures:GetChildren()) do
  if m:IsA('Model') and m:GetAttribute('Bob') and m.PrimaryPart then
   local origin=m:GetAttribute('Origin'); local pivot=m:GetPivot()
   local offset=math.sin(os.clock()*2+m.Name:len())*.035
   m:PivotTo(pivot+Vector3.new(0,origin.Y+offset-m.PrimaryPart.Position.Y,0))
  end
 end end end
end)
workspace:SetAttribute('MountainverseServerReady',true)
print('MOUNTAINVERSE / server ready; persistence='..tostring(store~=nil))

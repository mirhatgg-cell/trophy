local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local DS = game:GetService('DataStoreService')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local Debris = game:GetService('Debris')
local C = require(RS:WaitForChild('Catalog'))
local remote = RS:WaitForChild('TrophyEvent')
local rng = Random.new()
local profiles, bases, sessions, pods, cooldowns, loading = {}, {}, {}, {}, {}, {}
local store = DS:GetDataStore('TrophyPrototype_v1')
local preview=workspace:FindFirstChild('PreviewScene'); if preview then preview:Destroy() end
local world = Instance.new('Folder',workspace); world.Name='TrophyWorld'
local lobby = Instance.new('Folder',world); lobby.Name='Lobby'
local matches = Instance.new('Folder',world); matches.Name='Matches'
local baseSlot, matchId = 0,0
local startMatch, joinPod, updateBase, sync, achievements
local function part(parent,name,size,pos,color,material)
 local p=Instance.new('Part'); p.Name=name; p.Size=size; p.Position=pos; p.Color=color or Color3.fromRGB(60,70,93)
 p.Anchored=true; p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
 p.Material=material or Enum.Material.SmoothPlastic; p.Parent=parent; return p
end
local function label(p,text,size)
 local gui=Instance.new('BillboardGui'); gui.Name='Label'; gui.Size=UDim2.fromOffset(size or 220,65)
 gui.StudsOffset=Vector3.new(0,p.Size.Y/2+2,0); gui.MaxDistance=170; gui.Parent=p
 local t=Instance.new('TextLabel',gui); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1
 t.Text=text; t.TextColor3=Color3.new(1,1,1); t.TextStrokeTransparency=.45; t.TextSize=16; t.Font=Enum.Font.GothamBold; t.TextWrapped=true
 return t
end
local function prompt(p,text,callback)
 local q=Instance.new('ProximityPrompt',p); q.ActionText=text; q.ObjectText=p.Name; q.HoldDuration=0; q.MaxActivationDistance=15
 q.Triggered:Connect(callback); return q
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
 if root and hum and hum.Health>0 then char:PivotTo(CFrame.new(pos)); root.AssemblyLinearVelocity=Vector3.zero; return true end
 return false
end
local function home(p)
 local b=bases[p]; teleport(p,b and b.spawn or Vector3.new(0,6,0))
end
-- Lobby and personal museums use built-in parts: no external assets or API keys.
part(lobby,'Остров музея',Vector3.new(120,3,100),Vector3.new(0,-1.5,0),Color3.fromRGB(28,33,48))
local spawn=Instance.new('SpawnLocation',lobby); spawn.Name='LobbySpawn'; spawn.Size=Vector3.new(10,1,10); spawn.Position=Vector3.new(0,.5,12); spawn.Neutral=true; spawn.Duration=0; spawn.Color=Color3.fromRGB(89,255,195)
local sign=part(lobby,'TROPHY // 50 МИРОВ',Vector3.new(46,8,2),Vector3.new(0,9,-43),Color3.fromRGB(35,43,65)); label(sign,'TROPHY // 50 МИРОВ\n5 испытаний → твоя коллекция',420)
for i=1,9 do part(lobby,'Световая дорожка',Vector3.new(1,.12,70),Vector3.new(-48+i*10,.06,0),Color3.fromRGB(61,117,130),Enum.Material.Neon) end
local shop=part(lobby,'МАГАЗИН',Vector3.new(12,8,8),Vector3.new(-43,4,25),Color3.fromRGB(144,88,225)); label(shop,'МАГАЗИН\nКосметика · титулы'); prompt(shop,'Открыть',function(p) send(p,'open','shop') end)
local museum=part(lobby,'МОЙ МУЗЕЙ',Vector3.new(12,8,8),Vector3.new(43,4,25),Color3.fromRGB(72,183,155)); label(museum,'МОЙ МУЗЕЙ\n50 мест для трофеев'); prompt(museum,'На свою базу',home)
for i=1,4 do
 local x=(i-2.5)*25
 local pad=part(lobby,'Куб '..i,Vector3.new(18,1,18),Vector3.new(x,.6,-18),C.Palette[7+i],Enum.Material.Neon)
 local cube=part(lobby,'Вход '..i,Vector3.new(17,12,17),Vector3.new(x,7,-18),C.Palette[7+i],Enum.Material.Glass); cube.Transparency=.8; cube.CanCollide=false
 local text=label(cube,'КУБ '..i..'\n0 / 4 · обычная')
 pods[i]={id=i,members={},max=4,difficulty=2,access='all',part=pad,text=text,starting=false}
 prompt(pad,'Выбрать команду',function(p) joinPod(p,i) end)
end
local function trophyModel(parent,g,t,position)
 local level=C.Level(t.wins); if level==0 then return end
 local model=Instance.new('Model',parent); model.Name='Trophy_'..g.id
 local color=C.Palette[level]; local material=level>=13 and Enum.Material.Neon or (level>=4 and Enum.Material.Metal or Enum.Material.Slate)
 local function block(offset,size)
  local b=part(model,'Figure',size or Vector3.new(.9,.9,.9),position+offset,color,material); b.CanCollide=false; return b
 end
 if g.kind=='tetris' then
  for _,o in ipairs({Vector3.new(-.9,0,0),Vector3.zero,Vector3.new(.9,0,0),Vector3.new(0,.9,0)}) do block(o) end
 elseif g.kind=='flood' then
  for j=1,4 do block(Vector3.new((j-2.5)*.5,(j-1)*.4,0),Vector3.new(.55,.4,1)) end
 elseif g.kind=='laser' then block(Vector3.zero,Vector3.new(2.5,.25,.25)); block(Vector3.new(0,.7,0),Vector3.new(.25,1.5,.25))
 elseif g.kind=='tiles' or g.kind=='color' or g.kind=='memory' then
  for a=-1,1 do for b=-1,1 do block(Vector3.new(a*.65,0,b*.65),Vector3.new(.55,.45,.55)) end end
 else
  local ball=block(Vector3.new(0,.35,0),Vector3.new(1.8,1.8,1.8)); ball.Shape=Enum.PartType.Ball
  block(Vector3.new(0,-.6,0),Vector3.new(2.3,.2,2.3))
 end
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
  local pos=b.origin+Vector3.new(((g.id-1)%10-4.5)*6,3.3,math.floor((g.id-1)/10)*7)
  local t=d.trophies[tostring(g.id)]
  if t then trophyModel(b.figures,g,t,pos) end
 end
end
local function createBase(p)
 baseSlot+=1
 local origin=Vector3.new((baseSlot-1)*85,0,180)
 local folder=Instance.new('Folder',world); folder.Name='Museum_'..p.UserId
 part(folder,'Музей',Vector3.new(68,2,52),origin+Vector3.new(0,-1,14),Color3.fromRGB(35,40,55))
 local door=part(folder,'Выход в лобби',Vector3.new(9,1,7),origin+Vector3.new(0,.5,-9),C.Palette[9],Enum.Material.Neon)
 prompt(door,'В лобби',function(who) teleport(who,Vector3.new(0,5,12)) end)
 label(door,p.DisplayName..' // МУЗЕЙ',300)
 local figures=Instance.new('Folder',folder); figures.Name='Figures'
 bases[p]={folder=folder,figures=figures,origin=origin,spawn=origin+Vector3.new(0,5,-4)}
 for _,g in ipairs(C.Games) do
  local pos=origin+Vector3.new(((g.id-1)%10-4.5)*6,1,math.floor((g.id-1)/10)*7)
  local stand=part(folder,'Пьедестал '..g.id,Vector3.new(4.5,2,4.5),pos,Color3.fromRGB(59,64,83)); label(stand,g.id..'. '..g.name,150)
 end
 updateBase(p)
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
local function arenaPosition(s,x,y,z) return s.origin+Vector3.new(x,y,z) end
local function tileGrid(s)
 local tiles={}
 for x=1,6 do for z=1,6 do
  local index=(x-1)*6+z
  local t=part(s.arena,'Tile_'..index,Vector3.new(7.8,1,7.8),arenaPosition(s,(x-3.5)*8,0,(z-3.5)*8),C.Palette[(index-1)%4+8])
  t:SetAttribute('ColorId',(index-1)%4+1); table.insert(tiles,t)
 end end
 return tiles
end
local function standing(p,t)
 local r=root(p); if not r then return false end
 local d=r.Position-t.Position
 return math.abs(d.X)<=t.Size.X/2+.5 and math.abs(d.Z)<=t.Size.Z/2+.5 and d.Y>0 and d.Y<9
end
local function setupGame(s)
 local g=s.game; local v=g.variant; local diff=s.difficulty
 s.state={}; local st=s.state
 local floor=part(s.arena,'ArenaFloor',Vector3.new(50,2,50),s.origin+Vector3.new(0,-1,0),Color3.fromRGB(33,41,61)); st.floor=floor
 -- Arena borders are visual only: falling is an actual loss.
 for _,x in ipairs({-25,25}) do local b=part(s.arena,'Edge',Vector3.new(.25,.15,50),arenaPosition(s,x,.1,0),C.Palette[14],Enum.Material.Neon); b.CanCollide=false end
 if g.kind=='tiles' or g.kind=='color' or g.kind=='memory' then floor:Destroy(); st.tiles=tileGrid(s); st.cycle=0; st.next=0 end
 if g.kind=='flood' then
  floor.Size=Vector3.new(54,2,54)
  for i=1,22 do
   local angle=i*math.pi/2; local rad=13+(v%2)*2
   part(s.arena,'Step',Vector3.new(12-v*.6,1,12-v*.6),arenaPosition(s,math.cos(angle)*rad,i*2,math.sin(angle)*rad),C.Palette[(i%10)+6])
  end
  st.water=part(s.arena,'RisingDanger',Vector3.new(58,2,58),arenaPosition(s,0,-4,0),C.Palette[7+v],Enum.Material.Neon); st.water.CanCollide=false; st.water.Transparency=.35
 end
 if g.kind=='tetris' then
  st.blocks={}; st.rows={}; st.column=3; st.rotation=0; st.nextDrop=0
  for _,x in ipairs({-25,25}) do part(s.arena,'TetrisWall',Vector3.new(1,45,50),arenaPosition(s,x,21,0),Color3.fromRGB(60,66,86)).Transparency=.6 end
  if #s.players>1 then
   s.controller=s.players[rng:NextInteger(1,#s.players)]; s.alive[s.controller]=false
   part(s.arena,'ArchitectBalcony',Vector3.new(18,1,12),arenaPosition(s,0,30,-35),C.Palette[11],Enum.Material.Neon)
   teleport(s.controller,arenaPosition(s,0,34,-35)); s.hint='Архитектор: '..s.controller.DisplayName
  else s.hint='Соло: фигуры сбрасывает автомат' end
 end
 if g.kind=='laser' then st.lasers={}; st.next=0 end
 if g.kind=='meteor' or g.kind=='collect' then st.next=0 end
 if g.kind=='wind' then floor.Size=Vector3.new(39-v*2,2,39-v*2); st.next=0; st.direction=Vector3.new(1,0,0) end
 if g.kind=='drones' then
  st.drones={}
  for i=1,2+math.floor(v/2) do
   local d=part(s.arena,'Hunter',Vector3.new(2.5,2.5,2.5),arenaPosition(s,math.cos(i)*21,2,math.sin(i)*21),C.Palette[8],Enum.Material.Neon)
   d.Shape=Enum.PartType.Ball; d.CanCollide=false; table.insert(st.drones,d)
  end
 end
 st.nextCoin=0; st.lastHit={}
end
local function spawnCoin(s)
 local coin=part(s.arena,'Spark',Vector3.new(1.3,1.3,1.3),arenaPosition(s,rng:NextNumber(-18,18),2,rng:NextNumber(-18,18)),C.Palette[7],Enum.Material.Neon); coin.Shape=Enum.PartType.Ball; coin.CanCollide=false
 local used=false
 coin.Touched:Connect(function(hit)
  local character=hit:FindFirstAncestorOfClass('Model')
  local p=character and Players:GetPlayerFromCharacter(character)
  if not used and p and s.alive[p] and sessions[p]==s and s.running then used=true; s.scores[p]=(s.scores[p] or 0)+15; coin:Destroy() end
 end)
 Debris:AddItem(coin,9)
end
local function meteor(s,now)
 local st=s.state; local g=s.game
 local x,z=rng:NextNumber(-21,21),rng:NextNumber(-21,21)
 if g.variant==2 or g.variant==5 then local list=aliveList(s); local p=list[rng:NextInteger(1,math.max(1,#list))]; local r=p and root(p); if r then x=r.Position.X-s.origin.X; z=r.Position.Z-s.origin.Z end end
 local radius=3+g.variant*.6
 local mark=part(s.arena,'ImpactWarning',Vector3.new(radius*2,.12,radius*2),arenaPosition(s,x,.2,z),Color3.fromRGB(255,58,86),Enum.Material.Neon); mark.CanCollide=false; mark.Transparency=.45
 task.delay(math.max(.55,1.6-s.difficulty*.2),function()
  if not s.running or not mark.Parent then return end
  local rock=part(s.arena,'Meteor',Vector3.new(radius*1.4,radius*1.4,radius*1.4),arenaPosition(s,x,42,z),C.Palette[7+g.variant],Enum.Material.Neon); rock.CanCollide=false
  local tween=TweenService:Create(rock,TweenInfo.new(.3,Enum.EasingStyle.Linear),{Position=arenaPosition(s,x,1,z)}); tween:Play(); tween.Completed:Wait()
  if s.running then for _,p in ipairs(aliveList(s)) do local r=root(p); if r and (Vector3.new(r.Position.X,0,r.Position.Z)-Vector3.new(s.origin.X+x,0,s.origin.Z+z)).Magnitude<radius then damage(s,p,70) end end end
  rock:Destroy(); mark:Destroy()
 end)
 Debris:AddItem(mark,4)
end
local SHAPES={{{0,0},{1,0},{2,0},{1,1}},{{0,0},{0,1},{1,0},{1,1}},{{0,0},{1,0},{2,0},{3,0}},{{0,0},{1,0},{1,1},{2,1}},{{0,0},{1,0},{2,0},{2,1}}}
local function dropTetris(s)
 local st=s.state; if not s.running or os.clock()<st.nextDrop then return end
 st.nextDrop=os.clock()+math.max(.65,1.65-s.game.variant*.1-s.difficulty*.12)
 local col=s.controller and st.column or rng:NextInteger(1,5)
 local shape=SHAPES[rng:NextInteger(1,#SHAPES)]; local blocks={}; local cells={}
 local depth=rng:NextInteger(1,6)
 for _,cell in ipairs(shape) do
  local dx,dz=cell[1],cell[2]; if st.rotation%2==1 then dx,dz=dz,dx end
  local cx=math.clamp(col+dx,1,8); local cz=math.clamp(depth+dz,1,8)
  table.insert(cells,{cx,cz})
  local b=part(s.arena,'FallingTetromino',Vector3.new(5.8,5.8,5.8),arenaPosition(s,(cx-4.5)*6,32,(cz-4.5)*6),C.Palette[7+s.game.variant],Enum.Material.Neon); b.CanCollide=false
  table.insert(blocks,b)
  local mark=part(s.arena,'DropWarning',Vector3.new(5.8,.1,5.8),arenaPosition(s,(cx-4.5)*6,.2,(cz-4.5)*6),Color3.fromRGB(255,70,90),Enum.Material.Neon); mark.CanCollide=false; mark.Transparency=.5; Debris:AddItem(mark,2)
 end
 task.delay(.65,function()
  if not s.running then return end
  local targetY=3
  for _,cell in ipairs(cells) do targetY=math.max(targetY,(st.rows[cell[1]..':'..cell[2]] or 0)+3) end
  targetY=math.min(targetY,21)
  for i,b in ipairs(blocks) do if b.Parent then TweenService:Create(b,TweenInfo.new(.55,Enum.EasingStyle.Linear),{Position=Vector3.new(b.Position.X,s.origin.Y+targetY,b.Position.Z)}):Play() end end
  task.wait(.55)
  if not s.running then return end
  for i,b in ipairs(blocks) do
   if b.Parent then
    for _,p in ipairs(aliveList(s)) do local r=root(p); if r and math.abs(r.Position.X-b.Position.X)<3.9 and math.abs(r.Position.Z-b.Position.Z)<3.9 and r.Position.Y<b.Position.Y+5 then damage(s,p,110) end end
    b.CanCollide=true; table.insert(st.blocks,b); st.rows[cells[i][1]..':'..cells[i][2]]=targetY+3
   end
  end
  -- Full columns across any occupied depth count as a completed set; clear the board.
  local full=false
  for z=1,8 do local count=0; for x=1,8 do if st.rows[x..':'..z] then count+=1 end end; if count==8 then full=true end end
  if full or #st.blocks>64 then
   if s.controller then s.scores[s.controller]=(s.scores[s.controller] or 0)+40; toast(s.controller,'Сет! +40') end
   for _,b in ipairs(st.blocks) do b:Destroy() end; st.blocks={}; st.rows={}
  end
 end)
end
local function tickGame(s,dt,now)
 local st=s.state; local g=s.game; local v=g.variant; local diff=s.difficulty
 if g.kind=='tetris' then
  if s.controller then
   local h=s.controller.Character and s.controller.Character:FindFirstChildOfClass('Humanoid')
   if not h or h.Health<=0 then s.controller=nil end
  end
  if not s.controller and now>=st.nextDrop then dropTetris(s) end
  if s.controller and now>=st.nextDrop+3 then dropTetris(s) end -- AFK controller cannot stall.
 elseif g.kind=='tiles' then
  if now>=st.next then
   st.next=now+math.max(.7,2.1-v*.16-diff*.12)
   local choices={}; for _,t in ipairs(st.tiles) do if t.CanCollide and not t:GetAttribute('Falling') then table.insert(choices,t) end end
   for i=1,math.min(1+math.floor(v/2),math.max(0,#choices-3)) do
    local t=table.remove(choices,rng:NextInteger(1,#choices)); t:SetAttribute('Falling',true); t.Color=C.Palette[8]
    task.delay(.85,function() if t.Parent and s.running then t.CanCollide=false; t.Transparency=1 end end)
   end
  end
 elseif g.kind=='color' or g.kind=='memory' then
  if now>=st.next then
   st.cycle+=1; local reveal=math.max(1.2,3-v*.17-diff*.18); st.next=now+reveal+2.2
   local colorId=rng:NextInteger(1,4); local safe={}
   if g.kind=='memory' then
    for i=1,math.max(4,11-v) do safe[rng:NextInteger(1,#st.tiles)]=true end
   end
   for i,t in ipairs(st.tiles) do
    t.CanCollide=true; t.Transparency=0
    local yes=g.kind=='color' and t:GetAttribute('ColorId')==colorId or g.kind=='memory' and safe[i]==true
    t:SetAttribute('Safe',yes); t.Color=g.kind=='memory' and (yes and C.Palette[9] or C.Palette[12]) or C.Palette[7+t:GetAttribute('ColorId')]
   end
   s.hint=g.kind=='color' and ('Нужный цвет: '..({'КРАСНЫЙ','ЗЕЛЁНЫЙ','СИНИЙ','ФИОЛЕТОВЫЙ'})[colorId]) or 'ЗАПОМНИ ЗЕЛЁНЫЕ ПЛИТКИ'
   if g.kind=='memory' then task.delay(reveal*.55,function() if s.running then for _,t in ipairs(st.tiles) do t.Color=C.Palette[12] end; s.hint='Вспомни безопасное место!' end end) end
   task.delay(reveal,function()
    if not s.running then return end
    s.hint='ПОЛ ИСЧЕЗАЕТ!'
    for _,t in ipairs(st.tiles) do if not t:GetAttribute('Safe') then t.CanCollide=false; t.Transparency=.95 else t.Color=C.Palette[9] end end
   end)
  end
 elseif g.kind=='meteor' or g.kind=='collect' then
  if now>=st.next then st.next=now+math.max(.35,1.5-v*.13-diff*.12); meteor(s,now) end
 elseif g.kind=='flood' then
  local elapsed=now-s.startedAt
  local y=-4+elapsed*(.83+v*.035+diff*.035); st.water.Position=arenaPosition(s,0,y,0)
  for _,p in ipairs(aliveList(s)) do local r=root(p); if r and r.Position.Y<s.origin.Y+y+2 then damage(s,p,35*dt) end end
 elseif g.kind=='laser' then
  if now>=st.next then
   st.next=now+math.max(1,2.8-v*.15-diff*.2)
   local sideways=v%2==0 and rng:NextNumber()<.5
   local high=v>=4 and rng:NextNumber()<.35
   local b=part(s.arena,'Laser',sideways and Vector3.new(.5,high and 4 or .7,49) or Vector3.new(49,high and 4 or .7,.5),arenaPosition(s,sideways and -25 or 0,high and 8 or 1.1,sideways and 0 or -25),C.Palette[8],Enum.Material.Neon); b.CanCollide=false
   table.insert(st.lasers,{part=b,axis=sideways and 'X' or 'Z',speed=9+v+diff*2,hit={}})
  end
  for i=#st.lasers,1,-1 do
   local l=st.lasers[i]; local delta=l.speed*dt
   l.part.Position+=l.axis=='X' and Vector3.new(delta,0,0) or Vector3.new(0,0,delta)
   for _,p in ipairs(aliveList(s)) do
    local r=root(p)
    if r and now-(l.hit[p] or 0)>.8 then
     local off=r.Position-l.part.Position
     local crossed=l.axis=='X' and math.abs(off.X)<1.6 or l.axis=='Z' and math.abs(off.Z)<1.6
     if crossed and math.abs(off.Y)<l.part.Size.Y/2+2 then l.hit[p]=now; damage(s,p,40) end
    end
   end
   if (l.part.Position-s.origin).Magnitude>40 then l.part:Destroy(); table.remove(st.lasers,i) end
  end
 elseif g.kind=='wind' then
  if now>=st.next then
   st.next=now+3.5; local angle=rng:NextNumber(0,math.pi*2); st.direction=Vector3.new(math.cos(angle),0,math.sin(angle)); s.hint='ВЕТЕР → '..math.floor(math.deg(angle))..'°'
  end
  for _,p in ipairs(aliveList(s)) do local r=root(p); if r then r.AssemblyLinearVelocity+=st.direction*(10+v*2+diff*2)*dt end end
 elseif g.kind=='drones' then
  for _,d in ipairs(st.drones) do
   local target,dist=nil,math.huge
   for _,p in ipairs(aliveList(s)) do local r=root(p); if r then local n=(r.Position-d.Position).Magnitude; if n<dist then target=r; dist=n end end end
   if target then
    local delta=Vector3.new(target.Position.X-d.Position.X,0,target.Position.Z-d.Position.Z)
    if delta.Magnitude>.1 then d.Position+=delta.Unit*math.min(delta.Magnitude,(6+v*.7+diff*.8)*dt) end
    for _,p in ipairs(aliveList(s)) do local r=root(p); if r and (r.Position-d.Position).Magnitude<3.7 and now-(st.lastHit[p] or 0)>.8 then st.lastHit[p]=now; damage(s,p,28) end end
   end
  end
 end
 if g.kind=='collect' or g.kind=='wind' or g.kind=='drones' then
  if now>=st.nextCoin then st.nextCoin=now+.7; spawnCoin(s) end
 end
end
startMatch=function(members,difficulty,forced)
 local ready={}
 for _,p in ipairs(members) do if profiles[p] and not sessions[p] and p.Parent==Players then table.insert(ready,p) end end
 if #ready==0 then return end
 matchId+=1
 local s={id=matchId,players=ready,difficulty=difficulty,origin=Vector3.new((matchId%8)*180,100,1000+math.floor(matchId/8)*180),alive={},scores={},running=false,forceGame=forced,round=0}
 for _,p in ipairs(ready) do leavePod(p); sessions[p]=s; send(p,'match',true) end
 task.spawn(function()
  local ok,err=xpcall(function()
   local pool={}; for i=1,#C.Games do table.insert(pool,i) end
   for round=1,C.RoundsPerRun do
    local present={}; for _,p in ipairs(s.players) do if p.Parent==Players and sessions[p]==s then table.insert(present,p) end end; s.players=present
    if #present==0 then break end
    s.round=round; s.controller=nil; s.hint=''; s.finish=false; s.scores={}; s.alive={}
    local index=rng:NextInteger(1,#pool); local gameId=table.remove(pool,index)
    if s.forceGame then gameId=s.forceGame; local j=table.find(pool,gameId); if j then table.remove(pool,j) end; s.forceGame=nil end
    s.game=C.Games[gameId]
    s.arena=Instance.new('Folder',matches); s.arena.Name='Match_'..s.id..'_Round_'..round
    for _,p in ipairs(present) do
     if not p.Character or not p.Character:FindFirstChildOfClass('Humanoid') or p.Character:FindFirstChildOfClass('Humanoid').Health<=0 then p:LoadCharacterAsync(); task.wait(.35) end
     s.scores[p]=0; s.alive[p]=true
     local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
     if h then h.MaxHealth=100; h.Health=100; h.WalkSpeed=16; h.JumpPower=50; h.UseJumpPower=true end
    end
    setupGame(s)
    for i,p in ipairs(present) do if p~=s.controller then teleport(p,arenaPosition(s,(i-1)%4*5-8,5,10+math.floor((i-1)/4)*5)) end end
    s.startedAt=os.clock(); s.endsAt=s.startedAt+C.RoundSeconds; s.running=true
    local last=os.clock(); local nextSend=0
    while os.clock()<s.endsAt and not s.finish do
     local now=os.clock(); local dt=math.min(.15,now-last); last=now
     for _,p in ipairs(aliveList(s)) do
      local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid'); local r=root(p)
      if not h or h.Health<=0 or not r or r.Position.Y<s.origin.Y-15 or (Vector3.new(r.Position.X,0,r.Position.Z)-Vector3.new(s.origin.X,0,s.origin.Z)).Magnitude>65 then
       s.alive[p]=false
       if s.controller and s.controller.Parent==Players then s.scores[s.controller]=(s.scores[s.controller] or 0)+55 end
       toast(p,'Ты выбыл. Следующее испытание скоро!'); home(p)
      else s.scores[p]=(s.scores[p] or 0)+dt*2 end
     end
     if #aliveList(s)==0 then break end
     tickGame(s,dt,now)
     if now>=nextSend then nextSend=now+.5; announce(s) end
     task.wait(.05)
    end
    s.running=false
    local best=-1; local winners={}
    -- Eliminated players retain points but cannot win, except the architect role.
    for _,p in ipairs(present) do
     if p.Parent==Players and (s.alive[p] or s.controller==p) then
      local score=math.floor(s.scores[p] or 0)
      if score>best then best=score; winners={p} elseif score==best then table.insert(winners,p) end
     end
    end
    local winner=#winners>0 and winners[rng:NextInteger(1,#winners)] or nil
    if winner then award(winner,gameId) end
    for _,p in ipairs(present) do
     if profiles[p] then profiles[p].coins+=15; sync(p) end
     send(p,'result',{name=s.game.name,winner=winner and winner.DisplayName or 'Никто не выжил',score=best,round=round}); home(p)
    end
    task.wait(4); s.arena:Destroy(); s.arena=nil
   end
   for _,p in ipairs(s.players) do if profiles[p] then profiles[p].runs+=1; profiles[p].coins+=40; achievements(p); sync(p); toast(p,'Заход завершён! +40 монет'); end end
  end,debug.traceback)
  s.running=false; if s.arena then s.arena:Destroy() end
  for _,p in ipairs(s.players) do if sessions[p]==s then sessions[p]=nil; send(p,'match',false); home(p) end end
  if not ok then warn('Trophy match failure: '..tostring(err)); for _,p in ipairs(s.players) do toast(p,'Сбой испытания. Команда возвращена в лобби.') end end
 end)
end
local function save(p)
 if not profiles[p] or p:GetAttribute('Persistence')~=true then return end
 local snapshot=profiles[p]
 local ok,err=pcall(function() store:UpdateAsync('u'..p.UserId,function() return snapshot end) end)
 if not ok then warn('Trophy save failed for UserId '..p.UserId..': '..tostring(err)); toast(p,'Сохранение временно недоступно; следующая попытка автоматически.') end
end
local function playerAdded(p)
 if loading[p] or profiles[p] then return end; loading[p]=true
 local d=newProfile(); local loaded=false
 for attempt=1,3 do
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
  if s and s.running then s.alive[p]=false end
  home(p); refreshCosmetics(p)
 end)
 if p.Character then home(p); refreshCosmetics(p) end
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
 elseif action=='lobby' then if not sessions[p] then leavePod(p); teleport(p,Vector3.new(0,5,12)) end
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
   pod.starting=true; local members=table.clone(pod.members); startMatch(members,pod.difficulty); pod.starting=false; pod.invited={}; podUpdate(pod)
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
 elseif action=='control' then
  local s=sessions[p]
  if s and s.running and s.controller==p and s.game.kind=='tetris' then
   if type(data.column)=='number' and data.column==data.column then s.state.column=math.clamp(math.floor(data.column),1,8) end
   if data.rotate then s.state.rotation+=1 end
   if data.drop then dropTetris(s) end
   send(p,'control',{column=s.state.column,rotation=s.state.rotation%2})
  end
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
  elseif data.command=='play' then if not sessions[p] then startMatch({p},2,id) else toast(p,'Сначала закончи текущий заход') end
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
 if bases[p] then bases[p].folder:Destroy(); bases[p]=nil end
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
 for _,b in pairs(bases) do for _,m in ipairs(b.figures:GetChildren()) do
  if m:IsA('Model') and m:GetAttribute('Bob') and m.PrimaryPart then
   local origin=m:GetAttribute('Origin'); local pivot=m:GetPivot()
   local offset=math.sin(os.clock()*2+m.Name:len())*.035
   m:PivotTo(pivot+Vector3.new(0,origin.Y+offset-m.PrimaryPart.Position.Y,0))
  end
 end end
end)
print('TROPHY prototype: 50 games, 4 party cubes, persistent museums. Studio test admin enabled.')

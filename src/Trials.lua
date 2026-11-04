-- MOUNTAINVERSE: fifty explicit trial state machines. Server authoritative.
local M={}
local Tween=game:GetService('TweenService')
local Players=game:GetService('Players')
local rng=Random.new()
local stone=Color3.fromRGB(134,140,129)
local steel=Color3.fromRGB(83,102,105)
local amber=Color3.fromRGB(240,193,102)
local danger=Color3.fromRGB(231,107,68)
local ice=Color3.fromRGB(160,210,220)
local function make(s,name,size,pos,color,material)
 return s.api.part(s.arena,name,size,s.origin+pos,color or stone,material or Enum.Material.Concrete)
end
local function box(s,name,x,y,z,w,h,d,color,material) return make(s,name,Vector3.new(w,h,d),Vector3.new(x,y,z),color,material) end
local function on(s,p,b,margin)
 local r=s.api.root(p); if not r or not b.Parent then return false end
 local v=b.CFrame:PointToObjectSpace(r.Position)
 return math.abs(v.X)<b.Size.X/2+(margin or 1.6) and math.abs(v.Z)<b.Size.Z/2+(margin or 1.6) and math.abs(v.Y)<b.Size.Y/2+2.5
end
local function near(s,p,pos,dist) local r=s.api.root(p); return r and (r.Position-pos).Magnitude<dist end
local function hits(s,b,dt,mode,lethal)
 for _,p in ipairs(s.api.alive(s)) do if on(s,p,b) then
  if lethal then s.api.kill(s,p,mode,b) else s.api.damage(s,p,dt*42,mode,b) end
 end end
end
local function score(s,p,n) s.scores[p]=(s.scores[p] or 0)+n end
local function actuator(s,name,x,z,axis,length,height)
 local b=box(s,name,x,height or 5,z,axis=='x' and 3 or length,10,axis=='x' and length or 3,steel,Enum.Material.Metal)
 box(s,'Drive rail',x,.3,z,axis=='x' and length or 2,.5,axis=='x' and 2 or length,steel,Enum.Material.DiamondPlate)
 box(s,'Hydraulic drive',x,3,z,6,6,6,steel,Enum.Material.Metal)
 return b
end
local function claim(s,pos,name,points)
 local b=make(s,name or 'Objective',Vector3.new(2,2,2),pos,amber,Enum.Material.Neon); b.CanCollide=false; b.Shape=Enum.PartType.Ball
 table.insert(s.state.pickups,{part=b,points=points or 15}); return b
end
local function marker(s,x,z,color)
 local b=box(s,'Warning footprint',x,.15,z,10,.1,10,color or danger,Enum.Material.Neon); b.CanCollide=false; b.Transparency=.4; return b
end
local function trigger(s,part,text,fn)
 local used={}
 s.api.prompt(part,text,function(p)
  if s.running and s.alive[p] and near(s,p,part.Position,16) and os.clock()-(used[p] or -10)>3 then used[p]=os.clock(); fn(p) end
 end)
end
local function grid(s,n,size)
 local tiles={}
 for x=1,n do for z=1,n do local b=box(s,'Cell '..x..':'..z,(x-(n+1)/2)*size,0,(z-(n+1)/2)*size,size-.3,1,size-.3); b:SetAttribute('Index',(x-1)*n+z); table.insert(tiles,b) end end
 return tiles
end
local function frame(s)
 local w,d,h=s.game.width,s.game.depth,s.game.height
 box(s,'Structural raft',0,-5,0,w+12,8,d+12)
 -- A separate safety floor is removed for shaft / collapsing-floor trials.
 s.state.floor=box(s,'Trial floor',0,-1,0,w,2,d)
 for _,x in ipairs({-w/2,w/2}) do for _,z in ipairs({-d/2,d/2}) do box(s,'Load-bearing pier',x,h/2,z,5,h+6,5) end end
 for _,z in ipairs({-d/2,d/2}) do
  box(s,'Roof truss',0,h,z,w+5,4,4,steel,Enum.Material.Metal)
  box(s,'Gallery',0,14,z,w,1.5,10,steel,Enum.Material.DiamondPlate)
 end
 -- Open central volume. Technical annex remains connected by a service walkway.
 box(s,'Service room floor',w/2+12,0,0,20,2,30)
 box(s,'Power cabinet',w/2+16,5,-10,5,10,4,steel,Enum.Material.Metal)
 box(s,'Ventilation trunk',w/2+12,12,0,3,3,30,steel,Enum.Material.Metal)
 box(s,'Cable channel',0,12,-d/2-3,w,.5,1,steel,Enum.Material.Metal)
 for _,x in ipairs({-w/3,w/3}) do
  local lamp=box(s,'Work light',x,h-4,-d/3,4,.5,2,amber,Enum.Material.Neon)
  local light=Instance.new('PointLight',lamp); light.Range=45; light.Brightness=1.4; light.Color=Color3.fromRGB(255,230,187)
 end
 s.spawnPositions={s.origin+Vector3.new(-8,4,10),s.origin+Vector3.new(0,4,10),s.origin+Vector3.new(8,4,10),s.origin+Vector3.new(16,4,10)}
end
local shapes={{{0,0},{1,0},{2,0},{3,0}},{{0,0},{1,0},{0,1},{1,1}},{{0,0},{1,0},{2,0},{1,1}},{{0,0},{1,0},{1,1},{2,1}},{{1,0},{2,0},{0,1},{1,1}},{{0,0},{0,1},{1,0},{2,0}},{{0,0},{1,0},{2,0},{2,1}}}
local function cells(st,col,rot)
 local result={}; local minx,miny=100,100
 for _,v in ipairs(shapes[st.shape]) do
  local x,y=v[1],v[2]
  for _=1,rot%4 do x,y=-y,x end
  minx=math.min(minx,x); miny=math.min(miny,y); table.insert(result,{x,y})
 end
 for _,v in ipairs(result) do v[1]=v[1]-minx+col; v[2]-=miny end
 return result
end
local function legal(st,c,base)
 for _,v in ipairs(c) do if v[1]<1 or v[1]>10 or base+v[2]<1 or st.board[v[1]..':'..(base+v[2])] then return false end end
 return true
end
local function newPiece(s)
 local st=s.state; st.shape=st.nextShape or rng:NextInteger(1,7); st.nextShape=rng:NextInteger(1,7); st.column=4; st.rotation=0; st.fallRow=17; st.fast=false; st.active={}; st.shadows={}
 s.api.audio(s,'movement')
 for i=1,4 do
  local b=box(s,'Tetromino cell '..i,0,110,0,5.9,5.9,23,steel,Enum.Material.Metal); b.CanCollide=false
  local trim=Instance.new('SelectionBox',b); trim.Adornee=b; trim.LineThickness=.04; trim.Color3=amber
  table.insert(st.active,b); table.insert(st.shadows,marker(s,0,0))
 end
end
local function landing(st,c)
 local row=17
 while row>1 and legal(st,c,row-1) do row-=1 end
 return row
end
function M.control(s,p,data)
 local st=s.state
 if not st or s.controller~=p or not s.running or not st.console or not near(s,p,st.console.Position,18) then return end
 if s.game.kind=='tetris' then
  if type(data.piece)=='number' and data.piece%1==0 and data.piece>=1 and data.piece<=7 then st.nextShape=data.piece end
  if data.rotate then local r=(st.rotation+1)%4; if legal(st,cells(st,st.column,r),math.ceil(st.fallRow)) then st.rotation=r end end
  if type(data.column)=='number' and data.column==data.column then
   local col=math.clamp(math.floor(data.column),1,10)
   if legal(st,cells(st,col,st.rotation),math.ceil(st.fallRow)) then st.column=col end
  end
  if data.drop then st.fast=true end
 elseif s.game.kind=='crane' then
  st.targetX=math.clamp((tonumber(data.column) or 4)*10-45,-40,40); if data.drop then st.dropUntil=os.clock()+3 end
 elseif s.game.kind=='curatormaze' then
  st.gateMode=not st.gateMode
  for i=1,math.min(8,#st.mazeWall) do local gate=st.mazeWall[i]; gate.part.CanCollide=st.gateMode; gate.part.Transparency=st.gateMode and 0 or .85
   if st.gateMode then st.graph[gate.a][gate.b]=nil; st.graph[gate.b][gate.a]=nil; hits(s,gate.part,.2,'crush',true)
   else st.graph[gate.a][gate.b]=true; st.graph[gate.b][gate.a]=true end
  end; st.repath=0
 end
end
local function mazeSetup(s)
 local st=s.state; local n=9; st.n=n; st.graph={}; st.mazeWall={}
 local function link(a,b) st.graph[a][b]=true; st.graph[b][a]=true end
 for i=1,n*n do st.graph[i]={} end
 local seen={[1]=true}; local stack={1}
 while #stack>0 do
  local a=stack[#stack]; local x=math.floor((a-1)/n)+1; local z=(a-1)%n+1; local choices={}
  for _,v in ipairs({{x-1,z},{x+1,z},{x,z-1},{x,z+1}}) do if v[1]>=1 and v[1]<=n and v[2]>=1 and v[2]<=n then local b=(v[1]-1)*n+v[2]; if not seen[b] then table.insert(choices,b) end end end
  if #choices==0 then table.remove(stack) else local b=choices[rng:NextInteger(1,#choices)]; seen[b]=true; link(a,b); table.insert(stack,b) end
 end
 st.nodes={}
 for x=1,n do for z=1,n do
  local a=(x-1)*n+z; st.nodes[a]=s.origin+Vector3.new((x-5)*12,3,(z-5)*12)
  if x<n and not st.graph[a][a+n] then local wall=box(s,'Maze gate',(x-4.5)*12,7,(z-5)*12,1,14,12,stone); table.insert(st.mazeWall,{a=a,b=a+n,part=wall}) end
  if z<n and not st.graph[a][a+1] then local wall=box(s,'Maze gate',(x-5)*12,7,(z-4.5)*12,12,14,1,stone); table.insert(st.mazeWall,{a=a,b=a+1,part=wall}) end
  if a%3==0 then claim(s,Vector3.new((x-5)*12,2,(z-5)*12),'Maze pellet',15) end
 end end
 for _,x in ipairs({-54,54}) do box(s,'Perimeter',x,7,0,2,14,110); box(s,'Perimeter',0,7,x,110,14,2) end
 st.hunter=make(s,'Jaw carriage',Vector3.new(5,5,5),st.nodes[81]-s.origin,danger,Enum.Material.Metal); st.hunter.Shape=Enum.PartType.Ball; st.hunter.CanCollide=false
 st.jaws={}
 for _,side in ipairs({-1,1}) do local b=box(s,'Hinged jaw',0,3,0,5,5,2,amber,Enum.Material.Metal); b.CanCollide=false; table.insert(st.jaws,{part=b,side=side}) end
 st.hunterNode=81; st.route={}; st.repath=0; st.mode='patrol'
 s.spawnPositions={st.nodes[1]+Vector3.new(0,2,0)}
end
local function bfs(st,from,to)
 local q={from}; local parents={[from]=0}; local head=1
 while head<=#q do local a=q[head]; head+=1; if a==to then break end; for b in pairs(st.graph[a]) do if parents[b]==nil then parents[b]=a; table.insert(q,b) end end end
 local path={}; local c=to
 while parents[c] and parents[c]~=0 do table.insert(path,1,c); c=parents[c] end
 return path
end
local function spiral(s)
 for j=1,42 do
  local a=j*math.pi/4; box(s,'Connected stair landing',math.cos(a)*24,j*1.7,math.sin(a)*24,24,1.5,24)
 end
 s.spawnPositions={s.origin+Vector3.new(17,5,17)}
end
function M.setup(s,api)
 s.api=api; s.state={pickups={},next=0,phase=0,hitTimes={},objectives={},deadPending={},hazards={}}
 local st=s.state; local k=s.game.kind; frame(s)
 s.hint='PREPARATION / '..s.game.rules
 if k=='tetris' or k=='crane' or k=='curatormaze' then
  if #s.players>1 then s.controller=s.players[rng:NextInteger(1,#s.players)]; s.alive[s.controller]=false end
  st.console=box(s,'Curator console',0,s.game.height-8,-s.game.depth/2-12,9,4,4,steel,Enum.Material.Metal)
  box(s,'Control booth floor',0,s.game.height-11,-s.game.depth/2-12,30,2,24)
  for _,x in ipairs({-15,15}) do box(s,'Booth glazing',x,s.game.height-3,-s.game.depth/2-12,1,16,24,ice,Enum.Material.Glass).Transparency=.65 end
  if s.controller then api.teleport(s.controller,st.console.Position+Vector3.new(0,4,5)) end
  for _,command in ipairs({'LEFT','RIGHT','ROTATE','DROP'}) do
   local btn=box(s,command,(table.find({'LEFT','RIGHT','ROTATE','DROP'},command)-2.5)*2,s.game.height-5,-s.game.depth/2-12,1.5,.4,2,amber,Enum.Material.Metal)
   api.prompt(btn,command,function(p) if p==s.controller then M.control(s,p,{column=(st.column or 4)+(command=='LEFT' and -1 or command=='RIGHT' and 1 or 0),rotate=command=='ROTATE',drop=command=='DROP'}) end end)
  end
 end
 if k=='tetris' then
  st.board={}; newPiece(s)
  for n=1,7 do
   local b=box(s,'Select next tetromino '..n,(n-4)*3.5,s.game.height-5,-s.game.depth/2-18,2.5,.4,2,amber,Enum.Material.Metal)
   api.prompt(b,'Next piece '..n,function(p) if p==s.controller then M.control(s,p,{piece=n}) end end)
   for _,cell in ipairs(shapes[n]) do box(s,'Piece preview '..n,(n-4)*3.5+cell[1]*.45,s.game.height-3+cell[2]*.45,-s.game.depth/2-18,.42,.42,.5,stone,Enum.Material.Metal) end
  end
  for _,x in ipairs({-32,32}) do box(s,'Shaft wall',x,54,0,3,110,28,steel,Enum.Material.Metal) end
  for _,z in ipairs({-13,13}) do box(s,'Shaft retaining wall',0,5,z,64,10,2,steel,Enum.Material.Metal) end
  st.floor.Size=Vector3.new(62,2,26)
  for i=-2,2 do claim(s,Vector3.new(i*10,2,0),'Line key',20) end
  s.spawnPositions={s.origin+Vector3.new(-18,4,0),s.origin+Vector3.new(0,4,0),s.origin+Vector3.new(18,4,0)}
 elseif k=='maze' or k=='curatormaze' or k=='corridors' then
  mazeSetup(s)
  if k=='corridors' then
   st.hunter:Destroy(); for _,v in ipairs(st.jaws) do v.part:Destroy() end
   for i=1,math.min(12,#st.mazeWall) do local v=st.mazeWall[i]; v.origin=v.part.Position; box(s,'Transit shutter guide',v.origin.X-s.origin.X,14,v.origin.Z-s.origin.Z,2,28,2,steel) end
  end
 elseif k=='duel' then
  st.floor:Destroy(); st.floor=box(s,'Central combat bridge',0,0,0,76,2,16)
  for _,x in ipairs({-38,38}) do for y=0,48,24 do box(s,'Throne floor',x,y,0,22,2,54); box(s,'Balcony bridge',0,y,18,76,2,10) end end
  for _,x in ipairs({-38,38}) do for j=1,24 do box(s,'Tower stair',x,j, -20+j*1.3,16,1.2,3) end end
  s.spawnPositions={s.origin+Vector3.new(-35,4,0),s.origin+Vector3.new(35,4,0)}
  claim(s,Vector3.new(0,3,0),'Royal standard',45)
  st.tools={}
  for _,p in ipairs(s.players) do
   local tool=Instance.new('Tool'); tool.Name='MountainverseBlade'; tool.RequiresHandle=true; tool.CanBeDropped=false
   local handle=Instance.new('Part',tool); handle.Name='Handle'; handle.Size=Vector3.new(.5,4,.7); handle.Color=amber; handle.Material=Enum.Material.Metal; handle.Anchored=false; handle.CanCollide=false; handle.Massless=true
   tool.Grip=CFrame.new(0,-1,0)*CFrame.Angles(math.pi/2,0,0); tool.Parent=p:FindFirstChildOfClass('Backpack') or p.Character
   local hum=p.Character and p.Character:FindFirstChildOfClass('Humanoid'); if hum and p:FindFirstChildOfClass('Backpack') then hum:EquipTool(tool) end
   tool.Activated:Connect(function() if s.running then M.attack(s,p) end end); table.insert(st.tools,tool)
  end
 elseif k=='chess' then
  st.floor:Destroy(); st.tiles=grid(s,8,10); st.pieces={}; st.turn=0
  for _,b in ipairs(st.tiles) do local i=b:GetAttribute('Index'); b.Material=Enum.Material.Marble; b.Color=(math.floor((i-1)/8)+(i-1)%8)%2==0 and Color3.fromRGB(196,190,166) or steel end
  local ranks={'rook','knight','bishop','queen','king','bishop','knight','rook'}
  for side=1,2 do for x=1,8 do for row=1,2 do
   local z=side==1 and row or 9-row; local role=row==2 and 'pawn' or ranks[x]
   local b=box(s,role,(x-4.5)*10,4,(z-4.5)*10,4,role=='king' and 12 or 7,4,side==1 and stone or steel,Enum.Material.Marble)
   if role=='pawn' then b.Shape=Enum.PartType.Ball; b.Size=Vector3.new(4,4,4) end
   if role=='rook' then box(s,'Rook battlement',(x-4.5)*10,9,(z-4.5)*10,7,2,7,stone) end
   if role=='knight' then b.CFrame*=CFrame.Angles(0,0,math.rad(28)) end
   if role=='bishop' then b.Size=Vector3.new(3,10,3) end
   if role=='king' then box(s,'King cross',(x-4.5)*10,11,(z-4.5)*10,8,1.5,1.5,amber) end
   table.insert(st.pieces,{part=b,x=x,z=z,role=role,side=side})
  end end end
 elseif k=='snake' then
  st.snake={}; st.history={}; st.target=2; st.previousNode=1; st.headNode=1; st.route={}
  for i=1,32 do local a=(i-1)*(math.pi*2)/32; st.route[i]=s.origin+Vector3.new(math.cos(a)*32,3+math.sin(a*2)^2*12,math.sin(a)*32) end
  st.head=st.route[1]; for i=1,150 do local a=-(i-1)*.025; st.history[i]=s.origin+Vector3.new(math.cos(a)*32,3+math.sin(a*2)^2*12,math.sin(a)*32) end
  for i=1,18 do local b=box(s,'Linked serpent segment',0,3,0,6,5,6,steel,Enum.Material.Metal); b.CanCollide=false; table.insert(st.snake,b) end
  for i=1,8 do local a=i*(math.pi*2)/8; box(s,'Raised refuge',math.cos(a)*20,4,math.sin(a)*20,8,1,8); claim(s,Vector3.new(math.cos(a)*20,7,math.sin(a)*20),'Signal seal',20) end
 elseif k=='bridge' or k=='drawbridge' or k=='convoy' then
  st.floor:Destroy(); st.raft=nil
  for _,v in ipairs(s.arena:GetChildren()) do if v.Name=='Structural raft' then v:Destroy() end end
  st.decks={}
  for i=1,12 do local b=box(s,'Bridge deck',0,0,(i-6.5)*10,26,2,9.7,steel,Enum.Material.DiamondPlate); table.insert(st.decks,b) end
  for _,z in ipairs({-65,65}) do box(s,'Abutment',0,0,z,42,4,16) end
  s.spawnPositions={s.origin+Vector3.new(0,4,-64)}; st.finish=claim(s,Vector3.new(0,3,64),'Extraction seal',120)
  for _,x in ipairs({-16,16}) do box(s,'Suspension cable',x,8,0,.6,.6,130,steel,Enum.Material.Metal) end
 elseif k=='lift' or k=='risingwater' or k=='flood' or k=='tower' then
  spiral(s)
  if k=='lift' then
   st.cab=box(s,'Lift carriage',0,1,0,30,2,30,steel,Enum.Material.DiamondPlate)
   for _,x in ipairs({-16,16}) do box(s,'Guide rail',x,50,0,1,100,1,steel,Enum.Material.Metal) end
  elseif k=='flood' or k=='risingwater' then st.water=box(s,'Water surface',0,-4,0,80,2,80,ice,Enum.Material.Glass); st.water.Transparency=.4; st.water.CanCollide=false; st.air={}
  elseif k=='tower' then st.levels={}; for i=0,3 do table.insert(st.levels,box(s,'Tower floor',0,i*22,0,64,2,64)) end end
 elseif k=='rotatingmaze' then
  st.drums={}
  for ring=1,3 do for j=1,10 do local a=j*(math.pi*2)/12; local b=box(s,'Rotating drum sector',0,4,0,ring*4+4,8,2,stone); b.CanCollide=false; table.insert(st.drums,{b=b,r=ring*14,a=a,dir=ring%2==0 and -1 or 1}) end end
  claim(s,Vector3.new(43,2,0),'Outer map seal',80)
 elseif k=='rhythm' or k=='memory' or k=='rooms' or k=='switches'  then
  st.tiles=grid(s,k=='rooms' and 3 or 6,k=='rooms' and 30 or 12); st.safe={}; st.next=3
  if k=='rooms' then
   st.roomWalls={}; for i,b in ipairs(st.tiles) do local walls={}; for _,offset in ipairs({Vector3.new(-14,5,0),Vector3.new(14,5,0),Vector3.new(0,5,-14)}) do local wall=make(s,'Room divider',Vector3.new(math.abs(offset.X)>0 and 1 or 20,10,math.abs(offset.X)>0 and 20 or 1),b.Position-s.origin+offset,stone); table.insert(walls,wall) end; st.roomWalls[i]=walls; box(s,'Freight-room rail',b.Position.X-s.origin.X,-2,0,1,.5,100,steel) end
  end
  if k=='switches' then for i=1,4 do local b=box(s,'Relay '..i,(i-2.5)*20,3,-25,5,6,5,steel); trigger(s,b,'Activate relay '..i,function(p) if i==st.phase%4+1 then st.phase+=1; score(s,p,30); b.Color=amber else api.damage(s,p,25,'shock',b) end end) end end
 elseif k=='frozen' or k=='oxygen' or k=='teamescape' or k=='furnace' then
  st.resource={}; st.valves={}; st.activated={}; st.owners={}; st.stationClaims={}
  for i=1,4 do local a=i*(math.pi*2)/4; local b=box(s,'Valve station '..i,math.cos(a)*32,3,math.sin(a)*32,6,6,6,k=='frozen' and amber or steel,Enum.Material.Metal); table.insert(st.valves,b)
   trigger(s,b,'Turn station '..i,function(p) st.activated[i]=os.clock(); st.owners[i]=p; st.stationClaims[p]=st.stationClaims[p] or {}; if not st.stationClaims[p][i] then st.stationClaims[p][i]=true; score(s,p,10) end end)
  end
  if k=='frozen' then for i=1,10 do local b=box(s,'Ice partition',(i%5-2)*16,8,math.floor(i/5)*24-20,4,16,12,ice,Enum.Material.Ice); b.Transparency=.25 end end
  if k=='furnace' then st.mouth=box(s,'Furnace mouth',0,8,-42,30,16,4,danger,Enum.Material.Brick); for x=-30,30,20 do box(s,'Heat baffle',x,4,0,12,8,3,steel) end end
 elseif k=='volcano' then
  st.vents={}; for i=1,3 do local a=i*(math.pi*2)/3; local b=box(s,'Eruption vent',math.cos(a)*25,1,math.sin(a)*25,14,2,14,danger,Enum.Material.Basalt); table.insert(st.vents,b) end
 elseif k=='domino' then
  st.domino={}; for i=1,16 do local x=i%2==0 and -12 or 12; local b=box(s,'Domino '..i,x,12,(i-8)*5,10,24,2,stone); table.insert(st.domino,{b=b,cf=b.CFrame,fallen=false}) end
  claim(s,Vector3.new(0,2,40),'Chain-end seal',90)
 elseif k=='rotor' or k=='clock' or k=='gears' or k=='blades' then
  st.arms={}; local count=k=='gears' and 12 or k=='blades' and 5 or 2
  for i=1,count do local b=box(s,'Driven arm',0,2,0,k=='gears' and 12 or k=='clock' and (i==1 and 72 or 42) or 72,k=='clock' and 2 or 1.2,2,steel,Enum.Material.Metal); b.CanCollide=false; table.insert(st.arms,b) end
  box(s,'Drive shaft',0,6,0,7,12,7,steel,Enum.Material.Metal)
 elseif k=='pendulum' then
  st.bobs={}; for i=1,5 do local b=box(s,'Pendulum bob',(i-3)*18,8,0,9,9,9,steel,Enum.Material.Metal); b.Shape=Enum.PartType.Ball; b.CanCollide=false
   local rod=box(s,'Suspension rod',(i-3)*18,35,0,1,48,1,steel,Enum.Material.Metal); table.insert(st.bobs,{b=b,rod=rod,x=(i-3)*18}) end
 elseif k=='balance' then
  st.pans={box(s,'Left weighing pan',-24,3,0,28,2,40,steel),box(s,'Right weighing pan',24,3,0,28,2,40,steel)}
  box(s,'Weighing beam',0,30,0,78,4,4,steel); for _,x in ipairs({-24,24}) do box(s,'Suspension',x,17,0,1,28,1,steel) end
  st.balanced=0; claim(s,Vector3.new(0,3,30),'Balanced seal',80)
 elseif k=='walls' then
  st.walls={}; for i=1,4 do table.insert(st.walls,actuator(s,'Sliding wall',0,(i-2.5)*20,'x',s.game.width-22,8)) end
 elseif k=='pinball' then
  st.ball=box(s,'Launched steel ball',-35,3,-45,7,7,7,steel,Enum.Material.Metal); st.ball.Shape=Enum.PartType.Ball; st.ball.CanCollide=false; st.velocity=Vector3.new(20,0,24)
  st.bumpers={}; for i=1,5 do local a=i*(math.pi*2)/5; table.insert(st.bumpers,box(s,'Bumper',math.cos(a)*25,3,math.sin(a)*25,7,6,7,amber,Enum.Material.Metal)) end
 elseif k=='gravity' then
  st.ceiling=box(s,'Magnetic ceiling grid',0,45,0,84,1,84,steel,Enum.Material.Metal); st.ceiling.CanCollide=false
  for i=-2,2 do box(s,'Raised landing',i*16,8,0,10,2,20,stone) end
 elseif k=='execution' or k=='press'  then
  st.rams={}; for i=1,6 do local b=box(s,'Guided ram',(i%3-1)*28,24,(math.floor((i-1)/3)-.5)*38,20,6,24,steel,Enum.Material.Metal); table.insert(st.rams,b); box(s,'Guide post',b.Position.X-s.origin.X+11,20,b.Position.Z-s.origin.Z,1.5,40,1.5,steel) end
 elseif k=='wheel' then
  st.gondolas={}; for i=1,10 do local b=box(s,'Wheel gondola',0,1,0,18,2,15,steel,Enum.Material.DiamondPlate); table.insert(st.gondolas,b) end
  box(s,'Bearing axle',0,44,0,10,10,36,steel)
 elseif k=='platforms' or k=='collapse' or k=='shrink' then
  st.floor:Destroy(); for _,v in ipairs(s.arena:GetChildren()) do if v.Name=='Structural raft' then v:Destroy() end end
  st.tiles=grid(s,8,12); st.loads={}
 elseif k=='debris' then st.falls={}
 elseif k=='statues' then
  st.statues={}; for i=1,5 do local a=i*(math.pi*2)/5; local b=box(s,'Witness',math.cos(a)*38,5,math.sin(a)*38,4,10,4,stone,Enum.Material.Marble); b.CanCollide=false; table.insert(st.statues,b) end
 elseif k=='crane' then
  st.targetX=0; st.dropUntil=0; st.load=box(s,'Suspended cargo',0,30,0,14,12,14,steel,Enum.Material.Metal)
  st.cable=box(s,'Hoist cable',0,55,0,.4,44,.4,steel,Enum.Material.Metal); box(s,'Jib',0,80,0,100,5,5,steel)
 elseif k=='shift' then
  st.floor:Destroy(); for _,v in ipairs(s.arena:GetChildren()) do if v.Name=='Structural raft' then v:Destroy() end end
  for _,x in ipairs({-44,44}) do box(s,'Transfer dock',x,0,0,12,2,100,stone) end
  st.finish=claim(s,Vector3.new(44,3,34),'Transfer extraction',120); s.spawnPositions={s.origin+Vector3.new(-44,4,-34)}
  st.platforms={}; for i=1,4 do table.insert(st.platforms,box(s,'Transfer platform',-30,0,(i-2.5)*22,24,2,18,steel)); box(s,'Platform transfer rail',0,-2,(i-2.5)*22,90,.8,1,steel,Enum.Material.Metal) end
 elseif k=='pillars' then
  st.columns={}; for x=-2,2 do for z=-2,2 do table.insert(st.columns,box(s,'Pressure column',x*17,0,z*17,13,12,13,steel)); box(s,'Hydraulic cylinder socket',x*17,-4,z*17,15,4,15,stone) end end
 elseif k=='resonance' then st.rings={}

 end
 if k=='bulkhead' then
  st.doors={}; st.doorUntil={}; st.keyCount=0
  for _,x in ipairs({-50,50}) do box(s,'Bulkhead side wall',x,10,0,2,20,100,steel) end
  for i=1,3 do
   local z=(i-2)*28; local pair={box(s,'Bulkhead left leaf',-25,10,z,50,20,4,steel),box(s,'Bulkhead right leaf',25,10,z,50,20,4,steel)}
   st.doors[i]={parts=pair,open=0,z=z}; st.doorUntil[i]=0
   box(s,'Rack and pinion housing',0,23,z,100,4,6,steel)
   local console=box(s,'Interlock '..i,36,3,z-7,4,6,4,amber)
   trigger(s,console,'Unlock gate '..i,function(p)
    if st.keyCount>=i then st.doorUntil[i]=os.clock()+8; score(s,p,10) else s.api.send(p,'toast','Collect lock tooth '..i..' before using this interlock') end
   end)
   local key=claim(s,Vector3.new(i%2==0 and 22 or -22,3,z-10),'Lock tooth '..i,25); st.pickups[#st.pickups].keyIndex=i
  end
  st.finish=claim(s,Vector3.new(0,3,44),'Bulkhead extraction',120)
  s.spawnPositions={s.origin+Vector3.new(0,4,-43)}
 elseif k=='machine' then
  st.stage={}; st.rollers={}; st.rams={}
  for i=1,3 do local b=box(s,'Intake roller',0,0,-50+i*7,80,4,4,steel); b.Shape=Enum.PartType.Cylinder; table.insert(st.rollers,b) end
  for x=-28,28,28 do local b=box(s,'Compression head',x,22,0,20,6,24,steel); table.insert(st.rams,b); box(s,'Compression guide',x+11,18,0,2,36,2,steel) end
  st.exhaust=box(s,'Exhaust shutter',0,7,36,48,14,3,steel)
  st.finish=claim(s,Vector3.new(0,3,55),'Exhaust extraction',140)
  s.spawnPositions={s.origin+Vector3.new(0,4,-56)}
 elseif k=='finale' then
  -- Two genuine stair routes outside the slab edges, with landings and timed physical interlocks.
  for y=24,48,24 do box(s,'Summit storey',0,y,0,70,2,100,stone) end
  for i=1,48 do box(s,'First summit stair',-45,i*.5,-48+i*1.5,12,.5,2); box(s,'Second summit stair',45,24+i*.5,24-i*1.5,12,.5,2) end
  box(s,'First upper landing',-40,24,24,22,2,16); box(s,'Second stair landing',40,24,24,22,2,16); box(s,'Summit landing',40,48,-48,22,2,16)
  st.summitGates={box(s,'First phase interlock',-45,14,-15,15,18,3,steel),box(s,'Second phase interlock',45,35,0,15,18,3,steel)}
  st.tiles={}; for x=-1,1 do for z=-1,1 do table.insert(st.tiles,box(s,'Summit memory cell',x*24,25.1,z*24,22,.2,22,stone)) end end
  st.safe={}; st.next=0
  st.finalArm=box(s,'Summit final sweeper',0,50,0,66,1,2,steel); st.finalArm.CanCollide=false
  st.finish=claim(s,Vector3.new(0,52,-38),'Summit extraction',200); st.exitUnlock=65
 elseif k=='mirrors' then
  for _,b in ipairs(st.beams or {}) do b:Destroy() end
  st.beams={}; st.mirrors={}; st.blockers={}; st.next=0
  for i,v in ipairs({{-30,-24,.785},{30,-24,-.785},{30,26,.785},{-30,26,-.785}}) do
   local b=box(s,'Optical mirror',v[1],6,v[2],.8,12,20,ice,Enum.Material.Glass); b.CFrame=CFrame.new(b.Position)*CFrame.Angles(0,v[3],0); table.insert(st.mirrors,b)
  end
  for _,x in ipairs({-50,50}) do table.insert(st.blockers,box(s,'Optical perimeter wall',x,7,0,2,14,100,stone)); table.insert(st.blockers,box(s,'Optical perimeter wall',0,7,x,100,14,2,stone)) end
  for _,x in ipairs({-15,15}) do table.insert(st.blockers,box(s,'Opaque optical baffle',x,6,0,6,12,10,stone)) end
  st.emitter=box(s,'Beam emitter',0,3,-43,4,4,4,amber)
 end
 if k=='wheel' or k=='lift' or k=='risingwater' or k=='tower' then
  local pos=k=='wheel' and Vector3.new(0,87,0) or k=='lift' and Vector3.new(0,78,0) or Vector3.new(0,75,24)
  st.finish=claim(s,pos,'Upper extraction seal',120)
 end
 if k=='clock' then st.finish=claim(s,Vector3.new(0,3,-35),'Bell refuge seal',120); st.exitUnlock=s.game.duration*.7 end
 if #st.pickups==0 and k~='tetris' then for i=1,6 do local a=i*(math.pi*2)/6; claim(s,Vector3.new(math.cos(a)*s.game.width*.28,3,math.sin(a)*s.game.depth*.28),'Trial seal',20) end end
end
local function movePlatform(s,b,pos)
 local delta=pos-b.Position
 for _,p in ipairs(s.api.alive(s)) do local r=s.api.root(p); if r and on(s,p,b,0) and r.Position.Y>b.Position.Y then p.Character:PivotTo(p.Character:GetPivot()+delta) end end
 b.Position=pos
end
local function chessMoves(st,piece)
 local choices={}; local function at(x,z) for _,p in ipairs(st.pieces) do if p.part.Parent and p.x==x and p.z==z then return p end end end
 local function add(x,z)
  if x<1 or x>8 or z<1 or z>8 then return false end
  local other=at(x,z)
  if not other or other.side~=piece.side then table.insert(choices,{x=x,z=z,capture=other}) end
  return not other
 end
 local r=piece.role
 if r=='knight' then for _,v in ipairs({{1,2},{2,1},{-1,2},{-2,1},{1,-2},{2,-1},{-1,-2},{-2,-1}}) do add(piece.x+v[1],piece.z+v[2]) end
 elseif r=='pawn' then
  local dir=piece.side==1 and 1 or -1
  if not at(piece.x,piece.z+dir) then add(piece.x,piece.z+dir) end
  for _,dx in ipairs({-1,1}) do local target=at(piece.x+dx,piece.z+dir); if target and target.side~=piece.side then add(piece.x+dx,piece.z+dir) end end
 else
  local dirs=r=='rook' and {{1,0},{-1,0},{0,1},{0,-1}} or r=='bishop' and {{1,1},{1,-1},{-1,1},{-1,-1}} or {{1,0},{-1,0},{0,1},{0,-1},{1,1},{1,-1},{-1,1},{-1,-1}}
  for _,v in ipairs(dirs) do for n=1,(r=='king' and 1 or 7) do if not add(piece.x+v[1]*n,piece.z+v[2]*n) then break end end end
 end
 return choices
end
local function rayBox(origin,direction,b)
 local o=b.CFrame:PointToObjectSpace(origin); local q=b.CFrame:PointToObjectSpace(origin+direction)-o
 local nearT,farT=0,200
 for _,axis in ipairs({'X','Y','Z'}) do
  local ov,dv,half=o[axis],q[axis],b.Size[axis]/2
  if math.abs(dv)<.00001 then if math.abs(ov)>half then return nil end
  else local a,c=(-half-ov)/dv,(half-ov)/dv; if a>c then a,c=c,a end; nearT=math.max(nearT,a); farT=math.min(farT,c); if nearT>farT then return nil end end
 end
 return nearT>.02 and nearT or nil
end
local function rebuildOptics(s,angle)
 local st=s.state
 for _,b in ipairs(st.beams) do b:Destroy() end; st.beams={}
 local origin=st.emitter.Position; local dir=Vector3.new(math.sin(angle),0,math.cos(angle))
 for bounce=1,6 do
  local distance=120; local mirror=nil
  for _,b in ipairs(st.blockers) do local n=rayBox(origin,dir,b); if n and n<distance then distance=n; mirror=nil end end
  for _,b in ipairs(st.mirrors) do local n=rayBox(origin,dir,b); if n and n<distance then distance=n; mirror=b end end
  local mid=origin+dir*distance/2; local b=make(s,'Reflected optical segment',Vector3.new(distance,.5,.5),mid-s.origin,amber,Enum.Material.Neon); b.CFrame=CFrame.lookAt(mid,mid+dir)*CFrame.Angles(0,math.pi/2,0); b.CanCollide=false; table.insert(st.beams,b)
  if not mirror then break end
  local normal=(mirror.CFrame:PointToWorldSpace(Vector3.new(1,0,0))-mirror.Position).Unit
  local hit=origin+dir*distance; dir=(dir-normal*(2*dir:Dot(normal))).Unit; origin=hit+dir*.1
 end
end
function M.attack(s,p)
 if s.game.kind~='duel' or not s.alive[p] then return end
 local r=s.api.root(p); if not r then return end
 local now=os.clock(); if now-(s.state.hitTimes[p] or 0)<.7 then return end; s.state.hitTimes[p]=now
 for _,motor in ipairs(p.Character:GetDescendants()) do if motor:IsA('Motor6D') and string.find(string.lower(motor.Name),'right') and string.find(string.lower(motor.Name),'shoulder') then
  local initial=motor.C0; Tween:Create(motor,TweenInfo.new(.12),{C0=initial*CFrame.Angles(-1.5,0,-.7)}):Play(); task.delay(.22,function() if motor.Parent then Tween:Create(motor,TweenInfo.new(.2),{C0=initial}):Play() end end)
 end end
 for _,other in ipairs(s.api.alive(s)) do if other~=p then local target=s.api.root(other)
  if target and (target.Position-r.Position).Magnitude<9 and r.CFrame.LookVector:Dot((target.Position-r.Position).Unit)>.15 then s.api.damage(s,other,34,'combat',r); score(s,p,12) end
 end end
end
function M.step(s,dt,now)
 local st=s.state; local k=s.game.kind; local t=now-s.startedAt; local intensity=1+t/s.game.duration*.6+(s.difficulty-1)*.12
 -- Objective collection is server-distance checked; exits accept every qualified arrival.
 for i=#st.pickups,1,-1 do local v=st.pickups[i]
  if not v.part.Parent then table.remove(st.pickups,i) else
   for _,p in ipairs(s.api.alive(s)) do
    if near(s,p,v.part.Position,4.5) then
     if v.part==st.finish then
      st.extracted=st.extracted or {}
      if not st.extracted[p] and t>=(st.exitUnlock or 0) then st.extracted[p]=true; score(s,p,v.points); s.api.send(p,'toast','EXTRACTION RECORDED / remain alive until the phase ends') end
     else
      if v.keyIndex then st.keyCount=math.max(st.keyCount or 0,v.keyIndex) end
      score(s,p,v.points); st.objectives[p]=(st.objectives[p] or 0)+1; v.part:Destroy(); table.remove(st.pickups,i); break
     end
    end
   end
  end
 end
 if k=='tetris' then
  local c=cells(st,st.column,st.rotation); local land=landing(st,c); st.fallRow-=dt*(st.fast and 14 or 2.2)*intensity
  for i,v in ipairs(c) do
   local b=st.active[i]; b.Position=s.origin+Vector3.new((v[1]-5.5)*6,(math.max(st.fallRow,land)+v[2]) *6-3,0)
   local sh=st.shadows[i]; sh.Size=Vector3.new(5.9,.1,23); sh.Position=s.origin+Vector3.new((v[1]-5.5)*6,.15,0)
   hits(s,b,dt,'crush',true)
  end
  if st.fallRow<=land then
   for i,v in ipairs(c) do local y=land+v[2]; local b=st.active[i]; b.CanCollide=true; st.board[v[1]..':'..y]={part=b,x=v[1],y=y}; st.shadows[i]:Destroy() end
   local full={}; for y=1,20 do local n=0; for x=1,10 do if st.board[x..':'..y] then n+=1 end end; if n==10 then table.insert(full,y) end end
   if #full>0 then
    local updated={}
    for _,cell in pairs(st.board) do
     if table.find(full,cell.y) then cell.part:Destroy() else
      local drop=0; for _,y in ipairs(full) do if y<cell.y then drop+=1 end end; cell.y-=drop; cell.part.Position-=Vector3.new(0,drop*6,0); updated[cell.x..':'..cell.y]=cell
     end
    end
    st.board=updated; if s.controller then score(s,s.controller,40*#full) end; s.hint='LINE CLEAR / '..#full; s.api.audio(s,'line')
    for _,p in ipairs(s.api.alive(s)) do score(s,p,20*#full) end
   end
   s.api.audio(s,'impact')
   if land>=16 then
    for _,p in ipairs(s.api.alive(s)) do s.api.kill(s,p,'crush',st.active[1]) end; s.finish=true
   else newPiece(s) end
  end
 elseif k=='corridors' then
  local active=math.floor(t/6)%math.min(12,#st.mazeWall)+1
  for i=1,math.min(12,#st.mazeWall) do local gate=st.mazeWall[i]; local open=i==active; local target=gate.origin+Vector3.new(0,open and 16 or 0,0)
   local delta=target-gate.part.Position; gate.part.Position+=delta*math.min(1,dt*3)
   if open and delta.Magnitude<2 then st.graph[gate.a][gate.b]=true; st.graph[gate.b][gate.a]=true; gate.part.CanCollide=false
   else st.graph[gate.a][gate.b]=nil; st.graph[gate.b][gate.a]=nil; gate.part.CanCollide=true; if not open and delta.Magnitude>.2 then hits(s,gate.part,dt,'crush',true) end end
  end
  s.hint='TRANSIT SHORTCUT '..active..' / COLLECT THREE ROUTE SEALS'
 elseif k=='maze' or k=='curatormaze' then
  local target,closest=nil,math.huge
  for _,p in ipairs(s.api.alive(s)) do local r=s.api.root(p); if r then local dist=(r.Position-st.hunter.Position).Magnitude; if dist<closest then target=p; closest=dist end end end
  if now>=st.repath then
   st.repath=now+1.2; local to=rng:NextInteger(1,81)
   if target and closest<70 then local r=s.api.root(target); local x=math.clamp(math.floor((r.Position.X-s.origin.X)/12+5.5),1,9); local z=math.clamp(math.floor((r.Position.Z-s.origin.Z)/12+5.5),1,9); to=(x-1)*9+z; st.mode='pursuit' else st.mode='patrol' end
   st.route=bfs(st,st.hunterNode,to)
  end
  local nextNode=st.route[1]
  if nextNode then local delta=st.nodes[nextNode]-st.hunter.Position; if delta.Magnitude<.4 then st.hunterNode=nextNode; table.remove(st.route,1) else st.hunter.Position+=delta.Unit*math.min(delta.Magnitude,dt*(10+t*.05)) end end
  for _,jaw in ipairs(st.jaws) do jaw.part.CFrame=CFrame.new(st.hunter.Position)*CFrame.Angles(0,0,jaw.side*(.4+math.sin(t*4)*.25))*CFrame.new(jaw.side*2,0,-1) end
  hits(s,st.hunter,dt,'consume',true); s.hint='HUNTER / '..st.mode..' / objective seals: '..#st.pickups
  if k=='curatormaze' then st.hunter.Color=st.gateMode and amber or danger end
 elseif k=='duel' then s.hint='CLICK / F / TAP STRIKE · 9 Studs reach · 0.7s recovery'
 elseif k=='chess' then
  if st.moving then
   local m=st.moving; local alpha=math.clamp((now-m.start)/1.3,0,1)
   if alpha>.45 then m.piece.part.Position=m.from:Lerp(m.to,(alpha-.45)/.55); hits(s,m.piece.part,dt,'crush',true) end
   if alpha>=1 then if m.capture then m.capture.part:Destroy() end; m.piece.x=m.x; m.piece.z=m.z; if m.piece.role=='pawn' and (m.z==1 or m.z==8) then m.piece.role='queen'; m.piece.part.Size=Vector3.new(5,10,5) end; m.warn:Destroy(); st.moving=nil end
  elseif now>=st.next then
   st.next=now+2/intensity; st.turn=st.turn%2+1; local choices={}
   for _,p in ipairs(st.pieces) do if p.side==st.turn and p.part.Parent then local moves=chessMoves(st,p); for _,v in ipairs(moves) do v.piece=p; table.insert(choices,v) end end end
   if #choices>0 then local m=choices[rng:NextInteger(1,#choices)]; m.from=m.piece.part.Position; m.to=s.origin+Vector3.new((m.x-4.5)*10,m.piece.part.Size.Y/2,(m.z-4.5)*10); m.start=now; m.warn=marker(s,(m.x-4.5)*10,(m.z-4.5)*10); st.moving=m; s.hint=string.upper(m.piece.role)..' → '..m.x..':'..m.z end
  end
 elseif k=='snake' then
  local destination=st.route[st.target]; local delta=destination-st.head
  if delta.Magnitude<.3 then
   st.previousNode=st.headNode; st.headNode=st.target
   local options={st.headNode%32+1,(st.headNode-2)%32+1}
   if (st.headNode-1)%8==0 then table.insert(options,(st.headNode+7)%32+1) end
   local valid={}; for _,node in ipairs(options) do if node~=st.previousNode then table.insert(valid,node) end end
   st.target=valid[rng:NextInteger(1,#valid)]
  else st.head+=delta.Unit*math.min(delta.Magnitude,dt*12*intensity) end
  if (st.head-st.history[1]).Magnitude>.8 then table.insert(st.history,1,st.head); if #st.history>240 then table.remove(st.history) end end
  for i,b in ipairs(st.snake) do
   local wanted=(i-1)*5.5; local accumulated=0; local pos=st.history[#st.history]; local facing=destination
   for j=2,#st.history do local segment=(st.history[j]-st.history[j-1]).Magnitude
    if accumulated+segment>=wanted and segment>.001 then pos=st.history[j-1]:Lerp(st.history[j],(wanted-accumulated)/segment); facing=st.history[j-1]; break end; accumulated+=segment
   end
   if (facing-pos).Magnitude<.01 then facing=pos+Vector3.new(1,0,0) end
   b.CFrame=CFrame.lookAt(pos,facing); hits(s,b,dt,'crush',true)
  end
 elseif k=='bridge' then
  for i,b in ipairs(st.decks) do if t>i*4 then b.Transparency=math.clamp((t-i*4)/1.4,0,1); if t>i*4+1.4 then b.CanCollide=false; b.Position-=Vector3.new(0,dt*12,0) end end end
  s.hint='DECK FAILURE IN SEQUENCE / REACH FAR ABUTMENT'
 elseif k=='drawbridge' then
  for i,b in ipairs(st.decks) do local a=math.sin(t*.35)*.65; local z=(i-6.5)*10; local y=math.abs(z)*math.sin(math.abs(a)); movePlatform(s,b,s.origin+Vector3.new(0,y,z)); b.CFrame=CFrame.new(b.Position)*CFrame.Angles(z<0 and a or -a,0,0) end
 elseif k=='convoy' then
  if not st.gantry then st.gantry=box(s,'Loading profile',0,4,65,18,8,3,steel) end
  st.gantry.Position=s.origin+Vector3.new(math.sin(t*.4)*10,4,65-(t*12)%135); hits(s,st.gantry,dt,'combat',true)
 elseif k=='lift' then
  local y=(math.sin(t*.1-math.pi/2)+1)*36; movePlatform(s,st.cab,s.origin+Vector3.new(0,y,0)); s.hint='LIFT ALTITUDE '..math.floor(y)..' / EXIT TO LANDINGS'
 elseif k=='flood' or k=='risingwater' then
  local y=k=='risingwater' and t*.85-5 or 24+math.sin(t*.12)*8; st.water.Position=s.origin+Vector3.new(0,y,0)
  for _,p in ipairs(s.api.alive(s)) do local r=s.api.root(p); st.air[p]=math.clamp((st.air[p] or 12)+(r and r.Position.Y<s.origin.Y+y and -dt or dt*2),0,12); if st.air[p]<=0 then s.api.kill(s,p,'drown',st.water) end end
  s.hint='WATER LEVEL '..math.floor(y)..' / CLIMB / AIR: 12s underwater'
 elseif k=='tower' then
  for i,b in ipairs(st.levels) do if t>i*16 then b.CanCollide=false; b.Transparency=.85; b.Position-=Vector3.new(0,dt*9,0) end end
 elseif k=='rotatingmaze' then
  for _,v in ipairs(st.drums) do local a=v.a+t*.14*v.dir; v.b.CFrame=CFrame.new(s.origin+Vector3.new(math.cos(a)*v.r,4,math.sin(a)*v.r))*CFrame.Angles(0,-a,0); hits(s,v.b,dt,'crush',false) end
 elseif k=='rhythm' or k=='memory' or k=='rooms'  then
  local period=k=='rhythm' and 3.5 or k=='rooms' and 7 or 6
  if now>=st.next then
   st.next=now+period; st.phase+=1; st.reveal=now;
   if k=='rooms' then
    for i,b in ipairs(st.tiles) do local sign=i%2==0 and 1 or -1; local delta=Vector3.new(sign*(st.phase%2==0 and -8 or 8),0,0); movePlatform(s,b,b.Position+delta); for _,wall in ipairs(st.roomWalls[i]) do wall.Position+=delta end end
   end
 st.safe={}; local safeIndex=rng:NextInteger(1,#st.tiles)
   for i,b in ipairs(st.tiles) do st.safe[i]=k=='memory' and rng:NextNumber()<.32 or i==safeIndex; b.Color=st.safe[i] and amber or stone; b.Transparency=0 end
   st.safe[safeIndex]=true; s.hint=(k=='memory' and 'MEMORIZE THE AMBER CELLS' or 'SAFE ROOM / CELL: '..safeIndex)
  end
  local elapsed=now-(st.reveal or now)
  if k=='memory' and elapsed>1.5 and elapsed<3 then for _,b in ipairs(st.tiles) do b.Color=stone end end
  if elapsed>period-1.3 then
   for i,b in ipairs(st.tiles) do if not st.safe[i] then b.Color=danger; for _,p in ipairs(s.api.alive(s)) do if on(s,p,b,0) then s.api.damage(s,p,dt*90,'shock',b) end end end end
  end
 elseif k=='switches' then
  s.hint='NEXT RELAY: '..(st.phase%4+1)..' / '..st.phase..' CONNECTED'
  if st.phase>=8 then for _,p in ipairs(s.api.alive(s)) do score(s,p,80) end; s.finish=true end
 elseif k=='frozen' or k=='oxygen' or k=='teamescape' or k=='furnace' then
  for _,p in ipairs(s.api.alive(s)) do
   local warm=false; local shelter=false
   for i,b in ipairs(st.valves) do if near(s,p,b.Position,12) and (k~='oxygen' or i==math.floor(t/12)%4+1) then warm=true end end
   if k=='teamescape' then
    local total=0; local owners={}; for i,time in pairs(st.activated) do if now-time<12 then total+=1; owners[st.owners[i]]=true end end
    local unique=0; for _ in pairs(owners) do unique+=1 end
    s.hint='SIMULTANEOUS RELIEF VALVES: '..total..'/4'
    if total>=4 and unique>=math.min(4,#s.players) then score(s,p,120); st.completed=true; s.finish=true end
   elseif k=='furnace' then
    local r=s.api.root(p); local localZ=r and r.Position.Z-s.origin.Z or 0
    shelter=localZ>3 and r and math.abs((r.Position.X-s.origin.X+30)%20-0)<7
    if t%9>5 and not shelter and not warm then s.api.damage(s,p,dt*24,'burn',st.mouth) end
    s.hint=t%9>4 and 'FURNACE OPEN / USE BAFFLES' or 'VENTILATION WINDOW'
   else
    st.resource[p]=math.clamp((st.resource[p] or 15)+(warm and dt*4 or -dt),0,15)
    if st.resource[p]<=0 then s.api.kill(s,p,k=='frozen' and 'freeze' or 'drown',st.valves[1]) end
    s.api.send(p,'resource',{label=k=='frozen' and 'HEAT' or 'OXYGEN',value=math.ceil(st.resource[p]),max=15})
   end
  end
 elseif k=='volcano' then
  local active=math.floor(t/5)%3+1
  for i,b in ipairs(st.vents) do b.Color=i==active and danger or steel; b.Size=Vector3.new(14,i==active and t%5>2 and 28 or 2,14); if i==active and t%5>2 then hits(s,b,dt,'burn',true) end end
 elseif k=='domino' then
  for i,v in ipairs(st.domino) do local a=math.clamp((t-i*2)/1.8,0,1)*1.5; v.b.CFrame=v.cf*CFrame.new(0,-12,0)*CFrame.Angles(a,0,0)*CFrame.new(0,12,0); if a>0 and a<1.5 then hits(s,v.b,dt,'crush',true) end end
 elseif k=='rotor' or k=='clock' or k=='gears' or k=='blades' then
  for i,b in ipairs(st.arms) do
   local a=t*(k=='clock' and .2/(i==1 and 1 or 12) or k=='gears' and .6 or .35)+i*(math.pi*2)/#st.arms
   local r=k=='gears' and 31 or k=='blades' and 24 or 0
   b.CFrame=CFrame.new(s.origin+Vector3.new(math.cos(a)*r,2,math.sin(a)*r))*CFrame.Angles(0,-a,0); hits(s,b,dt,k=='blades' and 'combat' or 'crush',false)
  end
 elseif k=='pendulum' then
  for i,v in ipairs(st.bobs) do local a=math.sin(t*.8+i)*.9; v.b.Position=s.origin+Vector3.new(v.x,48-42*math.cos(a),42*math.sin(a)); v.rod.CFrame=CFrame.new(s.origin+Vector3.new(v.x,48-21*math.cos(a),21*math.sin(a)))*CFrame.Angles(a,0,0); hits(s,v.b,dt,'combat',true) end
 elseif k=='balance' then
  local counts={0,0}; for _,p in ipairs(s.api.alive(s)) do for i,b in ipairs(st.pans) do if on(s,p,b,0) then counts[i]+=1 end end end
  local tilt=counts[1]-counts[2]
  for i,b in ipairs(st.pans) do movePlatform(s,b,s.origin+Vector3.new(i==1 and -24 or 24,3+(i==1 and -tilt or tilt)*3,0)) end
  st.balanced=tilt==0 and st.balanced+dt or 0; s.hint='BALANCE '..counts[1]..':'..counts[2]..' / HOLD 8s'
  if st.balanced>8 and counts[1]+counts[2]>0 then for _,p in ipairs(s.api.alive(s)) do score(s,p,100) end; st.completed=true; s.finish=true end
 elseif k=='walls' then
  for i,b in ipairs(st.walls) do local x=math.sin(t*.35+i*1.5)*37; b.Position=s.origin+Vector3.new(x,6,(i-2.5)*20); hits(s,b,dt,'crush',false) end
 elseif k=='pinball' then
  local b=st.ball; b.Position+=st.velocity*dt
  local v=b.Position-s.origin
  if math.abs(v.X)>44 then st.velocity=Vector3.new(-st.velocity.X,0,st.velocity.Z) end
  if math.abs(v.Z)>54 then st.velocity=Vector3.new(st.velocity.X,0,-st.velocity.Z) end
  for _,bumper in ipairs(st.bumpers) do if (bumper.Position-b.Position).Magnitude<8 then st.velocity=(b.Position-bumper.Position).Unit*32 end end
  hits(s,b,dt,'combat',true)
 elseif k=='gravity' then
  local phase=t%12; s.hint=phase>7 and 'MAGNETIC PULSE / LAND ON A RAISED PLATFORM' or 'MAGNET DISCHARGING'
  if phase>8 and phase<10 then for _,p in ipairs(s.api.alive(s)) do local r=s.api.root(p); if r then r.AssemblyLinearVelocity+=Vector3.new(0,dt*245,0) end end end
  if phase>9 then hits(s,st.ceiling,dt,'shock',true) end
 elseif k=='execution' or k=='press'  then
  for i,b in ipairs(st.rams) do local cycle=(t+i*(k=='execution' and .7 or 1.5))%7; local y=cycle<4 and 24 or cycle<5 and 24-(cycle-4)*21 or 3+(cycle-5)*10
   b.Position=Vector3.new(b.Position.X,s.origin.Y+y,b.Position.Z); b.Color=cycle>3 and cycle<5 and danger or steel; if cycle>=4 and cycle<5.5 then hits(s,b,dt,'crush',true) end
  end
 elseif k=='wheel' then
  for i,b in ipairs(st.gondolas) do local a=t*.12+i*(math.pi*2)/10; movePlatform(s,b,s.origin+Vector3.new(math.cos(a)*40,44+math.sin(a)*40,0)) end
 elseif k=='platforms' or k=='collapse' or k=='shrink' then
  for i,b in ipairs(st.tiles) do
   local load=0; for _,p in ipairs(s.api.alive(s)) do if on(s,p,b,0) then load+=1 end end
   st.loads[i]=(st.loads[i] or 0)+load*dt
   local row=math.floor((i-1)/8); local col=(i-1)%8
   local failed=k=='shrink' and (math.min(row,col,7-row,7-col)<math.floor(t/18)) or k=='collapse' and st.loads[i]>2.5 or k=='platforms' and (i%5==math.floor(t/8)%5 and t%8>4)
   b.Color=(st.loads[i]>1.5 or failed) and danger or stone
   if failed then b.CanCollide=false; b.Transparency=.85 else b.CanCollide=true; b.Transparency=0 end
  end
 elseif k=='debris' then
  if now>=st.next then st.next=now+1.5/intensity; local x,z=rng:NextNumber(-42,42),rng:NextNumber(-42,42); local warn=marker(s,x,z); local b=box(s,'Falling masonry',x,55,z,8,8,8,stone); b.CanCollide=false; table.insert(st.falls,{b=b,warn=warn,starts=now+1.5}) end
  for i=#st.falls,1,-1 do local v=st.falls[i]; if now>v.starts then v.b.Position-=Vector3.new(0,dt*45,0); hits(s,v.b,dt,'crush',true); if v.b.Position.Y<s.origin.Y-8 then v.b:Destroy(); v.warn:Destroy(); table.remove(st.falls,i) end end end
 elseif k=='statues' then
  for _,b in ipairs(st.statues) do local watched=false; local closest,dist=nil,math.huge
   for _,p in ipairs(s.api.alive(s)) do local r=s.api.root(p); if r then local delta=b.Position-r.Position; if delta.Magnitude>0 and r.CFrame.LookVector:Dot(delta.Unit)>.45 then watched=true end; if delta.Magnitude<dist then closest=r; dist=delta.Magnitude end end end
   if not watched and closest and dist>.1 then local d=Vector3.new(closest.Position.X-b.Position.X,0,closest.Position.Z-b.Position.Z); if d.Magnitude>.1 then b.Position+=d.Unit*dt*10 end end
   hits(s,b,dt,'consume',true)
  end
 elseif k=='crane' then
  if not s.controller then st.targetX=math.sin(t*.6)*36; st.dropUntil=t%7>4 and now+1 or 0 end
  local y=now<st.dropUntil and 5 or 32
  st.load.Position=st.load.Position:Lerp(s.origin+Vector3.new(st.targetX or 0,y,math.sin(t*.23)*30),math.min(1,dt*2)); st.cable.Position=Vector3.new(st.load.Position.X,s.origin.Y+(80+(st.load.Position.Y-s.origin.Y))/2,st.load.Position.Z); st.cable.Size=Vector3.new(.4,80-(st.load.Position.Y-s.origin.Y),.4); hits(s,st.load,dt,'crush',true)
 elseif k=='shift' then
  for i,b in ipairs(st.platforms) do movePlatform(s,b,s.origin+Vector3.new(math.sin(t*.3+i)*30,0,(i-2.5)*22)) end
 elseif k=='pillars' then
  for i,b in ipairs(st.columns) do local y=math.max(0,math.sin(t*.4+i*.7))*20; movePlatform(s,b,Vector3.new(b.Position.X,s.origin.Y+y,b.Position.Z)) end
 elseif k=='resonance' then
  if now>=st.next then st.next=now+4; table.insert(st.rings,{r=2}) end
  for i=#st.rings,1,-1 do local v=st.rings[i]; v.r+=dt*10
   if not v.parts then v.parts={}; for j=1,24 do local b=box(s,'Pressure ring',0,1,0,4,.8,2,amber,Enum.Material.Neon); b.CanCollide=false; table.insert(v.parts,b) end end
   for j,b in ipairs(v.parts) do local a=j*(math.pi*2)/24; b.Position=s.origin+Vector3.new(math.cos(a)*v.r,1,math.sin(a)*v.r); hits(s,b,dt,'shock',false) end
   if v.r>60 then for _,b in ipairs(v.parts) do b:Destroy() end; table.remove(st.rings,i) end
  end
 elseif k=='bulkhead' then
  for i,v in ipairs(st.doors) do
   local goal=now<st.doorUntil[i] and 1 or 0; local previous=v.open; v.open+=math.clamp(goal-v.open,-dt*.6,dt*.6)
   for j,b in ipairs(v.parts) do b.Position=s.origin+Vector3.new((j==1 and -1 or 1)*(25+v.open*24),10,v.z); if v.open<previous then hits(s,b,dt,'crush',true) end end
  end
  s.hint='LOCK TEETH '..st.keyCount..'/3 / INTERLOCK WINDOW 8s'
 elseif k=='machine' then
  for i,b in ipairs(st.rollers) do b.CFrame=CFrame.new(b.Position)*CFrame.Angles(t*2,0,0); if t%8>5 then hits(s,b,dt,'crush',false) end end
  for i,b in ipairs(st.rams) do local phase=(t+i*1.4)%7; local y=phase<4 and 24 or phase<5 and 24-(phase-4)*21 or 3+(phase-5)*10; b.Position=Vector3.new(b.Position.X,s.origin.Y+y,b.Position.Z); if phase>4 and phase<5.5 then hits(s,b,dt,'crush',true) end end
  st.exhaust.Position=s.origin+Vector3.new(math.sin(t*.5)*26,7,36); if t%10>6 then hits(s,st.exhaust,dt,'burn',true) end
  for _,p in ipairs(s.api.alive(s)) do local r=s.api.root(p); if r then local z=r.Position.Z-s.origin.Z; local stage=st.stage[p] or 1; if stage==1 and z>-20 then st.stage[p]=2; score(s,p,25) elseif stage==2 and z>22 then st.stage[p]=3; score(s,p,25) end; if z<-20 then r.AssemblyLinearVelocity+=Vector3.new(0,0,dt*5) end end end
  s.hint='INTAKE → COMPRESSION → EXHAUST / CROSS ALL THREE'
 elseif k=='finale' then
  local phase=t<25 and 1 or t<50 and 2 or 3; s.hint='SUMMIT PHASE '..phase..'/3 / EXTRACTION AFTER 65s'
  for i,b in ipairs(st.summitGates) do b.CanCollide=t<i*25; b.Transparency=b.CanCollide and 0 or .85 end
  if now>=st.next then st.next=now+6; st.safe={}; local safe=rng:NextInteger(1,#st.tiles); st.reveal=now; for i,b in ipairs(st.tiles) do st.safe[i]=i==safe or rng:NextNumber()<.25; b.Color=st.safe[i] and amber or stone end end
  if phase==2 then local elapsed=now-(st.reveal or now); if elapsed>1.5 and elapsed<4 then for _,b in ipairs(st.tiles) do b.Color=stone end elseif elapsed>4 then for i,b in ipairs(st.tiles) do if not st.safe[i] then b.Color=danger; for _,p in ipairs(s.api.alive(s)) do if on(s,p,b,0) then s.api.damage(s,p,dt*80,'shock',b) end end end end end end
  st.finalArm.CFrame=CFrame.new(s.origin+Vector3.new(0,50,0))*CFrame.Angles(0,t*.55,0); if phase==3 then hits(s,st.finalArm,dt,'combat',false) end
 elseif k=='mirrors' then
  if now>=st.next then st.next=now+5; st.fireAt=now+1.6; rebuildOptics(s,.3+(math.floor(t/5)%5)*.2) end
  for _,b in ipairs(st.beams) do b.Transparency=now<st.fireAt and .7 or .1; if now>=st.fireAt then hits(s,b,dt,'burn',false) end end
  s.hint=now<st.fireAt and 'OPTICAL PATH PREVIEW / USE BAFFLES' or 'REFLECTED BEAM ACTIVE'

 end
end
function M.debugLine(s)
 if s.game.kind~='tetris' then return end
 local st=s.state
 for _,v in pairs(st.board) do v.part:Destroy() end; st.board={}
 for x=1,6 do local b=box(s,'Debug locked block',(x-5.5)*6,3,0,5.9,5.9,23,steel,Enum.Material.Metal); st.board[x..':1']={part=b,x=x,y=1} end
 st.shape=1; st.column=7; st.rotation=0; st.fallRow=17; st.fast=true
end
function M.cleanup(s)
 if s.state and s.state.tools then for _,tool in ipairs(s.state.tools) do tool:Destroy() end end
end
function M.eligibleWinner(s,p)
 local st=s.state; local k=s.game.kind
 if p==s.controller then return #s.api.alive(s)==0 end
 if not s.alive[p] or st.deadPending[p] then return false end
 if k=='teamescape' or k=='balance' then return st.completed==true end
 if k=='machine' and (st.stage[p] or 1)<3 then return false end
 if k=='bridge' or k=='drawbridge' or k=='convoy' or k=='wheel' or k=='lift' or k=='risingwater' or k=='tower' or k=='clock' or k=='bulkhead' or k=='machine' or k=='finale' or k=='shift' then return st.extracted and st.extracted[p]==true end
 if k=='maze' or k=='curatormaze' or k=='corridors' then return (st.objectives[p] or 0)>=3 end
 if k=='switches' then return st.phase>=8 end
 if k=='rooms' then
  for i,b in ipairs(st.tiles) do if st.safe[i] and on(s,p,b,0) then return true end end; return false
 end
 if k=='rotatingmaze' or k=='snake' then return (st.objectives[p] or 0)>=1 end
 return true
end
return M

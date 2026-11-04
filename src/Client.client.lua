local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local Tween=game:GetService('TweenService')
local p=Players.LocalPlayer
local C=require(RS:WaitForChild('Catalog'))
local event=RS:WaitForChild('TrophyEvent')
local gui=Instance.new('ScreenGui'); gui.Name='TrophyUI'; gui.ResetOnSpawn=false; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=p:WaitForChild('PlayerGui')
local ink=Color3.fromRGB(18,23,36)
local panelColor=Color3.fromRGB(30,37,55)
local mint=Color3.fromRGB(112,255,205)
local white=Color3.fromRGB(235,240,255)
local muted=Color3.fromRGB(159,177,204)
local profile=nil; local isAdmin=false; local inMatch=false; local currentPod=nil; local page=''; local selection=1; local level=1; local column=3
local function corners(o,n) local c=Instance.new('UICorner',o); c.CornerRadius=UDim.new(0,n or 10) end
local function text(parent,value,size,color)
 local t=Instance.new('TextLabel',parent); t.BackgroundTransparency=1; t.Text=value; t.TextColor3=color or white; t.TextSize=size or 16; t.Font=Enum.Font.GothamMedium
 t.TextWrapped=true; t.TextXAlignment=Enum.TextXAlignment.Left; t.Size=UDim2.new(1,0,0,36); return t
end
local function frame(parent,size,pos,color)
 local f=Instance.new('Frame',parent); f.Size=size; f.Position=pos or UDim2.new(); f.BackgroundColor3=color or panelColor; f.BorderSizePixel=0; corners(f); return f
end
local function button(parent,value,callback,color)
 local b=Instance.new('TextButton',parent); b.Text=value; b.TextColor3=ink; b.TextSize=14; b.Font=Enum.Font.GothamBold; b.BackgroundColor3=color or mint; b.BorderSizePixel=0
 b.Size=UDim2.new(1,0,0,40); b.AutoButtonColor=true; corners(b,8); b.Activated:Connect(callback); return b
end
local function fire(action,data) event:FireServer(action,data or {}) end
local header=frame(gui,UDim2.new(1,-24,0,65),UDim2.fromOffset(12,12),ink)
local logo=text(header,'T R O P H Y   /   50 МИРОВ',20,mint); logo.Position=UDim2.fromOffset(16,5); logo.Size=UDim2.new(.54,0,0,29)
local wallet=text(header,'Загрузка коллекции…',14,muted); wallet.Position=UDim2.fromOffset(16,34); wallet.Size=UDim2.new(1,-25,0,22)
local round=frame(gui,UDim2.new(.6,0,0,132),UDim2.new(.2,0,0,86),ink); round.Visible=false
local roundName=text(round,'',19,mint); roundName.Position=UDim2.fromOffset(12,5); roundName.Size=UDim2.new(1,-24,0,32)
local rules=text(round,'',13); rules.Position=UDim2.fromOffset(12,38); rules.Size=UDim2.new(1,-24,0,43)
local timer=text(round,'',14,muted); timer.Position=UDim2.fromOffset(12,84); timer.Size=UDim2.new(1,-24,0,42)
local nav=frame(gui,UDim2.fromOffset(142,310),UDim2.fromOffset(12,88),ink)
local navList=Instance.new('UIListLayout',nav); navList.Padding=UDim.new(0,6)
local navPad=Instance.new('UIPadding',nav); navPad.PaddingTop=UDim.new(0,8); navPad.PaddingLeft=UDim.new(0,8); navPad.PaddingRight=UDim.new(0,8)
local window=frame(gui,UDim2.new(.67,0,.72,0),UDim2.new(.3,0,.18,0),ink); window.Visible=false
local title=text(window,'',22,mint); title.Position=UDim2.fromOffset(16,9); title.Size=UDim2.new(1,-78,0,40)
local close=button(window,'×',function() window.Visible=false; page='' end); close.Size=UDim2.fromOffset(38,34); close.Position=UDim2.new(1,-48,0,12)
local content=Instance.new('ScrollingFrame',window); content.Size=UDim2.new(1,-28,1,-70); content.Position=UDim2.fromOffset(14,60)
content.BackgroundTransparency=1; content.BorderSizePixel=0; content.ScrollBarThickness=5; content.ScrollBarImageColor3=mint; content.AutomaticCanvasSize=Enum.AutomaticSize.Y; content.CanvasSize=UDim2.new()
local layout=Instance.new('UIListLayout',content); layout.Padding=UDim.new(0,8)
local notice=frame(gui,UDim2.new(.6,0,0,68),UDim2.new(.2,0,1,-85),ink); notice.Visible=false
local noticeText=text(notice,'',17,mint); noticeText.Size=UDim2.new(1,-24,1,-12); noticeText.Position=UDim2.fromOffset(12,6)
local toastVersion=0
local function toast(msg)
 toastVersion+=1; local mine=toastVersion; noticeText.Text=msg; notice.Visible=true
 task.delay(5,function() if mine==toastVersion then notice.Visible=false end end)
end
local function clear(name)
 for _,v in ipairs(content:GetChildren()) do if v~=layout then v:Destroy() end end
 title.Text=name; window.Visible=true; content.CanvasPosition=Vector2.zero
end
local function paragraph(value,color,height)
 local t=text(content,value,14,color); t.Size=UDim2.new(1,-8,0,height or 56); return t
end
local function row(left,right,callback,color)
 local f=frame(content,UDim2.new(1,-8,0,76),nil,panelColor)
 local t=text(f,left,14); t.Size=UDim2.new(.65,-14,1,-12); t.Position=UDim2.fromOffset(12,6)
 local b=button(f,right,callback,color); b.Size=UDim2.new(.33,-8,0,48); b.Position=UDim2.new(.67,0,.5,-24)
 return f
end
local render
local function show(which) page=which; render() end
local function adminCommand(command,extra)
 local data={command=command,id=selection,level=level}; for k,v in pairs(extra or {}) do data[k]=v end; fire('admin',data)
end
render=function()
 if page=='' then return end
 if not profile then toast('Данные ещё загружаются'); return end
 if page=='games' then
  clear('50 ИСПЫТАНИЙ')
  paragraph('Каждый заход — 5 случайных испытаний. Победа: +60 монет и фигурка; участие: +15; полный заход: +40. Равный счёт разрешается случайно.',muted,72)
  for _,g in ipairs(C.Games) do row(g.id..'. '..g.name..'\n'..g.rules,isAdmin and 'Тест игры' or 'Выбрать',function() selection=g.id; if isAdmin then show('admin') else toast('В кубах игры выбираются случайно') end end) end
 elseif page=='shop' then
  clear('ЛАВКА КУРАТОРА')
  paragraph('Только игровые монеты. Косметика не меняет силу персонажа. Повторное нажатие снимает аксессуар или след.',muted)
  for _,item in ipairs(C.Shop) do
   local owned=profile.owned[item.id]; local equipped=profile.equipped[item.kind]==item.id or item.kind=='title' and profile.title==item.text
   row(item.name..'\n'..item.kind,owned and (equipped and 'Снять / титул' or 'Надеть') or (item.price..' ◈'),function() fire(owned and 'equip' or 'buy',{id=item.id}) end,owned and Color3.fromRGB(172,190,255) or mint)
  end
 elseif page=='museum' then
  clear('ТВОЯ КОЛЛЕКЦИЯ')
  button(content,'Телепорт на свою базу',function() fire('home'); window.Visible=false; page='' end)
  paragraph('20 уровней за победы в каждой игре: 1, 3, 5, 8 … 450. Мутация выпадает с шансом 0,1% за победу. Фигурки первого уровня — живая грязь.',muted,74)
  for _,g in ipairs(C.Games) do
   local t=profile.trophies[tostring(g.id)]; local wins=t and t.wins or 0; local lv=C.Level(wins)
   local info=lv>0 and (C.Tiers[lv]..' · '..lv..'/20 · '..wins..' побед') or 'Пустой пьедестал'
   if t and t.mutation then info..=' · '..t.mutation end
   paragraph(g.id..'. '..g.name..'\n'..info,lv>0 and C.Palette[lv] or muted,52)
  end
 elseif page=='achievements' then
  clear('ДОСТИЖЕНИЯ И ТИТУЛЫ')
  row('Титул над головой\n'..(profile.title~='' and profile.title or 'Без титула'),'Снять титул',function() fire('title',{title=''}) end)
  local titles={}; for name in pairs(profile.titles) do table.insert(titles,name) end; table.sort(titles)
  for _,name in ipairs(titles) do row('Титул: '..name,'Надеть',function() fire('title',{title=name}) end) end
  local unique=0; for _,v in pairs(profile.trophies) do if v.wins>0 then unique+=1 end end
  local values={wins=profile.wins,runs=profile.runs,unique=unique,mutations=profile.mutationCount}
  for _,a in ipairs(C.Achievements) do paragraph((profile.achievements[a.id] and '✓ ' or '○ ')..a.name..'   '..math.min(values[a.field],a.goal)..'/'..a.goal..'\n+'..a.reward..' ◈ · титул «'..a.title..'»',profile.achievements[a.id] and mint or muted,58) end
 elseif page=='pod' then
  clear('КУБ // КОМАНДА')
  if not currentPod then
   paragraph('Подойди к светящемуся кубу в лобби или выбери его здесь. Лидер задаёт сложность, размер команды и доступ.',muted,70)
   for i=1,4 do button(content,'Войти в куб '..i,function() fire('join',{id=i}) end) end
   return
  end
  local d=currentPod; local leader=d.leader==p.UserId
  local names={}; for _,m in ipairs(d.members) do table.insert(names,m.name..(m.id==d.leader and ' ★' or '')) end
  paragraph('Куб '..d.id..' · '..#d.members..'/'..d.max..'\n'..table.concat(names,'  /  '),mint,70)
  if leader then
   row('Лимит игроков: '..d.max,'Следующий',function() fire('configure',{max=d.max%8+1}) end)
   row('Сложность: '..({'Легко','Обычно','Хардкор'})[d.difficulty],'Изменить',function() fire('configure',{difficulty=d.difficulty%3+1}) end)
   local accessNames={all='Открыто всем',friends='Друзья лидера',invite='По приглашению'}
   row('Доступ: '..accessNames[d.access],'Изменить',function() local nextMode={all='friends',friends='invite',invite='all'}; fire('configure',{access=nextMode[d.access]}) end)
   paragraph('Пригласить конкретного игрока с этого сервера:',muted,30)
   for _,other in ipairs(Players:GetPlayers()) do if other~=p then button(content,'Пригласить '..other.DisplayName,function() fire('configure',{invite=other.UserId}); toast('Приглашение отправлено') end) end end
   button(content,'НАЧАТЬ ЗАХОД · 5 ИГР',function() fire('start'); window.Visible=false; page='' end)
  else paragraph('Лидер выбирает настройки и запускает заход. Можно начать и неполной командой.',muted) end
  button(content,'Выйти из куба',function() fire('leave') end,Color3.fromRGB(255,146,146))
 elseif page=='admin' then
  clear('ЛАБОРАТОРИЯ ПРОТОТИПА')
  if not isAdmin then paragraph('Админка доступна создателю, списку AdminUserIds и всем тестерам в Studio.'); return end
  paragraph('Команды работают на сервере. Награды в опубликованной игре сохраняются. В Studio без API — только на время теста.',muted,64)
  row('Игра '..selection..'/50\n'..C.Games[selection].name,'Следующая',function() selection=selection%50+1; render() end)
  row('Уровень фигурки: '..level..'/20','Следующий',function() level=level%20+1; render() end)
  button(content,'Предыдущая игра',function() selection=(selection-2)%50+1; render() end)
  button(content,'Тест выбранной игры соло',function() adminCommand('play'); window.Visible=false; page='' end)
  button(content,'Выбранная игра в следующем раунде команды',function() adminCommand('force') end)
  button(content,'Завершить текущий раунд',function() adminCommand('next') end)
  button(content,'+1 победа и трофей выбранной игры',function() adminCommand('win') end)
  button(content,'Поднять трофей до выбранного уровня',function() adminCommand('level') end)
  for i,name in ipairs({'Золотоносная','Призрачная','Галактическая'}) do button(content,'Мутация: '..name,function() adminCommand('mutation',{mutation=i}) end) end
  button(content,'+10 000 монет',function() adminCommand('coins') end)
  button(content,'Открыть всю косметику',function() adminCommand('unlock') end)
  button(content,'Выдать условия всех достижений',function() adminCommand('achievements') end)
  button(content,'Вылечить себя',function() adminCommand('heal') end)
 elseif page=='help' then
  clear('ДОБРО ПОЖАЛОВАТЬ В TROPHY')
  paragraph('Музей странных побед. Собирай друзей в кубах лобби, переживи пять испытаний и принеси домой новый экспонат.',mint,76)
  paragraph('Управление Roblox: WASD / стик — ходьба, пробел / кнопка прыжка — прыжок. Взаимодействие с кубом: E или экранная подсказка.',white,76)
  paragraph('Тетрис: один случайный игрок — архитектор сверху. Кнопки на экране выбирают столбец, поворот и сброс. Клавиши A/D, R, F тоже работают. Остальные уклоняются внизу. Сеты +40, устранения +55, выживание +2/сек.',white,110)
  paragraph('В остальных играх решают выживание и сбор искр (+15). Победить может только выживший. При одинаковом счёте победителя выбирает жребий; если все погибли, трофей не выдаётся.',muted,90)
  paragraph('Ушёл из игры — текущий заход прерывается для тебя. Респаун после смерти не возвращает в раунд. Следующий раунд снова собирает команду.',muted,76)
  paragraph('Прототип: 50 испытаний — это 10 семейств по 5 вариантов. Сохранение требует опубликованного места и доступа к DataStore. Статус указан под логотипом.',muted,90)
 end
end
for _,entry in ipairs({{'Команда','pod'},{'Коллекция','museum'},{'Магазин','shop'},{'Достижения','achievements'},{'50 игр','games'},{'Как играть','help'}}) do button(nav,entry[1],function() show(entry[2]) end) end
local adminButton=button(nav,'Админка',function() show('admin') end,Color3.fromRGB(255,199,111)); adminButton.Visible=false
local lobbyButton=button(gui,'В ЛОББИ',function() fire('lobby') end); lobbyButton.Size=UDim2.fromOffset(128,36); lobbyButton.Position=UDim2.new(0,18,1,-51)
local controller=frame(gui,UDim2.new(.6,0,0,104),UDim2.new(.2,0,1,-205),ink); controller.Visible=false
local controlText=text(controller,'АРХИТЕКТОР · столбец 3',15,mint); controlText.Position=UDim2.fromOffset(10,2)
local function move(n) column=math.clamp(column+n,1,8); fire('control',{column=column}); controlText.Text='АРХИТЕКТОР · столбец '..column end
for i,entry in ipairs({{'◀',function() move(-1) end},{'ПОВОРОТ R',function() fire('control',{rotate=true}) end},{'СБРОС F',function() fire('control',{drop=true,column=column}) end},{'▶',function() move(1) end}}) do
 local b=button(controller,entry[1],entry[2]); b.Size=UDim2.new(.24,-8,0,44); b.Position=UDim2.new((i-1)*.25,8,0,47)
end
UIS.InputBegan:Connect(function(input,processed)
 if processed or not controller.Visible then return end
 if input.KeyCode==Enum.KeyCode.A then move(-1) elseif input.KeyCode==Enum.KeyCode.D then move(1)
 elseif input.KeyCode==Enum.KeyCode.R then fire('control',{rotate=true}) elseif input.KeyCode==Enum.KeyCode.F then fire('control',{drop=true,column=column}) end
end)
event.OnClientEvent:Connect(function(kind,data)
 if kind=='profile' then
  profile=data.data; isAdmin=data.admin; adminButton.Visible=isAdmin; nav.Size=UDim2.fromOffset(142,isAdmin and 356 or 310)
  wallet.Text='◈ '..profile.coins..'   /   '..profile.wins..' побед   /   '..(data.persistent and 'Сохранение включено' or 'ВРЕМЕННАЯ СЕССИЯ · без сохранения')
  if page~='' then render() end
 elseif kind=='toast' then toast(data)
 elseif kind=='open' then show(data)
 elseif kind=='pod' then currentPod=data or nil; if page=='pod' or data then show('pod') end
 elseif kind=='match' then inMatch=data; lobbyButton.Visible=not data; if not data then round.Visible=false; controller.Visible=false end
 elseif kind=='round' then
  round.Visible=true; roundName.Text='0'..data.round..'/05  ·  '..data.name
  rules.Text=data.rules; timer.Text=data.time..' сек   /   '..math.floor(data.scores)..' очков\n'..(data.hint~='' and data.hint or (data.alive and 'ВЫЖИВАЙ' or 'НАБЛЮДЕНИЕ · новый раунд скоро'))
  controller.Visible=data.controller; if data.controller then controlText.Text='АРХИТЕКТОР · столбец '..column end
 elseif kind=='control' then column=data.column; controlText.Text='АРХИТЕКТОР · столбец '..column..' · поворот '..data.rotation
 elseif kind=='result' then controller.Visible=false; toast(data.name..' → '..data.winner..' · '..data.score..' очков'); timer.Text='Раунд окончен. Возвращение в лобби…'
 elseif kind=='invite' then
  local box=frame(gui,UDim2.fromOffset(300,100),UDim2.new(.5,-150,.5,-50),panelColor)
  local t=text(box,data.name..' зовёт в куб '..data.id,16); t.Position=UDim2.fromOffset(10,5); t.Size=UDim2.new(1,-20,0,40)
  local yes=button(box,'Войти',function() fire('join',{id=data.id}); box:Destroy() end); yes.Position=UDim2.fromOffset(10,50); yes.Size=UDim2.new(.5,-15,0,38)
  local no=button(box,'Позже',function() box:Destroy() end,muted); no.Position=UDim2.new(.5,5,0,50); no.Size=UDim2.new(.5,-15,0,38)
  task.delay(15,function() if box.Parent then box:Destroy() end end)
 end
end)
-- Keep the navigation usable on narrow screens; built-in Roblox movement remains available.
local scale=Instance.new('UIScale',gui)
local function resize()
 local camera=workspace.CurrentCamera
 if camera then scale.Scale=math.clamp(camera.ViewportSize.X/1000,.7,1) end
end
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(resize) end
resize()
fire('sync')
task.spawn(function() for _=1,15 do if profile then break end; task.wait(1); fire('sync') end; if profile and page=='' and not inMatch then show('help') end end)

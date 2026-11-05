local Players=game:GetService("Players")
local Rep=game:GetService("ReplicatedStorage")
local Input=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local SoundService=game:GetService("SoundService")
local player=Players.LocalPlayer
local Shared=Rep:WaitForChild("Shared")
local Config=require(Shared:WaitForChild("Config"))
local Domain=require(Shared.Domain)
local Rarity=require(Shared.Rarity)
local Appearance=require(Shared.Appearance)
local Presentation=require(Shared.Presentation)
local Decor=require(Shared.Decor)
local Layout=require(Shared.HUDLayout)
local IdentityFX=require(script.Parent:WaitForChild("IdentityFX"))
local IdentityUI=require(script.Parent:WaitForChild("IdentityUI"))
local Instruments=require(script.Parent:WaitForChild("InstrumentUI"))
require(script.Parent:WaitForChild("ItemEffects")).Start()
require(script.Parent:WaitForChild("RigMotion")).Start()
local network=Rep:WaitForChild("Network")
local Action,State=network:WaitForChild("Action"),network:WaitForChild("State")
pcall(function()game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList,false)end)

local C={deep=Color3.fromRGB(10,14,24),ink=Color3.fromRGB(15,20,33),panel=Color3.fromRGB(25,33,51),line=Color3.fromRGB(48,62,86),
	paper=Color3.fromRGB(238,245,255),muted=Color3.fromRGB(145,162,190),mint=Color3.fromRGB(69,234,204),gold=Color3.fromRGB(132,155,255),red=Color3.fromRGB(255,115,137)}
local function make(class,props,parent)local o=Instance.new(class);for k,v in pairs(props or{})do o[k]=v end;o.Parent=parent;return o end
local function corner(o,r)make("UICorner",{CornerRadius=UDim.new(0,r or 12)},o)end
local function stroke(o,color,alpha,width)return make("UIStroke",{Color=color or C.line,Transparency=alpha or 0,Thickness=width or 1},o)end
local function text(parent,value,size,color,pos,dimensions,font)
	return make("TextLabel",{BackgroundTransparency=1,Text=value,Font=font or Enum.Font.Gotham,TextSize=size or 13,TextColor3=color or C.paper,
		TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,Position=pos or UDim2.new(),Size=dimensions or UDim2.fromOffset(220,24)},parent)
end
local function button(parent,value,x,y,w,h,callback,style)
	local b=make("TextButton",{Text=value,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=if style=="primary"then C.deep else C.paper,
		BackgroundColor3=if style=="primary"then C.mint elseif style=="gold"then Color3.fromRGB(55,66,113)else C.panel,AutoButtonColor=false,BorderSizePixel=0,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h)},parent)
	corner(b,9);stroke(b,if style=="primary"then C.mint else C.line,.35)
	b.MouseEnter:Connect(function()TweenService:Create(b,TweenInfo.new(.12),{BackgroundTransparency=.16}):Play()end)
	b.MouseLeave:Connect(function()TweenService:Create(b,TweenInfo.new(.12),{BackgroundTransparency=0}):Play()end)
	b.Activated:Connect(callback);return b
end
local function box(parent,placeholder,value,x,y,w,changed)
	local b=make("TextBox",{BackgroundColor3=C.deep,BorderSizePixel=0,Text=value or"",PlaceholderText=placeholder,ClearTextOnFocus=false,
		Font=Enum.Font.GothamMedium,TextSize=16,TextColor3=C.paper,PlaceholderColor3=C.muted,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,34)},parent)
	corner(b,8);stroke(b);b:GetPropertyChangedSignal("Text"):Connect(function()changed(b.Text)end);return b
end
local function money(n)local s=tostring(math.floor(n or 0));return s:reverse():gsub("(%d%d%d)","%1 "):reverse():gsub("^ ","")end
local function emit(name,data)Action:FireServer(name,data or{})end
local function panel(parent,x,y,w,h)local f=make("Frame",{BackgroundColor3=C.ink,BackgroundTransparency=.06,BorderSizePixel=0,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h)},parent);corner(f);stroke(f,C.line,.2);return f end
local function scroll(parent,x,y,w,h)return make("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollBarImageColor3=C.gold},parent)end
local function visible(o)local p=o;while p do if p:IsA("GuiObject")and not p.Visible then return false end;p=p.Parent end;return o:IsDescendantOf(game)end

local gui=make("ScreenGui",{Name="ProbaInterface",ResetOnSpawn=false,IgnoreGuiInset=false,DisplayOrder=20,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},player:WaitForChild("PlayerGui"))
local data,catalog,rows=nil,{},{}
local mode=nil
local rosterOpen=false
local selectedItem,selectedDecor=nil,"sign_painted"
local caseMode="npc"
local drafts={}
local views,connections={},{ }
local identityState={}
local avatarDebug
local lab={id="h03",mutation="silver",unique=0,tab="fx"}
local exhibit,lastReceipt=nil,nil
local showModel,showNotes,showOffer=false,false,false
local muted=false
local render,renderHUD,renderRoster,resize
local layout=Layout.Compute(1280,720)
local focusedFields={}
local renderedMode,lastCaseView=nil,nil
local function release()for _,c in ipairs(connections)do c:Disconnect()end;connections={};views={};focusedFields={}end

-- Passive HUD: a small brand, one wallet chip and a 318 px tool rail.
local brand=make("Frame",{BackgroundTransparency=1,Size=UDim2.fromOffset(108,24)},gui)
local mark=panel(brand,0,0,22,22);mark.BackgroundColor3=C.mint
text(mark,"P",17,C.deep,UDim2.fromOffset(6,-1),UDim2.fromOffset(17,24),Enum.Font.GothamBlack)
text(brand,"PROBA",16,C.paper,UDim2.fromOffset(30,0),UDim2.fromOffset(78,23),Enum.Font.GothamBlack)
local wallet=panel(gui,0,0,178,42)
local walletText=text(wallet,"...",17,C.paper,UDim2.fromOffset(11,4),UDim2.fromOffset(103,24),Enum.Font.GothamBold)
local repText=text(wallet,"",9,C.mint,UDim2.fromOffset(115,5),UDim2.fromOffset(53,23),Enum.Font.GothamBold)
local repTrack=make("Frame",{BackgroundColor3=C.line,BorderSizePixel=0,Position=UDim2.fromOffset(11,33),Size=UDim2.fromOffset(146,2)},wallet)
local repFill=make("Frame",{BackgroundColor3=C.mint,BorderSizePixel=0,Size=UDim2.fromScale(0,1)},repTrack)
local saveDot=make("Frame",{BackgroundColor3=C.gold,BorderSizePixel=0,Position=UDim2.fromOffset(164,31),Size=UDim2.fromOffset(4,4)},wallet);corner(saveDot,3)
local queueButton=button(gui,"",0,0,104,22,function()rosterOpen=not rosterOpen;renderRoster()end);queueButton.TextSize=10
local dock=panel(gui,0,0,318,40)
local navButtons={}
local function icon(b,id)
	if id=="guide"then return end
	b.Text=""
	local function part(x,y,w,h,angle,color)
		local f=make("Frame",{BackgroundColor3=color or C.paper,BorderSizePixel=0,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),Rotation=angle or 0},b);corner(f,2);return f
	end
	local function outline(x,y,w,h,r)
		local f=part(x,y,w,h);f.BackgroundTransparency=1;corner(f,r or 3);stroke(f,C.paper,0,1.4);return f
	end
	if id=="case"then outline(11,6,13,13,9);part(24,18,2,9,-42)
	elseif id=="inventory"then outline(10,6,14,17);outline(15,10,14,17);part(18,14,7,1,0,C.mint)
	elseif id=="workshop"then part(19,9,2,14);part(14,9,2,9,40);part(24,9,2,9,-40);part(13,25,15,2)
	elseif id=="specialty"then local head=part(17,5,7,7);corner(head,5);outline(12,16,17,11,6)
	elseif id=="titles"then local badge=outline(14,6,12,12,2);badge.Rotation=45;part(15,19,3,8,15,C.gold);part(23,19,3,8,-15,C.gold)
	else outline(12,6,17,20);part(15,10,11,2,0,C.mint);part(15,15,7,2);part(15,20,9,2)end
end
local dockItems={{"Д","case","Дело [B]"},{"К","inventory","Коллекция"},{"Б","workshop","Бюро и приборы"},{"П","specialty","Профессии"},{"Т","titles","Стиль: титул, nametag, фон"},{"О","decor","Декор"},{"?","guide","Помощь"}}
local hint=text(gui,"",11,C.paper,UDim2.new(),UDim2.fromOffset(210,26));hint.BackgroundColor3=C.panel;hint.BackgroundTransparency=.05;corner(hint,8);hint.Visible=false;hint.TextXAlignment=Enum.TextXAlignment.Center
for i,entry in ipairs(dockItems)do
	local b=button(dock,entry[1],5+(i-1)*44,4,40,32,function()if mode==entry[2]then mode=nil;render()else emit("Open",{panel=entry[2]})end end)
	navButtons[entry[2]]=b;icon(b,entry[2])
	b.MouseEnter:Connect(function()hint.Text=entry[3];hint.Visible=true;hint.Position=UDim2.fromOffset(math.clamp(layout.dock.x+(i-1)*44-74,0,layout.width-210),layout.dock.y-32)end)
	b.MouseLeave:Connect(function()hint.Visible=false end)
end
wallet.MouseEnter:Connect(function()if data then hint.Text=if data.saveMode=="cloud"then"Облачное сохранение"elseif data.saveMode=="studio"then"Studio / тестовый профиль"else"Сеанс БЕЗ облачного сохранения";hint.Position=UDim2.fromOffset(layout.width-224,80);hint.Visible=true end end)
wallet.MouseLeave:Connect(function()hint.Visible=false end)
local home=button(gui,"ДОМ",0,0,48,30,function()emit("Return")end)
local sound=button(gui,"SFX",0,0,43,30,function()muted=not muted;local group=SoundService:FindFirstChild("ProbaWorld");if group then group.Volume=if muted then 0 else 1 end;if renderHUD then renderHUD()end end)
local admin=button(gui,"F8 / LAB",0,0,80,26,function()mode=if mode=="admin"then nil else"admin";render()end,"gold");admin.Visible=false
local mentor=button(gui,"",14,0,270,28,function()mode="guide";render()end);mentor.TextSize=10;mentor.TextXAlignment=Enum.TextXAlignment.Left
local mentorFocus=make("Highlight",{FillTransparency=.96,OutlineTransparency=.1,OutlineColor=C.mint,FillColor=C.mint,Enabled=false},workspace)
local rosterShell=panel(gui,0,0,270,340);rosterShell.Visible=false
local manager=panel(gui,0,0,760,530);manager.Visible=false
local pageTitle=text(manager,"",22,C.paper,UDim2.fromOffset(18,9),UDim2.new(1,-75,0,31),Enum.Font.GothamBold)
local pageSubtitle=text(manager,"",10,C.muted,UDim2.fromOffset(18,41),UDim2.new(1,-30,0,19))
local closeManager=button(manager,"×",0,12,28,28,function()mode=nil;render()end)
local body=scroll(manager,16,70,728,442)
local casePane=panel(gui,0,0,296,410);casePane.Visible=false
local caseTitle=text(casePane,"",14,C.paper,UDim2.fromOffset(12,7),UDim2.fromOffset(220,23),Enum.Font.GothamBold)
local timeLabel=text(casePane,"",10,C.mint,UDim2.fromOffset(12,29),UDim2.fromOffset(244,18))
button(casePane,"×",259,7,25,25,function()mode=nil;render()end)
local caseBody=scroll(casePane,12,54,272,340)
local pending=panel(gui,0,0,244,100);pending.Visible=false
local pendingText=text(pending,"",11,C.paper,UDim2.fromOffset(10,5),UDim2.fromOffset(224,51))
button(pending,"Принять / +40",10,61,130,29,function()if data and data.pending then emit("PeerAccept",{id=data.pending.id})end end,"primary")
button(pending,"Отказ",147,61,87,29,function()if data and data.pending then emit("PeerDecline",{id=data.pending.id})end end)
local toastLabel=text(gui,"",12,C.paper,UDim2.new(),UDim2.fromOffset(360,42));toastLabel.BackgroundColor3=C.panel;toastLabel.BackgroundTransparency=.04;toastLabel.ZIndex=80;corner(toastLabel,12);stroke(toastLabel,C.gold,.5);toastLabel.Visible=false
local toastGeneration=0
local function toast(value,tone)
	toastGeneration+=1;local generation=toastGeneration;toastLabel.Text=value;toastLabel.TextColor3=if tone=="bad"then C.red else C.paper;toastLabel.Visible=true
	task.delay(4,function()if toastGeneration==generation then toastLabel.Visible=false end end)
end

local function viewport(parent,id,x,y,w,h,item,folder)
	local frame=make("ViewportFrame",{BackgroundColor3=C.deep,BorderSizePixel=0,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),Ambient=Color3.fromRGB(186,198,217),LightColor=Color3.fromRGB(244,248,255),LightDirection=Vector3.new(-1,-1,-1),Active=true},parent);corner(frame,10)
	local world=make("WorldModel",{},frame);local source=(folder or Rep.ItemModels):FindFirstChild(id)
	if not source then text(frame,"Модель загружается",12,C.muted);return frame end
	local model=source:Clone();model.Parent=world;model:PivotTo(CFrame.new())
	if item then local ok,err=pcall(Appearance.Apply,model,item);if not ok then warn("[PROBA] Preview appearance",id,err);text(frame,"Эффект не загрузился; модель доступна",9,C.red,UDim2.fromOffset(8,h-22),UDim2.fromOffset(w-16,20))end end
	local center,size=Presentation.Bounds(model)
	local camera=make("Camera",{FieldOfView=38},frame);frame.CurrentCamera=camera
	local state={frame=frame,camera=camera,target=center,size=math.max(size.X,size.Y,size.Z,1),yaw=.4,pitch=.35,dragging=false,last=nil,resume=0};table.insert(views,state)
	table.insert(connections,frame.InputBegan:Connect(function(input)if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then state.dragging=true;state.last=input.Position end end))
	table.insert(connections,Input.InputChanged:Connect(function(input)
		if state.dragging and state.last and(input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch)then state.yaw+=(input.Position.X-state.last.X)*.012;state.pitch=math.clamp(state.pitch+(input.Position.Y-state.last.Y)*.009,-1.15,1.2);state.last=input.Position;state.resume=os.clock()+2 end
	end))
	table.insert(connections,Input.InputEnded:Connect(function(input)if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then state.dragging=false end end));return frame
end
local function heading(name,sub)pageTitle.Text=name;pageSubtitle.Text=sub or""end
local function currentCase()return data and(if caseMode=="peer"then data.peer else data.case)end
local function timerText(record)
	if data and data.timersPaused then return"Время остановлено в лаборатории"end
	if record.challenge then return"Исследование / таймер на паузе"end
	if record.timing and record.timing.paused then return"Подготовка / таймер на паузе"end
	local seconds=record.timing and record.timing.seconds or 300;return string.format("На оценку %d:%02d / очередь %d",math.floor(seconds/60),seconds%60,data.queue)
end
local function fieldsPacket(record)
	local draft=drafts[record.id];local quote=tonumber(draft and draft.quote)
	if not quote or quote<1 then toast("Укажи стоимость предмета","bad");return end
	return{caseId=record.id,quote=quote,auth=draft.auth or"unknown"}
end
local function drawCase()
	local r=currentCase();local w=math.max(200,caseBody.AbsoluteSize.X-5)
	if not r then caseTitle.Text="Стойка готова";timeLabel.Text="Клиенты подходят по одному";text(caseBody,"Дождись гостя у стола",15,C.paper,UDim2.fromOffset(0,12),UDim2.fromOffset(w,42));return end
	caseTitle.Text=r.customer;timeLabel.Text=timerText(r)
	local item=r.item;local draft=drafts[r.id]or{quote="",offer="",auth="unknown"};drafts[r.id]=draft
	text(caseBody,item.name,19,C.paper,UDim2.new(),UDim2.fromOffset(w,48),Enum.Font.GothamBold)
	text(caseBody,Config.Specs[item.spec].name.." / "..Rarity.Caption(item),10,C.muted,UDim2.fromOffset(0,48),UDim2.fromOffset(w,30))
	if r.challenge then
		local stage=make("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(0,83),Size=UDim2.fromOffset(w,168*w/308)},caseBody)
		local view=viewport(stage,item.id,0,0,308,168,item);make("UIScale",{Scale=w/308},view)
		Instruments.Build(view,r,{make=make,text=text,button=button,corner=corner,stroke=stroke,colors=C,emit=emit,connections=connections})
		button(caseBody,"Отменить исследование",0,94+168*w/308,w,30,function()emit("CancelInspection",{caseId=r.id})end);return
	end
	local y=82
	if showModel then viewport(caseBody,item.id,0,y,w,138,item);y+=146 end
	button(caseBody,if showModel then"Скрыть 3D"else"Рассмотреть 3D",0,y,126,26,function()showModel=not showModel;render()end)
	button(caseBody,if showNotes then"Скрыть записи"else"Записи",134,y,w-134,26,function()showNotes=not showNotes;render()end);y+=34
	local names={loupe="Лупа",scale="Весы",uv="УФ",spectro="Спектр",diagnostic="Тест"}
	for i,id in ipairs(Config.ToolsOrder)do
		local b=button(caseBody,(if r.tests[id]then"✓ "else"")..names[id],(i-1)*(w+5)/5,y,(w-20)/5,34,function()emit("Inspect",{caseId=r.id,tool=id})end,if r.tests[id]then"primary"else nil)
		b.TextSize=10;if(data.equipment[id]or 0)==0 then b.TextColor3=C.muted end
	end;y+=42
	if showNotes then
		local parts={};for _,id in ipairs(Config.ToolsOrder)do if r.tests[id]then table.insert(parts,Config.Tools[id].name..": "..r.tests[id].text)end end
		local noteArea=scroll(caseBody,0,y,w,110);local notes=text(noteArea,if #parts>0 then table.concat(parts,"\n\n")else"Доказательств ещё нет. Начни с лупы и весов.",11,C.paper,UDim2.new(),UDim2.new(1,-6,0,0));notes.AutomaticSize=Enum.AutomaticSize.Y;notes.TextYAlignment=Enum.TextYAlignment.Top;y+=118
	end
	text(caseBody,"Ориентир "..money(item.estimate.low).."—"..money(item.estimate.high),12,C.gold,UDim2.fromOffset(0,y),UDim2.fromOffset(w,22));y+=26
	focusedFields.quote=box(caseBody,"Стоимость",draft.quote,0,y,w,function(value)draft.quote=value end);y+=41
	for i,choice in ipairs({{"genuine","Оригинал"},{"replica","Реплика"},{"unknown","Неясно"}})do button(caseBody,choice[2],(i-1)*(w+5)/3,y,(w-10)/3,28,function()draft.auth=choice[1];render()end,if draft.auth==choice[1]then"gold"else nil)end;y+=36
	button(caseBody,if caseMode=="peer"then"Выдать заключение / +40"else"Выдать оценку",0,y,w,34,function()local p=fieldsPacket(r);if p then emit("Complete",p)end end,"primary");y+=42
	if caseMode=="npc"then
		button(caseBody,if showOffer then"Скрыть торг"else"Предложить выкуп",0,y,w,28,function()showOffer=not showOffer;render();if showOffer then task.defer(function()caseBody.CanvasPosition=Vector2.new(0,80)end)end end);y+=35
		if showOffer then
			focusedFields.offer=box(caseBody,"Сумма выкупа",draft.offer,0,y,w-94,function(value)draft.offer=value end)
			button(caseBody,"Предложить",w-88,y,88,34,function()local p=fieldsPacket(r);local amount=tonumber(draft.offer);if p and amount then p.amount=amount;emit("Offer",p)elseif p then toast("Укажи сумму выкупа","bad")end end,"gold")
		end
	end
end
local function drawWorkshop(w)
	heading("Бюро и приборы","Развитие без повторной покупки профессий")
	local level=Config.BaseLevels[data.baseLevel];local nextLevel=Config.BaseLevels[data.baseLevel+1]
	local c=panel(body,0,0,w,106);text(c,level.name,22,C.paper,UDim2.fromOffset(14,8),UDim2.fromOffset(w-28,30),Enum.Font.GothamBold)
	text(c,"Очередь "..level.capacity.." / гонорар ×"..level.fee,12,C.muted,UDim2.fromOffset(14,40),UDim2.fromOffset(w-28,22))
	button(c,if nextLevel then"Улучшить / "..money(nextLevel.price).." / REP "..nextLevel.rep else"Максимальная база",14,68,math.min(w-28,360),28,function()emit("UpgradeBase")end,"primary")
	for i,id in ipairs(Config.ToolsOrder)do
		local d=Config.Tools[id];local rank=data.equipment[id]or 0;local cost=d.price[rank+1];local row=panel(body,0,118+(i-1)*91,w,82)
		text(row,d.name.." / "..rank.." из 3",15,C.paper,UDim2.fromOffset(12,7),UDim2.fromOffset(w-25,24),Enum.Font.GothamBold)
		text(row,d.hint,11,C.muted,UDim2.fromOffset(12,33),UDim2.fromOffset(w-160,38));button(row,if cost then money(cost)else"Максимум",w-137,41,125,29,function()emit("UpgradeTool",{tool=id})end,if cost then"primary"else nil)
	end
end
local function drawSpecialty(w)
	heading("Твоя специализация","Переключай бесплатно. Опыт каждого направления сохраняется.")
	for i,id in ipairs(Config.SpecOrder)do
		local d=Config.Specs[id];local xp=data.specXP[id]or 0;local active=data.specialty==id;local c=panel(body,0,(i-1)*93,w,83)
		text(c,d.name,17,C.paper,UDim2.fromOffset(12,7),UDim2.fromOffset(w-145,25),Enum.Font.GothamBold)
		text(c,d.subtitle.."\nУровень "..Domain.specLevel(xp).." / XP "..xp,11,C.muted,UDim2.fromOffset(12,35),UDim2.fromOffset(w-150,38));button(c,if active then"Выбрана"else"Выбрать",w-122,24,108,34,function()emit("Specialty",{spec=id})end,if active then"primary"else nil)
	end
end
local function itemDetails(parent,item,w,owned,y)
	viewport(parent,item.id,0,y,w,178,item);y+=187
	text(parent,item.name,19,C.paper,UDim2.fromOffset(0,y),UDim2.fromOffset(w,42),Enum.Font.GothamBold);y+=44
	text(parent,Rarity.Caption(item),12,C.mint,UDim2.fromOffset(0,y),UDim2.fromOffset(w,30));y+=34
	text(parent,item.condition.." / "..item.material,11,C.muted,UDim2.fromOffset(0,y),UDim2.fromOffset(w,35));y+=39
	local report=item.reports and item.reports[#item.reports]
	local evidence=if report then report.by..": "..money(report.quote).." / "..(if report.auth=="genuine"then"оригинал"elseif report.auth=="replica"then"реплика"else"неясно")
		else"Твой ориентир: "..money(item.estimate.low).."—"..money(item.estimate.high).." / точность "..item.estimate.confidence.."%"
	text(parent,evidence,12,C.gold,UDim2.fromOffset(0,y),UDim2.fromOffset(w,43));y+=49
	if owned then button(parent,"Взять в руки",0,y,(w-8)/2,34,function()emit("Carry",{uid=item.uid})end,"primary");button(parent,"Скупщику",(w+8)/2,y,(w-8)/2,34,function()emit("Sell",{uid=item.uid})end);y+=42 end
	text(parent,"Витрина: E — рассмотреть, F — взять. В 3D потяни мышью или пальцем, чтобы повернуть и наклонить.",11,C.muted,UDim2.fromOffset(0,y),UDim2.fromOffset(w,52))
end
local function drawInventory(w)
	heading("Коллекция / "..#data.inventory.." из 40","Первые покупки — на пьедесталах; остальные — на полках")
	if #data.inventory==0 then text(body,"Выкупи предмет у гостя — он появится на витрине твоего бюро.",17,C.muted,UDim2.fromOffset(12,60),UDim2.fromOffset(w-24,90));return end
	local item;for _,v in ipairs(data.inventory)do if v.uid==selectedItem then item=v end end
	if item then button(body,"Назад к вещам",0,0,w,28,function()selectedItem=nil;render(true)end);itemDetails(body,item,w,true,38);return end
	for i,v in ipairs(data.inventory)do
		local row=button(body,"",0,(i-1)*76,w,66,function()selectedItem=v.uid;render(true)end)
		text(row,v.name,15,C.paper,UDim2.fromOffset(12,7),UDim2.fromOffset(w-24,25),Enum.Font.GothamBold);text(row,Rarity.Caption(v),11,C.mint,UDim2.fromOffset(12,36),UDim2.fromOffset(w-24,21))
	end
end
local function drawTitles(w)
	heading("Стиль игрока","Три независимых слоя. Примеряй бесплатно в живом предпросмотре.")
	IdentityUI.Build(body,data,player,w,identityState,{button=button,text=text,panel=panel,colors=C,emit=emit,render=render})
end
local function drawDecor(w)
	heading("Декор / 19 предметов","Оформление игрока перенесено в «Стиль». Здесь обстановка бюро.")
	local y=0;local selected=Decor.ById[selectedDecor]
	if selected and selected.category~="frame"and selected.category~="card"then viewport(body,selected.id,0,0,w,150,nil,Rep.DecorModels);y=160 end
	for _,d in ipairs(Decor.List)do
		if d.category=="card"or d.category=="frame"then continue end
		local row=panel(body,0,y,w,88);y+=98
		text(row,d.name,14,C.paper,UDim2.fromOffset(12,5),UDim2.fromOffset(w-145,25),Enum.Font.GothamBold);text(row,d.description,10,C.muted,UDim2.fromOffset(12,31),UDim2.fromOffset(w-145,48))
		button(row,"Вид",w-125,8,46,25,function()selectedDecor=d.id;render(true)end)
		if data.equippedDecor[d.category]==d.id and d.category~="chair"and d.category~="frame"and d.category~="card"then button(row,"Убрать",w-73,8,61,25,function()emit("RemoveDecor",{category=d.category})end)end
		local label=if data.equippedDecor[d.category]==d.id then"Надето"elseif data.ownedDecor[d.id]then"Надеть"elseif d.premium then"Robux *"else money(d.price)
		button(row,label,w-125,44,113,31,function()emit("BuyDecor",{id=d.id})end,if data.ownedDecor[d.id]then"gold"else nil)
	end
	text(body,"* Премиум-позиции включаются после назначения настоящего Product ID. Пока покупки Robux отключены.",11,C.muted,UDim2.fromOffset(0,y),UDim2.fromOffset(w,45))
end
local function drawAdmin(w)
	heading("PROBA / TEST LAB","Живое сравнение мутаций и уникальности без редкого выпадения")
	if not data.admin then return end
	button(body,"Эффекты и образцы",0,0,(w-8)/2,30,function()lab.tab="fx";render()end,if lab.tab=="fx"then"primary"else nil);button(body,"Игра и время",(w+8)/2,0,(w-8)/2,30,function()lab.tab="game";render()end,if lab.tab=="game"then"primary"else nil)
	if lab.tab=="game"then
		local commands={{"+25 000 монет","funds"},{"REP 75","reputation"},{"Все приборы III","tools"},{"База 1 → 2 → 3","base"},{"Все оформления","identity"},{"Весь декор","decor"},{if data.timersPaused then"Продолжить время"else"Остановить время","pause"},{"Настроение клиента","emotions"}}
		for i,c in ipairs(commands)do button(body,c[1],((i-1)%2)*(w+8)/2,44+math.floor((i-1)/2)*44,(w-8)/2,35,function()emit("Admin",{command=c[2]})end)end
		button(body,"Привести друга пешком",0,228,w,32,function()emit("Admin",{command="friendwalk"})end,"primary")
		avatarDebug=text(body,"",12,C.paper,UDim2.fromOffset(0,270),UDim2.fromOffset(w,90))
		text(body,"F8 → «Все оформления» открывает титулы, nametag, фоны и рамки. Нативные треки гостя используются после загрузки; резерв включается, если Roblox не отдаёт анимацию.",11,C.muted,UDim2.fromOffset(0,370),UDim2.fromOffset(w,80));return
	end
	local specimen={mutation=lab.mutation,uniqueness=lab.unique,conditionScore=.95,visualSeed=417,repair=false,surfaceTone=0}
	viewport(body,lab.id,0,42,w,170,specimen);text(body,Rarity.Caption(specimen).." / цена ×"..string.format("%.3f",Rarity.Multiplier(specimen)),13,C.mint,UDim2.fromOffset(0,217),UDim2.fromOffset(w,26),Enum.Font.GothamBold)
	local choices={"none",unpack(Rarity.Order)};local columns=if w>530 then 4 else 2;local bw=(w-(columns-1)*6)/columns;local y=250
	for i,id in ipairs(choices)do
		local d=Rarity.Definitions[id];local b=button(body,if d then d.name else"Без мутации",((i-1)%columns)*(bw+6),y+math.floor((i-1)/columns)*34,bw,28,function()lab.mutation=id;render()end,if lab.mutation==id then"primary"else nil)
		if d and lab.mutation~=id then b.TextColor3=Color3.fromRGB(unpack(d.color))end
	end;y+=math.ceil(#choices/columns)*34+8
	text(body,"Уникальность — выбери значение",11,C.muted,UDim2.fromOffset(0,y),UDim2.fromOffset(w,22));y+=27
	for i,v in ipairs({0,.1,1,10,100})do button(body,tostring(v).."%",(i-1)*(w+5)/5,y,(w-20)/5,28,function()lab.unique=v;render()end,if lab.unique==v then"primary"else nil)end;y+=38
	button(body,"Образец на полку",0,y,(w-8)/2,34,function()emit("Admin",{command="sample",id=lab.id,mutation=lab.mutation,uniqueness=lab.unique})end,"primary")
	button(body,"Все 8 вариантов на полки",(w+8)/2,y,(w-8)/2,34,function()emit("Admin",{command="samples",id=lab.id,uniqueness=lab.unique})end,"gold");y+=44
	button(body,"Клиент с выбранным предметом",0,y,w,30,function()emit("Admin",{command="spawn",id=lab.id,mutation=lab.mutation,uniqueness=lab.unique})end);y+=40
	button(body,if data.timersPaused then"Время: пауза / продолжить"else"Остановить время клиентов",0,y,w,28,function()emit("Admin",{command="pause"})end);y+=38
	text(body,"Предмет для сравнения",12,C.paper,UDim2.fromOffset(0,y),UDim2.fromOffset(w,24));y+=30
	for _,d in ipairs(catalog)do local id=d.id;button(body,d.id.." / "..d.name,0,y,w,28,function()lab.id=id;render(true)end,if lab.id==id then"gold"else nil);y+=34 end
end
local function drawGuide(w)
	heading("Быстрый старт","H — скрыть HUD / B — дело / TAB — игроки / F8 — тестовая лаборатория")
	local entries={"Сядь в своё рабочее кресло — дело откроется автоматически. Профессия выбирается бесплатно, прогресс каждой сохраняется.","У клиента у стойки 5–6 минут, у ожидающего 15–18 минут. Во время задания прибором его таймер стоит. Уход одного не обнуляет терпение остальных.","Выбери прибор, выполни задание, прочитай запись. Состояние и ремонт видны на предмете; реставрация не доказывает подделку.","Назови цену и подлинность, затем выдай оценку или раскрой торг. Гость отвечает в своей речевой плашке.","Купленные вещи — на пьедесталах и полках. E — осмотр с 3D, F — взять. Принеси вещь другому специалисту: E у его стойки, комиссия 40.","F8 открывает все 7 мутаций и значения уникальности. Выбери эффект в живом 3D, создай образец или все 8 вариантов рядом. Время можно остановить.","Титул движется у имени в TAB и над персонажем. Титул, рамка и фон карточки — разные настройки.","В Studio профиль тестовый. В опубликованной игре сохранение облачное. Наведи курсор на деньги, чтобы увидеть режим сохранения."}
	for i,v in ipairs(entries)do local c=panel(body,0,(i-1)*86,w,76);text(c,string.format("%02d",i),19,C.mint,UDim2.fromOffset(12,16),UDim2.fromOffset(33,32),Enum.Font.GothamBold);text(c,v,12,C.paper,UDim2.fromOffset(54,7),UDim2.fromOffset(w-66,62))end
	button(body,"Повторить обучение",0,#entries*86,w,32,function()emit("Tutorial",{mode="replay"});mode=nil;render()end);button(body,"Скрыть обучение",0,#entries*86+40,w,32,function()emit("Tutorial",{mode="skip"});mode=nil;render()end)
end
local function drawReceipt(w)
	local p=lastReceipt;if not p then return end
	heading(if p.kind=="report"then"Мнение специалиста"else"Оценка завершена","Результат последней сделки")
	text(body,p.name,22,C.paper,UDim2.new(),UDim2.fromOffset(w,50),Enum.Font.GothamBold)
	local value=if p.kind=="report"then p.by.."\nОценка: "..money(p.quote).."\nЗаключение: "..(if p.auth=="genuine"then"оригинал"elseif p.auth=="replica"then"реплика"else"неясно").."\nКомиссия: "..p.fee else"Стоимость: "..money(p.value).."\nТвоя оценка: "..money(p.quote).." / ошибка "..p.error.."%\n"..(if p.genuine then"Оригинал"else"Реплика").."\nГонорар +"..p.fee.." / REP "..p.rep..(if p.bought then"\nПредмет выставлен в твоей коллекции"else"")
	text(body,value,16,C.paper,UDim2.fromOffset(0,62),UDim2.fromOffset(w,190));button(body,"Следующий клиент",0,268,w,34,function()mode=if data and data.seated then"case"else nil;render()end,"primary")
end

render=function(resetScroll)
	local focused=Input:GetFocusedTextBox();local focusName;for name,field in pairs(focusedFields)do if field==focused then focusName=name end end;local cursor=focused and focused.CursorPosition
	local oldScroll=body.CanvasPosition;local sameMode=mode==renderedMode;renderedMode=mode
	release();body:ClearAllChildren();caseBody:ClearAllChildren();body.CanvasPosition=if sameMode and not resetScroll then oldScroll else Vector2.new()
	manager.Visible=mode~=nil and mode~="case"and mode~="peer";casePane.Visible=mode=="case"or mode=="peer"
	if not mode then renderHUD();return end
	if not data then manager.Visible=false;casePane.Visible=false;return end
	local w=math.max(240,math.floor(body.AbsoluteSize.X-6))
	if mode=="case"or mode=="peer"then
		caseMode=if mode=="peer"then"peer"else"npc";drawCase()
		local r=currentCase();local key=mode..":"..(r and r.id or"empty")..":"..(r and r.challenge and r.challenge.id or"form")
		if key~=lastCaseView then caseBody.CanvasPosition=Vector2.new();lastCaseView=key end
	elseif mode=="workshop"then drawWorkshop(w)
	elseif mode=="specialty"then drawSpecialty(w)
	elseif mode=="inventory"then drawInventory(w)
	elseif mode=="titles"then drawTitles(w)
	elseif mode=="decor"then drawDecor(w)
	elseif mode=="admin"then drawAdmin(w)
	elseif mode=="guide"then drawGuide(w)
	elseif mode=="receipt"then drawReceipt(w)
	elseif mode=="exhibit"and exhibit then heading(exhibit.owner.." / витрина","Осмотр предмета в 3D");itemDetails(body,exhibit.item,w,exhibit.owned,0)end
	if focusName and focusedFields[focusName]then local field=focusedFields[focusName];task.defer(function()if field.Parent then field:CaptureFocus();if cursor then field.CursorPosition=math.clamp(cursor,-1,#field.Text+1)end end end)end
	renderHUD()
end
renderRoster=function()
	rosterShell.Visible=rosterOpen;rosterShell:ClearAllChildren();corner(rosterShell,12);stroke(rosterShell,C.line,.25)
	if not rosterOpen then return end
	local w=layout.roster.w;local height=math.min(layout.height-100,29+math.min(#rows,6)*88);rosterShell.Size=UDim2.fromOffset(w,height)
	text(rosterShell,"ОЦЕНЩИКИ",10,C.muted,UDim2.fromOffset(12,4),UDim2.fromOffset(w-24,22),Enum.Font.GothamBold)
	local list=scroll(rosterShell,5,28,w-10,height-32)
	for i,row in ipairs(rows)do
		if i>6 then break end
		local card=IdentityFX.Card(list,{name=row.name,userId=row.userId,title=row.title,nametag=row.nametag,card=row.card,frame=row.frame,width=w-14,height=82})
		card.Position=UDim2.fromOffset(0,(i-1)*88)
		local rep=text(card,tostring(row.reputation).." REP",8,C.mint,UDim2.fromOffset(18,66),UDim2.fromOffset(54,13),Enum.Font.GothamBold);rep.TextXAlignment=Enum.TextXAlignment.Center
	end
end
local nameplates={}
local function updateNameplates()
	local present={}
	for _,row in ipairs(rows)do
		present[row.userId]=true
		local target=Players:GetPlayerByUserId(row.userId);local head=target and target.Character and target.Character:FindFirstChild("Head");local old=nameplates[row.userId]
		if not head then if old then old:Destroy();nameplates[row.userId]=nil end;continue end
		local key=(row.title or"trainee").."|"..(row.nametag or"tag_plain").."|"..row.name
		if old and old.Parent==head and old:GetAttribute("IdentityKey")==key then continue end
		if old then old:Destroy()end
		local board=make("BillboardGui",{Name="ProbaPlayerTitle",Size=UDim2.fromOffset(230,80),StudsOffset=Vector3.new(0,3.1,0),MaxDistance=65,AlwaysOnTop=false},head);board:SetAttribute("IdentityKey",key);nameplates[row.userId]=board
		IdentityFX.World(board,{name=row.name,title=row.title,nametag=row.nametag})
		local humanoid=target.Character:FindFirstChildOfClass("Humanoid");if humanoid then humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
	end
	for id,board in pairs(nameplates)do if not present[id]then board:Destroy();nameplates[id]=nil end end
end
renderHUD=function()
	if not data then return end
	walletText.Text=money(data.cash);repText.Text=tostring(data.reputation).." REP";repFill.Size=UDim2.fromScale(data.reputation/100,1)
	saveDot.BackgroundColor3=if data.saveMode=="session"then C.red elseif data.saveMode=="cloud"then C.mint else C.gold
	queueButton.Text="Игроки / TAB";admin.Visible=data.admin
	pending.Visible=data.pending~=nil;if data.pending then pendingText.Text=data.pending.name.."\n"..data.pending.item end
	if avatarDebug and avatarDebug.Parent then
		local a=data.avatarStatus
		avatarDebug.Text=if a then "Гость: "..a.name.."\nДрайвер: "..a.status.." / clip "..a.clip.."\nWalk из аватара: "..a.walk..(if a.error and a.error~=""then"\n"..a.error else"")else"Нет гостя. Нажми «Привести друга пешком»."
	end
	local tutorial=data.tutorial;mentor.Visible=tutorial and not tutorial.done and not mode and not layout.mobile
	if tutorial and not tutorial.done then mentor.Text="  "..tutorial.step.."/"..tutorial.total.."  "..tutorial.title end
	mentorFocus.Enabled=false
	if tutorial and not tutorial.done and not mode then
		local plot=data.plot and workspace.Plots:FindFirstChild(data.plot);local b=plot and plot:FindFirstChild("Building")
		local target=if tutorial.event=="seated"then b and b:FindFirstChild("AppraiserSeat",true)else nil
		if target then mentorFocus.Adornee=target;mentorFocus.Enabled=true end
	end
	if mode=="case"or mode=="peer"then local r=currentCase();if r then timeLabel.Text=timerText(r)end end
	brand.Visible=not layout.mobile and not manager.Visible;sound.Text=if muted then"OFF"else"SFX"
	for id,b in pairs(navButtons)do b.BackgroundColor3=if mode==id then C.mint:Lerp(C.panel,.78)else C.panel;b.UIStroke.Color=if mode==id then C.mint else C.line end
end
resize=function()
	local s=gui.AbsoluteSize;if s.X<1 or s.Y<1 then return end;layout=Layout.Compute(s.X,s.Y)
	for object,r in pairs({[brand]=layout.brand,[wallet]=layout.wallet,[dock]=layout.dock,[mentor]=layout.tutorial,[manager]=layout.manager,[casePane]=layout.case})do object.Position=UDim2.fromOffset(r.x,r.y);object.Size=UDim2.fromOffset(r.w,r.h)end
	queueButton.Position=UDim2.fromOffset(s.X-116,57);home.Position=UDim2.fromOffset(s.X-62,s.Y-46);sound.Position=UDim2.fromOffset(s.X-111,s.Y-46)
	home.Visible=s.X>=650;sound.Visible=s.X>=650;admin.Position=UDim2.fromOffset(14,s.Y-46)
	closeManager.Position=UDim2.fromOffset(layout.manager.w-42,12);body.Size=UDim2.fromOffset(layout.manager.w-32,layout.manager.h-84);caseBody.Size=UDim2.fromOffset(layout.case.w-24,layout.case.h-64)
	rosterShell.Position=UDim2.fromOffset(layout.roster.x,85);pending.Position=UDim2.fromOffset(s.X-256,107)
	toastLabel.Size=UDim2.fromOffset(math.min(360,s.X-28),42);toastLabel.Position=UDim2.fromOffset((s.X-toastLabel.Size.X.Offset)/2,12)
	if mode then render()else renderHUD()end;if rosterOpen then renderRoster()end
end
State.OnClientEvent:Connect(function(packet)
	if packet.kind=="snapshot"then data=packet;render()
	elseif packet.kind=="pulse"and data then data.queue=packet.queue;data.avatarStatus=packet.avatarStatus;if data.case and data.case.id==packet.caseId then data.case.patience=packet.patience;data.case.timing=packet.timing end;renderHUD()
	elseif packet.kind=="open"then mode=packet.panel;showModel=false;showNotes=false;showOffer=false;render()
	elseif packet.kind=="catalog"then catalog=packet.items
	elseif packet.kind=="roster"then rows=packet.rows;renderRoster();updateNameplates()
	elseif packet.kind=="toast"then toast(packet.text,packet.tone)
	elseif packet.kind=="exhibit"then exhibit=packet;mode="exhibit";render()
	elseif packet.kind=="leaveDesk"then if mode=="case"or mode=="peer"then mode=nil;render()end
	elseif packet.kind=="challengeUpdate"and data then local r=if data.peer and data.peer.id==packet.caseId then data.peer else data.case;if r and r.id==packet.caseId then r.challenge=packet.challenge;if mode=="case"or mode=="peer"then render()end end
	elseif packet.kind=="receipt"or packet.kind=="report"then lastReceipt=packet;mode="receipt";render()end
end)
Input.InputBegan:Connect(function(input,processed)
	if processed then return end
	if input.KeyCode==Enum.KeyCode.Tab then rosterOpen=not rosterOpen;renderRoster()
	elseif input.KeyCode==Enum.KeyCode.F8 and data and data.admin then mode=if mode=="admin"then nil else"admin";render()
	elseif input.KeyCode==Enum.KeyCode.B then emit("Open",{panel="case"})
	elseif input.KeyCode==Enum.KeyCode.H then gui.Enabled=not gui.Enabled
	elseif input.KeyCode==Enum.KeyCode.Escape then mode=nil;render()end
end)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
SoundService.ChildAdded:Connect(function(group)if group.Name=="ProbaWorld"then group.Volume=if muted then 0 else 1 end end)
RunService.RenderStepped:Connect(function(dt)
	for i=#views,1,-1 do local v=views[i];if not v.frame.Parent then table.remove(views,i);continue end;if not visible(v.frame)then continue end
		if not v.dragging and os.clock()>v.resume then v.yaw+=dt*.22 end
		local r=v.size*1.9;v.camera.CFrame=CFrame.lookAt(v.target+Vector3.new(math.sin(v.yaw)*math.cos(v.pitch)*r,math.sin(v.pitch)*r,math.cos(v.yaw)*math.cos(v.pitch)*r),v.target)
	end
end)
task.spawn(function()while gui.Parent do task.wait(1);updateNameplates()end end)
resize();emit("Hello");task.delay(4,function()if not data then emit("Hello")end end)

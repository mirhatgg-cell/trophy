local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Domain = require(ReplicatedStorage.Shared.Domain)
local InstrumentUI = require(script.Parent:WaitForChild("InstrumentUI"))
local Appearance = require(ReplicatedStorage.Shared.Appearance)
local Rarity = require(ReplicatedStorage.Shared.Rarity)
local Decor = require(ReplicatedStorage.Shared.Decor)
require(script.Parent:WaitForChild("ItemEffects")).Start()
local network = ReplicatedStorage:WaitForChild("Network")
local Action, State = network:WaitForChild("Action"), network:WaitForChild("State")

local C = { ink = Color3.fromRGB(23, 36, 39), deep = Color3.fromRGB(15, 25, 28), panel = Color3.fromRGB(34, 49, 51),
	paper = Color3.fromRGB(243, 239, 224), muted = Color3.fromRGB(163, 178, 172), mint = Color3.fromRGB(140, 208, 177),
	gold = Color3.fromRGB(216, 178, 108), copper = Color3.fromRGB(199, 139, 104), line = Color3.fromRGB(70, 87, 86), red = Color3.fromRGB(224, 132, 121) }
local FONT, BOLD, DISPLAY, NUM = Enum.Font.Gotham, Enum.Font.GothamBold, Enum.Font.Garamond, Enum.Font.Code
local data, catalog, rows = nil, {}, {}
local muted=false
local function updateAudio()local group=SoundService:FindFirstChild("ProbaWorld");if group then group.Volume=if muted then 0 else 1 end end
SoundService.ChildAdded:Connect(function(group)if group.Name=="ProbaWorld"then updateAudio()end end)
local activePanel, caseMode, selectedInventory, adminId = nil, "npc", nil, "h01"
local selectedDecor="sign_painted"
local caseId, auth, dragAngle, scanUntil = nil, "unknown", 0, 0
local dragPitch=.42
local bindings, connections = {}, {}
local animatedBadges = {}
local viewportModel, viewportCamera, viewportTarget, viewportSize
local window, content, pageTitle, pageSubtitle, quoteBox, offerBox, scanLabel, scanBar, receipt
local casePane,caseBody,caseHeading
local renderPanel, renderRoster, renderHUD
local rosterVisible = false
local rosterShell
local mentor,mentorHeading,mentorDetail,mentorFocus

local gui = Instance.new("ScreenGui"); gui.Name = "ProbaInterface"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 20; gui.Parent = player:WaitForChild("PlayerGui")
pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) end)

local function make(class, properties, parent)
	local obj = Instance.new(class)
	for key, value in pairs(properties or {}) do obj[key] = value end
	obj.Parent = parent
	return obj
end
local function corner(obj, radius) make("UICorner", { CornerRadius = UDim.new(0, radius or 12) }, obj) end
local function stroke(obj, color, alpha, width) make("UIStroke", { Color = color or C.line, Transparency = alpha or 0, Thickness = width or 1 }, obj) end
local function text(parent, value, size, color, pos, dimensions, font)
	return make("TextLabel", { BackgroundTransparency = 1, Text = value, TextColor3 = color or C.paper, TextSize = size or 14,
		Font = font or FONT, Position = pos or UDim2.new(), Size = dimensions or UDim2.fromOffset(200, 24), TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = true }, parent)
end
local function line(parent, x, y, w, color) return make("Frame", { BorderSizePixel = 0, BackgroundColor3 = color or C.line, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, 1) }, parent) end
local function button(parent, label, x, y, w, h, callback, style)
	local b = make("TextButton", { AutoButtonColor = false, Text = label, Font = BOLD, TextSize = 13, TextColor3 = if style == "primary" then C.deep else C.paper,
		BackgroundColor3 = if style == "primary" then C.mint elseif style == "gold" then Color3.fromRGB(105, 82, 45) else C.panel,
		BorderSizePixel = 0, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h) }, parent)
	corner(b, 8); stroke(b, if style == "primary" then C.mint else C.line, 0.25)
	b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), { BackgroundTransparency = 0.18 }):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), { BackgroundTransparency = 0 }):Play() end)
	b.Activated:Connect(callback)
	return b
end
local function field(parent, placeholder, x, y, w)
	local box = make("TextBox", { PlaceholderText = placeholder, Text = "", ClearTextOnFocus = false, Font = NUM, TextSize = 23,
		TextColor3 = C.paper, PlaceholderColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = C.deep,
		BorderSizePixel = 0, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, 47) }, parent)
	corner(box, 8); stroke(box); make("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 10) }, box)
	return box
end
local function money(value)
	local s = tostring(math.floor(value or 0)); local result = s:reverse():gsub("(%d%d%d)", "%1 "):reverse():gsub("^ ", "")
	return result
end
local function emit(action, packet) Action:FireServer(action, packet or {}) end
local function ping()
	local sound = Instance.new("Sound"); sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"; sound.Volume = 0.12; sound.Parent = SoundService
	sound.SoundGroup=SoundService:FindFirstChild("ProbaWorld")
	SoundService:PlayLocalSound(sound); game:GetService("Debris"):AddItem(sound, 2)
end

-- A compact editorial HUD: a seal, engraved-looking rules, tabbed navigation and a paper dossier.
local brand = make("Frame", { BackgroundColor3 = C.deep, BackgroundTransparency = 0.08, BorderSizePixel = 0, Position = UDim2.fromOffset(18, 16), Size = UDim2.fromOffset(268, 76) }, gui)
corner(brand, 12); stroke(brand, C.gold, 0.55)
local seal = make("Frame", { BackgroundColor3 = C.ink, Position = UDim2.fromOffset(13, 13), Size = UDim2.fromOffset(50, 50) }, brand); corner(seal, 25); stroke(seal, C.gold, 0, 2)
text(seal, "P", 36, C.gold, UDim2.fromOffset(0, -2), UDim2.fromOffset(50, 50), DISPLAY).TextXAlignment = Enum.TextXAlignment.Center
text(brand, "P R O B A", 21, C.paper, UDim2.fromOffset(78, 9), UDim2.fromOffset(185, 30), BOLD)
text(brand, "Б Ю Р О   О Ц Е Н К И", 10, C.muted, UDim2.fromOffset(79, 40), UDim2.fromOffset(180, 18), FONT)
line(brand, 79, 63, 156, C.gold)
local wallet = make("Frame", { BackgroundColor3 = C.deep, BackgroundTransparency = 0.06, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 16), Size = UDim2.fromOffset(268, 102) }, gui)
corner(wallet, 12); stroke(wallet)
local walletValue = text(wallet, "···", 25, C.gold, UDim2.fromOffset(18, 8), UDim2.fromOffset(230, 32), NUM)
local repText = text(wallet, "Бюро открывается…", 12, C.muted, UDim2.fromOffset(18, 43), UDim2.fromOffset(235, 22))
local repTrack = make("Frame", { BackgroundColor3 = C.panel, BorderSizePixel = 0, Position = UDim2.fromOffset(18, 76), Size = UDim2.fromOffset(232, 4) }, wallet); corner(repTrack, 2)
local repFill = make("Frame", { BackgroundColor3 = C.mint, BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0) }, repTrack); corner(repFill, 2)
local saveText = text(wallet, "", 9, C.muted, UDim2.fromOffset(18, 85), UDim2.fromOffset(235, 13))

local objective = make("Frame", { BackgroundColor3 = C.deep, BackgroundTransparency = 0.08, BorderSizePixel = 0, Position = UDim2.fromOffset(18, 106), Size = UDim2.fromOffset(268, 99) }, gui)
corner(objective, 10); stroke(objective)
text(objective, "СЕГОДНЯ В БЮРО", 10, C.gold, UDim2.fromOffset(15, 9), UDim2.fromOffset(235, 19), BOLD)
local objectiveText = text(objective, "Загрузка участка…", 13, C.paper, UDim2.fromOffset(15, 31), UDim2.fromOffset(235, 43))
local queueText = text(objective, "", 11, C.muted, UDim2.fromOffset(15, 77), UDim2.fromOffset(235, 16))

local dock = make("Frame", { AnchorPoint = Vector2.new(0.5, 1), BackgroundColor3 = C.deep, BackgroundTransparency = 0.04, BorderSizePixel = 0,
	Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(849, 65) }, gui)
corner(dock, 13); stroke(dock, C.gold, 0.65)
local dockScale = make("UIScale", { Scale = 1 }, dock)
local dockItems = { {"01  Дело", "case"}, {"02  Коллекция", "inventory"}, {"03  Мастерская", "workshop"}, {"04  Профессия", "specialty"}, {"05  Титулы", "titles"}, {"06  Декор", "decor"}, {"?  Справка", "guide"} }
for i, entry in ipairs(dockItems) do button(dock, entry[1], 10 + (i - 1) * 119, 10, 112, 44, function() emit("Open", { panel = entry[2] }) end) end
local homeButton = button(gui, "⌂  К своему бюро", 0, 0, 175, 37, function() emit("Return") end)
homeButton.AnchorPoint = Vector2.new(1, 1); homeButton.Position = UDim2.new(1, -18, 1, -96)
local muteButton
muteButton=button(gui,"Звук: вкл",0,0,105,30,function()muted=not muted;muteButton.Text=if muted then"Звук: выкл"else"Звук: вкл";updateAudio()end)
muteButton.AnchorPoint=Vector2.new(1,1);muteButton.Position=UDim2.new(1,-18,1,-139)
local rosterButton = button(gui, "Оценщики  [TAB]", 0, 0, 175, 37, function() rosterVisible = not rosterVisible; renderRoster() end)
rosterButton.AnchorPoint = Vector2.new(1, 0); rosterButton.Position = UDim2.new(1, -18, 0, 131)
local adminButton = button(gui, "Лаборатория  [F8]", 0, 0, 175, 32, function() activePanel = "admin"; renderPanel() end, "gold")
adminButton.AnchorPoint = Vector2.new(0, 1); adminButton.Position = UDim2.new(0, 18, 1, -96); adminButton.Visible = false
rosterShell = make("Frame", {AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-18,0,177),Size=UDim2.fromOffset(310,420),
	BackgroundColor3=C.deep,BackgroundTransparency=0.07,BorderSizePixel=0,Visible=false},gui)
corner(rosterShell,10);stroke(rosterShell,C.gold,0.55)

local toastFrame = make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 18), Size = UDim2.fromOffset(480, 250) }, gui)
toastFrame.ZIndex=40
local toastLayout = make("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center }, toastFrame)
local function toast(value, tone)
	local frame = make("Frame", { BackgroundColor3 = C.deep, BackgroundTransparency = 0.02, BorderSizePixel = 0, Size = UDim2.fromOffset(470, 63) }, toastFrame)
	corner(frame, 10); stroke(frame, if tone == "bad" then C.red elseif tone == "good" then C.mint else C.gold, 0.25)
	text(frame, value, 13, C.paper, UDim2.fromOffset(17, 8), UDim2.fromOffset(436, 47))
	task.delay(5, function() if frame.Parent then TweenService:Create(frame, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play(); task.wait(0.25); frame:Destroy() end end)
end
mentor=make("Frame",{AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,14),Size=UDim2.fromOffset(354,86),
	BackgroundColor3=C.deep,BackgroundTransparency=.08,BorderSizePixel=0,Visible=false},gui)
corner(mentor,10);stroke(mentor,C.gold,.5)
mentorHeading=text(mentor,"ПЕРВЫЙ ДЕНЬ",13,C.gold,UDim2.fromOffset(12,5),UDim2.fromOffset(310,23),BOLD)
mentorDetail=text(mentor,"",11,C.paper,UDim2.fromOffset(12,31),UDim2.fromOffset(329,46))
button(mentor,"×",325,5,22,22,function()emit("Tutorial",{mode="skip"})end)
mentorFocus=make("Highlight",{FillTransparency=.95,OutlineTransparency=.15,FillColor=C.gold,OutlineColor=C.gold,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop,Enabled=false},workspace)
local function renderMentor()
	local t=data and data.tutorial
	mentor.Visible=t~=nil and not t.done;mentorFocus.Enabled=false
	if not t or t.done then return end
	mentorHeading.Text=t.step.."/"..t.total.." · "..t.title;mentorDetail.Text=t.detail
	local plot=data.plot and workspace.Plots:FindFirstChild(data.plot)
	local building=plot and plot:FindFirstChild("Building")
	local target
	if t.event=="seated"then target=building and building:FindFirstChild("AppraiserSeat",true)
	elseif t.event=="loupe"or t.event=="scale"then target=plot and plot:FindFirstChild("CurrentItem")
	elseif t.event=="carried"then local collection=plot and plot:FindFirstChild("OwnedCollection");target=collection and collection:FindFirstChildOfClass("Model")end
	if target then mentorFocus.Adornee=target;mentorFocus.Enabled=true end
end

window = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(980, 660),
	BackgroundColor3 = C.ink, BorderSizePixel = 0, Visible = false }, gui)
corner(window, 16); stroke(window, C.gold, 0.42)
local windowScale = make("UIScale", { Scale = 1 }, window)
local header = make("Frame", { BackgroundColor3 = C.deep, BorderSizePixel = 0, Size = UDim2.fromOffset(980, 92) }, window); corner(header, 16)
make("Frame", { BorderSizePixel = 0, BackgroundColor3 = C.deep, Position = UDim2.fromOffset(0, 60), Size = UDim2.fromOffset(980, 32) }, header)
text(header, "П / БЮРО", 10, C.gold, UDim2.fromOffset(25, 12), UDim2.fromOffset(120, 15), BOLD)
pageTitle = text(header, "Рабочее дело", 32, C.paper, UDim2.fromOffset(24, 27), UDim2.fromOffset(775, 40), DISPLAY)
pageSubtitle = text(header, "", 11, C.muted, UDim2.fromOffset(26, 67), UDim2.fromOffset(820, 19))
button(header, "×", 919, 22, 38, 38, function() window.Visible = false; activePanel = nil end)
content = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(22, 109), Size = UDim2.fromOffset(936, 530) }, window)
casePane=make("Frame",{AnchorPoint=Vector2.new(0,1),Position=UDim2.new(0,14,1,-91),Size=UDim2.fromOffset(340,550),
	BackgroundColor3=C.deep,BackgroundTransparency=.08,BorderSizePixel=0,Visible=false},gui)
corner(casePane,12);stroke(casePane,C.gold,.4)
caseHeading=text(casePane,"PROBA / ЭКСПЕРТИЗА",17,C.paper,UDim2.fromOffset(14,7),UDim2.fromOffset(280,29),DISPLAY)
button(casePane,"×",302,8,27,27,function()casePane.Visible=false;activePanel=nil end)
caseBody=make("ScrollingFrame",{Position=UDim2.fromOffset(12,44),Size=UDim2.new(1,-24,1,-53),BackgroundTransparency=1,
	BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,ScrollBarImageColor3=C.gold},casePane)

local function clearContent()
	for _, c in ipairs(connections) do c:Disconnect() end; connections = {}
	content:ClearAllChildren(); bindings = {}; viewportModel = nil; viewportCamera = nil; quoteBox = nil; offerBox = nil; scanLabel = nil; scanBar = nil
	caseBody:ClearAllChildren()
	local surviving={};for _,badge in ipairs(animatedBadges)do if badge.object.Parent and badge.object:IsDescendantOf(rosterShell)then table.insert(surviving,badge)end end;animatedBadges=surviving
end
local function heading(title, subtitle) pageTitle.Text = title; pageSubtitle.Text = subtitle or "" end
local function scroll(parent, x, y, w, h)
	local s = make("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
		ScrollBarThickness = 4, ScrollBarImageColor3 = C.gold, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y }, parent)
	return s
end
local function currentCase()
	return if data then (if caseMode == "peer" then data.peer else data.case) else nil
end
local function itemViewport(parent, itemId, x, y, w, h, appearance, sourceFolder)
	local frame = make("ViewportFrame", { BackgroundColor3 = C.deep, BorderSizePixel = 0, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
		Ambient = Color3.fromRGB(172, 172, 153), LightColor = Color3.fromRGB(255, 237, 195), LightDirection = Vector3.new(-1, -1, -1), Active = true }, parent)
	corner(frame, 12); stroke(frame)
	local world = make("WorldModel", {}, frame)
	local source = (sourceFolder or ReplicatedStorage.ItemModels):FindFirstChild(itemId)
	if source then
		viewportModel = source:Clone(); viewportModel:PivotTo(CFrame.new()); viewportModel.Parent = world
		if appearance then Appearance.Apply(viewportModel,appearance)end
		local cf, bounds = viewportModel:GetBoundingBox(); viewportTarget = cf.Position; viewportSize = math.max(bounds.X, bounds.Y, bounds.Z, 1.8)
		viewportCamera = make("Camera", { FieldOfView = 37 }, frame); frame.CurrentCamera = viewportCamera
	end
	local dragging, lastX, lastY = false, 0, 0
	table.insert(connections, frame.InputBegan:Connect(function(input)
		local record=currentCase();if record and record.challenge and (activePanel=="case" or activePanel=="peer")then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; lastX = input.Position.X;lastY=input.Position.Y end
	end))
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			dragAngle += (input.Position.X - lastX) * 0.012;dragPitch=math.clamp(dragPitch+(input.Position.Y-lastY)*.009,-1.15,1.2)
			lastX=input.Position.X;lastY=input.Position.Y
		end
	end))
	table.insert(connections, UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end))
	text(frame, "ПОТЯНИ, ЧТОБЫ ПОВЕРНУТЬ", 9, C.muted, UDim2.fromOffset(15, h - 29), UDim2.fromOffset(w - 30, 15), NUM)
	local rule = make("Frame", { BackgroundColor3 = C.line, BorderSizePixel = 0, Position = UDim2.fromOffset(18, h - 47), Size = UDim2.fromOffset(w - 36, 1) }, frame)
	for i = 0, 18 do make("Frame", { BorderSizePixel = 0, BackgroundColor3 = C.line, Position = UDim2.fromOffset(18 + i * (w - 36) / 18, h - 47), Size = UDim2.fromOffset(1, if i % 3 == 0 then 7 else 4) }, frame) end
	return frame
end

local function testNotes(record)
	local notes = {}
	for _, toolId in ipairs(Config.ToolsOrder) do
		local r = record.tests[toolId]
		if r then table.insert(notes, Config.Tools[toolId].name .. ": " .. r.text) end
	end
	return if #notes > 0 then table.concat(notes, "\n\n") else "Доказательств пока нет. Начни с лупы и весов.\n\nНе путай реставрацию с подделкой: старая вещь может иметь новые детали."
end
local function packet(record)
	local quote = tonumber(quoteBox and quoteBox.Text)
	if not quote or quote < 1 then toast("Введи числовую оценку стоимости.", "bad"); return nil end
	return { caseId = record.id, quote = quote, auth = auth }
end
local function buildCase()
 local record=currentCase()
 if not record then
  caseHeading.Text="PROBA / ПРИЁМ"
  text(caseBody,"Кресло занято. Ждём клиента.",21,C.paper,UDim2.fromOffset(3,20),UDim2.fromOffset(305,65),DISPLAY)
  text(caseBody,"Гость сам подойдёт к стойке и расскажет о вещи. Пока можно бесплатно выбрать профессию.",13,C.muted,UDim2.fromOffset(3,100),UDim2.fromOffset(305,90))
  button(caseBody,"Профессии",3,220,303,38,function()activePanel="specialty";renderPanel()end,"primary")
  caseId=nil;return
 end
 if caseId~=record.id then auth="unknown";caseId=record.id;dragAngle=0;dragPitch=.42 end
 local item=record.item
 caseHeading.Text=item.name
 local track=make("Frame",{BackgroundColor3=C.line,BorderSizePixel=0,Position=UDim2.fromOffset(14,37),Size=UDim2.fromOffset(312,3)},casePane)
 bindings.patience=make("Frame",{BackgroundColor3=C.mint,BorderSizePixel=0,Size=UDim2.new(record.patience,0,1,0)},track)
 -- Clear previous header tracks too, without touching the permanent title and close button.
 for _,old in ipairs(casePane:GetChildren())do if old.Name=="PatienceTrack"then old:Destroy()end end;track.Name="PatienceTrack"
 local vh=if record.challenge then 168 else math.clamp(casePane.AbsoluteSize.Y-405,88,145)
 local view=itemViewport(caseBody,item.id,0,0,308,vh,item)
 if record.challenge then
  InstrumentUI.Build(view,record,{make=make,text=text,button=button,corner=corner,stroke=stroke,colors=C,emit=emit,connections=connections})
 end
 text(caseBody,Config.Specs[item.spec].symbol.." "..Config.Specs[item.spec].name.." · "..Rarity.Caption(item),10,C.muted,UDim2.fromOffset(0,vh+5),UDim2.fromOffset(308,27))
 local labels={loupe="Лупа",scale="Весы",uv="УФ",spectro="Спектр",diagnostic="Механизм"}
 for i,toolId in ipairs(Config.ToolsOrder)do
  local done=record.tests[toolId]~=nil
  button(caseBody,(if done then "✓ "else"")..labels[toolId],((i-1)%3)*105,vh+32+math.floor((i-1)/3)*34,98,28,function()emit("Inspect",{caseId=record.id,tool=toolId})end,if done then "gold"else nil)
 end
 if record.challenge then button(caseBody,"Отмена",210,vh+66,98,28,function()emit("CancelInspection",{caseId=record.id})end)end
 local notes=scroll(caseBody,0,vh+98,308,45)
 local notesLabel=text(notes,testNotes(record),11,C.paper,UDim2.new(),UDim2.new(1,-10,0,0));notesLabel.AutomaticSize=Enum.AutomaticSize.Y;notesLabel.TextYAlignment=Enum.TextYAlignment.Top
 text(caseBody,"≈ "..money(item.estimate.low).."—"..money(item.estimate.high).." · "..item.estimate.confidence.."%",13,C.gold,UDim2.fromOffset(0,vh+149),UDim2.fromOffset(308,25),NUM)
 quoteBox=field(caseBody,"Оценка",0,vh+177,308);quoteBox.Size=UDim2.fromOffset(308,34)
 local choices={}
 local function refreshAuth()for k,b in pairs(choices)do b.BackgroundColor3=if k==auth then C.mint else C.panel;b.TextColor3=if k==auth then C.deep else C.paper end end
 for i,entry in ipairs({{"genuine","Оригинал"},{"replica","Реплика"},{"unknown","Неясно"}})do
  choices[entry[1]]=button(caseBody,entry[2],(i-1)*105,vh+217,98,28,function()auth=entry[1];refreshAuth()end)
 end;refreshAuth()
 if caseMode=="npc" then
  offerBox=field(caseBody,"Выкуп за…",0,vh+250,149);offerBox.Size=UDim2.fromOffset(149,34)
  button(caseBody,"Предложить",160,vh+250,148,36,function()local p=packet(record);local amount=tonumber(offerBox.Text);if p and amount then p.amount=amount;emit("Offer",p)elseif p then toast("Введи сумму выкупа.","bad")end end,"gold")
  text(caseBody,if record.counter then "Встречная цена — в сообщении клиента"else"Клиент ответит в облачке над головой",10,C.muted,UDim2.fromOffset(0,vh+288),UDim2.fromOffset(308,24))
 end
 button(caseBody,if caseMode=="peer"then"Выдать заключение · +40"else"Выдать заключение",0,vh+311,308,39,function()local p=packet(record);if p then emit("Complete",p)end end,"primary")
 text(caseBody,record.customer,10,C.muted,UDim2.fromOffset(0,vh+354),UDim2.fromOffset(308,25))
end

local function buildWorkshop()
	heading("Мастерская", "Три уровня базы · приборы до III ранга · улучшения применяются к твоему физическому бюро")
	local level = Config.BaseLevels[data.baseLevel]; local nextLevel = Config.BaseLevels[data.baseLevel + 1]
	local card = make("Frame", { BackgroundColor3 = C.deep, BorderSizePixel = 0, Size = UDim2.fromOffset(936, 133) }, content); corner(card, 12); stroke(card, C.gold, 0.5)
	text(card, "БЮРО  /  0" .. data.baseLevel, 10, C.gold, UDim2.fromOffset(20, 13), UDim2.fromOffset(300, 19), NUM)
	text(card, level.name, 32, C.paper, UDim2.fromOffset(20, 34), UDim2.fromOffset(520, 46), DISPLAY)
	text(card, level.subtitle .. " · очередь " .. level.capacity .. " · гонорар ×" .. level.fee, 12, C.muted, UDim2.fromOffset(20, 91), UDim2.fromOffset(565, 21))
	button(card, if nextLevel then "Улучшить · " .. money(nextLevel.price) else "Максимум прототипа", 613, 33, 300, 46, function() emit("UpgradeBase") end, "primary")
	text(card, if nextLevel then "Следом: " .. nextLevel.name .. " · репутация " .. nextLevel.rep else "Третий уровень открыт. Дальше — развитие приборов и профессии.", 10, C.muted, UDim2.fromOffset(613, 84), UDim2.fromOffset(299, 35))
	for i, toolId in ipairs(Config.ToolsOrder) do
		local row = make("Frame", { BackgroundColor3 = C.panel, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 151 + (i - 1) * 73), Size = UDim2.fromOffset(936, 63) }, content); corner(row, 9)
		local def, rank = Config.Tools[toolId], data.equipment[toolId] or 0
		text(row, string.format("%02d", i), 19, C.gold, UDim2.fromOffset(17, 14), UDim2.fromOffset(40, 27), NUM)
		text(row, def.name, 15, C.paper, UDim2.fromOffset(68, 8), UDim2.fromOffset(400, 23), BOLD)
		text(row, def.hint, 11, C.muted, UDim2.fromOffset(68, 34), UDim2.fromOffset(490, 21))
		text(row, "РАНГ " .. rank .. "/3", 11, C.gold, UDim2.fromOffset(565, 18), UDim2.fromOffset(105, 22), NUM)
		local cost = def.price[rank + 1]
		button(row, if cost then (if rank == 0 then "Купить · " else "Улучшить · ") .. money(cost) else "Оснащён полностью", 684, 10, 234, 42, function() emit("UpgradeTool", { tool = toolId }) end, if cost then "primary" else nil)
	end
end

local function buildSpecialty()
	heading("Профессия", "Одна активная специальность. Историк не получает точность археолога автоматически.")
	for i, specId in ipairs(Config.SpecOrder) do
		local def = Config.Specs[specId]; local xp = data.specXP[specId] or 0
		local active = specId == data.specialty; local level = Domain.specLevel(xp)
		local row = make("Frame", { BackgroundColor3 = if active then Color3.fromRGB(44, 67, 59) else C.panel, BorderSizePixel = 0, Position = UDim2.fromOffset(0, (i - 1) * 84), Size = UDim2.fromOffset(936, 73) }, content)
		corner(row, 10); if active then stroke(row, C.mint, 0.3) end
		make("Frame", { BackgroundColor3 = Color3.fromRGB(unpack(def.color)), BorderSizePixel = 0, Position = UDim2.fromOffset(16, 15), Size = UDim2.fromOffset(4, 43) }, row)
		text(row, def.name, 20, C.paper, UDim2.fromOffset(35, 7), UDim2.fromOffset(290, 30), DISPLAY)
		text(row, def.subtitle, 11, C.muted, UDim2.fromOffset(35, 41), UDim2.fromOffset(420, 21))
		text(row, "УР. " .. level .. " / 10   ·   " .. xp .. " XP", 12, C.gold, UDim2.fromOffset(470, 25), UDim2.fromOffset(210, 22), NUM)
		button(row, if active then "Основная" else "Выбрать бесплатно", 700, 15, 218, 42, function() emit("Specialty", { spec = specId }) end, if active then "gold" else nil)
	end
	local level = Domain.specLevel(data.specXP[data.specialty])
	text(content,if level<10 then "Следующий уровень: "..math.max(0,30*level*level-data.specXP[data.specialty]).." XP" else "Квалификация максимальна",19,C.gold,UDim2.fromOffset(0,437),UDim2.fromOffset(402,47),NUM)
	text(content, "Уровни растут от оценок предметов соответствующей области. Смена профессии бесплатна; знания сохраняются. В чужой области приборы оставляют неопределённость.", 12, C.muted, UDim2.fromOffset(423, 435), UDim2.fromOffset(506, 66))
end

local function buildInventory()
	heading("Личная коллекция", #data.inventory .. " / " .. Config.InventoryLimit .. " вещей · предмет можно отнести к другому оценщику или продать скупщику")
	local selected
	for _, item in ipairs(data.inventory) do if item.uid == selectedInventory then selected = item end end
	if not selected and #data.inventory > 0 then selected = data.inventory[1]; selectedInventory = selected.uid end
	local list = scroll(content, 0, 0, 394, 524)
	for i, item in ipairs(data.inventory) do
		local b = button(list, "", 0, (i - 1) * 78, 382, 68, function() selectedInventory = item.uid; renderPanel() end, if item.uid == selectedInventory then "gold" else nil)
		text(b, item.name, 15, C.paper, UDim2.fromOffset(13, 8), UDim2.fromOffset(350, 24), BOLD)
		text(b, Config.Specs[item.spec].name .. " · куплен за " .. money(item.paid), 11, C.muted, UDim2.fromOffset(13, 39), UDim2.fromOffset(350, 20))
	end
	if not selected then
		text(content, "Коллекция пока пуста", 32, C.paper, UDim2.fromOffset(428, 95), UDim2.fromOffset(490, 60), DISPLAY)
		text(content, "При оценке клиентской вещи введи предложение выкупа. Если клиент согласится, предмет станет твоим.", 16, C.muted, UDim2.fromOffset(428, 174), UDim2.fromOffset(475, 110))
		return
	end
	itemViewport(content, selected.id, 418, 0, 518, 241, selected)
	text(content, selected.name, 25, C.paper, UDim2.fromOffset(418, 252), UDim2.fromOffset(518, 42), DISPLAY)
	text(content, selected.condition .. " · " .. selected.material, 12, C.muted, UDim2.fromOffset(418, 298), UDim2.fromOffset(518, 27))
	local report = selected.reports[#selected.reports]
	text(content, if report then "Последнее заключение: " .. report.by .. "\n" .. money(report.quote) .. " монет · " .. (if report.auth == "genuine" then "оригинал" elseif report.auth == "replica" then "реплика" else "подлинность не установлена")
		else "Независимой оценки ещё нет.\nТвой ориентир: " .. money(selected.estimate.low) .. "—" .. money(selected.estimate.high), 14, C.paper, UDim2.fromOffset(418, 339), UDim2.fromOffset(518, 65))
	button(content, "Взять в руки", 418, 425, 247, 46, function() emit("Carry", { uid = selected.uid }) end, "primary")
	button(content, "Продать скупщику", 680, 425, 256, 46, function() emit("Sell", { uid = selected.uid }) end, "gold")
	text(content, "Экспертиза у игрока: 40 монет. Подойди к его стойке с предметом в руках и нажми E. Для продажи нужен скупщик у южных ворот.", 11, C.muted, UDim2.fromOffset(418, 480), UDim2.fromOffset(518, 49))
end

local titleColors = { paper = C.muted, mint = C.mint, copper = C.copper, gold = C.gold, blue = Color3.fromRGB(130, 181, 222), violet = Color3.fromRGB(190, 155, 217) }
local function titleDefinition(id) for _, t in ipairs(Config.Titles) do if t.id == id then return t end end; return Config.Titles[1] end
local function titleBadge(parent, def, x, y, w, h)
	local color = titleColors[def.style]
	local frame = make("Frame", { BackgroundColor3 = color:Lerp(C.deep, 0.82), BorderSizePixel = 0, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), ClipsDescendants = true }, parent)
	corner(frame, 6); stroke(frame, color, 0.23)
	local gradient = make("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, color:Lerp(C.deep, 0.68)), ColorSequenceKeypoint.new(0.5, C.deep), ColorSequenceKeypoint.new(1, color:Lerp(C.deep, 0.86)) }), Rotation = 20 }, frame)
	local function ornament(px,py,ww,hh,angle,alpha)
		return make("Frame", { BorderSizePixel = 0, BackgroundColor3 = color, BackgroundTransparency = alpha or 0.75, Rotation = angle or 0, Position = UDim2.fromOffset(px,py), Size = UDim2.fromOffset(ww,hh) }, frame)
	end
	if def.style == "paper" then
		for i=1,12 do ornament(8+i*(w-20)/13,h-5,6,1,0,0.6) end
		ornament(w-42,7,24,2,0,0.7);ornament(w-42,13,18,2,0,0.8)
	elseif def.style == "mint" then
		for _, px in ipairs({5,w-6}) do ornament(px,5,1,8,0,0.15);ornament(px,h-13,1,8,0,0.15) end
		local optic=ornament(w-35,7,22,22,0,1);corner(optic,20);stroke(optic,color,0.65)
		ornament(w-25,13,1,10,0,0.65);ornament(w-30,18,11,1,0,0.65)
	elseif def.style == "copper" then
		for i=1,5 do ornament(w-18-i*14,-14,5,h+26,35,0.83) end
		ornament(0,0,w,2,0,0.15);ornament(0,h-2,w,2,0,0.15)
	elseif def.style == "blue" then
		for i=1,6 do ornament(w-10-i*9,h/2-3-i%3*2,3,6+(i%3)*4,0,0.65) end
		ornament(0,h-2,w,1,0,0.5)
	elseif def.style == "gold" then
		local sun=make("Frame",{BackgroundTransparency=1,Position=UDim2.fromOffset(w-27,h/2),Size=UDim2.fromOffset(0,0)},frame)
		for i=0,11 do
			local ray=make("Frame",{BorderSizePixel=0,BackgroundColor3=color,BackgroundTransparency=0.78,Position=UDim2.fromOffset(math.cos(i*math.pi/6)*16,math.sin(i*math.pi/6)*16),Size=UDim2.fromOffset(9,1),Rotation=i*30},sun)
		end
		table.insert(animatedBadges,{object=sun,gradient=gradient,style="gold"})
	else
		local constellation={{w-76,10},{w-49,24},{w-20,9},{w-12,28}}
		for i,p in ipairs(constellation) do
			local star=ornament(p[1],p[2],3,3,45,0.35)
			if i>1 then local prev=constellation[i-1];local dx,dy=p[1]-prev[1],p[2]-prev[2];ornament((p[1]+prev[1])/2,(p[2]+prev[2])/2,math.sqrt(dx*dx+dy*dy),1,math.deg(math.atan2(dy,dx)),0.85).AnchorPoint=Vector2.new(.5,.5) end
		end
		table.insert(animatedBadges,{object=frame,gradient=gradient,style="violet"})
	end
	text(frame, "◆", 12, color, UDim2.fromOffset(9, 0), UDim2.fromOffset(17, h), FONT)
	text(frame, def.name, 10, color, UDim2.fromOffset(31, 0), UDim2.fromOffset(w - 39, h), BOLD)
	return frame
end
local function buildTitles()
	heading("Знаки мастерства", "Титулы украшают карточку оценщика в списке игроков. Все условия проверяет сервер.")
	for i, def in ipairs(Config.Titles) do
		local y = (i - 1) * 85
		local row = make("Frame", { BackgroundColor3 = C.panel, BorderSizePixel = 0, Position = UDim2.fromOffset(((i - 1) % 2) * 477, math.floor((i - 1) / 2) * 168), Size = UDim2.fromOffset(459, 153) }, content); corner(row, 11)
		titleBadge(row, def, 17, 17, 425, 39)
		text(row, def.requirement, 12, C.muted, UDim2.fromOffset(18, 65), UDim2.fromOffset(422, 29))
		button(row, if data.title == def.id then "Надет" elseif data.unlocked[def.id] then "Надеть" else "Пока закрыт", 18, 105, 422, 32, function() emit("Title", { id = def.id }) end, if data.unlocked[def.id] then "gold" else nil)
	end
end

local function buildDecor()
	heading("Обстановка и оформление","Покупка один раз · установка в подготовленное место · рамка, фон и титул выбираются независимо")
	local list=scroll(content,0,0,548,523)
	for i,d in ipairs(Decor.List)do
		local owned=data.ownedDecor[d.id]
		local b=button(list,"",0,(i-1)*68,534,60,function()selectedDecor=d.id;renderPanel()end,if selectedDecor==d.id then"gold"else nil)
		text(b,d.name,14,C.paper,UDim2.fromOffset(12,4),UDim2.fromOffset(350,25),BOLD)
		text(b,(if owned then"В коллекции"elseif d.premium then"Премиум-косметика"else money(d.price).." монет").." · класс "..d.tier,10,C.muted,UDim2.fromOffset(12,33),UDim2.fromOffset(490,19))
	end
	local d=Decor.ById[selectedDecor]or Decor.List[1]
	if d.category=="frame"or d.category=="card"then
		local sample=make("Frame",{BackgroundColor3=Color3.fromRGB(unpack(d.color)),BorderSizePixel=0,Position=UDim2.fromOffset(575,25),Size=UDim2.fromOffset(350,150)},content)
		corner(sample,12);stroke(sample,C.gold,.2,if d.tier>1 then 2 else 1)
		text(sample,player.DisplayName,22,C.paper,UDim2.fromOffset(22,35),UDim2.fromOffset(306,35),BOLD)
		text(sample,titleDefinition(data.title).name,11,C.gold,UDim2.fromOffset(22,82),UDim2.fromOffset(306,27),BOLD)
	else itemViewport(content,d.id,568,0,368,270,nil,ReplicatedStorage.DecorModels)end
	text(content,d.name,27,C.paper,UDim2.fromOffset(568,284),UDim2.fromOffset(368,55),DISPLAY)
	text(content,d.description,14,C.muted,UDim2.fromOffset(568,345),UDim2.fromOffset(368,82))
	local owned=data.ownedDecor[d.id]
	local label=if data.equippedDecor[d.category]==d.id then"Установлено"elseif owned then"Установить"elseif d.premium then(if (Config.DecorProducts[d.id]or 0)>0 then"Купить за Robux"else"Премиум · не подключено")else"Купить и установить · "..money(d.price)
	button(content,label,568,445,368,44,function()emit("BuyDecor",{id=d.id})end,if owned or not d.premium then"primary"else"gold")
	if data.admin and d.premium and not owned then button(content,"Примерить в Studio",568,498,368,28,function()emit("Admin",{command="decor"})end)end
end

renderRoster = function()
	rosterShell.Visible=rosterVisible
	if not rosterVisible then return end
	for _,child in ipairs(rosterShell:GetChildren())do if child:IsA("GuiObject")then child:Destroy()end end
	text(rosterShell,"PROBA / ОЦЕНЩИКИ",11,C.gold,UDim2.fromOffset(12,7),UDim2.fromOffset(285,22),BOLD)
	rosterShell.Size=UDim2.fromOffset(310,35+math.min(#rows,6)*61)
	for i, row in ipairs(rows) do
		if i>6 then break end
		local def=titleDefinition(row.title);local color=titleColors[def.style]
		local cardDef=Decor.ById[row.card]or Decor.ById.card_paper;local frameDef=Decor.ById[row.frame]or Decor.ById.frame_plain
		local card=make("Frame",{BackgroundColor3=Color3.fromRGB(unpack(cardDef.color)),BackgroundTransparency=0.12,BorderSizePixel=0,
			Position=UDim2.fromOffset(8,32+(i-1)*61),Size=UDim2.fromOffset(294,54)},rosterShell);corner(card,6)
		stroke(card,Color3.fromRGB(unpack(frameDef.color)),.25,if frameDef.tier>=2 then 1.5 else 1)
		if frameDef.tier>=2 then
			for _,point in ipairs({{3,3},{282,3},{3,42},{282,42}})do
				local glyph=text(card,if row.frame=="frame_mechanical"then"⚙"else"✦",12,Color3.fromRGB(unpack(frameDef.color)),UDim2.fromOffset(point[1],point[2]),UDim2.fromOffset(10,10))
				if row.frame=="frame_mechanical"or row.frame=="frame_astral"then table.insert(animatedBadges,{object=glyph,style="frameSpin"})end
			end
		end
		if row.card=="card_starmap"then
			for star=1,7 do local dot=make("Frame",{BackgroundColor3=C.paper,BackgroundTransparency=.6,BorderSizePixel=0,Position=UDim2.fromOffset((star*37)%280+7,(star*17)%45+4),Size=UDim2.fromOffset(2,2)},card)end
		end
		text(card,Config.Specs[row.specialty].symbol,24,Color3.fromRGB(unpack(Config.Specs[row.specialty].color)),UDim2.fromOffset(7,6),UDim2.fromOffset(34,38))
		local name=text(card,row.name,14,if row.title=="trainee" then C.paper else color,UDim2.fromOffset(47,3),UDim2.fromOffset(195,24),BOLD)
		if row.title~="trainee"then stroke(name,color,.7,.8)end
		if row.title=="eye"or row.title=="collector"or row.title=="archivist"then
			local glyph=text(card,if row.title=="eye"then"⌕"else"✧",14,color,UDim2.fromOffset(230,31),UDim2.fromOffset(17,17),BOLD)
			table.insert(animatedBadges,{object=glyph,style="bob",x=230,y=31,phase=i})
		elseif row.title=="diplomat"then
			for dot=1,3 do local b=text(card,"•",12,color,UDim2.fromOffset(220+dot*7,32),UDim2.fromOffset(7,12));table.insert(animatedBadges,{object=b,style="bob",x=220+dot*7,y=32,phase=dot})end
		elseif row.title=="fake"then
			make("Frame",{BackgroundColor3=color,BackgroundTransparency=.3,BorderSizePixel=0,Position=UDim2.fromOffset(47,26),Size=UDim2.fromOffset(190,1)},card)
		end
		text(card,def.name,9,color,UDim2.fromOffset(47,29),UDim2.fromOffset(208,17),BOLD)
		text(card,tostring(row.reputation),16,C.gold,UDim2.fromOffset(250,5),UDim2.fromOffset(37,24),NUM)
		if def.style=="gold" or def.style=="violet" then
			local sheen=make("UIGradient",{Color=ColorSequence.new(color,C.paper)},name)
			table.insert(animatedBadges,{object=name,gradient=sheen,style="name"})
		end
	end
end

local function buildGuide()
	heading("Путеводитель оценщика", "ПРОБА / первый рабочий день")
	local guide = scroll(content, 0, 0, 936, 524)
	local entries = {
		{"01 / ТВОЁ БЮРО", "У тебя собственный участок. Войди в контейнер и сядь в кресло за столом: дело откроется само. B возвращает к делу сидящего оценщика. E у чужой стойки нужен только для независимой экспертизы. Все пять профессий можно менять бесплатно; опыт каждой сохраняется."},
		{"02 / ОСМОТР И ЗАКЛЮЧЕНИЕ", "Лупой найди три метки; обнули весы и подбери противовес; УФ-лампой пройди четыре зоны; настрой призму или механизм. Вращай и наклоняй вещь мышью. Читай записи, назови стоимость и выбери оригинал, реплику или неясно. Износ и реставрация сами по себе не доказывают подделку."},
		{"03 / ДЕНЬГИ И РЕПУТАЦИЯ", "Гонорар зависит от сложности вещи, точности, подлинности, терпения клиента и уровня бюро. Точное заключение даёт репутацию; серьёзная ошибка и ушедшие клиенты её снижают. Чем выше репутация, тем чаще гости и дороже предметы."},
		{"04 / ОЖИДАНИЕ И ЭМОЦИИ", "Очередь и время снижают терпение. Эмодзи над гостем показывают размышление, вздох, грусть, злость, радость и смех. Слишком низкая цена раздражает. Слишком щедрый выкуп радует продавца за твой счёт."},
		{"05 / ВЫКУП И ДРУГИЕ ИГРОКИ", "Чтобы выкупить вещь, заполни оценку, подлинность и предложение. Допускается три раунда торга. Из коллекции возьми предмет в руки, подойди к чужой стойке и нажми E. Владелец принимает запрос, исследует вещь и получает 40 монет за заключение."},
		{"06 / КОЛЛЕКЦИЯ И ДЕКОР", "Купленные вещи занимают настоящие полки: F берёт предмет в руки. У скупщика можно продать его за 72% рынка. В декоре 26 вариантов; вывески, картины, светильники и весы ставятся в подготовленные места. Титул у имени, рамка и фон TAB выбираются отдельно."},
		{"07 / РЕДКОСТЬ", "Уникальность и мутация выпадают независимо. Первые +0,1% уникальности — примерно 1 к 1000; каждый следующий шаг в тысячу раз реже. Серебро, золото, призрак, рост, лёд, угли и астрал имеют разные эффекты. Обычная вещь без мутации тоже может быть дорогой."},
		{"08 / СОХРАНЕНИЕ И ТЕСТИРОВАНИЕ", "В Studio используются отдельные тестовые данные. В опубликованной игре прогресс хранится в DataStore; при недоступности сохранения HUD явно показывает режим сеанса. F8 открывает лабораторию только тестировщикам Studio и разрешённым администраторам."},
	}
	for i, entry in ipairs(entries) do
		text(guide, entry[1], 13, C.gold, UDim2.fromOffset(14, (i - 1) * 137), UDim2.fromOffset(890, 24), BOLD)
		text(guide, entry[2], 15, C.paper, UDim2.fromOffset(14, (i - 1) * 137 + 33), UDim2.fromOffset(890, 93)).TextYAlignment = Enum.TextYAlignment.Top
	end
	button(guide,"Повторить обучение",14,#entries*137+8,300,40,function()emit("Tutorial",{mode="replay"});activePanel=nil;window.Visible=false end,"primary")
end

local function buildAdmin()
	heading("Лаборатория прототипа", "Доступ проверяет сервер · команды изменяют только собственный профиль · в Studio сохранения изолированы")
	if not data.admin then text(content, "Доступ закрыт", 28, C.red); return end
	local commands = { {"+25 000 монет", "funds"}, {"Репутация 75", "reputation"}, {"Все приборы III", "tools"}, {"Следующая база 1→2→3", "base"}, {"Сменить настроение гостя", "emotions"}, {"Открыть все титулы", "titles"}, {"Следующая мутация", "mutation"}, {"Уникальность 0→0.1→1→10→100%", "unique"}, {"Открыть весь декор", "decor"} }
	for i, entry in ipairs(commands) do button(content, entry[1], ((i - 1) % 3) * 313, math.floor((i - 1) / 3) * 52, 299, 42, function() emit("Admin", { command = entry[2] }) end, "gold") end
	text(content, "КАТАЛОГ / ВСЕ 100 ПРЕДМЕТОВ", 12, C.gold, UDim2.fromOffset(0, 157), UDim2.fromOffset(900, 25), BOLD)
	local list = scroll(content, 0, 190, 551, 333)
	for i, def in ipairs(catalog) do
		button(list, def.id .. " · " .. def.name, 0, (i - 1) * 38, 537, 32, function() adminId = def.id; renderPanel() end, if adminId == def.id then "gold" else nil)
	end
	itemViewport(content, adminId, 571, 190, 365, 182,if data.case and data.case.item.id==adminId then data.case.item else nil)
	button(content, "Клиент с этой вещью", 571, 389, 365, 44, function() emit("Admin", { command = "spawn", id = adminId }) end, "primary")
	button(content, "Добавить в коллекцию", 571, 447, 365, 44, function() emit("Admin", { command = "item", id = adminId }) end)
end

renderPanel = function(preserve)
	if not activePanel then return end
	if not data and activePanel ~= "guide" then toast("Загружаем профиль и участок…"); return end
	local oldQuote = quoteBox and quoteBox.Text; local oldOffer = offerBox and offerBox.Text; local oldCase = caseId
	local focused=UserInputService:GetFocusedTextBox();local focusKind=if focused and focused==quoteBox then "quote"elseif focused and focused==offerBox then "offer"else nil
	local cursor=focused and focused.CursorPosition
	clearContent(); window.Visible = activePanel~="case" and activePanel~="peer";casePane.Visible=not window.Visible
	if activePanel == "case" or activePanel == "peer" then
		caseMode = if activePanel == "peer" then "peer" else "npc"
		buildCase()
		if preserve and caseId == oldCase then if quoteBox and oldQuote then quoteBox.Text = oldQuote end; if offerBox and oldOffer then offerBox.Text = oldOffer end end
		if preserve and caseId==oldCase and focusKind then
			local box=if focusKind=="quote"then quoteBox else offerBox
			if box then task.defer(function()if box.Parent then box:CaptureFocus();if cursor then box.CursorPosition=math.clamp(cursor,-1,#box.Text+1)end end end)end
		end
	elseif activePanel == "workshop" then buildWorkshop()
	elseif activePanel == "specialty" then buildSpecialty()
	elseif activePanel == "inventory" then buildInventory()
	elseif activePanel == "titles" then buildTitles()
	elseif activePanel == "decor"then buildDecor()
	elseif activePanel == "roster" then renderRoster()
	elseif activePanel == "admin" then buildAdmin()
	elseif activePanel == "guide" then buildGuide() end
end

local pendingFrame = make("Frame", { BackgroundColor3 = C.deep, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 18, 1, -109), Size = UDim2.fromOffset(330, 164), Visible = false }, gui)
corner(pendingFrame, 12); stroke(pendingFrame, C.gold, 0.3)
text(pendingFrame, "ВХОДЯЩАЯ ЭКСПЕРТИЗА", 11, C.gold, UDim2.fromOffset(15, 9), UDim2.fromOffset(300, 24), BOLD)
local pendingText = text(pendingFrame, "", 13, C.paper, UDim2.fromOffset(15, 39), UDim2.fromOffset(300, 62))
button(pendingFrame, "Принять · +40", 15, 113, 166, 35, function() if data and data.pending then emit("PeerAccept", { id = data.pending.id }) end end, "primary")
button(pendingFrame, "Отклонить", 190, 113, 123, 35, function() if data and data.pending then emit("PeerDecline", { id = data.pending.id }) end end)

renderHUD = function()
	if not data then return end
	renderMentor()
	walletValue.Text = money(data.cash) .. "  ¤"
	repText.Text = "Репутация " .. data.reputation .. " / 100   ·   " .. Config.Specs[data.specialty].name
	TweenService:Create(repFill, TweenInfo.new(0.3), { Size = UDim2.new(data.reputation / 100, 0, 1, 0) }):Play()
	saveText.Text = if data.saveMode == "studio" then "STUDIO / тестовый профиль" elseif data.saveMode == "cloud" then "ОБЛАКО / автосохранение" elseif data.saveMode == "session" then "СЕАНС / без облачного сохранения" else "Загрузка…"
	saveText.TextColor3 = if data.saveMode == "session" then C.red else C.muted
	objective.Visible=workspace.CurrentCamera.ViewportSize.X>=760 and not data.seated
	objectiveText.Text = if data.case then "У стойки: " .. data.case.item.name else "Гости скоро подойдут.\nЗайми место за рабочим столом."
	queueText.Text = "Очередь " .. data.queue .. "/" .. data.capacity .. "   ·   " .. Config.BaseLevels[data.baseLevel].name
	adminButton.Visible = data.admin
	pendingFrame.Visible = data.pending ~= nil
	if data.pending then pendingText.Text = data.pending.name .. "\n" .. data.pending.item .. " · комиссия " .. data.pending.fee end
end

local function receiptCard(packet)
	if receipt then receipt:Destroy() end
	receipt = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(510, 412), BackgroundColor3 = C.paper, BorderSizePixel = 0, ZIndex = 5 }, gui)
	corner(receipt, 8); stroke(receipt, C.gold, 0, 2)
	local scale = make("UIScale", { Scale = math.clamp((workspace.CurrentCamera.ViewportSize.X - 30) / 510, 0.25, 1) }, receipt)
	text(receipt, "П Р О Б А  /  К В И Т А Н Ц И Я", 11, C.ink, UDim2.fromOffset(27, 19), UDim2.fromOffset(450, 27), BOLD)
	text(receipt, packet.name, 31, C.ink, UDim2.fromOffset(27, 53), UDim2.fromOffset(453, 67), DISPLAY)
	line(receipt, 27, 130, 454, Color3.fromRGB(197, 190, 169))
	local body
	if packet.kind == "report" then
		body = "Эксперт: " .. packet.by .. "\nОценка: " .. money(packet.quote) .. "\nЗаключение: " .. (if packet.auth == "genuine" then "оригинал" elseif packet.auth == "replica" then "реплика" else "подлинность не установлена") .. "\nКомиссия: −" .. packet.fee .. "\n\nЭто мнение игрока; оно может быть ошибочным."
	else
		body = "Проверочная стоимость: " .. money(packet.value) .. "\nТвоя оценка: " .. money(packet.quote) .. " · ошибка " .. packet.error .. "%\nПодлинность: " .. (if packet.genuine then "оригинал" else "реплика") .. "\nГонорар: +" .. packet.fee .. "   Репутация: " .. (if packet.rep >= 0 then "+" else "") .. packet.rep
			.. (if packet.bought then "\nВыкуп: −" .. money(packet.bought) .. " · вещь в коллекции" else "\nПредмет возвращён клиенту")
	end
	text(receipt, body, 16, C.ink, UDim2.fromOffset(29, 149), UDim2.fromOffset(451, 190)).TextYAlignment = Enum.TextYAlignment.Top
	button(receipt, "Принять", 27, 352, 454, 41, function() receipt:Destroy(); receipt = nil end, "primary")
	ping()
end

State.OnClientEvent:Connect(function(packet)
	if packet.kind == "snapshot" then
		data = packet; renderHUD(); if activePanel then renderPanel(true) end
	elseif packet.kind == "pulse" and data then
		data.queue = packet.queue
		if data.case and data.case.id == packet.caseId then data.case.patience = packet.patience; data.case.mood = packet.mood end
		queueText.Text = "Очередь " .. data.queue .. "/" .. data.capacity .. "   ·   " .. Config.BaseLevels[data.baseLevel].name
		if activePanel == "case" and bindings.patience and packet.caseId == caseId and packet.patience then
			bindings.patience.Size = UDim2.new(packet.patience, 0, 1, 0); bindings.patience.BackgroundColor3 = if packet.patience < 0.3 then C.red else C.mint
		end
	elseif packet.kind == "open" then activePanel = packet.panel; renderPanel()
	elseif packet.kind == "toast" then toast(packet.text, packet.tone)
	elseif packet.kind == "catalog" then catalog = packet.items
	elseif packet.kind == "roster" then rows = packet.rows; if rosterVisible then renderRoster() end
	elseif packet.kind == "leaveDesk" then if activePanel=="case" or activePanel=="peer" then activePanel=nil;window.Visible=false end
		casePane.Visible=false
	elseif packet.kind=="challengeUpdate" and data then
		local record=if data.peer and data.peer.id==packet.caseId then data.peer else data.case
		if record and record.id==packet.caseId then record.challenge=packet.challenge;record.busy=true;if activePanel=="case" or activePanel=="peer" then renderPanel(true)end end
	elseif packet.kind == "receipt" or packet.kind == "report" then receiptCard(packet)
	elseif packet.kind == "scan" then
		scanUntil = os.clock() + packet.seconds
		if scanLabel and caseId == packet.caseId then scanLabel.Text = Config.Tools[packet.tool].name .. " / исследование…" end
		if scanBar then scanBar.Size = UDim2.fromOffset(0, 2); TweenService:Create(scanBar, TweenInfo.new(packet.seconds, Enum.EasingStyle.Linear), { Size = UDim2.fromOffset(574, 2) }):Play() end
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Tab then
		rosterVisible = not rosterVisible; renderRoster()
	elseif input.KeyCode == Enum.KeyCode.F8 and data and data.admin then activePanel = "admin"; renderPanel()
	elseif input.KeyCode == Enum.KeyCode.B then emit("Open", { panel = "case" })
	elseif input.KeyCode == Enum.KeyCode.Escape and activePanel then activePanel = nil; window.Visible = false;casePane.Visible=false end
end)

local function resize()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local size = camera.ViewportSize
	windowScale.Scale = math.clamp(math.min((size.X - 22) / 980, (size.Y - 112) / 660), 0.25, 1)
	dockScale.Scale = math.clamp((size.X - 20) / 849, 0.25, 1)
	local compact = size.X < 760
	casePane.Size=UDim2.fromOffset(math.max(280,math.min(340,size.X-28)),math.clamp(if compact then size.Y*.48 else size.Y-190,180,550))
	brand.Visible = not compact; objective.Visible = not compact and not (data and data.seated)
	wallet.Size = UDim2.fromOffset(if compact then 224 else 268, 102)
	toastFrame.Size = UDim2.fromOffset(math.min(480, size.X - 20), 250)
	local toastScale = toastFrame:FindFirstChildOfClass("UIScale") or make("UIScale", {}, toastFrame)
	toastScale.Scale = math.clamp((size.X - 20) / 480, 0.25, 1)
	pendingFrame.Position = UDim2.new(0, 12, 1, if compact then -76 else -109)
	if not pendingFrame:FindFirstChildOfClass("UIScale") then make("UIScale", {}, pendingFrame) end
	pendingFrame:FindFirstChildOfClass("UIScale").Scale = if compact then 0.8 else 1
	homeButton.Position = UDim2.new(1, -18, 1, if compact then -70 else -96)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() resize(); if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end end)
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
RunService.RenderStepped:Connect(function(dt)
	for i=#animatedBadges,1,-1 do
		local badge=animatedBadges[i]
		if not badge.object.Parent then table.remove(animatedBadges,i);continue end
		if badge.object.Parent and (window.Visible or rosterVisible) then
			if badge.style=="gold"or badge.style=="frameSpin"then badge.object.Rotation=(badge.object.Rotation+dt*18)%360 end
			if badge.style=="bob"then badge.object.Position=UDim2.fromOffset(badge.x,badge.y+math.sin(os.clock()*2+(badge.phase or 0))*1.6)end
			if badge.gradient then badge.gradient.Offset=Vector2.new(math.sin(os.clock()*.5)*.16,0)end
		end
	end
	if viewportModel and viewportModel.Parent and viewportCamera and (window.Visible or casePane.Visible) then
		dragAngle += dt * 0.10
		local target = viewportTarget
		local radius = viewportSize * 1.9
		viewportCamera.CFrame = CFrame.lookAt(target + Vector3.new(math.sin(dragAngle)*math.cos(dragPitch)*radius,math.sin(dragPitch)*radius,math.cos(dragAngle)*math.cos(dragPitch)*radius), target)
	end
end)
resize(); emit("Hello")
task.delay(4, function() if not data then emit("Hello") end end)
task.delay(8, function() if data and data.stats.served == 0 then toast("Первый день: выбери профессию и сядь за свою стойку. Рабочее дело откроется само.") end end)

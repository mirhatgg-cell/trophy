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
local network = ReplicatedStorage:WaitForChild("Network")
local Action, State = network:WaitForChild("Action"), network:WaitForChild("State")

local C = { ink = Color3.fromRGB(23, 36, 39), deep = Color3.fromRGB(15, 25, 28), panel = Color3.fromRGB(34, 49, 51),
	paper = Color3.fromRGB(243, 239, 224), muted = Color3.fromRGB(163, 178, 172), mint = Color3.fromRGB(140, 208, 177),
	gold = Color3.fromRGB(216, 178, 108), copper = Color3.fromRGB(199, 139, 104), line = Color3.fromRGB(70, 87, 86), red = Color3.fromRGB(224, 132, 121) }
local FONT, BOLD, DISPLAY, NUM = Enum.Font.Gotham, Enum.Font.GothamBold, Enum.Font.Garamond, Enum.Font.Code
local data, catalog, rows = nil, {}, {}
local activePanel, caseMode, selectedInventory, adminId = nil, "npc", nil, "h01"
local caseId, auth, dragAngle, scanUntil = nil, "unknown", 0, 0
local bindings, connections = {}, {}
local animatedBadges = {}
local viewportModel, viewportCamera, viewportTarget, viewportSize
local window, content, pageTitle, pageSubtitle, quoteBox, offerBox, scanLabel, scanBar, receipt
local renderPanel, renderRoster, renderHUD

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
	SoundService:PlayLocalSound(sound); game:GetService("Debris"):AddItem(sound, 2)
end

-- A compact editorial HUD: a seal, engraved-looking rules, tabbed navigation and a paper dossier.
local brand = make("Frame", { BackgroundColor3 = C.deep, BackgroundTransparency = 0.08, BorderSizePixel = 0, Position = UDim2.fromOffset(18, 16), Size = UDim2.fromOffset(268, 76) }, gui)
corner(brand, 12); stroke(brand, C.gold, 0.55)
local seal = make("Frame", { BackgroundColor3 = C.ink, Position = UDim2.fromOffset(13, 13), Size = UDim2.fromOffset(50, 50) }, brand); corner(seal, 25); stroke(seal, C.gold, 0, 2)
text(seal, "П", 36, C.gold, UDim2.fromOffset(0, -2), UDim2.fromOffset(50, 50), DISPLAY).TextXAlignment = Enum.TextXAlignment.Center
text(brand, "П Р О Б А", 21, C.paper, UDim2.fromOffset(78, 9), UDim2.fromOffset(185, 30), BOLD)
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
	Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(730, 65) }, gui)
corner(dock, 13); stroke(dock, C.gold, 0.65)
local dockScale = make("UIScale", { Scale = 1 }, dock)
local dockItems = { {"01  Дело", "case"}, {"02  Коллекция", "inventory"}, {"03  Мастерская", "workshop"}, {"04  Профессия", "specialty"}, {"05  Титулы", "titles"}, {"?  Справка", "guide"} }
for i, entry in ipairs(dockItems) do button(dock, entry[1], 10 + (i - 1) * 119, 10, 112, 44, function() emit("Open", { panel = entry[2] }) end) end
local homeButton = button(gui, "⌂  К своему бюро", 0, 0, 175, 37, function() emit("Return") end)
homeButton.AnchorPoint = Vector2.new(1, 1); homeButton.Position = UDim2.new(1, -18, 1, -96)
local rosterButton = button(gui, "Оценщики  [TAB]", 0, 0, 175, 37, function() if activePanel == "roster" then window.Visible = false; activePanel = nil else activePanel = "roster"; renderPanel() end end)
rosterButton.AnchorPoint = Vector2.new(1, 0); rosterButton.Position = UDim2.new(1, -18, 0, 131)
local adminButton = button(gui, "Лаборатория  [F8]", 0, 0, 175, 32, function() activePanel = "admin"; renderPanel() end, "gold")
adminButton.AnchorPoint = Vector2.new(1, 0); adminButton.Position = UDim2.new(1, -18, 0, 178); adminButton.Visible = false

local toastFrame = make("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 18), Size = UDim2.fromOffset(480, 250) }, gui)
local toastLayout = make("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center }, toastFrame)
local function toast(value, tone)
	local frame = make("Frame", { BackgroundColor3 = C.deep, BackgroundTransparency = 0.02, BorderSizePixel = 0, Size = UDim2.fromOffset(470, 63) }, toastFrame)
	corner(frame, 10); stroke(frame, if tone == "bad" then C.red elseif tone == "good" then C.mint else C.gold, 0.25)
	text(frame, value, 13, C.paper, UDim2.fromOffset(17, 8), UDim2.fromOffset(436, 47))
	task.delay(5, function() if frame.Parent then TweenService:Create(frame, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play(); task.wait(0.25); frame:Destroy() end end)
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

local function clearContent()
	for _, c in ipairs(connections) do c:Disconnect() end; connections = {}
	content:ClearAllChildren(); bindings = {}; viewportModel = nil; viewportCamera = nil; quoteBox = nil; offerBox = nil; scanLabel = nil; scanBar = nil
	animatedBadges = {}
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
local function itemViewport(parent, itemId, x, y, w, h)
	local frame = make("ViewportFrame", { BackgroundColor3 = C.deep, BorderSizePixel = 0, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
		Ambient = Color3.fromRGB(172, 172, 153), LightColor = Color3.fromRGB(255, 237, 195), LightDirection = Vector3.new(-1, -1, -1), Active = true }, parent)
	corner(frame, 12); stroke(frame)
	local world = make("WorldModel", {}, frame)
	local source = ReplicatedStorage.ItemModels:FindFirstChild(itemId)
	if source then
		viewportModel = source:Clone(); viewportModel:PivotTo(CFrame.new()); viewportModel.Parent = world
		local cf, bounds = viewportModel:GetBoundingBox(); viewportTarget = cf.Position; viewportSize = math.max(bounds.X, bounds.Y, bounds.Z, 1.8)
		viewportCamera = make("Camera", { FieldOfView = 37 }, frame); frame.CurrentCamera = viewportCamera
	end
	local dragging, lastX = false, 0
	table.insert(connections, frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; lastX = input.Position.X end
	end))
	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then dragAngle += (input.Position.X - lastX) * 0.012; lastX = input.Position.X end
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
	local record = currentCase()
	heading(if caseMode == "peer" then "Независимая экспертиза" else "Рабочее дело", "Осмотри вещь → собери доказательства → выдай заключение или предложи выкуп")
	if not record then
		text(content, if data and data.plot then "Стол готов. Ждём посетителя." else "Ожидаем свободное бюро.", 32, C.paper, UDim2.fromOffset(40, 92), UDim2.fromOffset(800, 70), DISPLAY)
		text(content, "Клиенты сами идут к стойке. Пока можешь выбрать специальность, осмотреть мастерскую или прогуляться по улице.\n\nДля оценки нужно находиться у собственного рабочего стола.", 17, C.muted, UDim2.fromOffset(42, 183), UDim2.fromOffset(770, 120))
		button(content, "Выбрать специальность", 42, 335, 254, 45, function() activePanel = "specialty"; renderPanel() end, "primary")
		button(content, "К своему бюро", 309, 335, 210, 45, function() emit("Return") end)
		caseId = nil; return
	end
	if caseId ~= record.id then auth = "unknown"; caseId = record.id; dragAngle = 0 end
	local item = record.item
	itemViewport(content, item.id, 0, 0, 313, 310)
	text(content, "ВЕЩЬ / " .. string.upper(item.id), 10, C.gold, UDim2.fromOffset(17, 16), UDim2.fromOffset(280, 17), NUM)
	text(content, item.name, 27, C.paper, UDim2.fromOffset(0, 319), UDim2.fromOffset(310, 66), DISPLAY)
	text(content, item.material .. " · " .. item.era .. "\n" .. item.condition, 12, C.muted, UDim2.fromOffset(0, 390), UDim2.fromOffset(310, 54))
	text(content, "«" .. item.story .. "»", 12, C.paper, UDim2.fromOffset(0, 453), UDim2.fromOffset(310, 73))
	text(content, record.customer, 15, C.paper, UDim2.fromOffset(334, 0), UDim2.fromOffset(570, 25), BOLD)
	local patience = make("Frame", { BackgroundColor3 = C.deep, BorderSizePixel = 0, Position = UDim2.fromOffset(334, 35), Size = UDim2.fromOffset(574, 5) }, content)
	bindings.patience = make("Frame", { BackgroundColor3 = C.mint, BorderSizePixel = 0, Size = UDim2.new(record.patience, 0, 1, 0) }, patience)
	bindings.patienceText = text(content, if caseMode == "peer" then "Комиссия 40 монет · предмет остаётся у владельца" else "Терпение клиента · очередь продолжает двигаться", 10, C.muted, UDim2.fromOffset(334, 44), UDim2.fromOffset(570, 18))
	for i, toolId in ipairs(Config.ToolsOrder) do
		local done = record.tests[toolId] ~= nil
		local owned = (data.equipment[toolId] or 0) > 0
		local b = button(content, (if done then "✓ " elseif not owned then "◇ " else "") .. Config.Tools[toolId].name, 334 + ((i - 1) % 3) * 195, 73 + math.floor((i - 1) / 3) * 42, 185, 35,
			function() emit("Inspect", { caseId = record.id, tool = toolId }) end, if done then "gold" else nil)
		if not owned then b.TextColor3 = C.muted end
	end
	scanLabel = text(content, "", 11, C.mint, UDim2.fromOffset(334, 158), UDim2.fromOffset(574, 19), NUM)
	scanBar = make("Frame", { BackgroundColor3 = C.mint, BorderSizePixel = 0, Position = UDim2.fromOffset(334, 180), Size = UDim2.fromOffset(0, 2) }, content)
	local notes = scroll(content, 334, 190, 584, 133)
	local notesText = text(notes, testNotes(record), 12, C.paper, UDim2.new(), UDim2.new(1, -14, 0, 0))
	notesText.AutomaticSize = Enum.AutomaticSize.Y; notesText.TextYAlignment = Enum.TextYAlignment.Top
	line(content, 334, 332, 574)
	text(content, "Ориентир: " .. money(item.estimate.low) .. "—" .. money(item.estimate.high) .. "   ·   точность " .. item.estimate.confidence .. "%", 12, C.gold, UDim2.fromOffset(334, 339), UDim2.fromOffset(575, 25), NUM)
	quoteBox = field(content, "Твоя оценка", 334, 373, 230)
	local quoteSaved = bindings.quoteSaved
	if quoteSaved then quoteBox.Text = quoteSaved end
	text(content, "ПОДЛИННОСТЬ", 9, C.muted, UDim2.fromOffset(578, 370), UDim2.fromOffset(330, 16), BOLD)
	local authButtons = {}
	local function updateAuth()
		for key, b in pairs(authButtons) do b.TextColor3 = if key == auth then C.deep else C.paper; b.BackgroundColor3 = if key == auth then C.mint else C.panel end
	end
	for i, entry in ipairs({ {"genuine", "Оригинал"}, {"replica", "Реплика"}, {"unknown", "Неясно"} }) do
		authButtons[entry[1]] = button(content, entry[2], 578 + (i - 1) * 113, 391, 106, 30, function() auth = entry[1]; updateAuth() end)
	end
	updateAuth()
	button(content, if caseMode == "peer" then "Выдать заключение · +40" else "Завершить оценку", 334, 438, 275, 44, function() local p = packet(record); if p then emit("Complete", p) end end, "primary")
	if caseMode == "npc" then
		offerBox = field(content, "Выкуп за…", 624, 438, 165)
		button(content, "Торг", 800, 438, 110, 44, function()
			local p = packet(record); local amount = tonumber(offerBox.Text)
			if p and amount then p.amount = amount; emit("Offer", p) elseif p then toast("Введи сумму выкупа.", "bad") end
		end, "gold")
		text(content, if record.counter then "Клиент просит " .. money(record.counter) .. " · попытка " .. record.negotiations .. "/3" else "Выкуп оплачиваешь ты. После сделки предмет попадёт в коллекцию.", 10, C.muted, UDim2.fromOffset(334, 492), UDim2.fromOffset(574, 29))
	else
		button(content, "Отменить экспертизу", 624, 438, 285, 44, function() emit("PeerDecline", { id = record.id }) end)
	end
	if record.busy then scanLabel.Text = "Исследование выполняется…" end
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
		button(row, if active then "Основная" elseif data.stats.served == 0 then "Выбрать бесплатно" else "Сменить · 200", 700, 15, 218, 42, function() emit("Specialty", { spec = specId }) end, if active then "gold" else nil)
	end
	local level = Domain.specLevel(data.specXP[data.specialty])
	button(content, if level < 10 then "Обучение до ур. " .. (level + 1) .. " · " .. money(level * 220) else "Квалификация максимальна", 0, 437, 402, 47, function() emit("Train") end, "primary")
	text(content, "Практика тоже даёт опыт. При смене профессии опыт сохраняется. В чужой области даже хорошие приборы оставляют заметную неопределённость.", 12, C.muted, UDim2.fromOffset(423, 435), UDim2.fromOffset(506, 66))
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
	itemViewport(content, selected.id, 418, 0, 518, 241)
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

renderRoster = function()
	heading("Оценщики квартала", "Рамки, фоны и титулы · TAB закрывает список · в прототипе шесть собственных бюро")
	for i, row in ipairs(rows) do
		local y = (i - 1) * 82
		local card = make("Frame", { BackgroundColor3 = C.panel, BorderSizePixel = 0, Position = UDim2.fromOffset(0, y), Size = UDim2.fromOffset(936, 73) }, content); corner(card, 9)
		text(card, string.format("%02d", i), 25, C.gold, UDim2.fromOffset(17, 15), UDim2.fromOffset(43, 39), NUM)
		text(card, row.name, 16, C.paper, UDim2.fromOffset(78, 8), UDim2.fromOffset(280, 27), BOLD)
		text(card, "@" .. row.username .. " · " .. row.plot, 10, C.muted, UDim2.fromOffset(78, 39), UDim2.fromOffset(290, 21))
		titleBadge(card, titleDefinition(row.title), 371, 18, 292, 37)
		text(card, Config.Specs[row.specialty].name .. " " .. row.level .. "\nРепутация " .. row.reputation, 12, C.paper, UDim2.fromOffset(696, 13), UDim2.fromOffset(220, 49))
	end
end

local function buildGuide()
	heading("Путеводитель оценщика", "ПРОБА / первый рабочий день")
	local guide = scroll(content, 0, 0, 936, 524)
	local entries = {
		{"01 / ТВОЁ БЮРО", "При входе сервер занимает свободный участок. Ты появляешься перед собственной лавкой. Кнопка «К своему бюро» возвращает к ней. У стойки нажми E или открой «Дело»."},
		{"02 / ОСМОТР И ЗАКЛЮЧЕНИЕ", "Выбери профессию. Исследуй вещь доступными приборами, вращай модель мышью или пальцем, читай записи. Назови стоимость и выбери: оригинал, реплика или неясно. Ориентир — оценка твоего персонажа, он может ошибаться."},
		{"03 / ДЕНЬГИ И РЕПУТАЦИЯ", "Гонорар зависит от сложности вещи, точности, подлинности, терпения клиента и уровня бюро. Точное заключение даёт репутацию; серьёзная ошибка и ушедшие клиенты её снижают. Чем выше репутация, тем чаще гости и дороже предметы."},
		{"04 / ОЖИДАНИЕ И ЭМОЦИИ", "Очередь и время снижают терпение. Эмодзи над гостем показывают размышление, вздох, грусть, злость, радость и смех. Слишком низкая цена раздражает. Слишком щедрый выкуп радует продавца за твой счёт."},
		{"05 / ВЫКУП И ДРУГИЕ ИГРОКИ", "Чтобы выкупить вещь, заполни оценку, подлинность и предложение. Допускается три раунда торга. Из коллекции возьми предмет в руки, подойди к чужой стойке и нажми E. Владелец принимает запрос, исследует вещь и получает 40 монет за заключение."},
		{"06 / ПРОДАЖА И ПРОГРЕСС", "Скупщик у южных ворот платит 72% рыночной стоимости: это ликвидность, а не гарантированная прибыль. Развивай инструменты, одну активную профессию и базу. В прототипе 100 предметов, 3 здания, 5 профессий, 5 приборов и 6 титулов."},
		{"07 / СОХРАНЕНИЕ И ТЕСТИРОВАНИЕ", "В Studio используются отдельные тестовые данные. В опубликованной игре прогресс хранится в DataStore; при недоступности сохранения HUD явно показывает режим сеанса. F8 открывает лабораторию только тестировщикам Studio и разрешённым администраторам."},
	}
	for i, entry in ipairs(entries) do
		text(guide, entry[1], 13, C.gold, UDim2.fromOffset(14, (i - 1) * 137), UDim2.fromOffset(890, 24), BOLD)
		text(guide, entry[2], 15, C.paper, UDim2.fromOffset(14, (i - 1) * 137 + 33), UDim2.fromOffset(890, 93)).TextYAlignment = Enum.TextYAlignment.Top
	end
end

local function buildAdmin()
	heading("Лаборатория прототипа", "Доступ проверяет сервер · команды изменяют только собственный профиль · в Studio сохранения изолированы")
	if not data.admin then text(content, "Доступ закрыт", 28, C.red); return end
	local commands = { {"+25 000 монет", "funds"}, {"Репутация 75", "reputation"}, {"Все приборы III", "tools"}, {"Следующая база 1→2→3", "base"}, {"Сменить настроение гостя", "emotions"}, {"Открыть все титулы", "titles"} }
	for i, entry in ipairs(commands) do button(content, entry[1], ((i - 1) % 3) * 313, math.floor((i - 1) / 3) * 52, 299, 42, function() emit("Admin", { command = entry[2] }) end, "gold") end
	text(content, "КАТАЛОГ / ВСЕ 100 ПРЕДМЕТОВ", 12, C.gold, UDim2.fromOffset(0, 118), UDim2.fromOffset(900, 25), BOLD)
	local list = scroll(content, 0, 153, 551, 370)
	for i, def in ipairs(catalog) do
		button(list, def.id .. " · " .. def.name, 0, (i - 1) * 38, 537, 32, function() adminId = def.id; renderPanel() end, if adminId == def.id then "gold" else nil)
	end
	itemViewport(content, adminId, 571, 153, 365, 219)
	button(content, "Клиент с этой вещью", 571, 389, 365, 44, function() emit("Admin", { command = "spawn", id = adminId }) end, "primary")
	button(content, "Добавить в коллекцию", 571, 447, 365, 44, function() emit("Admin", { command = "item", id = adminId }) end)
end

renderPanel = function(preserve)
	if not activePanel then return end
	if not data and activePanel ~= "guide" then toast("Загружаем профиль и участок…"); return end
	local oldQuote = quoteBox and quoteBox.Text; local oldOffer = offerBox and offerBox.Text; local oldCase = caseId
	clearContent(); window.Visible = true
	if activePanel == "case" or activePanel == "peer" then
		caseMode = if activePanel == "peer" then "peer" else "npc"
		buildCase()
		if preserve and caseId == oldCase then if quoteBox and oldQuote then quoteBox.Text = oldQuote end; if offerBox and oldOffer then offerBox.Text = oldOffer end end
	elseif activePanel == "workshop" then buildWorkshop()
	elseif activePanel == "specialty" then buildSpecialty()
	elseif activePanel == "inventory" then buildInventory()
	elseif activePanel == "titles" then buildTitles()
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
	walletValue.Text = money(data.cash) .. "  ¤"
	repText.Text = "Репутация " .. data.reputation .. " / 100   ·   " .. Config.Specs[data.specialty].name
	TweenService:Create(repFill, TweenInfo.new(0.3), { Size = UDim2.new(data.reputation / 100, 0, 1, 0) }):Play()
	saveText.Text = if data.saveMode == "studio" then "STUDIO / тестовый профиль" elseif data.saveMode == "cloud" then "ОБЛАКО / автосохранение" elseif data.saveMode == "session" then "СЕАНС / без облачного сохранения" else "Загрузка…"
	saveText.TextColor3 = if data.saveMode == "session" then C.red else C.muted
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
	elseif packet.kind == "roster" then rows = packet.rows; if activePanel == "roster" then renderPanel() end
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
		if activePanel == "roster" then activePanel = nil; window.Visible = false else activePanel = "roster"; renderPanel() end
	elseif input.KeyCode == Enum.KeyCode.F8 and data and data.admin then activePanel = "admin"; renderPanel()
	elseif input.KeyCode == Enum.KeyCode.B then emit("Open", { panel = "case" })
	elseif input.KeyCode == Enum.KeyCode.Escape and activePanel then activePanel = nil; window.Visible = false end
end)

local function resize()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local size = camera.ViewportSize
	windowScale.Scale = math.clamp(math.min((size.X - 22) / 980, (size.Y - 112) / 660), 0.25, 1)
	dockScale.Scale = math.clamp((size.X - 20) / 730, 0.25, 1)
	local compact = size.X < 760
	brand.Visible = not compact; objective.Visible = not compact
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
	for _,badge in ipairs(animatedBadges) do
		if badge.object.Parent and window.Visible then
			if badge.style=="gold" then badge.object.Rotation=(badge.object.Rotation+dt*9)%360 end
			badge.gradient.Offset=Vector2.new(math.sin(os.clock()*.5)*.16,0)
		end
	end
	if viewportModel and viewportModel.Parent and viewportCamera and window.Visible then
		dragAngle += dt * 0.10
		local target = viewportTarget
		local radius = viewportSize * 1.9
		viewportCamera.CFrame = CFrame.lookAt(target + Vector3.new(math.sin(dragAngle) * radius, viewportSize * 0.85, math.cos(dragAngle) * radius), target)
	end
end)
resize(); emit("Hello")
task.delay(4, function() if not data then emit("Hello") end end)
task.delay(8, function() if data and data.stats.served == 0 then toast("Первый день: выбери профессию, затем подойди к стойке своего бюро. E — взаимодействие, B — дело.") end end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

local Config = require(ReplicatedStorage.Shared.Config)
local Domain = require(ReplicatedStorage.Shared.Domain)
local Challenges = require(ReplicatedStorage.Shared.Challenges)
local Appearance = require(ReplicatedStorage.Shared.Appearance)
local Rarity = require(ReplicatedStorage.Shared.Rarity)
local Audio = require(script.Parent.Audio)
Audio.Init()
local Decor=require(ReplicatedStorage.Shared.Decor)
local Decorations=require(script.Parent.Decorations)
local Commerce=require(script.Parent.Commerce)
local Tutorial=require(ReplicatedStorage.Shared.Tutorial)
local Timing=require(ReplicatedStorage.Shared.CustomerTiming)
local Presentation=require(ReplicatedStorage.Shared.Presentation)
local Identity=require(ReplicatedStorage.Shared.Identity)
local Workstation=require(script.Parent.Workstation)
local Catalog = require(script.Parent.Catalog)
local Profiles = require(script.Parent.Profiles)
local Customers = require(script.Parent.Customers)
local Action, State = ReplicatedStorage.Network.Action, ReplicatedStorage.Network.State
local index = {}
for _, def in ipairs(Catalog) do index[def.id] = def end

local sessions, plots, requests, doors, buckets = {}, {}, {}, {}, {}
local sendSnapshot, updateDisplay, rebuild, roster, syncCollection
local function applyDecor(player)
	local s,p=sessions[player],Profiles.loaded[player]
	if s and s.plot and p then Decorations.Apply(s.plot,p)end
end
local function message(player, text, tone)
	if player.Parent then State:FireClient(player, { kind = "toast", text = text, tone = tone or "info" }) end
end
local function open(player, panel)
	if player.Parent then State:FireClient(player, { kind = "open", panel = panel }) end
end
local function isAdmin(player)
	return RunService:IsStudio() or (game.CreatorType == Enum.CreatorType.User and game.CreatorId == player.UserId)
		or table.find(Config.AdminUserIds, player.UserId) ~= nil
end
local function near(player, point, radius)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return root ~= nil and (root.Position - point).Magnitude <= radius
end
local function atDesk(player, session)
	return session and session.plot and near(player, (session.plot.Anchor.CFrame * CFrame.new(0, 3, 7)).Position, 27)
end
local function working(player, session)
	if not atDesk(player, session) then return false end
	local building = session.plot:FindFirstChild("Building")
	local seat = building and building:FindFirstChild("AppraiserSeat", true)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	return seat ~= nil and humanoid ~= nil and seat.Occupant == humanoid
end
local function unseat(player)
	local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local seat=humanoid.SeatPart;humanoid.Sit=false
	local weld=seat and seat:FindFirstChild("SeatWeld");if weld then weld:Destroy()end
end
local function availableCash(player)
	local p = Profiles.loaded[player]
	if not p then return 0 end
	local reserved = 0
	for _, request in pairs(requests) do if request.visitor == player then reserved += Config.PeerFee end end
	return p.cash - reserved
end
local function inventoryItem(profile, uid)
	for i, item in ipairs(profile.inventory) do if item.uid == uid then return item, i end end
	return nil
end
local function lockedItem(player, uid)
	for _, r in pairs(requests) do if r.visitor == player and r.itemUid == uid then return true end end
	return false
end
local function conditionText(value)
	return if value >= 0.85 then "Отличная сохранность" elseif value >= 0.65 then "Есть следы использования" elseif value >= 0.48 then "Заметный износ" else "Нуждается в реставрации"
end
local function publicItem(player, item, tests)
	local def = index[item.id]
	local low, high, confidence = Domain.estimate(Profiles.loaded[player], def, item, tests or {})
	return { id = item.id, uid = item.uid, name = def.name, spec = def.spec, material = def.material, era = def.era,
		conditionScore=item.condition,visualSeed=item.visualSeed or 1,mutation=item.mutation or "none",uniqueness=item.uniqueness or 0,
		surfaceTone=item.surfaceTone or 0,repair=if type(item.repair)=="boolean"then item.repair else item.condition<.65,
		story = item.story or def.story, condition = conditionText(item.condition), estimate = { low = low, high = high, confidence = confidence },
		reports = item.reports or {}, paid = item.paid or 0 }
end
local function casePacket(player, record)
	if not record then return nil end
	local tests = {}
	for key, result in pairs(record.tests) do tests[key] = { text = result.text, relevant = result.relevant } end
	local timing=Timing.Public(record)
	if record.accepted and record.expires then timing.seconds=math.max(0,math.ceil(record.expires-os.clock()));timing.paused=record.busy~=nil end
	return { id = record.id, item = publicItem(player, record.item, record.tests), customer = record.name,
		patience = record.patience, mood = record.mood, tests = tests, negotiations = record.negotiations, counter = record.counter, busy = record.busy ~= nil,
		timing=timing,
		challenge = record.busy and Challenges.Public(record.busy) }
end
local function avatarStatus(player)
	if not isAdmin(player)then return end
	local s=Customers.sessions[player];local r=s and s.queue[1];local m=r and r.model
	if not m then return end
	return{name=r.name,status=m:GetAttribute("ProbaAnimationStatus")or"loading",clip=m:GetAttribute("ProbaPlayingClip")or 0,
		walk=m:GetAttribute("ProbaWalkRequested")or 0,error=m:GetAttribute("ProbaAnimationError")}
end

sendSnapshot = function(player)
	local s, p = sessions[player], Profiles.loaded[player]
	if not s or not p or not player.Parent then return end
	local inv = {}
	for _, item in ipairs(p.inventory) do table.insert(inv, publicItem(player, item, {})) end
	local customerSession = Customers.sessions[player]
	local pending, peer
	for _, request in pairs(requests) do
		if request.appraiser == player then
			if request.accepted then
				peer = casePacket(player, request)
				peer.visitor = request.visitor.DisplayName; peer.fee = Config.PeerFee
			else pending = { id = request.id, name = request.visitor.DisplayName, item = index[request.item.id].name, fee = Config.PeerFee } end
		end
	end
	State:FireClient(player, { kind = "snapshot", cash = p.cash, available = availableCash(player), reputation = p.reputation,
		baseLevel = p.baseLevel, specialty = p.specialty, specXP = p.specXP, equipment = p.equipment, stats = p.stats,
		ownedDecor=p.ownedDecor,equippedDecor=p.equippedDecor,tutorial=Tutorial.State(p),
		nametag=p.nametag,ownedNametags=p.ownedNametags,
		avatarStatus=avatarStatus(player),
		timersPaused=customerSession and customerSession.paused==true,
		title = p.title, unlocked = Domain.unlockedTitles(p), seenCount = #p.seen, inventory = inv, heldUid = s.heldUid,
		plot = if s.plot then s.plot.Name else nil, saveMode = s.saveMode, queue = if customerSession then #customerSession.queue else 0,
		capacity = Config.BaseLevels[p.baseLevel].capacity, seated = working(player,s), case = casePacket(player, Customers.Active(player)), pending = pending, peer = peer, admin = isAdmin(player) })
end

roster = function()
	local rows = {}
	for player, s in pairs(sessions) do
		local p = Profiles.loaded[player]
		if p then table.insert(rows, { userId = player.UserId, name = player.DisplayName, username = player.Name, title = p.title,nametag=p.nametag,
			frame=p.equippedDecor.frame or "frame_plain",card=p.equippedDecor.card or "card_paper",
			reputation = p.reputation, specialty = p.specialty, level = Domain.specLevel(p.specXP[p.specialty]), plot = if s.plot then s.plot.Name else "Ожидает участок" }) end
	end
	table.sort(rows, function(a, b) return a.reputation > b.reputation end)
	State:FireAllClients({ kind = "roster", rows = rows })
end

local function clearHeld(player)
	local s = sessions[player]
	if s then s.heldUid = nil end
	for _, container in ipairs({ player.Character, player:FindFirstChildOfClass("Backpack") }) do
		if container then for _, child in ipairs(container:GetChildren()) do if child:IsA("Tool") and child:GetAttribute("ProbaItem") then child:Destroy() end end end
	end
end
local function carry(player, item)
	clearHeld(player)
	if not player.Character then return end
	local model = ReplicatedStorage.ItemModels[item.id]:Clone()
	model:ScaleTo(0.5)
	local tool = Instance.new("Tool"); tool.Name = index[item.id].name; tool.CanBeDropped = false; tool:SetAttribute("ProbaItem", true)
	local handle = Instance.new("Part"); handle.Name = "Handle"; handle.Size = Vector3.new(0.25, 0.25, 0.25); handle.Transparency = 1
	handle.CanCollide = false; handle.CanTouch = false; handle.Massless = true; handle.Parent = tool
	model:PivotTo(CFrame.new(0, 0.2, 0))
	Appearance.Apply(model,item)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false; part.CanCollide = false; part.CanTouch = false; part.Massless = true
			local weld = Instance.new("WeldConstraint"); weld.Part0 = handle; weld.Part1 = part; weld.Parent = handle
		end
	end
	model.Parent = tool
	tool.Grip = CFrame.new(0, -0.35, -0.5) * CFrame.Angles(0, math.rad(90), 0)
	tool.Parent = player.Backpack
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid:EquipTool(tool) end
	sessions[player].heldUid = item.uid
	Tutorial.Mark(Profiles.loaded[player],"carried")
	if tool.Equipped then tool.Equipped:Connect(function()if sessions[player]then sessions[player].heldUid=item.uid;syncCollection(player)end end)end
	if tool.Unequipped then tool.Unequipped:Connect(function()if sessions[player]and sessions[player].heldUid==item.uid then sessions[player].heldUid=nil;syncCollection(player)end end)end
	syncCollection(player)
end

syncCollection=function(player)
	local s,p=sessions[player],Profiles.loaded[player]
	if not s or not p or not s.plot then return end
	local building=s.plot:FindFirstChild("Building");if not building then return end
	local slots={}
	for _,part in ipairs(building:GetDescendants())do if part:IsA("BasePart")and part.Name:match("^CollectionSlot_%d+$")then table.insert(slots,part)end end
	table.sort(slots,function(a,b)return a.Name<b.Name end)
	local folder=s.plot:FindFirstChild("OwnedCollection")
	if not folder then folder=Instance.new("Folder");folder.Name="OwnedCollection";folder.Parent=s.plot end
	local kept={}
	for i,item in ipairs(p.inventory)do
		local slot=slots[i]
		if not slot or s.heldUid==item.uid then continue end
		local name="Owned_"..item.uid
		local key=table.concat({p.baseLevel,slot.Name,item.id,item.mutation or "none",item.uniqueness or 0,item.visualSeed or 1,item.condition,item.surfaceTone or 0,tostring(item.repair)},"|")
		kept[name]=true
		local previous=folder:FindFirstChild(name)
		if previous and previous:GetAttribute("VisualKey")==key then continue end
		if previous then previous:Destroy()end
		local model=ReplicatedStorage.ItemModels[item.id]:Clone();model.Name=name;model:SetAttribute("VisualKey",key)
		model:SetAttribute("OwnedUid",item.uid);model:SetAttribute("OwnerUserId",player.UserId)
		model.Parent=folder
		Presentation.Place(model,slot.CFrame,1.9,1.55)
		for _,part in ipairs(model:GetDescendants())do if part:IsA("BasePart")then part.Anchored=true;part.CanCollide=false;part.CanTouch=false end end
		local styled,err=pcall(Appearance.Apply,model,item)
		if not styled then warn("[PROBA] Collection appearance",item.id,err)end
		local view=Instance.new("ProximityPrompt");view.Name="CollectionInspect";view.ActionText="Рассмотреть"
		view.ObjectText=index[item.id].name;view.RequiresLineOfSight=false;view.MaxActivationDistance=11
		view.KeyboardKeyCode=Enum.KeyCode.E;view.Parent=model.PrimaryPart
		view.Triggered:Connect(function(visitor)
			if not Profiles.loaded[visitor]or not near(visitor,slot.Position,14)then return end
			State:FireClient(visitor,{kind="exhibit",item=publicItem(visitor,item,{}),owner=player.DisplayName,owned=visitor==player})
		end)
		local interaction=Instance.new("ProximityPrompt");interaction.Name="CollectionPickup";interaction.ActionText="Взять в руки"
		interaction.ObjectText=index[item.id].name.." · "..Rarity.Caption(item);interaction.RequiresLineOfSight=false
		interaction.MaxActivationDistance=12;interaction.KeyboardKeyCode=Enum.KeyCode.F;interaction.HoldDuration=.2;interaction.Parent=model.PrimaryPart
		interaction.Triggered:Connect(function(visitor)
			if visitor~=player or not Profiles.loaded[player]or not near(player,slot.Position,14)then return end
			local owned=inventoryItem(Profiles.loaded[player],item.uid)
			if owned then carry(player,owned);sendSnapshot(player)end
		end)
	end
	for _,model in ipairs(folder:GetChildren())do if not kept[model.Name]then model:Destroy()end end
end

updateDisplay = function(player,force)
	local s = sessions[player]
	if not s or not s.plot then return end
	local old = s.plot:FindFirstChild("CurrentItem")
	local record = Customers.Active(player)
	for _, request in pairs(requests) do if request.appraiser == player and request.accepted then record = request; break end end
	if old and record and old:GetAttribute("CaseId")==record.id and not force then return end
	Workstation.Stop(player)
	if old then old:Destroy()end
	if not record then return end
	local model = ReplicatedStorage.ItemModels[record.item.id]:Clone(); model.Name = "CurrentItem"; model:ScaleTo(0.8)
	model:PivotTo(s.plot.Anchor.CFrame * CFrame.new(0, 5.05, 4))
	Appearance.Apply(model,record.item)
	model:SetAttribute("CaseId",record.id)
	for _, part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false; part.CanTouch = false end end
	model.Parent = s.plot
end

local function cancelRequest(id, reason)
	local request = requests[id]
	if not request then return end
	requests[id] = nil
	message(request.visitor, reason or "Экспертиза отменена. Комиссия не списана.")
	if request.appraiser.Parent then message(request.appraiser, "Запрос на экспертизу закрыт."); updateDisplay(request.appraiser); sendSnapshot(request.appraiser) end
	if request.visitor.Parent then sendSnapshot(request.visitor) end
end

local function requestPeer(visitor, owner)
	local s, p = sessions[visitor], Profiles.loaded[visitor]
	if not s or not p or not s.heldUid then message(visitor, "Сначала возьми купленный предмет из коллекции в руки."); return end
	local item = inventoryItem(p, s.heldUid)
	if not item then return end
	for _, request in pairs(requests) do
		if request.appraiser == owner then message(visitor, "Этот оценщик уже получил другой запрос."); return end
		if request.visitor == visitor then message(visitor, "Сначала заверши предыдущую экспертизу."); return end
	end
	if availableCash(visitor) < Config.PeerFee then message(visitor, "Для экспертизы нужно 40 монет.", "bad"); return end
	local sOwner = sessions[owner]
	if not sOwner or not atDesk(visitor, sOwner) then return end
	if item.lastAppraiser == owner.UserId and os.time() - (item.lastReportAt or 0) < 300 then message(visitor, "Этот специалист уже оценивал вещь. Повторная оценка будет доступна через пять минут."); return end
	local id = HttpService:GenerateGUID(false)
	requests[id] = { id = id, visitor = visitor, appraiser = owner, itemUid = item.uid, item = item,
		name = visitor.DisplayName, tests = {}, patience = 1, mood = "neutral", negotiations = 0, accepted = false, expires = os.clock() + 50 }
	message(visitor, "Запрос отправлен. 40 монет зарезервированы до ответа.")
	message(owner, visitor.DisplayName .. " принёс предмет на экспертизу. Открой входящий запрос.")
	sendSnapshot(visitor); sendSnapshot(owner)
end

local function applyEquipment(player)
	local s, p = sessions[player], Profiles.loaded[player]
	if not s or not s.plot or not p then return end
	local building = s.plot:FindFirstChild("Building")
	if not building then return end
	for toolId, rank in pairs(p.equipment) do
		local model = building:FindFirstChild("Tool_" .. toolId, true)
		if model then
			for _, obj in ipairs(model:GetDescendants()) do
				if obj:IsA("BasePart") then
					local original = obj:GetAttribute("OriginalAlpha")
					if original == nil then original = obj.Transparency; obj:SetAttribute("OriginalAlpha", original) end
					obj.Transparency = if rank > 0 then original else 1
					obj.CanCollide = false
				elseif obj:IsA("Light") then obj.Enabled = rank > 0 end
			end
		end
	end
end

rebuild = function(player)
	local s, p = sessions[player], Profiles.loaded[player]
	if not s or not s.plot or not p then return end
	local old = s.plot:FindFirstChild("Building"); if old then old:Destroy() end
	local building = ServerStorage.Buildings["Level" .. p.baseLevel]:Clone(); building.Name = "Building"
	building:PivotTo(s.plot.Anchor.CFrame); building.Parent = s.plot
	for _, object in ipairs(building:GetDescendants()) do
		if object:IsA("TextLabel") and object.Name == "OwnerName" then object.Text = string.upper(player.DisplayName) .. " · ОЦЕНЩИК" end
		if object:IsA("TextLabel") and object.Name == "PlotNumber" then object.Text = "БЮРО / " .. string.sub(s.plot.Name, -2) end
	end
	local prompt = building:FindFirstChild("AppraisalPrompt", true)
	if prompt then
		prompt.Triggered:Connect(function(visitor)
			if visitor == player then message(player, "Сядь в кресло за стойкой — рабочее дело откроется автоматически.") else requestPeer(visitor, player) end
		end)
	end
	local seat = building:FindFirstChild("AppraiserSeat", true)
	if seat then
		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			local occupant = seat.Occupant
			if occupant and occupant.Parent ~= player.Character then occupant.Sit = false; return end
			if occupant and Profiles.loaded[player]then Tutorial.Mark(Profiles.loaded[player],"seated")end
			if not occupant then
				Workstation.Stop(player)
				local record=Customers.Active(player);if record then record.busy=nil end
				for _,request in pairs(requests)do if request.appraiser==player then request.busy=nil end end
			end
			sendSnapshot(player)
			if occupant then open(player,"case") else State:FireClient(player,{kind="leaveDesk"}) end
		end)
	end
	local registry = building:FindFirstChild("RegistryPrompt", true)
	if registry then registry.Triggered:Connect(function(visitor) if visitor == player then sendSnapshot(player); open(player, "workshop") else message(visitor, "Это бюро " .. player.DisplayName) end end) end
	for _, door in ipairs(building:GetChildren()) do
		if door.Name == "DoorAssembly" then
			doors[door] = { left = door.Left.CFrame, right = door.Right.CFrame, open = false, tweening = false }
		end
	end
	applyEquipment(player); updateDisplay(player);syncCollection(player);applyDecor(player)
end

local function registerSeen(profile, id)
	if not table.find(profile.seen, id) then table.insert(profile.seen, id) end
end
local function reward(player, record, quote, auth, purchase)
	local p = Profiles.loaded[player]
	local def = index[record.item.id]
	local outcome = Domain.verdict(def, record.item, quote, auth, record.patience, Config.BaseLevels[p.baseLevel].fee)
	p.cash = Domain.money(p.cash + outcome.fee - (purchase or 0))
	p.reputation = math.clamp(p.reputation + outcome.rep, 0, 100)
	p.stats.served += 1
	Tutorial.Mark(p,"verdict")
	if outcome.good then p.stats.good += 1 end
	if outcome.correctAuth and not record.item.genuine then p.stats.fakes += 1 end
	p.specXP[def.spec] += if outcome.good then 16 else 7
	registerSeen(p, def.id)
	if purchase then
		Tutorial.Mark(p,"bought")
		record.item.paid = purchase; table.insert(p.inventory, record.item); p.stats.purchases += 1
		if def.value >= 3000 then p.stats.rare += 1 end
	end
	if purchase then syncCollection(player)end
	local display=sessions[player].plot and sessions[player].plot:FindFirstChild("CurrentItem")
	if display then Audio.Play(display.PrimaryPart,if purchase then "coin"else "stamp")end
	Customers.Finish(player, if purchase and purchase > outcome.value * 1.15 then "laugh" else outcome.mood)
	State:FireClient(player, { kind = "receipt", name = def.name, value = outcome.value, quote = quote, genuine = record.item.genuine,
		fee = outcome.fee, rep = outcome.rep, error = math.floor(outcome.error * 100), good = outcome.good, bought = purchase })
	sendSnapshot(player); updateDisplay(player); roster()
end

local function validVerdict(data)
	return type(data) == "table" and Domain.finite(data.quote) and data.quote >= 1 and data.quote <= 100000000
		and (data.auth == "genuine" or data.auth == "replica" or data.auth == "unknown")
end
local function getRecord(player, id)
	local record = Customers.Active(player)
	if record and record.id == id then return record, "npc" end
	local request = requests[id]
	if request and request.appraiser == player and request.accepted then return request, "peer" end
	return nil
end

local function completePeer(player, record, data)
	local visitor, p, ownerProfile = record.visitor, Profiles.loaded[player], Profiles.loaded[record.visitor]
	if not visitor.Parent or not ownerProfile then cancelRequest(record.id); return end
	local item = inventoryItem(ownerProfile, record.itemUid)
	if not item or ownerProfile.cash < Config.PeerFee then cancelRequest(record.id); return end
	local def = index[item.id]
	local outcome = Domain.verdict(def, item, data.quote, data.auth, 1, 1)
	ownerProfile.cash -= Config.PeerFee; p.cash += Config.PeerFee
	p.reputation = math.clamp(p.reputation + (if outcome.good then 2 else -1), 0, 100)
	p.stats.served += 1; if outcome.good then p.stats.good += 1 end
	if outcome.correctAuth and not item.genuine then p.stats.fakes += 1 end
	registerSeen(p, def.id)
	p.specXP[def.spec] += if outcome.good then 12 else 6
	item.lastAppraiser = player.UserId; item.lastReportAt = os.time()
	table.insert(item.reports, { by = player.DisplayName, quote = Domain.money(data.quote), auth = data.auth, at = os.time() })
	if #item.reports > 3 then table.remove(item.reports, 1) end
	requests[record.id] = nil
	Tutorial.Mark(p,"peer");Tutorial.Mark(ownerProfile,"peer")
	State:FireClient(visitor, { kind = "report", name = def.name, by = player.DisplayName, quote = Domain.money(data.quote), auth = data.auth, fee = Config.PeerFee })
	message(player, "Заключение выдано. +40 монет за независимую экспертизу.", "good")
	updateDisplay(player); sendSnapshot(player); sendSnapshot(visitor); roster()
end

local handlers = {}
handlers.Hello = function(player)
	local publicCatalog = {}
	for _, def in ipairs(Catalog) do table.insert(publicCatalog, { id = def.id, name = def.name, spec = def.spec }) end
	State:FireClient(player, { kind = "catalog", items = publicCatalog })
	sendSnapshot(player); roster()
end
handlers.Open = function(player, data)
	local panel = if type(data) == "table" then data.panel else "case"
	if panel == "case" or panel == "workshop" or panel == "inventory" or panel == "specialty" or panel == "titles" or panel == "guide" or panel=="decor"then
		if panel == "case" and not working(player,sessions[player]) then message(player,"Сядь в рабочее кресло своего бюро, чтобы начать оценку."); return end
		sendSnapshot(player); open(player, panel)
	end
end
handlers.Inspect = function(player, data)
	local s, p = sessions[player], Profiles.loaded[player]
	if type(data) ~= "table" or type(data.tool) ~= "string" or not Config.Tools[data.tool] then return end
	if not working(player, s) then message(player, "Для исследования сядь в своё рабочее кресло."); return end
	local record = getRecord(player, data.caseId)
	if not record then message(player, "Это дело уже закрыто."); sendSnapshot(player); return end
	if record.busy and record.busy.deadline<os.clock() then record.busy=nil;Workstation.Stop(player) end
	if record.busy then sendSnapshot(player);return end
	if (p.equipment[data.tool] or 0) <= 0 then message(player, "Сначала купи этот прибор в мастерской."); return end
	if record.tests[data.tool] then message(player, "Результат уже записан в дело."); return end
	record.busy=Challenges.New(data.tool,record.item.seed,os.clock());record.busy.id=HttpService:GenerateGUID(false)
	Workstation.Begin(player,s.plot,record,data.tool)
	Workstation.Step(player,record.busy)
	local display=s.plot:FindFirstChild("CurrentItem")
	if display then Audio.Play(display.PrimaryPart,if data.tool=="loupe"or data.tool=="scale"then "ceramic"else "paper")end
	sendSnapshot(player)
end
handlers.ChallengeStep=function(player,data)
	if type(data)~="table" or not working(player,sessions[player]) then return end
	local record=getRecord(player,data.caseId)
	if not record or not record.busy or data.id~=record.busy.id then return end
	local c=record.busy
	local ok,done,note=Challenges.Step(c,data.action,data.value,os.clock())
	if ok then Workstation.Step(player,c)end
	if done then
		Workstation.Stop(player)
		Tutorial.Mark(Profiles.loaded[player],c.tool)
		record.tests[c.tool]=Domain.test(Profiles.loaded[player],index[record.item.id],record.item,c.tool);record.busy=nil;record.servicePausedUntil=os.clock()+10
		sendSnapshot(player)
	else
		if os.clock()>c.deadline then record.busy=nil;Workstation.Stop(player);sendSnapshot(player);return end
		State:FireClient(player,{kind="challengeUpdate",caseId=record.id,challenge=Challenges.Public(c),note=note,accepted=ok})
	end
end
handlers.CancelInspection=function(player,data)
	if type(data)~="table" then return end
	local record=getRecord(player,data.caseId)
	if record then record.busy=nil;Workstation.Stop(player);sendSnapshot(player) end
end
handlers.Complete = function(player, data)
	if not validVerdict(data) or not working(player, sessions[player]) then message(player, "Нужны цена, заключение и место в своём рабочем кресле."); return end
	local record, kind = getRecord(player, data.caseId)
	if not record then message(player, "Это дело уже закрыто."); sendSnapshot(player); return end
	if record.busy then message(player, "Исследование ещё идёт."); return end
	if kind == "peer" then completePeer(player, record, data) else reward(player, record, Domain.money(data.quote), data.auth, nil) end
end
handlers.Offer = function(player, data)
	local p, s = Profiles.loaded[player], sessions[player]
	if not validVerdict(data) or not Domain.finite(data.amount) or data.amount < 1 or data.amount > 100000000 then message(player, "Введи цену оценки и сумму выкупа."); return end
	if not working(player, s) then return end
	local record, kind = getRecord(player, data.caseId)
	if not record or kind ~= "npc" or record.busy then return end
	if #p.inventory >= Config.InventoryLimit then message(player, "Коллекция заполнена. Продай часть предметов скупщику."); return end
	if record.negotiations >= 3 then message(player, "Клиент больше не торгуется. Можно завершить только оценку."); return end
	local amount = Domain.money(data.amount)
	if availableCash(player) < amount then message(player, "Не хватает свободных денег для выкупа.", "bad"); return end
	local minimum = Domain.minimumOffer(index[record.item.id], record.item, record.patience)
	if amount >= minimum then
		reward(player, record, Domain.money(data.quote), data.auth, amount)
	else
		record.negotiations += 1; record.patience = math.max(0.05, record.patience - 0.1)
		record.counter = Domain.money(minimum * (1.05 - record.negotiations * 0.015))
		Customers.Mood(player, if amount < minimum * 0.4 then "angry" else "sigh", "Хочу не меньше " .. record.counter .. " монет")
		sendSnapshot(player)
	end
end
handlers.UpgradeBase = function(player)
	local p, s = Profiles.loaded[player], sessions[player]
	if not s.plot or not near(player, s.plot.Anchor.Position, 110) then message(player, "Улучшение доступно рядом с твоим бюро."); return end
	local nextLevel = Config.BaseLevels[p.baseLevel + 1]
	if not nextLevel then message(player, "Это последний из трёх уровней прототипа."); return end
	if p.reputation < nextLevel.rep then message(player, "Нужна репутация " .. nextLevel.rep .. "."); return end
	if availableCash(player) < nextLevel.price then message(player, "Не хватает денег на перестройку.", "bad"); return end
	for id, request in pairs(requests) do if request.appraiser == player then cancelRequest(id, "Бюро перестраивается. Комиссия не списана.") end end
	-- Always relocate people before replacing collidable walls, floors and furniture.
	for _, visitor in ipairs(Players:GetPlayers()) do
		if visitor.Character and near(visitor, s.plot.Anchor.Position, 65) then unseat(visitor);visitor.Character:PivotTo(s.plot.Anchor.CFrame * CFrame.new(14, 4, -76)) end
	end
	Customers.Detach(player)
	p.cash -= nextLevel.price; p.baseLevel += 1
	rebuild(player); Customers.Attach(player, s.plot, p)
	message(player, "Бюро перестроено: " .. nextLevel.name .. ".", "good"); sendSnapshot(player); roster()
end
handlers.UpgradeTool = function(player, data)
	local p, s = Profiles.loaded[player], sessions[player]
	if type(data) ~= "table" or not Config.Tools[data.tool] then return end
	if not s.plot or not near(player, s.plot.Anchor.Position, 105) then message(player, "Вернись в своё бюро за оборудованием."); return end
	local level = p.equipment[data.tool] or 0
	local cost = Config.Tools[data.tool].price[level + 1]
	if not cost then message(player, "Прибор уже улучшен до третьего уровня."); return end
	if availableCash(player) < cost then message(player, "Не хватает денег на прибор.", "bad"); return end
	p.cash -= cost; p.equipment[data.tool] = level + 1
	applyEquipment(player); message(player, Config.Tools[data.tool].name .. ": уровень " .. (level + 1), "good"); sendSnapshot(player)
end
handlers.Specialty = function(player, data)
	local p = Profiles.loaded[player]
	if type(data) ~= "table" or not Config.Specs[data.spec] then return end
	Tutorial.Mark(p,"specialty")
	if data.spec == p.specialty then sendSnapshot(player);return end
	p.specialty = data.spec
	message(player, "Основная специальность: " .. Config.Specs[data.spec].name .. ". Опыт остальных направлений сохранён.", "good")
	sendSnapshot(player); roster()
end
handlers.Train = function(player)
	message(player,"Профессии развиваются практикой: оценивай предметы этого направления. Покупать уровни не требуется.")
end
handlers.Tutorial=function(player,data)
	if type(data)~="table"then return end
	local p=Profiles.loaded[player]
	if data.mode=="skip"then p.tutorial.skipped=true
	elseif data.mode=="replay"then p.tutorial={flags={},skipped=false}end
	sendSnapshot(player)
end
handlers.BuyDecor=function(player,data)
	if type(data)~="table"or type(data.id)~="string"then return end
	local d=Decor.ById[data.id];local p,s=Profiles.loaded[player],sessions[player]
	if not d then return end
	local personal=d.category=="card"or d.category=="frame"
	if not personal and not s.plot then return end
	if not personal and not near(player,s.plot.Anchor.Position,105)then message(player,"Покупка обстановки доступна у своего бюро.");return end
	if not p.ownedDecor[d.id]then
		if d.premium then Commerce.Prompt(player,d);return end
		if availableCash(player)<d.price then message(player,"Не хватает монет на этот декор.","bad");return end
		p.cash-=d.price;p.ownedDecor[d.id]=true
	end
	p.equippedDecor[d.category]=d.id;applyDecor(player);sendSnapshot(player);roster()
end
handlers.RemoveDecor=function(player,data)
	if type(data)~="table"then return end
	local p=Profiles.loaded[player];local d=Decor.ById[p.equippedDecor[data.category]]
	if d and d.category~="chair"and d.category~="frame"and d.category~="card"then p.equippedDecor[d.category]=nil;applyDecor(player);sendSnapshot(player)end
end
handlers.Carry = function(player, data)
	if type(data) ~= "table" then return end
	local item = inventoryItem(Profiles.loaded[player], data.uid)
	if not item then return end
	carry(player, item); sendSnapshot(player); message(player, "Предмет в руках. Подойди к столу другого игрока и нажми E.")
end
handlers.Sell = function(player, data)
	if type(data) ~= "table" then return end
	local broker = workspace.Town:FindFirstChild("BrokerAnchor", true)
	if not broker or not near(player, broker.Position, 25) then message(player, "Для продажи дойди до скупщика у южных ворот. Указатель «СКУПКА»."); return end
	local p = Profiles.loaded[player]
	local item, i = inventoryItem(p, data.uid)
	if not item or lockedItem(player, item.uid) then message(player, "Этот предмет сейчас находится на экспертизе."); return end
	local value = Domain.money(Domain.trueValue(index[item.id], item) * 0.72)
	table.remove(p.inventory, i); p.cash = Domain.money(p.cash + value)
	if sessions[player].heldUid == item.uid then clearHeld(player) end
	syncCollection(player)
	message(player, "Скупщик купил «" .. index[item.id].name .. "» за " .. value .. " монет (72% рыночной цены).", "good")
	sendSnapshot(player)
end
handlers.PeerAccept = function(player, data)
	if type(data) ~= "table" then return end
	local r = requests[data.id]
	if not r or r.appraiser ~= player or r.accepted then return end
	if not working(player, sessions[player]) then message(player, "Для приёма экспертизы сядь в своё рабочее кресло."); return end
	if not near(r.visitor, sessions[player].plot.Anchor.Position, 110) then cancelRequest(r.id, "Посетитель ушёл из бюро."); return end
	r.accepted = true; r.expires = os.clock() + 600
	message(r.visitor, "Оценщик принял предмет. Он выдаст заключение после исследования.")
	sendSnapshot(player); updateDisplay(player); open(player, "peer")
end
handlers.PeerDecline = function(player, data)
	local r = type(data) == "table" and requests[data.id]
	if r and (r.appraiser == player or r.visitor == player) then cancelRequest(r.id) end
end
handlers.Title = function(player, data)
	if type(data) ~= "table" then return end
	local p = Profiles.loaded[player]
	if Domain.unlockedTitles(p)[data.id] then p.title = data.id; sendSnapshot(player); roster() end
end
handlers.BuyNametag=function(player,data)
	if type(data)~="table"or type(data.id)~="string"then return end
	local d=Identity.ById[data.id];local p=Profiles.loaded[player]
	if not d then return end
	if not p.ownedNametags[d.id]then
		if availableCash(player)<d.price then message(player,"Не хватает монет на nametag.","bad");return end
		p.cash-=d.price;p.ownedNametags[d.id]=true
	end
	p.nametag=d.id;sendSnapshot(player);roster()
end
handlers.Return = function(player)
	local s = sessions[player]
	if not s or not player.Character then return end
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		unseat(player)
		player.Character:PivotTo(if s.plot then s.plot.Anchor.CFrame * CFrame.new(14, 4, -65) else CFrame.new(0, 5, -274))
	end
end
handlers.Admin = function(player, data)
	if not isAdmin(player) or type(data) ~= "table" then return end
	local p, s = Profiles.loaded[player], sessions[player]
	if data.command == "funds" then p.cash = math.min(1000000000, p.cash + 25000)
	elseif data.command == "reputation" then p.reputation = 75
	elseif data.command == "tools" then for key in pairs(p.equipment) do p.equipment[key] = 3 end; applyEquipment(player)
	elseif data.command == "titles"or data.command=="identity"then
		p.stats.good = math.max(10, p.stats.good); p.stats.fakes = math.max(5, p.stats.fakes)
		p.stats.purchases = math.max(5, p.stats.purchases); p.stats.rare = math.max(1, p.stats.rare)
		for _, def in ipairs(Catalog) do registerSeen(p, def.id) end
		if data.command=="identity"then Identity.GrantAll(p)end
	elseif data.command=="friendwalk"then Customers.Flush(player);Customers.Spawn(player,nil,false)
	elseif data.command == "base" and s.plot then
		for _, r in pairs(requests) do if r.appraiser == player then cancelRequest(r.id) end end
		Customers.Detach(player)
		for _, visitor in ipairs(Players:GetPlayers()) do if visitor.Character and near(visitor, s.plot.Anchor.Position, 70) then unseat(visitor);visitor.Character:PivotTo(s.plot.Anchor.CFrame * CFrame.new(14, 4, -76)) end end
		p.baseLevel = p.baseLevel % 3 + 1; rebuild(player); Customers.Attach(player, s.plot, p)
	elseif data.command=="pause"then Customers.SetPaused(player,not(Customers.sessions[player]and Customers.sessions[player].paused))
	elseif (data.command=="sample"or data.command=="samples")and index[data.id]then
		local mutations=if data.command=="samples"then {"none",unpack(Rarity.Order)}else {data.mutation or "none"}
		for _,mutation in ipairs(mutations)do
			if #p.inventory>=Config.InventoryLimit then break end
			if mutation~="none"and not Rarity.Definitions[mutation]then continue end
			local item=Customers.NewItem(index[data.id],p.reputation);item.paid=0;item.condition=.95;item.repair=false;item.surfaceTone=0
			item.mutation=mutation;item.uniqueness=if Domain.finite(data.uniqueness)then math.floor(math.clamp(data.uniqueness,0,100)*10+.5)/10 else 0
			table.insert(p.inventory,item)
		end
		message(player,"Образцы выставлены в коллекции. E — рассмотреть, F — взять.","good")
	elseif data.command == "spawn" and index[data.id] then
		Customers.Flush(player)
		if Customers.Spawn(player, data.id, true,data)then if working(player,s)then open(player,"case")else message(player,"Клиент у стойки. Сядь в кресло, чтобы начать.")end end
	elseif data.command == "item" and index[data.id] and #p.inventory < Config.InventoryLimit then
		local item = Customers.NewItem(index[data.id], p.reputation); item.paid = 0; table.insert(p.inventory, item)
	elseif data.command == "emotions" then
		local r = Customers.Active(player)
		if r then
			r.patience = if r.patience > 0.65 then 0.5 elseif r.patience > 0.3 then 0.15 else 1
			Customers.Mood(player, if r.patience < 0.3 then "angry" elseif r.patience < 0.65 then "sigh" else "neutral")
		end
	elseif data.command=="mutation" or data.command=="unique" then
		local r=Customers.Active(player)
		local item=if data.uid then inventoryItem(p,data.uid)else r and r.item
		if item then
			if data.command=="mutation"then
				local position=table.find(Rarity.Order,item.mutation)or 0
				item.mutation=Rarity.Order[position+1]or"none"
			else
				local values={0,.1,1,10,100};local position=table.find(values,item.uniqueness or 0)or 1;item.uniqueness=values[position+1]or 0
			end
			updateDisplay(player,true);syncCollection(player)
		end
	elseif data.command=="decor"then
		for _,d in ipairs(Decor.List)do p.ownedDecor[d.id]=true end
	end
	syncCollection(player);sendSnapshot(player); roster()
end

Commerce.Init(Profiles,sessions,message,function(player)applyDecor(player);sendSnapshot(player);roster()end)

Action.OnServerEvent:Connect(function(player, action, data)
	if type(action) ~= "string" or not handlers[action] then return end
	local now=os.clock();local instrument=action=="ChallengeStep"
	local bucketSet=buckets[player]or{};buckets[player]=bucketSet
	local key=if instrument then"instrument"else"general";local capacity=if instrument then 30 else 10
	local b=bucketSet[key]or{tokens=capacity,at=now};bucketSet[key]=b
	b.tokens=math.min(capacity,b.tokens+(now-b.at)*(if instrument then 15 else 3));b.at=now
	if b.tokens < 1 then return end
	b.tokens -= 1
	if action ~= "Hello" and not Profiles.loaded[player] then message(player, "Бюро ещё загружается."); return end
	local ok, err = pcall(handlers[action], player, data)
	if not ok then warn("[PROBA] Action failed", action, err); message(player, "Действие не завершено. Попробуй ещё раз.", "bad") end
end)

Customers.Init(Catalog, index, {
	servicePause=function(player)for _,r in pairs(requests)do if r.appraiser==player and r.accepted then return true end end;return false end,
	changed = function(player) if sessions[player] and Profiles.loaded[player] then updateDisplay(player); sendSnapshot(player) end end,
	abandoned = function(player)
		local p = Profiles.loaded[player]
		if p then p.reputation = math.max(0, p.reputation - 1); message(player, "Клиент ушёл из-за ожидания. Репутация −1.", "bad") end
	end,
	pulse = function(player)
		if not player.Parent then return end
		local s = Customers.sessions[player]; local active = Customers.Active(player)
		State:FireClient(player, { kind = "pulse", queue = if s then #s.queue else 0, caseId = active and active.id,
			patience = active and active.patience, mood = active and active.mood,timing=active and Timing.Public(active),avatarStatus=avatarStatus(player) })
	end,
})

for _, plot in ipairs(workspace.Plots:GetChildren()) do table.insert(plots, plot) end
table.sort(plots, function(a, b) return a.Name < b.Name end)

local function assignPlot(player)
	local s = sessions[player]
	if not s or s.plot then return end
	for _, plot in ipairs(plots) do
		if not plot:GetAttribute("OwnerId") then
			plot:SetAttribute("OwnerId", player.UserId); s.plot = plot
			if Profiles.loaded[player] then rebuild(player); Customers.Attach(player, plot, Profiles.loaded[player]); sendSnapshot(player) end
			return
		end
	end
end
local function characterAdded(player, character)
	local root = character:WaitForChild("HumanoidRootPart", 12)
	if not root then return end
	for _, part in ipairs(character:GetDescendants()) do if part:IsA("BasePart") then part.CollisionGroup = "Characters" end end
	character.DescendantAdded:Connect(function(part) if part:IsA("BasePart") then part.CollisionGroup = "Characters" end end)
	local s = sessions[player]
	if s then
		s.heldUid = nil
		if Profiles.loaded[player]then syncCollection(player)end
		character:PivotTo(if s.plot then s.plot.Anchor.CFrame * CFrame.new(14, 4, -65) else CFrame.new(0, 5, -274))
	end
end
local function joined(player)
	if sessions[player] then return end
	sessions[player] = { saveMode = "loading" }
	assignPlot(player) -- reserve before the first yielding API request
	player.CharacterAdded:Connect(function(character) characterAdded(player, character) end)
	if player.Character then task.spawn(characterAdded, player, player.Character) end
	local profile, mode = Profiles.Load(player, index)
	if not player.Parent then Profiles.Save(player, true); Profiles.Forget(player); return end
	local s = sessions[player]; s.saveMode = mode
	if s.plot then rebuild(player); Customers.Attach(player, s.plot, profile) else message(player, "Все шесть бюро заняты. Ты в гостевом режиме до освобождения участка.") end
	sendSnapshot(player); roster()
	if mode == "session" then message(player, "Сохранение недоступно: прогресс этого сеанса не будет записан в облако.", "bad") end
end
Players.PlayerAdded:Connect(joined)
Players.PlayerRemoving:Connect(function(player)
	Workstation.Stop(player)
	for id, request in pairs(requests) do if request.visitor == player or request.appraiser == player then cancelRequest(id, "Один из участников вышел. Комиссия не списана.") end end
	Customers.Detach(player)
	local s = sessions[player]
	if s and s.plot then
		s.plot:SetAttribute("OwnerId", nil)
		local collection=s.plot:FindFirstChild("OwnedCollection");if collection then collection:Destroy()end
		local decorations=s.plot:FindFirstChild("Decorations");if decorations then decorations:Destroy()end
		local old = s.plot:FindFirstChild("CurrentItem"); if old then old:Destroy() end
		local building = s.plot:FindFirstChild("Building"); if building then building:Destroy() end
		local empty = ServerStorage.Buildings.Level1:Clone(); empty.Name = "Building"; empty:PivotTo(s.plot.Anchor.CFrame); empty.Parent = s.plot
	end
	sessions[player] = nil; buckets[player] = nil
	for waiting in pairs(sessions) do if not sessions[waiting].plot then assignPlot(waiting) end end
	roster()
	Profiles.Save(player, true); Profiles.Forget(player)
end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(joined, player) end

local brokerPrompt = workspace.Town:FindFirstChild("BrokerPrompt", true)
if brokerPrompt then brokerPrompt.Triggered:Connect(function(player) sendSnapshot(player); open(player, "inventory"); message(player, "Выбери предмет и нажми «Продать скупщику». Выплата — 72% рыночной стоимости.") end) end
local guidePrompt = workspace.Town:FindFirstChild("GuidePrompt", true)
if guidePrompt then guidePrompt.Triggered:Connect(function(player) open(player, "guide") end) end

task.spawn(function()
	while true do
		task.wait(0.25)
		for door, status in pairs(doors) do
			if not door.Parent then doors[door] = nil; continue end
			local occupied = false
			for _, player in ipairs(Players:GetPlayers()) do if near(player, door.Sensor.Position, 19) then occupied = true; break end end
			if not occupied then
				for _, model in ipairs(workspace.Customers:GetChildren()) do
					local root = model:FindFirstChild("HumanoidRootPart")
					if root and (root.Position - door.Sensor.Position).Magnitude < 22 then occupied = true; break end
				end
			end
			if occupied ~= status.open and not status.tweening then
				status.open = occupied; status.tweening = true
				Audio.Play(door.Sensor,"doorSlide")
				door.Left.CanCollide = false; door.Right.CanCollide = false
				local left = status.left * CFrame.new(if occupied then -7 else 0, 0, 0)
				local right = status.right * CFrame.new(if occupied then 7 else 0, 0, 0)
				TweenService:Create(door.Left, TweenInfo.new(0.55, Enum.EasingStyle.Sine), { CFrame = left }):Play()
				TweenService:Create(door.Right, TweenInfo.new(0.55, Enum.EasingStyle.Sine), { CFrame = right }):Play()
				task.delay(0.6, function()
					if door.Parent then door.Left.CanCollide = not occupied; door.Right.CanCollide = not occupied end
					if door.Parent then Audio.Play(door.Sensor,"glassLatch")end
					status.tweening = false
				end)
			end
		end
		for id,request in pairs(requests)do
			if request.accepted and request.busy and os.clock()<request.busy.deadline then request.expires+=.25 end
			if os.clock()>request.expires then cancelRequest(id,"Время ожидания экспертизы истекло. Комиссия не списана.")end
		end
	end
end)
task.spawn(function()
	while true do task.wait(6); roster() end
end)
task.spawn(function()
	while true do
		task.wait(45)
		for player in pairs(Profiles.loaded) do task.spawn(function()
			if not Profiles.Save(player, false) then message(player, "Не удалось сохранить прогресс. Следующая попытка — автоматически.", "bad") end
		end) end
	end
end)
game:BindToClose(function()
	local remaining = 0
	for player in pairs(Profiles.loaded) do remaining += 1; task.spawn(function() Profiles.Save(player, true); remaining -= 1 end) end
	local deadline = os.clock() + 25
	while remaining > 0 and os.clock() < deadline do task.wait(0.1) end
end)

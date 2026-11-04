local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local PhysicsService = game:GetService("PhysicsService")
local TweenService = game:GetService("TweenService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local Domain = require(game.ReplicatedStorage.Shared.Domain)

local Customers = { sessions = {}, actors = {} }
local callbacks, catalog, byId
local rng = Random.new()
local descriptionCache = {}
local emoji = { neutral = "🙂", think = "🤔", sigh = "😮‍💨", sad = "😢", angry = "😠", happy = "😄", laugh = "😆", surprise = "😲" }
local phrases = { neutral = "Жду своей очереди", think = "Сколько это может стоить?", sigh = "Это надолго?..", sad = "Я уже долго жду", angry = "Я ухожу!", happy = "Спасибо за экспертизу!", laugh = "Вот это щедрость!", surprise = "Неожиданный результат" }

local function world(session, x, y, z)
	return session.plot.Anchor.CFrame:PointToWorldSpace(Vector3.new(x, y, z))
end

function Customers.NewItem(def, reputation)
	return { id = def.id, uid = HttpService:GenerateGUID(false), seed = rng:NextInteger(1, 2000000000),
		genuine = rng:NextNumber() < math.clamp(0.78 - reputation * 0.0012, 0.58, 0.78),
		condition = rng:NextNumber(0.35, 1), demand = rng:NextNumber(0.85, 1.2), reports = {} }
end

local function setMood(record, mood, phrase)
	if not record.model or not record.model.Parent then return end
	record.mood = mood
	local label = record.model:FindFirstChild("Mood", true)
	if label and label:IsA("TextLabel") then label.Text = emoji[mood] or emoji.neutral end
	local caption = record.model:FindFirstChild("Caption", true)
	if caption and caption:IsA("TextLabel") then caption.Text = phrase or phrases[mood] or "" end
	local head = record.model:FindFirstChild("Head")
	if head then
		local neck = record.model:FindFirstChild("Neck", true)
		if neck and neck:IsA("Motor6D") then
			local rest = neck:GetAttribute("Rest")
			if not rest then rest = neck.C0; neck:SetAttribute("Rest", rest) end
			TweenService:Create(neck, TweenInfo.new(0.3), { C0 = rest * CFrame.Angles(0, 0, if mood == "sad" then -0.14 elseif mood == "think" then 0.13 else 0) }):Play()
		end
	end
end

function Customers.Mood(player, mood, phrase)
	local record = Customers.Active(player)
	if record then record.moodLock = os.clock() + 5; setMood(record, mood, phrase) end
end

local function decorate(model, displayName)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Customers"
			part.CanTouch = false
			part.CanCollide = part.Name == "HumanoidRootPart" or part.Name == "Torso" or part.Name == "UpperTorso"
		end
		if part:IsA("Script") or part:IsA("LocalScript") then part:Destroy() end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None; humanoid.WalkSpeed = 10; humanoid.JumpHeight = 4 end
	local head = model:FindFirstChild("Head")
	if head then
		local board = Instance.new("BillboardGui"); board.Name = "CustomerMood"; board.Size = UDim2.fromOffset(180, 86)
		board.StudsOffset = Vector3.new(0, 3.1, 0); board.MaxDistance = 52; board.AlwaysOnTop = false; board.Parent = head
		local mood = Instance.new("TextLabel"); mood.Name = "Mood"; mood.Size = UDim2.fromOffset(54, 42); mood.Position = UDim2.fromOffset(63, 0)
		mood.BackgroundColor3 = Color3.fromRGB(249, 245, 228); mood.BackgroundTransparency = 0.08; mood.TextSize = 29; mood.Text = "🙂"; mood.Parent = board
		local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = mood
		local name = Instance.new("TextLabel"); name.Name = "CustomerName"; name.Size = UDim2.new(1, 0, 0, 18); name.Position = UDim2.fromOffset(0, 43)
		name.BackgroundTransparency = 1; name.Font = Enum.Font.GothamMedium; name.TextSize = 12; name.TextColor3 = Color3.fromRGB(252, 246, 224)
		name.TextStrokeTransparency = 0.5; name.Text = displayName; name.Parent = board
		local caption = name:Clone(); caption.Name = "Caption"; caption.TextSize = 10; caption.Position = UDim2.fromOffset(0, 62); caption.Text = "Жду своей очереди"; caption.Parent = board
	end
	return humanoid
end

local function move(record, session, points, token, leaving)
	local root = record.model and record.model:FindFirstChild("HumanoidRootPart")
	if not root or not record.humanoid then return false end
	record.walking = true
	for _, point in ipairs(points) do
		if not record.model.Parent or record.moveToken ~= token or (not leaving and not session.alive) then record.walking = false; return false end
		local target = world(session, point.X, point.Y, point.Z)
		record.humanoid:MoveTo(target)
		local deadline = os.clock() + math.max(5, (root.Position - target).Magnitude / 7 + 2)
		while root.Parent and record.model.Parent and record.moveToken == token and os.clock() < deadline do
			if (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(target.X, 0, target.Z)).Magnitude < 2 then break end
			task.wait(0.15)
		end
		if not root.Parent or record.moveToken ~= token then record.walking = false; return false end
		if (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(target.X, 0, target.Z)).Magnitude >= 5 then record.walking = false; return false end
	end
	record.walking = false
	return true
end

local function walkToSlot(session, record, index)
	record.slot = index; record.arrived = false
	record.moveToken += 1
	local token = record.moveToken
	task.spawn(function()
		local points
		if index == 1 then
			points = { Vector3.new(0, 3, -48), Vector3.new(0, 3, -20), Vector3.new(0, 3, -1) }
		else
			points = { Vector3.new(-18, 3, -72), Vector3.new(-18, 3, -48 - (index - 2) * 6) }
		end
		if move(record, session, points, token) and session.alive and record.moveToken == token then
			record.arrived = true
			if index == 1 then
				record.humanoid:MoveTo(world(session, 0, 3, -1))
				local root = record.model:FindFirstChild("HumanoidRootPart")
				if root then root.CFrame = CFrame.lookAt(root.Position, world(session, 0, root.Position.Y, 10)) end
				setMood(record, "think", "Готов рассказать о своей вещи")
			end
			callbacks.changed(session.player)
		elseif session.alive and record.moveToken == token then
			-- Do not teleport a client through a blocked wall. Unreachable customers leave without a penalty.
			record.routeFailed = true
		end
	end)
end

local function reorder(session)
	for i, record in ipairs(session.queue) do
		if record.model and record.slot ~= i then walkToSlot(session, record, i) end
	end
end

local function remove(session, record, mood)
	local index = table.find(session.queue, record)
	if not index then return end
	table.remove(session.queue, index)
	record.moveToken += 1; record.leaving = true
	local token = record.moveToken
	setMood(record, mood)
	reorder(session)
	callbacks.changed(session.player)
	task.spawn(function()
		task.wait(1.5)
		if record.model and record.model.Parent then
			local points = if index == 1 then { Vector3.new(0, 3, -20), Vector3.new(0, 3, -48), Vector3.new(30, 3, -75), Vector3.new(48, 3, -94) }
				else { Vector3.new(-18, 3, -74), Vector3.new(20, 3, -84), Vector3.new(48, 3, -94) }
			move(record, session, points, token, true)
			record.model:Destroy()
		end
		Customers.actors[record] = nil
	end)
end

function Customers.Active(player)
	local s = Customers.sessions[player]
	local first = s and s.queue[1]
	return if first and first.arrived and not first.routeFailed then first else nil
end

function Customers.Finish(player, mood)
	local s = Customers.sessions[player]; local active = Customers.Active(player)
	if s and active then remove(s, active, mood) end
end

function Customers.Flush(player)
	local s = Customers.sessions[player]
	if not s then return end
	for _, r in ipairs(s.queue) do r.moveToken += 1; if r.model then r.model:Destroy() end end
	for r, owner in pairs(Customers.actors) do
		if owner == s then r.moveToken += 1; if r.model then r.model:Destroy() end; Customers.actors[r] = nil end
	end
	s.queue = {}; s.nextSpawn = os.clock() + 30
	callbacks.changed(player)
end

function Customers.Spawn(player, forcedId, immediate)
	local session = Customers.sessions[player]
	if not session or not session.alive or #session.queue >= Config.BaseLevels[session.profile.baseLevel].capacity then return false end
	local profile = session.profile
	local def = byId[forcedId]
	if not def then
		local pool = {}
		local cap = 250 + (profile.reputation + 1) ^ 1.65 * 16
		for _, candidate in ipairs(catalog) do
			if candidate.value <= cap then
				table.insert(pool, candidate)
				if candidate.spec == profile.specialty then table.insert(pool, candidate); table.insert(pool, candidate) end
			end
		end
		def = pool[rng:NextInteger(1, #pool)]
	end
	local friend = if #session.friends > 0 then session.friends[rng:NextInteger(1, #session.friends)] else nil
	local displayName = if friend then friend.name else ({ "Алекс · классический гость", "Робин · классический гость", "Сэм · классический гость", "Бэкон · классический гость" })[rng:NextInteger(1, 4)]
	local record = { id = HttpService:GenerateGUID(false), item = Customers.NewItem(def, profile.reputation), name = displayName,
		patience = 1, tests = {}, negotiations = 0, moveToken = 0, arrived = false, mood = "neutral", age = 0 }
	table.insert(session.queue, record)
	task.spawn(function()
		local model
		if friend and descriptionCache[friend.id] then
			local ok, result = pcall(function() return Players:CreateHumanoidModelFromDescriptionAsync(descriptionCache[friend.id], Enum.HumanoidRigType.R15) end)
			if ok then model = result end
		end
		if not model then model = game.ServerStorage.Templates.BaconCustomer:Clone() end
		if not session.alive or not table.find(session.queue, record) then model:Destroy(); return end
		model.Name = "Customer_" .. string.sub(record.id, 1, 8)
		record.model = model; record.humanoid = decorate(model, displayName)
		Customers.actors[record] = session
		local primary = model:FindFirstChild("HumanoidRootPart")
		if primary then model.PrimaryPart = primary end
		model.Parent = workspace.Customers
		model:PivotTo(session.plot.Anchor.CFrame * (if immediate then CFrame.new(0, 4.2, -1) * CFrame.Angles(0, math.pi, 0) else CFrame.new(46, 3.2, -94)))
		local root = model:FindFirstChild("HumanoidRootPart")
		if root then pcall(function() root:SetNetworkOwner(nil) end) end
		if immediate then record.slot = 1; record.arrived = true; setMood(record, "think", "Тестовый предмет готов к осмотру")
		else walkToSlot(session, record, table.find(session.queue, record)) end
		callbacks.changed(player)
	end)
	callbacks.changed(player)
	return true
end

function Customers.Attach(player, plot, profile)
	local session = { player = player, plot = plot, profile = profile, queue = {}, friends = {}, alive = true, nextSpawn = os.clock() + 2 }
	Customers.sessions[player] = session
	task.spawn(function()
		local ok, pages = pcall(function() return Players:GetFriendsAsync(player.UserId) end)
		if not ok or not session.alive then return end
		local candidates = {}
		for _, friend in ipairs(pages:GetCurrentPage()) do
			if #candidates >= 12 then break end
			table.insert(candidates, { id = friend.Id, name = friend.DisplayName or friend.Username })
		end
		for _, friend in ipairs(candidates) do
			if not session.alive then break end
			if not descriptionCache[friend.id] then
				local got, description = pcall(function() return Players:GetHumanoidDescriptionFromUserIdAsync(friend.id) end)
				if got then descriptionCache[friend.id] = description end
			end
			if descriptionCache[friend.id] then table.insert(session.friends, friend) end
			task.wait(0.3)
		end
	end)
end

function Customers.Detach(player)
	local s = Customers.sessions[player]
	if not s then return end
	s.alive = false
	for _, r in ipairs(s.queue) do r.moveToken += 1; if r.model then r.model:Destroy() end end
	for r, owner in pairs(Customers.actors) do
		if owner == s then r.moveToken += 1; if r.model then r.model:Destroy() end; Customers.actors[r] = nil end
	end
	Customers.sessions[player] = nil
end

function Customers.Init(definitions, index, handlers)
	catalog = definitions; byId = index; callbacks = handlers
	pcall(function() PhysicsService:RegisterCollisionGroup("Customers") end)
	pcall(function() PhysicsService:RegisterCollisionGroup("Characters") end)
	PhysicsService:CollisionGroupSetCollidable("Customers", "Customers", false)
	PhysicsService:CollisionGroupSetCollidable("Customers", "Characters", false)
	task.spawn(function()
		while true do
			task.wait(1)
			for player, s in pairs(Customers.sessions) do
				if not s.alive then continue end
				if os.clock() >= s.nextSpawn then
					Customers.Spawn(player)
					s.nextSpawn = os.clock() + math.max(9, 25 - s.profile.reputation * 0.12 - s.profile.baseLevel * 1.5)
				end
				local expired = {}
				for index, r in ipairs(s.queue) do
					r.age += 1
					if r.arrived then r.patience = math.max(0, r.patience - (1 + (#s.queue - 1) * 0.13) / (if index == 1 then 115 else 145)) end
					if r.routeFailed or r.patience <= 0 or (not r.arrived and r.age > 60) then table.insert(expired, r)
					elseif r.arrived and (r.moodLock or 0) < os.clock() then
						local mood = if r.patience < 0.2 then "angry" elseif r.patience < 0.4 then "sad" elseif r.patience < 0.6 then "sigh" elseif index == 1 then "think" else "neutral"
						if mood ~= r.mood then setMood(r, mood) end
					end
				end
				for _, r in ipairs(expired) do
					if r.patience <= 0 then callbacks.abandoned(player, r) end
					remove(s, r, "angry")
				end
				callbacks.pulse(player)
			end
		end
	end)
	-- Server-side joint motion also animates the asset-free classic fallback rig.
	task.spawn(function()
		while true do
			task.wait(0.16)
			local now = os.clock()
			for r in pairs(Customers.actors) do
					if r.model then
						for _, limb in ipairs({ "Right Shoulder", "Left Shoulder", "Right Hip", "Left Hip", "RightShoulder", "LeftShoulder", "RightHip", "LeftHip" }) do
							local joint = r.model:FindFirstChild(limb, true)
							if joint and joint:IsA("Motor6D") then
								local rest = joint:GetAttribute("Rest")
								if not rest then rest = joint.C0; joint:SetAttribute("Rest", rest) end
								local side = if string.find(limb, "Right") then 1 else -1
								local swing = if r.walking then math.sin(now * 8) * 0.35 * side else math.sin(now * 1.8) * 0.035
								if r.mood == "angry" and string.find(limb, "Shoulder") then swing += 0.35 end
								TweenService:Create(joint, TweenInfo.new(0.16, Enum.EasingStyle.Linear), { C0 = rest * CFrame.Angles(swing, 0, 0) }):Play()
							end
						end
					end
			end
		end
	end)
end

return Customers

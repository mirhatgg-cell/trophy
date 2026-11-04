local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Shared.Config)
local Domain = require(game.ReplicatedStorage.Shared.Domain)

local Profiles = { loaded = {}, sessions = {} }
local store
local sessionId = game.JobId .. HttpService:GenerateGUID(false)

local function getStore()
	-- An unpublished Studio file can reject even GetDataStore itself. Never call it for a Studio sandbox.
	if not store then store = DataStoreService:GetDataStore("ProbaBureau_v1") end
	return store
end

local function defaults()
	return { schema = 1, cash = Config.StartingCash, reputation = 0, baseLevel = 1, specialty = "Everyday",
		specXP = { Everyday = 0, Jeweler = 0, Historian = 0, Archaeologist = 0, Technician = 0 },
		equipment = { loupe = 1, scale = 1, uv = 0, spectro = 0, diagnostic = 0 },
		inventory = {}, seen = {}, title = "trainee", stats = { served = 0, good = 0, fakes = 0, purchases = 0, rare = 0 } }
end

local function integer(value, default, low, high)
	return if Domain.finite(value) then math.clamp(math.floor(value), low, high) else default
end

local function sanitize(raw, catalogById)
	local profile = defaults()
	if type(raw) ~= "table" then return profile end
	profile.cash = integer(raw.cash, profile.cash, 0, 1000000000)
	profile.reputation = integer(raw.reputation, 0, 0, 100)
	profile.baseLevel = integer(raw.baseLevel, 1, 1, #Config.BaseLevels)
	profile.specialty = if Config.Specs[raw.specialty] then raw.specialty else "Everyday"
	if type(raw.specXP) == "table" then
		for key in pairs(profile.specXP) do profile.specXP[key] = integer(raw.specXP[key], 0, 0, 1000000) end
	end
	if type(raw.equipment) == "table" then
		for key, level in pairs(profile.equipment) do profile.equipment[key] = integer(raw.equipment[key], level, if key == "loupe" or key == "scale" then 1 else 0, 3) end
	end
	if type(raw.stats) == "table" then
		for key in pairs(profile.stats) do profile.stats[key] = integer(raw.stats[key], 0, 0, 100000000) end
	end
	local seen = {}
	if type(raw.seen) == "table" then
		for _, id in ipairs(raw.seen) do
			if catalogById[id] and not seen[id] then seen[id] = true; table.insert(profile.seen, id) end
		end
	end
	if type(raw.inventory) == "table" then
		local uids = {}
		for _, item in ipairs(raw.inventory) do
			if #profile.inventory >= Config.InventoryLimit then break end
			if type(item) == "table" and catalogById[item.id] and type(item.uid) == "string" and not uids[item.uid]
				and Domain.finite(item.seed) and Domain.finite(item.condition) and Domain.finite(item.demand) and type(item.genuine) == "boolean" then
				uids[item.uid] = true
				local clean = { uid = item.uid, id = item.id, seed = integer(item.seed, 1, 1, 2000000000),
					condition = math.clamp(item.condition, 0.35, 1), demand = math.clamp(item.demand, 0.85, 1.2), genuine = item.genuine,
					paid = integer(item.paid, 0, 0, 1000000000), reports = {} }
				if type(item.reports) == "table" then
					for _, report in ipairs(item.reports) do
						if #clean.reports >= 3 then break end
						if type(report) == "table" and Domain.finite(report.quote) and type(report.by) == "string" then
							table.insert(clean.reports, { quote = Domain.money(report.quote), by = string.sub(report.by, 1, 80),
								auth = if report.auth == "genuine" or report.auth == "replica" then report.auth else "unknown", at = integer(report.at, 0, 0, 5000000000) })
						end
					end
				end
				table.insert(profile.inventory, clean)
			end
		end
	end
	local unlocked = Domain.unlockedTitles(profile)
	profile.title = if unlocked[raw.title] then raw.title else "trainee"
	return profile
end

function Profiles.Load(player, catalogById)
	-- Studio uses an explicit sandbox profile; production records are never overwritten by a Studio test.
	if RunService:IsStudio() or player.UserId <= 0 then
		local p = defaults(); Profiles.loaded[player] = p; Profiles.sessions[player] = { mode = "studio" }; return p, "studio"
	end
	local refused = false
	local ok, raw = pcall(function()
		return getStore():UpdateAsync("u_" .. player.UserId, function(old)
			if type(old) == "table" and type(old.lock) == "table" and old.lock.id ~= sessionId and (old.lock.expires or 0) > os.time() then
				refused = true; return nil
			end
			refused = false
			local value = if type(old) == "table" then old else defaults()
			value.lock = { id = sessionId, expires = os.time() + 180 }
			return value
		end)
	end)
	local mode = if ok and not refused and raw then "cloud" else "session"
	local profile = sanitize(if mode == "cloud" then raw else nil, catalogById)
	Profiles.loaded[player] = profile
	Profiles.sessions[player] = { mode = mode, saving = false }
	if mode == "session" then warn("[PROBA] Persistent data unavailable for user", player.UserId, "— session-only progress; persistent writes disabled") end
	return profile, mode
end

function Profiles.Save(player, release)
	local profile, session = Profiles.loaded[player], Profiles.sessions[player]
	if not profile or not session or session.mode ~= "cloud" then return true end
	local deadline = os.clock() + 8
	while session.saving and os.clock() < deadline do task.wait(0.1) end
	if session.saving then return false end
	session.saving = true
	-- A deep JSON copy prevents in-flight gameplay mutations from changing an UpdateAsync retry.
	local payload = HttpService:JSONDecode(HttpService:JSONEncode(profile))
	local wrote = false
	local ok = false
	for attempt = 1, 3 do
		wrote = false
		ok = pcall(function()
			getStore():UpdateAsync("u_" .. player.UserId, function(old)
				if type(old) ~= "table" or type(old.lock) ~= "table" or old.lock.id ~= sessionId then return nil end
				local nextValue = table.clone(payload)
				nextValue.lock = if release then nil else { id = sessionId, expires = os.time() + 180 }
				wrote = true
				return nextValue
			end)
		end)
		if ok then break end
		task.wait(attempt * 0.6)
	end
	session.saving = false
	if not ok or not wrote then
		warn("[PROBA] Save failed or session lock lost:", player.UserId)
		return false
	end
	return true
end

function Profiles.Forget(player)
	Profiles.loaded[player] = nil; Profiles.sessions[player] = nil
end

return Profiles

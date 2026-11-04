-- A shuffled bag per owner: all friends participate before a new cycle, recent visitors stay out.
local Visits = {}
function Visits.ReadPages(pages, alive, pause)
	local result, seen = {}, {}
	while alive() do
		for _, friend in ipairs(pages:GetCurrentPage()) do
			if not seen[friend.Id] then seen[friend.Id]=true; table.insert(result,{id=friend.Id,name=friend.DisplayName or friend.Username}) end
		end
		if pages.IsFinished then break end
		if not pcall(function() pages:AdvanceToNextPageAsync() end) then break end
		if pause then pause() end
	end
	return result
end
function Visits.Next(state, friends, random, blocked)
	blocked = blocked or {}
	state.bag = state.bag or {}; state.recent = state.recent or {}; state.known = state.known or {}
	local distinct = {}
	for _, friend in ipairs(friends) do
		distinct[friend.id] = true
		if not state.known[friend.id] then state.known[friend.id] = true; table.insert(state.bag, friend) end
	end
	if #friends == 0 then return nil end
	for i=#state.bag,1,-1 do if not distinct[state.bag[i].id] then table.remove(state.bag,i) end end
	if #state.bag == 0 then for _, friend in ipairs(friends) do table.insert(state.bag, friend) end end
	local keep = math.min(3, #friends - 1)
	while #state.recent > keep do table.remove(state.recent, 1) end
	local choices = {}
	local eligible = false
	for i, friend in ipairs(state.bag) do
		if distinct[friend.id] and not blocked[friend.id] then
			eligible = true
			if not table.find(state.recent, friend.id) then table.insert(choices, i) end
		end
	end
	if not eligible then return nil end
	-- At a cycle boundary, serve the least recently seen remaining member; never silently skip them.
	while #choices == 0 and #state.recent > 0 do
		table.remove(state.recent, 1)
		for i, friend in ipairs(state.bag) do if distinct[friend.id] and not blocked[friend.id] and not table.find(state.recent, friend.id) then table.insert(choices, i) end end
	end
	if #choices == 0 then return nil end
	local chosen = choices[random:NextInteger(1, #choices)]
	local friend = table.remove(state.bag, chosen)
	table.insert(state.recent, friend.id)
	return friend
end
return Visits

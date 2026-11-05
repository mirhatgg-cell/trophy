-- NPC animations must be loaded on a server-created Animator to replicate to every player.
local RunService=game:GetService("RunService")
local AssetService=game:GetService("AssetService")
local Driver={controllers={}}
local fields={idle="IdleAnimation",walk="WalkAnimation",run="RunAnimation"}
-- Standard Roblox R15 clips. Custom IDs always come from the friend's own description.
local defaults={idle={507766666,507766951},walk={507777826},run={507767714}}
local cache={}
local function id(value)
	if type(value)=="number"then return if value==value and value>0 and value<9007199254740991 and value%1==0 then value else nil end
	if type(value)=="string"then return id(tonumber(value:match("rbxassetid://(%d+)")or value:match("[?&]id=(%d+)")or value:match("^(%d+)$")))end
	return nil
end
Driver.AssetId=id
function Driver.Capture(model)
	local result={idle={},walk={},run={}}
	local animate=model:FindFirstChild("Animate")
	if not animate then return result end
	for _,animation in ipairs(animate:GetDescendants())do
		if not animation:IsA("Animation")then continue end
		local key;local p=animation
		while p and p~=animate do if result[p.Name:lower()]then key=p.Name:lower();break end;p=p.Parent end
		local asset=id(animation.AnimationId)
		if key and asset then table.insert(result[key],asset)end
	end
	return result
end
function Driver.ResolveContainer(asset,state)
	local key=tostring(asset)..":"..state;local entry=cache[key]
	if entry and entry.ids then return entry.ids end
	if entry and entry.loading then return{}end
	if entry and os.clock()<(entry.retryAt or 0)then return{}end
	cache[key]={loading=true}
	local ok,container=pcall(function()return AssetService:LoadAssetAsync(asset)end)
	local all,specific={},{}
	if ok and container then
		-- Never insert downloaded scripts or parent this asset into the world. Read animation references only.
		local objects={container};for _,o in ipairs(container:GetDescendants())do table.insert(objects,o)end
		for _,o in ipairs(objects)do
			if not o:IsA("Animation")then continue end
			local clip=id(o.AnimationId)
			if clip then
				table.insert(all,clip);local p=o
				while p and p~=container do if p.Name:lower()==state then table.insert(specific,clip);break end;p=p.Parent end
			end
		end
		container:Destroy()
	end
	local ids=if #specific>0 then specific else all
	cache[key]=if #ids>0 then{ids=ids}else{retryAt=os.clock()+60}
	return ids
end
function Driver.Attach(model,description,captured)
	local humanoid=model:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local animator=humanoid:FindFirstChildOfClass("Animator")
	if not animator then animator=Instance.new("Animator");animator.Name="Animator";animator.Parent=humanoid end
	local folder=Instance.new("Folder");folder.Name="AvatarMotion";folder.Parent=model
	local self={model=model,humanoid=humanoid,animator=animator,folder=folder,sets={idle={},walk={},run={}},requested={},resolved={},retried={},current=nil}
	local isR15=humanoid.RigType==Enum.HumanoidRigType.R15
	function self:Load(state,asset,source,first)
		if self.destroyed or not self.model.Parent then return end
		if not id(asset)then return end
		for _,candidate in ipairs(self.sets[state])do if candidate.id==asset then return candidate end end
		local animation=Instance.new("Animation");animation.Name=state.."_"..asset;animation.AnimationId="rbxassetid://"..asset;animation.Parent=self.folder
		local ok,track=pcall(function()return self.animator:LoadAnimation(animation)end)
		if not ok then animation:Destroy();self.model:SetAttribute("ProbaAnimationError",tostring(track):sub(1,180));return end
		track.Looped=true;track.Priority=if state=="idle"then Enum.AnimationPriority.Idle else Enum.AnimationPriority.Movement
		local candidate={id=asset,track=track,source=source,state=state}
		if first then table.insert(self.sets[state],1,candidate)else table.insert(self.sets[state],candidate)end
		return candidate
	end
	function self:Repair(state)
		local asset=self.requested[state];if not asset or self.resolved[state]then return end
		local repaired=Driver.ResolveContainer(asset,state)
		if self.destroyed or not self.model.Parent then return end
		for _,clip in ipairs(repaired)do self:Load(state,clip,"avatar",true)end
		self.resolved[state]=#repaired>0
		if not self.resolved[state]and not self.retried[state]then self.retried[state]=true;task.delay(5,function()if self.model.Parent then self:Repair(state)end end)end
	end
	function self:Update(speed)
		local state=if speed<.35 then"idle"elseif speed>13 then"run"else"walk"
		local selected
		for _,candidate in ipairs(self.sets[state])do if candidate.track.Length>0 then selected=candidate;break end end
		selected=selected or self.sets[state][1]
		if not selected then self.model:SetAttribute("ProbaNativeActive",false);self.model:SetAttribute("ProbaAnimationStatus","procedural / "..state);return end
		if self.current~=selected then
			local phase=if self.current and self.current.track.Length>0 then self.current.track.TimePosition/self.current.track.Length else 0
			if self.current then self.current.track:Stop(.18)end
			self.current=selected;selected.track:Play(.18)
			if selected.track.Length>0 and state~="idle"then selected.track.TimePosition=(phase%1)*selected.track.Length end
		elseif not selected.track.IsPlaying then selected.track:Play(.18)end
		local scale=math.clamp((self.humanoid.HipHeight or 2)/2,.6,1.8)
		selected.track:AdjustSpeed(if state=="idle"then 1 else math.clamp(speed/((if state=="run"then 16 else 8)*scale),.4,1.9))
		local active=selected.track.IsPlaying and selected.track.Length>0
		self.model:SetAttribute("ProbaNativeActive",active)
		self.model:SetAttribute("ProbaAnimationStatus",(if active then selected.source else"loading").." / "..state)
		self.model:SetAttribute("ProbaPlayingClip",selected.id)
	end
	function self:Destroy()
		self.destroyed=true
		if self.running then self.running:Disconnect()end
		for _,set in pairs(self.sets)do for _,c in ipairs(set)do pcall(function()c.track:Stop(.1)end)end end
		if self.folder.Parent then self.folder:Destroy()end
		Driver.controllers[model]=nil
	end
	for state,field in pairs(fields)do
		local requested=description and id(description[field]);self.requested[state]=requested
		if requested then self:Load(state,requested,"avatar")end
		for _,asset in ipairs(captured and captured[state]or{})do self:Load(state,asset,"avatar")end
		if isR15 then for _,asset in ipairs(defaults[state])do self:Load(state,asset,"Roblox default")end end
		model:SetAttribute("Proba"..state:sub(1,1):upper()..state:sub(2).."Requested",requested or 0)
	end
	self.running=humanoid.Running:Connect(function(speed)self:Update(speed)end)
	Driver.controllers[model]=self;self:Update(0)
	task.delay(1.5,function()
		if not model.Parent then return end
		for state,requested in pairs(self.requested)do
			local direct
			for _,candidate in ipairs(self.sets[state])do if candidate.id==requested then direct=candidate;break end end
			if requested and(not direct or direct.track.Length==0)then task.spawn(function()if model.Parent then self:Repair(state)end end)end
		end
	end)
	return self
end
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
	elapsed+=dt;if elapsed<.2 then return end;elapsed=0
	for model,controller in pairs(Driver.controllers)do
		local root=model:FindFirstChild("HumanoidRootPart")
		if not model.Parent or not root then controller:Destroy();continue end
		local v=root.AssemblyLinearVelocity;controller:Update(Vector3.new(v.X,0,v.Z).Magnitude)
	end
end)
return Driver

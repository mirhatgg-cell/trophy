-- Minimal services for executing the actual authoritative server scripts outside Roblox.
-- This deliberately does not simulate physics, rendering, avatar APIs or the Studio engine.
local clock = 100
local guid = 0
local studio = true
local assertions = 0
local function expect(value, reason) assertions += 1; assert(value, reason) end
local function signal()
	local s = { listeners = {} }
	function s:Connect(fn) table.insert(self.listeners, fn); return { Disconnect = function() end } end
	function s:Fire(...) for _, fn in ipairs(self.listeners) do fn(...) end end
	return s
end
local vectorMeta = {}
vectorMeta.__index = function(v, key) if key == "Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end end
vectorMeta.__add = function(a,b) return setmetatable({X=a.X+b.X,Y=a.Y+b.Y,Z=a.Z+b.Z},vectorMeta) end
vectorMeta.__sub = function(a,b) return setmetatable({X=a.X-b.X,Y=a.Y-b.Y,Z=a.Z-b.Z},vectorMeta) end
vectorMeta.__mul = function(a,b)
	if type(a)=="number"then a,b=b,a end
	return setmetatable({X=a.X*(if type(b)=="number"then b else b.X),Y=a.Y*(if type(b)=="number"then b else b.Y),Z=a.Z*(if type(b)=="number"then b else b.Z)},vectorMeta)
end
local Vector = {new = function(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vectorMeta) end}
local cfMeta = {}
local CF = {}
function CF.new(x,y,z) return setmetatable({Position=if type(x)=="table" then x else Vector.new(x,y,z)},cfMeta) end
function CF.Angles() return CF.new() end
function CF.lookAt(pos) return CF.new(pos) end
cfMeta.__mul = function(a,b) return CF.new(a.Position+b.Position) end
cfMeta.__index = {PointToWorldSpace=function(a,b)return a.Position+b end,PointToObjectSpace=function(a,b)return b-a.Position end}
local function enumTable(name) return setmetatable({}, {__index=function(t,k)local v=name.."."..k;rawset(t,k,v);return v end}) end
local enum=setmetatable({}, {__index=function(t,k)local v=enumTable(k);rawset(t,k,v);return v end})
local allNodes={}
local methods={}
local nodeMeta={}
nodeMeta.__index=function(n,k)
	if k=="Parent" then return rawget(n,"_parent") end
	if k=="CFrame" then return rawget(n,"_cframe") end
	if methods[k] then return methods[k] end
	for _,c in ipairs(n.children) do if c.Name==k then return c end end
	return nil
end
nodeMeta.__newindex=function(n,k,v)
	if k=="Parent" then
		local old=rawget(n,"_parent");if old then local i=table.find(old.children,n);if i then table.remove(old.children,i) end end
		rawset(n,"_parent",v);if v then table.insert(v.children,n) end
	elseif k=="CFrame" then rawset(n,"_cframe",v);rawset(n,"Position",v.Position)
	else rawset(n,k,v) end
end
local function node(cls,name,parent)
	local n=setmetatable({ClassName=cls,Name=name or cls,children={},attributes={}},nodeMeta)
	if cls=="RemoteEvent" then n.OnServerEvent=signal();n.sent={} end
	if cls=="ProximityPrompt" then n.Triggered=signal() end
	if cls=="Player" then n.CharacterAdded=signal() end
	if cls=="Model" or cls=="Part" then n.CFrame=CF.new() end
	n.Parent=parent;table.insert(allNodes,n);return n
end
function methods:IsA(cls) return self.ClassName==cls or (cls=="BasePart" and (self.ClassName=="Part" or self.ClassName=="Seat")) end
function methods:GetChildren() return table.clone(self.children) end
function methods:GetDescendants() local out={};for _,c in ipairs(self.children) do table.insert(out,c);for _,d in ipairs(c:GetDescendants()) do table.insert(out,d) end end;return out end
function methods:FindFirstChild(name,recursive) for _,c in ipairs(self.children) do if c.Name==name then return c end end;if recursive then for _,c in ipairs(self.children) do local v=c:FindFirstChild(name,true);if v then return v end end end;return nil end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name),"Mock missing child "..name) end
function methods:FindFirstChildOfClass(cls) for _,c in ipairs(self.children) do if c.ClassName==cls then return c end end;return nil end
function methods:SetAttribute(k,v) self.attributes[k]=v end
function methods:GetAttribute(k) return self.attributes[k] end
function methods:GetPropertyChangedSignal(k)
	self.propertySignals=self.propertySignals or {};self.propertySignals[k]=self.propertySignals[k] or signal();return self.propertySignals[k]
end
function methods:Destroy() self.Parent=nil end
function methods:Clone()
	local n=node(self.ClassName,self.Name)
	for k,v in pairs(self.attributes)do n.attributes[k]=v end
	for k,v in pairs(self) do if k~="children" and k~="_parent" and k~="attributes" and k~="Triggered" and k~="OnServerEvent" and k~="sent" then n[k]=v end end
	for _,c in ipairs(self.children) do local copy=c:Clone();copy.Parent=n end
	if self.PrimaryPart then n.PrimaryPart=n:FindFirstChild(self.PrimaryPart.Name,true) end
	return n
end
function methods:PivotTo(cf)
	local delta=cf.Position-self:GetPivot().Position
	for _,part in ipairs(self:GetDescendants())do if part:IsA("BasePart")and part.CFrame then part.CFrame=CF.new(part.CFrame.Position+delta)end end
	self.CFrame=cf
end
function methods:GetPivot() return if self.PrimaryPart then self.PrimaryPart.CFrame else self.CFrame end
function methods:GetScale()return self.testScale or 1 end
function methods:ScaleTo(scale)
	local factor=scale/self:GetScale();local pivot=self:GetPivot().Position
	for _,p in ipairs(self:GetDescendants())do if p:IsA("BasePart")then if p.Size then p.Size=p.Size*factor end;if p.CFrame then p.CFrame=CF.new(pivot+(p.Position-pivot)*factor)end end end
	self.testScale=scale
end
function methods:EquipTool(tool) tool.Parent=self.Parent end
function methods:MoveTo() end
function methods:FireClient(player,packet) table.insert(self.sent,{player=player,packet=packet}) end
function methods:FireAllClients(packet) table.insert(self.sent,{player="all",packet=packet}) end
function methods:SetNetworkOwner() end

local gameMock=node("DataModel","game")
gameMock.JobId="test";gameMock.CreatorId=99999;gameMock.CreatorType=enum.CreatorType.User
local services={}
for _,name in ipairs({"Players","ReplicatedStorage","ServerStorage","ServerScriptService","Workspace","DataStoreService","HttpService","RunService","TweenService","PhysicsService","SoundService","Debris","MarketplaceService","CollectionService"}) do services[name]=node(name,name,gameMock) end
services.CollectionService.AddTag=function()end
function gameMock:GetService(name) return assert(services[name],"Unexpected service "..name) end
function gameMock:BindToClose(fn) self.close=fn end
services.RunService.IsStudio=function()return studio end
local fakeStore={records={},fail=false}
function fakeStore:UpdateAsync(key,fn)
	if self.fail then error("Simulated DataStore outage") end
	local nextValue=fn(self.records[key]);if nextValue~=nil then self.records[key]=nextValue end;return nextValue
end
services.DataStoreService.GetDataStore=function()
	if studio then error("Unpublished Studio cannot construct a DataStore") end
	return fakeStore
end
services.HttpService.GenerateGUID=function()guid+=1;return "uid_"..guid end
local function deepCopy(value)
	if type(value)~="table" then return value end
	local out={};for k,v in pairs(value)do out[k]=deepCopy(v)end;return out
end
services.HttpService.JSONEncode=function(_,value)return deepCopy(value)end
services.HttpService.JSONDecode=function(_,value)return deepCopy(value)end
services.TweenService.Create=function()return {Play=function()end}end
services.PhysicsService.RegisterCollisionGroup=function()end
services.PhysicsService.CollisionGroupSetCollidable=function()end
local players=services.Players
players.PlayerAdded=signal();players.PlayerRemoving=signal()
function players:GetPlayers()return self:GetChildren()end
function players:GetPlayerByUserId(id)for _,p in ipairs(self:GetChildren())do if p.UserId==id then return p end end;return nil end
function players:GetFriendsAsync()error("Avatar API unavailable in unit test")end
local rep=services.ReplicatedStorage
local shared=node("Folder","Shared",rep)
local models=node("Folder","ItemModels",rep)
local net=node("Folder","Network",rep)
local remote=node("RemoteEvent","Action",net);local state=node("RemoteEvent","State",net)
local buildings=node("Folder","Buildings",services.ServerStorage)
for i=1,3 do
	local b=node("Model","Level"..i,buildings);b.PrimaryPart=node("Part","Anchor",b)
	local p=node("Part","Interaction",b);node("ProximityPrompt","AppraisalPrompt",p)
	node("Seat","AppraiserSeat",b)
	for slot=1,40 do local marker=node("Part",string.format("CollectionSlot_%02d",slot),b);marker.CFrame=CF.new((slot%4)*3,4+math.floor(slot/4)*2,-10)end
	local reg=node("Part","Registry",b);node("ProximityPrompt","RegistryPrompt",reg)
end
local templates=node("Folder","Templates",services.ServerStorage);node("Model","BaconCustomer",templates)
local ws=services.Workspace;local plotFolder=node("Folder","Plots",ws);node("Folder","Customers",ws)
for i=1,6 do local plot=node("Model",string.format("Plot%02d",i),plotFolder);local a=node("Part","Anchor",plot);a.CFrame=CF.new((i-1)*200,0,0);node("Model","Building",plot) end
local town=node("Model","Town",ws);local broker=node("Part","BrokerAnchor",town);broker.CFrame=CF.new(0,3,1000);node("ProximityPrompt","BrokerPrompt",broker)
local delayed={}
local taskMock={spawn=function()end,wait=function()error("Unexpected yielding path in synchronous server-flow test")end,
	delay=function(seconds,fn)table.insert(delayed,{due=clock+seconds,fn=fn})end}
local env=setmetatable({game=gameMock,workspace=ws,Vector3=Vector,CFrame=CF,Enum=enum,
	Instance={new=function(cls)return node(cls,cls)end},Random={new=function()return {seed=12345,NextInteger=function(self,a,b)self.seed=(self.seed*48271)%2147483647;return a+self.seed%(b-a+1) end,NextNumber=function(_,a,b)return if a then (a+b)/2 else .5 end}end},
	task=taskMock,Color3={fromRGB=function(r,g,b)return {r=r,g=g,b=b}end},TweenInfo={new=function()return {}end},
	UDim2={fromOffset=function()return {}end,new=function()return {}end},os=setmetatable({clock=function()return clock end},{__index=os}),warn=function(...) print("test warning:",...)end}, {__index=getfenv()})
local modules,cache={},{}
local function register(path,fn,parent,name)
	local scriptNode=node(path=="Game" and "Script" or "ModuleScript",name or path,parent)
	scriptNode.path=path;modules[path]={fn=fn,node=scriptNode}
	return scriptNode
end
env.require=function(scriptNode)
	local key=scriptNode.path
	if cache[key] then return cache[key] end
	local record=assert(modules[key],"Missing module "..tostring(key))
	local moduleEnv=setmetatable({script=record.node},{__index=env});setfenv(record.fn,moduleEnv)
	local result=record.fn();cache[key]=result;return result
end

-- tools/run_checks.py appends module functions, then server_flow.spec.luau.

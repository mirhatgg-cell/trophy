-- Constructor/event smoke harness. It exercises the real client code; it is not a Roblox renderer.
local dimensions={w=1458,h=680}
local U={new=function(scale,offset)return{Scale=scale or 0,Offset=offset or 0}end}
local D={new=function(xs,xo,ys,yo)return{X=U.new(xs,xo),Y=U.new(ys,yo)}end}
D.fromOffset=function(x,y)return D.new(0,x,0,y)end;D.fromScale=function(x,y)return D.new(x,0,y,0)end
local colorMeta={};colorMeta.__index={Lerp=function(a,b,t)return setmetatable({R=a.R+(b.R-a.R)*t,G=a.G+(b.G-a.G)*t,B=a.B+(b.B-a.B)*t},colorMeta)end}
local Color={new=function(r,g,b)return setmetatable({R=r or 0,G=g or 0,B=b or 0},colorMeta)end}
Color.fromRGB=function(r,g,b)return Color.new(r/255,g/255,b/255)end
Color.fromHSV=function(h,s,v)local k=math.floor(h*6);local f=h*6-k;local p=v*(1-s);local q=v*(1-f*s);local t=v*(1-(1-f)*s);local rgb=({{v,t,p},{q,v,p},{p,v,t},{p,q,v},{t,p,v},{v,p,q}})[k%6+1];return Color.new(unpack(rgb))end
local guiClasses={Frame=true,CanvasGroup=true,TextLabel=true,TextButton=true,TextBox=true,ScrollingFrame=true,ImageLabel=true,ViewportFrame=true}
local events={MouseEnter=true,MouseLeave=true,Activated=true,InputBegan=true,InputChanged=true,InputEnded=true,ChildAdded=true,DescendantAdded=true,CharacterAdded=true}
local originalIndex=nodeMeta.__index
nodeMeta.__index=function(n,k)
	if k=="Visible"or k=="Enabled"then return true end
	if k=="BackgroundTransparency"or k=="Rotation"or k=="ZIndex"then return 0 end
	if k=="Size"then return D.fromOffset(100,100)end
	if k=="Position"then return D.fromOffset(0,0)end
	if k=="AnchorPoint"or k=="CanvasPosition"then return Vector.new()end
	if k=="Text"then return""end
	if events[k]then local s=signal();rawset(n,k,s);return s end
	if k=="AbsoluteSize"then
		if n.ClassName=="ScreenGui"then return Vector.new(dimensions.w,dimensions.h)end
		local p=n.Parent;local size=p and p.AbsoluteSize or Vector.new(dimensions.w,dimensions.h)
		local scale=n:FindFirstChildOfClass("UIScale");local f=scale and scale.Scale or 1
		return Vector.new((size.X*n.Size.X.Scale+n.Size.X.Offset)*f,(size.Y*n.Size.Y.Scale+n.Size.Y.Offset)*f)
	end
	if k=="AbsolutePosition"then
		if n.ClassName=="ScreenGui"then return Vector.new()end
		local p=n.Parent;local pos=p and p.AbsolutePosition or Vector.new();local size=p and p.AbsoluteSize or Vector.new(dimensions.w,dimensions.h)
		return Vector.new(pos.X+size.X*n.Position.X.Scale+n.Position.X.Offset-n.AnchorPoint.X*n.AbsoluteSize.X,pos.Y+size.Y*n.Position.Y.Scale+n.Position.Y.Offset-n.AnchorPoint.Y*n.AbsoluteSize.Y)
	end
	return originalIndex(n,k)
end
local originalIsA=methods.IsA
function methods:IsA(class)if class=="GuiObject"then return guiClasses[self.ClassName]==true end;return originalIsA(self,class)end
function methods:IsDescendantOf(parent)local p=self;while p do if p==parent then return true end;p=p.Parent end;return false end
function methods:ClearAllChildren()for _,c in ipairs(self:GetChildren())do c:Destroy()end end
function methods:Destroy()for _,c in ipairs(self:GetChildren())do c:Destroy()end;self.Parent=nil end
function methods:CaptureFocus()services.UserInputService.focused=self end
function methods:GetScale()return 1 end
env.UDim=U;env.UDim2=D;env.Vector2=Vector;env.Color3=Color
env.ColorSequence={new=function(...)return{...}end};env.ColorSequenceKeypoint={new=function(...)return{...}end}
env.NumberSequence={new=function(...)return{...}end};env.NumberSequenceKeypoint={new=function(...)return{...}end}
cfMeta.__index.RightVector=Vector.new(1,0,0)
cfMeta.__index.VectorToObjectSpace=function(_,v)return v end
CF.fromAxisAngle=function(_,angle)local cf=CF.new();cf.angle=angle;return cf end
local oldMultiply=cfMeta.__mul
cfMeta.__mul=function(a,b)local cf=oldMultiply(a,b);cf.angle=(a.angle or 0)+(b.angle or 0);return cf end
services.TweenService.Create=function(_,o,_,properties)return{Play=function()for k,v in pairs(properties)do o[k]=v end end,Cancel=function()end}end
for _,name in ipairs({"UserInputService","StarterGui"})do services[name]=node(name,name,gameMock)end
services.TextService=node("TextService","TextService",gameMock)
local previewFontMetrics={}
services.TextService.GetTextSize=function(_,value,size,font)
	local metrics=previewFontMetrics[font]
	if metrics and metrics[value]then return Vector.new(metrics[value]*size,size)end
	local factor=if font==enum.Font.Michroma then .72 elseif font==enum.Font.Bangers then .50 else .59
	return Vector.new((utf8.len(value)or #value)*size*factor,size)
end
services.UserInputService.GetFocusedTextBox=function(self)return self.focused end
services.StarterGui.SetCoreGuiEnabled=function()end
services.RunService.RenderStepped=signal();services.RunService.PreSimulation=signal()
local tagSignals={}
services.CollectionService.GetTagged=function()return{}end
services.CollectionService.GetInstanceAddedSignal=function(_,tag)tagSignals[tag]=tagSignals[tag]or signal();return tagSignals[tag]end
services.CollectionService.GetInstanceRemovedSignal=function()return signal()end
local localPlayer=node("Player","TestPlayer",players);localPlayer.UserId=123;localPlayer.DisplayName="PROBA Player";players.LocalPlayer=localPlayer
localPlayer.Character=node("Model","Character",ws);node("Part","Head",localPlayer.Character)
localPlayer.PlayerGui=node("PlayerGui","PlayerGui",localPlayer)
net.Action.FireServer=function(_,name,packet)net.Action.sent=net.Action.sent or{};table.insert(net.Action.sent,{name=name,data=packet})end
net.State.OnClientEvent=signal()
taskMock.defer=function(fn)fn()end
ws.CurrentCamera=node("Camera","Camera",ws);ws.CurrentCamera.CFrame=CF.new(0,8,12);ws.CurrentCamera.ViewportSize=Vector.new(dimensions.w,dimensions.h)
local clientScripts=node("Folder","StarterPlayerScripts",gameMock)
local function shown(n)
	if not n:IsDescendantOf(localPlayer.PlayerGui)then return false end
	local p=n;while p do if guiClasses[p.ClassName]and p.Visible==false then return false end;p=p.Parent end
	return true
end
local function click(value)
	for _,n in ipairs(allNodes)do if n.ClassName=="TextButton"and n.Text==value and shown(n)then n.Activated:Fire();return n end end
	error("Visible button not found: "..value)
end
local function clickCard(label)
	for _,n in ipairs(allNodes)do if n.ClassName=="TextButton"and shown(n)then
		for _,child in ipairs(n:GetDescendants())do if child.ClassName=="TextLabel"and child.Text==label then n.Activated:Fire();return n end end
	end end
	error("Visible card not found: "..label)
end
local function json(v)
	local typ=type(v);if typ=="string"then return '"'..v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')..'"'end
	if typ=="number"or typ=="boolean"then return tostring(v)end;if typ=="nil"then return"null"end
	local out={};if #v>0 then for _,a in ipairs(v)do table.insert(out,json(a))end;return"["..table.concat(out,",").."]"end
	for k,a in pairs(v)do table.insert(out,json(tostring(k))..":"..json(a))end;return"{"..table.concat(out,",").."}"
end
local captureIds={};local nextCaptureId=0
local function capture(name,compactPaint)
	local objects={}
	for _,n in ipairs(allNodes)do
		if guiClasses[n.ClassName]and shown(n)then
			local artAncestor=n.Parent;local insideArt=false
			while artAncestor do
				if artAncestor:GetAttribute("ArtworkKey")and(compactPaint or artAncestor:GetAttribute("ArtworkBackend")=="EditableImage")then insideArt=true;break end
				artAncestor=artAncestor.Parent
			end
			if insideArt then continue end
			local p,s=n.AbsolutePosition,n.AbsoluteSize
			local cx,cy=p.X+s.X/2,p.Y+s.Y/2;local rotation=n.Rotation;local rotator=n.Parent
			while rotator do
				if guiClasses[rotator.ClassName]and rotator.Rotation~=0 then
					local a,b=rotator.AbsolutePosition,rotator.AbsoluteSize;local x,y=a.X+b.X/2,a.Y+b.Y/2
					local angle=math.rad(rotator.Rotation);local dx,dy=cx-x,cy-y
					cx=x+dx*math.cos(angle)-dy*math.sin(angle);cy=y+dx*math.sin(angle)+dy*math.cos(angle);rotation+=rotator.Rotation
				end
				rotator=rotator.Parent
			end
			local color=n.BackgroundColor3;local ink=n.TextColor3;local r=n:FindFirstChildOfClass("UICorner")
			local clip={x=0,y=0,w=dimensions.w,h=dimensions.h};local ancestor=n.Parent
			while ancestor do
				if ancestor.ClassName=="ScrollingFrame"or ancestor.ClipsDescendants==true then
					local a,b=ancestor.AbsolutePosition,ancestor.AbsoluteSize
					local right=math.min(clip.x+clip.w,a.X+b.X);local bottom=math.min(clip.y+clip.h,a.Y+b.Y)
					clip.x=math.max(clip.x,a.X);clip.y=math.max(clip.y,a.Y);clip.w=math.max(0,right-clip.x);clip.h=math.max(0,bottom-clip.y)
				end
				ancestor=ancestor.Parent
			end
			local border=n:FindFirstChildOfClass("UIStroke")
			local g=n:FindFirstChildOfClass("UIGradient")
			local opacity=1;local group=n
			while group do
				if group.ClassName=="CanvasGroup"then opacity*=1-(group.GroupTransparency or 0)end
				group=group.Parent
			end
			if not captureIds[n]then nextCaptureId+=1;captureIds[n]=nextCaptureId end
			table.insert(objects,{id=captureIds[n],nodeName=n.Name,class=n.ClassName,x=cx-s.X/2,y=cy-s.Y/2,w=s.X,h=s.Y,text=if n.ClassName=="TextBox"and n.Text==""then n.PlaceholderText or""else n.Text,size=n.TextSize or 12,
				alpha=n.BackgroundTransparency,color=color,ink=ink,radius=r and(r.CornerRadius.Offset+r.CornerRadius.Scale*math.min(s.X,s.Y))or 0,
				z=n.ZIndex,rotation=rotation,clip=clip,border=border and border.Color,thickness=border and border.Thickness or 0,align=n.TextXAlignment,font=n.Font,
				textAlpha=n.TextTransparency or 0,textStroke=n.TextStrokeColor3,strokeAlpha=n.TextStrokeTransparency or 1,
				gradient=g and{colors=g.Color,alpha=g.Transparency,rotation=g.Rotation or 0},wrap=n.TextWrapped==true,
				artwork=n:GetAttribute("ArtworkKey"),backend=n:GetAttribute("ArtworkBackend"),groupAlpha=1-opacity})
		end
	end
	print("UI_SNAPSHOT "..json({name=name,width=dimensions.w,height=dimensions.h,objects=objects}))
end

-- Three independent identity layers, with original painted anime artwork.
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local Rep=game:GetService("ReplicatedStorage")
local Identity=require(Rep.Shared.Identity)
local Decor=require(Rep.Shared.Decor)
local Config=require(Rep.Shared.Config)
local Art=require(script.Parent.Artwork)
local Motion=require(script.Parent.CosmeticMotion)
local Typography=require(script.Parent.NameTypography)
local FX={}
local actors,portraits={},{}
local WHITE=Color3.fromRGB(241,248,255)
local INK=Color3.fromRGB(7,10,24)
local function new(class,props,parent)local o=Instance.new(class);for k,v in pairs(props)do o[k]=v end;o.Parent=parent;return o end
local function color(rgb)return Color3.fromRGB(unpack(rgb))end
local function round(o,r)new("UICorner",{CornerRadius=UDim.new(0,r)},o)end
local function canvas(parent,name,w,h,clip)
	return new("Frame",{Name=name,BackgroundTransparency=1,Size=UDim2.fromOffset(w,h),ClipsDescendants=clip==true},parent)
end
local function rect(parent,w,h,c,alpha)
	return new("Frame",{BackgroundColor3=c,BackgroundTransparency=alpha or 0,BorderSizePixel=0,AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(w,h)},parent)
end
local function at(o,x,y)o.Position=UDim2.fromOffset(x,y);return o end
local function label(parent,value,size,c,w,h)
	return new("TextLabel",{BackgroundTransparency=1,Text=value,TextColor3=c,TextSize=size,Font=Enum.Font.GothamBold,
		TextStrokeColor3=INK,TextStrokeTransparency=.18,TextTruncate=Enum.TextTruncate.AtEnd,
		TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.fromOffset(w,h)},parent)
end
local function animate(root,step)step(0);table.insert(actors,{root=root,step=step})end

function FX.Nametag(parent,id,name,w,h,centered)
	h=h or 48;local d=Identity.ById[id]or Identity.ById.tag_plain
	local root=canvas(parent,"NicknameEffect",w,h);root:SetAttribute("NametagId",d.id)
	local art=d.style~="plain"and Art.Draw(root,"aura_"..d.style,w+8,h+17)or nil
	if art then art.Position=UDim2.fromOffset(-4,-8);art.GroupTransparency=.58 end
	local _,effect=Motion.Build(root,d.style,w,h,false)
	local _,letters=Typography.Build(root,d,name,w,h,centered==true)
	if d.style=="plain"then return root end
	animate(root,function(t)
		effect(t);letters(t)
	end)
	return root
end

function FX.Title(parent,id,w,centered)
	local d=Config.Titles[1];for _,v in ipairs(Config.Titles)do if v.id==id then d=v;break end end
	local styles={eye={"volt",{108,226,255}},fake={"vesper",{238,130,255}},diplomat={"tide",{116,229,244}},collector={"ember",{255,217,128}},archivist={"astrolabe",{191,172,255}}}
	local style=styles[d.id];local c=style and color(style[2])or Color3.fromRGB(179,194,215)
	local root=canvas(parent,"TitleEffect",w,27);root:SetAttribute("TitleId",d.id)
	local title=label(root,d.name,10,c,w-12,23);title.Name="TitleLabel";title.Position=UDim2.fromOffset(6,0)
	if style then local face=Identity.Typeface(style[1],d.name);title.Font=Enum.Font[face]end
	if centered then title.TextXAlignment=Enum.TextXAlignment.Center end
	if not style then return root end
	local geometry,step=Motion.Build(root,style[1],math.min(w-4,174),24,true)
	geometry.Position=UDim2.fromOffset(if centered then(w-math.min(w-4,174))/2 else 0,0)
	-- Keep the subtitle above its independent animated geometry.
	title.ZIndex=2
	animate(root,step)
	return root
end

function FX.Background(parent,id,w,h)
	local d=Decor.ById[id]or Decor.ById.card_paper;local style=Identity.BackgroundStyles[d.id]or"neutral"
	local root=canvas(parent,"CardArtwork",w,h,true)
	local base=at(rect(root,w,h,Color3.fromRGB(17,23,39)),w/2,h/2)
	if style=="neutral"then
		base.BackgroundColor3=WHITE
		new("UIGradient",{Color=ColorSequence.new(Color3.fromRGB(25,34,52),Color3.fromRGB(16,23,39)),Rotation=12},base)
		return root
	end
	local painting=Art.Draw(root,"banner_"..style,w+16,h+8)
	if painting then painting.Position=UDim2.fromOffset(-8,-4)end
	local _,step=Motion.Background(root,style,w,h)
	-- A restrained directional scrim preserves text contrast over the illustration.
	local scrim=at(rect(root,w,h,INK),w/2,h/2)
	new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.12),NumberSequenceKeypoint.new(.45,.58),NumberSequenceKeypoint.new(1,.93)})},scrim)
	animate(root,step)
	return root
end

function FX.Frame(parent,id,cx,cy,radius,w,h)
	local d=Decor.ById[id]or Decor.ById.frame_plain;local style=Identity.FrameStyles[d.id]or"plain";local c=color(d.color)
	local root=canvas(parent,"AvatarFrameArtwork",w,h)
	if style=="plain"then
		local rim=at(rect(root,radius*2+3,radius*2+3,c,1),cx,cy);round(rim,100)
		new("UIStroke",{Color=c,Thickness=1,Transparency=.22},rim);return root
	end
	local size=(radius*2+24)*(if style=="wings"then 1.06 else 1)
	local painting=Art.Draw(root,"frame_"..style,size,size)
	if painting then painting.Position=UDim2.fromOffset(cx-size/2,cy-size/2);painting.GroupTransparency=.12 end
	local _,step=Motion.Frame(root,style,cx,cy,radius,w,h)
	animate(root,step)
	return root
end

local function portrait(parent,userId,name,size)
	local circle=rect(parent,size,size,Color3.fromRGB(38,50,73));circle.AnchorPoint=Vector2.new();round(circle,size/2)
	local first=name:sub(1,(utf8.offset(name,2)or(#name+1))-1)
	local initials=label(circle,first:upper(),20,WHITE,size,size);initials.TextXAlignment=Enum.TextXAlignment.Center
	local image=new("ImageLabel",{Name="AvatarPortrait",BackgroundTransparency=1,ImageTransparency=1,Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Crop},circle);round(image,size/2)
	local function apply(url)if image.Parent and type(url)=="string"and url~=""then image.Image=url;image.ImageTransparency=0 end end
	if portraits[userId]then apply(portraits[userId])elseif userId and userId>0 then
		task.spawn(function()
			local ok,url=pcall(function()return Players:GetUserThumbnailAsync(userId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)end)
			if ok then portraits[userId]=url;apply(url)end
		end)
	end
	return circle
end
function FX.Card(parent,options)
	local w,h=options.width or 270,options.height or 88
	local root=new("CanvasGroup",{Name="PlayerIdentityCard",BackgroundTransparency=1,Size=UDim2.fromOffset(w,h),ClipsDescendants=true},parent);round(root,12)
	FX.Background(root,options.card or"card_paper",w,h)
	local size=math.min(50,h-32);local cx,cy=17+size/2,h/2
	local avatar=portrait(root,options.userId,options.name or"Player",size);avatar.Position=UDim2.fromOffset(17,(h-size)/2)
	FX.Frame(root,options.frame or"frame_plain",cx,cy,size/2,w,h)
	local x=17+size+17;local width=w-x-12
	local tagWidth=math.min(width,math.max(110,(utf8.len(options.name or"Player")or 12)*10+32))
	local tag=FX.Nametag(root,options.nametag or"tag_plain",options.name or"Player",tagWidth,46);tag.Position=UDim2.fromOffset(x,math.max(1,h*.5-32))
	local title=FX.Title(root,options.title or"trainee",width);title.Position=UDim2.fromOffset(x,h*.5+12)
	return root
end
function FX.World(parent,options)
	local root=canvas(parent,"WorldIdentity",230,80)
	local width=math.min(224,math.max(110,(utf8.len(options.name)or 12)*10+32))
	local tag=FX.Nametag(root,options.nametag or"tag_plain",options.name,width,50,true);tag.Position=UDim2.fromOffset((230-width)/2,0)
	local title=FX.Title(root,options.title or"trainee",218,true);title.Position=UDim2.fromOffset(6,52)
	return root
end
local function isVisible(root)
	local p=root
	while p do
		if p:IsA("GuiObject")and not p.Visible then return false end
		if p:IsA("LayerCollector")and not p.Enabled then return false end
		if p:IsA("ScrollingFrame")then
			local a,b=root.AbsolutePosition,root.AbsoluteSize;local c,d=p.AbsolutePosition,p.AbsoluteSize
			if a.Y+b.Y<c.Y or a.Y>c.Y+d.Y or a.X+b.X<c.X or a.X>c.X+d.X then return false end
		end
		if p:IsA("BillboardGui")then
			local part=p.Adornee or p.Parent;local camera=workspace.CurrentCamera
			if camera and part and part:IsA("BasePart")and(part.Position-camera.CFrame.Position).Magnitude>65 then return false end
		end
		p=p.Parent
	end
	return true
end
local elapsed=0
RunService.RenderStepped:Connect(function(dt)
	elapsed+=dt;if elapsed<1/30 then return end;elapsed=0
	local now=os.clock()
	for i=#actors,1,-1 do local a=actors[i];if not a.root.Parent then table.remove(actors,i)elseif isVisible(a.root)then a.step(now)end end
end)
return FX

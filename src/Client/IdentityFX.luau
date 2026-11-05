-- Three independent identity layers, with original painted anime artwork.
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local Rep=game:GetService("ReplicatedStorage")
local Identity=require(Rep.Shared.Identity)
local Decor=require(Rep.Shared.Decor)
local Config=require(Rep.Shared.Config)
local Art=require(script.Parent.Artwork)
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
local function gradient(o,a,b)
	if o:IsA("TextLabel")then o.TextColor3=WHITE else o.BackgroundColor3=WHITE end
	return new("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,a),ColorSequenceKeypoint.new(.48,WHITE),ColorSequenceKeypoint.new(1,b)})},o)
end
local function animate(root,step)step(0);table.insert(actors,{root=root,step=step})end
local function spark(parent,size,c)
	local root=canvas(parent,"Glint",size*2,size*2)
	local v=at(rect(root,size*.25,size*1.5,c),size,size);v.Rotation=28
	local h=at(rect(root,size*1.1,size*.2,WHITE),size,size);h.Rotation=28
	return root
end
local function particles(parent,style,c,w,h,count)
	local nodes={}
	for i=1,count do
		local p
		if style=="maple"then
			p=canvas(parent,"FallingPetal",8,9)
			for j=1,3 do local leaf=at(rect(p,3,5,c),1+j*1.7,4);round(leaf,3);leaf.Rotation=-50+j*25 end
		elseif style=="tide"or style=="tidal"then
			p=rect(parent,2+i%3,3+i%3,c,.2);round(p,8)
		elseif style=="vesper"or style=="rift"or style=="eclipse"then
			p=rect(parent,2,5,c,.28);p.Rotation=40
		else p=spark(parent,1.8+i%3,c)end
		nodes[i]=p
	end
	return function(t)
		for i,p in ipairs(nodes)do
			local u=(t*(if style=="ember"or style=="forge"then .19 else .07)+i/count)%1
			local x=((i*47)%101)/101*w
			local y=h*(1-u)
			if style=="maple"or style=="velvet"then x+=math.sin(t+i)*7;y=u*h
			elseif style=="volt"then x=(i%2==0 and .1 or .9)*w+math.sin(t*9+i)*7;y=(i/count)*h
			elseif style=="prism"or style=="astrolabe"then local a=t*.25+i*math.pi*.71;x=w*.5+math.cos(a)*w*.44;y=h*.5+math.sin(a)*h*.39
			else x+=math.sin(t*.7+i)*5 end
			p.Position=UDim2.fromOffset(x,y);p.Rotation=math.sin(t+i)*25
			if p:IsA("Frame")and p.Name~="Glint"and p.Name~="FallingPetal"then p.BackgroundTransparency=.1+math.sin(u*math.pi)^2*.55 end
		end
	end
end

function FX.Nametag(parent,id,name,w,h)
	h=h or 48;local d=Identity.ById[id]or Identity.ById.tag_plain;local c=color(d.color)
	local root=canvas(parent,"NicknameEffect",w,h);root:SetAttribute("NametagId",d.id)
	local art=d.style~="plain"and Art.Draw(root,"aura_"..d.style,w+8,h+17)or nil
	local motes=if d.style~="plain"then particles(root,d.style,c,w,h,6)else function()end
	local shadow=label(root,name,17,INK,w-16,30);shadow.Name="NicknameShadow";shadow.Position=UDim2.fromOffset(9,h*.5-13);shadow.TextStrokeTransparency=0
	local nick=label(root,name,17,WHITE,w-16,30);nick.Name="Nickname";nick.Font=Enum.Font.GothamBlack;nick.Position=UDim2.fromOffset(8,h*.5-15)
	local sheen=gradient(nick,if d.style=="plain"then WHITE else c,WHITE)
	animate(root,function(t)
		if art then
			local speed=if d.style=="volt"then 2.4 elseif d.style=="ember"then 1.7 else .75
			local breath=math.sin(t*speed)*.017
			art.Size=UDim2.fromOffset((w+8)*(1+breath),h+17+math.sin(t*speed+.8)*2)
			art.Position=UDim2.fromOffset(-4-breath*w*.5,-8+math.sin(t*.8)*1.2)
			art.Rotation=math.sin(t*.6)*1.4
			art.GroupTransparency=if d.style=="volt"then .02+(math.sin(t*9)^12)*.22 else .04+math.sin(t*.9)^2*.08
		end
		motes(t);sheen.Offset=Vector2.new(math.sin(t*.7)*.42,0)
	end)
	return root
end

function FX.Title(parent,id,w,centered)
	local d=Config.Titles[1];for _,v in ipairs(Config.Titles)do if v.id==id then d=v;break end end
	local styles={eye={"volt",{108,226,255}},fake={"vesper",{238,130,255}},diplomat={"tide",{116,229,244}},collector={"ember",{255,217,128}},archivist={"astrolabe",{191,172,255}}}
	local style=styles[d.id];local c=style and color(style[2])or Color3.fromRGB(179,194,215)
	local root=canvas(parent,"TitleEffect",w,27);root:SetAttribute("TitleId",d.id)
	local flare=style and Art.Draw(root,"aura_"..style[1],math.min(w-4,174),25)or nil
	local title=label(root,d.name,10,c,w-12,23);title.Name="TitleLabel";title.Position=UDim2.fromOffset(6,0)
	if centered then title.TextXAlignment=Enum.TextXAlignment.Center end
	if not style then return root end
	local sheen=gradient(title,c,WHITE)
	-- Keep the small subtitle legible while giving prestige a living crest/glint.
	local seal=spark(root,3,c)
	animate(root,function(t)
		if flare then flare.Position=UDim2.fromOffset(if centered then(w-math.min(w-4,174))/2 else 0,1+math.sin(t)*.6);flare.GroupTransparency=.65+math.sin(t*.7)^2*.13 end
		seal.Position=UDim2.fromOffset(5+((t*.18)%1)*(w-14),18+math.sin(t*2)*2);seal.Rotation=t*25
		sheen.Offset=Vector2.new(math.sin(t*.9)*.55,0)
	end)
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
	-- A restrained directional scrim preserves text contrast over the illustration.
	local scrim=at(rect(root,w,h,INK),w/2,h/2)
	new("UIGradient",{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.12),NumberSequenceKeypoint.new(.45,.58),NumberSequenceKeypoint.new(1,.93)})},scrim)
	local motes=particles(root,if style=="velvet"then"maple"else style,color(d.color):Lerp(WHITE,.45),w,h,5)
	animate(root,function(t)
		if painting then painting.Position=UDim2.fromOffset(-8+math.sin(t*.17)*4,-4+math.cos(t*.13)*2)end
		motes(t*.7)
	end)
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
	local gleams={};for i=1,3 do gleams[i]=spark(root,1.8+i%2,c:Lerp(WHITE,.5))end
	animate(root,function(t)
		if painting then
			painting.Position=UDim2.fromOffset(cx-size/2,cy-size/2+math.sin(t*.7)*.55)
			painting.Rotation=if style=="rift"then math.sin(t*.35)*2 else math.sin(t*.4)*.7
			painting.GroupTransparency=if style=="rift"then .04+math.sin(t*.8)^2*.09 else .02
		end
		for i,p in ipairs(gleams)do local a=t*(if style=="comet"then .6 else .16)+i*math.pi*.7
			p.Position=UDim2.fromOffset(cx+math.cos(a)*(radius+5)-3,cy+math.sin(a)*(radius+5)-3);p.Rotation=t*30
		end
	end)
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
	local tag=FX.Nametag(root,options.nametag or"tag_plain",options.name,width,50);tag.Position=UDim2.fromOffset((230-width)/2,0);tag.Nickname.TextXAlignment=Enum.TextXAlignment.Center
	tag.NicknameShadow.TextXAlignment=Enum.TextXAlignment.Center
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

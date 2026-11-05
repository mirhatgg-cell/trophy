-- Real per-tag fonts and animated letter materials; no common gradient overlay.
local TextService=game:GetService("TextService")
local Identity=require(game.ReplicatedStorage.Shared.Identity)
local Type={}
local WHITE=Color3.fromRGB(241,248,255)
local INK=Color3.fromRGB(7,10,24)
local function new(cls,props,parent)local n=Instance.new(cls);for k,v in pairs(props)do n[k]=v end;n.Parent=parent;return n end
local function text(parent,value,size,font,color,w,h)
	return new("TextLabel",{Name="Glyph",BackgroundTransparency=1,Text=value,TextColor3=color,TextSize=size,Font=font,AutoLocalize=false,
		TextStrokeColor3=INK,TextStrokeTransparency=.18,TextXAlignment=Enum.TextXAlignment.Left,
		Size=UDim2.fromOffset(w,h)},parent)
end
local function characters(value)
	local out={}
	if utf8.graphemes then for first,last in utf8.graphemes(value)do table.insert(out,value:sub(first,last))end
	else for _,code in utf8.codes(value)do
		local cluster=utf8.char(code)
		if code>=0x300 and code<=0x36f and #out>0 then out[#out]..=cluster else table.insert(out,cluster)end
	end end
	return out
end
local function measure(value,size,font)
	local ok,result=pcall(function()return TextService:GetTextSize(value,size,font,Vector2.new(4096,64)).X end)
	return if ok and(result>0 or value=="")then result else (utf8.len(value)or #value)*size*.59
end
local function joinedScript(value)
	for _,c in utf8.codes(value)do if(c>=0x600 and c<=0x8ff)or(c>=0x900 and c<=0xdff)then return true end end
	return false
end
function Type.Build(parent,definition,name,w,h,centered)
	local fontName,treatment=Identity.Typeface(definition.style,name)
	local font=Enum.Font[fontName];local size=18
	local available=math.max(20,w-20)
	local measured=measure(name,size,font)
	if measured>available then size=math.max(10,18*available/measured);measured=measure(name,size,font)end
	local left=if centered then(w-measured)/2 else 9
	local top=h/2-14
	local root=new("Frame",{Name="Nickname",BackgroundTransparency=1,Size=UDim2.fromOffset(w,h)},parent)
	root:SetAttribute("Typeface",fontName);root:SetAttribute("LetterTreatment",treatment)
	root:SetAttribute("DisplayName",name)
	local baseColor=Color3.fromRGB(unpack(definition.color))
	-- Connected scripts retain shaping/ligatures in one TextLabel. Decorative
	-- material changes still run, while the name itself is never scrambled.
	local units=if treatment=="clean"or joinedScript(name)then{name}else characters(name)
	local glyphs={};local prefix="";local previous=0
	for index,character in ipairs(units)do
		prefix..=character;local advance=measure(prefix,size,font)
		local width=measure(character,size,font)+7
		local holder=new("Frame",{Name="Letter_"..index,BackgroundTransparency=1,Position=UDim2.fromOffset(left+previous,top),Size=UDim2.fromOffset(width,30)},root)
		local shadow=text(holder,character,size,font,INK,width,30);shadow.Name="InkShadow";shadow.Position=UDim2.fromOffset(1,1)
		local back=text(holder,character,size,font,baseColor,width,30);back.Name="MaterialEdge";back.Position=UDim2.fromOffset(-.6,0)
		back.TextStrokeColor3=baseColor;back.TextStrokeTransparency=.62
		local front=text(holder,character,size,font,WHITE,width,30);front.Name="LetterFace"
		local fill,shine
		if treatment=="liquid"then
			fill=new("Frame",{Name="WaterFill",BackgroundTransparency=1,ClipsDescendants=true,Size=UDim2.fromOffset(width,16),Position=UDim2.fromOffset(0,14)},holder)
			local copy=text(fill,character,size,font,Color3.fromRGB(76,210,239),width,30);copy.Position=UDim2.fromOffset(0,-14)
			shine=new("Frame",{Name="WaterMeniscus",BackgroundTransparency=1,ClipsDescendants=true,Size=UDim2.fromOffset(width,2)},holder)
			local line=text(shine,character,size,font,WHITE,width,30);line.TextStrokeTransparency=1
		end
		table.insert(glyphs,{holder=holder,front=front,edge=back,shadow=shadow,x=left+previous,fill=fill,shine=shine,index=index})
		previous=advance
	end
	local function update(t)
		root:SetAttribute("MaterialPhase",t)
		for i,g in ipairs(glyphs)do
			local phase=t*2.4-i*.47;local face=g.front
			if treatment=="clean"then face.TextColor3=WHITE;g.edge.Visible=false
			elseif treatment=="discharge"then
				local live=math.sin(t*5-i*.9)>.78
				face.TextColor3=if live then WHITE else Color3.fromRGB(135,222,255)
				g.edge.Position=UDim2.fromOffset(if live then math.sin(t*32+i)*1.6 else-.6,0)
				g.edge.TextStrokeTransparency=if live then .12 else .65
			elseif treatment=="ink"then
				face.TextColor3=Color3.fromRGB(228,187,247);face.TextTransparency=.05+(math.sin(phase*.6)*.5+.5)*.21
				g.edge.Position=UDim2.fromOffset(math.sin(phase*.7)*1.1,1)
				g.edge.TextColor3=Color3.fromRGB(183,59,222);g.edge.TextTransparency=.3+math.sin(phase)^2*.3
			elseif treatment=="silk"then
				g.holder.Position=UDim2.fromOffset(g.x,top+math.sin(phase*.65)*1.3)
				face.TextColor3=Color3.fromRGB(111,245,209):Lerp(Color3.fromRGB(205,184,255),math.sin(phase*.5)*.5+.5)
				g.edge.TextStrokeTransparency=.70
			elseif treatment=="molten"then
				face.TextColor3=Color3.fromRGB(255,196,91):Lerp(Color3.fromRGB(255,244,185),math.sin(t*5+i*1.7)^2)
				g.edge.TextStrokeColor3=Color3.fromRGB(255,83,42);g.edge.TextStrokeTransparency=.12+math.sin(t*3+i)^2*.35
				g.edge.Position=UDim2.fromOffset(0,1.2+math.sin(phase)*.35)
			elseif treatment=="facet"then
				local flash=(t*.55-i/#glyphs)%1
				face.TextColor3=if flash<.13 then WHITE else Color3.fromRGB(237,188,255)
				g.edge.TextColor3=if i%2==0 then Color3.fromRGB(88,229,255)else Color3.fromRGB(255,116,191)
				g.edge.Position=UDim2.fromOffset(if flash<.13 then-1.7 else-.7,if flash<.13 then .6 else 0)
			elseif treatment=="engraved"then
				face.TextColor3=Color3.fromRGB(245,224,173);g.edge.TextColor3=Color3.fromRGB(129,149,218)
				g.edge.Position=UDim2.fromOffset(-.7,-.7);g.shadow.Position=UDim2.fromOffset(.9,1.1)
				g.edge.TextStrokeTransparency=.38+math.sin(phase*.55)^2*.38
				face.TextColor3=face.TextColor3:Lerp(WHITE,math.max(0,math.sin(t*1.6-i*.65))^8*.7)
			elseif treatment=="handwritten"then
				face.TextColor3=Color3.fromRGB(255,214,155);g.edge.TextColor3=Color3.fromRGB(176,92,48)
				g.holder.Rotation=math.sin(i*1.7)*2.3
				g.edge.TextTransparency=.25+math.sin(phase*.3)^2*.22
			elseif treatment=="liquid"then
				face.TextColor3=Color3.fromRGB(220,248,255)
				local level=14+math.sin(t*2.2-i*.55)*3
				g.fill.Position=UDim2.fromOffset(0,level);g.fill.Size=UDim2.fromOffset(g.fill.Size.X.Offset,30-level)
				g.fill.Glyph.Position=UDim2.fromOffset(0,-level)
				g.shine.Position=UDim2.fromOffset(0,level-.7);g.shine.Glyph.Position=UDim2.fromOffset(0,-level+.7)
			end
		end
	end
	update(0)
	return root,update
end
return Type

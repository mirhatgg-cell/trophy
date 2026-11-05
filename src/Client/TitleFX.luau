local RunService=game:GetService("RunService")
local FX={}
local effects={}
local colors={trainee=Color3.fromRGB(171,183,205),eye=Color3.fromRGB(68,239,205),fake=Color3.fromRGB(255,111,139),
	diplomat=Color3.fromRGB(91,185,255),collector=Color3.fromRGB(255,208,85),archivist=Color3.fromRGB(184,139,255)}
local function new(class,props,parent)local o=Instance.new(class);for k,v in pairs(props)do o[k]=v end;o.Parent=parent;return o end
local function shape(parent,color,w,h)
	return new("Frame",{BackgroundColor3=color,BorderSizePixel=0,Size=UDim2.fromOffset(w,h),AnchorPoint=Vector2.new(.5,.5)},parent)
end
function FX.Attach(parent,id,displayName,title,width)
	local color=colors[id]or colors.trainee
	local root=new("Frame",{Name="AnimatedTitle",BackgroundTransparency=1,Size=UDim2.fromOffset(width,44)},parent)
	root:SetAttribute("TitleId",id)
	local name=new("TextLabel",{BackgroundTransparency=1,Text=displayName,Font=Enum.Font.GothamBold,TextSize=15,
		TextColor3=Color3.new(1,1,1),TextStrokeColor3=Color3.fromRGB(5,10,20),TextStrokeTransparency=.65,
		TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Size=UDim2.new(1,0,0,24)},root)
	local label=new("TextLabel",{BackgroundTransparency=1,Text=title,Font=Enum.Font.GothamBold,TextSize=9,TextColor3=color,
		TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Position=UDim2.fromOffset(0,24),Size=UDim2.new(1,0,0,15)},root)
	if id=="trainee"then return root end
	local gradient=new("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,color),ColorSequenceKeypoint.new(.5,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,color)})},name)
	local state={root=root,id=id,gradient=gradient,nodes={},width=width,label=label}
	if id=="eye"then
		state.scan=shape(root,color,2,18)
		state.lens=shape(root,color,14,14);state.lens.BackgroundTransparency=1
		new("UICorner",{CornerRadius=UDim.new(1,0)},state.lens);new("UIStroke",{Color=color,Thickness=1.5},state.lens)
	elseif id=="fake"then
		for i=1,5 do state.nodes[i]=shape(root,color,9+i*2,2)end
	elseif id=="diplomat"then
		for i=1,3 do local ring=shape(root,color,10,10);ring.BackgroundTransparency=1
			new("UICorner",{CornerRadius=UDim.new(1,0)},ring);new("UIStroke",{Color=color,Thickness=1.2},ring);state.nodes[i]=ring
		end
	elseif id=="collector"then
		for i=1,4 do
			local star=shape(root,color,4,9);star.Rotation=45
			local cross=shape(star,color,9,3);cross.Position=UDim2.fromScale(.5,.5);state.nodes[i]=star
		end
	else
		for i=1,6 do local dot=shape(root,color,3,3);new("UICorner",{CornerRadius=UDim.new(1,0)},dot);state.nodes[i]=dot end
		state.line=shape(root,color,width,1);state.line.BackgroundTransparency=.65
	end
	table.insert(effects,state)
	return root
end
RunService.RenderStepped:Connect(function()
	local t=os.clock()
	for i=#effects,1,-1 do
		local s=effects[i];if not s.root.Parent then table.remove(effects,i);continue end
		local visible=true;local p=s.root
		while p do if p:IsA("GuiObject")and not p.Visible then visible=false;break end;p=p.Parent end
		if not visible then continue end
		s.gradient.Offset=Vector2.new(math.sin(t*1.4)*.6,0)
		if s.id=="eye"then
			local x=(t*.24%1)*s.width;s.scan.Position=UDim2.fromOffset(x,12);s.scan.BackgroundTransparency=.42
			s.lens.Position=UDim2.fromOffset(x,12)
		elseif s.id=="fake"then
			for j,node in ipairs(s.nodes)do node.Position=UDim2.fromOffset((math.floor(t*7+j*27)%math.max(1,s.width-12))+6,21+j%2*2);node.BackgroundTransparency=.2+math.sin(t*4+j)^2*.65 end
		elseif s.id=="diplomat"then
			for j,node in ipairs(s.nodes)do local phase=(t*.5+j/3)%1;node.Size=UDim2.fromOffset(6+phase*26,6+phase*26);node.Position=UDim2.fromOffset(s.width-16,20);node.UIStroke.Transparency=phase end
		elseif s.id=="collector"then
			for j,node in ipairs(s.nodes)do local a=t*1.2+j*math.pi/2;node.Position=UDim2.fromOffset(s.width*.48+math.cos(a)*s.width*.46,18+math.sin(a)*17);node.Rotation=t*35+j*45 end
		else
			for j,node in ipairs(s.nodes)do node.Position=UDim2.fromOffset(j*s.width/7,20+math.sin(t*1.8+j)*4);node.BackgroundTransparency=.1+math.sin(t+j)^2*.6 end
			s.line.Position=UDim2.fromOffset(s.width*.5,23);s.line.Size=UDim2.fromOffset(s.width*(.8+math.sin(t)*.15),1)
		end
	end
end)
return FX

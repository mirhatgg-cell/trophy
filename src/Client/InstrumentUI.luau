local UserInputService=game:GetService("UserInputService")
local UI={}
function UI.Build(parent,record,api)
	local c=record.challenge
	if not c then return end
	local make,text,button,C=api.make,api.text,api.button,api.colors
	local layer=make("Frame",{BackgroundColor3=C.deep,BackgroundTransparency=.25,BorderSizePixel=0,Size=UDim2.fromScale(1,1),Active=true},parent)
	local function step(action,value)api.emit("ChallengeStep",{caseId=record.id,id=c.id,action=action,value=value})end
	local function label(value,y)text(layer,value,11,C.paper,UDim2.fromOffset(8,y),UDim2.new(1,-16,0,23),Enum.Font.GothamMedium).TextXAlignment=Enum.TextXAlignment.Center end
	if c.tool=="loupe" then
		label("Проведи лупой; нажми на три найденные метки",0)
		local rings={}
		for i,spot in ipairs(c.spots)do
			local ring=make("Frame",{BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(spot.x,spot.y),Size=UDim2.fromOffset(25,25),Visible=c.found[i]==true},layer)
			api.corner(ring,30);api.stroke(ring,C.mint,0,2);rings[i]=ring
		end
		local glass=make("Frame",{BackgroundTransparency=.92,BackgroundColor3=C.mint,Size=UDim2.fromOffset(64,64),AnchorPoint=Vector2.new(.5,.5)},layer)
		api.corner(glass,40);api.stroke(glass,C.gold,0,2)
		local function point(input)
			local relative=Vector2.new(input.Position.X-layer.AbsolutePosition.X,input.Position.Y-layer.AbsolutePosition.Y)
			return {x=relative.X/math.max(1,layer.AbsoluteSize.X),y=relative.Y/math.max(1,layer.AbsoluteSize.Y)}
		end
		table.insert(api.connections,layer.InputChanged:Connect(function(input)
			if input.UserInputType~=Enum.UserInputType.MouseMovement and input.UserInputType~=Enum.UserInputType.Touch then return end
			local p=point(input);glass.Position=UDim2.fromScale(p.x,p.y)
			for i,spot in ipairs(c.spots)do rings[i].Visible=c.found[i] or (p.x-spot.x)^2+(p.y-spot.y)^2<.1^2 end
		end))
		table.insert(api.connections,layer.InputBegan:Connect(function(input)
			if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then step("sample",point(input))end
		end))
		label("Наблюдения: "..c.progress.." / 3",133)
	elseif c.tool=="uv" then
		label("Просвети поверхность: проведи по четырём полосам",0)
		for i=1,4 do
			local zone=button(layer,if c.found[i]then "✓" else "▥",6+(i-1)*74,33,68,92,function()step("zone",i)end)
			zone.BackgroundColor3=if c.found[i]then C.mint:Lerp(C.deep,.5)else Color3.fromRGB(53,46,77)
			table.insert(api.connections,zone.MouseEnter:Connect(function()if not c.found[i]then step("zone",i)end end))
		end
		label("Различай реставрацию и искусственную патину",134)
	elseif c.tool=="scale" then
		label(if c.tared then "Подбери противовесы и выровняй стрелку"else"Сначала обнули весы без нагрузки",0)
		local rail=make("Frame",{BorderSizePixel=0,BackgroundColor3=C.line,Position=UDim2.fromOffset(24,46),Size=UDim2.fromOffset(260,4)},layer)
		make("Frame",{BorderSizePixel=0,BackgroundColor3=C.gold,Position=UDim2.fromOffset(129,-7),Size=UDim2.fromOffset(2,18)},rail)
		make("Frame",{BorderSizePixel=0,BackgroundColor3=C.mint,Position=UDim2.fromOffset(130+math.clamp(c.amount-c.target,-80,80)*1.4,-4),Size=UDim2.fromOffset(3,12)},rail)
		if not c.tared then button(layer,"Тара / ноль",61,75,186,36,function()step("tare")end,"primary")
		else
			for i,v in ipairs({-20,-5,-1,1,5,20})do button(layer,(if v>0 then "+"else"")..v,5+(i-1)*51,75,46,34,function()step("weight",v)end)end
		end
		label("Груз: "..c.amount.."  ·  "..(if c.amount==c.target then"равновесие"else if c.amount<c.target then"добавь справа"else"убери справа"),123)
	elseif c.tool=="spectro" then
		label("Поверни призму до совпадения спектральных линий",0)
		local dial=make("Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(154,79),Size=UDim2.fromOffset(76,76),BackgroundTransparency=1},layer)
		api.corner(dial,40);api.stroke(dial,C.gold,.25,2)
		for i=0,11 do make("Frame",{BorderSizePixel=0,BackgroundColor3=Color3.fromHSV(i/12,.55,.85),Position=UDim2.fromOffset(38+math.sin(i*math.pi/6)*32,38+math.cos(i*math.pi/6)*32),Size=UDim2.fromOffset(3,7),Rotation=-i*30},dial)end
		text(dial,"◆",35,C.mint,UDim2.fromOffset(12,10),UDim2.fromOffset(54,54)).Rotation=c.angle
		button(layer,"−15°",7,61,75,36,function()step("rotate",-15)end)
		button(layer,"+15°",226,61,75,36,function()step("rotate",15)end)
		label("Канал "..c.target.."°  /  призма "..c.angle.."°",130)
	else
		label("Совмести разрывы трёх передаточных колёс",0)
		for i,angle in ipairs(c.gears)do
			local gear=button(layer,"⚙",13+(i-1)*99,39,84,79,function()step("gear",i)end)
			gear.Text=""
			local wheel=text(gear,"⚙",54,if angle==0 then C.mint else C.gold,UDim2.new(),UDim2.fromScale(1,1));wheel.Rotation=angle*90;wheel.TextXAlignment=Enum.TextXAlignment.Center
			make("Frame",{BorderSizePixel=0,BackgroundColor3=if angle==0 then C.mint else C.red,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(36,3),Rotation=angle*90},gear)
		end
		label("Зелёная горизонталь — правильное зацепление",134)
	end
	if c.ready then button(layer,"Записать показания",46,63,216,39,function()step("finish")end,"primary")end
end
return UI

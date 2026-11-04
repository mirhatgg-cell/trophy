local TweenService=game:GetService("TweenService")
local CollectionService=game:GetService("CollectionService")
local Workstation={active={}}
local function piece(parent,name,size,cf,color,material,shape)
	local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.Metal
	p.Shape=shape or Enum.PartType.Block;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=parent;return p
end
function Workstation.Stop(player)
	local s=Workstation.active[player]
	if not s then return end
	Workstation.active[player]=nil
	if s.tween then s.tween:Cancel()end
	if s.connection then s.connection:Disconnect()end
	if s.item and s.item.Parent then s.item:PivotTo(s.original)end
	for joint,rest in pairs(s.pose)do if joint.Parent then TweenService:Create(joint,TweenInfo.new(.25),{C0=rest}):Play()end end
	if s.root and s.root.Parent then s.root:Destroy()end
end
function Workstation.Begin(player,plot,record,tool)
	Workstation.Stop(player)
	local item=plot:FindFirstChild("CurrentItem")
	if not item or not item.PrimaryPart then return end
	local box,bounds=item:GetBoundingBox()
	local root=Instance.new("Model");root.Name="WorkingTool";root.Parent=plot
	local anchor=piece(root,"Anchor",Vector3.new(.1,.1,.1),box,Color3.new(),Enum.Material.SmoothPlastic);anchor.Transparency=1;root.PrimaryPart=anchor
	local s={root=root,item=item,original=item:GetPivot(),pose={},recordId=record.id,gearBases={},markers={}}
	Workstation.active[player]=s
	local character=player.Character
	if character then
		for _,name in ipairs({"RightShoulder","Right Shoulder","LeftShoulder","Left Shoulder","Neck"})do
			local joint=character:FindFirstChild(name,true)
			if joint and joint:IsA("Motor6D")then
				s.pose[joint]=joint.C0
				TweenService:Create(joint,TweenInfo.new(.3),{C0=joint.C0*CFrame.Angles(if name=="Neck"then-.09 else-.28,0,0)}):Play()
			end
		end
	end
	local brass=Color3.fromRGB(184,143,76)
	if tool=="scale"then
		local building=plot:FindFirstChild("Building")
		local scale=building and building:FindFirstChild("Tool_scale",true)
		local pan=scale and scale:FindFirstChild("ScalePlatform",true)
		if pan then
			s.scaleTarget=CFrame.new(pan.Position+Vector3.new(0,.15,0))*s.original.Rotation
			local mount=piece(root,"CalibrationReadout",Vector3.new(1.7,.34,.04),scale:GetPivot()*CFrame.new(0,.28,-1.445),Color3.fromRGB(31,44,43))
			local surface=Instance.new("SurfaceGui");surface.Face=Enum.NormalId.Front;surface.CanvasSize=Vector2.new(256,52);surface.Parent=mount
			local readout=Instance.new("TextLabel");readout.BackgroundTransparency=1;readout.Size=UDim2.fromScale(1,1);readout.Font=Enum.Font.Code
			readout.TextSize=36;readout.TextColor3=Color3.fromRGB(176,223,196);readout.Text="TARE";readout.Parent=surface;s.readout=readout
		end
	elseif tool=="loupe"then
		local lens=box*CFrame.new(0,bounds.Y*.25,1.1)*CFrame.Angles(-.35,0,0)
		for i=1,24 do local a=i*math.pi/12;piece(root,"LoupeRim",Vector3.new(.07,.18,.07),lens*CFrame.new(math.sin(a)*.57,math.cos(a)*.57,0)*CFrame.Angles(0,0,-a),brass)end
		local glass=piece(root,"MagnifyingGlass",Vector3.new(1.06,1.06,.07),lens,Color3.fromRGB(186,221,217),Enum.Material.Glass,Enum.PartType.Ball);glass.Transparency=.72
		piece(root,"HandGrip",Vector3.new(.14,.85,.14),lens*CFrame.new(0,-.95,0),Color3.fromRGB(95,66,44))
	elseif tool=="uv"then
		local cf=CFrame.lookAt(box.Position+Vector3.new(.7,bounds.Y*.5+.7,1.0),box.Position)
		local pen=piece(root,"PortableUVProbe",Vector3.new(.22,.22,1.1),cf,Color3.fromRGB(48,57,63))
		local lens=piece(root,"UVLens",Vector3.new(.18,.18,.05),cf*CFrame.new(0,0,-.57),Color3.fromRGB(151,132,219),Enum.Material.Neon)
		local light=Instance.new("SpotLight");light.Face=Enum.NormalId.Front;light.Color=Color3.fromRGB(153,133,223);light.Range=8;light.Angle=42;light.Brightness=.7;light.Parent=pen
		pen:SetAttribute("ProbaMotion","swing");pen:SetAttribute("FXJoint",root:GetPivot():ToObjectSpace(cf));pen:SetAttribute("FXLocal",CFrame.new());pen:SetAttribute("FXSize",pen.Size)
		lens:SetAttribute("ProbaMotion","swing");lens:SetAttribute("FXJoint",root:GetPivot():ToObjectSpace(cf));lens:SetAttribute("FXLocal",CFrame.new(0,0,-.57));lens:SetAttribute("FXSize",lens.Size)
	elseif tool=="spectro"then
		local base=plot.Anchor.CFrame*CFrame.new(3.2,5.2,4.4)
		piece(root,"PrismCalibrationStand",Vector3.new(.9,.12,.9),base,brass)
		s.prismBase=base*CFrame.new(0,.38,0)
		s.prism=piece(root,"RotatingPrism",Vector3.new(.65,.6,.65),s.prismBase,Color3.fromRGB(166,207,220),Enum.Material.Glass,Enum.PartType.Wedge);s.prism.Transparency=.35
		for i=1,5 do piece(root,"SpectrumBand",Vector3.new(.065,.03,.75),base*CFrame.new(.62+i*.08,.08,0),Color3.fromHSV(i/6,.65,.8),Enum.Material.Neon)end
	elseif tool=="diagnostic"then
		for i=1,3 do
			local base=plot.Anchor.CFrame*CFrame.new(3+(i-2)*.52,5.16,4.5)
			s.gearBases[i]=base
			piece(root,"DiagnosticWheel",Vector3.new(.12,.85,.85),base*CFrame.Angles(0,0,math.pi/2),brass,Enum.Material.Metal,Enum.PartType.Cylinder)
			s.markers[i]=piece(root,"WheelNotch",Vector3.new(.3,.025,.055),base*CFrame.new(.22,.08,0),Color3.fromRGB(108,187,154),Enum.Material.Neon)
		end
	end
	root:SetAttribute("FXCenter",CFrame.new());root:SetAttribute("FXRadius",1)
	CollectionService:AddTag(root,"ProbaItemVisual")
end
function Workstation.Step(player,challenge)
	local s=Workstation.active[player];if not s then return end
	if s.scaleTarget and challenge.tared then
		if not s.tween then
			local value=Instance.new("CFrameValue");value.Value=s.original;value.Parent=s.root
			s.connection=value:GetPropertyChangedSignal("Value"):Connect(function()if s.item.Parent then s.item:PivotTo(value.Value)end end)
			s.tween=TweenService:Create(value,TweenInfo.new(.65,Enum.EasingStyle.Sine),{Value=s.scaleTarget});s.tween:Play()
		end
		if s.readout then s.readout.Text=string.format("CAL %+03d",challenge.amount-challenge.target)end
	end
	if s.prism and s.prism.Parent then s.prism.CFrame=s.prismBase*CFrame.Angles(0,math.rad(challenge.angle),0)end
	for i,marker in ipairs(s.markers)do if marker.Parent then marker.CFrame=s.gearBases[i]*CFrame.Angles(0,challenge.gears[i]*math.pi/2,0)*CFrame.new(.22,.08,0)end end
end
return Workstation

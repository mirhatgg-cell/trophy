local RunService=game:GetService("RunService")
local CollectionService=game:GetService("CollectionService")
local Effects={}
function Effects.Start()
	local tracked={}
	local function track(model)
		if tracked[model]then return end
		local state={parts={}};tracked[model]=state
		local function add(p)if p:GetAttribute("ProbaMotion")then table.insert(state.parts,p)end end
		for _,p in ipairs(model:GetDescendants())do add(p)end
		state.added=model.DescendantAdded:Connect(add)
	end
	for _,model in ipairs(CollectionService:GetTagged("ProbaItemVisual"))do track(model)end
	CollectionService:GetInstanceAddedSignal("ProbaItemVisual"):Connect(track)
	CollectionService:GetInstanceRemovedSignal("ProbaItemVisual"):Connect(function(model)local state=tracked[model];if state then state.added:Disconnect();tracked[model]=nil end end)
	RunService.RenderStepped:Connect(function()
		local now=os.clock()
		for model,state in pairs(tracked)do
			if not model.Parent then continue end
			if model:FindFirstAncestorOfClass("Tool")then continue end -- Never move the welded carried assembly.
			local pivot=model:GetPivot();local camera=workspace.CurrentCamera
			if camera and not model:FindFirstAncestorOfClass("WorldModel")and(pivot.Position-camera.CFrame.Position).Magnitude>150 then continue end
			local center=pivot*(model:GetAttribute("FXCenter")or CFrame.new());local radius=model:GetAttribute("FXRadius")or 1
			for _,p in ipairs(state.parts)do
				if not p.Parent then continue end
				local kind=p:GetAttribute("ProbaMotion");local phase=p:GetAttribute("FXPhase")or 0;local t=now+phase
				if kind=="sheen"then p.FillTransparency=.92+math.sin(t*1.7)*.065
				elseif kind=="glint"then p.Brightness=.12+(math.sin(t)*.5+.5)*.45
				elseif kind=="heat"then p.Color=Color3.fromRGB(255,115+math.floor(math.sin(t*2)*35),43)
				elseif kind=="spin"or kind=="swing"then
					local joint=p:GetAttribute("FXJoint")or CFrame.new()
					p.CFrame=pivot*joint*CFrame.Angles(0,0,if kind=="spin"then t*.35 else math.sin(t*.8)*.06)*(p:GetAttribute("FXLocal")or CFrame.new())
				else
					local base=pivot*(p:GetAttribute("FXLocal")or CFrame.new());local size=p:GetAttribute("FXSize")or p.Size
					if kind=="phase"then p.CFrame=base*CFrame.new(math.sin(t)*.09,math.cos(t*.6)*.04,0);p.Transparency=.86+math.sin(t*.8)*.08
					elseif kind=="leaf"then p.CFrame=base*CFrame.Angles(0,0,math.sin(t*.5)*.09);p.Size=size*(.94+math.sin(t*.3)*.06)
					elseif kind=="frost"then p.Size=size*(.94+(math.sin(t*.35)*.5+.5)*.12)
					elseif kind=="mist"then local age=(t*.17)%1;p.CFrame=base*CFrame.new(math.sin(t)*.13,age*.55,0);p.Transparency=.84+age*.15;p.Size=size*(1+age*1.8)
					elseif kind=="cinder"then local age=(t*.34)%1;p.CFrame=base*CFrame.new(math.sin(phase)*age*.3,age*1.1,math.cos(phase)*age*.2);p.Transparency=.15+age*.85
					elseif kind=="orbit"then p.CFrame=center*CFrame.new(math.cos(t*.55)*radius,math.sin(t*.7)*radius*.4,math.sin(t*.55)*radius)end
				end
			end
		end
	end)
end
return Effects

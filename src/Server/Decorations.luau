local Rep=game:GetService("ReplicatedStorage")
local CollectionService=game:GetService("CollectionService")
local Decorations={}
function Decorations.Apply(plot,profile)
	local old=plot:FindFirstChild("Decorations");if old then old:Destroy()end
	local folder=Instance.new("Folder");folder.Name="Decorations";folder.Parent=plot
	local building=plot:FindFirstChild("Building")
	if not building then return end
	for category,id in pairs(profile.equippedDecor)do
		local def=Rep.Shared.Decor and require(Rep.Shared.Decor).ById[id]
		if not def or not profile.ownedDecor[id]then continue end
		if category=="chair"then
			local chair=building:FindFirstChild("AppraiserChair",true)
			if chair then
				local color=Color3.fromRGB(unpack(def.color))
				for _,p in ipairs(chair:GetDescendants())do
					if p:IsA("BasePart")and(p.Name=="AppraiserSeat"or p.Name=="BackPad")then p.Color=color;p.Material=Enum.Material.Fabric end
				end
				local previous=chair:FindFirstChild("ChairTrim");if previous then previous:Destroy()end
				if def.tier>1 then
					local trim=Instance.new("Folder");trim.Name="ChairTrim";trim.Parent=chair
					local seat=chair:FindFirstChild("AppraiserSeat",true)
					if seat then
						for side=-1,1,2 do
							local rail=Instance.new("Part");rail.Name="ArmRest";rail.Size=Vector3.new(.16,.18,2.7);rail.CFrame=seat.CFrame*CFrame.new(side*1.95,.9,0)
							rail.Anchored=true;rail.CanCollide=false;rail.CanTouch=false;rail.Material=Enum.Material.Metal;rail.Color=Color3.fromRGB(191,150,81);rail.Parent=trim
						end
					end
				end
			end
		elseif category~="frame"and category~="card"then
			local socket=building:FindFirstChild("DecorSocket_"..category,true)
			local templates=Rep:FindFirstChild("DecorModels")
			local template=templates and templates:FindFirstChild(id)
			if socket and template then
				local model=template:Clone();model:PivotTo(socket.CFrame);model.Parent=folder
				model:SetAttribute("FXCenter",CFrame.new());model:SetAttribute("FXRadius",1)
				for _,group in ipairs(model:GetDescendants())do
					if group:IsA("Model")and(group.Name=="MotionSpin"or group.Name=="MotionSwing")then
						for _,p in ipairs(group:GetDescendants())do
							if p:IsA("BasePart")and p.Name~="Anchor"then
								p:SetAttribute("ProbaMotion",if group.Name=="MotionSpin"then"spin"else"swing")
								p:SetAttribute("FXJoint",model:GetPivot():ToObjectSpace(group:GetPivot()))
								p:SetAttribute("FXLocal",group:GetPivot():ToObjectSpace(p.CFrame));p:SetAttribute("FXSize",p.Size)
							end
						end
					end
				end
				CollectionService:AddTag(model,"ProbaItemVisual")
			end
		end
	end
end
return Decorations

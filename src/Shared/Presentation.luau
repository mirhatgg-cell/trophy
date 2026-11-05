-- Placement uses visible geometry, never the invisible model anchor.
local Presentation={}
function Presentation.Bounds(model)
	local pivot=model:GetPivot();local low=Vector3.new(math.huge,math.huge,math.huge);local high=Vector3.new(-math.huge,-math.huge,-math.huge)
	local found=false
	for _,p in ipairs(model:GetDescendants())do
		if not p:IsA("BasePart")or p.Name=="Anchor"or p.Transparency>=.98 then continue end
		found=true
		for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
			local v=pivot:PointToObjectSpace(p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)*.5))
			low=Vector3.new(math.min(low.X,v.X),math.min(low.Y,v.Y),math.min(low.Z,v.Z))
			high=Vector3.new(math.max(high.X,v.X),math.max(high.Y,v.Y),math.max(high.Z,v.Z))
		end end end
	end
	if not found then return Vector3.new(),Vector3.new()end
	return (low+high)*.5,high-low
end
function Presentation.Place(model,cf,width,height)
	local _,size=Presentation.Bounds(model)
	if size.Magnitude==0 then model:PivotTo(cf);return end
	local scale=math.min(width/math.max(size.X,size.Z,.01),height/math.max(size.Y,.01))
	model:ScaleTo(model:GetScale()*scale)
	local center,scaled=Presentation.Bounds(model)
	model:PivotTo(cf*CFrame.new(-center.X,-center.Y+scaled.Y*.5+.025,-center.Z))
end
return Presentation

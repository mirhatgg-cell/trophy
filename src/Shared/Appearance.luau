-- Runtime-authored wear and seven different mutation mechanisms. No unverified asset IDs.
local Rarity=require(script.Parent.Rarity)
local Config=require(script.Parent.Config)
local Appearance={}
local function part(parent,name,size,cf,color,material,alpha,shape)
	local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
	p.Transparency=alpha or 0;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true
	p.Shape=shape or Enum.PartType.Block;p.Parent=parent;return p
end
local function motion(p,kind,model,phase)
	p:SetAttribute("ProbaMotion",kind);p:SetAttribute("FXPhase",phase or 0)
	if p:IsA("BasePart")then p:SetAttribute("FXLocal",model:GetPivot():ToObjectSpace(p.CFrame));p:SetAttribute("FXSize",p.Size)end
end
local function ornament(p,seed,porcelain)
	local gui=Instance.new("SurfaceGui");gui.Name="AuthoredSurface";gui.Face=Enum.NormalId.Back;gui.CanvasSize=Vector2.new(128,128)
	gui.LightInfluence=.85;gui.AlwaysOnTop=false;gui.ZOffset=.004;gui.Parent=p
	local function ink(x,y,w,h,angle,color)
		local f=Instance.new("Frame");f.BorderSizePixel=0;f.BackgroundColor3=color;f.BackgroundTransparency=.2
		f.Position=UDim2.fromOffset(x,y);f.Size=UDim2.fromOffset(w,h);f.Rotation=angle;f.Parent=gui;return f
	end
	if porcelain then
		if Config.ArtTextures.porcelain>0 then
			local image=Instance.new("ImageLabel");image.BackgroundTransparency=1;image.Size=UDim2.fromScale(1,1);image.Image="rbxassetid://"..Config.ArtTextures.porcelain;image.Parent=gui;return
		end
		local blue=Color3.fromRGB(53,87,130)
		ink(61,10,2,100,-17,blue)
		for i=1,4 do
			local leaf=ink(40+(i%2)*25,10+i*21,12,23,if i%2==0 then 40 else -40,blue)
			local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(1,0);corner.Parent=leaf
		end
	else
		for i=1,4 do ink(15,18+i*18,80-(i%3)*9,2,(seed+i)%5-2,Color3.fromRGB(84,75,55))end
	end
end
local function surface(p,kind,seed,repair)
	local gui=Instance.new("SurfaceGui");gui.Name="AuthoredMaterial";gui.CanvasSize=Vector2.new(256,256);gui.LightInfluence=1
	gui.Face=if p.Size.Y<math.min(p.Size.X,p.Size.Z)then Enum.NormalId.Top else Enum.NormalId.Back
	gui.ZOffset=.003;gui.Parent=p
	local asset=Config.ArtTextures[kind]or 0
	if asset>0 then
		local image=Instance.new("ImageLabel");image.Size=UDim2.fromScale(1,1);image.BackgroundTransparency=1
		image.Image="rbxassetid://"..asset;image.ImageTransparency=if kind=="steel"then .36 else .12;image.Parent=gui
	else
		local count=if kind=="walnut"then 12 elseif kind=="paper"then 18 else 6
		for i=1,count do
			local line=Instance.new("Frame");line.BorderSizePixel=0
			line.BackgroundColor3=if kind=="walnut"then Color3.fromRGB(58,36,24)elseif kind=="paper"then Color3.fromRGB(130,112,78)else Color3.fromRGB(220,226,223)
			line.BackgroundTransparency=if kind=="paper"then .83 else .74
			local x=(seed*7+i*23)%236;local y=(seed+i*37)%230
			line.Position=UDim2.fromOffset(x,y)
			line.Size=if kind=="walnut"then UDim2.fromOffset(1+i%2,45+i%4*12)else UDim2.fromOffset(8+i%5*9,1)
			line.Rotation=if kind=="walnut"then math.sin(i+seed)*4 else (seed+i)%7-3
			line.Parent=gui
		end
	end
	if repair then
		for i=1,4 do
			local seam=Instance.new("Frame");seam.Name="VisibleRepairSeam";seam.BorderSizePixel=0
			seam.BackgroundColor3=Color3.fromRGB(132,118,90);seam.BackgroundTransparency=.32
			seam.Position=UDim2.fromOffset(65+i*17,98+(i%2)*6);seam.Size=UDim2.fromOffset(26,2);seam.Rotation=if i%2==0 then -14 else 19;seam.Parent=gui
		end
	end
end
function Appearance.Apply(model,item)
	if model:GetAttribute("ProbaStyled")then return model end
	local originals={}
	for _,p in ipairs(model:GetDescendants())do if p:IsA("BasePart")and p.Name~="Anchor"then table.insert(originals,p)end end
	if #originals==0 then return model end
	model:SetAttribute("ProbaStyled",true)
	local seed=item.visualSeed or 1
	local condition=item.conditionScore or item.condition or .9
	if type(condition)~="number"then condition=.9 end
	model:SetAttribute("Mutation",item.mutation or "none");model:SetAttribute("Uniqueness",item.uniqueness or 0)
	local basis=model:GetPivot();local box,bounds=model:GetBoundingBox();local radius=math.max(bounds.X,bounds.Z)*.55
	local center=basis:ToObjectSpace(box);model:SetAttribute("FXCenter",center);model:SetAttribute("FXRadius",radius)
	local materialParts={}
	for _,p in ipairs(originals)do table.insert(materialParts,p)end
	table.sort(materialParts,function(a,b)return a.Size.X*a.Size.Y*a.Size.Z>b.Size.X*b.Size.Y*b.Size.Z end)
	local decorated=0
	for _,p in ipairs(materialParts)do
		local kind=if p.Material==Enum.Material.Wood or p.Material==Enum.Material.WoodPlanks then "walnut"
			elseif p.Name=="PaperBlock"or p.Name=="Parchment"or p.Name=="ArtifactSlab"then "paper"
			elseif p.Material==Enum.Material.Metal then "steel"else nil
		if kind and decorated<3 then surface(p,kind,seed+decorated,item.repair==true and decorated==0);decorated+=1 end
	end
	for i,p in ipairs(originals)do
		p.Color=p.Color:Lerp(Color3.fromRGB(110,96,72),(1-condition)*.2)
		p.Color=p.Color:Lerp(Color3.fromRGB(139,156,137),math.clamp(item.surfaceTone or 0,0,.25))
		if p.Name=="HollowCupWall"and i%5==0 then ornament(p,seed,true)end
		if p.Name=="HollowCupWall"and i%17==0 and item.repair==true then surface(p,"porcelain",seed,true)end
		if p.Name=="MakerInlay"then ornament(p,seed,false)end
		if condition<.55 and p.Name:match("^Lip_")and tonumber(p.Name:match("(%d+)$"))==seed%24 then p.Transparency=1 end
		if i%11==seed%11 and condition<.8 then
			local grime=Instance.new("SurfaceGui");grime.Name="SurfaceWear";grime.Face=Enum.NormalId.Front;grime.CanvasSize=Vector2.new(64,64);grime.LightInfluence=1;grime.ZOffset=.006;grime.Parent=p
			for j=1,3 do
				local patch=Instance.new("Frame");patch.BorderSizePixel=0;patch.BackgroundColor3=Color3.fromRGB(93,73,48);patch.BackgroundTransparency=.45+condition*.4
				patch.Size=UDim2.fromOffset(8+j*4,5+j*3);patch.Position=UDim2.fromOffset((seed+j*13)%47,(seed+j*17)%43)
				patch.Rotation=(seed+j*31)%70;patch.Parent=grime;local c=Instance.new("UICorner");c.CornerRadius=UDim.new(1,0);c.Parent=patch
			end
		end
	end
	local id=item.mutation or "none";local def=Rarity.Definitions[id]
	local fx=Instance.new("Folder");fx.Name="MutationGeometry";fx.Parent=model
	if def then
		local color=Color3.fromRGB(unpack(def.color))
		for _,p in ipairs(originals)do
			if id=="silver"or id=="gold"then p.Color=color;p.Material=Enum.Material.Metal;p.Reflectance=if id=="gold"then .28 else .4
			elseif id=="ghost"then p.Transparency=math.max(p.Transparency,.66);p.Material=Enum.Material.Glass;p.Color=color
			elseif id=="glacial"then p.Color=p.Color:Lerp(color,.7);p.Material=Enum.Material.Ice;p.Transparency=math.max(p.Transparency,.18)
			elseif id=="ember"then p.Color=Color3.fromRGB(42,37,34);p.Material=Enum.Material.Slate
			elseif id=="astral"then p.Color=Color3.fromRGB(24,30,66);p.Material=Enum.Material.Glass end
		end
		if id=="silver"then
			local sheen=Instance.new("Highlight");sheen.Name="MovingSpecular";sheen.FillColor=color;sheen.FillTransparency=.94;sheen.OutlineTransparency=.75;sheen.Adornee=model;sheen.Parent=fx
			motion(sheen,"sheen",model)
		elseif id=="gold"then
			for i=1,10 do
				local t=i*math.pi/5
				local p=part(fx,"RaisedFiligree",Vector3.new(.025,math.max(.07,bounds.Y*.12),.025),box*CFrame.new(math.sin(t)*bounds.X*.38,math.cos(t)*bounds.Y*.25,-bounds.Z*.49)*CFrame.Angles(0,0,t),color,Enum.Material.Metal)
			end
			local light=Instance.new("PointLight");light.Color=color;light.Range=5;light.Brightness=.15;light.Parent=originals[1];motion(light,"glint",model)
		elseif id=="ghost"then
			for i=1,math.min(12,#originals)do
				local source=originals[math.max(1,math.floor(i*#originals/math.min(12,#originals)))]
				local echo=part(fx,"PhasedSilhouette",source.Size,source.CFrame,color,Enum.Material.Glass,.88,source:IsA("Part")and source.Shape or Enum.PartType.Block)
				motion(echo,"phase",model,i*.5)
			end
		elseif id=="verdant"then
			for i=1,14 do
				local a=i*.72
				local cf=box*CFrame.new(math.sin(a)*bounds.X*.43,-bounds.Y*.4+i*bounds.Y/17,math.cos(a)*bounds.Z*.43)
				part(fx,"GrowingVine",Vector3.new(.035,math.max(.05,bounds.Y/11),.035),cf,Color3.fromRGB(63,106,54),Enum.Material.Grass)
				if i%2==0 then local leaf=part(fx,"LivingLeaf",Vector3.new(.15,.035,.22),cf*CFrame.Angles(.3,a,.2),color,Enum.Material.Grass);motion(leaf,"leaf",model,a)end
			end
		elseif id=="glacial"then
			for i=1,8 do
				local a=i*math.pi/4
				local frost=part(fx,"FacetedFrost",Vector3.new(.14,.24+.04*(i%3),.13),box*CFrame.new(math.sin(a)*bounds.X*.4,-bounds.Y*.27,math.cos(a)*bounds.Z*.4)*CFrame.Angles(.2,a,.4),color,Enum.Material.Ice,.12,Enum.PartType.Wedge)
				motion(frost,"frost",model,a)
			end
			for i=1,3 do local mist=part(fx,"ColdBreath",Vector3.new(.2,.08,.2),box*CFrame.new(0,bounds.Y*.3,0),Color3.fromRGB(218,236,238),Enum.Material.SmoothPlastic,.9,Enum.PartType.Ball);motion(mist,"mist",model,i*2)end
		elseif id=="ember"then
			for i=1,9 do
				local crack=part(fx,"IncandescentCrack",Vector3.new(.018,math.max(.08,bounds.Y*.22),.02),box*CFrame.new((i%3-1)*bounds.X*.2,(math.floor(i/3)-1)*bounds.Y*.18,-bounds.Z*.505)*CFrame.Angles(0,0,(i%2-.5)*.8),color,Enum.Material.Neon)
				motion(crack,"heat",model,i)
			end
			for i=1,6 do local cinder=part(fx,"RisingCinder",Vector3.new(.028,.028,.028),box*CFrame.new(0,bounds.Y*.4,0),color,Enum.Material.Neon,.3);motion(cinder,"cinder",model,i*.7)end
		elseif id=="astral"then
			for i=1,12 do
				local star=part(fx,"OrbitalStar",Vector3.new(.04,.04,.04),box,if i%3==0 then Color3.fromRGB(231,190,105)else Color3.fromRGB(200,218,246),Enum.Material.Neon,0,Enum.PartType.Ball)
				motion(star,"orbit",model,i*math.pi/6)
			end
		end
	end
	game:GetService("CollectionService"):AddTag(model,"ProbaItemVisual")
	return model
end
return Appearance

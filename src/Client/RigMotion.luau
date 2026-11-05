local RunService=game:GetService("RunService")
local CollectionService=game:GetService("CollectionService")
local Motion={}
function Motion.Start()
	local rigs={}
	local function attach(model)
		if rigs[model]then return end
		local state={joints={},seen={},nextScan=0};rigs[model]=state
		local function add(obj)
			if state.seen[obj]then return end
			if obj:IsA("Motor6D")and obj.Part0 and obj.Part1 then
				local name=obj.Name:gsub(" ",""):lower()
				local root=model:FindFirstChild("HumanoidRootPart")
				if not root then return end
				local axis=(obj.Part0.CFrame*obj.C0):VectorToObjectSpace(root.CFrame.RightVector)
				table.insert(state.joints,{joint=obj,name=name,axis=axis,rest=obj.Transform,side=if name:find("right")then 1 else -1})
				state.seen[obj]=true
			end
		end
		for _,obj in ipairs(model:GetDescendants())do add(obj)end
		state.added=model.DescendantAdded:Connect(add)
		state.scan=function()for _,obj in ipairs(model:GetDescendants())do add(obj)end end
	end
	for _,model in ipairs(CollectionService:GetTagged("ProbaCustomer"))do attach(model)end
	CollectionService:GetInstanceAddedSignal("ProbaCustomer"):Connect(attach)
	CollectionService:GetInstanceRemovedSignal("ProbaCustomer"):Connect(function(model)
		local s=rigs[model];if s then s.added:Disconnect();rigs[model]=nil end
	end)
	RunService.PreSimulation:Connect(function()
		local now=os.clock();local camera=workspace.CurrentCamera
		for model,state in pairs(rigs)do
			if model:GetAttribute("ProbaNativeActive")==true then continue end -- Animator owns these joints; do not overwrite its tracks.
			if now>=state.nextScan then state.nextScan=now+2;state.scan()end
			local root=model:FindFirstChild("HumanoidRootPart")
			if not root or not model:IsDescendantOf(workspace)or(camera and(root.Position-camera.CFrame.Position).Magnitude>210)then continue end
			local velocity=root.AssemblyLinearVelocity;local speed=Vector3.new(velocity.X,0,velocity.Z).Magnitude
			local moving=speed>.35 or model:GetAttribute("ProbaWalking")==true
			local amplitude=if moving then math.clamp(speed/10,.35,1)else 0
			local stride=math.sin(now*8.5);local mood=model:GetAttribute("ProbaMood")
			for _,entry in ipairs(state.joints)do
				local joint,name=entry.joint,entry.name
				if not joint.Parent then continue end
				local angle=0
				if name:find("shoulder")then angle=stride*.58*entry.side*amplitude+math.sin(now*1.6)*.035
					if mood=="angry"then angle+=.28 elseif mood=="happy"or mood=="laugh"then angle+=math.sin(now*3)*.1 end
				elseif name:find("hip")then angle=-stride*.60*entry.side*amplitude
				elseif name:find("knee")then angle=math.max(0,stride*entry.side)*.8*amplitude
				elseif name:find("ankle")then angle=-stride*.16*entry.side*amplitude
				elseif name:find("elbow")then angle=.12+math.max(0,-stride*entry.side)*.25*amplitude
				elseif name:find("waist")then angle=math.sin(now*1.7)*.025
				elseif name:find("neck")then angle=math.sin(now*1.3)*.025+(if mood=="sad"then .15 else 0)
				else continue end
				joint.Transform=entry.rest*CFrame.fromAxisAngle(entry.axis,angle)
			end
		end
	end)
end
return Motion

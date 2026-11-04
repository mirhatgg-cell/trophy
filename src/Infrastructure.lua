local I={}
local Run=game:GetService('RunService')
local Players=game:GetService('Players')
local Tween=game:GetService('TweenService')
local function partRoot(p) return p.Character and p.Character:FindFirstChild('HumanoidRootPart') end
function I.bind(parent,prompt)
 for _,model in ipairs(parent:GetDescendants()) do if model:IsA('Model') and model.Name=='Lift' and not model:GetAttribute('Bound') then
  model:SetAttribute('Bound',true)
  local cab=model:FindFirstChild('Cabin'); local upper=model:FindFirstChild('UpperStop'); local lower=model:FindFirstChild('LowerStop')
  if cab and upper then
   local bottom=cab.Position; local top=Vector3.new(bottom.X,upper.Position.Y+.5,bottom.Z); local moving=false; local atTop=false
   local function move(p,target)
    local r=partRoot(p); if moving or not r or math.min((r.Position-cab.Position).Magnitude,(r.Position-upper.Position).Magnitude,lower and (r.Position-lower.Position).Magnitude or math.huge)>20 then return end
    moving=true; local from=cab.Position; local goal=target=='top' and top or target=='bottom' and bottom or (atTop and bottom or top); local duration=math.max(3,(goal-from).Magnitude/14); local start=os.clock()
    task.spawn(function()
     while cab.Parent and os.clock()-start<duration do
      local a=math.clamp((os.clock()-start)/duration,0,1); a=a*a*(3-2*a); local pos=from:Lerp(goal,a); local delta=pos-cab.Position
      for _,who in ipairs(Players:GetPlayers()) do local root=partRoot(who)
       if root and math.abs(root.Position.X-cab.Position.X)<6.5 and math.abs(root.Position.Z-cab.Position.Z)<6.5 and root.Position.Y>cab.Position.Y and root.Position.Y<cab.Position.Y+8 then who.Character:PivotTo(who.Character:GetPivot()+delta) end
      end
      cab.Position=pos; Run.Heartbeat:Wait()
     end
     if cab.Parent then cab.Position=goal end; atTop=(goal-top).Magnitude<1; moving=false
    end)
   end
   prompt(cab,'Lift / next level',function(p) move(p,nil) end)
   prompt(upper,'Call lift',function(p) if not atTop then move(p,'top') end end)
   if lower then prompt(lower,'Call lift',function(p) if atTop then move(p,'bottom') end end) end
  end
 end end
end
return I

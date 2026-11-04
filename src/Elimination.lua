-- Procedural R6/R15 motor choreography; no uploaded animation dependency.
local Tween=game:GetService('TweenService')
local E={}
function E.play(s,p,cause,contact)
 local st=s.state; if not s.alive[p] or st.deadPending[p] then return end
 local char=p.Character; local hum=char and char:FindFirstChildOfClass('Humanoid'); local root=char and char:FindFirstChild('HumanoidRootPart')
 if not hum or not root then return end
 st.deadPending[p]=true; hum.WalkSpeed=0; hum.JumpPower=0; hum.AutoRotate=false
 local before=root.CFrame; root.Anchored=true
 local direction=contact and contact.Position-root.Position or root.CFrame.LookVector
 local yaw=math.atan2(direction.X,direction.Z)
 local original={}
 local function pose(stage)
  for _,motor in ipairs(char:GetDescendants()) do if motor:IsA('Motor6D') then
   if not original[motor] then original[motor]=motor.C0 end
   local name=string.lower(motor.Name); local rx,rz=0,0
   if string.find(name,'shoulder') then
    rx=stage==1 and -.45 or stage==2 and -2.1 or stage==3 and -1.7 or -.8
    rz=(string.find(name,'left') and -1 or 1)*(stage==3 and .7 or .3)
   elseif string.find(name,'neck') then rx=stage==1 and -.3 or stage==3 and .35 or 0
   elseif string.find(name,'hip') then rx=stage>=3 and .5 or .1
   elseif string.find(name,'waist') or string.find(name,'root') then rz=stage==4 and .65 or 0 end
   Tween:Create(motor,TweenInfo.new(.18),{C0=original[motor]*CFrame.Angles(rx,0,rz)}):Play()
  end end
 end
 s.api.send(p,'death',{phase='recognition',cause=cause})
 task.spawn(function()
  pose(1); task.wait(.16)
  if not char.Parent then return end
  pose(2); s.api.send(p,'death',{phase='defensive posture',cause=cause}); task.wait(.2)
  pose(3); s.api.send(p,'death',{phase='resistance',cause=cause})
  if cause=='freeze' then
   for _,b in ipairs(char:GetChildren()) do if b:IsA('BasePart') then Tween:Create(b,TweenInfo.new(.5),{Color=Color3.fromRGB(154,202,219)}):Play() end end
  elseif cause=='drown' then root.CFrame=before*CFrame.Angles(0,0,.2)
  elseif cause=='consume' then root.CFrame=CFrame.new(root.Position)*CFrame.Angles(0,yaw,0) end
  task.wait(.3); pose(4)
  -- Contact determines direction; only a small local displacement is used. Camera is never locked.
  local lean=cause=='crush' and .55 or cause=='combat' and -.7 or .3
  Tween:Create(root,TweenInfo.new(.3),{CFrame=root.CFrame*CFrame.new(0,-.6,0)*CFrame.Angles(lean,0,.3)}):Play()
  s.api.send(p,'death',{phase='loss of balance',cause=cause}); task.wait(.35)
  if hum.Parent then hum.Health=0 end
  root.Anchored=false; s.alive[p]=false
  if s.controller and s.controller~=p then s.scores[s.controller]=(s.scores[s.controller] or 0)+55 end
  s.api.audio(s,'elimination',root.Position); s.api.send(p,'death',{phase='eliminated',cause=cause})
 end)
end
return E

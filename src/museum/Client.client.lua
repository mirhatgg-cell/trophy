local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local p=Players.LocalPlayer
local remote=RS:WaitForChild('MuseumEvent')
local B=require(RS:WaitForChild('MuseumBlueprint'))
local gui=Instance.new('ScreenGui');gui.Name='MuseumInterface';gui.ResetOnSpawn=false;gui.Parent=p:WaitForChild('PlayerGui')
local function panel(size,pos)
 local f=Instance.new('Frame');f.Size=size;f.Position=pos;f.BackgroundColor3=Color3.fromRGB(28,35,31);f.BackgroundTransparency=.12;f.BorderSizePixel=0;f.Parent=gui;local c=Instance.new('UICorner',f);c.CornerRadius=UDim.new(0,8);return f
end
local function label(parent,text,size,pos,sz)
 local t=Instance.new('TextLabel',parent);t.Text=text;t.Size=size;t.Position=pos;t.TextColor3=Color3.fromRGB(237,223,182);t.BackgroundTransparency=1;t.Font=Enum.Font.Gotham;t.TextSize=sz or 14;t.TextWrapped=true;t.TextXAlignment=Enum.TextXAlignment.Left;return t
end
local top=panel(UDim2.new(1,-24,0,62),UDim2.fromOffset(12,10))
label(top,'MOUNTAINVERSE / МУЗЕЙ МАТЕРИИ',UDim2.new(1,-200,0,25),UDim2.fromOffset(12,4),18)
local status=label(top,B.build..' / соединение с музеем…',UDim2.new(1,-24,0,24),UDim2.fromOffset(12,31),12)
local menu=panel(UDim2.fromOffset(220,325),UDim2.new(1,-232,0,82));menu.Visible=false
local paused=false
local function button(parent,text,pos,fn)
 local b=Instance.new('TextButton',parent);b.Size=UDim2.new(1,-16,0,38);b.Position=pos;b.Text=text;b.Font=Enum.Font.GothamMedium;b.TextSize=14;b.BackgroundColor3=Color3.fromRGB(194,165,105);b.TextColor3=Color3.fromRGB(28,35,31);b.BorderSizePixel=0;local corner=Instance.new('UICorner',b);corner.CornerRadius=UDim.new(0,6);b.Activated:Connect(fn);return b
end
local toggle=button(top,'ГАЛЕРЕИ',UDim2.new(1,-152,0,9),function()menu.Visible=not menu.Visible end);toggle.Size=UDim2.fromOffset(140,36)
for i,v in ipairs({{'Входной зал','entry'},{'Первый этаж','floor1'},{'Второй этаж','floor2'},{'Третий этаж','floor3'},{'20 материалов','tiers'},{'Лаборатория мутаций','mutations'}})do button(menu,v[1],UDim2.fromOffset(8,8+(i-1)*43),function()remote:FireServer('travel',v[2]);menu.Visible=false end)end
local pause=button(menu,'Анимации: включены',UDim2.fromOffset(8,270),function()paused=not paused end)
local card=panel(UDim2.fromOffset(360,130),UDim2.new(0,12,1,-146));card.Visible=false
local detail=label(card,'',UDim2.new(1,-24,1,-12),UDim2.fromOffset(12,6),15)
local serial=0
remote.OnClientEvent:Connect(function(action,data)
 if action=='state'then
  status.Text=data.build..' / '..(data.ready and 'полная детализация готова' or 'сборка деталей: '..data.created)..' / экспонатов '..data.trophies
 elseif action=='inspect'then card.Visible=true;detail.Text=data.name..'\n'..data.kind..' / ранг '..data.level..' / '..data.mutation..'\nКорпус: '..data.bodyParts..' физических деталей\nАнимации можно приостановить в меню галерей.'
 elseif action=='toast'then serial+=1;local version=serial;card.Visible=true;detail.Text=data;task.delay(6,function()if serial==version then card.Visible=false end end)end
end)
local cache=setmetatable({},{__mode='k'});local nearest={};local scanAt=0;local animationTime=0
local function collect(model)
 if cache[model]then return cache[model]end
 local c=model:FindFirstChild('Center');local a=model:FindFirstChild('Animation');local theme=model:FindFirstChild('Theme');if not c or not a or not theme then return end
 local data={center=c.Value,theme=theme.Value,parts={},body={},phase=#model.Name*.23,lastBody=0}
 for _,part in ipairs(a:GetChildren())do if part:IsA('BasePart')then table.insert(data.parts,{p=part,cf=part.CFrame,size=part.Size,alpha=part.Transparency,index=tonumber(string.match(part.Name,'_(%d+)$'))or 0})end end
 local body=model:FindFirstChild('Body')
 if body then for _,part in ipairs(body:GetChildren())do if part:IsA('BasePart')and(data.theme=='ghost'or data.theme=='galaxy'and part.Material==Enum.Material.Neon)then table.insert(data.body,{p=part,alpha=part.Transparency})end end end
 cache[model]=data;return data
end
Run.RenderStepped:Connect(function(dt)
 pause.Text=paused and 'Анимации: пауза' or 'Анимации: включены'
 if paused then return end
 animationTime+=math.min(dt,.1);local now=os.clock();local camera=workspace.CurrentCamera
 if not camera then return end
 if now>=scanAt then
  scanAt=now+.5;nearest={};local world=workspace:FindFirstChild('MuseumWorld');local exhibits=world and world:FindFirstChild('Exhibits')
  if exhibits then for _,model in ipairs(exhibits:GetChildren())do local center=model:FindFirstChild('Center')
   if center then local delta=center.Value-camera.CFrame.Position;local distance=delta.Magnitude
    if distance<72 and (distance<1 or camera.CFrame.LookVector:Dot(delta.Unit)>-.2)then local data=collect(model);if data then table.insert(nearest,{model=model,data=data,distance=distance})end end
   end
  end end
  table.sort(nearest,function(a,b)return a.distance<b.distance end);while #nearest>4 do table.remove(nearest)end
 end
 for _,item in ipairs(nearest)do
  local data=item.data;if not item.model.Parent then continue end
  local t=animationTime+data.phase;local center=data.center
  for _,v in ipairs(data.parts)do local part=v.p;if not part.Parent then continue end;local i=v.index;local name=part.Name;local offset=v.cf.Position-center
   if string.sub(name,1,5)=='Fold_'then
    local squash=1+math.sin(t*2+i*.7)*.22;part.Size=Vector3.new(v.size.X/math.sqrt(squash),v.size.Y*squash,v.size.Z/math.sqrt(squash));part.CFrame=v.cf*CFrame.new(math.sin(t*1.7+i)*.025,math.sin(t*2+i)*.06,0)
   elseif string.sub(name,1,5)=='Drop_'then
    local fall=(t*.65+i*.13)%1;part.CFrame=v.cf+Vector3.new(0,-fall*1.3,0);part.Size=Vector3.new(v.size.X*(.8+fall*.3),v.size.Y*(1.4-fall*.7),v.size.Z*(.8+fall*.3));part.Transparency=fall>.85 and (fall-.85)/.15 or 0
   elseif string.sub(name,1,7)=='Ripple_'then
    local pulse=(t*.5+i/32)%1;local delta=Vector3.new(offset.X*pulse,offset.Y,offset.Z*pulse);part.CFrame=CFrame.new(center+delta)*v.cf.Rotation;part.Transparency=pulse*.65;part.Size=Vector3.new(v.size.X*(.5+pulse),v.size.Y,v.size.Z)
   elseif string.sub(name,1,5)=='Coin_'or string.sub(name,1,13)=='GoldFiligree_'then
    part.CFrame=CFrame.new(center)*CFrame.Angles(0,t*.32,0)*CFrame.new(offset)*v.cf.Rotation*CFrame.Angles(0,t*.9,0)
   elseif string.sub(name,1,11)=='GhostRibbon'then
    part.CFrame=CFrame.new(center)*CFrame.Angles(0,-t*.23,0)*CFrame.new(offset+Vector3.new(0,math.sin(t*1.4+i*.16)*.18,0))*v.cf.Rotation;part.Transparency=.38+math.sin(t*1.7+i*.1)*.18
   elseif string.sub(name,1,9)=='GhostWisp'then
    part.CFrame=v.cf+Vector3.new(math.sin(t*.8+i)*.1,math.sin(t*1.2+i)*.35,math.cos(t*.8+i)*.1);part.Transparency=.3+(math.sin(t*1.4+i)+1)*.22
   elseif string.sub(name,1,5)=='Orbit'then
    local ring=tonumber(string.sub(name,6,6))or 0;part.CFrame=CFrame.new(center)*CFrame.Angles(t*.08*(ring-1),t*(.18+ring*.08),0)*CFrame.new(offset)*v.cf.Rotation
   elseif string.sub(name,1,5)=='Star_'then
    part.Transparency=.04+(math.sin(t*(1+i%4*.3)+i)+1)*.28;part.CFrame=v.cf+Vector3.new(0,math.sin(t*.7+i)*.055,0)
   elseif string.match(name,'^ClayCoil_')then
    part.CFrame=CFrame.new(center)*CFrame.Angles(0,t*.13,0)*CFrame.new(offset+Vector3.new(0,math.sin(t*1.6+i*.2)*.06,0))*v.cf.Rotation
   elseif string.match(name,'^StoneChip_')then
    part.CFrame=v.cf*CFrame.Angles(math.sin(t*.5+i)*.18,t*.08,0)+Vector3.new(0,math.sin(t*.8+i)*.12,0)
   elseif string.match(name,'^CopperTooth_')then
    part.CFrame=CFrame.new(center)*CFrame.Angles(0,t*.6,0)*CFrame.new(offset)*v.cf.Rotation
   elseif string.match(name,'^BronzeLeaf_')then
    part.CFrame=v.cf*CFrame.Angles(0,0,math.sin(t*.7+i*.15)*.055)
   elseif string.match(name,'^SilverSweep_')then
    part.CFrame=v.cf+Vector3.new(math.sin(t*.9+i*.3)*.65,0,0);part.Transparency=.15+(math.sin(t*1.5+i)+1)*.25
   elseif string.match(name,'^SilverOrb_')then
    part.CFrame=CFrame.new(center)*CFrame.Angles(0,t*.12,0)*CFrame.new(offset)*v.cf.Rotation
   elseif string.match(name,'^RubyFacet_')then
    part.CFrame=v.cf*CFrame.Angles(0,math.sin(t*.5+i)*.08,0);part.Transparency=.06+(math.sin(t*.9+i)+1)*.035
   elseif string.match(name,'^EmeraldSpire_')then
    part.Size=Vector3.new(v.size.X,v.size.Y*(1+math.sin(t*.65+i*.23)*.17),v.size.Z)
   elseif string.match(name,'^SapphireDrop_')then
    local fall=(t*.45+i*.07)%1;part.CFrame=v.cf+Vector3.new(0,1.2-fall*2.4,0);part.Transparency=.05+fall*.35
   elseif string.match(name,'^AmethystHelix_')then
    part.CFrame=CFrame.new(center)*CFrame.Angles(0,t*.23*(i<32 and 1 or -1),0)*CFrame.new(offset)*v.cf.Rotation
   elseif string.match(name,'^ObsidianPlate_')then
    local opening=(math.sin(t*.7)+1)*.055;part.CFrame=CFrame.new(center+Vector3.new(offset.X*(1+opening),offset.Y,offset.Z*(1+opening)))*v.cf.Rotation
   elseif string.match(name,'^ObsidianCrack_')then
    part.Transparency=.1+(math.sin(t*.7+math.pi)+1)*.2
   elseif string.match(name,'^IceCrystal_')then
    part.CFrame=v.cf*CFrame.Angles(0,0,math.sin(t*.4+i)*.025)
   elseif string.match(name,'^Snowflake_')then
    part.CFrame=v.cf+Vector3.new(math.sin(t+i)*.12,1-((t*.18+i*.05)%1)*2.2,0)
   elseif string.match(name,'^PlasmaArc_')then
    part.CFrame=CFrame.new(center)*CFrame.Angles(math.sin(t*.7)*.25,t*.6,0)*CFrame.new(offset)*v.cf.Rotation;part.Transparency=.1+(math.sin(t*3+i*.2)+1)*.16
   elseif string.match(name,'^ConstellationStar_')then
    part.Transparency=.03+(math.sin(t*.8+i//4)+1)*.18
   elseif string.match(name,'^Comet')then
    part.CFrame=CFrame.new(center)*CFrame.Angles(0,t*.55,0)*CFrame.new(offset)*v.cf.Rotation
   elseif string.match(name,'^Planet_')then
    part.CFrame=CFrame.new(center)*CFrame.Angles(0,t*(.11+i*.06),0)*CFrame.new(offset)*v.cf.Rotation*CFrame.Angles(0,t*.3,0)
   elseif string.match(name,'^CosmosRing_')then
    part.CFrame=CFrame.new(center)*CFrame.Angles(.25,0,t*.07)*CFrame.new(offset)*v.cf.Rotation
   elseif string.match(name,'^RiftPlate_')then
    local opening=.08+math.sin(t*.8)*.12;part.CFrame=v.cf+Vector3.new((i%2==0 and 1 or -1)*opening,0,0)
   elseif string.match(name,'^RiftCore_')then
    part.Transparency=.05+(math.sin(t*2+i*.3)+1)*.13
   elseif string.match(name,'^Sand_')then
    part.CFrame=v.cf+Vector3.new(0,.9-((t*.5+i*.047)%1)*1.8,0)
   elseif string.match(name,'^Hourglass_')then
    part.CFrame=CFrame.new(center)*CFrame.Angles(0,t*.08,0)*CFrame.new(offset)*v.cf.Rotation
   elseif string.match(name,'^Crown')then
    part.CFrame=CFrame.new(center)*CFrame.Angles(0,t*.12,0)*CFrame.new(offset)*v.cf.Rotation
   elseif string.sub(name,1,10)=='RankOrbit_'then
    local level=item.model.Level.Value;local speed=level<=6 and .12 or level>=14 and .4 or .22
    part.CFrame=CFrame.new(center)*CFrame.Angles(0,t*speed,0)*CFrame.new(offset+Vector3.new(0,math.sin(t*1.3+i*.3)*.08,0))*v.cf.Rotation
   end
  end
  if now-data.lastBody>.15 then data.lastBody=now
   for _,v in ipairs(data.body)do if v.p.Parent then v.p.Transparency=data.theme=='ghost'and .4+math.sin(t*.9)*.14 or .05+(math.sin(t*1.5+v.p.Position.X)*.5+.5)*.3 end end
  end
 end
end)
remote:FireServer('sync')
task.spawn(function()for _=1,15 do task.wait(1);remote:FireServer('sync')end end)

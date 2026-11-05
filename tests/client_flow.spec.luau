local Catalog=env.require(services.ServerScriptService.Catalog)
local Config=env.require(shared.Config)
for _,d in ipairs(Catalog)do local model=node("Model",d.id,models);model.PrimaryPart=node("Part","Anchor",model)end
local decorModels=node("Folder","DecorModels",rep)
for _,d in ipairs(env.require(shared.Decor).List)do local model=node("Model",d.id,decorModels);model.PrimaryPart=node("Part","Anchor",model)end
env.require(clientScripts.ProbaClient)
local networkState=net.State.OnClientEvent
local profile={kind="snapshot",cash=25793,reputation=75,baseLevel=3,specialty="Everyday",specXP={Everyday=100,Jeweler=0,Historian=0,Archaeologist=0,Technician=0},equipment={loupe=3,scale=3,uv=3,spectro=3,diagnostic=3},stats={served=10},inventory={},ownedDecor={},equippedDecor={card="card_geode",frame="frame_facet"},unlocked={trainee=true,eye=true,fake=true,diplomat=true,collector=true,archivist=true},tutorial={done=false,step=1,total=8,title="Выбери специальность"},queue=4,capacity=5,saveMode="studio",admin=true,seated=true,title="archivist",nametag="tag_volt",ownedNametags={}}
local identities=env.require(shared.Identity)
for _,d in ipairs(identities.Nametags)do profile.ownedNametags[d.id]=true end
for _,d in ipairs(env.require(shared.Decor).List)do profile.ownedDecor[d.id]=true end
networkState:Fire({kind="catalog",items=Catalog});networkState:Fire(profile);capture("passive")
local item={id="h03",uid="owned",name="Фарфоровая кружка",spec="Everyday",condition="Есть следы времени",conditionScore=.8,material="Фарфор",mutation="ghost",uniqueness=.1,visualSeed=17,reports={},estimate={low=100,high=150,confidence=70},paid=15}
profile.case={id="case",customer="Friend avatar",item=item,tests={},patience=1,timing={seconds=310,paused=false},negotiations=0}
profile.inventory={item};networkState:Fire(profile);networkState:Fire({kind="open",panel="case"});capture("case")
click("Рассмотреть 3D");services.RunService.RenderStepped:Fire(.016)
for _,n in ipairs(allNodes)do
	if n.ClassName=="ViewportFrame"and shown(n)and n.CurrentCamera then
		expect(n.CurrentCamera.CFrame.Position.Z<0,"The first item view must face the authored front, rather than the blank back of a mask or device")
	end
end
click("Предложить выкуп");click("Оригинал")
local challenges=env.require(shared.Challenges)
for _,tool in ipairs(Config.ToolsOrder)do
	local c=challenges.New(tool,9173,clock);c.id="task_"..tool
	profile.case.challenge=challenges.Public(c);networkState:Fire(profile);services.RunService.RenderStepped:Fire(.016)
	local cancel=click("Отменить исследование")
	expect(cancel~=nil and net.Action.sent[#net.Action.sent].name=="CancelInspection","Every instrument must render usable controls inside the compact working panel")
end
profile.case.challenge=nil
networkState:Fire({kind="open",panel="inventory"});clickCard(item.name)
local hasView=false;for _,n in ipairs(allNodes)do if n.ClassName=="ViewportFrame"and shown(n)then hasView=true end end
expect(hasView,"An owned item must open a visible 3D inspection, not just a carry button")
networkState:Fire({kind="open",panel="titles"});services.RunService.RenderStepped:Fire(.1);capture("titles")
local animated
for _,n in ipairs(allNodes)do if n.Name=="TitleEffect"and n:GetAttribute("TitleId")=="archivist"and shown(n)then animated=n;break end end
local moving=animated:FindFirstChild("OrbitingStar",true)
local beforeX,beforeY=moving.Position.X.Offset,moving.Position.Y.Offset;clock+=.6;services.RunService.RenderStepped:Fire(.1)
expect(moving.Position.X.Offset~=beforeX or moving.Position.Y.Offset~=beforeY,"Prestige titles must change actual ornament geometry, not only a text color")
click("Nametag")
for _,d in ipairs(identities.Nametags)do clickCard(d.name);services.RunService.RenderStepped:Fire(.1)end
clickCard("Vesper Veil");services.RunService.RenderStepped:Fire(.1);capture("nametags")
click("Надеть")
expect(net.Action.sent[#net.Action.sent].name=="BuyNametag"and net.Action.sent[#net.Action.sent].data.id=="tag_vesper","Nametag selection must equip only the nickname layer")
expect(profile.title=="archivist"and profile.equippedDecor.card=="card_geode","Previewing or buying a nametag must leave title and background independent")
click("Фон / рамка");clickCard("Полярный поток");click("Надеть")
expect(net.Action.sent[#net.Action.sent].name=="BuyDecor"and net.Action.sent[#net.Action.sent].data.id=="card_boreal","The third section equips the card background independently")
click("Рамки портрета");clickCard("Крылья ветра");services.RunService.RenderStepped:Fire(.1);capture("profile-frames")
click("Надеть");expect(net.Action.sent[#net.Action.sent].data.id=="frame_wings","Portrait frames must remain independent from card backgrounds")
for _,p in ipairs({"workshop","specialty","guide","decor"})do networkState:Fire({kind="open",panel=p})end
services.UserInputService.InputBegan:Fire({KeyCode=enum.KeyCode.F8},false)
click("Ghost");click("0.1%");services.RunService.RenderStepped:Fire(.016);capture("fx-lab")
click("Образец на полку")
local last=net.Action.sent[#net.Action.sent]
expect(last.name=="Admin"and last.data.command=="sample"and last.data.mutation=="ghost"and last.data.uniqueness==.1,"FX lab must send explicit selected rarity to the server")
click("Все 8 вариантов на полки");expect(net.Action.sent[#net.Action.sent].data.command=="samples","A complete mutation comparison must be one visible button")
click("Игра и время");click("Остановить время");expect(net.Action.sent[#net.Action.sent].data.command=="pause","Timer pause must be reachable without scrolling the old admin grid")
networkState:Fire({kind="roster",rows={{userId=123,name="PROBA Player",title="archivist",nametag="tag_vesper",card="card_eclipse",frame="frame_rift",specialty="Everyday",reputation=75},
	{userId=456,name="Mira",title="collector",nametag="tag_prism",card="card_geode",frame="frame_facet",reputation=64},
	{userId=789,name="Rowan",title="eye",nametag="tag_maple",card="card_horizon",frame="frame_brass",reputation=43}}})
services.UserInputService.InputBegan:Fire({KeyCode=enum.KeyCode.Tab},false);services.RunService.RenderStepped:Fire(.1);capture("player-cards")
networkState:Fire({kind="exhibit",item=item,owner="TestPlayer",owned=true});services.RunService.RenderStepped:Fire(.016)
networkState:Fire({kind="receipt",name=item.name,value=120,quote=118,error=2,genuine=true,fee=43,rep=3,bought=85})
click("Следующий клиент")
for _,jointName in ipairs({"Right Shoulder","RightShoulder"})do
	local rig=node("Model","FriendRig",ws);local root=node("Part","HumanoidRootPart",rig);rig.PrimaryPart=root
	root.AssemblyLinearVelocity=Vector.new(8,0,0);rig:SetAttribute("ProbaWalking",true)
	local limb=node("Part","Arm",rig);local joint=node("Motor6D",jointName,rig);joint.Part0=root;joint.Part1=limb;joint.C0=CF.new();joint.Transform=CF.new()
	tagSignals.ProbaCustomer:Fire(rig);services.RunService.PreSimulation:Fire()
	expect(joint.Transform.angle~=nil and math.abs(joint.Transform.angle)>.01,"Both R6 and R15 friend joints must enter the actual animation path")
	rig:SetAttribute("ProbaNativeActive",true);joint.Transform=CF.new();services.RunService.PreSimulation:Fire()
	expect(joint.Transform.angle==nil,"Procedural motion must never overwrite a playing native avatar animation")
end
local neutralParent=node("Frame","DefaultCardContrast",localPlayer.PlayerGui)
local neutral=env.require(clientScripts.IdentityFX).Background(neutralParent,"card_paper",270,88)
for _,n in ipairs(neutral:GetDescendants())do
	if n.ClassName=="UIGradient"and n.Color then
		for _,value in ipairs(n.Color)do
			local colors=if value.R then{value}else value
			for _,point in ipairs(colors)do
				local c=if point.R then point else point[2]
				expect(c.R*.2126+c.G*.7152+c.B*.0722<.3,"The default card must keep every background gradient stop dark enough for its white nickname")
			end
		end
	end
end
neutralParent:Destroy()
print("PASS actual client constructors and actions:",assertions,"assertions")

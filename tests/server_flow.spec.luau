local Config=env.require(shared.Config)
local Domain=env.require(shared.Domain)
local Catalog=env.require(services.ServerScriptService.Catalog)
for _,def in ipairs(Catalog)do local model=node("Model",def.id,models);model.PrimaryPart=node("Part","Anchor",model)end
env.require(services.ServerScriptService.Game)
local Profiles=env.require(services.ServerScriptService.Profiles)
local Customers=env.require(services.ServerScriptService.Customers)
local function makePlayer(name,id)
	local p=node("Player",name,players);p.UserId=id;p.DisplayName=name
	local backpack=node("Backpack","Backpack",p);p.Backpack=backpack
	local character=node("Model",name.."Character",ws);p.Character=character
	character.PrimaryPart=node("Part","HumanoidRootPart",character);node("Humanoid","Humanoid",character)
	p.CharacterAdded=signal();players.PlayerAdded:Fire(p)
	return p
end
local alice=makePlayer("Alice",123);local bob=makePlayer("Bob",456)
local pA,pB=Profiles.loaded[alice],Profiles.loaded[bob]
local plotA,plotB=plotFolder.Plot01,plotFolder.Plot02
expect(plotA:GetAttribute("OwnerId")==123 and plotB:GetAttribute("OwnerId")==456,"Different players must reserve different vacant plots")
expect(pA.cash==750 and pB.baseLevel==1,"First arrival needs a usable starter profile")
local function desk(player,plot)
	player.Character:PivotTo(plot.Anchor.CFrame*CF.new(0,3,7))
	if plot:GetAttribute("OwnerId")==player.UserId then
		local seat=plot.Building:FindFirstChild("AppraiserSeat",true)
		seat.Occupant=player.Character:FindFirstChildOfClass("Humanoid");seat:GetPropertyChangedSignal("Occupant"):Fire()
	end
end
desk(alice,plotA);desk(bob,plotB)
local function action(player,name,packet)clock+=1;remote.OnServerEvent:Fire(player,name,packet or {})end
local function latest(player,kind)
	for i=#state.sent,1,-1 do local event=state.sent[i];if event.player==player and event.packet.kind==kind then return event.packet end end
	return nil
end
local function customer(player,definition,genuine)
	local item=Customers.NewItem(definition,0);item.genuine=genuine;item.condition=.9;item.demand=1
	local r={id="case_"..item.uid,item=item,name="Test client",tests={},patience=1,mood="neutral",negotiations=0,arrived=true,moveToken=0,slot=1}
	Customers.sessions[player].queue={r};return r
end
local def=Catalog[1]
local r=customer(alice,def,true)
local before=pA.cash
action(alice,"Complete",{caseId=r.id,quote=0/0,auth="genuine"})
expect(pA.cash==before and #Customers.sessions[alice].queue==1,"NaN must not pay out or consume a case")
action(alice,"Complete",{caseId="stale",quote=20,auth="genuine"})
expect(pA.cash==before,"A stale or invented case ID must not create currency")
action(alice,"Inspect",{caseId=r.id,tool="spectro"})
expect(r.tests.spectro==nil,"A client cannot use equipment that has not been purchased")
action(alice,"Inspect",{caseId=r.id,tool="scale"})
expect(r.busy~=nil and r.tests.scale==nil,"Instrument research must take time")
clock+=3
for _,job in ipairs(delayed)do if job.due<=clock then job.fn() end end;delayed={}
expect(r.tests.scale and r.busy==nil,"A completed instrument run must add evidence to the same active case")
local value=Domain.trueValue(def,r.item)
action(alice,"Complete",{caseId=r.id,quote=value,auth="genuine"})
expect(pA.cash>before and pA.reputation==3 and pA.stats.good==1,"Accurate appraisal pays once and improves reputation")
local paid=pA.cash
action(alice,"Complete",{caseId=r.id,quote=value,auth="genuine"})
expect(pA.cash==paid and pA.stats.good==1,"Replaying completion must not pay again")
r=customer(alice,Catalog[4],false);value=Domain.trueValue(Catalog[4],r.item)
action(alice,"Offer",{caseId=r.id,quote=value,auth="replica",amount=1})
expect(r.negotiations==1 and #pA.inventory==0,"An insufficient purchase offer must be rejected without transferring the item")
local amount=r.counter;before=pA.cash
action(alice,"Offer",{caseId=r.id,quote=value,auth="replica",amount=amount})
expect(#pA.inventory==1 and pA.inventory[1].paid==amount and pA.cash<before+100,"An accepted buyout must debit the buyer and create exactly one owned item")
local item=pA.inventory[1]
action(alice,"Carry",{uid=item.uid})
expect(latest(alice,"snapshot").heldUid==item.uid,"Owned items must be physically carryable")
desk(alice,plotB)
plotB.Building.Interaction.AppraisalPrompt.Triggered:Fire(alice)
local pending=latest(bob,"snapshot").pending
expect(pending and latest(alice,"snapshot").available==pA.cash-40,"Visiting another desk must create a request and reserve the fee")
action(bob,"PeerAccept",{id=pending.id})
expect(latest(bob,"snapshot").peer~=nil,"The appraiser must explicitly accept a visitor's case")
local aCash,bCash=pA.cash,pB.cash
action(bob,"Complete",{caseId=pending.id,quote=value,auth="replica"})
expect(pA.cash==aCash-40 and pB.cash==bCash+40 and #item.reports==1,"Independent appraisal must transfer the reserved fee and append an expert report")
expect(latest(alice,"snapshot").available==pA.cash,"Completion must release the fee reservation")
action(bob,"Complete",{caseId=pending.id,quote=value,auth="replica"})
expect(pB.cash==bCash+40 and #item.reports==1,"Independent reports must not pay twice")
item.lastReportAt=0
plotB.Building.Interaction.AppraisalPrompt.Triggered:Fire(alice)
pending=latest(bob,"snapshot").pending
action(bob,"PeerDecline",{id=pending.id})
expect(latest(alice,"snapshot").available==pA.cash and pA.cash==aCash-40,"Declined requests must release funds without charging")
before=pA.cash
studio=false
action(alice,"Admin",{command="funds"})
expect(pA.cash==before,"An ordinary production player must not execute Studio admin commands")
studio=true
action(alice,"Admin",{command="funds"});action(alice,"Admin",{command="reputation"})
desk(alice,plotA)
action(alice,"UpgradeBase")
expect(pA.baseLevel==2 and plotA:FindFirstChild("Building")~=nil,"A paid upgrade must replace the occupied plot with a valid next-stage building")
desk(alice,plotA)
action(alice,"UpgradeTool",{tool="uv"})
expect(pA.equipment.uv==1,"Purchased equipment must become usable")
action(alice,"Specialty",{spec="Archaeologist"})
expect(pA.specialty=="Archaeologist" and pA.specXP.Everyday>0,"Changing specialty must preserve the previous qualification")
before=pA.cash;action(alice,"Specialty",{spec="Everyday"});action(alice,"Specialty",{spec="Archaeologist"})
expect(pA.cash==before,"Changing learned professions must not charge the player again")
action(alice,"Title",{id="collector"})
expect(pA.title=="trainee","Locked title cosmetics must not be equippable by a forged request")
action(alice,"Admin",{command="titles"});action(alice,"Title",{id="collector"})
expect(pA.title=="collector","Studio testers must be able to preview unlocked title frames without grinding")
alice.Character:PivotTo(CF.new(0,3,1000))
before=pA.cash
action(alice,"Sell",{uid=item.uid})
expect(#pA.inventory==0 and pA.cash>before,"The physical broker must buy an owned, unreserved item")
action(alice,"Sell",{uid=item.uid})
expect(#pA.inventory==0,"The same inventory item cannot be sold twice")
players.PlayerRemoving:Fire(alice)
expect(plotA:GetAttribute("OwnerId")==nil and Profiles.loaded[alice]==nil,"Leaving must release the plot and profile")

-- Production persistence: foreign locks and unavailable storage must never overwrite good data.
studio=false
fakeStore.records.u_789={cash=99999,lock={id="another-server",expires=os.time()+120}}
local locked=makePlayer("Locked",789)
expect(Profiles.sessions[locked].mode=="session" and fakeStore.records.u_789.cash==99999,"An active foreign session must fall back without overwriting persistent data")
Profiles.loaded[locked].cash=1;Profiles.Save(locked,false)
expect(fakeStore.records.u_789.cash==99999,"Session-only profiles must never save over a foreign lock")
fakeStore.records.u_790={cash=1287,lock={id="expired-server",expires=os.time()-1}}
local recovered=makePlayer("Recovered",790)
expect(Profiles.sessions[recovered].mode=="cloud" and Profiles.loaded[recovered].cash==1287,"An expired lock must preserve and recover the stored profile")
Profiles.loaded[recovered].cash=1350
expect(Profiles.Save(recovered,false) and fakeStore.records.u_790.cash==1350,"Autosave must write the authoritative profile while retaining its own lock")
expect(Profiles.Save(recovered,true) and fakeStore.records.u_790.lock==nil,"Shutdown save must release its persistent session lease")
fakeStore.fail=true
local offline=makePlayer("Offline",791)
expect(Profiles.sessions[offline].mode=="session" and Profiles.loaded[offline].cash==750,"Storage outage must produce an explicitly unsaved starter session")
fakeStore.fail=false
studio=true
print("PASS authoritative server flow:",assertions,"assertions")

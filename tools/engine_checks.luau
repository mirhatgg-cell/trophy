local function player(id,name)
 local p=Instance.new('Player',Players); p.UserId=id; p.DisplayName=name; p:LoadCharacterAsync(); Players.PlayerAdded:Fire(p); advance(.5); return p
end
local function call(p,action,data) remote.OnServerEvent:Fire(p,action,data or {}); advance(.3) end
local function last(p,kind) for i=#remote.messages,1,-1 do local m=remote.messages[i]; if m.player==p and m.kind==kind then return m.data end end end
local owner=player(42,'Creator'); local visitor=player(99,'Visitor')
assert(workspace:GetAttribute('MountainverseServerReady'),'Server failed to initialize')
assert(last(owner,'profile'),'UI did not receive a profile')
if OFFLINE then
 assert(not last(owner,'profile').persistent,'Unavailable DataStore must not be used')
 call(owner,'admin',{command='play',id=1}); advance(5)
 assert(last(owner,'round').gameId==1,'Offline local trial could not start')
 print('PASS: unpublished-place DataStore initialization failure still permits world startup, profile handshake, admin and local trial')
else
 local ownerRoot=owner.Character:FindFirstChild('HumanoidRootPart')
 owner.Character:PivotTo(CFrame.new(cabFixture.Position+Vector3.new(0,4,0)))
 cabFixture:FindFirstChildOfClass('ProximityPrompt').Triggered:Fire(owner); advance(5)
 assert(ownerRoot.Position.Y>30,'Upward lift did not carry the rider')
 visitor.Character:PivotTo(CFrame.new(lowerFixture.Position+Vector3.new(0,4,0)))
 lowerFixture:FindFirstChildOfClass('ProximityPrompt').Triggered:Fire(visitor); advance(5)
 assert(ownerRoot.Position.Y<8,'Lower-floor call did not return lift and rider')
 RunService.studio=false
 call(visitor,'admin',{command='coins'}); assert(last(visitor,'profile').data.coins==0,'Unauthorized currency')
 call(owner,'admin',{command='coins'}); call(owner,'buy',{id='trail_mint'}); call(owner,'buy',{id='trail_mint'})
 assert(last(owner,'profile').data.coins==9910,'Purchase was not idempotent')
 call(owner,'admin',{command='level',id=1,level=20}); assert(C.Level(last(owner,'profile').data.trophies['1'].wins)==20)
 call(owner,'admin',{command='achievements'})
 local museum=workspace:FindFirstChild('Museum_'..owner.UserId,true); assert(museum and #museum:FindFirstChild('Figures'):GetChildren()==50,'All fifty architectural trophy icons must build')
 -- Every engine branch runs through its full first round and four further random rounds.
 for id=1,50 do
  local messageStart=#remote.messages
  call(owner,'admin',{command='play',id=id}); advance(1)
  assert(last(owner,'round').gameId==id,'Incorrect first trial '..id)
  if id==1 then owner.CharacterAdded:Fire(owner.Character); advance(.3); assert(owner.Character:FindFirstChild('HumanoidRootPart').Position.Y< -100,'Preparation character callback displaced player to lobby') end
  advance(550)
  assert(last(owner,'match')==false,'Run stuck: '..id)
  assert(#failures==0,table.concat(failures,'\n'))
  local byRound={}; for j=messageStart+1,#remote.messages do local m=remote.messages[j]; if m.kind=='round' and m.player==owner then byRound[m.data.round]=m.data.gameId end end
  local seen={}; for r=1,5 do assert(byRound[r] and not seen[byRound[r]],'Missing/repeated round '..id..':'..r); seen[byRound[r]]=true end
 end
 call(owner,'join',{id=1}); call(visitor,'join',{id=1}); call(owner,'start'); advance(2)
 call(owner,'admin',{command='force',id=1}); call(owner,'admin',{command='next'}); advance(10)
 local architect=last(owner,'round').controller and owner or last(visitor,'round').controller and visitor
 assert(architect,'No tetris architect'); call(architect,'control',{column=5,rotate=true}); advance(.2)
 assert(last(architect,'control').column==5,'Architect controls failed')
 call(owner,'admin',{command='line'}); advance(3)
 local cleared=false; for _,message in ipairs(remote.messages) do if message.kind=='sound' and message.data.phase=='line' then cleared=true end end
 assert(cleared,'Tetris board did not remove the prepared complete row')
 local runs=last(owner,'profile').data.runs
 call(owner,'admin',{command='stop'}); advance(8)
 assert(last(owner,'match')==false and last(owner,'profile').data.runs==runs,'Cancelled run was credited or did not stop')
 assert(#failures==0,'Server failure: '..table.concat(failures,'\n'))
 print('PASS: 50 distinct state machines, 250 round lifecycles, purchases, server admin permissions, trophy level 20, lift calls and passenger carry, multiplayer tetris controls, actual row clear, cancellation')
end

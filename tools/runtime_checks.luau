local function player(id,name)
 local p=Instance.new('Player',Players); p.UserId=id; p.DisplayName=name; p:LoadCharacterAsync(); Players.PlayerAdded:Fire(p); advance(.5); return p
end
local function call(p,action,data) remote.OnServerEvent:Fire(p,action,data or {}); advance(.3) end
local function last(p,kind)
 for i=#remote.messages,1,-1 do local m=remote.messages[i]; if m.player==p and m.kind==kind then return m.data end end
end
local owner=player(42,'Creator')
local visitor=player(99,'Visitor')
assert(last(owner,'profile').persistent,'DataStore fixture should be used')
RunService.studio=false
call(visitor,'admin',{command='coins'})
assert(last(visitor,'profile').data.coins==0,'Non-admin received currency')
call(owner,'admin',{command='coins'})
assert(last(owner,'profile').data.coins==10000,'Creator admin command failed')
call(owner,'buy',{id='trail_mint'})
assert(last(owner,'profile').data.coins==9910 and last(owner,'profile').data.owned.trail_mint,'Shop purchase failed')
call(owner,'buy',{id='trail_mint'})
assert(last(owner,'profile').data.coins==9910,'Duplicate purchase charged twice')
call(owner,'equip',{id='hat_orbit'})
assert(not last(owner,'profile').data.equipped.hat,'Unowned item equipped')
call(owner,'admin',{command='level',id=1,level=2})
assert(last(owner,'profile').data.trophies['1'].wins==3,'Three wins should grant tier 2')
call(owner,'admin',{command='level',id=1,level=20})
assert(C.Level(last(owner,'profile').data.trophies['1'].wins)==20,'Tier 20 unavailable')
call(owner,'admin',{command='mutation',id=1,mutation=3})
assert(last(owner,'profile').data.trophies['1'].mutation=='Галактическая','Mutation command failed')
call(owner,'join',{id=1})
call(owner,'configure',{max=2,access='invite',invite=99})
call(visitor,'join',{id=1})
assert(#last(owner,'pod').members==2,'Invitation admission failed')
call(visitor,'configure',{difficulty=3})
assert(last(owner,'pod').difficulty==2,'Non-leader changed difficulty')
call(owner,'configure',{difficulty=1})
assert(last(visitor,'pod').difficulty==1,'Leader configuration did not replicate')
call(visitor,'leave')
assert(#last(owner,'pod').members==1,'Leaving party failed')
call(owner,'leave')
-- Execute every catalog variant via real server match code, with virtual time.
for id=1,50 do
 local messageStart=#remote.messages
 local before=last(owner,'profile').data.runs
 call(owner,'admin',{command='play',id=id}); advance(1)
 assert(last(owner,'match')==true,'Match did not start: '..id)
 assert(last(owner,'round').gameId==id,'Forced game not selected: '..id)
 advance(215)
 assert(last(owner,'match')==false,'Five-round match did not finish: '..id)
 assert(last(owner,'profile').data.runs==before+1,'Completed run not credited: '..id)
 local seen,byRound={},{}
 for j=messageStart+1,#remote.messages do
  local message=remote.messages[j]
  if message.player==owner and message.kind=='round' then byRound[message.data.round]=message.data.gameId end
 end
 for round=1,5 do local chosen=byRound[round]; assert(chosen and not seen[chosen],'Missing or repeated game in five-round run'); seen[chosen]=true end
end
-- Exercise the multiplayer architect path and manual drop commands.
call(owner,'join',{id=2}); call(visitor,'join',{id=2}); call(owner,'start')
local controller=last(owner,'round').controller and owner or (last(visitor,'round').controller and visitor)
-- First random game may not be tetris: set the next round explicitly.
call(owner,'admin',{command='force',id=1}); call(owner,'admin',{command='next'}); advance(4.2)
controller=last(owner,'round').controller and owner or (last(visitor,'round').controller and visitor)
assert(controller,'No architect selected for multiplayer tetris')
call(controller,'control',{column=5,rotate=true,drop=true}); advance(2)
assert(last(controller,'control').column==5,'Architect controls not acknowledged')
assert(#failures==0,'Server error: '..table.concat(failures,'\n'))
print('PASS: access control, shop idempotence, trophy tiers, mutations, invitations, leader permissions, 50 full runs / 250 rounds, multiplayer architect controls')

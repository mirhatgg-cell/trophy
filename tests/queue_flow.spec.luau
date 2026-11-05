-- Exercise Finish -> actual reorder -> actual MoveTo path, with long-waiting NPCs.
-- The substitute humanoid reaches each waypoint immediately; this is not physics.
local timing=env.require(shared.CustomerTiming)
local session=Customers.sessions[bob]
Customers.Flush(bob)
local waiting={}
for i=1,5 do
	local model=node("Model","QueueRegression_"..i,ws.Customers)
	local root=node("Part","HumanoidRootPart",model);root.CFrame=session.plot.Anchor.CFrame*CF.new(i*4,3,-5)
	model.PrimaryPart=root
	local humanoid=node("Humanoid","Humanoid",model)
	humanoid.MoveTo=function(_,target)
		expect(session.plot.Anchor.CFrame:PointToObjectSpace(target).Z>-10,"An already indoor visitor must never be sent out through the street entrance on promotion")
		root.CFrame=CF.new(target)
	end
	waiting[i]={id="queued_"..i,item=Customers.NewItem(Catalog[1],0),name="Waiting "..i,
		model=model,humanoid=humanoid,arrived=true,slot=i,moveToken=0,age=600,
		patience=.7,tests={},negotiations=0,clockPhase="queue"}
end
session.queue=table.clone(waiting)
local originalSpawn=taskMock.spawn
local journeys={}
local cancelledJourney
taskMock.spawn=function(fn)table.insert(journeys,fn)end
for completed=1,4 do
	clock+=150
	journeys={}
	if completed==2 then waiting[3].arrived=false;waiting[3].inside=true end
	Customers.Finish(bob,"happy")
	expect(#session.queue==5-completed and waiting[completed].leaving,"Only the completed customer must leave")
	for _,record in ipairs(session.queue)do
		expect(not timing.Expired(record,clock+1),"Promotion must start a new route deadline despite six hundred seconds of waiting")
	end
	-- reorder starts one movement job per remaining customer, then the departing job.
	for i=1,#session.queue do journeys[i]()end
	if completed==1 then cancelledJourney=journeys[2]
	elseif completed==2 then
		cancelledJourney()
		expect(waiting[3].walking==false and waiting[3].arrived,"A late cancelled task must not reactivate walking or disturb a newer arrival")
	end
	local active=Customers.Active(bob)
	expect(active==waiting[completed+1]and active.slot==1,"The actual next visitor must reach and become active at the counter")
	for i,record in ipairs(session.queue)do
		expect(record.arrived and record.slot==i and not record.routeFailed,"All remaining visitors must advance to their own slots")
	end
	timing.Step(active,true,1,clock,false)
	expect(active.patience==1 and active.clockPhase=="service","Reaching the desk gives the promoted visitor their own fresh service clock")
end
taskMock.spawn=originalSpawn
Customers.Flush(bob)
print("PASS queued visitors: four successive completions advance the real queue without expiring waiters")

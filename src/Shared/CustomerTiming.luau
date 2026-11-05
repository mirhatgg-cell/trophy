-- One clock per visitor. Waiting never consumes the service budget.
local Timing={ServiceSeconds=300,QueueSeconds=900,ServiceGrace=20}
-- Loading and every individual journey have their own deadlines. A visitor may
-- wait for several appraisals before moving again; their total age is irrelevant.
function Timing.StartRoute(record,now,seconds)
	record.arrived=false;record.routeFailed=false
	record.loadingDeadline=nil;record.routeDeadline=now+seconds
end
function Timing.Arrive(record)
	record.arrived=true;record.routeDeadline=nil;record.loadingDeadline=nil;record.routeFailed=false
end
function Timing.Expired(record,now)
	if record.leaving then return false end
	if record.patience<=0 or record.routeFailed then return true end
	if record.arrived then return false end
	local deadline=record.routeDeadline or record.loadingDeadline
	return deadline~=nil and now>deadline
end
function Timing.Step(record,serving,dt,now,paused)
	if not record.arrived or record.leaving then return end
	local phase=if serving then "service"else "queue"
	local seed=record.item and record.item.visualSeed or 1
	if record.clockPhase~=phase then
		record.clockPhase=phase
		record.clockBudget=if serving then Timing.ServiceSeconds+seed%61 else Timing.QueueSeconds+seed%181
		if serving then record.patience=1;record.graceUntil=now+Timing.ServiceGrace end
	end
	record.clockPaused=paused==true or (serving and record.busy~=nil and now<record.busy.deadline)
		or (record.graceUntil or 0)>now or (record.servicePausedUntil or 0)>now
	if not record.clockPaused then record.patience=math.max(0,(record.patience or 1)-math.clamp(dt,0,5)/record.clockBudget)end
	record.remainingSeconds=math.ceil(record.patience*record.clockBudget+math.max(0,(record.graceUntil or 0)-now))
end
function Timing.Public(record)
	return {seconds=record.remainingSeconds or Timing.ServiceSeconds,paused=record.clockPaused==true,
		phase=record.clockPhase or "queue"}
end
return Timing

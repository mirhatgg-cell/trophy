-- One clock per visitor. Waiting never consumes the service budget.
local Timing={ServiceSeconds=300,QueueSeconds=900,ServiceGrace=20}
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

-- Instrument tasks are explicit server-owned state machines; clients submit actions, never a score.
local Domain=require(if script then script.Parent.Domain else "./Domain")
local Challenges={}
local kinds={loupe=true,scale=true,uv=true,spectro=true,diagnostic=true}
function Challenges.New(tool,seed,now)
	assert(kinds[tool],"Unknown instrument")
	local c={tool=tool,started=now,deadline=now+90,lastStep=now-.2,progress=0,found={},amount=0,tared=false,
		target=20+math.floor(Domain.hash(seed,71)*13)*5,angle=0,gears={},spots={}}
	for i=1,3 do
		c.spots[i]={x=.25+Domain.hash(seed,91+i)*.5,y=.24+Domain.hash(seed,103+i)*.48}
		c.gears[i]=1+math.floor(Domain.hash(seed,131+i)*3)
	end
	if tool=="spectro" then c.target=math.floor(Domain.hash(seed,151)*24)*15;c.angle=(c.target+315)%360 end
	return c
end
function Challenges.Ready(c)
	if c.tool=="loupe" then return c.progress==3 end
	if c.tool=="uv" then return c.progress==4 end
	if c.tool=="scale" then return c.tared and c.amount==c.target end
	if c.tool=="spectro" then return c.angle==c.target end
	return c.gears[1]==0 and c.gears[2]==0 and c.gears[3]==0
end
function Challenges.Public(c)
	local out={id=c.id,tool=c.tool,progress=c.progress,found=table.clone(c.found),amount=c.amount,tared=c.tared,
		target=c.target,angle=c.angle,gears=table.clone(c.gears),spots={},ready=Challenges.Ready(c)}
	for _,spot in ipairs(c.spots)do table.insert(out.spots,table.clone(spot))end
	return out
end
function Challenges.Step(c,action,value,now)
	if now>c.deadline then return false,false,"Время исследования истекло. Начни заново." end
	if now<c.started or now-c.lastStep<.075 then return false,false,"Двигай прибор немного медленнее." end
	local valid=false
	if action=="finish" then
		valid=Challenges.Ready(c)
	elseif c.tool=="loupe" and action=="sample" and type(value)=="table" and Domain.finite(value.x) and Domain.finite(value.y) then
		for i,spot in ipairs(c.spots)do
			if not c.found[i] and (value.x-spot.x)^2+(value.y-spot.y)^2<=.075^2 then c.found[i]=true;c.progress+=1;valid=true;break end
		end
	elseif c.tool=="uv" and action=="zone" and Domain.finite(value) and value%1==0 and value>=1 and value<=4 and not c.found[value] then
		c.found[value]=true;c.progress+=1;valid=true
	elseif c.tool=="scale" then
		if action=="tare" and not c.tared then c.tared=true;c.amount=0;valid=true
		elseif action=="weight" and c.tared and Domain.finite(value) and table.find({-20,-5,-1,1,5,20},value) then c.amount=math.clamp(c.amount+value,-120,120);valid=true end
	elseif c.tool=="spectro" and action=="rotate" and (value==15 or value==-15) then
		c.angle=(c.angle+value)%360;valid=true
	elseif c.tool=="diagnostic" and action=="gear" and Domain.finite(value) and value%1==0 and value>=1 and value<=3 then
		c.gears[value]=(c.gears[value]+1)%4;valid=true
	end
	if not valid then return false,false,"Сначала совмести метки прибора и собери наблюдения." end
	c.lastStep=now
	local finished=Challenges.Ready(c) and now-c.started>=.8
	return true,finished,if finished then "Наблюдения записаны" elseif Challenges.Ready(c) then "Подтверди показания" else "Продолжай исследование"
end
return Challenges

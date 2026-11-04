local Challenges=require("../src/Shared/Challenges")
local n=0
local function expect(v,why)n+=1;assert(v,why)end
for _,tool in ipairs({"loupe","scale","uv","spectro","diagnostic"})do
	local c=Challenges.New(tool,9173,10)
	local ok,done=Challenges.Step(c,"finish",nil,11)
	expect(not ok and not done,"An idle instrument must not produce evidence after merely waiting")
	local now=12
	local function step(action,value)now+=.2;local valid,complete=Challenges.Step(c,action,value,now);expect(valid,"Legitimate instrument control rejected");return complete end
	if tool=="loupe" then for _,spot in ipairs(c.spots)do step("sample",{x=spot.x,y=spot.y})end
	elseif tool=="uv" then for i=1,4 do step("zone",i)end
	elseif tool=="scale" then step("tare");while c.amount<c.target do local d=c.target-c.amount;step("weight",if d>=20 then 20 elseif d>=5 then 5 else 1)end
	elseif tool=="spectro" then while c.angle~=c.target do step("rotate",15)end
	else for i=1,3 do while c.gears[i]~=0 do step("gear",i)end end end
	expect(Challenges.Ready(c),"The solved instrument must reach a ready state")
	local _,finished=Challenges.Step(c,"finish",nil,now+.2)
	expect(finished,"A solved instrument must finalize its evidence")
	local expired=Challenges.New(tool,17,0);local accepted=Challenges.Step(expired,"finish",nil,91)
	expect(not accepted,"Expired instrument cases must be rejected")
end
local c=Challenges.New("scale",1,0)
expect(not Challenges.Step(c,"weight",math.huge,1),"Infinite weights must be rejected")
print("PASS instrument challenges:",n,"assertions")

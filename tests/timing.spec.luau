local T=require("../src/Shared/CustomerTiming")
local count=0
local function check(v,why)count+=1;assert(v,why)end
local records={}
for i=1,5 do records[i]={arrived=true,patience=1,item={visualSeed=i*17}}end
for now=1,390 do for i,r in ipairs(records)do T.Step(r,i==1,1,now,false)end end
check(records[1].patience==0,"The first visitor should eventually exhaust only their own service budget")
for i=2,5 do check(records[i].patience>.55,"A complete first service must not empty the waiting queue")end
T.Step(records[2],true,1,391,false)
check(records[2].patience==1 and records[2].remainingSeconds>=300,"Promotion grants a fresh independent service clock")
records[2].busy={deadline=650}
for now=392,520 do T.Step(records[2],true,1,now,false)end
check(records[2].patience==1,"Hands-on research pauses the current visitor's timer")
T.Step(records[3],false,1,521,false)
check(records[3].patience<records[4].patience,"Visitors must have independent elapsed waiting time")
local before=records[3].patience;T.Step(records[3],false,1,522,true)
check(records[3].patience==before,"The admin pause must stop the selected bureau clock")
local late={arrived=false,patience=1,item={visualSeed=1}}
T.Step(late,true,5,1000,false);check(late.patience==1,"Travel and avatar loading must not consume patience")
for _,waited in ipairs({61,300,600,899})do
	local nextVisitor={arrived=true,patience=.4,age=waited,item={visualSeed=7}}
	T.StartRoute(nextVisitor,waited,45)
	check(not T.Expired(nextVisitor,waited+1),"A long wait must not expire a freshly promoted route")
	T.Arrive(nextVisitor);T.Step(nextVisitor,true,1,waited+8,false)
	check(not T.Expired(nextVisitor,waited+900)and nextVisitor.patience==1,"Arriving clears the route deadline and grants fresh service time")
end
T.StartRoute(late,1000,45)
check(not T.Expired(late,1044)and T.Expired(late,1046),"A genuinely stuck route must still have a finite independent timeout")
late.loadingDeadline=2000;late.routeDeadline=nil
check(not T.Expired(late,1999)and T.Expired(late,2001),"Avatar loading has a separate bounded lifetime")
print("PASS independent customer clocks:",count,"assertions")

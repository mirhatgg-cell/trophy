local Layout=require("../src/Shared/HUDLayout")
local n=0
local function check(ok,why)n+=1;assert(ok,why)end
for _,size in ipairs({{1458,680},{1280,720},{1024,600},{1920,1080},{390,800}})do
	local w,h=unpack(size);local l=Layout.Compute(w,h)
	for _,key in ipairs({"wallet","brand","dock","case","manager","tutorial"})do
		local r=l[key];check(r.x>=0 and r.y>=0 and r.x+r.w<=w and r.y+r.h<=h,"HUD must fit viewport: "..key)
	end
	local passive=l.wallet.w*l.wallet.h+l.brand.w*l.brand.h+l.dock.w*l.dock.h+l.tutorial.w*l.tutorial.h+8000
	check(passive/(w*h)<.14,"Passive HUD must not cover the world with dashboard panels")
	if w>=700 then check((passive+l.case.w*l.case.h)/(w*h)<.30,"Working HUD must keep at least seventy percent of the screen unobstructed")end
end
print("PASS responsive HUD bounds:",n,"assertions")

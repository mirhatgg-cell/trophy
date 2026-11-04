local Rarity=require("../src/Shared/Rarity")
local n=0
local function expect(v,why)n+=1;assert(v,why)end
local total=0
for _,id in ipairs(Rarity.Order)do
	local slots=10000000/Rarity.Definitions[id].odds
	for _,ticket in ipairs({total+1,total+slots})do
		local rng={NextInteger=function(_,_,maximum)return if maximum==10000000 then ticket else 1000 end}
		local mutation,unique=Rarity.Roll(rng)
		expect(mutation==id and unique==0,"Mutation range boundaries must implement the published exact odds")
	end
	total+=slots
end
local rng={step=0}
function rng:NextInteger(_,maximum)if maximum==10000000 then return maximum end;self.step+=1;return if self.step==1 then 1 else 1000 end
local mutation,unique=Rarity.Roll(rng)
expect(mutation=="none"and unique==.1,"The first uniqueness increment is independent and occurs on the 1/1000 branch")
expect(Rarity.Multiplier({mutation="gold",uniqueness=.1})>Rarity.Multiplier({mutation="silver",uniqueness=0}),"Mutation and uniqueness must both participate in collectible market value")
print("PASS collectible rarity:",n,"assertions")

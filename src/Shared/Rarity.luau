local Rarity={}
Rarity.Order={"silver","gold","ghost","verdant","glacial","ember","astral"}
Rarity.Definitions={
	silver={name="Silver",odds=1000,multiplier=1.4,color={190,202,208}},
	gold={name="Gold",odds=10000,multiplier=2,color={225,181,66}},
	ghost={name="Ghost",odds=50000,multiplier=2.8,color={193,224,225}},
	verdant={name="Verdant",odds=100000,multiplier=3.4,color={85,151,91}},
	glacial={name="Glacial",odds=250000,multiplier=4.2,color={157,219,242}},
	ember={name="Ember",odds=1000000,multiplier=6,color={236,131,64}},
	astral={name="Astral",odds=10000000,multiplier=10,color={101,124,211}},
}
function Rarity.Roll(random)
	local ticket=random:NextInteger(1,10000000)
	local mutation="none"
	for _,id in ipairs(Rarity.Order)do
		local slots=10000000/Rarity.Definitions[id].odds
		if ticket<=slots then mutation=id;break end
		ticket-=slots
	end
	local steps=0
	while steps<1000 and random:NextInteger(1,1000)==1 do steps+=1 end
	return mutation,steps/10
end
function Rarity.Multiplier(item)
	local def=Rarity.Definitions[item.mutation]
	return (if def then def.multiplier else 1)*(1+math.clamp(item.uniqueness or 0,0,100)*.25)
end
function Rarity.Caption(item)
	local def=Rarity.Definitions[item.mutation]
	return (if def then def.name else "Обычный").." · уникальность "..string.format("%.1f%%",item.uniqueness or 0)
end
return Rarity

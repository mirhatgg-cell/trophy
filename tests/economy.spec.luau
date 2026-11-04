local Domain = require("../src/Shared/Domain")
local Config = require("../src/Shared/Config")
local Catalog = require("../src/Server/Catalog")
local assertions = 0
local function expect(value, why) assertions += 1; assert(value, why) end
local function profile(spec, xp, rank)
	return { specialty = spec, specXP = { [spec] = xp }, equipment = { loupe = rank, scale = rank, uv = rank, spectro = rank, diagnostic = rank } }
end
expect(#Catalog == 100, "The prototype must contain exactly 100 authored items")
local names, ids, disciplines = {}, {}, {}
for _, d in ipairs(Catalog) do
	expect(not ids[d.id] and not names[d.name], "Catalogue identity collision")
	ids[d.id] = true; names[d.name] = true; disciplines[d.spec] = (disciplines[d.spec] or 0) + 1
	expect(Config.Specs[d.spec] ~= nil and d.value > 0 and d.weight > 0, "Incomplete appraisal metadata")
	local beginner = profile(d.spec, 0, 1)
	local expert = profile(d.spec, 3000, 3)
	local tests = {}
	for tool in pairs(expert.equipment) do tests[tool] = Domain.test(expert, d, { seed = 83, genuine = true, condition = 1 }, tool) end
	for _, genuine in ipairs({true, false}) do
		for _, condition in ipairs({0.35, 0.7, 1}) do
			local item = { seed = 12345, genuine = genuine, condition = condition, demand = 1 }
			local value = Domain.trueValue(d, item)
			expect(value >= 5 and value % 1 == 0, "Market value must be an integer and never negative")
			local low, high, confidence = Domain.estimate(beginner, d, item, {})
			expect(low < high and confidence > 0 and confidence < 100, "A beginner receives a usable range, never exact omniscience")
			local _, _, trainedConfidence = Domain.estimate(expert, d, item, tests)
			expect(trainedConfidence > confidence, "Training and relevant equipment must improve appraisal confidence")
			local correct = Domain.verdict(d, item, value, if genuine then "genuine" else "replica", 1, 1)
			local wrong = Domain.verdict(d, item, value * 3, if genuine then "replica" else "genuine", 1, 1)
			expect(correct.good and correct.rep > 0 and wrong.rep < 0 and correct.fee > wrong.fee, "Truthful accurate work must outperform a bad appraisal")
			local unknown = Domain.verdict(d, item, value, "unknown", 1, 1)
			expect(unknown.fee > wrong.fee and unknown.fee < correct.fee, "Honest uncertainty is distinct from a confidently wrong verdict")
			local minimum = Domain.minimumOffer(d, item, 1)
			expect(minimum > 0 and minimum < value, "Negotiation must leave a possible resale margin")
		end
	end
	local cross = profile(if d.spec == "Jeweler" then "Everyday" else "Jeweler", 3000, 3)
	local uncertainty = Domain.uncertainty(cross, d, tests)
	expect(uncertainty >= 0.26, "Instruments alone must not erase specialization")
end
for _, spec in ipairs(Config.SpecOrder) do expect(disciplines[spec] == 20, "Each discipline needs twenty items") end
expect(not Domain.finite(0/0) and not Domain.finite(math.huge) and not Domain.finite("500"), "Remote numeric validation rejects NaN, infinity and strings")
expect(Domain.specLevel(0) == 1 and Domain.specLevel(2430) == 10, "Qualification must span ten achievable levels")
expect(Config.BaseLevels[2].capacity > Config.BaseLevels[1].capacity and Config.BaseLevels[3].fee > Config.BaseLevels[2].fee, "Construction upgrades must change service capacity and income")
local intact={seed=17,genuine=true,condition=.95,demand=1,repair=false}
local restored=table.clone(intact);restored.repair=true
expect(Domain.trueValue({value=1000},restored)<Domain.trueValue({value=1000},intact),"A visible documented restoration must reduce market value without making an original counterfeit")
expect(Domain.test(profile("Everyday",2430,3),Catalog[1],restored,"uv").text:find("реставрация")~=nil,"UV findings must agree with the saved visible repair")
print("PASS economy/catalogue:", assertions, "assertions")

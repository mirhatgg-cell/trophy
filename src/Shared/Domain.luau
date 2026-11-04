-- Pure economy and assessment rules. This module also runs in the standalone Luau test suite.
local Domain = {}

function Domain.finite(n)
	return type(n) == "number" and n == n and n > -math.huge and n < math.huge
end

function Domain.money(n)
	return math.clamp(math.floor(n + 0.5), 0, 1000000000)
end

function Domain.hash(seed, salt)
	local n = (seed * 1664525 + salt * 1013904223) % 2147483647
	return (n % 100000) / 100000
end

function Domain.trueValue(def, item)
	local originality = if item.genuine then 1 else 0.16 + Domain.hash(item.seed, 13) * 0.19
	return math.max(5, Domain.money(def.value * (0.42 + item.condition * 0.58) * item.demand * originality))
end

function Domain.specLevel(xp)
	return math.min(10, 1 + math.floor(math.sqrt(math.max(0, xp) / 30)))
end

function Domain.uncertainty(profile, def, tests)
	local xp = profile.specXP[profile.specialty] or 0
	local matching = profile.specialty == def.spec
	local errorSize = if matching then 0.38 - (Domain.specLevel(xp) - 1) * 0.023 else 0.77
	local count = 0
	for tool, result in pairs(tests) do
		if result.relevant then
			count += 1
			errorSize -= 0.055 + (profile.equipment[tool] or 0) * 0.016
		end
	end
	return math.clamp(errorSize, if matching then 0.035 else 0.26, 0.85), count
end

function Domain.estimate(profile, def, item, tests)
	local spread, count = Domain.uncertainty(profile, def, tests)
	local value = Domain.trueValue(def, item)
	local bias = (Domain.hash(item.seed, 27 + count) * 2 - 1) * spread * 0.72
	local center = value * (1 + bias)
	return math.max(1, Domain.money(center * (1 - spread))), math.max(2, Domain.money(center * (1 + spread))), math.floor((1 - spread) * 100)
end

function Domain.relevant(tool, def)
	if tool == "loupe" or tool == "scale" then return true end
	if tool == "uv" then return def.spec ~= "Technician" end
	if tool == "spectro" then return def.kind ~= "letter" and def.kind ~= "map" and def.kind ~= "book" and def.kind ~= "scroll" end
	if tool == "diagnostic" then
		return def.spec == "Technician" or def.kind == "pocketwatch" or def.kind == "clock" or def.kind == "toycar"
	end
	return false
end

function Domain.test(profile, def, item, tool)
	local level = profile.equipment[tool] or 0
	local relevant = Domain.relevant(tool, def)
	if not relevant then return { relevant = false, text = "Этот метод не даёт полезных данных для данного предмета." } end
	local knowledge = if profile.specialty == def.spec then Domain.specLevel(profile.specXP[profile.specialty] or 0) else 0
	local quality = level * 0.21 + knowledge * 0.025
	local detects = Domain.hash(item.seed, 41 + #tool) < math.min(0.96, quality + 0.24)
	local text = ""
	if tool == "scale" then
		local convincingMass = Domain.hash(item.seed, 9) > 0.55
		local ratio = if item.genuine or convincingMass then 0.985 + Domain.hash(item.seed, 2) * 0.03 else 0.62 + Domain.hash(item.seed, 3) * 0.22
		local noise = (Domain.hash(item.seed, 5) - 0.5) * (0.09 / math.max(1, level))
		text = string.format("Масса: %.1f г. Справочный ориентир: %.1f г (возможны различия комплектации).", def.weight * (ratio + noise), def.weight)
	elseif tool == "loupe" then
		text = if not item.genuine and detects then "Клеймо «" .. def.mark .. "» имеет свежие края. Видны повторяющиеся следы современной формы."
			else "Наблюдение: «" .. def.mark .. "». " .. (if detects then "Износ согласуется с поверхностью; явных следов новодела не видно." else "Часть деталей неразличима. Одного наблюдения недостаточно.")
	elseif tool == "uv" then
		text = if not item.genuine and detects then "Неравномерная яркая флуоресценция: обнаружены современный связующий состав и искусственная патина."
			elseif item.condition < 0.65 then "Есть локальная реставрация. Она снижает стоимость, но сама по себе не доказывает подделку."
			else "Свечение слабое и однородное. Явные зоны свежего клея не обнаружены."
	elseif tool == "spectro" then
		text = if not item.genuine and detects then "Состав расходится с заявленным материалом «" .. def.material .. "». Вероятны покрытие или композит."
			else "Спектр близок к материалу «" .. def.material .. "». " .. (if detects then "Состав согласуется с заявленным." else "Точности пока недостаточно для окончательного вывода.")
	elseif tool == "diagnostic" then
		text = if not item.genuine and detects then "Обнаружены современные крепления и несоответствующая маркировке внутренняя сборка."
			elseif item.condition < 0.6 then "Обнаружены износ и заменённые элементы. Механизм нуждается в обслуживании."
			else "Схема и способ сборки согласуются с заявленным периодом; отклик стабилен."
	end
	return { relevant = true, text = text }
end

function Domain.verdict(def, item, quote, authenticity, patience, baseFee)
	local value = Domain.trueValue(def, item)
	local errorSize = math.abs(quote - value) / math.max(1, value)
	local correctAuth = (authenticity == "genuine" and item.genuine) or (authenticity == "replica" and not item.genuine)
	local honestUnknown = authenticity == "unknown"
	local accuracy = math.clamp(1 - errorSize, 0, 1)
	local good = errorSize <= 0.22 and correctAuth
	local reputation = if good then 3 elseif errorSize <= 0.4 and (correctAuth or honestUnknown) then 1 else -3
	if patience < 0.15 then reputation -= 1 end
	local fee = 20 + math.sqrt(def.value) * 1.3
	fee *= baseFee * (0.38 + accuracy * 0.62) * (if correctAuth then 1.15 elseif honestUnknown then 0.82 else 0.48)
	fee *= 0.7 + patience * 0.3
	return { value = value, error = errorSize, good = good, correctAuth = correctAuth, fee = Domain.money(fee), rep = reputation,
		mood = if good then "happy" elseif correctAuth or honestUnknown then "sigh" else "angry" }
end

function Domain.minimumOffer(def, item, patience)
	return Domain.money(Domain.trueValue(def, item) * (0.68 + Domain.hash(item.seed, 83) * 0.2 + (1 - patience) * 0.08))
end

function Domain.unlockedTitles(profile)
	local s = profile.stats
	return { trainee = true, eye = s.good >= 10, fake = s.fakes >= 5, diplomat = s.purchases >= 5,
		collector = s.rare >= 1, archivist = #profile.seen >= 25 }
end

return Domain

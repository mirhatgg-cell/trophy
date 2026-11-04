local Config = {}

Config.Name = "ПРОБА · Бюро оценки"
Config.Version = "0.1.0"
Config.StartingCash = 750
Config.InventoryLimit = 40
Config.PeerFee = 40
Config.AdminUserIds = {} -- Studio testers and the individual experience owner are also admins.
Config.SpecOrder = { "Everyday", "Jeweler", "Historian", "Archaeologist", "Technician" }
Config.Specs = {
	Everyday = { name = "Товаровед", subtitle = "Быт, инструменты, игрушки", color = { 126, 185, 154 } },
	Jeweler = { name = "Ювелир", subtitle = "Металлы, камни, украшения", color = { 217, 179, 100 } },
	Historian = { name = "Историк", subtitle = "Монеты, документы, наследие", color = { 180, 151, 197 } },
	Archaeologist = { name = "Археолог", subtitle = "Древности, керамика, окаменелости", color = { 201, 145, 107 } },
	Technician = { name = "Механик", subtitle = "Оптика, электроника, механизмы", color = { 119, 172, 200 } },
}
Config.ToolsOrder = { "loupe", "scale", "uv", "spectro", "diagnostic" }
Config.Tools = {
	loupe = { name = "Лупа", hint = "Клеймо, резьба и следы изготовления", price = { 0, 350, 950 }, seconds = 1.2 },
	scale = { name = "Точные весы", hint = "Масса и соответствие эталону", price = { 0, 450, 1200 }, seconds = 1.6 },
	uv = { name = "УФ-лампа", hint = "Клей, новая краска и реставрация", price = { 550, 900, 1600 }, seconds = 1.8 },
	spectro = { name = "Спектрометр", hint = "Состав металла, минерала или керамики", price = { 1600, 2200, 3400 }, seconds = 2.4 },
	diagnostic = { name = "Стенд диагностики", hint = "Оптика, механизм и заменённые детали", price = { 900, 1500, 2600 }, seconds = 2.0 },
}
Config.BaseLevels = {
	{ name = "Контейнер", subtitle = "Первая точка приёма", price = 0, rep = 0, capacity = 3, fee = 1.00 },
	{ name = "Мастерская", subtitle = "Кирпичное бюро и лаборатория", price = 2400, rep = 12, capacity = 4, fee = 1.18 },
	{ name = "Дом экспертизы", subtitle = "Два этажа, галерея и архив", price = 10000, rep = 35, capacity = 5, fee = 1.40 },
}
Config.Titles = {
	{ id = "trainee", name = "СТАЖЁР", style = "paper", requirement = "Доступен сразу" },
	{ id = "eye", name = "ОСТРЫЙ ГЛАЗ", style = "mint", requirement = "10 точных заключений" },
	{ id = "fake", name = "ГРОЗА ПОДДЕЛОК", style = "copper", requirement = "5 распознанных подделок" },
	{ id = "diplomat", name = "ДИПЛОМАТ", style = "blue", requirement = "5 успешных выкупов" },
	{ id = "collector", name = "ХРАНИТЕЛЬ РЕДКОСТЕЙ", style = "gold", requirement = "Купить предмет ценой от 3000" },
	{ id = "archivist", name = "АРХИВАРИУС", style = "violet", requirement = "Оценить 25 разных предметов" },
}
return Config

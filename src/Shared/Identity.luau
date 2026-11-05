local Decor=require(if script then script.Parent.Decor else "./Decor")
local Identity={Nametags={
	{id="tag_plain",name="Чистый ник",style="plain",price=0,color={220,232,250},description="Спокойный ник без окружающего эффекта."},
	{id="tag_volt",name="Voltweave",style="volt",price=1200,color={90,204,255},description="Ветвящиеся разряды, светящиеся узлы и ионное свечение."},
	{id="tag_vesper",name="Vesper Veil",style="vesper",price=2400,color={190,108,255},description="Слои тёмного тумана и вращающийся сумеречный разлом."},
	{id="tag_boreal",name="Boreal Flow",style="boreal",price=4200,color={76,242,196},description="Переплетённые ленты северного сияния за буквами."},
	{id="tag_ember",name="Cinder Crown",style="ember",price=1900,color={255,159,81},description="Огненная корона, языки пламени и восходящие угли."},
	{id="tag_prism",name="Prism Break",style="prism",price=6000,color={248,132,225},description="Рефракционные грани, осколки и хроматический блик."},
	{id="tag_astrolabe",name="Star Atlas",style="astrolabe",price=5200,color={145,182,255},description="Две орбиты, кометы и соединённые узлы звёздной карты."},
	{id="tag_maple",name="Maple Current",style="maple",price=1600,color={255,189,101},description="Резные листья с прожилками в тёплом воздушном потоке."},
	{id="tag_tide",name="Liquid Glass",style="tide",price=1800,color={101,230,248},description="Прозрачные волны, бегущие каустики и капли стекла."},
},ById={}}
for _,d in ipairs(Identity.Nametags)do Identity.ById[d.id]=d end
Identity.BackgroundStyles={card_paper="neutral",card_velvet="velvet",card_starmap="starmap",card_boreal="boreal",card_eclipse="eclipse",card_horizon="horizon",card_tidal="tidal",card_geode="geode",card_forge="forge"}
Identity.FrameStyles={frame_plain="plain",frame_brass="brass",frame_mechanical="circuit",frame_astral="comet",frame_facet="facet",frame_wings="wings",frame_rift="rift"}
Identity.LegacyTags={eye="tag_volt",fake="tag_vesper",diplomat="tag_tide",collector="tag_prism",archivist="tag_astrolabe"}
function Identity.Load(profile,raw)
	profile.ownedNametags={tag_plain=true}
	if type(raw.ownedNametags)=="table"then for id,owned in pairs(raw.ownedNametags)do if owned==true and Identity.ById[id]then profile.ownedNametags[id]=true end end end
	if raw.nametag==nil and raw.ownedNametags==nil then
		local legacy=Identity.LegacyTags[profile.title]
		if legacy then profile.ownedNametags[legacy]=true;profile.nametag=legacy;return end
	end
	profile.nametag=if Identity.ById[raw.nametag]and profile.ownedNametags[raw.nametag]then raw.nametag else"tag_plain"
end
function Identity.Selection(profile)
	local equipped=profile.equippedDecor or{}
	return{title=profile.title or"trainee",nametag=profile.nametag or"tag_plain",card=equipped.card or"card_paper",frame=equipped.frame or"frame_plain"}
end
function Identity.GrantAll(profile)
	profile.ownedNametags=profile.ownedNametags or{tag_plain=true}
	for _,d in ipairs(Identity.Nametags)do profile.ownedNametags[d.id]=true end
	for _,d in ipairs(Decor.List)do if d.category=="frame"or d.category=="card"then profile.ownedDecor[d.id]=true end end
end
return Identity

local Rep=game:GetService("ReplicatedStorage")
local Catalog=require(Rep.Shared.Identity)
local Decor=require(Rep.Shared.Decor)
local Config=require(Rep.Shared.Config)
local FX=require(script.Parent.IdentityFX)
local UI={}
function UI.Build(parent,profile,player,w,state,api)
	local button,text,panel,C=api.button,api.text,api.panel,api.colors
	state.tab=state.tab or"title";state.sub=state.sub or"card"
	state.title=state.title or profile.title;state.tag=state.tag or profile.nametag or"tag_plain"
	state.card=state.card or profile.equippedDecor.card or"card_paper";state.frame=state.frame or profile.equippedDecor.frame or"frame_plain"
	for i,d in ipairs({{"title","Титулы"},{"tag","Nametag"},{"card","Фон / рамка"}})do
		button(parent,d[2],(i-1)*(w+6)/3,0,(w-12)/3,31,function()state.tab=d[1];api.render(true)end,if state.tab==d[1]then"primary"else nil)
	end
	local selected={title=profile.title,nametag=profile.nametag or"tag_plain",card=profile.equippedDecor.card or"card_paper",frame=profile.equippedDecor.frame or"frame_plain"}
	if state.tab=="title"then selected.title=state.title elseif state.tab=="tag"then selected.nametag=state.tag else selected[state.sub]=state[state.sub]end
	selected.name=player.DisplayName;selected.userId=player.UserId;selected.width=math.min(w,360);selected.height=112
	local preview=FX.Card(parent,selected);preview.Position=UDim2.fromOffset((w-selected.width)/2,42)
	local choices,key,owned,equipped,action,description
	local y=164
	if state.tab=="title"then
		choices=Config.Titles;key="title";owned=profile.unlocked;equipped=profile.title;action="Title"
		description="Только подпись под ником. Nametag и фон остаются выбранными отдельно."
	elseif state.tab=="tag"then
		choices=Catalog.Nametags;key="tag";owned=profile.ownedNametags or{tag_plain=true};equipped=profile.nametag or"tag_plain";action="BuyNametag"
		description="Эффект вокруг самого ника: виден в мире и в карточке игрока. Титул не меняется."
	else
		button(parent,"Фоны карточки",0,y,(w-8)/2,27,function()state.sub="card";api.render(true)end,if state.sub=="card"then"gold"else nil)
		button(parent,"Рамки портрета",(w+8)/2,y,(w-8)/2,27,function()state.sub="frame";api.render(true)end,if state.sub=="frame"then"gold"else nil);y+=35
		choices={};for _,d in ipairs(Decor.List)do if d.category==state.sub then table.insert(choices,d)end end
		key=state.sub;owned=profile.ownedDecor;equipped=profile.equippedDecor[key];action="BuyDecor"
		description="Фон оформляет карточку в TAB. Иллюстрированная рамка окружает портрет."
	end
	local current
	for _,d in ipairs(choices)do if d.id==state[key]then current=d;break end end
	current=current or choices[1];state[key]=current.id
	if state.tab=="tag"then
		local face=Catalog.Typeface(current.style,player.DisplayName)
		description="Шрифт: "..face.." · эффект букв и аура входят в nametag."
	end
	text(parent,description,11,C.muted,UDim2.fromOffset(0,y),UDim2.fromOffset(w,31));y+=36
	local available=owned[current.id]==true
	local cost=if current.premium then"Robux"else tostring(current.price or 0).." монет"
	local label=if equipped==current.id then"Выбрано"elseif available then"Надеть"elseif state.tab=="title"then current.requirement else"Купить / "..cost
	button(parent,label,0,y,w,33,function()
		if state.tab=="title"and not available then return end
		api.emit(action,{id=current.id})
	end,if equipped==current.id then"gold"else"primary");y+=43
	text(parent,current.name..(if current.description then" / "..current.description else""),11,C.paper,UDim2.fromOffset(0,y),UDim2.fromOffset(w,36));y+=42
	local columns=if w>530 then 3 else 2;local cw=(w-(columns-1)*7)/columns
	for i,d in ipairs(choices)do
		local card=button(parent,"",((i-1)%columns)*(cw+7),y+math.floor((i-1)/columns)*95,cw,88,function()state[key]=d.id;api.render(true)end,if state[key]==d.id then"gold"else nil)
		card.ClipsDescendants=true
		if state.tab=="tag"then FX.Nametag(card,d.id,player.DisplayName,cw,44)
		elseif state.tab=="title"then local sample=FX.Title(card,d.id,cw,true);sample.Position=UDim2.fromOffset(0,12)
		elseif state.sub=="card"then FX.Background(card,d.id,cw,48)
		else FX.Frame(card,d.id,cw/2,27,15,cw,52)end
		local c=if d.color then Color3.fromRGB(unpack(d.color))else C.mint
		text(card,d.name,11,c,UDim2.fromOffset(10,49),UDim2.fromOffset(cw-20,19),Enum.Font.GothamBold)
		local status=if equipped==d.id then"НАДЕТО"elseif owned[d.id]then"ПОЛУЧЕНО"elseif state.tab=="title"then d.requirement else if d.premium then"ПРЕМИУМ"else tostring(d.price).." монет"
		text(card,status,9,C.muted,UDim2.fromOffset(10,69),UDim2.fromOffset(cw-20,16))
	end
end
return UI

local Players=game:GetService("Players")
local MarketplaceService=game:GetService("MarketplaceService")
local Config=require(game.ReplicatedStorage.Shared.Config)
local Decor=require(game.ReplicatedStorage.Shared.Decor)
local Domain=require(game.ReplicatedStorage.Shared.Domain)
local Commerce={}
local profiles,sessions,notify,changed
function Commerce.Init(profileService,activeSessions,message,onChanged)
	profiles=profileService;sessions=activeSessions;notify=message;changed=onChanged
	MarketplaceService.ProcessReceipt=function(receipt)
		local player=Players:GetPlayerByUserId(receipt.PlayerId)
		local p=player and profiles.loaded[player]
		local session=player and profiles.sessions[player]
		if not p or not session or session.mode~="cloud"then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local def
		for id,product in pairs(Config.DecorProducts)do if product>0 and product==receipt.ProductId then def=Decor.ById[id];break end end
		if not def then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local key=tostring(receipt.PurchaseId)
		if not p.receipts[key]then
			if p.ownedDecor[def.id]then p.cash=Domain.money(p.cash+(def.value or 0))end
			p.ownedDecor[def.id]=true;p.equippedDecor[def.category]=def.id;p.receipts[key]=true
		end
		if not profiles.Save(player,false)then return Enum.ProductPurchaseDecision.NotProcessedYet end
		changed(player);notify(player,"Премиум-декор получен: "..def.name,"good")
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end
function Commerce.Prompt(player,def)
	local id=Config.DecorProducts[def.id]or 0
	if id<=0 then notify(player,"Этот премиум-предмет пока доступен для примерки в Studio: настоящий Product ID ещё не подключён.");return end
	if profiles.sessions[player].mode~="cloud"then notify(player,"Покупка доступна только при работающем облачном сохранении.");return end
	if profiles.loaded[player].ownedDecor[def.id]then changed(player);return end
	MarketplaceService:PromptProductPurchase(player,id)
end
return Commerce

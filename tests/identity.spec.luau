local Identity=require("../src/Shared/Identity")
local Decor=require("../src/Shared/Decor")
local n=0
local function check(v,why)n+=1;assert(v,why)end
local ids,styles={},{}
check(#Identity.Nametags==9,"The nickname department needs nine complete authored choices")
for _,d in ipairs(Identity.Nametags)do check(not ids[d.id]and not styles[d.style]and d.price>=0 and #d.description>10,"Every nametag must have its own design, identity and server price");ids[d.id]=true;styles[d.style]=true end
for id in pairs(Identity.BackgroundStyles)do check(Decor.ById[id]and Decor.ById[id].category=="card","Every background design must be purchasable and persistable")end
for id in pairs(Identity.FrameStyles)do check(Decor.ById[id]and Decor.ById[id].category=="frame","Every portrait frame must have a valid catalog definition")end
local legacy={title="collector",ownedDecor={},equippedDecor={card="card_velvet",frame="frame_brass"}}
Identity.Load(legacy,{})
check(legacy.nametag=="tag_prism"and legacy.ownedNametags.tag_prism,"Existing equipped title effects migrate without repurchasing")
check(legacy.equippedDecor.card=="card_velvet"and legacy.equippedDecor.frame=="frame_brass","Migration must preserve independent older card and frame purchases")
Identity.Load(legacy,{nametag="invented",ownedNametags={invented=true,tag_ember=true}})
check(legacy.nametag=="tag_plain"and not legacy.ownedNametags.invented and legacy.ownedNametags.tag_ember,"Unknown styles cannot enter a persistent owned catalog")
local before=Identity.Selection(legacy);Identity.GrantAll(legacy);local after=Identity.Selection(legacy)
check(before.title==after.title and before.nametag==after.nametag and before.card==after.card and before.frame==after.frame,"Admin unlocking must not silently equip or mix the three layers")
print("PASS independent identity layers:",n,"assertions")

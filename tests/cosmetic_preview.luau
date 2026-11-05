-- External replay recording: actual production constructors and animation steps.
dimensions.w=1020;dimensions.h=482
local FX=env.require(clientScripts.IdentityFX)
local identity=env.require(shared.Identity)
local screen=node("ScreenGui","MotionReview",localPlayer.PlayerGui)
local cards={
	{"tag_plain","trainee","card_paper","frame_plain"},
	{"tag_volt","eye","card_horizon","frame_mechanical"},
	{"tag_vesper","fake","card_eclipse","frame_rift"},
	{"tag_boreal","diplomat","card_boreal","frame_astral"},
	{"tag_ember","collector","card_forge","frame_wings"},
	{"tag_prism","collector","card_geode","frame_facet"},
	{"tag_astrolabe","archivist","card_starmap","frame_astral"},
	{"tag_maple","trainee","card_velvet","frame_brass"},
	{"tag_tide","diplomat","card_tidal","frame_facet"},
}
for i,entry in ipairs(cards)do
	local d=identity.ById[entry[1]]
	local x,y=12+(i-1)%3*336,14+math.floor((i-1)/3)*156
	local card=FX.Card(screen,{width=324,height=106,userId=0,name="red_blink",nametag=d.id,title=entry[2],card=entry[3],frame=entry[4]})
	card.Position=D.fromOffset(x,y)
	local label=node("TextLabel","Caption",screen)
	label.Text=d.name.." / "..identity.Typeface(d.style,"red_blink");label.Font=enum.Font.GothamMedium;label.TextSize=12
	label.BackgroundTransparency=1;label.TextColor3=Color.fromRGB(179,195,219);label.Position=D.fromOffset(x,y+111);label.Size=D.fromOffset(324,22)
end
for i=0,47 do
	clock=i/12
	services.RunService.RenderStepped:Fire(1/12)
	capture("motion_"..i,true)
end

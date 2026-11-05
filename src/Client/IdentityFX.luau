-- Self-contained vector artwork: no uploaded textures or borrowed Discord assets.
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local Rep=game:GetService("ReplicatedStorage")
local Identity=require(Rep.Shared.Identity)
local Decor=require(Rep.Shared.Decor)
local Config=require(Rep.Shared.Config)
local FX={}
local actors,portraits={},{ }
local WHITE=Color3.fromRGB(240,247,255)
local function new(class,props,parent)local o=Instance.new(class);for k,v in pairs(props)do o[k]=v end;o.Parent=parent;return o end
local function round(o,r)new("UICorner",{CornerRadius=UDim.new(0,r)},o)end
local function color(rgb)return Color3.fromRGB(unpack(rgb))end
local function rect(parent,w,h,c,alpha)
	return new("Frame",{BackgroundColor3=c,BackgroundTransparency=alpha or 0,BorderSizePixel=0,AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(w,h)},parent)
end
local function at(o,x,y)o.Position=UDim2.fromOffset(x,y);return o end
local function canvas(parent,name,w,h,clip)
	return new("Frame",{Name=name,BackgroundTransparency=1,Size=UDim2.fromOffset(w,h),ClipsDescendants=clip==true},parent)
end
local function gradient(o,a,b,rotation,soft)
	if o:IsA("Frame")then o.BackgroundColor3=WHITE elseif o:IsA("TextLabel")then o.TextColor3=WHITE elseif o:IsA("UIStroke")then o.Color=WHITE end
	local props={Color=ColorSequence.new(a,b),Rotation=rotation or 0}
	if soft then props.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.25,.35),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(.75,.35),NumberSequenceKeypoint.new(1,1)})end
	return new("UIGradient",props,o)
end
local function label(parent,value,size,c,w,h)
	return new("TextLabel",{Name="Label",BackgroundTransparency=1,Text=value,TextColor3=c,TextSize=size,Font=Enum.Font.GothamBold,
		TextStrokeColor3=Color3.fromRGB(5,8,18),TextStrokeTransparency=.55,TextTruncate=Enum.TextTruncate.AtEnd,
		TextXAlignment=Enum.TextXAlignment.Left,Size=UDim2.fromOffset(w,h)},parent)
end
local function segment(o,x1,y1,x2,y2,thickness)
	local dx,dy=x2-x1,y2-y1;o.Position=UDim2.fromOffset((x1+x2)/2,(y1+y2)/2)
	o.Size=UDim2.fromOffset(math.max(.1,math.sqrt(dx*dx+dy*dy)),thickness or 1);o.Rotation=math.deg(math.atan2(dy,dx))
end
local function glow(parent,w,h,c)
	local root=canvas(parent,"SoftLight",w,h)
	for i=1,3 do local p=at(rect(root,w*(1+(i-1)*.10),h*(1+(i-1)*.15),c,.72+i*.045),w/2,h/2);round(p,100);gradient(p,c,c,if i%2==0 then 90 else 0,true)end
	return root
end
local function star(parent,size,c)
	local p=rect(parent,size*.35,size,c);p.Rotation=45
	local cross=at(rect(p,size,size*.35,c),size*.175,size*.5)
	return p
end
local function lineSet(parent,n,c,alpha)
	local set={};for i=1,n do set[i]=rect(parent,1,1,c,alpha or 0)end;return set
end
local function polygon(parent,points,c,alpha)
	local low,high=math.huge,-math.huge
	for _,p in ipairs(points)do low=math.min(low,p[2]);high=math.max(high,p[2])end
	for y=low,high,1 do
		local intersections={};local scan=y+.5
		for i,a in ipairs(points)do local b=points[i%#points+1]
			if(a[2]<=scan and b[2]>scan)or(b[2]<=scan and a[2]>scan)then table.insert(intersections,a[1]+(scan-a[2])*(b[1]-a[1])/(b[2]-a[2]))end
		end
		table.sort(intersections)
		for i=1,#intersections-1,2 do local a,b=intersections[i],intersections[i+1];at(rect(parent,math.max(.1,b-a),1.2,c,alpha or 0),(a+b)*.5,y+.5)end
	end
end
local function animate(root,step)table.insert(actors,{root=root,step=step})end
local function wave(parent,w,h,a,b,count)
	local nodes=lineSet(parent,count or 22,a,.28)
	for i,p in ipairs(nodes)do p.BackgroundColor3=a:Lerp(b,i/#nodes)end
	return function(t,phase,amplitude,baseline)
		for i,p in ipairs(nodes)do
			local u=(i-1)/#nodes;local v=i/#nodes
			segment(p,u*w,baseline+math.sin(u*math.pi*2+t+phase)*amplitude,v*w,baseline+math.sin(v*math.pi*2+t+phase)*amplitude,1.5)
		end
	end
end

function FX.Nametag(parent,id,name,w,h)
	h=h or 48;local d=Identity.ById[id]or Identity.ById.tag_plain;local c=color(d.color)
	local root=canvas(parent,"NicknameEffect",w,h);root:SetAttribute("NametagId",d.id)
	local art=canvas(root,"NametagArtwork",w,h)
	local update=function()end
	if d.style=="volt"then
		local halo=glow(art,w*.92,h*.7,c);halo.Position=UDim2.fromOffset(w*.04,h*.12)
		local bolts=lineSet(art,32,c,.08);local branches=lineSet(art,8,WHITE,.15)
		update=function(t)
			for j,p in ipairs(bolts)do
				local row=math.floor((j-1)/16);local i=(j-1)%16
				local function point(k)local x=w*(.03+k/16*.94);return x,h*(if row==0 then .19 else .79)+math.sin(k*7.3+math.floor(t*5)*1.7)*5 end
				local x,y=point(i);local xx,yy=point(i+1);segment(p,x,y,xx,yy,if j%3==0 then 2 else 1)
			end
			for j,p in ipairs(branches)do local x=(j%2==0 and .92 or .08)*w;local y=h*.5+(j-4)*2;segment(p,x,y,x+(j%2==0 and-1 or 1)*(8+j),y+math.sin(t*4+j)*12,1)end
		end
	elseif d.style=="vesper"then
		local clouds={}
		for i=1,7 do local cloud=glow(art,w*.45,h*.65,if i%2==0 then c else Color3.fromRGB(53,28,106));clouds[i]=cloud end
		local dark=at(rect(art,w*.64,h*.65,Color3.fromRGB(6,7,18),.24),w*.5,h*.47);round(dark,70)
		local fragments=lineSet(art,12,c,.23)
		update=function(t)
			for i,p in ipairs(clouds)do local a=t*.28+i*.9;p.Position=UDim2.fromOffset(w*.5+math.cos(a)*w*.25-w*.225,h*.5+math.sin(a*1.3)*h*.19-h*.325);p.Rotation=math.sin(a)*22 end
			for i,p in ipairs(fragments)do local a=i*math.pi/6+t*.34;local x,y=w*.5+math.cos(a)*w*.42,h*.48+math.sin(a)*h*.34;segment(p,x,y,x+math.sin(a)*7,y+math.cos(a)*4,1.6)end
		end
	elseif d.style=="boreal"then
		local a=wave(art,w,h,c,Color3.fromRGB(163,114,255));local b=wave(art,w,h,Color3.fromRGB(111,181,255),c)
		local veil=glow(art,w,h*.85,c);veil.Position=UDim2.fromOffset(0,h*.06)
		update=function(t)a(t*.7,0,h*.22,h*.34);b(-t*.55,1.4,h*.17,h*.67);veil.Rotation=math.sin(t*.3)*5 end
	elseif d.style=="ember"then
		local base=glow(art,w,h*.72,Color3.fromRGB(255,88,53));base.Position=UDim2.fromOffset(0,h*.23)
		local tongues,cinders={},{}
		for i=1,13 do local p=rect(art,4,15,if i%2==0 then c else Color3.fromRGB(255,104,57),.2);p.Rotation=45;gradient(p,c,Color3.fromRGB(229,64,52),90,true);tongues[i]=p end
		for i=1,8 do cinders[i]=star(art,2,c)end
		update=function(t)
			for i,p in ipairs(tongues)do local x=w*(.07+i/15*.87);local rise=(math.sin(t*2.2+i)*.5+.5)*10;p.Position=UDim2.fromOffset(x,h*.65-rise);p.Size=UDim2.fromOffset(3+i%3,13+rise);p.Rotation=30+math.sin(t+i)*17 end
			for i,p in ipairs(cinders)do local age=(t*.24+i/8)%1;p.Position=UDim2.fromOffset((i*31)%w+math.sin(t+i)*8,h*(.9-age));p.BackgroundTransparency=age;p.Rotation=t*35+i*40 end
		end
	elseif d.style=="prism"then
		local shards={}
		for i=1,10 do local p=rect(art,9+i%3*3,15+i%4*3,Color3.fromHSV(i/12,.58,1),.25);p.Rotation=45;gradient(p,WHITE,p.BackgroundColor3,45);shards[i]=p end
		local flash=rect(art,3,h*.95,WHITE,.65);flash.Rotation=25
		update=function(t)
			for i,p in ipairs(shards)do local a=i*math.pi/5+t*.12;p.Position=UDim2.fromOffset(w*.5+math.cos(a)*w*.40,h*.49+math.sin(a)*h*.30);p.Rotation=45+math.sin(t*.7+i)*13 end
			flash.Position=UDim2.fromOffset((t*.18%1)*w,h*.5);flash.BackgroundTransparency=.75+math.sin(t)^2*.15
		end
	elseif d.style=="astrolabe"then
		local rings=lineSet(art,40,c,.22);local stars={}
		for i=1,4 do stars[i]=star(art,5,if i%2==0 then WHITE else Color3.fromRGB(255,216,131))end
		update=function(t)
			for j,p in ipairs(rings)do local ring=math.floor((j-1)/20);local a=((j-1)%20)/20*math.pi*2+t*(if ring==0 then .3 else-.24);local b=a+math.pi/10
				local function point(v)return w*.5+math.cos(v)*w*.45,h*.5+math.sin(v)*h*(if ring==0 then .36 else .19)+math.cos(v)*h*(if ring==0 then .05 else-.2)end
				local x,y=point(a);local xx,yy=point(b);segment(p,x,y,xx,yy,1)
			end
			for i,p in ipairs(stars)do local a=t*.55+i*math.pi/2;p.Position=UDim2.fromOffset(w*.5+math.cos(a)*w*.44,h*.5+math.sin(a)*h*.34);p.Rotation=t*20 end
		end
	elseif d.style=="maple"then
		local leaves={};local breeze=wave(art,w,h,Color3.fromRGB(255,199,102),Color3.fromRGB(203,99,56),16)
		for i=1,8 do
			local leaf=rect(art,7,11,if i%2==0 then c else Color3.fromRGB(222,113,58),.05);leaf.Rotation=45
			local lobe=at(rect(leaf,10,5,leaf.BackgroundColor3),3.5,5.5);lobe.Rotation=-15
			at(rect(leaf,1,10,Color3.fromRGB(132,76,40),.2),3.5,6);leaves[i]=leaf
		end
		update=function(t)
			breeze(t*.6,0,4,h*.72)
			for i,p in ipairs(leaves)do local phase=(t*.045+i/8)%1;p.Position=UDim2.fromOffset(phase*(w+24)-12,h*(.12+(i%3)*.3)+math.sin(t+i)*6);p.Rotation=t*17+i*63 end
		end
	elseif d.style=="tide"then
		local a=wave(art,w,h,c,WHITE);local b=wave(art,w,h,Color3.fromRGB(72,133,239),c)
		local drops={};for i=1,7 do local p=rect(art,4,7,c,.3);round(p,5);drops[i]=p end
		update=function(t)
			a(t,0,4,h*.73);b(t*.8,2,6,h*.82)
			for i,p in ipairs(drops)do local phase=(t*.16+i/7)%1;p.Position=UDim2.fromOffset((i*37)%w,h*(.86-phase*.68));p.BackgroundTransparency=.3+phase*.65;p.Rotation=math.sin(t+i)*15 end
		end
	end
	-- A dark lift and luminous type remain readable above every effect.
	if d.style~="plain"then
		local shadow=label(root,name,16,Color3.fromRGB(5,9,22),w-12,28);shadow.Position=UDim2.fromOffset(7,h*.5-11);shadow.TextStrokeTransparency=.2
	end
	local nameLabel=label(root,name,16,WHITE,w-12,28);nameLabel.Name="Nickname";nameLabel.Position=UDim2.fromOffset(6,h*.5-14)
	local sheen=gradient(nameLabel,if d.style=="plain"then WHITE else c,WHITE,0)
	animate(root,function(t)update(t);sheen.Offset=Vector2.new(math.sin(t*.8)*.55,0)end)
	return root
end

function FX.Title(parent,id,w,centered)
	local d=Config.Titles[1];for _,v in ipairs(Config.Titles)do if v.id==id then d=v;break end end
	local palette={trainee={169,184,207},eye={90,239,204},fake={255,118,148},diplomat={107,192,255},collector={255,212,112},archivist={187,155,255}}
	local c=color(palette[d.id]or palette.trainee);local root=canvas(parent,"TitleEffect",w,26);root:SetAttribute("TitleId",d.id)
	local title=label(root,d.name,10,c,w-12,22);title.Name="TitleLabel";title.Position=UDim2.fromOffset(6,0)
	if centered then title.TextXAlignment=Enum.TextXAlignment.Center end
	if d.id=="trainee"then return root end
	local sheen=gradient(title,c,WHITE,0);local ornaments=lineSet(root,if d.id=="collector"then 12 else 6,c,.2)
	animate(root,function(t)
		sheen.Offset=Vector2.new(math.sin(t)*.65,0)
		for i,p in ipairs(ornaments)do
			if d.id=="eye"then local x=(t*.25+i/6)%1*w;segment(p,x,22,x+7,22,1)
			elseif d.id=="fake"then local x=(i*w/7+math.floor(t*4)*9)%w;segment(p,x,22,x+9,19,1)
			elseif d.id=="collector"then local side=if i<=6 then-1 else 1;local j=(i-1)%6;local x=w*.5+side*(w*.42-j*2);segment(p,x,4+j*3,x+side*6,1+j*3,1.2);p.BackgroundTransparency=.2+math.sin(t+j)^2*.35
			elseif d.id=="diplomat"then local x=i*w/7;segment(p,x,21+math.sin(t*2+i)*2,x+8,21+math.sin(t*2+i+.5)*2,1)
			else local x=i*w/7;segment(p,x,22,x+5,19+math.sin(t*2+i)*2,1);p.BackgroundTransparency=.2+math.sin(t+i)^2*.5 end
		end
	end)
	return root
end

function FX.Background(parent,id,w,h)
	local d=Decor.ById[id]or Decor.ById.card_paper;local style=Identity.BackgroundStyles[d.id]or"neutral";local c=color(d.color)
	local root=canvas(parent,"CardArtwork",w,h,true)
	local base=at(rect(root,w,h,c),w/2,h/2);gradient(base,c:Lerp(Color3.fromRGB(8,13,26),.6),c,12)
	local update=function()end
	if style=="boreal"or style=="tidal"then
		local a=wave(root,w,h,if style=="boreal"then Color3.fromRGB(94,227,183)else Color3.fromRGB(99,198,235),Color3.fromRGB(129,121,226))
		local b=wave(root,w,h,Color3.fromRGB(82,154,206),Color3.fromRGB(182,136,223))
		local wash=glow(root,w*.8,h*.9,c:Lerp(WHITE,.25));wash.Position=UDim2.fromOffset(w*.24,0)
		update=function(t)a(t*.35,0,h*.23,h*.4);b(-t*.3,2,h*.2,h*.66)end
	elseif style=="eclipse"then
		local corona=glow(root,h*1.3,h*1.3,Color3.fromRGB(165,106,236));corona.Position=UDim2.fromOffset(w-h*1.15,-h*.15)
		local disk=at(rect(root,h*.7,h*.7,Color3.fromRGB(9,9,26)),w-h*.5,h*.5);round(disk,100)
		local arcs=lineSet(root,20,Color3.fromRGB(191,151,255),.3)
		update=function(t)for i,p in ipairs(arcs)do local a=i*math.pi/10+t*.12;local b=a+.12;segment(p,w-h*.5+math.cos(a)*h*.43,h*.5+math.sin(a)*h*.43,w-h*.5+math.cos(b)*h*.43,h*.5+math.sin(b)*h*.43,1.6)end end
	elseif style=="starmap"then
		local cloud=glow(root,w*.65,h,Color3.fromRGB(115,126,217));cloud.Position=UDim2.fromOffset(w*.4,0)
		local nodes,links={},lineSet(root,8,Color3.fromRGB(155,181,242),.65)
		for i=1,18 do nodes[i]=star(root,if i%4==0 then 4 else 2,WHITE)end
		update=function(t)
			for i,p in ipairs(nodes)do p.Position=UDim2.fromOffset((i*47)%w,9+(i*29)%(h-18));p.BackgroundTransparency=.1+math.sin(t*.7+i)^2*.6 end
			for i,p in ipairs(links)do local a,b=nodes[i*2-1].Position,nodes[i*2].Position;segment(p,a.X.Offset,a.Y.Offset,b.X.Offset,b.Y.Offset,1)end
		end
	elseif style=="geode"then
		local points={{0,0},{.32,0},{.18,.6},{.53,.23},{.70,0},{1,0},{.88,.6},{1,1},{.5,1},{0,1}}
		local triangles={{1,2,3},{2,4,3},{2,5,4},{5,6,4},{4,6,7},{6,8,7},{7,8,9},{4,7,9},{3,4,9},{3,9,10},{1,3,10}}
		for i,ids in ipairs(triangles)do local triangle={};for _,j in ipairs(ids)do table.insert(triangle,{points[j][1]*w,points[j][2]*h})end;polygon(root,triangle,c:Lerp(WHITE,.015+(i%4)*.055))end
		local seams=lineSet(root,7,Color3.fromRGB(196,165,240),.65)
		for i,edge in ipairs({{1,3},{2,3},{3,4},{4,7},{7,9},{3,9},{4,5}})do local a,b=points[edge[1]],points[edge[2]];segment(seams[i],a[1]*w,a[2]*h,b[1]*w,b[2]*h,1)end
		update=function(t)for i,p in ipairs(seams)do p.BackgroundTransparency=.6+math.sin(t*.4+i)^2*.25 end end
	elseif style=="horizon"then
		local sun=at(rect(root,29,29,Color3.fromRGB(241,185,108),.08),w*.8,h*.27);round(sun,20)
		polygon(root,{{0,h},{w*.2,h*.28},{w*.43,h*.8},{w*.65,h*.18},{w*.85,h*.72},{w,h*.4},{w,h}},Color3.fromRGB(65,99,140))
		polygon(root,{{0,h},{w*.14,h*.57},{w*.35,h*.9},{w*.57,h*.46},{w*.83,h*.93},{w,h*.64},{w,h}},Color3.fromRGB(40,71,108))
		polygon(root,{{0,h},{w*.22,h*.83},{w*.4,h},{w*.7,h*.77},{w,h*.92},{w,h}},Color3.fromRGB(25,46,77))
		local horizon=at(rect(root,w,1,Color3.fromRGB(236,175,115),.45),w/2,h*.77)
		update=function(t)horizon.BackgroundTransparency=.45+math.sin(t*.3)^2*.2 end
	elseif style=="forge"then
		for i=1,20 do local p=at(rect(root,1,h*2,Color3.fromRGB(197,132,91),.82),i*w/18,h/2);p.Rotation=35 end
		local sweep=at(rect(root,3,h*1.4,Color3.fromRGB(236,163,102),.55),w*.8,h*.5);sweep.Rotation=25
		update=function(t)sweep.Position=UDim2.fromOffset((t*.07%1)*w,h*.5)end
	elseif style=="velvet"then
		local bands={};for i=1,10 do local p=at(rect(root,w*.8,h*.8,Color3.fromRGB(135,92,130),.9),w*.8,h*.5);round(p,100);new("UIStroke",{Color=Color3.fromRGB(184,130,172),Transparency=.8,Thickness=1},p);p.Rotation=i*13;bands[i]=p end
		update=function(t)for i,p in ipairs(bands)do p.Rotation=i*13+math.sin(t*.2)*6 end end
	else
		for i=1,8 do at(rect(root,w,1,Color3.fromRGB(130,156,190),.92),w/2,i*h/9)end
	end
	animate(root,update);return root
end

function FX.Frame(parent,id,cx,cy,radius,w,h)
	local d=Decor.ById[id]or Decor.ById.frame_plain;local c=color(d.color);local style=Identity.FrameStyles[d.id]or"plain"
	local root=canvas(parent,"AvatarFrameArtwork",w,h)
	local halo=at(rect(root,radius*2+4,radius*2+4,c,.85),cx,cy);round(halo,100)
	new("UIStroke",{Color=c,Thickness=if style=="plain"then 1 else 1.7,Transparency=.18},halo)
	if style=="plain"then return root end
	local nodes=lineSet(root,if style=="wings"then 16 else 14,c,.1)
	local trim=new("UIStroke",{Color=c,Thickness=1.3,Transparency=.12},parent);local sheen=gradient(trim,c,WHITE,0)
	animate(root,function(t)
		sheen.Rotation=t*24
		for i,p in ipairs(nodes)do
			if style=="wings"then
				local side=if i<=8 then-1 else 1;local j=(i-1)%8;local a=(j/8*.9+.15)+math.sin(t*.7)*.06
				local x,y=cx+side*(radius+4+j*.8),cy-14+j*4;segment(p,x,y,x+side*(9+math.sin(a)*6),y-7-j*.3,2)
			elseif style=="facet"then
				local a=i*math.pi/7;p.Position=UDim2.fromOffset(cx+math.cos(a)*(radius+5),cy+math.sin(a)*(radius+5));p.Size=UDim2.fromOffset(5,10+i%2*3);p.Rotation=math.deg(a)+45;p.BackgroundTransparency=.14+math.sin(t+i)^2*.35
			else
				local a=i*math.pi/7+(if style=="brass"then 0 elseif style=="circuit"then t*.1 else t*.35)
				local b=a+(if style=="rift"then .2 else .32);local r=radius+(if style=="comet"then 7 else 4)
				segment(p,cx+math.cos(a)*r,cy+math.sin(a)*r,cx+math.cos(b)*r,cy+math.sin(b)*r,if style=="circuit"then 2 else 1.4)
				p.BackgroundTransparency=if style=="comet"then .2+(i/14)*.6 else .12+math.sin(t*.7+i)^2*.28
			end
		end
	end)
	return root
end

local function portrait(parent,userId,name,size)
	local circle=rect(parent,size,size,Color3.fromRGB(38,50,73));circle.AnchorPoint=Vector2.new();round(circle,size/2)
	local first=name:sub(1,(utf8.offset(name,2)or(#name+1))-1)
	local initials=label(circle,first:upper(),20,WHITE,size,size);initials.TextXAlignment=Enum.TextXAlignment.Center
	local image=new("ImageLabel",{Name="AvatarPortrait",BackgroundTransparency=1,ImageTransparency=1,Size=UDim2.fromScale(1,1),ScaleType=Enum.ScaleType.Crop},circle);round(image,size/2)
	local function apply(url)if image.Parent and type(url)=="string"and url~=""then image.Image=url;image.ImageTransparency=0 end end
	if portraits[userId]then apply(portraits[userId])elseif userId and userId>0 then
		task.spawn(function()
			local ok,url=pcall(function()return Players:GetUserThumbnailAsync(userId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)end)
			if ok then portraits[userId]=url;apply(url)end
		end)
	end
	return circle
end
function FX.Card(parent,options)
	local w,h=options.width or 270,options.height or 88
	local root=new("CanvasGroup",{Name="PlayerIdentityCard",BackgroundTransparency=1,Size=UDim2.fromOffset(w,h),ClipsDescendants=true},parent);round(root,12)
	FX.Background(root,options.card or"card_paper",w,h)
	local size=math.min(54,h-24);local cx,cy=18+size/2,h/2
	local avatar=portrait(root,options.userId,options.name or"Player",size);avatar.Position=UDim2.fromOffset(18,(h-size)/2)
	FX.Frame(root,options.frame or"frame_plain",cx,cy,size/2,w,h)
	local x=18+size+14;local width=w-x-12
	local tagWidth=math.min(width,math.max(96,(utf8.len(options.name or"Player")or 12)*10+26))
	local tag=FX.Nametag(root,options.nametag or"tag_plain",options.name or"Player",tagWidth,46);tag.Position=UDim2.fromOffset(x,math.max(1,h*.5-32))
	local title=FX.Title(root,options.title or"trainee",width);title.Position=UDim2.fromOffset(x,h*.5+12)
	return root
end
function FX.World(parent,options)
	local root=canvas(parent,"WorldIdentity",230,80)
	local width=math.min(224,math.max(96,(utf8.len(options.name)or 12)*10+26))
	local tag=FX.Nametag(root,options.nametag or"tag_plain",options.name,width,50);tag.Position=UDim2.fromOffset((230-width)/2,0);tag.Nickname.TextXAlignment=Enum.TextXAlignment.Center
	local title=FX.Title(root,options.title or"trainee",218,true);title.Position=UDim2.fromOffset(6,52)
	return root
end
local function isVisible(root)
	local p=root
	while p do
		if p:IsA("GuiObject")and not p.Visible then return false end
		if p:IsA("LayerCollector")and not p.Enabled then return false end
		if p:IsA("ScrollingFrame")then
			local a,b=root.AbsolutePosition,root.AbsoluteSize;local c,d=p.AbsolutePosition,p.AbsoluteSize
			if a.Y+b.Y<c.Y or a.Y>c.Y+d.Y or a.X+b.X<c.X or a.X>c.X+d.X then return false end
		end
		if p:IsA("BillboardGui")then
			local part=p.Adornee or p.Parent;local camera=workspace.CurrentCamera
			if camera and part and part:IsA("BasePart")and(part.Position-camera.CFrame.Position).Magnitude>65 then return false end
		end
		p=p.Parent
	end
	return true
end
local elapsed=0
RunService.RenderStepped:Connect(function(dt)
	elapsed+=dt;if elapsed<1/30 then return end;elapsed=0
	local now=os.clock()
	for i=#actors,1,-1 do local a=actors[i];if not a.root.Parent then table.remove(actors,i)elseif isVisible(a.root)then a.step(now)end end
end)
return FX

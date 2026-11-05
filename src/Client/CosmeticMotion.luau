-- Continuous geometry animation. Paintings stay fixed; paths, flame tongues,
-- crystal faces, leaf silhouettes and droplets have independent lifecycles.
local Motion={}
local WHITE=Color3.fromRGB(242,249,255)
local function new(cls,props,parent)local n=Instance.new(cls);for k,v in pairs(props)do n[k]=v end;n.Parent=parent;return n end
local function frame(parent,name,color,alpha)
	return new("Frame",{Name=name,BorderSizePixel=0,BackgroundColor3=color,BackgroundTransparency=alpha or 0,
		AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(1,1)},parent)
end
local function round(p,r)new("UICorner",{CornerRadius=UDim.new(0,r)},p)end
local function line(p,x,y,xx,yy,width,alpha)
	local dx,dy=xx-x,yy-y
	p.Position=UDim2.fromOffset((x+xx)/2,(y+yy)/2);p.Size=UDim2.fromOffset(math.max(.05,math.sqrt(dx*dx+dy*dy)+.5),math.max(.05,width))
	p.Rotation=math.deg(math.atan2(dy,dx));p.BackgroundTransparency=math.clamp(alpha or 0,0,1)
end
local function dot(parent,name,size,color)
	local p=frame(parent,name,color);p.Size=UDim2.fromOffset(size,size);round(p,99);return p
end
local function ribbon(parent,name,count,a,b)
	local nodes={}
	for i=1,count do
		local shade=a:Lerp(b,i/count)
		local glow=frame(parent,name.."_Body",shade,.3);round(glow,99)
		new("UIGradient",{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.25,.5),NumberSequenceKeypoint.new(.5,0),NumberSequenceKeypoint.new(.75,.5),NumberSequenceKeypoint.new(1,1)})},glow)
		local core=frame(parent,name.."_Edge",shade:Lerp(WHITE,.28),.3);round(core,99)
		nodes[i]={glow,core}
	end
	return function(sample,alpha)
		for i,pair in ipairs(nodes)do
			local u,v=(i-1)/count,i/count
			local x,y,width=sample(u);local xx,yy,ww=sample(v)
			local thickness=math.max(.1,(width+ww)*.5)
			line(pair[1],x,y,xx,yy,thickness,(alpha or 0)+.12)
			line(pair[2],x,y,xx,yy,math.max(.35,thickness*.18),(alpha or 0)+.17)
		end
	end
end
local function polygon(parent,name,rows)
	local nodes={};for i=1,rows do nodes[i]=frame(parent,name,WHITE)end
	return function(points,color,alpha)
		local lo,hi=math.huge,-math.huge
		for _,p in ipairs(points)do lo=math.min(lo,p[2]);hi=math.max(hi,p[2])end
		local height=math.max(.05,(hi-lo)/rows)
		for i,p in ipairs(nodes)do
			local y=lo+(i-.5)*height;local crosses={}
			for j,a in ipairs(points)do local b=points[j%#points+1]
				if(a[2]<=y and b[2]>y)or(b[2]<=y and a[2]>y)then table.insert(crosses,a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2]))end
			end
			table.sort(crosses);p.Visible=#crosses>=2
			if #crosses>=2 then
				p.Position=UDim2.fromOffset((crosses[1]+crosses[#crosses])/2,y);p.Size=UDim2.fromOffset(math.max(.1,crosses[#crosses]-crosses[1]+.25),height+.25)
				p.BackgroundColor3=color;p.BackgroundTransparency=alpha or 0
			end
		end
	end
end
local function crystal(parent,name,size)
	local faces={};for i=1,4 do faces[i]=polygon(parent,name.."_Facet",8)end
	return function(x,y,angle,phase)
		local width=size*(.40+math.abs(math.cos(phase))*.60)
		local center=width*math.sin(phase)*.74
		local function p(xx,yy)return{x+xx*math.cos(angle)-yy*math.sin(angle),y+xx*math.sin(angle)+yy*math.cos(angle)}end
		local top,left,right,bottom,mid=p(0,-size*1.45),p(-width,0),p(width,0),p(0,size*1.45),p(center,size*.1)
		faces[1]({top,left,mid},Color3.fromRGB(118,200,244),.08)
		faces[2]({top,mid,right},Color3.fromRGB(233,208,255),.04)
		faces[3]({bottom,mid,left},Color3.fromRGB(161,111,212),.12)
		faces[4]({bottom,right,mid},WHITE,.08+math.sin(phase)^2*.25)
	end
end
local function bolt(parent,w,h,small)
	local nodes={}
	for i=1,(small and 16 or 26)do
		local a=frame(parent,"DischargeGlow",Color3.fromRGB(92,143,255));local b=frame(parent,"DischargeCore",WHITE)
		nodes[i]={a,b}
	end
	return function(t)
		local epoch=math.floor(t*7);local progress=(t*1.8)%1
		for i,pair in ipairs(nodes)do
			local n=#nodes;local u,v=(i-1)/n,i/n
			local function point(k)
				local x=w*(.05+k*.90)
				local y=h*(.45+math.sin(k*math.pi*2)*.32)+math.sin(k*39+epoch*17)*h*.10
				return x,y
			end
			local x,y=point(u);local xx,yy=point(v)
			local alpha=if u<progress*1.8 and progress<.75 then .12+progress*.7 else 1
			line(pair[1],x,y,xx,yy,3.8,alpha+.22);line(pair[2],x,y,xx,yy,.85,alpha)
		end
	end
end
local function fire(parent,w,h,count,radial)
	local tongues={}
	for i=1,count do tongues[i]=ribbon(parent,"FlameTongue",7,Color3.fromRGB(255,73,33),Color3.fromRGB(255,228,133))end
	return function(t)
		for i,draw in ipairs(tongues)do
			local age=(t*(.72+i*.021)+i*.173)%1;local life=math.sin(age*math.pi)
			local length=h*(.34+.30*life)*(if radial then .65 else 1)
			local x=w*(.08+i/(count+1)*.84);local y=h*.88
			local angle=radial and i/count*math.pi*2 or 0
			draw(function(u)
				local bend=math.sin(u*3.2+t*3+i)*u*6
				local yy=-u*length;local width=(3.5+life*3)*math.sin(math.pi*u)^.55*(.3+life*.7)
				if radial then
					local r=h*.23
					return w*.76+math.cos(angle)*(r-yy)+math.sin(angle)*bend,h*.43+math.sin(angle)*(r-yy)-math.cos(angle)*bend,width
				end
				return x+bend,y+yy,width
			end,.16+(1-life)*.58)
		end
	end
end
local function aurora(parent,w,h,count)
	local bands={};for i=1,count do bands[i]=ribbon(parent,"AuroraRibbon",20,Color3.fromRGB(65,210,177),Color3.fromRGB(190,151,255))end
	return function(t)
		for i,draw in ipairs(bands)do draw(function(u)
			local y=h*(.42+(i-(count+1)/2)*.20)+math.sin(u*6+t*.9+i)*h*.18+math.sin(u*13-t*.6)*h*.06
			return w*(.025+u*.95),y,(4+i*1.4)*math.sin(u*math.pi)^.5+.3
		end,.32+i*.025)end
	end
end
local function smoke(parent,w,h,count,cloud)
	local curls={};for i=1,count do curls[i]=ribbon(parent,cloud and"CloudCurl"or"InkTendril",14,
		cloud and Color3.fromRGB(83,113,153)or Color3.fromRGB(48,25,82),cloud and Color3.fromRGB(177,174,210)or Color3.fromRGB(195,79,228))end
	return function(t)
		for i,draw in ipairs(curls)do
			local age=(t*.12+i/count)%1
			local side=if i%2==0 then-1 else 1
			draw(function(u)
				local a=u*4.8+i*1.3+t*.38
				local cx=w*(if side<0 then .16 else .84);local cy=h*.5
				local rx=w*(.10+.07*age);local ry=h*(.16+.10*age)
				return cx+math.cos(a)*rx*(.4+.6*u),cy+math.sin(a)*ry+math.sin(t*.8+u*4+i)*h*.06,(4+age*7)*math.sin(u*math.pi)^.45+.1
			end,.33+age*.30)
		end
	end
end
local function constellation(parent,w,h,count)
	local stars,links,tail={},{},{}
	for i=1,count do stars[i]=dot(parent,"OrbitingStar",2+i%2,WHITE);links[i]=frame(parent,"ConstellationTrace",Color3.fromRGB(173,188,246),.65)end
	for i=1,9 do tail[i]=dot(parent,"CometTrail",math.max(1,3-i*.22),Color3.fromRGB(246,219,153))end
	return function(t)
		local points={}
		for i,p in ipairs(stars)do
			local a=i*math.pi*2/count+t*(.15+i*.009)
			local x=w*.5+math.cos(a)*w*.43;local y=h*.5+math.sin(a)*h*(.24+.06*math.sin(t*.3))
			points[i]={x,y};p.Position=UDim2.fromOffset(x,y);p.BackgroundTransparency=.05+math.sin(t*1.8+i)^2*.6
		end
		for i,p in ipairs(links)do local a,b=points[i],points[i%count+1];local grow=math.clamp((t*.28+i/count)%1*2,0,1)
			line(p,a[1],a[2],a[1]+(b[1]-a[1])*grow,a[2]+(b[2]-a[2])*grow,.65,.58+(1-grow)*.37)
		end
		for i,p in ipairs(tail)do local a=t*.9-i*.055;p.Position=UDim2.fromOffset(w*.5+math.cos(a)*w*.46,h*.5+math.sin(a)*h*.38);p.BackgroundTransparency=.05+i*.075 end
	end
end
local function leaves(parent,w,h,count)
	local shapes,veins={},{ }
	for i=1,count do shapes[i]=polygon(parent,"MapleLeaf",12);veins[i]=frame(parent,"LeafMidrib",Color3.fromRGB(132,62,35),.15)end
	local outline={{0,-1},{.22,-.42},{.6,-.77},{.56,-.18},{1,-.23},{.48,.28},{.52,.67},{.12,.47},{0,1},{-.12,.47},{-.52,.67},{-.48,.28},{-1,-.23},{-.56,-.18},{-.6,-.77},{-.22,-.42}}
	return function(t)
		for i,draw in ipairs(shapes)do
			local age=(t*(.08+i*.004)+i/count)%1;local turn=t*(.65+i*.03)+i
			local x=(i/count)*w+math.sin(t*.7+i)*w*.065-age*w*.1;local y=-6+(age+age*age)*.5*(h+12)
			local sx=(2.7+i%3)*(.25+.75*math.abs(math.cos(turn)));local sy=4+i%2
			local angle=math.sin(turn*.7)*.8
			local function point(xx,yy)return{x+xx*sx*math.cos(angle)-yy*sy*math.sin(angle),y+xx*sx*math.sin(angle)+yy*sy*math.cos(angle)}end
			local points={};for _,p in ipairs(outline)do table.insert(points,point(p[1],p[2]))end
			draw(points,(if i%2==0 then Color3.fromRGB(240,156,62)else Color3.fromRGB(197,71,57)):Lerp(Color3.fromRGB(255,207,106),math.abs(math.cos(turn))*.25),.04)
			local a,b=point(0,-.6),point(0,.75);line(veins[i],a[1],a[2],b[1],b[2],.6,.22)
		end
	end
end
local function water(parent,w,h,count)
	local waves={ribbon(parent,"WaterCrest",21,Color3.fromRGB(40,171,206),Color3.fromRGB(190,247,255)),ribbon(parent,"WaterUndertow",19,Color3.fromRGB(85,203,239),WHITE)}
	local drops,rings,strokes={},{},{}
	for i=1,count do
		drops[i]=dot(parent,"BallisticDrop",2+i%2,Color3.fromRGB(195,249,255))
		local ring=frame(parent,"ImpactRipple",WHITE,1);round(ring,99)
		strokes[i]=new("UIStroke",{Color=Color3.fromRGB(139,232,247),Thickness=.8,Transparency=.3},ring);rings[i]=ring
	end
	return function(t)
		for i,draw in ipairs(waves)do draw(function(u)
			return u*w,h*(.62+(i-1)*.17)+math.sin(u*8-t*1.7+i)*h*.11,(2.8+math.sin(u*5+t)^2*2)*math.sin(u*math.pi)^.4+.2
		end,.28+(i-1)*.13)end
		for i,p in ipairs(drops)do
			local age=(t*.38+i/count)%1;local flight=math.min(1,age/.73)
			local x=(i/(count+1))*w+math.sin(i)*flight*9;local base=h*.72
			p.Position=UDim2.fromOffset(x,base-h*.90*flight+h*.90*flight*flight);p.Visible=age<.73
			local ripple=math.max(0,(age-.73)/.27);local ring=rings[i];ring.Position=UDim2.fromOffset(x,base)
			ring.Size=UDim2.fromOffset(2+ripple*18,1+ripple*5);ring.Visible=age>=.73;strokes[i].Transparency=.2+ripple*.8
		end
	end
end

function Motion.Build(parent,style,w,h,small)
	local root=new("Frame",{Name="LiveEffectGeometry",BackgroundTransparency=1,Size=UDim2.fromOffset(w,h)},parent)
	root:SetAttribute("MotionStyle",style)
	local update=function()end
	if style=="volt"then update=bolt(root,w,h,small)
	elseif style=="vesper"then update=smoke(root,w,h,small and 2 or 4)
	elseif style=="boreal"then update=aurora(root,w,h,small and 2 or 3)
	elseif style=="ember"then update=fire(root,w,h,small and 4 or 9)
	elseif style=="prism"then
		local pieces={};for i=1,(small and 3 or 5)do pieces[i]=crystal(root,"TurningPrism",small and 3 or 4.5)end
		update=function(t)for i,draw in ipairs(pieces)do local a=i/#pieces*math.pi*2+t*.20
			draw(w*.5+math.cos(a)*w*.43,h*.5+math.sin(a)*h*.30,math.sin(t*.4+i)*.32,t*.9+i*.8)
		end end
	elseif style=="astrolabe"then update=constellation(root,w,h,small and 5 or 8)
	elseif style=="maple"then update=leaves(root,w,h,small and 3 or 6)
	elseif style=="tide"then update=water(root,w,h,small and 3 or 5)
	end
	return root,function(t)root:SetAttribute("MotionTime",t);update(t)end
end

function Motion.Background(parent,style,w,h)
	local root=new("Frame",{Name="LivingBackground",BackgroundTransparency=1,Position=UDim2.fromOffset(w*.40,0),Size=UDim2.fromOffset(w*.6,h),ClipsDescendants=true},parent)
	root:SetAttribute("MotionStyle",style)
	local ww=w*.6;local update
	if style=="velvet"then update=leaves(root,ww,h,7)
	elseif style=="starmap"then update=constellation(root,ww,h,8)
	elseif style=="boreal"then update=aurora(root,ww,h,4)
	elseif style=="eclipse"then update=fire(root,ww,h,12,true)
	elseif style=="horizon"then update=smoke(root,ww,h,3,true)
	elseif style=="tidal"then update=water(root,ww,h,6)
	elseif style=="geode"then
		local rays={};for i=1,6 do rays[i]=frame(root,"RefractedRay",i%2==0 and Color3.fromRGB(195,156,255)or WHITE,.5)end
		update=function(t)for i,p in ipairs(rays)do local age=(t*.15+i/6)%1;local x=ww*(.36+i*.07);local y=h*(.35+i%2*.22)
			line(p,x,y,x+math.sin(i*1.4)*age*25,y+age*h*.5,.7,.45+age*.55)
		end end
	elseif style=="forge"then update=fire(root,ww,h,8)
	else update=function()end end
	return root,function(t)root:SetAttribute("MotionTime",t);update(t)end
end

function Motion.Frame(parent,style,cx,cy,radius,w,h)
	local root=new("Frame",{Name="FrameMechanism",BackgroundTransparency=1,Size=UDim2.fromOffset(w,h)},parent)
	root:SetAttribute("MotionStyle",style)
	local update=function()end
	if style=="wings"then
		local feathers={};for i=1,12 do feathers[i]=ribbon(root,"FlexingFeather",6,Color3.fromRGB(224,177,111),WHITE)end
		update=function(t)for i,draw in ipairs(feathers)do
			local side=if i<=6 then-1 else 1;local j=(i-1)%6
			draw(function(u)
				local flex=math.sin(t*1.7-j*.23)*u*u*3.4
				return cx+side*(radius*.70+u*(8+j*1.7)+math.sin(u*math.pi)*2),cy+radius*.48-u*(radius*1.28-j*3.3)+flex,math.sin(u*math.pi)^.55*(2.7-j*.18)+.2
			end,.18)end end
	elseif style=="circuit"then
		local gears={}
		for side=-1,1,2 do
			local gear=new("Frame",{Name="MechanicalRotor",BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(14,14),Position=UDim2.fromOffset(cx+side*radius*.75,cy-radius*.65)},root)
			for i=1,10 do local a=i*math.pi/5;local tooth=frame(gear,"RotorTooth",Color3.fromRGB(126,196,235));tooth.Position=UDim2.fromOffset(7+math.cos(a)*5.7,7+math.sin(a)*5.7);tooth.Size=UDim2.fromOffset(2.6,2.7);tooth.Rotation=math.deg(a)end
			local hub=dot(gear,"EnergyBearing",5,WHITE);hub.Position=UDim2.fromOffset(7,7)
			gears[side]=gear
		end
		update=function(t)for side,gear in pairs(gears)do gear.Rotation=t*side*45 end end
	elseif style=="facet"then
		local pieces={};for i=1,5 do pieces[i]=crystal(root,"CrownCrystal",3.5)end
		update=function(t)for i,draw in ipairs(pieces)do local a=math.pi+(i-1)/4*math.pi
			draw(cx+math.cos(a)*(radius+6),cy+math.sin(a)*(radius+6),a+math.pi/2,t*.5+i*.6)
		end end
	elseif style=="rift"then
		local live,step=Motion.Build(root,"vesper",radius*2+16,radius*2+16,true);live.Position=UDim2.fromOffset(cx-radius-8,cy-radius-8);update=step
	elseif style=="comet"then
		local tails={};for i=1,14 do tails[i]=dot(root,"FrameCometTail",math.max(1,3.5-i*.17),i<4 and WHITE or Color3.fromRGB(229,191,116))end
		update=function(t)for i,p in ipairs(tails)do local a=t*.72-i*.035;p.Position=UDim2.fromOffset(cx+math.cos(a)*(radius+6),cy+math.sin(a)*(radius+6));p.BackgroundTransparency=.06+i*.055 end end
	elseif style=="brass"then
		local leavesSet={};for i=1,10 do leavesSet[i]=frame(root,"UnfoldingLaurel",Color3.fromRGB(238,200,115));round(leavesSet[i],3)end
		update=function(t)for i,p in ipairs(leavesSet)do local a=i/10*math.pi*2;local opening=math.sin(t*.9-i*.4)*.5+.5
			p.Position=UDim2.fromOffset(cx+math.cos(a)*(radius+3),cy+math.sin(a)*(radius+3));p.Size=UDim2.fromOffset(2+opening*1.2,5);p.Rotation=math.deg(a)+35+opening*12;p.BackgroundTransparency=.18+(1-opening)*.35
		end end
	end
	return root,function(t)root:SetAttribute("MotionTime",t);update(t)end
end
return Motion

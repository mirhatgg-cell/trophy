-- Dense relief sculptures; no external models or particle-color substitutions.
local B=require(script.Parent:WaitForChild('MuseumBlueprint'))
local S={}
local mats={};for _,v in ipairs(Enum.Material:GetEnumItems()) do mats[v.Value]=v end
local shapes={Enum.PartType.Ball,Enum.PartType.Block,Enum.PartType.Cylinder}
local function vec(t)return Vector3.new(t[1],t[2],t[3])end
local function cf(p,r)return CFrame.new(p[1],p[2],p[3],table.unpack(r))end
local function color(c,n)return Color3.fromRGB(math.clamp(c[1]+n,0,255),math.clamp(c[2]+n,0,255),math.clamp(c[3]+n,0,255))end
local function hash(x,y,s)return ((x*374761393+y*668265263+s*69069)%65536)/65535 end
local function value(parent,class,name,v)local o=Instance.new(class);o.Name=name;o.Value=v;o.Parent=parent;return o end
function S.build(parent,e,yieldFn)
 local model=Instance.new('Model');model.Name='Exhibit_'..e.key;model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
 local body=Instance.new('Folder',model);body.Name='Body';local anim=Instance.new('Folder',model);anim.Name='Animation'
 local created=0
 local function part(folder,name,size,frame,c,mat,alpha,shape)
  local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=frame;p.Color=c;p.Material=mats[mat] or Enum.Material.Marble
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Transparency=alpha or 0;p.Shape=shapes[(shape or 1)+1]
  p.Parent=folder;created+=1;if created%256==0 and yieldFn then yieldFn(256) end;return p
 end
 local level=e.level;local mutation=e.mutation;local center=vec(e.center);local base=B.colors[level];local material=B.materials[level];local scale=e.scale*(1+(level-1)*.035)
 if mutation=='gold' then base={235,178,47};material=1088 elseif mutation=='ghost' then base={181,231,235};material=1568 elseif mutation=='galaxy' then base={22,31,70};material=1568 end
 local alpha=mutation=='ghost' and .38 or mutation=='galaxy' and .12 or (material==1536 or material==1568) and .08 or 0
 local specs=B.shapes[e.kind];local resolution=math.ceil(math.sqrt(1200/(6*#specs)));local bodyCount=0
 for bi,sp in ipairs(specs) do
  local size={sp.size[1]*scale,sp.size[2]*scale,sp.size[3]*scale};local position=center+vec(sp.position)*scale;local frame=cf({position.X,position.Y,position.Z},sp.rotation)
  part(body,'Sculpture core',Vector3.new(math.max(.012,size[1]-.14*scale),math.max(.012,size[2]-.14*scale),math.max(.012,size[3]-.14*scale)),frame,color(base,0),material,alpha,sp.shape);bodyCount+=1
  for axis=1,3 do
   local axes={};for q=1,3 do if q~=axis then table.insert(axes,q) end end;local a,b=axes[1],axes[2]
   for _,sign in ipairs({-1,1}) do for u=0,resolution-1 do for v=0,resolution-1 do
    local localP={0,0,0};localP[axis]=sign*size[axis]/2;localP[a]=((u+.5)/resolution-.5)*size[a];localP[b]=((v+.5)/resolution-.5)*size[b]
    local noise=hash(u+(bi-1)*13,v+(axis-1)*17,level)
    if sp.shape==0 then local norm=0;for q=1,3 do norm+=(localP[q]/math.max(.001,size[q]/2))^2 end;norm=math.sqrt(norm);for q=1,3 do localP[q]/=norm end
    elseif sp.shape==2 and axis~=1 then local norm=math.sqrt((localP[2]/math.max(.001,size[2]/2))^2+(localP[3]/math.max(.001,size[3]/2))^2);localP[2]/=math.max(norm,.001);localP[3]/=math.max(norm,.001) end
    local bump=(noise-.5)*(level==1 and mutation=='natural' and .085 or .018)*scale;localP[axis]+=sign*bump
    local sz={};for q=1,3 do sz[q]=math.max(.018,size[q]/resolution*1.04) end;sz[axis]=.022*scale+math.abs(bump)
    local variation=(noise-.5)*(level==1 and 24 or 13);local c=color(base,variation);local mat=material
    if mutation=='galaxy' and noise>.965 then c=Color3.fromRGB(203,233,249);mat=288 elseif mutation=='gold' and (u+v)%resolution==0 then c=Color3.fromRGB(255,224,133) end
    part(body,'Material relief tessera',vec(sz),frame*CFrame.new(vec(localP)),c,mat,alpha);bodyCount+=1
   end end end
  end
 end
 assert(bodyCount>=1000,'Dense trophy below body budget')
 local theme=mutation=='natural' and level==1 and 'mud' or mutation~='natural' and mutation or 'rank'..level
 value(model,'IntValue','Level',level);value(model,'StringValue','Mutation',mutation);value(model,'StringValue','Kind',e.kind);value(model,'StringValue','Theme',theme);value(model,'Vector3Value','Center',center);value(model,'IntValue','BodyPartCount',bodyCount)
 local function ap(name,sz,off,c,mat,shape,trans,rotation)
  return part(anim,name,vec(sz),CFrame.new(center+vec(off))*(rotation or CFrame.new()),color(c or base,0),mat or material,trans or 0,shape or 1)
 end
 if theme=='mud' then
  for i=0,47 do
   local sp=specs[i%#specs+1];local a=i*math.pi*(3-math.sqrt(5));local localP=Vector3.new(math.sin(a)*sp.size[1]*.4*scale,math.cos(a)*sp.size[2]*.4*scale,(i%2==1 and 1 or -1)*(sp.size[3]*scale/2+.06))
   local r=sp.rotation;local off=vec(sp.position)*scale+CFrame.new(0,0,0,table.unpack(r)):VectorToWorldSpace(localP)
   ap('Fold_'..i,{.42,.2,.42},{off.X,off.Y,off.Z},{math.clamp(base[1]+i%5*3,0,255),math.clamp(base[2]+i%5*3,0,255),math.clamp(base[3]+i%5*3,0,255)},1344,0)
  end
  for i=0,23 do local a=i*math.pi/12;ap('Drop_'..i,{.13,.25,.13},{math.cos(a)*1.1,.25+(i%6)*.27,math.sin(a)*1.1},{65,42,24},1344,0) end
  for i=0,31 do local a=i*math.pi/16;ap('Ripple_'..i,{.2,.035,.08},{math.cos(a)*1.25,-.55,math.sin(a)*1.25},{77,51,28},1344,1,0,CFrame.Angles(0,-a,0)) end
 elseif theme=='gold' or level==7 and mutation=='natural' then
  for i=0,63 do local a=i*math.pi/32;ap('GoldFiligree_'..i,{.14,.035,.2},{math.cos(a)*2.7,.35+math.sin(a*4)*.15,math.sin(a)*2.7},{240,191,65},1088,1,0,CFrame.Angles(0,-a,0)) end
  for i=0,23 do local a=i*math.pi/12;local p=ap('Coin_'..i,{.2,.055,.2},{math.cos(a)*2.4,.8+(i%3)*.25,math.sin(a)*2.4},{255,217,96},1088,2,0,CFrame.Angles(0,0,.5));p.Reflectance=.25 end
 elseif theme=='ghost' then
  for i=0,79 do local a=i*math.pi/10;local r=2.8+.15*math.sin(a);ap('GhostRibbon_'..i,{.13,.12,.3},{math.cos(a)*r,i*.035-.4,math.sin(a)*r},{186,235,237},1568,1,.42,CFrame.Angles(0,-a,0)) end
  for i=0,23 do local a=i*math.pi/12;ap('GhostWisp_'..i,{.06,.3,.08},{math.cos(a)*3.0,.25+i%5*.3,math.sin(a)*3.0},{217,246,246},288,1,.35) end
 elseif theme=='galaxy' then
  for ring=0,2 do local tilt=CFrame.Angles(.45+ring*.45,0,0);for i=0,47 do local a=i*math.pi/24;local off=tilt:PointToWorldSpace(Vector3.new(math.cos(a)*(2.7+ring*.2),.7,math.sin(a)*(2.7+ring*.2)));ap('Orbit'..ring..'_'..i,{.12,.035,.09},{off.X,off.Y,off.Z},{98+ring*30,161+ring*25,231},288,1,0,tilt*CFrame.Angles(0,-a,0)) end end
  local starColors={{239,245,247},{141,209,237},{238,205,146}}
  for i=0,71 do local a=i*2.399963;local r=1.4+(i%11)*.14;ap('Star_'..i,{.065,.065,.065},{math.cos(a)*r,(i%17)*.13-.3,math.sin(a)*r},starColors[i%3+1],288,0) end
 else
  for _,q in ipairs(B.rankOrnaments[tostring(level)])do
   local r=q.rotation;ap(q.name,q.size,q.position,q.color,q.material,q.shape,q.alpha,CFrame.new(0,0,0,table.unpack(r)))
  end
 end
 if yieldFn and created%256~=0 then yieldFn(created%256) end
 model.Parent=parent;return model
end
return S

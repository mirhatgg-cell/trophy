-- Small architectural symbols for all fifty exhibits; generated geometry, no asset dependency.
local Icons={}
function Icons.build(kind,block)
 local function b(x,y,z,w,h,d) return block(Vector3.new(x,y,z),Vector3.new(w,h,d)) end
 local function ring(radius,height,count)
  for i=1,count do local a=i*math.pi*2/count; b(math.cos(a)*radius,height,math.sin(a)*radius,.3,.35,.3) end
 end
 if kind=='tetris' then for _,v in ipairs({{-1,0},{0,0},{1,0},{0,1}}) do b(v[1]*.65,v[2]*.65,0,.6,.6,.6) end
 elseif kind=='maze' then for _,v in ipairs({{-.8,0,0},{0,0,.8},{.8,0,-.4},{-.4,0,-.8}}) do b(v[1],.4,v[3],.2,.8,1) end
 elseif kind=='duel' then for _,x in ipairs({-.55,.55}) do b(x,.7,0,.2,1.8,.25); b(x,.2,0,.8,.12,.2) end
 elseif kind=='chess' then b(0,.6,0,.55,1.5,.55); b(0,1.4,0,1,.15,.2); b(0,-.25,0,1.2,.25,1.2)
 elseif kind=='snake' then for i=1,10 do local a=i*math.pi/6; b(math.cos(a)*.9,.15,math.sin(a)*.9,.4,.4,.4) end
 elseif kind=='bridge' then for i=-2,2 do b(0,0,i*.4,.7,.15,.35); b(-.55,.4,i*.4,.1,.8,.1); b(.55,.4,i*.4,.1,.8,.1) end
 elseif kind=='lift' then b(0,.1,0,1.3,.2,1.3); for _,x in ipairs({-.8,.8}) do b(x,.7,0,.12,2,.12) end; b(0,1.6,0,1.8,.3,.5)
 elseif kind=='rotatingmaze' then ring(.9,.2,12); ring(.5,.5,8)
 elseif kind=='rhythm' then for i=-2,2 do b(i*.35,.6+math.abs(i)*.15,0,.2,1.2+math.abs(i)*.3,.3) end
 elseif kind=='frozen' then for i=-1,1 do local p=b(i*.6,.5+math.abs(i)*.2,0,.35,1.7- math.abs(i)*.4,.4); p.Transparency=.3 end
 elseif kind=='volcano' then b(0,.1,0,1.8,.6,1.8); ring(.5,.6,10); b(0,1,0,.3,.8,.3)
 elseif kind=='domino' then for i=-2,2 do b(0,.6,i*.4,.8,1.4,.16) end
 elseif kind=='memory' then for x=-1,1 do for z=-1,1 do b(x*.45,0,z*.45,.38,.2,.38) end end; b(0,.7,0,.25,.8,.25)
 elseif kind=='tower' then for i=0,3 do b(0,i*.5,0,1.4,.15,1.4) end; b(-.5,.6,-.5,.2,1.6,.2)
 elseif kind=='rotor' then b(0,.25,0,2,.15,.2); b(0,.4,0,.2,.15,2); b(0,.4,0,.3,1,.3)
 elseif kind=='curatormaze' then b(-.6,.3,0,.2,.8,1.7); b(.6,.3,0,.2,.8,1.7); b(0,.9,0,1.5,.2,.7); b(0,1.2,0,.5,.4,.4)
 elseif kind=='clock' then ring(.85,.1,12); b(0,.35,0,.2,.15,1.5); b(.35,.5,0,.8,.15,.2)
 elseif kind=='pendulum' then b(0,1.4,0,1.8,.2,.3); for _,x in ipairs({-.7,.7}) do b(x,.55,0,.12,1.5,.12); local p=b(x,-.2,0,.5,.5,.5); p.Shape=Enum.PartType.Ball end
 elseif kind=='balance' then b(0,.7,0,2,.2,.25); b(0,.5,0,.2,1.6,.2); b(-.8,-.1,0,.6,.2,.8); b(.8,-.1,0,.6,.2,.8)
 elseif kind=='teamescape' then for i=1,4 do local a=i*math.pi/2; b(math.cos(a)*.7,.4,math.sin(a)*.7,.4,.8,.4) end; b(0,0,0,1.8,.2,1.8)
 elseif kind=='walls' then b(-.5,.5,0,.2,1.2,1.7); b(.5,.5,0,.2,1.2,1.7); b(0,-.2,0,1.7,.15,.2)
 elseif kind=='pinball' then b(0,-.2,0,1.7,.2,2); local p=b(.5,.3,.5,.5,.5,.5); p.Shape=Enum.PartType.Ball; b(-.5,.1,-.4,.35,.6,.35)
 elseif kind=='rooms' then for x=-1,1 do for z=-1,1 do b(x*.5,0,z*.5,.4,.4,.4) end end; b(0,-.3,0,2,.1,.15)
 elseif kind=='gravity' then ring(.8,.1,10); ring(.8,1.3,10); b(0,.7,0,.25,.8,.25)
 elseif kind=='drawbridge' then b(0,0,-.7,1,.2,.8); local p=b(0,.4,.3,1,.2,1.3); p.CFrame*=CFrame.Angles(.45,0,0)
 elseif kind=='execution' then b(0,1.1,0,1.7,.3,.6); b(0,.7,0,.9,.5,.9); for _,x in ipairs({-.7,.7}) do b(x,.5,0,.15,1.8,.15) end
 elseif kind=='wheel' then for i=1,12 do local a=i*math.pi/6; b(math.cos(a)*.8,.7+math.sin(a)*.8,0,.25,.25,.35) end; b(0,.7,0,.3,.3,.8)
 elseif kind=='flood' then for i=0,2 do b(0,i*.45,0,1.6,.1,1.6) end; b(0,.5,0,.2,1.4,.2)
 elseif kind=='risingwater' then for i=1,8 do local a=i*math.pi/2; b(math.cos(a)*.6,i*.16,math.sin(a)*.6,.65,.12,.65) end
 elseif kind=='corridors' then b(-.7,.3,0,.2,.8,1.8); b(0,.3,.7,1.5,.8,.2); b(.7,.8,-.2,.2,.8,1)
 elseif kind=='furnace' then b(0,.4,0,1.4,1.2,.7); b(-.5,1.2,0,.3,.9,.3); b(.5,1.2,0,.3,.9,.3); b(0,.2,.5,.7,.4,.2)
 elseif kind=='platforms' then for i=-1,1 do b(i*.6,0,0,.5,.2,.7); b(i*.6,.7,0,.06,1.4,.06) end
 elseif kind=='press' then for i=-1,1 do b(i*.6,.6,0,.45,.5,.65); b(i*.6,1,0,.1,1,.1) end; b(0,-.2,0,2,.2,1)
 elseif kind=='debris' then b(0,0,0,1.7,.2,1.7); b(-.5,.7,.2,.5,.5,.5); b(.4,1,-.2,.35,.35,.35); b(.1,.3,.5,.4,.4,.4)
 elseif kind=='gears' then ring(.8,.1,12); ring(.35,.2,8); b(0,.2,0,.4,.4,.4)
 elseif kind=='statues' then for i=-1,1 do b(i*.6,.4,0,.25,.9,.3); b(i*.6,1,0,.35,.35,.35) end
 elseif kind=='shrink' then for i=0,2 do b(0,i*.35,0,1.8-i*.4,.2,1.8-i*.4) end
 elseif kind=='crane' then b(-.7,.7,0,.3,1.9,.3); b(0,1.5,0,2,.2,.3); b(.65,.8,0,.05,1.4,.05); b(.65,.1,0,.6,.6,.6)
 elseif kind=='blades' then for i=-1,1 do b(i*.65,.3,0,.15,.7,.15); b(i*.65,.5,0,.75,.1,.1); b(i*.65,.5,0,.1,.1,.75) end
 elseif kind=='collapse' then b(-.5,0,0,.8,.2,1.6); b(.5,-.3,.2,.8,.2,1.6); b(.2,-.7,0,.3,.3,.3)
 elseif kind=='shift' then b(0,-.2,0,2,.1,.1); b(-.5,.05,0,.6,.2,.9); b(.6,.05,.5,.6,.2,.9)
 elseif kind=='bulkhead' then b(-.6,.4,0,.5,1.3,.3); b(.6,.4,0,.5,1.3,.3); b(0,1.1,0,1.8,.2,.4); b(0,.3,0,.25,.5,.25)
 elseif kind=='machine' then for i=-1,1 do local p=b(0,.4,i*.6,1.6,.4,.4); p.Shape=Enum.PartType.Cylinder end; b(.6,1,0,.4,.8,.4)
 elseif kind=='pillars' then for x=-1,1 do for z=-1,1 do b(x*.5,.2+(x+z+2)*.1,z*.5,.35,.5+(x+z+2)*.2,.35) end end
 elseif kind=='resonance' then ring(.8,0,16); ring(.5,.4,12); ring(.25,.8,8)
 elseif kind=='mirrors' then for _,x in ipairs({-.6,.6}) do local p=b(x,.6,0,.1,1.3,.8); p.CFrame*=CFrame.Angles(0,x,0) end; b(0,.3,0,1.5,.1,.1)
 elseif kind=='oxygen' then for i=-1,1 do local p=b(i*.6,.4,0,.45,1.3,.45); p.Shape=Enum.PartType.Cylinder end; b(0,.7,0,1.8,.1,.1)
 elseif kind=='switches' then for i=1,4 do local a=i*math.pi/2; b(math.cos(a)*.7,.4,math.sin(a)*.7,.3,.9,.3) end; b(0,.8,0,.2,.4,.2)
 elseif kind=='convoy' then for i=-1,1 do b(0,.1,i*.65,.7,.4,.55); b(-.5,.6,i*.65,.12,1.4,.12); b(.5,.6,i*.65,.12,1.4,.12) end
 elseif kind=='finale' then for i=0,3 do b(0,i*.45,0,1.8-i*.35,.2,1.8-i*.35) end; b(0,1.8,0,.18,.6,.18)
 else error('Missing trophy icon: '..tostring(kind)) end
end
return Icons

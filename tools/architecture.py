"""Purpose-built physical architecture shared by the place builder and dimension report."""
import math
import xml.etree.ElementTree as ET
from world_spec import records

class Architect:
    def __init__(self,item): self.item=item; self.counts={}
    def folder(self,parent,name,cls='Model'): return self.item(parent,cls,name)
    def p(self,parent,name,size,pos,color=(137,140,136),mat=816,rot=0,cls='Part',alpha=0):
        # Serialized Roblox BasePart color uses Color3uint8, not the nonserialized Color alias.
        obj=self.item(parent,cls,name,[('Vector3','size',size),('CoordinateFrame','CFrame',(*pos,rot)),('Color3uint8','Color3uint8',4278190080+color[0]*65536+color[1]*256+color[2]),('bool','Anchored',True),('token','Material',mat),('float','Transparency',alpha),('token','TopSurface',0),('token','BottomSurface',0)])
        return obj
    def sign(self,parent,text,pos,width=18,height=5):
        plate=self.p(parent,'Inscription',(width,height,.45),pos,(39,48,51),1088)
        gui=self.item(plate,'SurfaceGui','Inscription',[('token','Face',5),('float','PixelsPerStud',32),('token','SizingMode',1)])
        self.item(gui,'TextLabel','Text',[('UDim2','Size',(1,0,1,0)),('float','BackgroundTransparency',1),('string','Text',text),('Color3','TextColor3',(238,224,188)),('float','TextSize',24),('bool','TextScaled',True),('bool','TextWrapped',True)])
        return plate
    def stairs(self,parent,x,y,z,rise,width=12):
        n=math.ceil(rise/.5)
        for i in range(n): self.p(parent,'Stair tread',(width,.5,1.5),(x,y+.25+i*.5,z+i*1.5),(148,146,134))
        self.p(parent,'Stair stringer',(1,rise,1),(x-width/2,y+rise/2,z+n*.75),(75,79,79),1088)
        self.p(parent,'Stair stringer',(1,rise,1),(x+width/2,y+rise/2,z+n*.75),(75,79,79),1088)
    def rail(self,parent,x,y,z,w,axis='x'):
        for i in range(int(w/10)+1):
            px=x-w/2+i*10 if axis=='x' else x; pz=z if axis=='x' else z-w/2+i*10
            self.p(parent,'Guardrail post',(.35,4,.35),(px,y+2,pz),(73,80,82),1088)
        self.p(parent,'Guardrail top',(w,.35,.35) if axis=='x' else (.35,.35,w),(x,y+4,z),(92,101,102),1088)
    def lift(self,parent,x,y,z,height):
        model=self.folder(parent,'Lift')
        for dx in (-6,6):
            for dz in (-6,6): self.p(model,'Guide rail',(.6,height+12,.6),(x+dx,y+height/2,z+dz),(79,89,94),1088)
        self.p(model,'Cabin',(12,1,12),(x,y+.5,z),(114,111,98),1088)
        self.p(model,'LiftMotor',(14,5,14),(x,y+height+9,z),(69,75,74),1088)
        self.p(model,'Counterweight',(3,12,4),(x+8,y+height-8,z),(76,78,78),1088)
        self.p(model,'Cable',(.18,height,.18),(x,y+height/2+2,z),(48,50,49),1088)
        self.p(model,'UpperStop',(14,1,16),(x+16,y+height,z),(144,142,132))
        self.p(model,'LowerStop',(14,1,16),(x+16,y,z),(144,142,132))
        self.sign(model,'LIFT / USE E',(x,y+4,z-6),9,2)
        return model
    def hall(self,parent,name,x,z,w,d,h=28):
        room=self.folder(parent,name)
        self.p(room,'Foundation',(w+6,6,d+6),(x,-3,z),(97,99,94))
        self.p(room,'Floor',(w,2,d),(x,0,z),(147,143,131),784)
        # Entry and exit openings are 16 Studs wide. Framed windows have real thickness.
        for dx in (-w/2,w/2):
            for zz in range(int(-d/2+8),int(d/2),16):
                self.p(room,'Structural pier',(3,h,3),(x+dx,h/2,z+zz),(115,119,115))
                self.p(room,'Window',(1,h-8,12),(x+dx,h/2+1,z+zz+7.5),(166,196,204),1568,alpha=.6)
            self.p(room,'Wall beam',(4,4,d),(x+dx,h-1,z),(111,115,112))
        for dz in (-d/2,d/2):
            self.p(room,'Lintel',(w,5,4),(x,h-2,z+dz),(112,117,111))
            for dx in (-w/4-4,w/4+4): self.p(room,'End wall',(w/2-8,h-5,3),(x+dx,(h-5)/2,z+dz),(128,130,121))
        self.p(room,'Roof',(w+6,3,d+6),(x,h+2,z),(75,83,80),816)
        for zz in (-d/3,0,d/3):
            self.p(room,'Ceiling service beam',(w,2,2),(x,h-5,z+zz),(69,79,80),1088)
            self.p(room,'Linear luminaire',(w*.6,.25,.6),(x,h-6,z+zz),(237,220,168),288)
        self.p(room,'Cable tray',(.5,1,d),(x+w/2-4,h-6,z),(61,66,65),1088)
        self.p(room,'Ventilation duct',(3,3,d),(x-w/2+4,h-5,z),(99,111,114),1088)
        return room
    def lobby(self,parent):
        l=self.folder(parent,'Lobby')
        ET.SubElement(l.find('Properties'),'token',{'name':'ModelStreamingMode'}).text='2'
        self.p(l,'Complex foundation',(480,12,360),(0,-7,0),(103,108,102))
        self.p(l,'Central plaza',(320,2,240),(0,-.5,0),(154,151,137),784)
        for x in range(-144,145,24):
            self.p(l,'Expansion joint',(.15,.05,240),(x,.53,0),(78,85,81))
        for z in range(-108,109,24): self.p(l,'Expansion joint',(320,.05,.15),(0,.53,z),(78,85,81))
        self.p(l,'Arrival',(40,1,28),(0,1,125),(136,144,140),784,cls='SpawnLocation')
        self.sign(l,'M O U N T A I N V E R S E',(0,14,-64),70,8)
        self.p(l,'PublicArchiveGate',(8,1,8),(205,1,140),(151,132,85),1088)
        self.sign(l,'PUBLIC ARCHIVE',(205,6,144.5),20,3)
        self.p(l,'AdminConsole',(6,4,4),(24,2,125),(110,117,106),1088)
        self.sign(l,'INSPECTION',(24,6,127.5),10,2)
        self.sign(l,'ARRIVAL / TRIALS NORTH / MUSEUMS EAST',(0,5,110),42,4)
        for x in (-205,205):
            h=self.hall(l,'Navigation Hall' if x<0 else 'Museum Exchange',x,0,62,300,32)
            self.sign(h,'THE FIFTY SUMMITS' if x<0 else 'ARCHIVE OF SURVIVORS',(x,9,149),45,6)
        market=self.hall(l,'Curator Market',0,159,120,36,22)
        self.p(market,'ShopCounter',(70,3,4),(0,2,153),(103,86,64),528)
        for x in range(-48,49,12):
            self.p(market,'Display case base',(7,3,5),(x,2,168),(120,116,101))
            self.p(market,'Glass cabinet',(7,7,5),(x,7,168),(175,205,211),1568,alpha=.65)
        # Navigational displays are physical wall-mounted objects, with local-sized labels.
        for g in records():
            i=g['id']-1; x=-205+(-16 if i%2==0 else 16); z=-136+(i//2)*11
            self.sign(l,f"{g['id']:02} / {g['name']}",(x,5,z),25,4)
            gate=self.p(l,f"TrialGate{g['id']}",(5,1,5),(x,1,z+3),(154,129,76),1088)
        for i in range(1,5):
            x=(i-2.5)*54
            booth=self.hall(l,f'Assembly Bay {i}',x,-112,42,32,18)
            self.p(booth,f'Queue{i}',(28,.4,20),(x,1.3,-112),(125,139,130),784)
            self.p(booth,'Console',(5,3,3),(x,2,-98),(63,74,75),1088)
            self.sign(booth,f'ASSEMBLY {i} / E TO JOIN',(x,11,-95),27,4)
        # Clock tower core, stepped accessible viewing decks, stair route and physical lift.
        tower=self.folder(l,'Meridian Tower')
        for y in (0,40,80,120,180,240):
            self.p(tower,'Tower deck',(76,3,56),(0,y,-30),(124,127,119))
            self.rail(tower,0,y+1.5,-3,76)
        for x in (-30,30):
            for z in (-52,-8): self.p(tower,'Tower pier',(8,250,8),(x,122,z),(93,103,101))
        for y in range(10,240,20):
            self.p(tower,'Tower crossbeam',(68,3,4),(0,y,-52),(82,93,92),1088)
        for j in range(480):
            angle=j*math.pi/64
            self.p(tower,'Helical stair',(10,.5,4),(math.cos(angle)*46,j*.5+.25,-30+math.sin(angle)*46),(134,138,129),rot=-angle)
        self.lift(tower,0,1,-30,239)
        self.p(tower,'Crown lantern',(24,18,24),(0,253,-30),(228,216,176),1568,alpha=.3)
        for x in (-150,150):
            for z in (-80,-30,30,85):
                self.p(l,'Light mast',(.7,15,.7),(x,8,z),(66,77,74),1088)
                lamp=self.p(l,'Lamp',(4,.6,4),(x,15.7,z),(246,224,175),288)
                self.item(lamp,'PointLight','Light',[('float','Range',30),('float','Brightness',1),('Color3','Color',(255,227,176))])
                self.p(l,'Waiting bench',(14,1.2,4),(x-10,2,z),(112,94,69),528)
        service=self.hall(l,'Service corridor',0,-166,280,20,12)
        for x in range(-120,121,40): self.p(service,'Power cabinet',(8,9,3),(x,5,-173),(82,96,94),1088)
        self.sign(l,'MUSEUM EXCHANGE →',(130,6,60),26,4)
        return l
    def museum(self,parent):
        m=self.folder(parent,'MuseumTemplate')
        ET.SubElement(m.find('Properties'),'token',{'name':'ModelStreamingMode'}).text='1'
        anchor=self.p(m,'MuseumAnchor',(1,1,1),(0,0,0),alpha=1)
        ET.SubElement(anchor.find('Properties'),'bool',{'name':'CanCollide'}).text='false'
        ET.SubElement(m.find('Properties'),'Ref',{'name':'PrimaryPart'}).text=anchor.attrib['referent']
        self.p(m,'Museum foundation',(360,8,320),(0,-5,0),(105,110,101))
        for px in (-160,0,160):
            for pz in (-140,140):self.p(m,'Foundation pile',(18,120,18),(px,-69,pz),(103,111,103))
        # Two annular floors around an open 200x160 court: 83,200 each, 166,400 internal total.
        for y in (0,32):
            for side in (-1,1):
                if y==0:self.p(m,'Gallery floor',(80,2,320),(side*140,y,0),(169,160,140),784)
                else:
                    # Real stairwell voids, not stairs colliding with an uncut upper slab.
                    self.p(m,'Outer gallery floor',(52,2,320),(side*154,y,0),(169,160,140),784)
                    self.p(m,'Inner gallery floor',(2,2,320),(side*101,y,0),(169,160,140),784)
                    self.p(m,'Stairwell end floor',(26,2,16),(side*115,y,-152),(169,160,140),784)
                    self.p(m,'Stairwell end floor',(26,2,198),(side*115,y,61),(169,160,140),784)
                    self.p(m,'Stair landing',(20,2,8),(side*114,y,-41.5),(169,160,140),784)
            for z in (-120,120): self.p(m,'Gallery floor',(200,2,80),(0,y,z),(169,160,140),784)
            for x in (-100,100): self.rail(m,x,y+1,0,160,'z')
            for z in (-80,80): self.rail(m,0,y+1,z,200)
        for x in range(-176,177,32):
            for z in (-156,156): self.p(m,'Load-bearing column',(4,64,4),(x,31,z),(137,138,124))
        for z in range(-124,125,32):
            for x in (-176,176):
                self.p(m,'Perimeter pier',(4,64,4),(x,31,z),(137,138,124))
                self.p(m,'Framed glazing',(1,50,26),(x,32,z+15),(178,204,204),1568,alpha=.65)
        for x in (-140,140): self.p(m,'Gallery roof',(86,3,326),(x,65,0),(84,95,88))
        for z in (-120,120): self.p(m,'Gallery roof',(200,3,86),(0,65,z),(84,95,88))
        # Entry passage, roofed service bays and internal stairs on both ends.
        self.sign(m,'MOUNTAINVERSE / PERSONAL ARCHIVE',(0,13,156),80,9)
        self.p(m,'MuseumExit',(12,1,12),(0,1,145),(151,132,85),1088)
        self.stairs(m,-114,1,-140,32,16); self.stairs(m,114,1,-140,32,16)
        self.lift(m,158,1,104,31)
        self.p(m,'Courtyard reflecting pool',(140,.3,100),(0,-.4,0),(76,113,126),1568,alpha=.3)
        self.p(m,'Courtyard bridge',(12,2,162),(0,0,0),(137,135,119))
        for floor in range(2):
            for n in range(25):
                side=-1 if n<13 else 1
                x=side*140; z=-124+(n if n<13 else n-13)*19
                i=floor*25+n+1
                stand=self.p(m,f'Stand{i}',(10,3,10),(x,floor*32+2.5,z),(98,106,102),784)
                self.sign(m,f'{i:02} / {records()[i-1]["name"]}',(x,floor*32+5,z-5),12,2.5)
                self.p(m,'Exhibit luminaire',(12,.3,1),(x,floor*32+15,z),(245,226,177),288)
        for x in (-165,165):
            self.p(m,'Service wall',(2,24,200),(x,13,0),(113,120,110))
            for z in (-70,0,70):
                self.p(m,'Ventilation register',(.5,4,6),(x-1,20,z),(74,84,81),1088)
                self.p(m,'Service cabinet',(5,9,6),(x+6,5,z),(84,94,88),1088)
        return m
    def mountain(self,parent,g):
        i=g['id']; angle=(i-1)*math.tau/50
        radius=3900+(i%3)*700; x=math.cos(angle)*radius; z=math.sin(angle)*radius
        m=self.folder(parent,f"Mountain{i:02}_{g['kind']}")
        # Tiered exposed geological mass. Footprints describe complexes, not every small arena.
        for tier in range(5):
            size=280-tier*38
            self.p(m,'Bedrock stratum',(size,35,size*.85),(x,-120+tier*24,z),(91+tier*7,99+tier*5,93+tier*5),800,rot=angle+tier*.11)
        w,d,h=g['width']+40,g['depth']+40,g['height']
        self.p(m,'Structural raft',(w,8,d),(x,-4,z),(110,115,105))
        self.sign(m,g['name'],(x,12,z+d/2+1),min(w-10,90),8)
        for xx in (-w/2,w/2):
            for zz in (-d/2,d/2): self.p(m,'Main support',(7,h+14,7),(x+xx,h/2,z+zz),(98,107,103))
        self.p(m,'Service gallery',(w+16,2,12),(x,h*.55,z-d/2),(132,135,119),1088)
        self.rail(m,x,h*.55+1,z-d/2-5,w+16)
        rise=min(h*.55,40)
        self.stairs(m,x-w/2-12,1,z-d/2-rise*3,rise,12)
        self.p(m,'Service approach',(24,3,rise*3+12),(x-w/2-12,-1,z-d/2-rise*1.5),(111,118,110))
        self.hall(m,'Technical room',x+w/2+16,z-d/2+20,24,36,16)
        # Infrastructure visibly changes with the mechanism; not color copies of one portal.
        kind=g['kind']
        if kind in ('tetris','lift','execution','press','crane','pillars','bulkhead'):
            for yy in (h*.35,h*.7,h): self.p(m,'Gantry beam',(w,5,7),(x,yy,z-d/2),(75,90,91),1088)
            for xx in (-w/2+10,w/2-10): self.p(m,'Machine rail',(2,h,3),(x+xx,h/2,z),(91,106,110),1088)
            self.p(m,'Control gallery',(w+12,3,20),(x,h,z-d/2),(108,121,115),1088)
            self.hall(m,'Curator tower',x,z-d/2-18,36,30,22)
        elif kind in ('snake','rotatingmaze','clock','rotor','wheel','gears','resonance','finale'):
            count=12+(i%5)*2
            for j in range(count):
                a=j*math.tau/count
                self.p(m,'Radial buttress',(6,h,10),(x+math.cos(a)*w/2,h/2,z+math.sin(a)*d/2),(103,116,109),rot=-a)
                self.p(m,'Bearing crown',(w/count+4,5,10),(x+math.cos(a)*w*.45,h,z+math.sin(a)*d*.45),(91,103,102),1088,rot=-a)
        elif kind in ('bridge','drawbridge','convoy'):
            for zz in (-d/2,d/2):
                for xx in (-20,20):
                    self.p(m,'Bridge tower',(7,h,9),(x+xx,h/2,z+zz),(114,122,115))
                    self.p(m,'Cable',(.5,h,.5),(x+xx,h/2,z+zz/2),(68,78,77),1088)
            for j in range(12): self.p(m,'Longitudinal girder',(7,4,d),(x-35+j*6,-4,z),(88,100,98),1088)
        elif kind=='duel':
            for xx,col in ((-38,(163,159,140)),(38,(84,94,95))):
                for yy in (0,24,48): self.p(m,'Keep floor',(28,3,44),(x+xx,yy,z),col)
                self.p(m,'Keep spine',(7,68,12),(x+xx,32,z-18),col)
            for yy in (0,24,48): self.p(m,'Combat bridge',(52,2,12),(x,yy,z),(118,120,106))
        else:
            for j in range(7):
                zz=-d/2+j*d/6
                self.p(m,'Roof rib',(w,3,3),(x,h,z+zz),(112,120,113),1088)
                for xx in (-w/2,w/2):
                    self.p(m,'Window frame',(2,h-8,d/6-3),(x+xx,h/2,z+zz),(154,179,184),1568,alpha=.72)
            if kind in ('volcano','furnace'):
                for xx in (-w/3,0,w/3): self.p(m,'Exhaust chimney',(12,h+30,12),(x+xx,(h+30)/2,z-d/2),(92,89,77),848)
            if kind=='frozen':
                for j in range(9): self.p(m,'Ice fin',(8,h+10+(j%3)*8,13),(x+(j-4)*13,h/2,z-d/2),(160,199,211),1536,alpha=.2)
        self.signature(m,g,x,z)
        gate=self.p(m,f'Entry{i}',(16,1,12),(x,1,z+d/2+14),(151,135,91),1088)
        self.p(m,f'Exit{i}',(10,1,10),(x+24,1,z+d/2+14),(111,139,135),1088)
        self.sign(m,'ENTRY / TRIAL / RETURN',(x,5,z+d/2+21),30,3)
        return m
    def signature(self,m,g,x,z):
        """Visible machinery / spatial typology specific to each named mountain."""
        k=g['kind']; h=g['height']; w=g['width']; d=g['depth']
        def p(name,px,y,pz,sx,sy,sz,col=(95,110,108),mat=1088,rot=0):
            return self.p(m,name,(sx,sy,sz),(x+px,y,z+pz),col,mat,rot)
        if k in ('maze','curatormaze'):
            # Perfect connected maze generated by deterministic depth-first search.
            import random
            r=random.Random(g['id']);seen={(0,0)};stack=[(0,0)];edges=set()
            while stack:
                a,b=stack[-1];choices=[(a+dx,b+dz) for dx,dz in ((1,0),(-1,0),(0,1),(0,-1)) if 0<=a+dx<9 and 0<=b+dz<9 and (a+dx,b+dz) not in seen]
                if not choices:stack.pop();continue
                v=r.choice(choices);edges.add(frozenset(((a,b),v)));seen.add(v);stack.append(v)
            for a in range(9):
                for b in range(9):
                    if a<8 and frozenset(((a,b),(a+1,b))) not in edges:p('Labyrinth partition',(a-3.5)*12,6,(b-4)*12,1,12,12,mat=816)
                    if b<8 and frozenset(((a,b),(a,b+1))) not in edges:p('Labyrinth partition',(a-4)*12,6,(b-3.5)*12,12,12,1,mat=816)
            if k=='curatormaze':p('Glass-backed switching bridge',0,22,0,100,2,14)
        elif k=='tetris':
            for a in range(10):p('Tetris shaft back ribs',(a-4.5)*6,50,-16,1,100,2)
            p('Traversing piece carriage',0,106,0,30,7,26);p('Suspended tetromino',0,88,0,6,6,23);p('Suspended tetromino',6,88,0,6,6,23);p('Suspended tetromino',-6,88,0,6,6,23);p('Suspended tetromino',0,94,0,6,6,23)
            self.lift(m,x+48,1,z,110)
        elif k=='chess':
            for a in range(8):
                for b in range(8):p('Chess square',(a-3.5)*10,.2,(b-3.5)*10,9.8,.4,9.8,(182,176,153) if (a+b)%2 else (63,77,79),784)
            for a in range(8):
                for b in (-35,-25,25,35):p('Chess garrison',(a-3.5)*10,5,b,4,10 if abs(b)==35 else 5,4,mat=784)
        elif k=='snake':
            for a in range(24):
                t=a*math.tau/24;p('Articulated serpent',math.cos(t)*38,6,math.sin(t)*38,7,7,7,rot=-t)
            for y in (12,28,44):
                for a in range(12):t=a*math.tau/12;p('Pit terrace',math.cos(t)*23,y,math.sin(t)*23,14,2,10,mat=816,rot=-t)
        elif k in ('bridge','drawbridge','convoy'):
            for a in range(12):p('Deck plate',0,1,(a-5.5)*10,26,2,9.5)
            if k=='convoy':
                for a in range(7):p('Freight wagon',0,5,(a-3)*18,23,8,13)
            if k=='drawbridge':
                for a in (-1,1):p('Bascule counterweight',0,12,a*54,22,18,10)
        elif k=='lift':self.lift(m,x,1,z,h-12)
        elif k=='rotatingmaze':
            for ring in range(1,4):
                for a in range(10):t=a*math.tau/12;p('Drum wall',math.cos(t)*ring*14,6,math.sin(t)*ring*14,9,12,2,rot=-t)
        elif k=='rhythm':
            for a in range(24):p('Organ resonator',(a-11.5)*3,8+(a%7)*2,-30,2,16+(a%7)*4,3)
            for a in range(8):p('Numbered acoustic pad',(a%4-1.5)*20,1,(a//4-.5)*24,16,2,16,(150,132,92),784)
        elif k=='frozen':
            for a in range(10):p('Frozen archive rack',(a%5-2)*16,7,(a//5-.5)*28,5,14,12,(167,211,220),1536)
        elif k=='volcano':
            for a in range(16):t=a*math.tau/16;p('Caldera rim',math.cos(t)*40,8,math.sin(t)*40,17,16,9,(86,89,82),800,rot=-t)
            for a in range(3):t=a*math.tau/3;p('Vent',math.cos(t)*24,3,math.sin(t)*24,12,6,12,(123,86,57),800)
        elif k=='domino':
            for a in range(18):p('Domino slab',(-1 if a%2 else 1)*14,13,(a-8.5)*5,10,26,2,(156,150,133),784)
        elif k=='memory':
            for a in range(6):
                for b in range(6):p('Memory projection coffer',(a-2.5)*12,h-3,(b-2.5)*12,10,1,10,(171,160,124),1088)
        elif k=='tower':
            for y in (22,44,66,88):p('Tower storey',0,y,0,66,2,66,mat=816)
            for a in range(44):p('Access stair',-26,a*2, -30+(a%22)*2.5,12,2,4,mat=816)
        elif k in ('rotor','gears','clock'):
            p('Bearing axis',0,10,0,9,20,9)
            for a in range(12):t=a*math.tau/12;p('Clock marker' if k=='clock' else 'Gear tooth',math.cos(t)*38,2,math.sin(t)*38,8,4,4,rot=-t)
            p('Minute / drive arm',0,3,0,78,2,3,rot=.3);p('Hour / secondary arm',0,5,0,44,2,3,rot=-.6)
        elif k=='pendulum':
            for a in range(5):p('Suspension rod',(a-2)*18,34,0,1,50,1);p('Pendulum bob',(a-2)*18,7,0,9,9,9)
        elif k=='balance':
            p('Balance beam',0,30,0,84,4,4)
            for side in (-1,1):p('Weighing pan',side*26,2,0,28,3,40);p('Pan suspension',side*26,17,0,1,28,1)
        elif k=='teamescape':
            for a in range(4):
                t=a*math.tau/4;p('Airlock frame',math.cos(t)*32,10,math.sin(t)*32,22,20,3,rot=-t);p('Relief valve',math.cos(t)*25,3,math.sin(t)*25,5,6,5)
        elif k in ('walls','corridors','bulkhead'):
            for a in range(4):p('Racked sliding wall',(a%2-.5)*40,8,(a-1.5)*20,30,16,3);p('Rack drive',0,1,(a-1.5)*20,92,1,1)
            if k=='bulkhead':p('Door drive housing',0,48,0,92,8,10)
        elif k=='pinball':
            for a in range(5):t=a*math.tau/5;p('Rebound bumper',math.cos(t)*28,4,math.sin(t)*28,8,8,8,(171,148,91))
            p('Launch spring housing',-35,4,-45,10,8,22)
        elif k=='rooms':
            for a in range(3):
                for b in range(3):p('Freight room module',(a-1)*31,5,(b-1)*31,28,10,2);p('Room rail',(a-1)*31,0,0,1,1,100)
        elif k=='gravity':
            for a in range(8):t=a*math.tau/8;p('Magnetic column',math.cos(t)*42,28,math.sin(t)*42,6,56,6)
            p('Upper magnetic grid',0,50,0,84,1,84)
        elif k in ('execution','press','machine'):
            for a in range(6):
                px=(a%3-1)*28;pz=(a//3-.5)*38;p('Press head',px,28,pz,20,6,24)
                for dx in (-12,12):p('Ram guide',px+dx,20,pz,2,40,2)
            if k=='machine':p('Exhaust trunk',0,30,-d/2,80,9,9)
        elif k=='wheel':
            for a in range(12):
                t=a*math.tau/12;p('Wheel gondola',math.cos(t)*40,44+math.sin(t)*40,0,16,2,12);p('Wheel shaft stay',math.cos(t)*20,44+math.sin(t)*20,-8,40,2,2,rot=t)
        elif k in ('flood','risingwater'):
            self.lift(m,x+34,1,z,h-10)
            for a in range(40):t=a*math.pi/4;p('Emergency spiral landing',math.cos(t)*24,a*1.8+2,math.sin(t)*24,20,1,20,mat=816)
        elif k=='furnace':
            p('Furnace mouth',0,9,-34,32,18,6,(120,86,62),848)
            for a in range(4):p('Heat baffle',(a-1.5)*22,5,0,12,10,4)
        elif k in ('platforms','collapse','shrink'):
            for a in range(6):
                for b in range(6):p('Independent load slab',(a-2.5)*14,1,(b-2.5)*14,13.5,2,13.5,mat=816)
            if k=='platforms':
                for a in range(6):p('Suspension cable',(a-2.5)*14,24,0,.3,46,.3)
        elif k=='debris':
            for a in range(14):p('Fractured vault remnant',(a%7-3)*14,h-5,(a//7-.5)*34,12,3,18,mat=816,rot=(a%3)*.1)
        elif k=='statues':
            for a in range(5):
                t=a*math.tau/5;px=math.cos(t)*30;pz=math.sin(t)*30;p('Witness plinth',px,2,pz,10,4,10,mat=784);p('Witness body',px,9,pz,5,12,4,mat=784);p('Witness head',px,17,pz,4,4,4,mat=784)
        elif k=='crane':
            p('Crane mast',-35,40,0,7,80,7);p('Slewing jib',0,80,0,110,5,6);p('Hoist cable',18,55,0,.4,45,.4);p('Suspended cargo',18,28,0,14,12,14)
        elif k=='blades':
            for a in range(5):
                px=(a-2)*18;p('Saw axle',px,5,0,2,10,2);p('Opposed blade',px,4,0,20,1,2,rot=a*.5);p('Opposed blade',px,4,0,2,1,20,rot=a*.5)
        elif k=='shift':
            for a in range(4):p('Transfer rail',0,0,(a-1.5)*22,92,1,1);p('Transfer carriage',(-1 if a%2 else 1)*24,2,(a-1.5)*22,24,2,18)
        elif k=='pillars':
            for a in range(5):
                for b in range(5):p('Hydraulic pillar',(a-2)*17,5+(a+b)%4*4,(b-2)*17,13,10+(a+b)%4*8,13)
        elif k=='resonance':
            for ring in range(1,4):
                for a in range(16):t=a*math.tau/16;p('Acoustic annular baffle',math.cos(t)*ring*14,ring*3,math.sin(t)*ring*14,6,2,2,rot=-t)
        elif k=='mirrors':
            for a in range(4):p('Reflector frame',(a%2-.5)*65,8,(a//2-.5)*50,2,16,12,rot=math.pi/4);p('Opaque beam baffle',(a-1.5)*20,5,0,7,10,4,mat=816)
        elif k=='oxygen':
            for a in range(4):t=a*math.tau/4;p('Air reservoir',math.cos(t)*32,8,math.sin(t)*32,10,16,10);p('Pressure trunk',0,14,(a-1.5)*15,90,2,2)
        elif k=='switches':
            for a in range(4):t=a*math.tau/4;p('Relay tower',math.cos(t)*32,14,math.sin(t)*32,9,28,9);p('Insulated conductor',0,2,(a-1.5)*12,90,1,1,(151,130,83))
        elif k=='finale':
            for a in range(3):p('Summit citadel tier',0,a*28,0,110-a*25,3,110-a*25,mat=816)
            self.stairs(m,x-44,1,z-50,56,12)

    def landscape(self,parent):
        land=self.folder(parent,'ValleyLandforms')
        for x in range(-6000,6001,1000):
            for z in range(-6000,6001,1000):self.p(land,'Valley bedrock',(1000,40,1000),(x,-145,z),(104,116,100),800)
        for tier in range(5):self.p(land,'Central escarpment',(1200-tier*150,40,1000-tier*125),(0,-125+tier*23,0),(107+tier*3,116+tier*3,104+tier*3),800)
    def horizon(self,parent,g):
        i=g['id']; a=(i-1)*math.tau/50;r=3900+(i%3)*700;x=math.cos(a)*r;z=math.sin(a)*r
        m=self.folder(parent,f'Horizon{i:02}')
        ET.SubElement(m.find('Properties'),'token',{'name':'ModelStreamingMode'}).text='2'
        for tier in range(3):self.p(m,'Distant bedrock',(270-tier*55,45,230-tier*45),(x,-110+tier*34,z),(104,116,106),800)
        for side in (-1,1):self.p(m,'Distant structural silhouette',(12,g['height'],12),(x+side*g['width']/2,g['height']/2,z),(101,115,110),816)
        self.p(m,'Distant roofline',(g['width']+15,5,g['depth']*.7),(x,g['height'],z),(100,114,108),1088)
        for p in m.findall("Item/Properties"):
            ET.SubElement(p,'bool',{'name':'CanCollide'}).text='false'
            p.find("float[@name='Transparency']").text='1'
        return m

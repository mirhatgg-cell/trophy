#!/usr/bin/env python3
"""Deterministic, dependency-free Roblox XML place builder. No Studio plug-ins or asset uploads required."""
from __future__ import annotations

import argparse
import collections
import json
import math
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "build"
PALETTE = {
    "ink": (30, 44, 45), "dark": (38, 44, 46), "mint": (112, 160, 143), "lightmint": (169, 200, 178),
    "cream": (226, 215, 185), "ivory": (236, 228, 205), "stone": (139, 135, 119), "concrete": (155, 157, 146),
    "wood": (112, 72, 45), "oak": (157, 112, 68), "brass": (171, 133, 69), "gold": (216, 173, 70),
    "silver": (170, 180, 177), "iron": (62, 69, 70), "copper": (170, 103, 67), "clay": (174, 108, 76),
    "paper": (225, 206, 163), "red": (151, 64, 55), "ruby": (167, 43, 68), "amber": (204, 138, 46),
    "green": (57, 112, 87), "blue": (63, 109, 143), "ice": (171, 217, 217), "glass": (175, 210, 198),
    "brick": (132, 92, 70), "road": (73, 79, 77), "grass": (118, 137, 100), "leaf": (75, 109, 78),
}
MATERIAL = {"Plastic": 256, "SmoothPlastic": 272, "Neon": 288, "Wood": 512, "WoodPlanks": 528,
            "Marble": 784, "Slate": 800, "Concrete": 816, "Granite": 832, "Brick": 848,
            "Cobblestone": 880, "Metal": 1088, "DiamondPlate": 1056, "Glass": 1568, "Fabric": 1312,
            "Grass": 1280, "Ground": 1360, "Asphalt": 1376}
IDENTITY = ((1., 0., 0.), (0., 1., 0.), (0., 0., 1.))
BASE_DIMENSIONS = ((56,22,14.5),(88,66,21),(108,84,39))


def mm(a, b):
    return tuple(tuple(sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)) for i in range(3))


def mv(a, v):
    return tuple(sum(a[i][k] * v[k] for k in range(3)) for i in range(3))


def add(a, b):
    return tuple(x + y for x, y in zip(a, b))


def rot(rx=0, ry=0, rz=0):
    x, y, z = map(math.radians, (rx, ry, rz))
    cx, sx, cy, sy, cz, sz = math.cos(x), math.sin(x), math.cos(y), math.sin(y), math.cos(z), math.sin(z)
    return mm(mm(((1, 0, 0), (0, cx, -sx), (0, sx, cx)), ((cy, 0, sy), (0, 1, 0), (-sy, 0, cy))), ((cz, -sz, 0), (sz, cz, 0), (0, 0, 1)))


def cross(a, b):
    return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])


def unit(v):
    n = math.sqrt(sum(x*x for x in v))
    return tuple(x/n for x in v)


class Node:
    sequence = 0

    def __init__(self, cls, name, parent=None, pos=(0, 0, 0), rotation=IDENTITY):
        Node.sequence += 1
        self.ref = f"RBX{Node.sequence:08d}"
        self.cls, self.name, self.parent = cls, name, parent
        self.children, self.props = [], {"Name": ("string", name)}
        if parent:
            parent.children.append(self)
            self.position = add(parent.position, mv(parent.rotation, pos))
            self.rotation = mm(parent.rotation, rotation)
        else:
            self.position, self.rotation = pos, rotation

    def set(self, name, typ, value):
        self.props[name] = (typ, value)
        return self

    def walk(self):
        yield self
        for child in self.children:
            yield from child.walk()


def group(parent, name, pos=(0, 0, 0), yaw=0):
    return Node("Model", name, parent, pos, rot(0, yaw, 0))


def part(parent, name, size, pos, color="cream", material="SmoothPlastic", rotation=(0, 0, 0),
         shape=1, collide=True, alpha=0, cls="Part"):
    p = Node(cls, name, parent, pos, rot(*rotation) if isinstance(rotation[0], (int, float)) else rotation)
    rgb = PALETTE.get(color, color)
    p.set("CFrame", "CoordinateFrame", (p.position, p.rotation))
    p.set("size", "Vector3", size).set("Color3uint8", "Color3uint8", (255 << 24) | (rgb[0] << 16) | (rgb[1] << 8) | rgb[2])
    p.set("Anchored", "bool", True).set("CanCollide", "bool", collide).set("CanTouch", "bool", False)
    p.set("CanQuery", "bool", collide).set("Transparency", "float", alpha).set("Material", "token", MATERIAL[material])
    p.set("TopSurface", "token", 0).set("BottomSurface", "token", 0).set("CastShadow", "bool", alpha < 0.8)
    if cls == "Part": p.set("shape", "token", shape)
    return p


def anchor(model):
    p = part(model, "Anchor", (0.2, 0.2, 0.2), (0, 0, 0), alpha=1, collide=False)
    model.set("PrimaryPart", "Ref", p)
    return p


def beam(parent, name, a, b, width, color="iron", material="Metal", collide=False):
    z = unit(tuple(b[i]-a[i] for i in range(3)))
    x = unit(cross((0, 1, 0) if abs(z[1]) < .98 else (0, 0, 1), z)); y = cross(z, x)
    rotation = tuple(tuple((x, y, z)[j][i] for j in range(3)) for i in range(3))
    return part(parent, name, (width, width, math.dist(a, b)), tuple((a[i]+b[i])/2 for i in range(3)), color, material, rotation=rotation, collide=collide)


def cylinder(parent, name, radius, height, pos, color="brass", material="Metal", collide=False, alpha=0):
    return part(parent, name, (height, radius*2, radius*2), pos, color, material, rotation=(0, 0, 90), shape=2, collide=collide, alpha=alpha)


def ball(parent, name, size, pos, color="cream", material="SmoothPlastic", alpha=0):
    return part(parent, name, size, pos, color, material, shape=0, collide=False, alpha=alpha)


def ring(parent, name, center, radius, thickness=.12, color="brass", segments=24, plane="xz", arc=360, start=0):
    for i in range(segments):
        t1, t2 = [math.radians(start + arc*j/segments) for j in (i, i+1)]
        def point(t):
            if plane == "xy": return (center[0]+math.cos(t)*radius, center[1]+math.sin(t)*radius, center[2])
            if plane == "yz": return (center[0], center[1]+math.cos(t)*radius, center[2]+math.sin(t)*radius)
            return (center[0]+math.cos(t)*radius, center[1], center[2]+math.sin(t)*radius)
        beam(parent, f"{name}_{i:02d}", point(t1), point(t2), thickness, color)


def sign(parent, label, pos, size, text_color="cream", background="ink", font=19, name="Sign", face=5, label_name="Inscription", text_size=30):
    plate = part(parent, name, size, pos, background, "Metal", collide=False)
    surface = Node("SurfaceGui", "Lettering", plate).set("Face", "token", face).set("CanvasSize", "Vector2", (max(200, size[0]*30), max(70, size[1]*30)))
    surface.set("LightInfluence", "float", 0.7).set("AlwaysOnTop", "bool", False).set("MaxDistance", "float", 140)
    rgb = PALETTE[text_color]
    Node("TextLabel", label_name, surface).set("Size", "UDim2", (1, 0, 1, 0)).set("BackgroundTransparency", "float", 1).set("Text", "string", label)
    textnode = surface.children[-1]
    textnode.set("TextColor3", "Color3", tuple(c/255 for c in rgb)).set("TextSize", "float", text_size).set("TextScaled", "bool", True)
    textnode.set("TextWrapped", "bool", True).set("Font", "token", font).set("BorderSizePixel", "int", 0)
    return plate


def prompt(parent, name, action, obj, distance=16):
    return Node("ProximityPrompt", name, parent).set("ActionText", "string", action).set("ObjectText", "string", obj).set("MaxActivationDistance", "float", distance).set("HoldDuration", "float", .15).set("RequiresLineOfSight", "bool", False).set("KeyboardKeyCode", "token", 101)


def lamp(parent, pos, height=17, street=False):
    x, y, z = pos
    if street:
        cylinder(parent, "LampBase", 1.2, .6, (x, y+.3, z), "iron", collide=True)
        cylinder(parent, "LampPost", .27, height, (x, y+height/2, z), "iron", collide=True)
        beam(parent, "Bracket", (x, y+height-2, z), (x+2.8, y+height, z), .25)
        p = part(parent, "LanternGlass", (2, 2.6, 2), (x+3, y+height-1.4, z), "ivory", "Glass", alpha=.23, collide=False)
        part(parent, "LanternCap", (2.7, .4, 2.7), (x+3, y+height+.1, z), "iron", "Metal", collide=False)
        for dx in (-.95, .95):
            for dz in (-.95, .95): part(parent, "LanternMullion", (.12, 2.8, .12), (x+3+dx, y+height-1.3, z+dz), "iron", "Metal", collide=False)
    else:
        cylinder(parent, "CeilingRose", .65, .2, (x, y+1.7, z), "iron")
        cylinder(parent, "LampStem", .07, 1.7, (x, y+.8, z), "iron")
        cylinder(parent, "LampShade", 1.3, .25, (x, y, z), "mint")
        p = cylinder(parent, "OpalDiffuser", .95, .22, (x, y-.2, z), "ivory", "Neon")
    Node("PointLight", "WarmLight", p).set("Color", "Color3", (1, .87, .65)).set("Brightness", "float", 1.5).set("Range", "float", 29 if street else 25).set("Shadows", "bool", False)


def rail(parent, a, b, height=3.6):
    length = math.dist(a, b); steps = max(1, int(length/5))
    for i in range(steps+1):
        p = tuple(a[j]+(b[j]-a[j])*i/steps for j in range(3))
        beam(parent, "GuardPost", p, (p[0], p[1]+height, p[2]), .2, "iron")
    beam(parent, "HandRail", (a[0], a[1]+height, a[2]), (b[0], b[1]+height, b[2]), .24, "brass")
    mid = tuple((a[j]+b[j])/2 for j in range(3))
    if abs(a[0]-b[0]) > abs(a[2]-b[2]): size = (length, height-.35, .2)
    else: size = (.2, height-.35, length)
    part(parent, "SafetyGlass", size, (mid[0], mid[1]+height/2, mid[2]), "glass", "Glass", alpha=.58, collide=True)


def cabinet(parent, pos, width=8, height=4, depth=3, drawers=3, yaw=0):
    parent = group(parent, "Cabinet", pos, yaw)
    x, y, z = (0, 0, 0)
    for dx in (-width/2+.3, width/2-.3): part(parent, "CabinetSide", (.6, height, depth), (x+dx, y+height/2, z), "wood", "WoodPlanks")
    part(parent, "CabinetBack", (width, height, .35), (x, y+height/2, z+depth/2), "wood", "Wood")
    part(parent, "CabinetTop", (width+.3, .35, depth+.3), (x, y+height, z), "oak", "Wood")
    for i in range(drawers):
        dy = (i+.5)*(height-.4)/drawers
        part(parent, "DrawerFront", (width-1.3, (height-.5)/drawers-.11, .25), (x, y+dy, z-depth/2-.05), "oak", "Wood")
        part(parent, "DrawerCupPull", (1.2, .18, .25), (x, y+dy+.1, z-depth/2-.3), "brass", "Metal", collide=False)
        part(parent, "LabelHolder", (.6, .2, .03), (x, y+dy-.2, z-depth/2-.21), "cream", collide=False)


def bench(parent, pos, width=11):
    x, y, z = pos
    for dz in (-1.1, -.35, .4, 1.15): part(parent, "SeatSlat", (width, .28, .55), (x, y+2.1, z+dz), "oak", "WoodPlanks")
    for dy in (3, 3.8, 4.6): part(parent, "BackSlat", (width, .5, .3), (x, y+dy, z+1.55), "oak", "WoodPlanks")
    for dx in (-width/2+1, width/2-1):
        beam(parent, "BenchLeg", (x+dx, y, z-1.1), (x+dx, y+2, z-1.1), .35)
        beam(parent, "BenchBackLeg", (x+dx, y, z+1.5), (x+dx, y+4.7, z+1.5), .35)
        beam(parent, "SeatBracket", (x+dx, y+1.8, z-1.5), (x+dx, y+1.8, z+1.8), .3)
    # Three independent usable seats, slightly below the slats so the authored bench stays visible.
    for i,dx in enumerate((-width*.3,0,width*.3)):
        seat=part(parent,"BenchSeat",(width*.27,.32,2.7),(x+dx,y+2.11,z),alpha=1,cls="Seat")
        seat.set("CanTouch","bool",True).set("Disabled","bool",False)


def desk(parent):
    m = group(parent, "AppraisalCounter")
    part(m, "SolidWalnutWorktop", (20, .65, 6.4), (0, 4.65, 4), "wood", "Wood")
    part(m, "BrassEdgeFront", (20.15, .13, .16), (0, 4.82, .77), "brass", "Metal", collide=False)
    for x in (-6.7, 6.7): cabinet(m, (x, 1, 4), 5.3, 3.3, 4.9, 3, yaw=180)
    part(m, "RecessedApron", (8, 1.2, .5), (0, 3.75, 1.4), "wood", "Wood")
    for x in (-8.9, 8.9):
        for z in (1.8, 6.1): part(m, "CounterFoot", (.45, .55, .45), (x, 1.3, z), "iron", "Metal")
    part(m, "FeltExaminationPad", (5.4, .06, 3.9), (0, 5.01, 4), "mint", "Fabric", collide=False)
    for x in (-2.8, 2.8): part(m, "PadBinding", (.08, .07, 4.05), (x, 5.04, 4), "brass", "Metal", collide=False)
    for z in (1.95, 6.05): part(m, "PadBinding", (5.6, .07, .08), (0, 5.04, z), "brass", "Metal", collide=False)
    for i in range(12): part(m, "CalibrationTick", (.035, .015, .13 if i % 3 else .25), (-2.5+i*.45, 5.055, 2.12), "cream", collide=False)
    for i in range(3): part(m, "LedgerLeaf", (2.1, .04, 2.6), (-4, 5.04+i*.045, 4.4), "paper", collide=False, rotation=(0, -8+i, 0))
    part(m, "LedgerSpine", (.25, .17, 2.7), (-5, 5.12, 4.4), "wood", "Wood", collide=False, rotation=(0, -8, 0))
    for i in range(8): part(m, "LedgerLine", (1.2, .01, .025), (-4, 5.18, 3.6+i*.19), "iron", collide=False)
    cylinder(m, "BellBase", .55, .15, (8, 5.1, 4), "iron")
    ball(m, "ServiceBell", (1, .6, 1), (8, 5.4, 4), "brass", "Metal")
    cylinder(m, "BellButton", .12, .25, (8, 5.8, 4), "brass")
    p = part(m, "Interaction", (.3, .3, .3), (0, 5.5, 7.5), alpha=1, collide=False)
    prompt(p, "AppraisalPrompt", "Независимая экспертиза", "Стол оценщика · работа в кресле", 17)
    # A framed receipt tray and split legs, not a single block standing in for a desk.
    part(m, "ReceiptTray", (2.2, .16, 2.6), (4.1, 5.02, 4.3), "brass", "Metal", collide=False)
    for dz in (-1.1, 1.1): part(m, "TrayLip", (2.2, .25, .12), (4.1, 5.18, 4.3+dz), "brass", "Metal", collide=False)


def equipment(parent, key, pos):
    m = group(parent, "Tool_"+key, pos)
    if key == "loupe":
        cylinder(m, "WeightedBase", .65, .18, (0, .1, 0), "iron")
        beam(m, "ArticulatedArm", (0, .2, 0), (.7, 1.7, .1), .12, "brass")
        beam(m, "ArmLink", (.7, 1.7, .1), (.1, 2.4, .1), .12, "brass")
        ring(m, "LensRim", (.1, 2.4, .1), .67, .1, "brass", plane="xy")
        part(m, "OpticalLens", (.1, 1.22, 1.22), (.1, 2.4, .1), "glass", "Glass", rotation=(0, 90, 0), shape=2, collide=False, alpha=.7)
    elif key == "scale":
        part(m, "ScaleBody", (3.4, .45, 2.8), (0, .25, 0), "mint", "Metal", collide=False)
        cylinder(m, "ScalePlatform", 1.15, .14, (0, .6, 0), "silver")
        sign(m, "0.00 g", (0, .28, -1.42), (1.7, .32, .05), "mint", "ink", text_size=18)
        for x in (-1.3, 1.3): cylinder(m, "LevelFoot", .15, .14, (x, -.02, .9), "iron")
    elif key == "uv":
        part(m, "ShieldBase", (5.4, .35, 3.8), (0, .18, 0), "mint", "Metal", collide=False)
        for x in (-2.5, 2.5): part(m, "Upright", (.35, 2.7, 3.6), (x, 1.6, 0), "mint", "Metal", collide=False)
        part(m, "LampHood", (5.4, .5, 3.8), (0, 3.1, 0), "mint", "Metal", collide=False)
        part(m, "UvTube", (3.7, .2, .3), (0, 2.78, 0), (148, 144, 212), "Neon", collide=False)
        part(m, "TestingMat", (4.3, .08, 3), (0, .43, 0), "iron", "Fabric", collide=False)
    elif key == "spectro":
        part(m, "InstrumentBody", (5.5, 2.8, 4.7), (0, 1.4, 0), "ivory", "Metal", collide=False)
        part(m, "OpticalBay", (2.3, 1.4, 2.4), (-.8, 2.9, .3), "iron", "Metal", collide=False)
        cylinder(m, "SampleCup", .55, .2, (-.8, 3.7, .3), "silver")
        sign(m, "λ / 420–780", (1.3, 1.7, -2.39), (2, .9, .04), "mint", "ink")
        for i in range(4): part(m, "CoolingSlot", (.75, .08, .05), (-1.55, .6+i*.25, -2.39), "iron", "Metal", collide=False)
        for x in (-2, 2): cylinder(m, "IsolationFoot", .28, .35, (x, -.16, 1.4), "iron")
    else:
        part(m, "DiagnosticBase", (6.5, .4, 4.8), (0, .2, 0), "iron", "Metal", collide=False)
        for x in (-2.5, 2.5): cylinder(m, "InstrumentPost", .14, 3.4, (x, 1.9, 1.5), "silver")
        part(m, "ProbeBridge", (5.5, .3, .5), (0, 3.5, 1.5), "silver", "Metal", collide=False)
        cylinder(m, "Probe", .23, 1.2, (0, 2.9, 1.5), "brass")
        part(m, "RubberVise", (2.8, .6, 1.8), (0, .7, 0), "mint", "Metal", collide=False)
        sign(m, "SIGNAL / OK", (0, .65, -2.46), (2.7, .7, .06), "mint", "ink")
    return m


def bookshelf(parent, pos, width=14, height=12):
    m = group(parent, "ArchiveShelf", pos)
    for x in (-width/2, width/2): part(m, "ShelfUpright", (.45, height, 3), (x, height/2, 0), "wood", "Wood")
    for y in [v for v in (.4,3.4,6.4,9.4) if v<height]+[height]: part(m, "ArchiveShelfBoard", (width, .35, 3), (0, y, 0), "wood", "WoodPlanks")
    for row in range(int(height/3)):
        for i in range(int(width/1.05)-1):
            color = ("mint", "wood", "paper", "iron", "red")[(i+row*3) % 5]
            h = min(1.8+((i*3+row) % 4)*.16,height-(.65+row*3)-.2)
            x = -width/2+1+i*1.04
            part(m, "ArchiveVolume", (.72, h, 2), (x, .65+row*3+h/2, -.3), color, "Fabric", collide=False)
            part(m, "SpineLabel", (.48, .4, .025), (x, 1.65+row*3, -1.32), "paper", collide=False)


def display_case(parent, pos, width=10, collection_offset=None):
    m = group(parent, "DisplayCase", pos)
    part(m, "CaseBase", (width, .55, 4.4), (0, 3.1, 0), "wood", "Wood")
    for x in (-width/2+.4, width/2-.4):
        for z in (-1.6, 1.6): part(m, "CaseLeg", (.4, 3, .4), (x, 1.5, z), "wood", "Wood")
    part(m, "FeltLining", (width-.5, .08, 3.8), (0, 3.43, 0), "mint", "Fabric", collide=False)
    for z in (-2.1, 2.1): part(m, "SafetyGlass", (width, 2.3, .14), (0, 4.6, z), "glass", "Glass", alpha=.73)
    for x in (-width/2, width/2): part(m, "SafetyGlass", (.14, 2.3, 4.2), (x, 4.6, 0), "glass", "Glass", alpha=.73)
    part(m, "CaseGlassTop", (width+.1, .16, 4.4), (0, 5.85, 0), "glass", "Glass", alpha=.7)
    for x in (-width/2, width/2):
        for z in (-2.1, 2.1): part(m, "CaseStile", (.14, 2.5, .14), (x, 4.65, z), "brass", "Metal", collide=False)
    # Blank plinths are deliberate exhibit positions for the player's growing collection.
    for index,x in enumerate((-width*.28, 0, width*.28)):
        cylinder(m,"ExhibitPlinth",.85,.17,(x,3.6,0),"ivory","Marble")
        if collection_offset is not None:
            part(m,f"CollectionSlot_{collection_offset+index+1:02d}",(.1,.1,.1),(x,3.71,0),alpha=1,collide=False)


def collection_case(parent,pos,width=11,offset=0,count=20):
    m=group(parent,"CollectionCabinet",pos)
    part(m,"CabinetPlinth",(width,1.5,4.4),(0,.75,0),"wood","Wood")
    for x in (-width/2,width/2):
        for z in (-2.1,2.1):part(m,"CabinetStile",(.18,11,.18),(x,6.9,z),"brass","Metal",collide=False)
        part(m,"SideSafetyGlass",(.13,10.1,4.2),(x,7.3,0),"glass","Glass",alpha=.76)
    part(m,"CabinetBack",(width,10.8,.18),(0,7,2.1),"wood","Wood")
    part(m,"CabinetCrown",(width+.4,.35,4.6),(0,12.4,0),"wood","Wood")
    # An open-front display cabinet provides physical access; side safety glazing and raised lips retain objects.
    for row in range(5):
        y=1.6+row*2.1
        part(m,"DisplayShelf",(width,.18,4.1),(0,y,0),"wood","Wood")
        part(m,"ShelfLip",(width,.18,.09),(0,y+.14,-2),"brass","Metal",collide=False)
        for col in range(4):
            x=-width/2+1.3+col*(width-2.6)/3
            order=(1,2,0,3,4).index(row)*4+col
            if order<count:
                cylinder(m,"CollectionPlinth",.78,.1,(x,y+.14,0),"ivory","Marble")
                part(m,f"CollectionSlot_{offset+order+1:02d}",(.1,.1,.1),(x,y+.22,0),alpha=1,collide=False)


def window_panel(parent, x, y, z, width, height, side=False):
    m = group(parent, "FramedWindow", (x, y, z), 90 if side else 0)
    part(m, "LaminatedGlass", (width, height, .3), (0, 0, 0), "glass", "Glass", alpha=.7, collide=True)
    for dx in (-width/2-.1, 0, width/2+.1): part(m, "Mullion", (.22, height+.4, .42), (dx, 0, 0), "ink", "Metal", collide=False)
    for dy in (-height/2-.1, height/2+.1): part(m, "WindowLintel", (width+.4, .22, .45), (0, dy, 0), "ink", "Metal", collide=False)
    part(m, "StoneSill", (width+.9, .36, .9), (0, -height/2-.35, .04), "concrete", "Concrete", collide=False)


def container_building(parent):
    """Two joined high-cube modules: recognizable ISO proportions, cargo hardware and operator-side furniture."""
    b=group(parent,"Level1" if parent.name=="Buildings" else "Building");anchor(b)
    s=group(b,"Structure");w,d,h=BASE_DIMENSIONS[0]
    part(s,"ContinuousFoundation",(60,1.1,27),(0,.15,0),"concrete","Concrete")
    part(s,"GroundFloor",(56,.5,22),(0,.75,0),"oak","WoodPlanks")
    part(s,"ThresholdStep",(12,.45,2),(0,.225,-14),"concrete","Concrete")
    part(s,"ThresholdLanding",(12,.85,2.1),(0,.425,-12),"concrete","Concrete")
    for x in (-27.65,27.65):part(s,"EndWall",(.7,13,22),(x,7.5,0),"mint","Metal")
    part(s,"BackWall",(56,13,.7),(0,7.5,10.65),"mint","Metal")
    for side in (-1,1):
        part(s,"FrontOuterPost",(4,13,.7),(side*26,7.5,-10.65),"mint","Metal")
        part(s,"FrontInnerPost",(1.8,13,.7),(side*5.1,7.5,-10.65),"mint","Metal")
        part(s,"WindowApron",(18,3,.7),(side*15,2.5,-10.65),"mint","Metal")
        window_panel(s,side*15,7.6,-10.58,18,7.2)
    part(s,"WeldedEntranceHeader",(56,3.4,.8),(0,12.3,-10.65),"mint","Metal")
    part(s,"RoofSlab",(56.8,.6,22.6),(0,14.2,0),"mint","Metal")
    for z in (-11,0,11):
        part(s,"LongitudinalFrame",(56.8,.5,.55),(0,13.85,z),"iron","Metal")
        part(s,"BottomFrame",(56.8,.7,.65),(0,.8,z),"iron","Metal")
    for x in (-27.5,27.5):
        for z in (-10.6,0,10.6):
            part(s,"CornerPost",(.65,13.6,.65),(x,7.2,z),"iron","Metal")
            for y in (1,13.8):
                part(s,"ISOCornerCasting",(1.1,.8,1.1),(x,y,z),"stone","Metal")
                part(s,"TwistlockSocket",(.55,.22,.04),(x,y,z-.57),"iron","Metal",collide=False)
    for x in range(-26,27,2):
        part(s,"RoofCorrugation",(.22,.16,21.5),(x,14.56,0),"mint","Metal",collide=False)
        part(s,"BackCorrugation",(.4,11.2,.18),(x,7.3,11.04),"mint","Metal",collide=False)
    for z in range(-10,11,2):
        part(s,"EndCorrugation",(.16,11.4,.4),(-28.06,7.2,z),"mint","Metal",collide=False)
    cargo=group(b,"CargoDoors")
    for z in (-8.25,-2.75,2.75,8.25):
        part(cargo,"OriginalCargoDoor",(.14,11.5,5.3),(28.08,7.1,z),"mint","Metal",collide=False)
        for dz in (-1.4,1.4):
            beam(cargo,"LockingRod",(28.46,2.3,z+dz),(28.46,12,z+dz),.12,"silver")
            for y in (3,7,11):part(cargo,"LockRodBracket",(.32,.28,.4),(28.43,y,z+dz),"iron","Metal",collide=False)
            beam(cargo,"LockingHandle",(28.5,6,z+dz),(28.5,6,z+dz+.85),.12,"silver")
        for y in (3.1,7,11.1):part(cargo,"CargoHinge",(.35,.4,.8),(28.3,y,z+2.3),"iron","Metal",collide=False)
    sign(b,"PROBA 040\nHIGH CUBE\nMAX GROSS 30 480 kg",(-23,6,11.08),(7,3,.05),"cream","mint",face=2)
    door=group(b,"DoorAssembly")
    part(door,"Rail",(24,.55,.75),(0,11.6,-11.65),"iron","Metal",collide=False)
    for x in (-10,0,10):part(door,"RailBracket",(.5,.6,1.3),(x,11.7,-11),"iron","Metal",collide=False)
    for side,label in ((-1,"Left"),(1,"Right")):
        part(door,label,(4.15,10,.3),(side*2.1,6,-11.3),"glass","Glass",alpha=.58)
    part(door,"Sensor",(.4,.4,.4),(0,5,-12),alpha=1,collide=False)
    for x in (-4.4,4.4):part(b,"CutoutSteelJamb",(.4,10.5,.7),(x,6.2,-11.1),"brass","Metal")
    part(b,"SmallEntranceHood",(16,.25,3.5),(0,12,-12.6),"mint","Metal")
    for x in (-7,7):beam(b,"HoodBracket",(x,10.6,-11),(x,11.85,-14),.18,"iron")
    sign(b,"P R O B A",(0,13,-14.4),(15,1.7,.16),"cream","ink")
    sign(b,"БЮРО / 00",(-22,9,-11.1),(6,1.4,.08),"brass","ink",label_name="PlotNumber")
    sign(b,"СВОБОДНОЕ БЮРО",(0,11.65,-14.55),(15,.8,.06),"cream","ink",label_name="OwnerName")
    desk(b)
    equipment(b,"loupe",(-6.5,5,4));equipment(b,"scale",(6,5,4))
    for x,key,yaw in ((-21,"uv",-90),(21,"diagnostic",90)):
        cabinet(b,(x,1,5),9,4,6.8,3,yaw=yaw);equipment(b,key,(x,5.4,5))
    cabinet(b,(-11.5,1,8.8),10,4,3,3);equipment(b,"spectro",(-11.5,5.4,8.8))
    bookshelf(b,(12,1,9.2),11,7.5)
    chair=group(b,"AppraiserChair",(0,1,8.2))
    seat=part(chair,"AppraiserSeat",(3.8,.55,3.5),(0,2.6,0),"mint","Fabric",cls="Seat")
    seat.set("CanTouch","bool",True).set("Disabled","bool",False)
    for x in (-1.45,1.45):
        for z in (-1.3,1.3):beam(chair,"ChairLeg",(x,0,z),(x,2.4,z),.22,"wood","Wood",True)
        beam(chair,"BackStile",(x,2.4,1.5),(x,5.3,1.5),.22,"wood","Wood",True)
    part(chair,"BackPad",(3.3,2.1,.45),(0,4.3,1.5),"mint","Fabric")
    collection_case(b,(-21,1,-5),11,0);collection_case(b,(21,1,-5),11,20)
    for x,z in ((-8,-5),(-14,-5),(8,-5),(14,-5)):cylinder(b,"QueueInlay",.65,.025,(x,1.025,z),"brass")
    for x in (-17,0,17):lamp(b,(x,12.2,0))
    for x in (-26.5,26.5):part(b,"ElectricalConduit",(.16,.18,18),(x,12.7,0),"iron","Metal",collide=False)
    part(b,"FuseBox",(2,2.7,.6),(-25.5,5,10),"iron","Metal")
    part(b,"VentilationUnit",(5,3,2.5),(22,3,12.5),"ivory","Metal")
    for i in range(7):part(b,"VentFin",(4.3,.12,.08),(22,2.1+i*.3,13.8),"iron","Metal",collide=False)
    registry=sign(b,"МАСТЕРСКАЯ",(23,10,10.1),(7,1.6,.12),"cream","ink")
    prompt(registry,"RegistryPrompt","Развитие бюро","Оборудование и декор",15)
    decor_sockets(b,w,d,h)
    return b


def building(parent, level):
    if level==1:return container_building(parent)
    b = group(parent, "Level"+str(level) if parent.name == "Buildings" else "Building")
    anchor(b)
    width, depth, height = BASE_DIMENSIONS[level-1]
    shell = group(b, "Structure")
    part(shell, "ContinuousFoundation", (width+8, 1.4, depth+8), (0, -.05, 0), "concrete", "Concrete")
    part(shell, "GroundFloor", (width, .5, depth), (0, .75, 0), "cream", "Concrete")
    # Two shallow entrance steps; no tall collision lip or an uncovered floor seam.
    part(shell, "ThresholdStep", (20, .45, 2.4), (0, .225, -depth/2-2.5), "concrete", "Concrete")
    part(shell, "ThresholdLanding", (20, .85, 2.3), (0, .425, -depth/2-.2), "concrete", "Concrete")
    mat, color = ("Metal", "mint") if level == 1 else ("Brick", "brick") if level == 2 else ("Concrete", "cream")
    wall_h = height-1
    for x in (-width/2+.7, width/2-.7): part(shell, "LoadBearingSide", (1.4, wall_h, depth), (x, 1+wall_h/2, 0), color, mat)
    part(shell, "BackWall", (width, wall_h, 1.4), (0, 1+wall_h/2, depth/2-.7), color, mat)
    front = -depth/2
    # Deliberate window and door voids are bounded by full-width lintels, sills and jambs.
    win_w = (width/2-14)
    for side in (-1, 1):
        cx = side*(7+(width/2-7)/2)
        for xx, ww in ((side*9.5, 5), (side*(width/2-2.5), 5)):
            part(shell, "FacadePier", (ww, 17, 1.4), (xx, 9.5, front+.7), color, mat)
        part(shell, "WindowApron", (width/2-7, 3.5, 1.4), (cx, 2.75, front+.7), color, mat)
        part(shell, "WindowHeader", (width/2-7, 5, 1.4), (cx, 15.5, front+.7), color, mat)
        window_panel(shell, cx, 8.75, front+.63, width/2-17, 8.5)
    part(shell, "EntranceLintel", (14, 4, 1.5), (0, 16, front+.7), color, mat)
    if level == 2:
        part(shell, "UpperFacadeBand", (width, 3, 1.6), (0, 19.5, front+.6), "cream", "Concrete")
    if level == 3:
        part(shell, "UpperFloorBand", (width, 3.2, 2), (0, 19.6, front+.7), "concrete", "Concrete")
        for x in range(-45, 46, 18):
            part(shell, "UpperFacadePier", (2.5, 17.4, 1.5), (x, 29.6, front+.7), "cream", "Concrete")
        part(shell, "UpperWindowApron", (width, 3, 1.5), (0, 22.5, front+.7), "cream", "Concrete")
        part(shell, "UpperWindowHeader", (width, 4.5, 1.5), (0, 36.75, front+.7), "cream", "Concrete")
        for x in (-36,-18,0,18,36): window_panel(shell,x,29.3,front+.65,15.5,10.6)
        for x in (-50.125,50.125): part(shell,"UpperCornerPier",(7.75,18,1.6),(x,29,front+.7),"cream","Concrete")
    # The roof, perimeter steel and drainage are continuous and physically supported.
    part(shell, "RoofSlab", (width+3, 1, depth+3), (0, height+.5, 0), "ink", "Metal")
    for x in (-width/2, width/2): part(shell, "RoofEdgeBeam", (1, .8, depth+4), (x, height+1.2, 0), "iron", "Metal")
    for z in (-depth/2, depth/2): part(shell, "RoofEdgeBeam", (width+3, .8, 1), (0, height+1.2, z), "iron", "Metal")
    for x in (-width/2+1.4, width/2-1.4):
        for z in (-depth/2+1.4, depth/2-1.4):
            part(shell, "CornerColumn", (1.2, height, 1.2), (x, height/2+1, z), "ink", "Metal")
            part(shell, "ColumnBasePlate", (2.1, .25, 2.1), (x, 1.15, z), "iron", "Metal")
            for dx in (-.7,.7):
                for dz in (-.7,.7): cylinder(shell,"AnchorBolt",.095,.12,(x+dx,1.34,z+dz),"silver")
    if level == 1:
        for z in range(-20,22,2):
            for x in (-width/2-.08,width/2+.08): part(shell,"ContainerCorrugation",(.22,15.8,.48),(x,9,z),"mint","Metal",collide=False)
        for x in range(-30,32,2):
            part(shell,"RoofRib",(.24,.15,depth+.8),(x,height+1.08,0),"iron","Metal",collide=False)
            part(shell,"BackCorrugation",(.45,15.8,.2),(x,9,depth/2+.05),"mint","Metal",collide=False)
        for x in (-31,31): sign(shell,"MAX GROSS\n30 480 kg",(x,4.2,-depth/2-.06),(2,2,.05),"cream","mint",text_size=14)
    else:
        for y in (1.8, 14, height-1):
            for x in (-width/2-.1,width/2+.1): part(shell,"StoneStringCourse",(.4,.4,depth),(x,y,0),"concrete","Concrete",collide=False)
        for x in range(-int(width/2)+8,int(width/2),12):
            part(shell,"RoofServiceRib",(.25,.25,depth),(x,height+1.05,0),"iron","Metal",collide=False)
    # A visible sliding drive track, hanger brackets and two frameless safety-glass leaves.
    d=group(b,"DoorAssembly")
    part(d,"Rail",(29,.65,.8),(0,14.65,front-.6),"iron","Metal",collide=False)
    for x in (-12,0,12): part(d,"RailBracket",(.7,.6,1.5),(x,14.7,front+.1),"iron","Metal",collide=False)
    for side,name in ((-1,"Left"),(1,"Right")):
        leaf=part(d,name,(6.9,12.6,.35),(side*3.5,7.3,front-.3),"glass","Glass",alpha=.58)
        surface=Node("SurfaceGui","EtchedSafetyBand",leaf).set("Face","token",5).set("CanvasSize","Vector2",(200,350)).set("LightInfluence","float",1)
        Node("Frame","PrivacyBand",surface).set("Size","UDim2",(1,0,.035,0)).set("Position","UDim2",(0,0,.52,0)).set("BackgroundColor3","Color3",(.82,.79,.62)).set("BorderSizePixel","int",0)
    part(d,"Sensor",(.5,.5,.5),(0,5,front-1),alpha=1,collide=False)
    for x in (-7.25,7.25): part(shell,"EntranceJamb",(.5,13.4,.7),(x,7.5,front-.15),"brass","Metal")
    # Sign canopy is attached to columns with diagonal steel struts.
    canopy_y=15.7
    part(b,"EntranceCanopy",(34,.55,7),(0,canopy_y,front-3),"mint","Metal")
    for x in (-15,15): beam(b,"CanopyBrace",(x,12.5,front+.1),(x,canopy_y-.3,front-5.3),.28)
    sign(b,"P R O B A",(0,17.7,front-6.5),(27,3.4,.35),"cream","ink",font=19)
    sign(b,"БЮРО / 00",(-width/2+8,6.5,front-.15),(9,2,.2),"brass","ink",label_name="PlotNumber")
    sign(b,"СВОБОДНОЕ БЮРО",(0,14.4,front-6.73),(25,1,.08),"cream","ink",label_name="OwnerName")
    # Electrical trunking goes to the workbench and the overhead fixtures.
    for x in (-width/2+2.1,width/2-2.1):
        part(b,"CableTray",(.35,.3,depth-4),(x,15,0),"iron","Metal",collide=False)
        part(b,"Downpipe",(.3,height,.3),(x,height/2+.5,depth/2+1),"iron","Metal",collide=False)
    part(b,"DistributionBox",(3,4,.9),(-width/2+2.4,5,depth/2-2),"iron","Metal")
    for i in range(3): part(b,"BreakerHandle",(.5,.4,.2),(-width/2+1.5+i*.85,5,depth/2-2.55),"silver","Metal",collide=False)
    # Air conditioning, grille, concrete feet and condensate pipe on the back service strip.
    part(b,"VentilationUnit",(7,4,3),(width/2-9,3.2,depth/2+2.2),"ivory","Metal")
    for i in range(9): part(b,"VentFin",(5.8,.14,.12),(width/2-9,1.8+i*.35,depth/2+3.8),"iron","Metal",collide=False)
    for x in (width/2-11,width/2-7): part(b,"UnitFoot",(.5,.8,2.7),(x,1.3,depth/2+2.2),"concrete","Concrete")
    beam(b,"ServiceConduit",(width/2-5,3,depth/2+2),(width/2-5,12,depth/2+2),.15,"silver")
    # Common customer path x=0 is deliberately kept unobstructed from entrance to counter.
    desk(b)
    equipment(b,"loupe",(-6.5,5,4))
    equipment(b,"scale",(6,5,4))
    cabinet(b,(-width/2+7,1,10),10,4,7,3,yaw=-90)
    equipment(b,"uv",(-width/2+7,5.4,10))
    cabinet(b,(width/2-7,1,10),10,4,7,3,yaw=90)
    equipment(b,"diagnostic",(width/2-7,5.4,10))
    cabinet(b,(-12,1,depth/2-4),12,4,5,4)
    equipment(b,"spectro",(-12,5.4,depth/2-4))
    bookshelf(b,(width/2-11,1,depth/2-3.5),15,12)
    # A formed chair with cross-braced legs and a padded back.
    chair=group(b,"AppraiserChair",(0,1,11),0)
    seat=part(chair,"AppraiserSeat",(4,.6,4),(0,2.6,0),"mint","Fabric",cls="Seat")
    seat.set("CanTouch","bool",True).set("Disabled","bool",False)
    for x in (-1.5,1.5):
        for z in (-1.5,1.5): beam(chair,"ChairLeg",(x,0,z),(x,2.4,z),.25,"wood","Wood",True)
        beam(chair,"BackStile",(x,2.5,1.65),(x,6,1.65),.28,"wood","Wood",True)
    part(chair,"BackPad",(3.5,2.6,.5),(0,4.8,1.65),"mint","Fabric")
    beam(chair,"ChairBrace",(-1.5,1,-1.5),(1.5,1,1.5),.2,"wood","Wood")
    display_case(b,(-21,1,-20),14,0)
    display_case(b,(21,1,-20),14,3)
    collection_case(b,(-width/2+9,1,-10),11,6,17)
    collection_case(b,(28 if level==3 else width/2-9,1,-29 if level==3 else -10),15 if level==3 else 11,23,17)
    sign(b,"ПРАВИЛА БЮРО\nОсмотр • Заключение • Выкуп",(-width/2+9,11,-depth/2+1.6),(11,4,.15),"cream","ink")
    registry=sign(b,"РАЗВИТИЕ\nБюро и оборудование",(width/2-8,11,-depth/2+1.6),(10,4,.15),"cream","ink")
    prompt(registry,"RegistryPrompt","Развитие бюро","Каталог мастерской",18)
    for x in (-19,0,19): lamp(b,(x,14.8 if level==1 else 16.8,-5))
    # The second stage adds an actual accessible rear laboratory, not a cosmetic shell.
    if level>=2:
        for side in (-1,1): part(b,"LabPartition",(width/2-7,12,.7),(side*(7+(width/2-7)/2),7,19),"cream","Concrete")
        for x in (-7,7): part(b,"LabDoorJamb",(.6,12,1),(x,7,19),"ink","Metal")
        part(b,"LabLintel",(14,1.1,1),(0,13,19),"ink","Metal")
        sign(b,"ЛАБОРАТОРИЯ / АРХИВ",(0,14.5,18.5),(17,1.8,.1),"brass","ink")
        lamp(b,(0,16.8,depth/2-7))
        cabinet(b,(14,1,depth/2-4),9,4,4,5)
        for i in range(6): part(b,"ReferenceBox",(2.4,1.9,2.1),(10.5+i*1.3,6.1,depth/2-4),"paper","Fabric",collide=False)
    if level==3:
        upper=group(b,"UpperGallery")
        # Guarded atrium plus a separate stairwell: all occupied slabs join to the landing.
        part(upper,"FrontGallerySlab",(108,1,17),(0,20.1,-32.5),"cream","Concrete")
        part(upper,"BackGallerySlab",(108,1,18),(0,20.1,32),"cream","Concrete")
        part(upper,"LeftGallerySlab",(38,1,47),(-35,20.1,-.5),"cream","Concrete")
        part(upper,"FrontAtriumCrosswalkSlab",(32,1,12),(0,20.1,-18),"cream","Concrete")
        part(upper,"RightInnerGallerySlab",(20,1,47),(26,20.1,-.5),"cream","Concrete")
        part(upper,"RightOuterGallerySlab",(6.5,1,47),(50.75,20.1,-.5),"cream","Concrete")
        for x in (-16,16): rail(upper,(x,20.6,-12),(x,20.6,23))
        rail(upper,(-16,20.6,-12),(16,20.6,-12));rail(upper,(-16,20.6,23),(16,20.6,23))
        for z in (-10,20): part(upper,"AtriumSupportBeam",(35,1,1),(0,19,z),"iron","Metal")
        stairs=group(b,"GalleryStair")
        # 36 risers of 0.5444 Studs and generous 1.2 Stud treads. The top meets y=20.6 exactly.
        for i in range(36):
            top=1+(i+1)*19.6/36
            part(stairs,"StairTread",(9,.3,1.23),(42,top-.15,-19.4+i*1.2),"wood","WoodPlanks")
            part(stairs,"StairRiser",(9,19.6/36,.16),(42,top-19.6/72,-20+i*1.2),"cream","Concrete")
        for x in (37.6,46.4):
            beam(stairs,"SteelStringer",(x,.6,-20),(x,20.1,23.4),.7,"iron","Metal")
            beam(stairs,"StairHandrail",(x,4.4,-20),(x,24,23.4),.22,"brass","Metal",True)
            for i in range(13): beam(stairs,"StairBaluster",(x,1+i*19.6/12,-20+i*43.4/12),(x,4.4+i*19.6/12,-20+i*43.4/12),.16)
            for z,y in ((-5,7.3),(10,14.1)):beam(stairs,"StairSupport",(x,1,z),(x,y,z),.45,"iron","Metal")
        rail(upper,(36,20.6,-24),(36,20.6,23))
        rail(upper,(47.5,20.6,-24),(47.5,20.6,23))
        rail(upper,(36,20.6,-24),(47.5,20.6,-24))
        bookshelf(upper,(-39,20.6,35),19,12)
        bookshelf(upper,(20,20.6,36),15,12)
        display_case(upper,(-34,20.6,-25),17)
        display_case(upper,(8,20.6,-29),16)
        for x in (-34,0,34): lamp(upper,(x,35.3,-23))
        lamp(upper,(-32,35.3,18));lamp(upper,(22,35.3,32))
        sign(upper,"АРХИВ ЗАКЛЮЧЕНИЙ",(0,29,depth/2-1.6),(25,3,.2),"brass","ink")
        bench(upper,(-32,20.6,12),12)
    # Outside bench, numbered queue pads and a clear owner arrival spot.
    bench(b,(23,0,-depth/2-9),13)
    for x,z in ((-8,-5),(-14,-5),(8,-5),(14,-5)):
        cylinder(b,"QueueInlay",.65,.025,(x,1.025,z),"brass")
    part(b,"Doormat",(12,.06,5),(0,1.06,front+4),"ink","Fabric",collide=False)
    sign_x=width/2-11
    sign(b,"ОЦЕНКА  •  ВЫКУП  •  ЭКСПЕРТИЗА",(sign_x,3.2,front-17),(15,2,.2),"cream","mint")
    for x in (sign_x-7.3,sign_x+7.3): beam(b,"SignFoot",(x,.1,front-17),(x,4.2,front-17),.18,"iron")
    decor_sockets(b,width,depth,height)
    return b


def decor_sockets(b,w,d,h):
    sockets={"sign":((-w/2+9,9,-d/2-1.5),0),"banner":((w/2-4,7.6,d/2-1.5),0),
             "advert":((w/2+.5,6.6,0),-90),"painting":((-w/2+7,9,d/2-1.5),0),
             "lamp":((0,h-3.5,-3.5),0),"scales":((-7,5.04,6.1),0)}
    for key,(position,yaw)in sockets.items():part(b,"DecorSocket_"+key,(.1,.1,.1),position,rotation=(0,yaw,0),alpha=1,collide=False)


def decor_model(parent,definition):
    m=group(parent,definition['id']);anchor(m)
    category=definition['category'];tier=definition['tier'];color=tuple(definition['color'])
    if category in ('frame','card'):return m
    if category=='chair':
        part(m,'PreviewSeat',(3.8,.55,3.5),(0,2.6,0),color,'Fabric',collide=False)
        for x in (-1.45,1.45):
            for z in (-1.3,1.3):beam(m,'ChairLeg',(x,0,z),(x,2.4,z),.22,'wood','Wood')
            beam(m,'BackStile',(x,2.4,1.5),(x,5.3,1.5),.22,'wood','Wood')
            if tier>1:part(m,'ArmRest',(.16,.18,2.7),(x*1.34,3.5,0),'brass','Metal',collide=False)
        part(m,'BackPad',(3.3,2.1,.45),(0,4.3,1.5),color,'Fabric',collide=False)
        return m
    def panel(name,size,pos,c=color,material='Metal'):
        return part(m,name,size,pos,c,material,collide=False)
    if category in ('sign','advert','painting'):
        w,h=(11,4.8)if category=='sign'else(8,5.4)
        panel('BackBoard',(w,h,.3),(0,0,.1),'wood','Wood')
        for x in (-w/2,w/2):panel('FrameUpright',(.18 if tier==1 else .4,h+.5,.45),(x,0,-.1),'wood'if tier==1 else'brass')
        for y in (-h/2,h/2):panel('FrameRail',(w+.5,.25 if tier==1 else .42,.45),(0,y,-.1),'wood'if tier==1 else'brass')
        if category=='painting':
            panel('PaintedCanvas',(w-.6,h-.6,.05),(0,0,-.13),'paper','Fabric')
            panel('HarborWater',(w-.8,h*.37,.035),(0,-h*.22,-.18),'blue','SmoothPlastic')
            for i in range(4):part(m,'PaintedRoof',(1.4,1,.025),(-2.4+i*1.4,.1+(i%2)*.3,-.19),'wood','SmoothPlastic',cls='WedgePart',collide=False)
            ball(m,'PaintedSun',(.7,.7,.025),(2,h*.22,-.19),'amber')
        else:
            sign(m,'PROBA\nAPPRAISAL & ANTIQUES'if category=='sign'else'BUY · SELL · VALUE',(0,0,-.12),(w-.5,h-.5,.06),'cream','ink')
        for x in (-w/2+.6,w/2-.6):beam(m,'WallBracket',(x,h/2,.4),(x,h/2+1.2,1),.12,'iron')
        if tier>=3:
            rotor=group(m,'MotionSpin',(0,0,-.4));anchor(rotor)
            ring(rotor,'Gimbal',(0,0,0),h*.38,.07,'gold',24,plane='xy')
            for i in range(12):
                a=i*math.pi/6;part(rotor,'GearTooth',(.14,.24,.16),(math.sin(a)*h*.4,math.cos(a)*h*.4,0),'brass','Metal',rotation=(0,0,-i*30),collide=False)
    elif category=='banner':
        beam(m,'WallHanger',(-2.8,3.5,.5),(2.8,3.5,.5),.14,'brass')
        cloth=group(m,'MotionSwing'if tier==3 else'Cloth',(0,3.3,0));anchor(cloth)
        part(cloth,'WovenBanner',(4.6,6,.12),(0,-3,0),color,'Fabric',collide=False)
        for x in (-2.12,2.12):part(cloth,'Embroidery',(.1,5.6,.06),(x,-3,-.1),'gold','Fabric',collide=False)
        sign(cloth,'P',(0,-2.5,-.15),(2.4,2.6,.04),'gold','ink',font=8)
        for x in (-1.8,-.9,0,.9,1.8):beam(cloth,'Tassel',(x,-5.9,0),(x,-6.5,0),.08,'gold','Fabric')
    elif category=='lamp':
        cylinder(m,'CeilingMount',.45,.18,(0,3.1,0),'brass')
        beam(m,'Suspension',(0,.8,0),(0,3.1,0),.09,'brass')
        bulb=ball(m,'OpalDiffuser',(1.7,2,1.7),(0,0,0),'ivory','Neon')
        Node('PointLight','AccentLight',bulb).set('Brightness','float',.35).set('Range','float',14).set('Color','Color3',(1,.88,.66)).set('Shadows','bool',False)
        rotor=group(m,'MotionSpin'if tier==3 else'LampCage');anchor(rotor)
        for i in range(6):
            a=i*math.pi/3;beam(rotor,'LampStile',(math.sin(a)*1.05,-1.1,math.cos(a)*1.05),(math.sin(a)*1.05,1.1,math.cos(a)*1.05),.09,'brass')
        for y in (-1.1,1.1):ring(rotor,'CageRing',(0,y,0),1.05,.08,'brass')
    elif category=='scales':
        cylinder(m,'CarvedBase',.8,.18,(0,.1,0),'wood','Wood')
        cylinder(m,'Column',.1,2.1,(0,1.2,0),'brass')
        arm=group(m,'MotionSwing'if tier==3 else'BalanceArm',(0,2.3,0));anchor(arm)
        beam(arm,'CrossArm',(-1.6,0,0),(1.6,0,0),.1,'brass')
        for side in (-1,1):
            for z in (-.35,.35):beam(arm,'PanChain',(side*1.45,0,0),(side*1.45,-1.1,z),.025,'silver')
            cylinder(arm,'IndividualPan',.5,.06,(side*1.45,-1.15,0),'brass')
    return m


def make_item(parent, definition):
    m=group(parent,definition["id"]);anchor(m)
    kind=definition["kind"];color=definition["color"];material="Metal"
    if color in ("paper","ivory"): material="SmoothPlastic"
    if color=="wood": material="Wood"
    if color in ("stone","clay"): material="Slate" if color=="stone" else "SmoothPlastic"
    seed=sum(map(ord,definition["id"]));variant=(seed%5)*.06
    def p(name,size,pos,c=color,mat=material,**kw): return part(m,name,size,pos,c,mat,collide=False,**kw)
    def cy(name,r,h,pos,c=color,mat=material): return cylinder(m,name,r,h,pos,c,mat)
    def ba(name,size,pos,c=color,mat=material,**kw): return ball(m,name,size,pos,c,mat,**kw)
    def ri(name,center,r,th=.09,c=color,**kw): return ring(m,name,center,r,th,c,**kw)
    def vessel(name,profile):
        for i in range(len(profile)-1):
            y0,r0=profile[i]; y1,r1=profile[i+1]
            cy(name+str(i),(r0+r1)/2,y1-y0,(0,(y0+y1)/2,0))
        cy("RecessedMouth",profile[-1][1]*.75,.03,(0,profile[-1][0]+.01,0),"ink")
        ri("TurnedMouthRim",(0,profile[-1][0]+.06,0),profile[-1][1],.12)
    if kind=="spoon":
        beam(m,"TaperedHandle",(0,.16,-1.65),(0,.16,.55),.18,color)
        ba("PressedBowl",(1.25,.25,1.75),(0,.2,1.1))
        ba("ConcaveReflection",(.96,.055,1.39),(0,.34,1.1),"iron")
        ri("HandleFinial",(0,.16,-1.65),.17,.08,plane="xz")
    elif kind in ("rock","shard","arrowhead","tooth"):
        p("Core",(1.8, .55,2.3),(0,.5,0),rotation=(4,12,7),cls="WedgePart")
        for i in range(5): p("KnappedFacet",(.85,.3,1.1),((i%2-.5)*.8,.65+i*.06,-.7+i*.3),rotation=(i*13,30+i*37,8),cls="WedgePart")
        if kind=="tooth": p("SerratedCrown",(1.7,2.6,.4),(0,1.6,0),rotation=(0,0,0),cls="WedgePart");p("FossilRoot",(2.1,.55,.55),(0,.35,0),"stone","Slate")
        if kind=="arrowhead": beam(m,"Tang",(0,.5,-.5),(0,.5,-1.6),.3,color)
    elif kind in ("mug","cup"):
        radius=.9 if kind=="mug" else 1.1
        cy("ClosedBase",radius,.16,(0,.1,0))
        for y in (.35,.7,1.05,1.4):
            for i in range(24):
                t=2*math.pi*i/24;r=radius*(.82+y*.12)
                p("HollowCupWall",(2*r*math.tan(math.pi/24)+.025,.36,.17),(math.sin(t)*r,y,math.cos(t)*r),rotation=(0,math.degrees(t),0))
        ri("Lip",(0,1.6,0),radius*1.015,.09,"brass" if kind=="cup" else "iron")
        ri("Handle",(radius+.23,.9,0),.58,.13,plane="xy",arc=260,start=-130)
        if kind=="cup": cy("Saucer",1.55,.1,(0,.02,0));ri("SaucerTrim",(0,.1,0),1.4,.055,"gold")
    elif kind in ("teapot","amphora","bottle","thermos","birdpot"):
        profiles={"teapot":[(0,.7),(.3,1),(.8,1.2),(1.5,1.05),(1.9,.7)],"amphora":[(0,.45),(.25,.6),(.9,1.1),(1.7,1.3),(2.3,.95),(2.7,.5),(3.1,.55)],
                  "bottle":[(0,.65),(.25,.75),(1.7,.75),(2.1,.35),(2.8,.3),(2.9,.4)],"thermos":[(0,.8),(.2,.85),(2.2,.85),(2.4,.7),(2.6,.8)],"birdpot":[(0,.6),(.7,1.2),(1.5,1.1),(1.9,.6)]}
        vessel("TurnedBody",profiles[kind])
        if kind in ("teapot","amphora"):
            for side in (-1,1): ri("FormedHandle",(side*1.1,1.9 if kind=="amphora" else 1.3,0),.75,.16,plane="xy",arc=240,start=-120)
        if kind=="teapot": beam(m,"BentSpoutA",(.9,1,0),(1.6,1.3,0),.38,color);beam(m,"BentSpoutB",(1.6,1.3,0),(2,2,0),.32,color);cy("Lid",.75,.15,(0,2,0));ba("LidKnob",(.3,.3,.3),(0,2.2,0))
        if kind=="birdpot": ba("BirdHead",(.7,.7,.7),(1.1,1.8,0));p("Beak",(.7,.25,.35),(1.5,1.8,0),cls="WedgePart");p("Tail",(.7,.25,1.2),(-1.1,1.4,0),rotation=(0,0,-25),cls="WedgePart")
        if kind=="bottle": ri("SealRing",(0,2.75,0),.32,.06,"brass")
    elif kind=="iron":
        p("CastSole",(2,.3,3.6),(0,.2,0),cls="WedgePart");p("CastBody",(1.8,.9,3),(0,.75,-.1),cls="WedgePart")
        for z in (-.9,.9): beam(m,"HandleSupport",(0,1,z),(0,2,z),.25,"iron")
        beam(m,"WoodenGrip",(0,2,-1),(0,2,1),.45,"wood","Wood")
    elif kind=="lantern":
        vessel("Reservoir",[(0,.8),(.3,.9),(.65,.65)])
        cy("Burner",.35,.4,(0,.85,0));ba("GlassChimney",(1.1,2.4,1.1),(0,2,0),"glass","Glass",alpha=.6)
        cy("TopCap",.7,.15,(0,3.2,0));ri("CarryHandle",(0,3.4,0),.9,.09,"iron",plane="xy",arc=210,start=-15)
        for x in (-.8,.8): beam(m,"Guard",(x,.6,0),(x,3.15,0),.1,color)
    elif kind in ("hammer","pen","key","scissors","drill","plane"):
        if kind=="hammer":
            beam(m,"AshHandle",(0,.2,-1.4),(0,.2,1.4),.3,"wood","Wood");p("SteelHead",(1.8,.65,.6),(0,.35,1.1),"iron");p("SplitClaw",(.4,.45,.8),(.65,.5,.8),"iron",rotation=(0,0,20),cls="WedgePart")
        elif kind=="pen":
            beam(m,"EboniteBarrel",(0,.2,-1.5),(0,.2,1),.3,color);p("GoldNib",(.4,.14,.75),(0,.2,1.35),"gold",cls="WedgePart");beam(m,"PocketClip",(.2,.25,-1.3),(.2,.25,-.2),.06,"gold")
        elif kind=="key":
            ri("Bow",(0,.2,-1),.5,.15,plane="xz");beam(m,"Shank",(0,.2,-.6),(0,.2,1.45),.18,color)
            for z,h in ((.75,.6),(1.1,.45),(1.4,.7)): p("Ward",(h,.2,.14),(h/2,.2,z))
        elif kind=="scissors":
            for side in (-1,1):
                ri("FingerLoop",(side*.5,.2,-.9),.5,.12,plane="xz");beam(m,"CrossBlade",(side*.5,.2,-.5),(-side*.48,.3,1.7),.14,color)
            cy("PivotRivet",.15,.2,(0,.4,.3),"brass")
        elif kind=="drill":
            ri("DriveGear",(0,.8,0),.8,.17,"iron",plane="xy")
            for i in range(12):
                t=i*math.pi/6; p("GearTooth",(.18,.18,.2),(math.cos(t)*.85,.8+math.sin(t)*.85,0),"iron",rotation=(0,0,i*30))
            beam(m,"DrillShaft",(0,.8,-1.1),(0,.8,1.7),.15,"silver");beam(m,"Handle",(0,.8,-1.1),(0,.8,-1.8),.4,"wood","Wood");beam(m,"Crank",(0,.8,.1),(1,.8,.1),.13,"silver");ba("CrankGrip",(.35,.5,.35),(1,.8,.1),"wood","Wood")
        else:
            p("BeechBody",(1.8,1,3.3),(0,.55,0),"wood","Wood");p("BladeSlot",(.9,.4,.25),(0,1.2,0),"iron",rotation=(25,0,0));p("WedgeLock",(.6,.65,.6),(0,1.2,-.2),"oak","Wood",cls="WedgePart")
    elif kind in ("balance","sextant","astrolabe","gyroscope","gear","movement","mechanicalheart"):
        cy("EngineeredBase",1.3,.2,(0,.1,0),"iron")
        if kind=="balance":
            cy("TurnedColumn",.18,2.4,(0,1.4,0));beam(m,"BalanceBeam",(-1.8,2.7,0),(1.8,2.7,0),.12,color)
            for side in (-1,1):
                for dz in (-.4,.4): beam(m,"PanChain",(side*1.7,2.6,0),(side*1.7,1.15,dz),.035,"silver")
                cy("WeighPan",.6,.1,(side*1.7,1.1,0))
        elif kind in ("astrolabe","gyroscope","mechanicalheart"):
            ri("OuterGimbal",(0,1.8,0),1.4,.13,plane="xy");ri("InnerGimbal",(0,1.8,0),1.05,.11,plane="yz");ri("EquatorialRing",(0,1.8,0),.8,.1,plane="xz")
            ba("CentralRotor",(.8,.8,.8),(0,1.8,0),"amber" if kind=="astrolabe" else "brass","Metal")
            for side in (-1,1): ba("RubyBearing",(.2,.2,.2),(side*1.3,1.8,0),"ruby")
            if kind=="mechanicalheart":
                for side in (-1,1): ba("HeartChamber",(1,1.3,.8),(side*.48,1.5,0));beam(m,"Artery",(side*.35,2.1,0),(side*.55,2.8,0),.24,"copper")
        elif kind=="sextant":
            ri("GraduatedArc",(0,2.5,0),2,.12,plane="xy",arc=85,start=225)
            for i in range(12):
                t=math.radians(225+i*85/11);beam(m,"ArcTick",(math.cos(t)*1.84,2.5+math.sin(t)*1.84,0),(math.cos(t)*2.06,2.5+math.sin(t)*2.06,0),.04,"silver")
            beam(m,"IndexArm",(0,2.5,0),(-1.4,.9,0),.12,color);beam(m,"FrameArm",(0,2.5,0),(1.4,.9,0),.17,color);beam(m,"SightingTube",(-.4,1.3,-.7),(-.4,1.3,.8),.3,color)
        else:
            cy("MainWheel",1.3,.18,(0,.35,0))
            for i in range(24):
                t=i*math.pi/12;p("MachinedTooth",(.23,.2,.28),(math.sin(t)*1.35,.35,math.cos(t)*1.35),rotation=(0,i*15,0))
            cy("CenterHub",.3,.28,(0,.5,0),"silver");cy("HubBore",.12,.03,(0,.66,0),"iron")
            if kind=="movement":
                for x,z,r in ((-.5,-.4,.5),(.6,-.3,.4),(.3,.65,.35)):
                    ri("SecondaryWheel",(x,.62,z),r,.08,"gold");cy("JewelBearing",.08,.08,(x,.7,z),"ruby")
                beam(m,"Bridge",(-.8,.8,-.4),(.8,.8,.4),.18,"silver")
    elif kind in ("ring","signet","bracelet","necklace","earrings","brooch","cufflinks","pendant","locket","cameo"):
        if kind in ("ring","signet","bracelet"):
            radius=1.2 if kind=="bracelet" else .8
            ri("MetalBand",(0,1.3,0),radius,.18,plane="xy")
            if kind=="signet": p("EngravedFace",(1.1,.7,.3),(0,2.05,0),rotation=(0,0,0));ri("FaceBorder",(0,2.05,-.18),.35,.045,"gold",plane="xy")
            elif kind=="ring": ba("SetStone",(.6,.5,.6),(0,2.1,0),"ice","Glass");ri("StoneCollet",(0,2.02,0),.35,.07,"silver")
            else:
                for i in range(8):
                    t=i*math.pi/4;ba("Rivet",(.17,.17,.22),(math.sin(t)*radius,1.3+math.cos(t)*radius,-.1),"gold")
        elif kind=="necklace":
            for i in range(24):
                t=i*math.pi/12;ba("IndividualBead",(.31,.31,.31),(math.sin(t)*1.5,.25,math.cos(t)*1.1),color)
            p("Clasp",(.4,.16,.2),(0,.25,-1.15),"silver")
        elif kind in ("cufflinks","earrings"):
            for side in (-1,1):
                ba("MountedStone",(.85,.85,.4),(side*.85,.65,0));ri("SettingRim",(side*.85,.65,-.23),.45,.07,"silver",plane="xy")
                beam(m,"Post",(side*.85,.65,.1),(side*.85,.65,.8),.08,"silver")
                if kind=="earrings": ri("EarHook",(side*.85,1.4,0),.35,.055,"silver",plane="xy",arc=250,start=-30)
        else:
            p("Backing",(1.9,2.4,.25),(0,1.3,0),"gold" if kind=="cameo" else "silver",rotation=(0,0,0),shape=0)
            ba("StoneOrPortrait",(1.55,2.05,.35),(0,1.3,-.18))
            if kind=="cameo": ba("CarvedProfile",(.6,1.1,.25),(.05,1.4,-.4),"ivory");ba("ProfileNose",(.27,.2,.2),(.35,1.6,-.45),"ivory")
            ri("Bail",(0,2.65,0),.2,.07,"gold",plane="xy")
            if kind=="brooch":
                for i in range(5): beam(m,"LeafVein",(0,.5,-.4),(.6-i*.22,.9+i*.3,-.4),.04,"gold")
    elif kind=="fibula":
        ri("SpringCoilA",(0,.55,-.8),.35,.1,plane="xy")
        ri("SpringCoilB",(0,.55,-.6),.35,.1,plane="xy")
        beam(m,"FasteningPin",(0,.55,-.9),(0,.55,1.5),.08,color)
        beam(m,"ArchedBowA",(0,.55,-.7),(.55,1.25,.1),.18,color)
        beam(m,"ArchedBowB",(.55,1.25,.1),(0,.6,1.4),.18,color)
        p("CatchPlate",(.55,.3,.3),(0,.5,1.4))
    elif kind in ("gem","crystal","cluster","gemstand","artifact"):
        if kind=="gemstand": cy("Collet",.85,.3,(0,.2,0),"gold")
        crystals=3 if kind=="cluster" else 1
        for n in range(crystals):
            centerx=(n-(crystals-1)/2)*.8;h=1.4+n*.4+variant
            for i in range(6):
                t=i*60;rad=.48 if crystals>1 else .75
                p("HexagonalPrismFacet",(.58,h,.28),(centerx+math.sin(math.radians(t))*rad,h/2+.25,math.cos(math.radians(t))*rad),rotation=(0,t,0))
                p("CrystalTermination",(.64,.85,.65),(centerx+math.sin(math.radians(t))*rad*.58,h+.55,math.cos(math.radians(t))*rad*.58),rotation=(0,t,0),cls="WedgePart")
        if kind=="artifact":
            ri("ArtifactCradle",(0,.35,0),1.15,.16,"gold")
            for i in range(6):
                t=i*math.pi/3;beam(m,"CradleProng",(math.sin(t)*1.1,.3,math.cos(t)*1.1),(math.sin(t)*.7,1.1,math.cos(t)*.7),.1,"gold")
    elif kind in ("coin","medal","badge","disk","compass","pocketwatch"):
        radius=1+variant
        cy("StruckDisc",radius,.18,(0,.2,0))
        ri("RaisedRim",(0,.31,0),radius-.06,.06)
        for i in range(24):
            t=i*math.pi/12;p("EdgeReeding",(.035,.2,.05),(math.sin(t)*radius,.2,math.cos(t)*radius),rotation=(0,i*15,0))
        if kind=="disk":cy("CentralOpening",.32,.02,(0,.31,0),"ink");ri("PerforationEdge",(0,.34,0),.32,.045)
        elif kind in ("compass","pocketwatch"):
            cy("EnamelDial",.87,.04,(0,.33,0),"ivory")
            for i in range(12):
                t=i*math.pi/6;p("DialMarker",(.06,.02,.14),(math.sin(t)*.74,.37,math.cos(t)*.74),"iron",rotation=(0,i*30,0))
            beam(m,"LongHand",(0,.41,0),(.2,.41,.64),.045,"iron");beam(m,"ShortHand",(0,.43,0),(-.4,.43,.2),.07,"iron");ba("Pin",(.13,.07,.13),(0,.45,0),"brass")
            if kind=="pocketwatch":ri("Bow",(0,.2,-1.25),.3,.09,plane="xz");cy("WindingCrown",.14,.25,(0,.2,-1.1))
        elif kind=="coin":
            # A struck profile with a neck, shoulder, nose and raised hair, rather than a blank disk.
            ba("PortraitHead",(.55,.055,.71),(-.04,.365,-.03),"brass")
            p("PortraitNeck",(.21,.055,.27),(-.02,.365,.37),"brass")
            ba("PortraitShoulder",(.72,.055,.3),(-.04,.365,.52),"brass")
            p("ProfileNose",(.16,.055,.12),(.22,.368,-.09),"brass",cls="WedgePart")
            for i in range(7):
                p("RaisedHair",(.08,.025,.24),(-.22+i*.055,.401,-.17+(i%2)*.02),"brass",rotation=(0,-14+i*5,0))
            for i in range(18):
                t=i*math.pi/9
                ba("BeadedBorder",(.035,.025,.035),(math.sin(t)*(radius-.2),.353,math.cos(t)*(radius-.2)))
        else:
            cy("CentralRelief",.4,.05,(0,.35,0),"brass")
            for i in range(5):
                t=i*72;p("HeraldicRay",(.12,.06,.65),(math.sin(math.radians(t))*.3,.39,math.cos(math.radians(t))*.3),"brass",rotation=(0,t,0))
            if kind=="medal":p("Ribbon",(.9,.08,1.1),(0,.2,-1.6),"blue","Fabric");ri("Suspension",(0,.2,-1.1),.22,.06,plane="xz")
    elif kind in ("letter","map","scroll","book","tablet","plaque","mosaic","typecase"):
        if kind=="book":
            p("LowerCover",(2.8,.15,3.6),(0,.1,0),"wood","Fabric");p("PaperBlock",(2.5,.6,3.3),(0,.45,0),"paper");p("UpperCover",(2.8,.15,3.6),(0,.8,0),"wood","Fabric");p("Spine",(.25,.8,3.6),(-1.3,.45,0),"wood","Fabric")
            for i in range(8):p("PageEdge",(2.5,.02,.03),(0,.2+i*.07,-1.67),"cream")
            p("CoverLabel",(1.6,.03,1.1),(0,.91,0),"paper")
        elif kind=="scroll":
            p("Parchment",(2.8,.07,3.3),(0,.15,0));
            for z in (-1.65,1.65): p("RolledEnd",(3.1,.48,.48),(0,.35,z),shape=2)
            cy("WaxSeal",.38,.1,(.7,.26,1),"red");beam(m,"LinenCord",(-1.4,.24,.8),(1.4,.24,.8),.04,"wood")
        elif kind=="mosaic":
            p("MortarBase",(3.3,.4,2.7),(0,.25,0),"stone","Concrete")
            for x in range(7):
                for z in range(6):p("IndividualTessera",(.4,.14,.4),(-1.3+x*.43,.53,-1.05+z*.42),color if (x+z)%3 else "ivory","Marble")
        elif kind=="typecase":
            p("Tray",(3.6,.25,2.8),(0,.15,0),"wood","Wood")
            for x in range(7):p("Divider",(.06,.35,2.8),(-1.8+x*.6,.4,0),"oak","Wood")
            for z in range(5):p("Divider",(3.6,.35,.06),(0,.4,-1.4+z*.7),"oak","Wood")
            for i in range(17):p("TypeBlock",(.25,.35,.3),(-1.5+(i%6)*.6,.55,-1.05+(i//6)*.7),"silver")
        else:
            p("ArtifactSlab",(3.2,.16 if kind in ("letter","map") else .5,2.8),(0,.3,0),mat="Slate" if kind=="tablet" else material)
            for row in range(7):
                for col in range(4 if kind=="tablet" else 1):
                    p("IncisedMark" if kind=="tablet" else "PrintedLine",(.3 if kind=="tablet" else 2.3,.025,.055),(-1+col*.6 if kind=="tablet" else 0,.57 if kind=="tablet" else .4,-.95+row*.28),"iron",rotation=(0,(row+col)%3*7,0))
            if kind=="map":
                for i in range(9):beam(m,"Coastline",(-1.2+i*.28,.43,math.sin(i)*.6),(-.92+i*.28,.43,math.sin(i+1)*.6),.035,"blue")
                ri("CompassRose",(.8,.45,.7),.3,.025,"iron")
            if kind=="plaque":
                for x in (-1.3,1.3):
                    for z in (-1.1,1.1):cy("MountingRivet",.09,.05,(x,.59,z),"iron")
    elif kind in ("chest","musicbox","grinder","clock","radio","camera","calculator","console","meter","digitalclock","spectrometer","telephone"):
        wooden=kind in ("chest","musicbox","grinder","clock")
        p("ConstructedHousing",(3.2,1.8 if kind!="clock" else 2.5,2.3),(0,1 if kind!="clock" else 1.35,0),mat="Wood" if wooden else "Metal")
        for x in (-1.4,1.4):
            for z in (-.95,.95):cy("HousingFoot",.15,.2,(x,.1,z),"iron")
        if kind in ("chest","musicbox"):
            p("SeparateLid",(3.3,.3,2.4),(0,2.1,0),"oak","Wood")
            for x in (-1.1,1.1):p("LidHinge",(.35,.2,.5),(x,1.95,1.2),"brass")
            p("LockPlate",(.45,.55,.07),(0,1.4,-1.2),"brass")
            for x in (-1.3,1.3):p("CornerBand",(.18,1.7,.08),(x,1,-1.2),"brass")
            if kind=="musicbox":
                p("OpenLid",(3.3,2.3,.2),(0,2.9,1.2),"oak","Wood",rotation=(-12,0,0));p("MechanismWindow",(2.8,.15,1.8),(0,2.3,0),"iron")
                p("PinnedCylinder",(1.7,.55,.55),(-.35,2.65,0),"brass",shape=2)
                for i in range(12):p("TunedCombTooth",(.1,.07,.65),(-1+i*.17,2.68,-.55),"silver")
        elif kind=="grinder":
            cy("Hopper",1.25,.3,(0,2.1,0),"iron");cy("Spindle",.12,.8,(0,2.6,0),"silver");beam(m,"Crank",(0,3,0),(1.3,3,0),.13,"silver");ba("CrankKnob",(.5,.5,.5),(1.3,3.1,0),"wood","Wood");p("Drawer",(2.5,.6,.15),(0,.7,-1.23),"oak","Wood");ba("DrawerKnob",(.25,.25,.25),(0,.7,-1.4),"brass")
        elif kind in ("radio","meter","digitalclock","console","calculator","spectrometer"):
            p("InsetDisplay",(2.3,1.1,.1),(-.15,1.2,-1.21),"ink")
            if kind=="radio":
                for i in range(11):p("SpeakerGrille",(.07,1.05,.03),(-1.25+i*.14,1.15,-1.28),"brass")
                beam(m,"TelescopicAntenna",(1,1.9,.5),(1.6,3.7,.5),.06,"silver")
            elif kind=="calculator":
                for x in range(7):
                    for z in range(3):cy("Keycap",.12,.1,(-1.1+x*.36,2,-.6+z*.5),"ivory")
                beam(m,"AddCrank",(1.6,1,.1),(2.2,1,.1),.12,"silver");beam(m,"CrankGrip",(2.2,1,.1),(2.2,1,.8),.2,"iron")
            elif kind=="console":
                p("Cartridge",(1.9,.3,.6),(0,2.05,.3),"iron");p("DpadH",(.65,.1,.2),(-.8,1,-1.35),"iron");p("DpadV",(.2,.1,.65),(-.8,1,-1.35),"iron");ba("ButtonA",(.25,.25,.12),(.85,.9,-1.35),"ruby");ba("ButtonB",(.25,.25,.12),(1.15,1.2,-1.35),"ruby")
            elif kind=="meter":beam(m,"Needle",(-.8,.8,-1.3),(.5,1.5,-1.3),.035,"red")
            elif kind=="digitalclock":sign(m,"12:48",(0,1.2,-1.3),(2.4,.9,.04),"mint","ink")
            else:cy("SamplePort",.5,.2,(.5,2.05,0),"silver");p("PrismCase",(.8,.8,.8),(-.65,2.3,.2),"glass","Glass",alpha=.5)
            for x in (-1.1,1.1):ba("ControlKnob",(.25,.25,.18),(x,.45,-1.25),"silver")
        elif kind=="camera":
            p("Viewfinder",(.9,.5,.8),(-.6,2.1,0),"silver");p("LensBarrel",(1.3,1.3,1.3),(.4,1.1,-1.6),"iron",rotation=(0,90,0),shape=2);ba("OpticalFront",(1.1,1.1,.15),(.4,1.1,-2.28),"blue","Glass",alpha=.25);cy("ShutterButton",.15,.13,(1,2.03,0),"silver")
        elif kind=="telephone":
            cy("Dial",.95,.1,(0,2,0),"silver")
            for i in range(10):
                t=i*math.pi/5;cy("FingerHole",.13,.03,(math.sin(t)*.72,2.08,math.cos(t)*.72),"iron")
            beam(m,"Handset",(-1.4,2.6,.8),(1.4,2.6,.8),.35,"iron")
            for x in (-1.3,1.3):ba("HandsetCup",(.7,.6,.7),(x,2.4,.8),"iron")
            for i in range(16):ba("CoiledCord",(.13,.13,.13),(-1.8,2.3-i*.11,.7+math.sin(i*2)*.16),"iron")
        else:
            dial=group(m,"ClockDial",(0,1.5,-1.22),0)
            part(dial,"Dial",(.1,2.1,2.1),(0,0,0),"ivory",rotation=(0,90,0),shape=2,collide=False)
            ring(dial,"Bezel",(0,0,-.08),1.12,.09,"brass",plane="xy")
            beam(dial,"MinuteHand",(0,0,-.14),(.2,.75,-.14),.05,"iron");beam(dial,"HourHand",(0,0,-.16),(-.5,.1,-.16),.07,"iron")
    elif kind in ("top","bell","seal","ingot","cylinderseal","chessking","oillamp","scarab","mask","idol","fossil","shell","boat","telescope","binoculars","microphone","tube","telegraph","metronome","fan","engine","toycar"):
        if kind in ("top","bell","seal","chessking","cylinderseal","tube","microphone"):
            if kind=="top":profile=[(0,.08),(.4,.6),(.8,1.1),(1,.8),(1.4,.2),(2,.15)]
            elif kind=="bell":profile=[(0,1.25),(.3,1.1),(1,.7),(1.7,.4),(1.9,.2)]
            elif kind=="seal":profile=[(0,1),(.25,1),(.4,.4),(1.4,.2),(2,.55),(2.4,.4)]
            elif kind=="chessking":profile=[(0,1),(.2,1.1),(.5,.8),(1.6,.35),(2,.6),(2.5,.5)]
            elif kind=="cylinderseal":profile=[(0,.55),(.2,.6),(2,.6),(2.2,.55)]
            elif kind=="tube":profile=[(0,.7),(.4,.7),(1,.6),(2.4,.55),(2.8,.3)]
            else:profile=[(0,1),(.2,1),(.4,.2),(1.8,.18),(2,.6),(3.2,.6)]
            vessel("TurnedForm",profile)
            if kind=="chessking":beam(m,"CrownStem",(0,2.5,0),(0,3.4,0),.2,color);beam(m,"CrownCross",(-.4,3.15,0),(.4,3.15,0),.2,color)
            if kind=="bell":ri("BellHanger",(0,2,0),.3,.12,plane="xy")
            if kind=="cylinderseal":
                for i in range(7):p("EngravedRegister",(.8,.08,.03),(0,.4+i*.22,-.61),"brass")
            if kind=="microphone":
                for i in range(10):p("GrilleSlot",(1,.05,.05),(0,2.15+i*.1,-.58),"iron")
            if kind=="tube":
                for x in (-.5,0,.5):cy("ContactPin",.045,.35,(x,-.12,0),"silver")
        elif kind=="ingot":p("CastIngot",(2.9,.6,1.5),(0,.4,0),cls="WedgePart");sign(m,"950 Pt",(0,.43,-.78),(1.5,.3,.03),"iron","silver")
        elif kind=="oillamp":
            ba("ClayReservoir",(2.3,.8,2),(0,.5,0));p("WickNozzle",(.7,.45,1.1),(0,.6,-1.15),cls="WedgePart");cy("FillHole",.3,.04,(0,.94,0),"ink");ri("Handle",(0,.7,1.1),.4,.13,plane="yz")
        elif kind in ("scarab","mask","idol"):
            ba("Body",(2,2.4 if kind!="scarab" else 1,1.2 if kind!="scarab" else 2.8),(0,1.3 if kind!="scarab" else .6,0))
            for side in (-1,1):
                ba("Eye",(.35,.22,.15),(side*.45,1.6 if kind!="scarab" else .9,-.58 if kind!="scarab" else -.8),"iron")
                if kind=="scarab":
                    for i in range(3):beam(m,"BeetleLeg",(side*.8,.5,-.6+i*.6),(side*1.4,.2,-.8+i*.6),.1,color)
                elif kind=="idol":beam(m,"Arm",(side*.7,1.5,0),(side*1.1,.5,0),.4,color);beam(m,"Leg",(side*.45,.6,0),(side*.5,.05,0),.4,color)
            if kind=="mask":p("Nose",(.35,.65,.5),(0,1.3,-.7),cls="WedgePart");p("Mouth",(.6,.12,.08),(0,.7,-.65),"iron")
        elif kind in ("fossil","shell"):
            for i in range(32):
                t=i*.45;r=.12+i*.034
                ba("SpiralChamber",(.24+i*.011,.32+i*.012,.24+i*.011),(math.sin(t)*r,.2+i*.012,math.cos(t)*r),color)
            if kind=="fossil":p("Matrix",(3.1,.3,3),(0,.1,0),"stone","Slate",rotation=(0,8,0))
        elif kind=="boat":
            p("Keel",(.35,.55,3.5),(0,.4,0));
            for side in (-1,1): p("RaisedGunwale",(.3,.5,3.1),(side*.7,.75,0),rotation=(0,side*8,side*10))
            for z in (-1.6,1.6):p("TurnedEnd",(1.3,.65,.6),(0,.9,z),rotation=(0,0,0),cls="WedgePart")
            for z in (-.9,0,.9):p("CrossSeat",(1.3,.15,.35),(0,.75,z))
        elif kind in ("telescope","binoculars"):
            for x in ((0,) if kind=="telescope" else (-.7,.7)):
                for i,r in enumerate((.5,.43,.35)):p("OpticalTube",(1.2,r*2,r*2),(x,.65,-1.1+i*1.05),rotation=(0,90,0),shape=2)
                ba("ObjectiveGlass",(.95,.95,.06),(x,.65,-1.75),"blue","Glass",alpha=.25)
            if kind=="binoculars":beam(m,"CenterBridge",(-.7,.65,0),(.7,.65,0),.3,"iron")
        elif kind=="telegraph":
            p("EboniteBase",(3,.3,2),(0,.2,0),"iron");beam(m,"KeyLever",(0,.6,-.9),(0,.6,.9),.15,"brass");cy("KeyKnob",.4,.3,(0,.7,-.8),"iron")
            for x in (-1,1):cy("Terminal",.15,.45,(x,.5,.6),"brass")
            cy("Pivot",.3,.35,(0,.4,0),"silver")
        elif kind=="metronome":
            p("TaperedHousing",(2.2,3.1,1.6),(0,1.6,0),"wood","Wood",cls="WedgePart");p("FaceInset",(1.4,2.2,.08),(0,1.8,-.85),"paper");beam(m,"Pendulum",(0,.6,-.95),(.5,3.1,-.95),.06,"silver");p("SlidingWeight",(.45,.35,.2),(.3,2.2,-.95),"brass")
            for i in range(9):p("TempoTick",(.8,.025,.02),(0,.9+i*.22,-.91),"iron")
        elif kind=="fan":
            cy("Base",1,.2,(0,.1,0));beam(m,"Neck",(0,.2,0),(0,1.7,0),.22,color)
            ri("FrontGuard",(0,2.7,-.2),1.2,.08,"silver",plane="xy");ri("RearGuard",(0,2.7,.15),1.2,.08,"silver",plane="xy")
            for i in range(12):
                t=i*math.pi/6;beam(m,"GuardSpoke",(0,2.7,-.25),(math.sin(t)*1.2,2.7+math.cos(t)*1.2,-.2),.035,"silver")
            for i in range(3):p("FanBlade",(.65,1.05,.1),(math.sin(i*2.094)*.55,2.7+math.cos(i*2.094)*.55,0),rotation=(0,0,-i*120+25),cls="WedgePart")
            ba("MotorHub",(.45,.45,.6),(0,2.7,.1),"iron")
        elif kind=="engine":
            p("BedPlate",(3.5,.3,2.6),(0,.2,0),"iron");cy("Boiler",.75,1.8,(-.7,1.2,0),"copper");cy("SafetyValve",.12,.4,(-.7,2.3,0),"brass");ri("Flywheel",(1,1.2,0),.9,.13,"iron",plane="xy")
            for i in range(6):t=i*math.pi/3;beam(m,"WheelSpoke",(1,1.2,0),(1+math.cos(t)*.8,1.2+math.sin(t)*.8,0),.08,"iron")
            beam(m,"PistonRod",(-.4,.8,.5),(1,.8,.5),.12,"silver");beam(m,"SteamPipe",(-.7,1.8,0),(.4,1.8,.5),.15,"brass")
        else:
            p("TinBody",(1.7,.65,3),(0,.65,0));p("Cabin",(1.45,.8,1.3),(0,1.3,.2));p("Windshield",(1.2,.55,.08),(0,1.35,-.5),"glass","Glass",alpha=.35)
            for x in (-.92,.92):
                for z in (-.95,.95):p("RubberWheel",(.28,.8,.8),(x,.4,z),"iron",shape=2);p("HubCap",(.3,.35,.35),(x*1.04,.4,z),"silver",shape=2)
            beam(m,"ClockworkKey",(.9,.8,0),(1.45,.8,0),.1,"silver");ri("WindingBow",(1.5,.8,0),.23,.06,"silver",plane="yz")
    else:
        raise ValueError(f"Missing authored item geometry: {definition['id']} / {kind}")
    # A tiny maker detail unique to the inventory model, not a floating billboard.
    part(m,"MakerInlay",(.18,.025,.12),(.1,.035,.1),"brass","Metal",collide=False)
    return m


def bacon(parent):
    m=group(parent,"BaconCustomer")
    root=part(m,"HumanoidRootPart",(2,2,1),(0,0,0),alpha=1,collide=True);root.set("Anchored","bool",False);m.set("PrimaryPart","Ref",root)
    parts={}
    definitions={"Torso":((2,2,1),(0,0,0),(53,93,114)),"Head":((2,1,1),(0,1.5,0),(236,194,148)),
                 "Left Arm":((1,2,1),(-1.5,0,0),(236,194,148)),"Right Arm":((1,2,1),(1.5,0,0),(236,194,148)),
                 "Left Leg":((1,2,1),(-.5,-2,0),(48,59,72)),"Right Leg":((1,2,1),(.5,-2,0),(48,59,72))}
    for name,(size,pos,color) in definitions.items():
        p=part(m,name,size,pos,color,collide=False);p.set("Anchored","bool",False);parts[name]=p
    def joint(name,a,b,c0,c1):
        Node("Motor6D",name,a).set("Part0","Ref",a).set("Part1","Ref",b).set("C0","CoordinateFrame",(c0,IDENTITY)).set("C1","CoordinateFrame",(c1,IDENTITY))
    joint("RootJoint",root,parts["Torso"],(0,0,0),(0,0,0));joint("Neck",parts["Torso"],parts["Head"],(0,1,0),(0,-.5,0))
    for side,signx in (("Left",-1),("Right",1)):
        joint(side+" Shoulder",parts["Torso"],parts[side+" Arm"],(signx, .5,0),(-signx*.5,.5,0))
        joint(side+" Hip",parts["Torso"],parts[side+" Leg"],(signx*.5,-1,0),(0,1,0))
    hum=Node("Humanoid","Humanoid",m).set("RigType","token",0).set("HipHeight","float",0).set("WalkSpeed","float",10).set("Health","float",100).set("MaxHealth","float",100).set("RequiresNeck","bool",True)
    # Sculpted bacon hair is welded to the head; no external catalog asset can fail to load.
    for i in range(8):
        strand=part(m,"BaconHairStrand",(.3,.35,1.2),(-.96+i*.27,2.1,-.02),(100+(i%3)*14,57,29),rotation=(0,(i-4)*7,(i%3-1)*9),collide=False)
        strand.set("Anchored","bool",False).set("Massless","bool",True)
        Node("WeldConstraint","HairWeld",strand).set("Part0","Ref",parts["Head"]).set("Part1","Ref",strand)
    face=Node("Decal","ClassicSmile",parts["Head"]).set("Face","token",5).set("Texture","Content","rbxasset://textures/face.png")
    return m


def tree(parent,x,z,seed=0):
    m=group(parent,"StreetTree",(x,0,z));part(m,"PlanterBase",(10,1,10),(0,.5,0),"concrete","Concrete")
    part(m,"Soil",(8.8,.5,8.8),(0,1.1,0),"wood","Ground",collide=False)
    for dx,dz in ((0,-5),(0,5),(-5,0),(5,0)):part(m,"PlanterRim",(10.5 if dz else .6,.7,.6 if dz else 10.5),(dx,1.3,dz),"cream","Concrete")
    cylinder(m,"Trunk",.65,11,(0,6.5,0),"wood","Wood",True)
    for i in range(5):
        t=i*2.4+seed; xx,zz=math.sin(t)*3.6,math.cos(t)*3.6
        beam(m,"Bough",(0,7,0),(xx,12+i*.3,zz),.4,"wood","Wood")
        ball(m,"Crown",(8,7,8),(xx,14+i*.7,zz),"leaf" if i%2 else "green","Grass")


def town(parent):
    t=group(parent,"Town")
    # One continuous structural ground slab under roads, pavement, parks and every plot.
    part(t,"ContinuousTownGround",(560,16,800),(0,-8.1,0),"grass","Grass")
    part(t,"Avenue",(64,.2,750),(0,.02,0),"road","Asphalt")
    for x in (-46,46):part(t,"ContinuousPromenade",(24,.35,750),(x,.12,0),"concrete","Concrete")
    for x in (-33,33):part(t,"GraniteKerb",(1,.55,750),(x,.15,0),"stone","Granite")
    for z in range(-350,351,16):
        part(t,"CentreRoadDash",(.5,.012,6),(0,.129,z),"cream",collide=False)
        for x in (-46,46):part(t,"PavementExpansionJoint",(23,.013,.08),(x,.305,z),"stone",collide=False)
    for z in (-160,0,160):
        for side in (-1,1):
            part(t,"PlotForecourt",(116,.3,136),(side*116,.06,z),"concrete","Concrete")
            for dx in range(7):part(t,"ForecourtPavingJoint",(.07,.012,136),(side*(60+dx*18),.217,z),"stone",collide=False)
            for dz in (-59,59):
                garden=group(t,"BureauGarden",(side*94,.2,z+dz))
                part(garden,"RaisedBed",(41,.8,8),(0,.4,0),"cream","Concrete")
                part(garden,"PlantedSoil",(39,.15,6.6),(0,.88,0),"wood","Ground",collide=False)
                for i in range(9):
                    ball(garden,"ClippedHerb",(3.5,2.5,4),(-17+i*4.2,1.7,0),"leaf","Grass")
                    for j in (-1,1):ball(garden,"DriedBlossom",(.38,.4,.38),(-17+i*4.2,2.9,j*.7),"ivory")
            # A low boundary wall and arched trellis frame each future expansion lot.
            for dz in (-72,72):
                part(t,"PlotGardenWall",(109,1.2,.8),(side*128,.6,z+dz),"cream","Concrete")
                for xx in (82,174):part(t,"GardenGatePier",(1.4,4,1.4),(side*xx,2,z+dz),"cream","Concrete")
        for x in range(-25,26,10):part(t,"CrosswalkStripe",(4,.015,11),(x,.135,z+66),"cream",collide=False)
    # A generous arrival square and a working-bureau district, not an empty baseplate.
    for z in (-300,300):part(t,"GatePlaza",(150,.35,100),(0,.12,z),"concrete","Concrete")
    for side in (-1,1):
        for z in range(-315,316,45):lamp(t,(side*61,.3,z),18,True)
        for z in (-240,-80,80,240):tree(t,side*46,z,int(z)%4);bench(t,(side*49,.3,z+16),12)
    for z in (-345,345):
        for x in (-66,66):
            part(t,"GatePier",(7,29,7),(x,14.5,z),"cream","Concrete")
            part(t,"PierCap",(9,1.5,9),(x,29.7,z),"stone","Concrete")
        part(t,"GateLintel",(139,4,5),(0,29,z),"ink","Metal")
        sign(t,"КВАРТАЛ ОЦЕНЩИКОВ" if z<0 else "РЫНОК НАХОДОК",(0,29,z-2.7),(95,3,.3),"cream","ink")
    # A dry, sealed ornamental basin; all water is a shallow noncolliding visual surface over solid stone.
    part(t,"PedestrianCourtyard",(82,.35,90),(-230,.12,20),"concrete","Concrete")
    f=group(t,"RegistryFountain",(-230,.2,20));cylinder(f,"ClosedBasin",21,1.3,(0,.65,0),"stone","Concrete",True)
    ring(f,"BasinRim",(0,1.5,0),20,.7,"cream",48)
    cylinder(f,"ShallowWater",19.3,.08,(0,1.35,0),"blue","Glass",alpha=.38)
    cylinder(f,"CentralPlinth",5,2.4,(0,1.8,0),"cream","Concrete",True)
    # The landmark's giant balance has a column, pivot, beam and visibly suspended pans.
    cylinder(f,"LandmarkColumn",.8,12,(0,8,0),"brass",collide=True)
    beam(f,"BalanceCrossbeam",(-12,14,0),(12,14,0),.6,"brass")
    for x in (-11,11):
        for dz in (-2,2):beam(f,"SuspensionRod",(x,14,0),(x,8.5,dz),.12,"brass")
        cylinder(f,"BalancePan",3,.25,(x,8.3,0),"brass")
    for x in (-260,-200):
        for z in (-7,47):bench(t,(x,.3,z),12)
    guide=sign(t,"ПРОБА\nБЮРО ОЦЕНКИ\nНачни свою историю",(-30,6,-290),(17,9,.6),"cream","ink")
    for x in (-37,-23):beam(t,"GuidePost",(x,.3,-290),(x,10.6,-290),.35,"iron")
    prompt(guide,"GuidePrompt","Как работать оценщиком","Путеводитель",19)
    # Broker kiosk with open sides, a real counter, stock drawers, roof and weighing station.
    broker=group(t,"BrokerKiosk",(0,.2,290));part(broker,"KioskFloor",(52,.6,28),(0,.3,0),"cream","Concrete")
    for x in (-24,24):
        for z in (-12,12):part(broker,"CanopyPost",(.6,14,.6),(x,7,z),"ink","Metal")
    part(broker,"KioskRoof",(56,.6,31),(0,14.3,0),"mint","Metal")
    for z in (-12,12):beam(broker,"CanopyBeam",(-24,13.5,z),(24,13.5,z),.5,"iron")
    for x in (-22,22):beam(broker,"CanopyBrace",(x,10,-12),(x-4*(1 if x>0 else -1),13.5,-12),.3,"iron")
    cabinet(broker,(0,.65,-4),29,4,5,4)
    equipment(broker,"scale",(-7,5,-4))
    sign(broker,"СКУПКА / 72% РЫНОЧНОЙ ЦЕНЫ",(0,12,-13),(42,3,.35),"cream","ink")
    p=part(broker,"BrokerAnchor",(.5,.5,.5),(0,4,-8),alpha=1,collide=False);prompt(p,"BrokerPrompt","Продать предметы","Независимый скупщик",20)
    for x in (-19,19):cabinet(broker,(x,.7,8),6,4,4,3)
    # Arrival tram: a readable landmark with wheels, cabin, seats, stairs and thick framed windows.
    tram=group(t,"ArrivalTram",(29,.2,-302),-90)
    part(tram,"Chassis",(48,1.5,14),(0,2,0),"iron","Metal")
    part(tram,"CabinFloor",(46,.6,13),(0,3.2,0),"wood","WoodPlanks")
    part(tram,"BackBody",(47,4,.6),(0,5,6.7),"mint","Metal")
    part(tram,"FrontBodyLeft",(23,4,.6),(-11.5,5,-6.7),"mint","Metal")
    part(tram,"FrontBodyRight",(16,4,.6),(15,5,-6.7),"mint","Metal")
    for x in (-23.2,23.2):part(tram,"CarriageEndWall",(.6,9,13.5),(x,7.7,0),"mint","Metal")
    # Open entrance is on the visible front side of the carriage; the chassis remains sealed underneath.
    part(tram,"Roof",(49,.8,15),(0,12.3,0),"cream","Metal")
    for x in range(-21,22,7):
        for z in (-7,7):part(tram,"WindowPost",(.4,5.4,.4),(x,9.1,z),"ink","Metal",collide=False)
        if x<21:
            for z in (-7,7):
                if not (x==0 and z==-7):window_panel(tram,x+3.5,9.2,z,6.3,4.4)
    for i in range(3):part(tram,"EntranceStep",(6.6,1.05,1.6),(3.5,.525+i*1.05,-11.3+i*1.6),"wood","WoodPlanks")
    for x in (.1,6.9):beam(tram,"EntryHandrail",(x,3,-12),(x,6.3,-7),.18,"brass","Metal",True)
    for x in (-14,14):bench(tram,(x,3.5,3),10)
    for x in (-15,15):
        for z in (-7.3,7.3):part(tram,"Wheel",(1.1,4,4),(x,1.9,z),"iron","Metal",rotation=(0,90,0),shape=2)
    sign(tram,"ПРОБА / ГОРОДСКОЙ МАРШРУТ",(-11.5,5.6,-7.13),(20,1.5,.15),"cream","mint")
    # Parks and utility infrastructure finish the lots at a playable scale.
    for side in (-1,1):
        for z in range(-320,321,80):
            if not (side==-1 and z==0):tree(t,side*235,z,(z//11)%5)
        for z in (-160,0,160):
            for x in (side*211,side*251):bench(t,(x,.1,z-65),14)
            part(t,"ParkWalkway",(77,.2,12),(side*225,.1,z-65),"stone","Cobblestone")
        part(t,"BoundaryPlinth",(2.5,3,790),(side*276,1.4,0),"concrete","Concrete")
        for z in range(-385,386,14):part(t,"BoundaryPier",(3,11,3),(side*276,5.5,z),"cream","Concrete")
        part(t,"BoundaryIronwork",(.8,8,790),(side*276,6.2,0),"ink","Metal")
    for z in (-396,396):part(t,"BoundaryWall",(554,12,2.5),(0,5.5,z),"cream","Concrete")
    for z in range(-340,341,70):
        for x in (-29,29):
            cylinder(t,"FlushManhole",1.7,.04,(x,.145,z),"iron")
            for i in range(5):part(t,"DrainSlot",(.08,.015,2.3),(x-.7+i*.35,.172,z),"dark",collide=False)
    return t


def write_property(parent, name, typ, value):
    el=ET.SubElement(parent,typ,{"name":name})
    if typ=="Ref":el.text=value.ref if isinstance(value,Node) else value
    elif typ=="bool":el.text="true" if value else "false"
    elif typ in ("Vector3","Vector2","Color3"):
        keys=("R","G","B") if typ=="Color3" else ("X","Y","Z")
        for key,n in zip(keys,value):ET.SubElement(el,key).text=f"{n:.8g}"
    elif typ=="CoordinateFrame":
        pos,rotation=value
        for key,n in zip(("X","Y","Z"),pos):ET.SubElement(el,key).text=f"{n:.9g}"
        for i in range(3):
            for j in range(3):ET.SubElement(el,f"R{i}{j}").text=f"{rotation[i][j]:.9g}"
    elif typ=="UDim2":
        for key,n in zip(("XS","XO","YS","YO"),value):ET.SubElement(el,key).text=str(n)
    elif typ=="Content":ET.SubElement(el,"url").text=str(value)
    else:el.text=str(value)


def serialize(node,parent):
    el=ET.SubElement(parent,"Item",{"class":node.cls,"referent":node.ref})
    props=ET.SubElement(el,"Properties")
    for name,(typ,value) in node.props.items():write_property(props,name,typ,value)
    for child in node.children:serialize(child,el)


def lua_literal(value):
    if isinstance(value,str):return json.dumps(value,ensure_ascii=False)
    if isinstance(value,bool):return "true" if value else "false"
    if isinstance(value,(int,float)):return str(value)
    if isinstance(value,list):return "{"+", ".join(lua_literal(v) for v in value)+"}"
    if isinstance(value,dict):return "{"+", ".join(f"[{lua_literal(k)}] = {lua_literal(v)}" for k,v in value.items())+"}"
    raise TypeError(value)


def main():
    OUT.mkdir(exist_ok=True)
    definitions=json.loads((ROOT/"content/items.json").read_text())
    decor_definitions=json.loads((ROOT/"content/decor.json").read_text())
    catalog_src="-- Generated from content/items.json by tools/build_place.py.\nreturn {\n"+"\n".join("\t"+lua_literal(d)+"," for d in definitions)+"\n}\n"
    (ROOT/"src/Server/Catalog.luau").write_text(catalog_src)
    decor_src='-- Generated from content/decor.json.\nlocal Decor={List={\n'+'\n'.join('\t'+lua_literal(d)+','for d in decor_definitions)+'\n}}\nDecor.ById={}\nfor _,d in ipairs(Decor.List)do Decor.ById[d.id]=d end\nreturn Decor\n'
    (ROOT/'src/Shared/Decor.luau').write_text(decor_src)
    root=Node("DataModel","PROBA")
    workspace=Node("Workspace","Workspace",root).set("Gravity","float",196.2).set("FallenPartsDestroyHeight","float",-100).set("StreamingEnabled","bool",False)
    town(workspace)
    Node("Folder","Customers",workspace)
    plots=Node("Folder","Plots",workspace)
    for i,(side,z) in enumerate(( (side,z) for z in (-160,0,160) for side in (-1,1)),1):
        plot=group(plots,f"Plot{i:02d}",(side*118,0,z),90*side)
        anchor(plot);building(plot,1)
    spawn=Node("SpawnLocation","ArrivalSpawn",workspace,(0,.1,-274))
    spawn.set("CFrame","CoordinateFrame",(spawn.position,IDENTITY)).set("size","Vector3",(20,.2,16)).set("Anchored","bool",True).set("Transparency","float",1).set("CanCollide","bool",False).set("Neutral","bool",True).set("Duration","int",0)
    cam=Node("Camera","Camera",workspace).set("CameraType","token",5)
    # A saved edit-mode camera actually frames the district when the place is opened.
    camera_pos=(74,100,-305);target=(-100,10,-160)
    zaxis=unit(tuple(camera_pos[i]-target[i] for i in range(3)));xaxis=unit(cross((0,1,0),zaxis));yaxis=cross(zaxis,xaxis)
    camera_rot=tuple(tuple((xaxis,yaxis,zaxis)[j][i] for j in range(3)) for i in range(3))
    cam.set("CFrame","CoordinateFrame",(camera_pos,camera_rot)).set("Focus","CoordinateFrame",(target,IDENTITY));workspace.set("CurrentCamera","Ref",cam)
    storage=Node("ServerStorage","ServerStorage",root)
    buildings=Node("Folder","Buildings",storage)
    levels=[building(buildings,i) for i in (1,2,3)]
    templates=Node("Folder","Templates",storage);bacon(templates)
    rep=Node("ReplicatedStorage","ReplicatedStorage",root)
    item_models=Node("Folder","ItemModels",rep)
    models=[make_item(item_models,d) for d in definitions]
    decor_models=Node('Folder','DecorModels',rep)
    for definition in decor_definitions:decor_model(decor_models,definition)
    network=Node("Folder","Network",rep)
    Node("RemoteEvent","Action",network);Node("RemoteEvent","State",network)
    shared=Node("Folder","Shared",rep)
    for path in sorted((ROOT/"src/Shared").glob("*.luau")):
        Node("ModuleScript",path.stem,shared).set("Source","ProtectedString",path.read_text())
    server=Node("ServerScriptService","ServerScriptService",root)
    for path in sorted((ROOT/"src/Server").glob("*.luau")):
        is_script=path.name.endswith(".server.luau");name=path.name.replace(".server.luau","").replace(".luau","")
        n=Node("Script" if is_script else "ModuleScript",name,server).set("Source","ProtectedString",path.read_text())
        if is_script:n.set("Disabled","bool",False)
    starter=Node("StarterPlayer","StarterPlayer",root).set("CameraMinZoomDistance","float",5).set("CameraMaxZoomDistance","float",36).set("CharacterWalkSpeed","float",16)
    scripts=Node("StarterPlayerScripts","StarterPlayerScripts",starter)
    Node("LocalScript","ProbaClient",scripts).set("Source","ProtectedString",(ROOT/"src/Client/Main.client.luau").read_text()).set("Disabled","bool",False)
    for path in sorted((ROOT/"src/Client").glob("*.luau")):
        if path.name!="Main.client.luau":Node("ModuleScript",path.stem,scripts).set("Source","ProtectedString",path.read_text())
    Node("StarterGui","StarterGui",root)
    lighting=Node("Lighting","Lighting",root).set("ClockTime","float",15.2).set("Brightness","float",2.3).set("GlobalShadows","bool",True).set("EnvironmentDiffuseScale","float",.65).set("EnvironmentSpecularScale","float",.8)
    lighting.set("Ambient","Color3",(.45,.49,.47)).set("OutdoorAmbient","Color3",(.59,.63,.62)).set("ShadowSoftness","float",.3).set("GeographicLatitude","float",38)
    Node("Atmosphere","Atmosphere",lighting).set("Density","float",.18).set("Offset","float",.15).set("Haze","float",1.2).set("Glare","float",.2).set("Color","Color3",(.82,.85,.78)).set("Decay","Color3",(.51,.59,.62))
    Node("BloomEffect","SubtleBloom",lighting).set("Intensity","float",.12).set("Size","float",20).set("Threshold","float",1.8)
    Node("ColorCorrectionEffect","WarmPaperGrade",lighting).set("Brightness","float",.015).set("Contrast","float",.08).set("Saturation","float",-.07).set("TintColor","Color3",(1,.98,.92))
    Node("SoundService","SoundService",root).set("AmbientReverb","token",0)
    Node("Players","Players",root).set("CharacterAutoLoads","bool",True)
    xml=ET.Element("roblox",{"version":"4"})
    ET.SubElement(xml,"External").text="null";ET.SubElement(xml,"External").text="nil"
    for service in root.children:serialize(service,xml)
    ET.ElementTree(xml).write(OUT/"PROBA.rbxlx",encoding="utf-8",xml_declaration=True)
    allnodes=list(root.walk());parts=[n for n in allnodes if n.cls in ("Part","WedgePart","SpawnLocation","Seat")]
    world_parts=[n for n in workspace.walk() if n.cls in ("Part","WedgePart","SpawnLocation","Seat")]
    stats={"name":"PROBA · Appraisal & Antiques","catalogue":len(definitions),"unique_model_kinds":len({d['kind'] for d in definitions}),
           "instances":len(allnodes)-1,"total_parts":len(parts),"world_parts":len(world_parts),
           "items":{m.name:sum(n.cls in ("Part","WedgePart") for n in m.walk()) for m in models},
           "base_levels":{str(i+1):{"width":dim[0],"depth":dim[1],"height":dim[2],"footprint":dim[0]*dim[1],
             "floors":1 if i<2 else 2,"gross_floor_area":dim[0]*dim[1] if i<2 else 108*84+108*17+108*18+38*47+32*12+20*47+6.5*47,
             "parts":sum(n.cls in ("Part","WedgePart","Seat") for n in levels[i].walk())} for i,dim in enumerate(BASE_DIMENSIONS)}}
    (OUT/"manifest.json").write_text(json.dumps(stats,ensure_ascii=False,indent=2)+"\n")
    scene=[]
    for n in world_parts:
        if n.props.get("Transparency",("",0))[1]>=.95:continue
        scene.append({"name":n.name,"class":n.cls,"position":n.position,"rotation":n.rotation,"size":n.props["size"][1],
                      "color":n.props.get("Color3uint8",("",0))[1]&0xffffff,"alpha":n.props.get("Transparency",("",0))[1],
                      "shape":n.props.get("shape",("",1))[1],"material":n.props.get("Material",("",272))[1]})
    (OUT/"scene.json").write_text(json.dumps(scene,separators=(",",":")))
    print(json.dumps({k:v for k,v in stats.items() if k!="items"},ensure_ascii=False,indent=2))
    print(f"Built {OUT/'PROBA.rbxlx'} ({(OUT/'PROBA.rbxlx').stat().st_size/1024/1024:.2f} MiB)")


if __name__=="__main__":main()

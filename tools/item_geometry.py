"""Closed faceted solids authored as correctly oriented Roblox WedgePart faces.

No uploaded mesh dependency. Every surface triangle is split along its longest
edge into two right triangles. Shared edge indices are checked for watertight
topology before exporting. The thin wedges overlap only at their shared seams.
"""
import collections, math

def add(a,b):return tuple(x+y for x,y in zip(a,b))
def sub(a,b):return tuple(x-y for x,y in zip(a,b))
def scale(a,k):return tuple(x*k for x in a)
def dot(a,b):return sum(x*y for x,y in zip(a,b))
def cross(a,b):return(a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0])
def unit(a):return scale(a,1/math.sqrt(dot(a,a)))

def triangle(a,b,c,thickness=.022):
    # bc is the longest edge; the perpendicular from a lies inside that edge.
    if math.dist(a,b)>max(math.dist(a,c),math.dist(b,c)):a,b,c=c,a,b
    elif math.dist(a,c)>math.dist(b,c):a,b,c=b,a,c
    ab,ac,bc=sub(b,a),sub(c,a),sub(c,b)
    right=unit(cross(ac,ab));back=unit(bc);up=cross(back,right)
    height=abs(dot(ab,up));assert height>.0001,'Degenerate face'
    for end,axis,xaxis in ((b,back,right),(c,scale(back,-1),scale(right,-1))):
        length=abs(dot(sub(end,a),back))
        if length<.001:continue
        axes=(xaxis,up,axis)
        rotation=tuple(tuple(axes[j][i]for j in range(3))for i in range(3))
        yield((thickness,height,length),scale(add(a,end),.5),rotation)

def validate(vertices,faces):
    edges=collections.Counter()
    for face in faces:
        assert len(face)==3 and len(set(face))==3
        a,b,c=(vertices[i]for i in face)
        assert dot(cross(sub(b,a),sub(c,a)),cross(sub(b,a),sub(c,a)))>1e-12
        for i,j in zip(face,face[1:]+face[:1]):edges[tuple(sorted((i,j)))]+=1
    assert all(n==2 for n in edges.values()),'Open or non-manifold item shell'
    assert len(vertices)-len(edges)+len(faces)==2,'Solid must be one closed genus-zero shell'

def solid(part,parent,name,vertices,faces,rgb,material='Glass',alpha=.06,thickness=.022):
    validate(vertices,faces)
    center=scale(tuple(sum(v[i]for v in vertices)for i in range(3)),1/len(vertices))
    for index,face in enumerate(faces):
        a,b,c=(vertices[i]for i in face)
        normal=unit(cross(sub(b,a),sub(c,a)))
        face_center=scale(add(add(a,b),c),1/3)
        if dot(normal,sub(face_center,center))<0:b,c=c,b;normal=scale(normal,-1)
        # Small intentional face-value changes keep facets readable in Viewports.
        value=.79+(index%5)*.045+max(0,normal[1])*.08
        color=tuple(max(0,min(255,round(v*value)))for v in rgb)
        for j,(size,pos,rotation) in enumerate(triangle(a,b,c,thickness)):
            p=part(parent,f'{name}_Face{index:02d}_{j}',size,pos,color,material,rotation=rotation,collide=False,alpha=alpha,cls='WedgePart')
            p.set('Reflectance','float',.10 if material=='Glass'else .025)

def rings(profile,segments=8,phase=0,oval=(1,1),twist=0):
    """Closed gem/cabochon/rock shell; radius=0 endpoints are single vertices."""
    vertices=[];levels=[]
    for layer,(height,radius) in enumerate(profile):
        ids=[]
        if radius==0:ids=[len(vertices)];vertices.append((0,height,0))
        else:
            for i in range(segments):
                a=2*math.pi*i/segments+phase+layer*twist
                ids.append(len(vertices));vertices.append((math.cos(a)*radius*oval[0],height,math.sin(a)*radius*oval[1]))
        levels.append(ids)
    faces=[]
    for lower,upper in zip(levels,levels[1:]):
        for i in range(segments):
            j=(i+1)%segments
            if len(lower)==1:faces.append((lower[0],upper[j],upper[i]))
            elif len(upper)==1:faces.append((lower[i],lower[j],upper[0]))
            else:faces.extend(((lower[i],lower[j],upper[i]),(lower[j],upper[j],upper[i])))
    validate(vertices,faces)
    return vertices,faces

def transform(vertices,position=(0,0,0),tilt=0,yaw=0):
    ct,st=math.cos(tilt),math.sin(tilt);cy,sy=math.cos(yaw),math.sin(yaw)
    result=[]
    for x,y,z in vertices:
        xx,yy=x*ct-y*st,x*st+y*ct
        result.append(add(position,(xx*cy+z*sy,yy,-xx*sy+z*cy)))
    return result

def truncate(vertices,faces,fraction=.14):
    """Bevel crystal vertices into closed cleavage caps, preserving shared edges."""
    validate(vertices,faces)
    directed={};result=[];neighbors=collections.defaultdict(set)
    for a,b,c in faces:
        for i,j in ((a,b),(b,c),(c,a)):
            neighbors[i].add(j);neighbors[j].add(i)
    for a in sorted(neighbors):
        for b in sorted(neighbors[a]):
            directed[a,b]=len(result)
            result.append(add(scale(vertices[a],1-fraction),scale(vertices[b],fraction)))
    polygons=[]
    for a,b,c in faces:polygons.append([directed[a,b],directed[b,a],directed[b,c],directed[c,b],directed[c,a],directed[a,c]])
    center=scale(tuple(sum(v[i]for v in vertices)for i in range(3)),1/len(vertices))
    for a,near in neighbors.items():
        axis=unit(sub(vertices[a],center));side=unit(cross(axis,(0,1,0)if abs(axis[1])<.9 else(1,0,0)));up=cross(axis,side)
        ordered=sorted((directed[a,b]for b in near),key=lambda i:math.atan2(dot(sub(result[i],vertices[a]),up),dot(sub(result[i],vertices[a]),side)))
        polygons.append(ordered)
    new_faces=[]
    for polygon in polygons:
        for i in range(1,len(polygon)-1):new_faces.append((polygon[0],polygon[i],polygon[i+1]))
    validate(result,new_faces)
    return result,new_faces

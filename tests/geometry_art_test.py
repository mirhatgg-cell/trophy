"""Check real wedge footprints and the embedded RGBA texture payloads."""
import base64, ctypes, ctypes.util, hashlib, json, math, random, sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'tools'))
from item_geometry import triangle, sub, dot, cross

def inside(point,a,b,c):
    u,v,p=sub(b,a),sub(c,a),sub(point,a)
    uu,uv,vv,pu,pv=dot(u,u),dot(u,v),dot(v,v),dot(p,u),dot(p,v)
    denominator=uu*vv-uv*uv
    x=(pu*vv-pv*uv)/denominator;y=(pv*uu-pu*uv)/denominator
    return x>=-1e-7 and y>=-1e-7 and x+y<=1+1e-7

random.seed(108);tested=0
examples=[((0,1,0),(0,0,0),(2,0,0)),((0,0,0),(3,0,0),(0,2,0))]
examples += [tuple(tuple(random.uniform(-3,3)for _ in range(3))for _ in range(3))for _ in range(100)]
for a,b,c in examples:
    normal=cross(sub(b,a),sub(c,a));area=math.sqrt(dot(normal,normal))*.5
    if area<1e-4:continue
    covered=0
    for size,position,rotation in triangle(a,b,c):
        covered+=size[1]*size[2]*.5
        for local in [(0,-size[1]/2,-size[2]/2),(0,-size[1]/2,size[2]/2),(0,size[1]/2,size[2]/2)]:
            point=tuple(position[i]+sum(rotation[i][j]*local[j]for j in range(3))for i in range(3))
            assert abs(dot(sub(point,a),normal))<1e-7,'Wedge projection leaves the authored face plane'
            assert inside(point,a,b,c),'Wedge slopes are inverted or extend outside the surface triangle'
        tested+=1
    assert math.isclose(area,covered,rel_tol=1e-8),'Surface triangles have a hole or overlap'
print('PASS closed item facets:',tested,'actual wedge footprints')

data=json.loads((ROOT/'content/identity_art.json').read_text())
assert len(data)==22
lib=ctypes.CDLL(ctypes.util.find_library('zstd'))
lib.ZSTD_decompress.argtypes=[ctypes.c_void_p,ctypes.c_size_t,ctypes.c_void_p,ctypes.c_size_t]
lib.ZSTD_decompress.restype=ctypes.c_size_t
for key,d in data.items():
    assert len(json.dumps(d,separators=(',',':')))<1000000,'Unexpected artwork payload growth'
    assert hashlib.sha256((ROOT/'assets/identity'/d['source']).read_bytes()).hexdigest()==d['sourceSha256'],'Repack changed source artwork'
    size=d['width']*d['height']*4;compressed=base64.b64decode(d['pixels'],validate=True)
    output=ctypes.create_string_buffer(size)
    assert lib.ZSTD_decompress(output,size,compressed,len(compressed))==size,'Truncated or corrupt RGBA payload'
    assert hashlib.sha256(output.raw).hexdigest()==d['sha256'],'Packed painting differs from its raw-pixel checksum'
    assert d['width']<=1024 and d['height']<=1024
    for x,y,pixels in d['strips']:
        assert 0<=y<d['fallbackHeight']and 0<=x and x+len(pixels)<=d['fallbackWidth']
        assert 2<=len(pixels)<=20,'Gradient keypoint count outside Roblox limits'
        assert all(isinstance(p,int)and 0<=p<=4294967295 for p in pixels)
print('PASS embedded artwork:',len(data),'original paintings, RGBA checksums and fallback limits')

#!/usr/bin/env python3
"""Package original RGBA artwork for the place. No remote IDs or uploads.

The originals are retained unchanged. Tiles are cropped/resampled for texture
storage, Zstandard-compressed, and given a low-resolution gradient-strip copy
for experiences where EditableImage creation is unavailable.
"""
import base64, ctypes, ctypes.util, hashlib, json
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
ZSTD=ctypes.CDLL(ctypes.util.find_library('zstd'))
ZSTD.ZSTD_compressBound.argtypes=[ctypes.c_size_t];ZSTD.ZSTD_compressBound.restype=ctypes.c_size_t
ZSTD.ZSTD_compress.argtypes=[ctypes.c_void_p,ctypes.c_size_t,ctypes.c_void_p,ctypes.c_size_t,ctypes.c_int]
ZSTD.ZSTD_compress.restype=ctypes.c_size_t
ZSTD.ZSTD_isError.argtypes=[ctypes.c_size_t];ZSTD.ZSTD_isError.restype=ctypes.c_uint

def compress(data):
    out=ctypes.create_string_buffer(ZSTD.ZSTD_compressBound(len(data)))
    n=ZSTD.ZSTD_compress(out,len(out),data,len(data),12)
    assert not ZSTD.ZSTD_isError(n)
    return base64.b64encode(out.raw[:n]).decode()

SHEETS=[
    ('anime-auras.png',2,4,['volt','vesper','boreal','ember','prism','astrolabe','maple','tide'],(256,112),'aura'),
    ('anime-frames.png',2,3,['brass','circuit','comet','facet','wings','rift'],(160,160),'frame'),
    ('anime-banners.png',2,4,['velvet','starmap','boreal','eclipse','horizon','tidal','geode','forge'],(320,128),'banner'),
]

def main():
    result={};preview=ROOT/'build/identity';preview.mkdir(parents=True,exist_ok=True)
    for filename,cols,rows,keys,size,kind in SHEETS:
        source=ROOT/'assets/identity'/filename;image=Image.open(source).convert('RGBA')
        for index,key in enumerate(keys):
            x,y=index%cols,index//cols
            box=(round(x*image.width/cols),round(y*image.height/rows),round((x+1)*image.width/cols),round((y+1)*image.height/rows))
            tile=image.crop(box)
            if kind!='banner':
                # Ignore near-zero background alpha when framing a sprite.
                bounds=tile.getchannel('A').point(lambda a:255 if a>18 else 0).getbbox()
                if bounds:
                    l,t,r,b=bounds
                    bounds=(max(0,l-4),max(0,t-4),min(tile.width,r+4),min(tile.height,b+4))
                    box=(box[0]+bounds[0],box[1]+bounds[1],box[0]+bounds[2],box[1]+bounds[3])
                    tile=tile.crop(bounds)
            tile=tile.resize(size,Image.Resampling.LANCZOS)
            name=kind+'_'+key;tile.save(preview/(name+'.png'))
            # Each GUI strip has <=16 gradient control points (Roblox max 20).
            fw,fh=(64,64)if kind=='frame'else(96,64)
            fallback=tile.resize((fw,fh),Image.Resampling.LANCZOS)
            strips=[]
            for row in range(fh):
                for col in range(0,fw,16):
                    pixels=[fallback.getpixel((px,row))for px in range(col,min(col+16,fw))]
                    if max(p[3]for p in pixels)<8:continue
                    strips.append([col,row,[r*16777216+g*65536+b*256+a for r,g,b,a in pixels]])
            raw=tile.tobytes()
            result[name]={'width':size[0],'height':size[1],'pixels':compress(raw),
                          'fallbackWidth':fw,'fallbackHeight':fh,'strips':strips,
                          'source':filename,'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),
                          'rect':box,'sha256':hashlib.sha256(raw).hexdigest()}
    (ROOT/'content/identity_art.json').write_text(json.dumps(result,separators=(',',':'))+'\n')
    print('Packed',len(result),'original identity illustrations;',sum(len(d['strips'])for d in result.values()),'fallback strips')

if __name__=='__main__':main()

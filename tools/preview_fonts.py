"""Optional local preview fonts, with renamed OFL/UFL subsets and licenses.

Roblox uses Enum.Font, not these files. No network requests in this module.
"""
import base64,io,json
from pathlib import Path

CACHE=Path('/tmp/proba-preview-fonts')

def prepare():
    manifest=CACHE/'manifest.json'
    if not manifest.exists():return {}
    from fontTools.ttLib import TTFont
    from fontTools import subset
    from fontTools.varLib.instancer import instantiateVariableFont
    result={}
    for index,(name,source)in enumerate(sorted(json.loads(manifest.read_text()).items()),1):
        path=Path(source['path']);ttf=CACHE/(name+'-preview-v2.ttf');woff=CACHE/(name+'-preview-v2.woff')
        if not woff.exists()or woff.stat().st_mtime<path.stat().st_mtime:
            font=TTFont(path)
            if 'fvar'in font:
                axes={a.axisTag:a.defaultValue for a in font['fvar'].axes}
                if 'wght'in axes:axes['wght']=600 if name=='FredokaOne'else 400
                if 'opsz'in axes:axes['opsz']=18
                instantiateVariableFont(font,axes,inplace=True)
            options=subset.Options();options.name_IDs=['*']
            selection=subset.Subsetter(options=options)
            selection.populate(unicodes=list(range(32,127))+list(range(0x400,0x530)))
            selection.subset(font)
            # Modified preview subsets do not retain reserved font family names.
            for record in font['name'].names:
                if record.nameID in (1,3,4,6):
                    value=('PROBAPreview'+str(index))if record.nameID==6 else('PROBA Preview '+str(index))
                    record.string=value.encode(record.getEncoding())
            font.save(ttf);font.flavor='woff';font.save(woff)
        result[name]={'ttf':ttf,'woff':woff,'license':Path(source['license']).read_text(),'url':source['url']}
    return result

def css(fonts):
    return ''.join('@font-face{font-family:"Preview_'+name+'";src:url(data:font/woff;base64,'+
                   base64.b64encode(d['woff'].read_bytes()).decode()+') format("woff");font-weight:400;font-style:normal;}'for name,d in fonts.items())

def metrics(fonts,names):
    from PIL import ImageFont
    result={}
    values=set()
    for name in names:
        for i in range(1,len(name)+1):values.add(name[:i])
        values.update(name)
    for name,d in fonts.items():
        font=ImageFont.truetype(str(d['ttf']),100)
        result['Font.'+name]={s:round(font.getlength(s)/100,6)for s in values}
    return result

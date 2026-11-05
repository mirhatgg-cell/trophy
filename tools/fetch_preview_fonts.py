"""Optional Google Fonts copies for external previews, never Roblox assets.

Uses the inherited HTTPS proxy/CA. Fonts and their OFL licenses stay in /tmp.
The game selects its own built-in Roblox Enum.Font faces independently.
"""
import concurrent.futures,json,re,urllib.parse,urllib.request
from pathlib import Path

OUT=Path('/tmp/proba-preview-fonts');OUT.mkdir(exist_ok=True)
FAMILIES={'Michroma':'michroma','GrenzeGotisch':'grenzegotisch','JosefinSans':'josefinsans','Bangers':'bangers',
          'FredokaOne':'fredokaone','Merriweather':'merriweather','Kalam':'kalam','Nunito':'nunito',
          'Jura':'jura','Ubuntu':'ubuntu','Oswald':'oswald','AmaticSC':'amaticsc'}
BASE='https://raw.githubusercontent.com/google/fonts/main/ofl/'

def fetch(entry):
    name,folder=entry
    try:
        saved=OUT/'manifest.json'
        cached=json.loads(saved.read_text())if saved.exists()else{}
        if name in cached and Path(cached[name]['path']).exists():return name,cached[name]
        prefix=BASE+folder+'/'
        if name=='Ubuntu':prefix=BASE.replace('/ofl/','/ufl/')+'ubuntu/'
        try:metadata=urllib.request.urlopen(prefix+'METADATA.pb',timeout=30).read().decode()
        except urllib.error.HTTPError:
            if name!='FredokaOne':raise
            folder='fredoka'
            prefix=BASE+folder+'/'
            metadata=urllib.request.urlopen(prefix+'METADATA.pb',timeout=30).read().decode()
        filenames=re.findall(r'filename: "([^"]+\.ttf)"',metadata)
        filename=next((f for f in filenames if 'Italic'not in f),filenames[0])
        assert Path(filename).name==filename
        url=prefix+urllib.parse.quote(filename)
        data=urllib.request.urlopen(url,timeout=30).read()
        license=urllib.request.urlopen(prefix+('UFL.txt'if name=='Ubuntu'else'OFL.txt'),timeout=30).read()
        (OUT/(name+'.ttf')).write_bytes(data);(OUT/(name+'-OFL.txt')).write_bytes(license)
        print(name,len(data),'bytes',flush=True)
        return name,{'path':str(OUT/(name+'.ttf')),'url':url,'license':str(OUT/(name+'-OFL.txt'))}
    except Exception as error:print(name,str(error),flush=True);return None

results={}
with concurrent.futures.ThreadPoolExecutor(max_workers=6)as pool:
    for result in pool.map(fetch,FAMILIES.items()):
        if result:results[result[0]]=result[1]
(OUT/'manifest.json').write_text(json.dumps(results,indent=2))

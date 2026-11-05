"""Offline constructor-based UI previews. This is not an engine screenshot; fonts/3D are approximated."""
import html,json
from pathlib import Path
from playwright.sync_api import sync_playwright
from preview_fonts import prepare,css
root=Path(__file__).resolve().parents[1]
preview_fonts=prepare();font_css=css(preview_fonts)
snapshots=json.loads((root/'build/ui-state.json').read_text())
def rgb(c,alpha=1):
    if not c:return 'transparent'
    return f'rgba({round(c["R"]*255)},{round(c["G"]*255)},{round(c["B"]*255)},{alpha})'
def keys(sequence):
    if not isinstance(sequence,list)or not sequence:return []
    if len(sequence)==1 and isinstance(sequence[0],list):return sequence[0]
    return [[i/max(1,len(sequence)-1),v]for i,v in enumerate(sequence)]
with sync_playwright()as p:
    browser=p.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox'])
    for state in snapshots:
        page=browser.new_page(viewport={'width':state['width'],'height':state['height']},device_scale_factor=1)
        blocks=[]
        for o in state['objects']:
            x,y,w,h=[o[k]for k in ('x','y','w','h')]
            if w<=0 or h<=0:continue
            clip=o['clip'];top=max(0,clip['y']-y);left=max(0,clip['x']-x);bottom=max(0,y+h-clip['y']-clip['h']);right=max(0,x+w-clip['x']-clip['w'])
            if top+bottom>=h or left+right>=w:continue
            style=f'left:{x}px;top:{y}px;width:{w}px;height:{h}px;background:{rgb(o.get("color"),1-o["alpha"])};color:{rgb(o.get("ink"))};font-size:{o["size"]}px;border-radius:{o["radius"]}px;z-index:{o["z"]};clip-path:inset({top}px {right}px {bottom}px {left}px);'
            if o.get('border'):style+=f'border:{o["thickness"]}px solid {rgb(o["border"],.6)};'
            align='left'if str(o.get('align','')).endswith('Left')else'center'
            bold='bold'if 'Bold'in str(o.get('font'))or'Black'in str(o.get('font'))else'normal'
            style+=f'text-align:{align};font-weight:{bold};'
            face=str(o.get('font','')).split('.')[-1]
            if face in preview_fonts:style+=f'font-family:"Preview_{face}",sans-serif;'
            if o.get('textAlpha'):style+=f'opacity:{(1-o["textAlpha"])*(1-o.get("groupAlpha",0))};'
            if o.get('textStroke')and o.get('strokeAlpha',1)<1:style+=f'text-shadow:0 1px 1px {rgb(o["textStroke"],1-o["strokeAlpha"])};'
            if not o.get('wrap'):style+='white-space:nowrap;text-overflow:ellipsis;'
            if o['rotation']:style+=f'transform:rotate({o["rotation"]}deg);'
            if o.get('groupAlpha'):style+=f'opacity:{1-o["groupAlpha"]};'
            if o.get('artwork')and o.get('backend')!='GuiPainting':
                import base64
                png=root/'build/identity'/(o['artwork']+'.png')
                uri=base64.b64encode(png.read_bytes()).decode()
                style+=f'background:url(data:image/png;base64,{uri}) 0 0/100% 100% no-repeat;opacity:{1-o.get("groupAlpha",0)};'
            g=o.get('gradient')
            if g:
                stops=','.join(f'{rgb(value)} {time*100}%'for time,value in keys(g.get('colors')))
                if stops:
                    if o['class']in ('TextLabel','TextButton','TextBox'):style+=f'background-image:linear-gradient({g["rotation"]+90}deg,{stops});background-clip:text;color:transparent;'
                    else:style+=f'background-image:linear-gradient({g["rotation"]+90}deg,{stops});'
                opacity=','.join(f'rgba(0,0,0,{1-value}) {time*100}%'for time,value in keys(g.get('alpha')))
                if opacity:style+=f'mask-image:linear-gradient({g["rotation"]+90}deg,{opacity});'
            content=html.escape(o.get('text','')).replace('\n','<br>')
            if o['class']=='ViewportFrame':content='<span style="opacity:.4;font-size:10px;color:#a0acb7">3D VIEWPORT / отображается движком Roblox</span>'
            blocks.append('<div style="'+style+'"><span>'+content+'</span></div>')
        source='<!doctype html><meta charset="utf-8"><style>'+font_css+'html,body{height:100%;margin:0;background:radial-gradient(ellipse at 50% 40%,#5a6572,#343f49);font-family:"DejaVu Sans",sans-serif}div{position:absolute;box-sizing:border-box;display:flex;align-items:center;overflow:hidden}div>span{width:100%;padding:0 3px;line-height:1.22}aside{position:absolute;left:44%;top:46%;width:28%;font-size:11px;color:#a0acb7;line-height:1.8}</style><aside>ПРОВЕРКА КОНСТРУКТОРОВ UI<br>Геометрия мира и эффекты 3D здесь не рендерятся.<br>Это не скриншот Roblox Studio.</aside>'+''.join(blocks)
        page.set_content(source);page.screenshot(path=str(root/f'build/ui-{state["name"]}.png'));page.close()
    browser.close()

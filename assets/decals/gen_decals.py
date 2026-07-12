#!/usr/bin/env python3
# Gera as placas/grafites brasileiros como PNG para virar decals no Roblox.
import os, math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

OUT = "/private/tmp/claude-501/-Users-willianbatista/3a5429f0-6508-43ea-8c86-3132b0d1f1f3/scratchpad/decals"
os.makedirs(OUT, exist_ok=True)

IMPACT = "/System/Library/Fonts/Supplemental/Impact.ttf"
BLACK  = "/System/Library/Fonts/Supplemental/Arial Black.ttf"
ARIAL  = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
UNI    = "/System/Library/Fonts/Supplemental/Arial Unicode.ttf"
COMIC  = "/System/Library/Fonts/Supplemental/Comic Sans MS Bold.ttf"

def font(path, size):
    return ImageFont.truetype(path, size)

def ctext(d, cx, y, text, ft, fill, outline=None, ow=0, anchor_mid=True):
    bb = d.textbbox((0,0), text, font=ft)
    w = bb[2]-bb[0]; h = bb[3]-bb[1]
    x = cx - w/2 - bb[0] if anchor_mid else cx
    if outline and ow:
        for dx in range(-ow, ow+1):
            for dy in range(-ow, ow+1):
                if dx*dx+dy*dy <= ow*ow:
                    d.text((x+dx, y+dy), text, font=ft, fill=outline)
    d.text((x, y), text, font=ft, fill=fill)
    return w, h

# ---------------------------------------------------------------- KIBOÇÃO LANCHES
def kibocao():
    W,H = 1024, 560
    img = Image.new("RGBA",(W,H),(0,0,0,0))
    d = ImageDraw.Draw(img)
    # painel laranja com borda
    d.rounded_rectangle([10,10,W-10,H-10], radius=30, fill=(232,120,28,255), outline=(120,50,10,255), width=8)
    d.rounded_rectangle([28,28,W-28,H-28], radius=22, outline=(255,200,90,255), width=5)
    # hamburguer mascote (formas simples)
    ccx, ccy, r = 250, 200, 120
    # pão de cima
    d.pieslice([ccx-r, ccy-r, ccx+r, ccy+r+40], 180, 360, fill=(214,150,70,255), outline=(120,70,20,255), width=5)
    # gergelim
    for gx,gy in [(-45,-70),(0,-88),(45,-70),(-20,-55),(22,-55)]:
        d.ellipse([ccx+gx-6,ccy+gy-4,ccx+gx+6,ccy+gy+4], fill=(255,235,180,255))
    # alface
    d.rectangle([ccx-r, ccy+8, ccx+r, ccy+28], fill=(90,170,60,255))
    for i in range(-r, r, 24):
        d.polygon([(ccx+i,ccy+8),(ccx+i+12,ccy-8),(ccx+i+24,ccy+8)], fill=(120,200,80,255))
    # carne
    d.rectangle([ccx-r, ccy+28, ccx+r, ccy+58], fill=(90,45,20,255))
    # pão de baixo
    d.pieslice([ccx-r, ccy+30, ccx+r, ccy+r+70], 0, 180, fill=(214,150,70,255), outline=(120,70,20,255), width=5)
    # olhos + sorriso do mascote
    d.ellipse([ccx-55,ccy-25,ccx-20,ccy+10], fill=(255,255,255,255), outline=(60,30,10,255), width=4)
    d.ellipse([ccx+20,ccy-25,ccx+55,ccy+10], fill=(255,255,255,255), outline=(60,30,10,255), width=4)
    d.ellipse([ccx-42,ccy-16,ccx-28,ccy-2], fill=(30,20,10,255))
    d.ellipse([ccx+30,ccy-16,ccx+44,ccy-2], fill=(30,20,10,255))
    # texto
    ctext(d, 640, 90,  "KIBOÇÃO", font(IMPACT,150), (255,240,120,255), (90,40,5,255), 6)
    ctext(d, 640, 250, "LANCHES", font(IMPACT,120), (255,255,255,255), (90,40,5,255), 6)
    ctext(d, 512, 430, "★ PIX E DELIVERY ★", font(BLACK,64), (255,240,120,255), (120,20,10,255), 3)
    img.save(f"{OUT}/kibocao_lanches.png")

# ---------------------------------------------------------------- PIX E DELIVERY (faixa toldo)
def pix_delivery():
    W,H = 1024, 240
    img = Image.new("RGBA",(W,H),(200,30,25,255))
    d = ImageDraw.Draw(img)
    d.rectangle([0,0,W,18], fill=(150,15,12,255))
    d.rectangle([0,H-18,W,H], fill=(150,15,12,255))
    ctext(d, 512, 55, "PIX E DELIVERY", font(IMPACT,120), (255,240,120,255), (90,10,8,255), 5)
    img.save(f"{OUT}/pix_delivery.png")

# ---------------------------------------------------------------- CORUJÃO LAN HOUSE
def corujao():
    W,H = 1024, 560
    img = Image.new("RGBA",(W,H),(0,0,0,0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([10,10,W-10,H-10], radius=28, fill=(30,80,175,255), outline=(15,40,95,255), width=8)
    # coruja simples
    ox,oy = 210, 210
    d.ellipse([ox-120,oy-110,ox+120,oy+130], fill=(150,110,60,255), outline=(80,55,25,255), width=6)
    d.ellipse([ox-95,oy-90,ox-5,oy+0], fill=(255,255,255,255), outline=(80,55,25,255), width=5)
    d.ellipse([ox+5,oy-90,ox+95,oy+0], fill=(255,255,255,255), outline=(80,55,25,255), width=5)
    d.ellipse([ox-70,oy-70,ox-30,oy-30], fill=(40,30,15,255))
    d.ellipse([ox+30,oy-70,ox+70,oy-30], fill=(40,30,15,255))
    d.polygon([(ox-14,oy-20),(ox+14,oy-20),(ox,oy+18)], fill=(240,170,40,255), outline=(120,80,10,255))
    ctext(d, 660, 100, "CORUJÃO", font(IMPACT,150), (255,255,255,255), (10,25,70,255), 6)
    ctext(d, 660, 270, "LAN HOUSE", font(BLACK,80), (255,220,60,255), (10,25,70,255), 4)
    ctext(d, 512, 430, "INTERNET · XEROX · IMPRESSÃO", font(ARIAL,52), (235,240,255,255), (10,25,70,255), 2)
    img.save(f"{OUT}/corujao_lanhouse.png")

# ---------------------------------------------------------------- BANDEIRA DO BRASIL (geométrica)
def bandeira():
    W,H = 1000, 700
    img = Image.new("RGBA",(W,H),(0,0,0,0))
    d = ImageDraw.Draw(img)
    green=(0,151,57,255); yellow=(255,223,0,255); blue=(0,39,118,255); white=(255,255,255,255)
    d.rectangle([0,0,W,H], fill=green)
    mx,my = W/2, H/2
    # losango
    dx = W*0.20; dy = H*0.20*(W/H)  # manter margem ~1.7
    dx = (W/2) - W*0.085*2
    dyv = (H/2) - H*0.085*2
    d.polygon([(mx,my-dyv),(mx+dx,my),(mx,my+dyv),(mx-dx,my)], fill=yellow)
    # círculo azul
    R = H*0.26
    d.ellipse([mx-R,my-R,mx+R,my+R], fill=blue)
    # faixa branca (arco) — aproximação com retângulo curvo
    d.arc([mx-R,my-R+10,mx+R,my+R+10], 20, 160, fill=white, width=int(H*0.045))
    ctext(d, int(mx), int(my-8), "ORDEM E PROGRESSO", font(ARIAL,26), white)
    # estrelas (algumas)
    import random
    random.seed(7)
    for _ in range(22):
        a = random.uniform(0,2*math.pi); rr=random.uniform(0.15,0.9)*R
        sx,sy = mx+math.cos(a)*rr, my+math.sin(a)*rr
        s=random.choice([2,3,3,4,5])
        d.ellipse([sx-s,sy-s,sx+s,sy+s], fill=white)
    img.save(f"{OUT}/bandeira_brasil.png")

# ---------------------------------------------------------------- PLACA DE RUA
def placa_rua():
    W,H = 1024, 300
    img = Image.new("RGBA",(W,H),(0,0,0,0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([12,12,W-12,H-12], radius=18, fill=(20,70,150,255), outline=(255,255,255,255), width=10)
    ctext(d, 512, 60, "RUA DA PAZ", font(ARIAL,110), (255,255,255,255))
    ctext(d, 512, 200, "COMPLEXO · 05253-030", font(ARIAL,44), (210,225,255,255))
    img.save(f"{OUT}/placa_rua.png")

# ---------------------------------------------------------------- PIXAÇÃO (reta, tipo tag)
def pixacao(name, txt, color=(20,20,20,255)):
    W,H = 900, 400
    img = Image.new("RGBA",(W,H),(0,0,0,0))
    d = ImageDraw.Draw(img)
    ft = font(IMPACT, 260)
    # letras esticadas e um pouco inclinadas
    ctext(d, 450, 60, txt, ft, color, (color[0],color[1],color[2],120), 2)
    img = img.rotate(-6, expand=True, resample=Image.BICUBIC)
    img.save(f"{OUT}/{name}.png")

# ---------------------------------------------------------------- GRAFITE BOLHA (throw-up)
def grafite_bolha(name, txt, fill=(60,150,230,255), outline=(15,30,90,255)):
    W,H = 1000, 500
    img = Image.new("RGBA",(W,H),(0,0,0,0))
    d = ImageDraw.Draw(img)
    ft = font(IMPACT, 300)
    # sombra
    ctext(d, 520, 90, txt, ft, (0,0,0,120))
    # contorno grosso (bolha)
    ctext(d, 500, 80, txt, ft, fill, outline, 12)
    # brilho
    ctext(d, 494, 72, txt, ft, tuple(min(255,c+60) for c in fill[:3])+(255,), None, 0)
    ctext(d, 500, 80, txt, ft, fill, outline, 10)
    img.save(f"{OUT}/{name}.png")

# ---------------------------------------------------------------- PERDEU A CHAVE (chaveiro)
def chaveiro():
    W,H = 700, 500
    img = Image.new("RGBA",(W,H),(235,225,60,255))
    d = ImageDraw.Draw(img)
    d.rectangle([0,0,W,H], outline=(40,40,40,255), width=14)
    ctext(d, 350, 40,  "PERDEU A", font(BLACK,90), (20,20,20,255))
    ctext(d, 350, 150, "CHAVE?", font(IMPACT,150), (200,30,25,255), (20,20,20,255),3)
    ctext(d, 350, 330, "CHAVEIRO 24H", font(BLACK,64), (20,20,20,255))
    img.save(f"{OUT}/perdeu_chave.png")

# ---------------------------------------------------------------- LANCHONETE DO ZÉ
def boteco():
    W,H = 1024, 420
    img = Image.new("RGBA",(W,H),(0,0,0,0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([10,10,W-10,H-10], radius=24, fill=(200,40,35,255), outline=(255,230,60,255), width=10)
    ctext(d, 512, 30,  "LANCHONETE", font(IMPACT,160), (255,230,60,255), (60,10,8,255),5)
    ctext(d, 512, 215, "DO ZÉ", font(IMPACT,180), (255,230,60,255), (60,10,8,255),5)
    img.save(f"{OUT}/bar_do_ze.png")

kibocao()
pix_delivery()
corujao()
bandeira()
placa_rua()
grafite_bolha("grafite_paz", "PAZ", (90,200,120,255), (10,60,25,255))
grafite_bolha("grafite_zn", "ZONA", (230,120,60,255), (90,30,10,255))
chaveiro()
boteco()

print("Gerados:")
for f in sorted(os.listdir(OUT)):
    p=os.path.join(OUT,f)
    print(f"  {f}  ({os.path.getsize(p)//1024} KB)")

"""Generate technical reference PNGs only; never writes to game resources."""
from pathlib import Path
import hashlib
import json
import re
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
source = (ROOT / "src/features/scriptorium/page_layout.lua").read_text(encoding="utf-8")

def values(body):
    return {key: int(value) for key, value in re.findall(r"(\w+)\s*=\s*(\d+)", body)}

page = values(re.search(r"local page = \{([^}]+)\}", source)[1])
grid = values(re.search(r"local grid = \{([^}]+)\}", source)[1])
def rect(name):
    body = re.search(r"\b" + name + r" = \{([^}]+)\}", source)[1]
    v = values(body)
    return tuple(v[k] for k in ("x", "y", "w", "h"))

layers = {name: rect(name) for name in ("background", "desk", "lectern")}
layers["parchment"] = tuple(page[k] for k in ("x", "y", "w", "h"))
ui = {name: rect(name) for name in ("commission", "glosses", "dock", "actions", "tray")}
gx, gy = page["x"] + grid["x"], page["y"] + grid["y"]
gw = grid["cols"] * grid["cell"] + (grid["cols"]-1)*grid["gap"]
gh = grid["rows"] * grid["cell"] + (grid["rows"]-1)*grid["gap"]
assert (gx, gy, gw, gh) == (686, 168, 548, 436), "Update written specification for changed layout"
reserves = {
    "header": (650,78,620,78),
    "grid_margin": (gx-8,gy-8,gw+16,gh+16),
    "row_labels": (617,196,66,406),
    "dice_caption": (540,1040,840,38),
}
paths = ["src/features/scriptorium/page_layout.lua", "src/features/scriptorium/desk_view.lua",
         "src/features/scriptorium/module.lua", "src/data/scriptorium_module_config.lua", "main.lua"]
hashes = {p: hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in paths}

CYAN = (88,213,247,255)
GOLD = (249,195,93,255)
GREEN = (141,225,174,255)
PINK = (242,128,201,255)
WHITE = (240,245,252,255)
font_path = "C:/Windows/Fonts/arial.ttf"
fonts = {s: ImageFont.truetype(font_path,s) for s in (16,18,20,22,24)}

def build(transparent=False):
    im = Image.new("RGBA",(1920,1080),(0,0,0,0) if transparent else (22,31,44,255))
    d = ImageDraw.Draw(im)
    def box(r,color,fill=None,width=2):
        x,y,w,h=r
        d.rectangle((x,y,x+w-1,y+h-1),outline=color,fill=fill,width=width)
    def label(x,y,lines,color=WHITE,size=18):
        text="\n".join(lines)
        bounds=d.multiline_textbbox((x,y),text,font=fonts[size],spacing=5)
        d.rectangle((bounds[0]-5,bounds[1]-4,bounds[2]+5,bounds[3]+4),fill=(22,31,44,245))
        d.multiline_text((x,y),text,font=fonts[size],fill=color,spacing=5)
    def dashed(r,color):
        x,y,w,h=r
        for a in range(x,x+w,16):
            for b in (y,y+h-1): d.line((a,b,min(a+8,x+w-1),b),fill=color,width=2)
        for b in range(y,y+h,16):
            for a in (x,x+w-1): d.line((a,b,a,min(b+8,y+h-1)),fill=color,width=2)
    def tint(color):
        return None if transparent else color
    box(layers["background"],CYAN,width=3)
    box(layers["desk"],CYAN,tint((43,39,35,255)),3)
    box(layers["lectern"],CYAN,tint((35,49,62,255)),3)
    if not transparent:
        d.polygon([(570,48),(1350,48),(1410,642),(510,642)],fill=(54,54,49,255))
        d.rectangle((508,636,1411,659),fill=(70,60,45,255))
    box(layers["parchment"],CYAN,tint((55,62,65,255)),3)
    for key in ("commission","glosses","dock","actions"):
        box(ui[key],GOLD,tint((49,48,45,255)),3)
    box(ui["tray"],GOLD,tint((41,50,52,255)),3)
    for r in reserves.values(): dashed(r,PINK)
    for row in range(grid["rows"]):
        for col in range(grid["cols"]):
            x=gx+col*(grid["cell"]+grid["gap"])
            y=gy+row*(grid["cell"]+grid["gap"])
            box((x,y,grid["cell"],grid["cell"]),GREEN,tint((34,54,52,255)))
            d.text((x+10,y+12),f"R{row+1} C{col+1}",fill=GREEN,font=fonts[18])
            d.text((x+10,y+68),f"{x},{y}",fill=WHITE,font=fonts[16])
    label(22,12,["SCRIPTORIUM / GUIDA KRITA", "1 SFONDO  (0,0)  1920 x 1080"],CYAN,20)
    label(1460,18,["Coordinate globali in pixel", "Origine (0,0) in alto a sinistra"],WHITE,18)
    label(488,62,["3 LEGGIO", "(480,48)", "960 x 612"],CYAN,18)
    label(700,82,["4 PERGAMENA  (610,62)  700 x 568", "Titolo e istruzione: riserva tratteggiata"],CYAN,18)
    label(696,141,["GRIGLIA (686,168)  548 x 436"],GREEN,16)
    label(700,612,["Casella 100 x 100  |  spazio 12  |  passo 112"],GREEN,16)
    label(100,140,["COMMISSIONE / INCHIOSTRI", "(80,116)  420 x 510", "Overlay UI: non dipingere il contenuto"],GOLD,18)
    label(1440,140,["GLOSSE / ANTEPRIMA", "(1420,116)  420 x 510", "Overlay UI: non dipingere il contenuto"],GOLD,18)
    label(22,653,["2 BANCO  (0,650)  1920 x 430"],CYAN,18)
    label(96,704,["TAVOLOZZA / BUFFER", "(80,682)  420 x 236", "Riserva per i comandi"],GOLD,18)
    label(1436,704,["AZIONI", "(1420,682)  420 x 180", "Riserva per i comandi"],GOLD,18)
    label(552,685,["REGIONE DADI 3D  (530,666)  860 x 404", "Riservare tutto il rettangolo; non dipingere dadi o vassoio"],GOLD,18)
    label(550,1047,["Testo dadi: stampa a (540,1046), larghezza 840"],PINK,16)
    label(32,956,["CIANO = rettangoli dei 4 PNG", "ORO = regioni UI / renderer 3D", "VERDE = caselle reali", "MAGENTA = rispetto artistico consigliato"],WHITE,18)
    label(1436,905,["GUIDA TECNICA, NON ASSET", "Documento esatto: 1920 x 1080", "Non ridimensionare in Krita.", "Nascondere la guida prima dell'export."],WHITE,18)
    if not transparent:
        im.putalpha(255)
    return im

for transparent,name in [(False,"layout-guide-1920x1080.png"),(True,"layout-overlay-1920x1080.png")]:
    im=build(transparent)
    im.save(OUT/name)
    with Image.open(OUT/name) as check:
        assert check.size==(1920,1080) and check.mode=="RGBA"
        if transparent: assert check.getpixel((20,500))[3]==0
        else: assert check.getextrema()[3]==(255,255)

(OUT/"layout-coordinates.json").write_text(json.dumps({
    "canvas": [1920,1080], "layers": layers, "ui":ui,
    "grid": {"bounds":[gx,gy,gw,gh],"rows":4,"columns":5,"cell":100,"gap":12},
    "recommended_reserves_not_hitboxes":reserves, "source_sha256":hashes,
},indent=2),encoding="utf-8")
assert hashes=={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in paths}
print("Verified: two 1920x1080 RGBA guides, transparent overlay, coordinates from Lua; game sources unchanged.")

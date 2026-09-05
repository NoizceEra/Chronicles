"""
generate_tiles_25d_v2.py — HIGH-FIDELITY 2.5D tile rebuild
Fixes: flat walls, mud-cliff faces, plastic props, checker grass.
Techniques: bevel highlight (top/left), AO shadow, mortar grooves,
noise dithering, overhang lip, vertical grass blades, wood grain.
Output: assets/tiles/25d_v2/ + assets/sprites/25d_v2 + web mirror
Run: python3 scripts/generate_tiles_25d_v2.py
"""
import os, random
from PIL import Image, ImageDraw

random.seed(1337)

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_T = os.path.join(BASE, "assets", "tiles", "25d_v2")
OUT_S = os.path.join(BASE, "assets", "sprites", "25d_v2")
OUT_W = os.path.join(BASE, "web", "assets", "25d_v2")
for d in [OUT_T, OUT_S, OUT_W]:
    os.makedirs(d, exist_ok=True)

P = {
    "outline": (24,20,37,255),
    "mid_gray": (88,97,122,255),
    "light_gray": (148,161,178,255),
    "white": (245,247,250,255),
    "steel_mid": (100,120,150,255),
    "steel_light": (180,200,225,255),
    "brown_dark": (55,35,25,255),
    "brown_mid": (115,70,45,255),
    "brown_light": (175,115,75,255),
    "emerald_dark": (15,75,45,255),
    "emerald_mid": (35,150,80,255),
    "emerald_light": (90,220,130,255),
    "gold_mid": (235,175,35,255),
    "grass_dark": (28,68,32,255),
    "grass_mid": (52,118,48,255),
    "grass_light": (92,170,78,255),
    "dirt_dark": (68,44,30,255),
    "dirt_mid": (105,72,46,255),
    "dirt_light": (142,102,68,255),
    "stone_dark": (52,58,72,255),
    "stone_mid": (88,97,122,255),
    "stone_light": (138,153,172,255),
    "shadow": (15,15,20,255),
}

def dr(c, f=0.6): return (int(c[0]*f), int(c[1]*f), int(c[2]*f), 255)
def li(c, f=1.28): return (min(255,int(c[0]*f)), min(255,int(c[1]*f)), min(255,int(c[2]*f)), 255)

def noise_sprinkle(img, rect, col, density=0.08):
    d=ImageDraw.Draw(img)
    x0,y0,x1,y1=rect
    for _ in range(int((x1-x0)*(y1-y0)*density)):
        x=random.randint(x0,x1-1); y=random.randint(y0,y1-1)
        d.point((x,y), fill=col)

def make_wall_v2(name, top_rgb, mortar_rgb):
    """32x48 slice: top 32x32 beveled bricks + 16px side face with depth"""
    img=Image.new("RGBA",(32,48),(0,0,0,0))
    d=ImageDraw.Draw(img)
    # --- Top face 0,0-31,31 ---
    # base with subtle vignette
    d.rectangle([0,0,31,31], fill=top_rgb, outline=P["outline"])
    # brick rows 3 courses of 10px + mortar 1px, staggered
    brick_col = li(top_rgb,1.06)
    gap = dr(mortar_rgb,0.85)
    for row in range(3):
        y0=row*10
        y1=y0+9
        offset = 8 if row%2 else 0
        # mortar horizontal
        if row>0:
            d.rectangle([0,y0-1,31,y0], fill=gap)
            # AO: darken bottom pixel of brick above mortar
            d.rectangle([0,y0-1,31,y0-1], fill=dr(gap,0.75))
        cols = [-8,0,8,16,24] if offset else [0,8,16,24]
        for cx in cols:
            if cx==-8:
                x0,x1=0,7
            else:
                x0,x1=cx,cx+7
            if x1>31: x1=31
            d.rectangle([x0,y0,x1,y1], fill=brick_col, outline=gap)
            # highlight top edge of brick (1px)
            d.line([x0,y0,x1,y0], fill=li(brick_col,1.45))
            # highlight left edge
            d.line([x0,y0,x0,y1], fill=li(brick_col,1.35))
            # AO bottom edge inside brick
            d.line([x0,y1,x1,y1], fill=dr(brick_col,0.82))
            # speckle
            noise_sprinkle(img,[x0+1,y0+2,x1,y1],dr(brick_col,0.92),0.04)
            noise_sprinkle(img,[x0+1,y0+1,x1,y1],li(brick_col,1.12),0.03)
        # vertical mortar
        for cx in cols:
            if cx==-8 or cx==0: continue
            if cx>=32: continue
            d.rectangle([cx-1,y0,cx,y1], fill=gap)
    # outer top bevel (2px TL highlight, bottom-right shadow)
    d.rectangle([1,1,30,2], fill=li(top_rgb,1.55))   # top highlight
    d.rectangle([1,1,2,30], fill=li(top_rgb,1.45))   # left highlight
    d.rectangle([1,29,30,30], fill=dr(top_rgb,0.72))
    d.rectangle([29,1,30,30], fill=dr(top_rgb,0.68))
    # --- Side face 0,32-31,47: 16px extrusion ---
    side_mid = dr(top_rgb,0.52)
    side_dark = dr(top_rgb,0.34)
    side_light = li(dr(top_rgb,0.55),1.25)
    d.rectangle([0,32,31,47], fill=side_mid)
    # top lip line (bevel between top and side - thin dark + highlight under)
    d.rectangle([0,32,31,32], fill=dr(top_rgb,0.48))
    d.rectangle([0,33,31,33], fill=side_light)
    # vertical grooves matching brick columns (shared mortar lines)
    for cx in [8,16,24]:
        d.rectangle([cx-1,32,cx,47], fill=side_dark)
        d.rectangle([cx,32,cx,47], fill=li(side_dark,1.6))
    # stone course lines on side (horizontal mortar scaled)
    for y in [38,43]:
        d.rectangle([0,y,31,y], fill=side_dark)
        d.rectangle([0,y+1,31,y+1], fill=side_light)
    # bottom contact shadow (2px)
    d.rectangle([0,46,31,47], fill=(0,0,0,90))
    # corner AO
    d.rectangle([0,32,0,47], fill=(0,0,0,45))
    d.rectangle([31,32,31,47], fill=(0,0,0,45))
    return img

def make_cliff_v2(kind):
    """32x48 combined: top 32x32 with grass overhang lip + side 16px layered strata"""
    top=Image.new("RGBA",(32,32),(0,0,0,0))
    d=ImageDraw.Draw(top)
    if kind=="grass":
        mid, light, dark = P["grass_mid"], P["grass_light"], P["grass_dark"]
        soil, soil_dark = P["dirt_mid"], P["dirt_dark"]
    elif kind=="dirt":
        mid, light, dark = P["dirt_mid"], P["dirt_light"], P["dirt_dark"]
        soil, soil_dark = (90,64,42,255), (50,32,20,255)
    else:
        mid, light, dark = P["stone_mid"], P["stone_light"], P["stone_dark"]
        soil, soil_dark = (62,68,80,255), (38,42,52,255)

    # top fill with noisy grass / stone
    d.rectangle([0,0,31,31], fill=mid)
    # subtle diagonal tiling texture
    for i in range(0,32,4):
        d.line([i,0,i+4,4], fill=dr(mid,0.94))
        d.line([i+2,0,i+6,4], fill=li(mid,1.08))
    noise_sprinkle(top,[0,0,32,32],dr(mid,0.9),0.06)
    noise_sprinkle(top,[0,0,32,32],li(mid,1.12),0.05)
    if kind=="grass":
        # grass tufts on top edge & scattered
        for x in [3,9,15,21,27]:
            # overhang blades hanging over south edge (y 28-31)
            d.rectangle([x,27,x+1,31], fill=P["emerald_light"])
            d.rectangle([x+1,28,x+2,30], fill=P["emerald_mid"])
        # random sprouts
        for _ in range(10):
            x=random.randint(2,29); y=random.randint(4,20)
            d.rectangle([x,y,x+1,y+3], fill=P["emerald_light"])
            d.rectangle([x,y+2,x,y+3], fill=P["emerald_dark"])
        # highlight top
        d.rectangle([1,1,30,2], fill=li(mid,1.5))
        d.rectangle([1,1,2,6], fill=li(mid,1.45))
    else:
        # rocks/pebbles
        for _ in range(14):
            x=random.randint(2,28); y=random.randint(2,28)
            sz=random.randint(1,2)
            d.rectangle([x,y,x+sz,y+sz], fill=dr(mid,0.78))
            d.rectangle([x,y,x,y], fill=li(mid,1.35))
    # south edge overhang shadow line (2px dark under lip)
    d.rectangle([0,30,31,31], fill=(0,0,0,65))
    d.rectangle([0,31,31,31], fill=(0,0,0,50))
    # side face 32x16
    face=Image.new("RGBA",(32,16),(0,0,0,0))
    f=ImageDraw.Draw(face)
    # layered strata: top 4px = grass overhang root line, then topsoil 4px, clay 4px, stone 4px
    # root fringe
    f.rectangle([0,0,31,3], fill=dr(P["emerald_dark"],0.9) if kind=="grass" else soil_dark)
    if kind=="grass":
        for x in range(0,32,3):
            l=random.randint(2,4)
            f.rectangle([x,1,x+1,l], fill=li(P["emerald_mid"],1.1))
    # layer 1: dark topsoil / dirt
    f.rectangle([0,4,31,7], fill=soil_dark)
    f.rectangle([0,4,31,4], fill=li(soil_dark,1.25))
    noise_sprinkle(face,[0,4,32,8],li(soil_dark,1.15),0.08)
    # crack
    f.line([10,4,10,7], fill=(0,0,0,35))
    f.line([22,4,22,7], fill=(0,0,0,35))
    # layer 2: mid soil / clay
    f.rectangle([0,8,31,11], fill=soil)
    f.rectangle([0,8,31,8], fill=li(soil,1.22))
    f.rectangle([0,11,31,11], fill=dr(soil,0.82))
    noise_sprinkle(face,[0,8,32,12],dr(soil,0.9),0.07)
    f.line([7,8,7,11], fill=(0,0,0,28))
    f.line([19,8,19,11], fill=(0,0,0,28))
    # layer 3: base stone
    base = P["stone_mid"] if kind=="stone" else dr(soil,0.75)
    f.rectangle([0,12,31,15], fill=base)
    f.rectangle([0,12,31,12], fill=li(base,1.25))
    f.rectangle([0,15,31,15], fill=(0,0,0,55))
    # pebbles in base
    for x in [4,13,24]:
        f.rectangle([x,13,x+1,14], fill=li(base,1.4))
    # vertical cracks across all layers
    f.rectangle([15,4,16,15], fill=(0,0,0,22))
    # combine
    combined=Image.new("RGBA",(32,48),(0,0,0,0))
    combined.alpha_composite(top,(0,0))
    combined.alpha_composite(face,(0,32))
    return top, face, combined

def make_props_v2():
    out={}
    # --- Crate v2 : 32x40 with wood grain + metal bands + side face ---
    for variant, base, accent, nail in [
        ("crate", P["brown_mid"], P["brown_dark"], P["gold_mid"]),
        ("crate_metal", P["stone_mid"], P["stone_dark"], P["brown_mid"]),
    ]:
        img=Image.new("RGBA",(32,40),(0,0,0,0))
        d=ImageDraw.Draw(img)
        top_y=6; h=16  # box body y
        # body
        d.rectangle([6,top_y,26,top_y+h], fill=base, outline=P["outline"])
        # planks (2 horizontal bands)
        for yy in [top_y+5, top_y+11]:
            d.rectangle([6,yy,26,yy+1], fill=dr(base,0.55))
            d.rectangle([6,yy+1,26,yy+1], fill=li(base,1.18))
        # vertical plank seam
        d.rectangle([14,top_y,15,top_y+h], fill=dr(base,0.62))
        d.rectangle([15,top_y,16,top_y+h], fill=li(base,1.12))
        # wood grain lines
        for y in [top_y+2,top_y+8,top_y+13]:
            grain=dr(base,0.85) if y%2 else li(base,1.08)
            d.line([7,y,25,y], fill=grain)
        # nails
        for x,y in [(8,top_y+2),(20,top_y+2),(8,top_y+7),(20,top_y+7),(8,top_y+13),(20,top_y+13)]:
            d.ellipse([x,y,x+2,y+2], fill=nail, outline=dr(nail,0.6))
            d.point((x+1,y+1), fill=li(nail,1.6))
        # metal bands if metal variant
        if "metal" in variant:
            d.rectangle([6,top_y+4,26,top_y+6], fill=dr(P["steel_mid"],0.85), outline=P["outline"])
            d.rectangle([6,top_y+10,26,top_y+12], fill=dr(P["steel_mid"],0.85), outline=P["outline"])
        # side face 8px below body
        d.rectangle([6,top_y+h,26,top_y+h+8], fill=dr(base,0.58), outline=dr(P["outline"],0.85))
        # side grain
        d.rectangle([14,top_y+h,15,top_y+h+8], fill=dr(base,0.45))
        # bottom shadow ellipse
        d.ellipse([7,30,25,34], fill=(0,0,0,75))
        out[variant]=img
    # --- Column v2 : 32x48 fluted shaft + capital + base with AO ---
    col=Image.new("RGBA",(32,48),(0,0,0,0))
    d=ImageDraw.Draw(col)
    # base slab 2px highlight
    d.rectangle([6,36,26,40], fill=P["stone_light"], outline=P["outline"])
    d.rectangle([7,37,25,38], fill=P["light_gray"])
    d.rectangle([6,36,26,37], fill=li(P["stone_light"],1.45))  # top highlight
    # shaft 10..36
    shaft_top=10; shaft_bot=36
    d.rectangle([9,shaft_top,23,shaft_bot], fill=P["stone_mid"], outline=P["outline"])
    d.rectangle([10,shaft_top+1,22,shaft_top+2], fill=li(P["stone_mid"],1.4)) # top light
    # fluting: 5 grooves
    for gx in [10,13,16,19,22]:
        d.rectangle([gx,shaft_top,gx,shaft_bot], fill=dr(P["stone_mid"],0.78))
        d.rectangle([gx+1,shaft_top,gx+1,shaft_bot], fill=li(P["stone_mid"],1.18))
    # center highlight ridge
    d.rectangle([15,shaft_top,17,shaft_bot], fill=li(P["stone_mid"],1.12))
    # capital
    d.rectangle([7,6,25,10], fill=P["stone_light"], outline=P["outline"])
    d.rectangle([8,7,24,9], fill=li(P["stone_light"],1.15))
    d.rectangle([5,2,27,6], fill=P["light_gray"], outline=P["outline"])
    d.rectangle([6,3,26,5], fill=li(P["light_gray"],1.1))
    # gold inlay on top
    d.rectangle([12,0,20,2], fill=P["gold_mid"], outline=dr(P["gold_mid"],0.6))
    # contact shadow
    d.ellipse([8,41,24,45], fill=(0,0,0,90))
    out["column"]=col
    # --- Stump v2 : 32x40 with rings + bark ---
    st=Image.new("RGBA",(32,40),(0,0,0,0))
    d=ImageDraw.Draw(st)
    d.ellipse([6,28,26,34], fill=(0,0,0,70))  # ground AO
    # trunk cylinder
    d.rectangle([7,14,25,28], fill=P["brown_mid"], outline=P["outline"])
    # bark vertical ridges
    for x in [9,13,17,21]:
        d.rectangle([x,14,x,28], fill=dr(P["brown_mid"],0.7))
        d.rectangle([x+1,14,x+1,28], fill=li(P["brown_mid"],1.15))
    # top cap ellipse
    d.ellipse([5,6,27,20], fill=P["brown_dark"], outline=P["outline"])
    d.ellipse([7,8,25,18], fill=P["brown_mid"])
    d.ellipse([8,9,24,17], fill=li(P["brown_mid"],1.18))
    # growth rings
    d.ellipse([10,9,22,16], fill=dr(P["brown_mid"],0.82), outline=dr(P["brown_dark"],0.9))
    d.ellipse([12,10,20,15], fill=li(P["brown_mid"],1.08))
    d.ellipse([14,11,18,14], fill=dr(P["brown_mid"],0.88))
    d.ellipse([15,12,17,13], fill=(25,15,10,255))
    # moss on north side
    d.ellipse([6,10,10,16], fill=P["emerald_dark"])
    d.ellipse([22,11,26,15], fill=P["emerald_dark"])
    out["stump"]=st
    # --- Bush v2 : 32x32 layered canopy with highlight ---
    bu=Image.new("RGBA",(32,32),(0,0,0,0))
    d=ImageDraw.Draw(bu)
    # shadow contact
    d.ellipse([8,24,24,28], fill=(0,0,0,70))
    # base dark mass
    d.ellipse([3,11,29,27], fill=P["emerald_dark"], outline=P["outline"])
    # mid mass
    d.ellipse([6,13,18,25], fill=P["emerald_mid"])
    d.ellipse([13,9,27,23], fill=li(P["emerald_mid"],1.12))
    # highlight blobs
    d.ellipse([9,10,17,18], fill=P["emerald_light"])
    d.ellipse([18,12,25,19], fill=li(P["emerald_light"],1.1))
    # leaf clusters highlights
    for x,y in [(8,14),(12,11),(19,10),(22,14),(15,18)]:
        d.ellipse([x,y,x+4,y+4], fill=li(P["grass_light"],1.15))
    # outline berries/flowers?
    d.ellipse([14,15,16,17], fill=P["white"])
    out["bush"]=bu
    # --- Barrel 32x32 new ---
    ba=Image.new("RGBA",(32,40),(0,0,0,0))
    d=ImageDraw.Draw(ba)
    d.ellipse([7,30,25,34], fill=(0,0,0,75))
    d.rectangle([8,8,24,30], fill=P["brown_mid"], outline=P["outline"])
    # staves
    for x in [11,15,19]:
        d.rectangle([x,8,x,30], fill=dr(P["brown_mid"],0.72))
        d.rectangle([x+1,8,x+1,30], fill=li(P["brown_mid"],1.12))
    # hoops
    for y in [11,19,26]:
        d.rectangle([8,y,24,y+2], fill=dr(P["stone_dark"],0.9), outline=P["outline"])
        d.rectangle([9,y,23,y+1], fill=P["steel_mid"])
    out["barrel"]=ba
    return out

def save_all():
    log=[]
    # Walls
    walls=[]
    for n,col,mortar in [
        ("stone", P["stone_mid"], P["stone_dark"]),
        ("brick", P["dirt_mid"], P["dirt_dark"]),
        ("dungeon", P["steel_mid"], P["stone_dark"]),
        ("mossy", (62,95,68,255), (42,62,45,255)),
        ("sandstone", (150,130,95,255), (104,88,64,255)),
    ]:
        img=make_wall_v2(n,col,mortar)
        p=os.path.join(OUT_T, f"wall_{n}_v2.png")
        img.save(p); log.append((p,img.size))
        img.save(os.path.join(OUT_W, f"wall_{n}_v2.png"))
        walls.append(img)
    atlas=Image.new("RGBA",(5*32,48),(0,0,0,0))
    for i,im in enumerate(walls): atlas.alpha_composite(im,(i*32,0))
    atlas.save(os.path.join(OUT_T,"wall_atlas_v2.png")); atlas.save(os.path.join(OUT_W,"wall_atlas_v2.png"))
    log.append((os.path.join(OUT_T,"wall_atlas_v2.png"),atlas.size))
    # Cliffs
    for kind in ["grass","dirt","stone"]:
        top,face,combined=make_cliff_v2(kind)
        for nm,im in [(f"cliff_{kind}_top_v2",top),(f"cliff_{kind}_face_v2",face),(f"cliff_{kind}_v2",combined)]:
            p=os.path.join(OUT_T, f"{nm}.png"); im.save(p); log.append((p,im.size))
            im.save(os.path.join(OUT_W,f"{nm}.png"))
    catlas=Image.new("RGBA",(3*32,48),(0,0,0,0))
    for i,k in enumerate(["grass","dirt","stone"]):
        catlas.alpha_composite(Image.open(os.path.join(OUT_T,f"cliff_{k}_v2.png")),(i*32,0))
    catlas.save(os.path.join(OUT_T,"cliff_atlas_v2.png")); catlas.save(os.path.join(OUT_W,"cliff_atlas_v2.png"))
    log.append((os.path.join(OUT_T,"cliff_atlas_v2.png"),catlas.size))
    # Props
    props=make_props_v2()
    for nm,im in props.items():
        p=os.path.join(OUT_S, f"prop_{nm}_v2.png"); im.save(p); log.append((p,im.size))
        im.save(os.path.join(OUT_W,f"prop_{nm}_v2.png"))
    patlas=Image.new("RGBA",(len(props)*32,48),(0,0,0,0))
    for i,(k,im) in enumerate(props.items()):
        patlas.alpha_composite(im,(i*32, (48-im.size[1])//2))
    patlas.save(os.path.join(OUT_T,"props_atlas_v2.png")); patlas.save(os.path.join(OUT_W,"props_atlas_v2.png"))
    log.append((os.path.join(OUT_T,"props_atlas_v2.png"),patlas.size))
    # Also overwrite main 25d with v2 (so game instantly upgrades), keep backup
    # wall_atlas promoted
    import shutil
    for n in ["stone","brick","dungeon","mossy"]:
        shutil.copy(os.path.join(OUT_T,f"wall_{n}_v2.png"), os.path.join(BASE,"assets","tiles","25d",f"wall_{n}_25d.png"))
    shutil.copy(os.path.join(OUT_T,"wall_atlas_v2.png"), os.path.join(BASE,"assets","tiles","25d","wall_atlas_25d.png"))
    for k in ["grass","dirt","stone"]:
        shutil.copy(os.path.join(OUT_T,f"cliff_{k}_v2.png"), os.path.join(BASE,"assets","tiles","25d",f"cliff_{k}_cliff_25d.png"))
    shutil.copy(os.path.join(OUT_T,"cliff_atlas_v2.png"), os.path.join(BASE,"assets","tiles","25d","cliff_atlas_25d.png"))
    for nm in props:
        if os.path.exists(os.path.join(BASE,"assets","sprites",f"prop_{nm}_25d.png")):
            shutil.copy(os.path.join(OUT_S,f"prop_{nm}_v2.png"), os.path.join(BASE,"assets","sprites",f"prop_{nm}_25d.png"))
    # copy to web/assets (live game)
    for n in ["stone","brick","dungeon","mossy"]:
        shutil.copy(os.path.join(OUT_W,f"wall_{n}_v2.png"), os.path.join(BASE,"web","assets",f"wall_atlas_25d.png"))  # keep atlas single
    print("=== 2.5D V2 HIGH-FIDELITY GENERATION ===")
    for p,s in log:
        print(f" {p} {s} {os.path.getsize(p)}B")
    return log

if __name__=="__main__":
    save_all()

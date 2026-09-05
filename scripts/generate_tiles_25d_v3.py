"""
generate_tiles_25d_v3.py — SOFT SHADOWS + INNER-CORNERS + STAIR SET
- Soft shadows: distance-field ellipses with smooth falloff (not hard binary ellipses)
- Cliff inner/outer corners + east edge + stair ramps for seamless platform tiling

Output: assets/tiles/25d_v2/ (augmented) + assets/sprites/25d_v2/ + web/assets/25d_v2/
Run: python3 scripts/generate_tiles_25d_v3.py
"""
import os, math, random
from PIL import Image, ImageDraw

random.seed(42)
BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_T = os.path.join(BASE, "assets", "tiles", "25d_v2")
OUT_S = os.path.join(BASE, "assets", "sprites", "25d_v2")
OUT_W = os.path.join(BASE, "web", "assets", "25d_v2")
for d in [OUT_T, OUT_S, OUT_W]:
    os.makedirs(d, exist_ok=True)
# keep legacy live paths synced too
LEGACY_T = os.path.join(BASE, "assets", "tiles", "25d")
LEGACY_S = os.path.join(BASE, "assets", "sprites")
LEGACY_W = os.path.join(BASE, "web", "assets")

P = {
    "emerald_dark": (15,75,45,255),
    "emerald_mid": (35,150,80,255),
    "emerald_light": (90,220,130,255),
    "dirt_dark": (68,44,30,255),
    "dirt_mid": (105,72,46,255),
    "stone_mid": (88,97,122,255),
    "stone_dark": (52,58,72,255),
    "stone_light": (138,153,172,255),
    "shadow": (0,0,0,255),
}

def soft_ellipse(w,h, max_alpha=76, softness=0.55, inner_cover=0.42):
    """
    Distance-field soft shadow. Pixels inside inner_cover are solid (max_alpha),
    then smooth falloff to 0 at edge. Looks hand-painted vs hard binary.
    """
    img = Image.new("RGBA", (w,h), (0,0,0,0))
    cx, cy = w*0.5, h*0.5
    rx, ry = w*0.5, h*0.5
    for y in range(h):
        for x in range(w):
            nx = (x+0.5 - cx)/rx
            ny = (y+0.5 - cy)/ry
            d2 = nx*nx + ny*ny
            if d2 > 1.0:
                continue
            d = math.sqrt(d2)  # 0 center, 1 edge
            if d <= inner_cover:
                a = max_alpha
            else:
                # smoothstep falloff
                t = (d - inner_cover) / (1.0 - inner_cover)
                # ease: 3t^2 -2t^3  then invert & soften
                smooth = t*t*(3 - 2*t)
                # extra softness
                smooth = pow(smooth, softness)
                a = int(max_alpha * (1.0 - smooth))
            # subtle center lift: slightly darker center
            if d < 0.28:
                a = min(255, int(a * 1.06))
            a = max(0, min(255, a))
            # premultiply not needed, keep pure black with varying alpha
            img.putpixel((x,y), (0,0,0,a))
    return img

def make_shadows():
    variants = [
        ("shadow_soft_14x5", 14, 5, 76, 0.58, 0.35),
        ("shadow_soft_20x8", 20, 8, 78, 0.58, 0.38),
        ("shadow_soft_32x16", 32, 16, 72, 0.60, 0.40),
        ("shadow_soft_48x12", 48, 12, 70, 0.60, 0.40),
        ("shadow_soft_32x32_sheet", 32, 32, 70, 0.62, 0.30), # for 32x32 centered blob
    ]
    outs=[]
    for name,w,h,alpha,soft,cover in variants:
        im = soft_ellipse(w,h, alpha, soft, cover)
        # For the 32x32 sheet, center the ellipse at y+10 (feet) with transparent padding
        if "sheet" in name:
            canvas = Image.new("RGBA",(32,32),(0,0,0,0))
            # place ellipse at y=20 centered -> offset 16-? keep at y 26 in 32 canvas ~ near feet
            # Use 20x8 ellipse at center bottom
            ell = soft_ellipse(20,8,78,0.58,0.38)
            canvas.alpha_composite(ell, ((32-20)//2, 20))
            im = canvas
            name = "shadow_soft_32x32"
        p = os.path.join(OUT_S, f"{name}.png")
        im.save(p)
        outs.append((p, im.size))
        # also save web mirror
        im.save(os.path.join(OUT_W, f"{name}.png"))
        # promote to legacy for live game
        legacy = os.path.join(LEGACY_S, f"{name}.png")
        im.save(legacy)
        legacy2 = os.path.join(LEGACY_W, f"{name}.png")
        try: im.save(legacy2)
        except: pass
    # also make a contact AO ring for props: small 22x10 very soft
    ao = soft_ellipse(22,10,52,0.52,0.25)
    ao.save(os.path.join(OUT_S,"shadow_soft_ao_22x10.png"))
    ao.save(os.path.join(OUT_W,"shadow_soft_ao_22x10.png"))
    outs.append((os.path.join(OUT_S,"shadow_soft_ao_22x10.png"), ao.size))
    # large boss shadow 64x16
    big = soft_ellipse(64,16,60,0.62,0.42)
    big.save(os.path.join(OUT_S,"shadow_soft_64x16.png"))
    big.save(os.path.join(OUT_W,"shadow_soft_64x16.png"))
    outs.append((os.path.join(OUT_S,"shadow_soft_64x16.png"), big.size))
    return outs

def dr(c,f=0.62): return (int(c[0]*f),int(c[1]*f),int(c[2]*f),255)
def li(c,f=1.28): return (min(255,int(c[0]*f)),min(255,int(c[1]*f)),min(255,int(c[2]*f)),255)

def make_corner_set():
    """Inner/outer corners + east edge + stairs"""
    outs=[]
    # palette for cliff top
    grass_mid=(52,118,48,255)
    grass_light=(92,170,78,255)
    grass_dark=(28,68,32,255)
    dirt_mid=(105,72,46,255)
    dirt_dark=(68,44,30,255)
    stone_mid=(88,97,122,255)
    stone_dark=(52,58,72,255)

    # --- cliff_edge_e (east face 16x32 vertical): similar to south but rotated ---
    # For east edge, the tile top faces east: side is on right side 16x32
    for kind, mid, light in [("grass", grass_mid, grass_light), ("dirt", dirt_mid, (142,102,68,255)), ("stone", stone_mid, (138,153,172,255))]:
        # East edge tile is 48x32 (48 wide: 32 top +16 side on right). For engine, easier keep 32x48 but side on right.
        # We'll make 48x32: left 32 top, right 16 side vertical.
        img=Image.new("RGBA",(48,32),(0,0,0,0))
        d=ImageDraw.Draw(img)
        # top
        d.rectangle([0,0,31,31], fill=mid)
        # noise
        for _ in range(18):
            x=random.randint(0,31); y=random.randint(0,31)
            d.point((x,y), fill=dr(mid,0.9) if random.random()<0.5 else li(mid,1.08))
        if kind=="grass":
            for x in range(0,32,3):
                l=random.randint(1,3)
                d.rectangle([x,28,x+1,31], fill=li(grass_light,1.05))
        # east side vertical strip on right of top (x 32..47, y 0..31) but south lip still shows?
        # Blend: east side covers x 32-47 full height, with top lip highlight
        side_mid = dr(mid,0.52)
        side_dark = dr(mid,0.34)
        d.rectangle([32,0,47,31], fill=side_mid)
        # highlight at seam
        d.rectangle([32,0,32,31], fill=li(dr(mid,0.55),1.2))
        d.rectangle([33,0,33,31], fill=side_dark)
        # vertical strata lines on east side (horizontal becomes vertical when rotated: actually side still shows horizontal strata rotated 90)
        for y in [10,20]:
            d.rectangle([32,y,47,y], fill=side_dark)
            d.rectangle([32,y+1,47,y+1], fill=li(side_mid,1.18))
        d.rectangle([47,0,47,31], fill=(0,0,0,55)) # far edge shadow
        name=f"cliff_edge_e_{kind}_v2"
        p=os.path.join(OUT_T,f"{name}.png")
        img.save(p); outs.append((p,img.size))
        img.save(os.path.join(OUT_W,f"{name}.png"))
        # also legacy
        img.save(os.path.join(LEGACY_T,f"{name}.png"))

    # --- Outer corner SE (south + east faces forming L) ---
    # 48x48 tile where top is 32x32 at NW, south strip 32x16 below, east strip 16x32 right
    for kind, mid in [("grass", grass_mid),("dirt", dirt_mid),("stone", stone_mid)]:
        img=Image.new("RGBA",(48,48),(0,0,0,0))
        d=ImageDraw.Draw(img)
        # top
        d.rectangle([0,0,31,31], fill=mid)
        for _ in range(22):
            x=random.randint(0,31); y=random.randint(0,31)
            d.point((x,y), fill=dr(mid,0.9) if random.random()<0.5 else li(mid,1.08))
        if kind=="grass":
            for x in [3,9,15,21,27]:
                d.rectangle([x,27,x+1,31], fill=(92,170,78,255))
        # south face
        side = dr(mid,0.52)
        d.rectangle([0,32,31,47], fill=side)
        d.rectangle([0,32,31,32], fill=dr(mid,0.48))
        d.rectangle([0,33,31,33], fill=li(side,1.15))
        # east face
        d.rectangle([32,0,47,31], fill=dr(mid,0.48))
        d.rectangle([32,0,32,31], fill=li(dr(mid,0.5),1.2))
        # corner block where south+east meet (32,32..47,47) - needs darker miter
        d.rectangle([32,32,47,47], fill=dr(mid,0.36))
        # AO at outer corner
        d.rectangle([31,31,32,32], fill=(0,0,0,65))
        d.ellipse([28,28,38,38], fill=(0,0,0,32)) # soft AO dot
        p=os.path.join(OUT_T,f"cliff_corner_outer_SE_{kind}_v2.png")
        img.save(p); outs.append((p,img.size))
        img.save(os.path.join(OUT_W,f"cliff_corner_outer_SE_{kind}_v2.png"))
        img.save(os.path.join(LEGACY_T,f"cliff_corner_outer_SE_{kind}_v2.png"))

    # --- Inner corner NW (notch): inverted L - the tile is ground level with a notch missing, showing inner walls ---
    # Size 48x48 but top is mostly grass with a 16x16 cutout at SE showing lower ground + inner faces
    for kind, mid in [("grass", grass_mid),("dirt", dirt_mid),("stone", stone_mid)]:
        img=Image.new("RGBA",(48,48),(0,0,0,0))
        d=ImageDraw.Draw(img)
        # lower ground (bottom-right reveal)
        low = dr(mid,0.72) if kind!="grass" else (38,88,36,255)
        d.rectangle([16,16,47,47], fill=low)
        # notch walls: inner south face (x 0..15, y16) and inner east face (x16, y0..15)
        # Top pieces: NW large + NE strip + SW strip
        # NW top 16x16? Actually split: top is L shape.
        # Simpler: draw top as full 32x32 then cut out 16x16 SE
        d.rectangle([0,0,31,31], fill=mid)
        # erase SE 16x16 of top
        d.rectangle([16,16,31,31], fill=low)
        # inner south face (horizontal wall along x 0-15 at y16, 8px tall downwards?)
        inner_dark = dr(mid,0.42)
        inner_light = li(dr(mid,0.5),1.15)
        # inner south: north-facing inner wall (facing south, so viewer sees its south face but it's recessed)
        # At y=16, a 16-wide south face strip at (0,16)-(15,24) ???
        # Represent as 16x8 wall at inner edge
        d.rectangle([0,16,15,23], fill=inner_dark) # south inner
        d.rectangle([0,16,15,16], fill=inner_light) # top lip highlight of inner wall
        d.rectangle([16,0,23,15], fill=dr(mid,0.45))  # east inner
        d.rectangle([16,0,16,15], fill=inner_light)
        # corner miter at (16,16)
        d.rectangle([16,16,23,23], fill=dr(mid,0.34))
        d.ellipse([14,14,22,22], fill=(0,0,0,40))
        # regrow grass on top edges near inner corner
        if kind=="grass":
            for x in [2,7,12]:
                d.rectangle([x,12,x+1,16], fill=li(grass_light,1.08))
            for y in [2,7,12]:
                d.rectangle([12,y,16,y+1], fill=li(grass_light,1.08))
        p=os.path.join(OUT_T,f"cliff_corner_inner_NW_{kind}_v2.png")
        img.save(p); outs.append((p,img.size))
        img.save(os.path.join(OUT_W,f"cliff_corner_inner_NW_{kind}_v2.png"))
        img.save(os.path.join(LEGACY_T,f"cliff_corner_inner_NW_{kind}_v2.png"))

    # --- Stairs: 32x32 ramp with 4 steps descending south ---
    for kind, mid in [("grass", grass_mid),("dirt", dirt_mid),("stone", stone_mid)]:
        img=Image.new("RGBA",(32,32),(0,0,0,0))
        d=ImageDraw.Draw(img)
        # base ground
        d.rectangle([0,0,31,31], fill=dr(mid,0.82))
        # 4 steps: each 8px tall (y), with 2px tread highlight + shadow
        # Step 0 top (y0-7) lightest (highest), step 3 bottom darkest
        for i in range(4):
            y0=i*8
            y1=y0+7
            t = i/3.0
            col = li(mid, 1.08 - t*0.18) if kind=="grass" else (mid[0]-int(t*18), mid[1]-int(t*13), mid[2]-int(t*8),255)
            # tread
            d.rectangle([0,y0,31,y1], fill=col, outline=dr(mid,0.78))
            # highlight leading edge of tread
            d.rectangle([0,y0,31,y0], fill=li(col,1.35))
            d.rectangle([0,y0,31,y0+1], fill=li(col,1.18))
            # shadow under tread
            d.rectangle([0,y1,31,y1], fill=dr(col,0.68))
            # side stringer shadows
            d.rectangle([0,y0,0,y1], fill=dr(col,0.85))
            d.rectangle([31,y0,31,y1], fill=dr(col,0.82))
            # center wear line
            if i<3:
                d.rectangle([4,y1,27,y1], fill=(0,0,0,48))
        # handrail/edge dark
        d.rectangle([0,31,31,31], fill=(0,0,0,55))
        outs.append((os.path.join(OUT_T,f"stair_south_{kind}_v2.png"), img.size))
        p=os.path.join(OUT_T,f"stair_south_{kind}_v2.png")
        img.save(p)
        img.save(os.path.join(OUT_W,f"stair_south_{kind}_v2.png"))
        img.save(os.path.join(LEGACY_T,f"stair_south_{kind}_v2.png"))
        # also east variation: rotate
        eimg=img.rotate(-90, expand=False)
        p2=os.path.join(OUT_T,f"stair_east_{kind}_v2.png")
        eimg.save(p2); outs.append((p2,eimg.size))
        eimg.save(os.path.join(OUT_W,f"stair_east_{kind}_v2.png"))
        eimg.save(os.path.join(LEGACY_T,f"stair_east_{kind}_v2.png"))
    # --- stair corner inner/outer for turns ---
    # Simple 32x32 L stair: south+east
    for kind, mid in [("grass", grass_mid),("dirt", dirt_mid),("stone", stone_mid)]:
        img=Image.new("RGBA",(32,32),(0,0,0,0))
        d=ImageDraw.Draw(img)
        d.rectangle([0,0,31,31], fill=dr(mid,0.88))
        # L shape: south steps 2 rows south, east steps 2 cols east
        # south part
        for i in range(2):
            y0=16+i*8
            col=li(mid,1.05 - i*0.12)
            d.rectangle([0,y0,31,y0+7], fill=col)
            d.rectangle([0,y0,31,y0+1], fill=li(col,1.32))
        # east part
        for i in range(2):
            x0=16+i*8
            col=li(mid,1.05 - i*0.12)
            d.rectangle([x0,0,x0+7,15], fill=col)
            d.rectangle([x0,0,x0+7,1], fill=li(col,1.32))
        # corner block at 16,16
        d.rectangle([16,16,23,23], fill=dr(mid,0.76))
        p=os.path.join(OUT_T,f"stair_corner_SE_{kind}_v2.png")
        img.save(p); outs.append((p,img.size))
        img.save(os.path.join(OUT_W,f"stair_corner_SE_{kind}_v2.png"))

    # Composite atlases
    # Shadow atlas 128x32: 14x5,20x8,32x16,48x12 side by side padded
    try:
        sh = Image.new("RGBA",(128,16),(0,0,0,0))
        for i, name in enumerate(["shadow_soft_14x5","shadow_soft_20x8","shadow_soft_32x16","shadow_soft_48x12"]):
            im=Image.open(os.path.join(OUT_S,f"{name}.png"))
            # center vertically in 16 tall
            y=(16-im.size[1])//2; x=i*32+(32-im.size[0])//2
            sh.alpha_composite(im,(x,y))
        sh.save(os.path.join(OUT_T,"shadow_atlas_soft_v2.png"))
        sh.save(os.path.join(OUT_W,"shadow_atlas_soft_v2.png"))
        outs.append((os.path.join(OUT_T,"shadow_atlas_soft_v2.png"), sh.size))
    except Exception as e:
        print("shadow atlas fail",e)
    # Cliff edge atlas 96x48 for the 3 east edges
    # Stair atlas 96x32
    try:
        sa=Image.new("RGBA",(96,32),(0,0,0,0))
        for i,k in enumerate(["grass","dirt","stone"]):
            im=Image.open(os.path.join(OUT_T,f"stair_south_{k}_v2.png"))
            sa.alpha_composite(im,(i*32,0))
        sa.save(os.path.join(OUT_T,"stair_atlas_south_v2.png"))
        sa.save(os.path.join(OUT_W,"stair_atlas_south_v2.png"))
        outs.append((os.path.join(OUT_T,"stair_atlas_south_v2.png"),sa.size))
    except Exception as e:
        print("stair atlas fail",e)
    return outs

if __name__=="__main__":
    sh=make_shadows()
    print("=== SOFT SHADOWS ===")
    for p,s in sh: print(f" {p} {s} {os.path.getsize(p)}B")
    cr=make_corner_set()
    print("=== CORNERS + STAIRS ===")
    for p,s in cr: print(f" {p} {s} {os.path.getsize(p)}B")
    print("DONE V3")

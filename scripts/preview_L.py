from PIL import Image
import os
BASE="D:/RPG_Quest_2D/assets/tiles/25d_v2"
OUT="D:/RPG_Quest_2D/assets/25d_v2/l_preview_L.png"
cells = [(18,14),(19,14),(20,14),(18,15),(18,16),(18,17),(18,18)]
cell_set=set(cells)
def has(x,y): return (x,y) in cell_set
kind="grass"
minx=min(c[0] for c in cells)-1
maxx=max(c[0] for c in cells)+1
miny=min(c[1] for c in cells)-1
maxy=max(c[1] for c in cells)+1
W=(maxx-minx+1)*32
H=(maxy-miny+1)*32+16
canvas=Image.new("RGBA",(W,H),(52,118,48,255))
# ground already grass, just composite tiles
for (x,y) in cells:
    has_n=has(x,y-1); has_s=has(x,y+1); has_e=has(x+1,y); has_w=has(x-1,y)
    has_se=has(x+1,y+1); has_sw=has(x-1,y+1); has_ne=has(x+1,y-1); has_nw=has(x-1,y-1)
    stem=None
    if has_s and has_e and not has_se: stem=f"cliff_corner_inner_NW_{kind}_v2"
    elif has_s and has_w and not has_sw: stem=f"cliff_corner_inner_NE_{kind}_v2"
    elif has_n and has_e and not has_ne: stem=f"cliff_corner_inner_SW_{kind}_v2"
    elif has_n and has_w and not has_nw: stem=f"cliff_corner_inner_SE_{kind}_v2"
    elif not has_s and not has_e: stem=f"cliff_corner_outer_SE_{kind}_v2"
    elif not has_s and not has_w: stem=f"cliff_corner_outer_SW_{kind}_v2"
    elif not has_n and not has_e: stem=f"cliff_corner_outer_NE_{kind}_v2"
    elif not has_n and not has_w: stem=f"cliff_corner_outer_NW_{kind}_v2"
    elif not has_s: stem=f"cliff_{kind}_v2"
    elif not has_e: stem=f"cliff_edge_e_{kind}_v2"
    elif not has_w: stem=f"cliff_edge_w_{kind}_v2"
    else: stem=f"cliff_{kind}_top_v2"
    p=os.path.join(BASE, stem+".png")
    if not os.path.exists(p):
        p=os.path.join(BASE, f"cliff_{kind}_v2.png")
    im=Image.open(p) if os.path.exists(p) else None
    if im:
        px=(x-minx)*32
        py=(y-miny)*32
        if im.size==(48,48):
            px-=8; py-=8
        # 48x32 east/west spills right but left 32 is top at same px (no offset)
        canvas.alpha_composite(im,(px,py))
        print(f"{x},{y} -> {stem} {im.size} at {px},{py}")
    else:
        print("MISSING",stem)
canvas2=canvas.resize((canvas.size[0]*4, canvas.size[1]*4), Image.NEAREST)
canvas2.save(OUT)
print("saved", OUT, canvas2.size, os.path.getsize(OUT))

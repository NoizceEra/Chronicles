"""
generate_2p5d_assets.py - 2.5D extruded wall tiles generator
- Reads assets/tiles/tileset.png (256x256, 8x8 grid 32x32)
- Layout: city(0,0,128,128), forest(128,0), crypt(0,128), magma(128,128)
  Wall tile Rect2(64,128,32,32) = crypt local (2,0)
  Tree tile Rect2(128,32,32,32) = forest local (0,1)
- Outputs:
  assets/tiles/tileset_2p5d.png (256x384)
  assets/sprites/shadow_blob.png (32x16)
  assets/sprites/shadow_wall_ao.png (32x8)
  assets/tiles/tileset_2p5d_props.png (256x256)
Palette matches generate_assets.py
"""
import os
from PIL import Image, ImageDraw

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TILES_DIR = os.path.join(BASE_DIR, "assets", "tiles")
SPRITES_DIR = os.path.join(BASE_DIR, "assets", "sprites")
SRC_TILESET = os.path.join(TILES_DIR, "tileset.png")
DST_TILESET = os.path.join(TILES_DIR, "tileset_2p5d.png")
DST_PROPS = os.path.join(TILES_DIR, "tileset_2p5d_props.png")
SHADOW_BLOB = os.path.join(SPRITES_DIR, "shadow_blob.png")
SHADOW_AO = os.path.join(SPRITES_DIR, "shadow_wall_ao.png")

os.makedirs(TILES_DIR, exist_ok=True)
os.makedirs(SPRITES_DIR, exist_ok=True)

PALETTE = {
    "black": (15, 15, 20, 255),
    "outline": (24, 20, 37, 255),
    "dark_gray": (45, 49, 66, 255),
    "mid_gray": (88, 97, 122, 255),
    "light_gray": (148, 161, 178, 255),
    "white": (245, 247, 250, 255),
    "skin_dark": (180, 105, 75, 255),
    "skin_mid": (225, 155, 115, 255),
    "skin_light": (255, 205, 170, 255),
    "gold_dark": (165, 105, 20, 255),
    "gold_mid": (235, 175, 35, 255),
    "gold_light": (255, 230, 110, 255),
    "steel_dark": (50, 60, 80, 255),
    "steel_mid": (100, 120, 150, 255),
    "steel_light": (180, 200, 225, 255),
    "royal_blue_dark": (15, 35, 85, 255),
    "royal_blue_mid": (35, 75, 165, 255),
    "royal_blue_light": (80, 140, 235, 255),
    "crimson_dark": (95, 15, 25, 255),
    "crimson_mid": (185, 30, 45, 255),
    "crimson_light": (245, 75, 90, 255),
    "emerald_dark": (15, 75, 45, 255),
    "emerald_mid": (35, 150, 80, 255),
    "emerald_light": (90, 220, 130, 255),
    "purple_dark": (55, 20, 85, 255),
    "purple_mid": (115, 45, 165, 255),
    "purple_light": (185, 105, 240, 255),
    "brown_dark": (55, 35, 25, 255),
    "brown_mid": (115, 70, 45, 255),
    "brown_light": (175, 115, 75, 255),
    "cyan_dark": (10, 70, 95, 255),
    "cyan_mid": (25, 155, 195, 255),
    "cyan_light": (90, 225, 245, 255),
}

def darken(c, f=0.6):
    return (int(c[0]*f), int(c[1]*f), int(c[2]*f), 255)

def lerp(a,b,t):
    return int(a+(b-a)*t)

# --- helpers to draw side faces ---
def draw_crypt_side(draw, x, y):
    """32x16 side face for crypt dungeon wall at grid (2,8) -> pixel x,y"""
    base = PALETTE["mid_gray"]
    dark = PALETTE["dark_gray"]
    light = PALETTE["light_gray"]
    side = darken(base, 0.55)
    side_dark = darken(dark, 0.65)
    side_light = darken(light, 0.55)
    # main side rect 32x16
    draw.rectangle([x, y, x+31, y+15], fill=side)
    # vertical brick striations (1px dark lines every 8px + highlight)
    for bx in [0, 8, 16, 24]:
        draw.line([x+bx, y, x+bx, y+15], fill=side_dark, width=1)
        # subtle highlight line next to groove
        if bx != 0:
            draw.line([x+bx+1, y, x+bx+1, y+15], fill=side_light, width=1)
    # horizontal mortar line mid-height
    draw.line([x, y+7, x+31, y+7], fill=side_dark, width=1)
    draw.line([x, y+8, x+31, y+8], fill=side_light, width=1)
    # AO gradient at top edge: 2px dark line
    draw.rectangle([x, y, x+31, y+1], fill=(0,0,0,160))
    draw.rectangle([x, y+2, x+31, y+2], fill=(0,0,0,70))
    # highlight at bottom edge 1px
    draw.line([x, y+15, x+31, y+15], fill=lighten(side_light,1.3), width=1)
    # outline left/right to match pixel-perfect
    draw.line([x, y, x, y+15], fill=PALETTE["outline"], width=1)
    draw.line([x+31, y, x+31, y+15], fill=PALETTE["outline"], width=1)

def lighten(c, f=1.25):
    return (min(255,int(c[0]*f)), min(255,int(c[1]*f)), min(255,int(c[2]*f)), 255)

def draw_city_side(draw, x, y):
    """32x16 city/palace wall side at (4,8) - steel palette"""
    base = PALETTE["steel_mid"]
    dark = PALETTE["steel_dark"]
    light = PALETTE["steel_light"]
    side = darken(base, 0.58)
    side_dark = darken(dark, 0.7)
    side_light = darken(light, 0.6)
    draw.rectangle([x, y, x+31, y+15], fill=side)
    for bx in [0, 8, 16, 24]:
        draw.line([x+bx, y, x+bx, y+15], fill=side_dark, width=1)
        if bx != 0:
            draw.line([x+bx+1, y, x+bx+1, y+15], fill=side_light, width=1)
    # horizontal steel beam
    draw.rectangle([x, y+7, x+31, y+8], fill=dark)
    draw.rectangle([x+1, y+7, x+30, y+7], fill=side_light)
    draw.rectangle([x, y, x+31, y+1], fill=(0,0,0,160))
    draw.rectangle([x, y+2, x+31, y+2], fill=(0,0,0,70))
    draw.line([x, y+15, x+31, y+15], fill=lighten(side_light,1.25), width=1)
    draw.line([x, y, x, y+15], fill=PALETTE["outline"], width=1)
    draw.line([x+31, y, x+31, y+15], fill=PALETTE["outline"], width=1)

def draw_forest_side(draw, x, y):
    """32x16 forest trunk/cliff side at (6,8) - brown bark"""
    base = PALETTE["brown_mid"]
    dark = PALETTE["brown_dark"]
    light = PALETTE["brown_light"]
    side = darken(base, 0.62)
    side_dark = darken(dark, 0.75)
    side_light = darken(light, 0.58)
    draw.rectangle([x, y, x+31, y+15], fill=side)
    # vertical bark striations
    for bx in [4, 10, 18, 26]:
        draw.line([x+bx, y, x+bx, y+15], fill=side_dark, width=1)
        draw.line([x+bx+1, y, x+bx+1, y+15], fill=side_light, width=1)
    # irregular bark knots
    draw.rectangle([x+12, y+4, x+14, y+6], fill=side_dark)
    draw.rectangle([x+22, y+10, x+24, y+12], fill=side_dark)
    draw.rectangle([x, y, x+31, y+1], fill=(0,0,0,160))
    draw.rectangle([x, y+2, x+31, y+2], fill=(0,0,0,65))
    draw.line([x, y+15, x+31, y+15], fill=side_light, width=1)
    draw.line([x, y, x, y+15], fill=PALETTE["outline"], width=1)
    draw.line([x+31, y, x+31, y+15], fill=PALETTE["outline"], width=1)

def draw_filler_shadow(draw, x, y, alpha_top=90):
    """Filler tile at 32x32 with shadow gradient for y-sorting tests"""
    # transparent base then gradient shadow oval bottom
    # full tile darker gradient bottom 12px
    # vertical shadow fading upward
    for row in range(16):
        a = int(alpha_top * (1 - row/16))
        # gradient from bottom upwards within tile
        # fill row at y+31-row
        draw.line([x, y+31-row, x+31, y+31-row], fill=(0,0,0,a), width=1)
    # subtle 1px outline bottom
    draw.rectangle([x, y, x+31, y+31], outline=(0,0,0,30), width=1)

def generate_tileset_2p5d():
    # Read source
    src = Image.open(SRC_TILESET).convert("RGBA")
    assert src.size == (256,256), f"Expected 256x256 got {src.size}"
    print(f"Loaded {SRC_TILESET} {src.size}")
    # Validate known tiles
    # Wall tile at Rect2(64,128,32,32) -> crypt local (2,0)
    # Extract and log center pixel
    wall_center = src.getpixel((64+16,128+16))
    tree_center = src.getpixel((128+16,32+16))
    print(f"  Wall tile (64,128) center {wall_center} -> crypt local (2,0)")
    print(f"  Tree tile (128,32) center {tree_center} -> forest local (0,1)")
    print(f"  Quadrants: city(0,0,128,128) forest(128,0) crypt(0,128) magma(128,128)")

    # Create 256x384 destination (extra 128px = 4 rows)
    dst = Image.new("RGBA", (256,384), (0,0,0,0))
    dst.paste(src, (0,0))

    d = ImageDraw.Draw(dst, "RGBA")

    # --- Row 8-9: Wall side faces (y=256..320) ---
    # Mark grid for visual debug: draw subtle labels? keep pixel-perfect, no text
    # At (2,8) crypt side 32x16
    draw_crypt_side(d, 2*32, 8*32)
    # At (4,8) city side
    draw_city_side(d, 4*32, 8*32)
    # At (6,8) forest/cliff side
    draw_forest_side(d, 6*32, 8*32)

    # Additional side variations in row 8 to fill gaps
    # (0,8) magma side (crimson)
    # create quick magma side
    mx, my = 0*32, 8*32
    side_magma = darken(PALETTE["crimson_mid"], 0.55)
    d.rectangle([mx, my, mx+31, my+15], fill=side_magma)
    for bx in [0,8,16,24]:
        d.line([mx+bx, my, mx+bx, my+15], fill=darken(PALETTE["crimson_dark"],0.6), width=1)
    d.rectangle([mx, my, mx+31, my+1], fill=(0,0,0,160))
    d.rectangle([mx, my+2, mx+31, my+2], fill=(0,0,0,70))
    d.line([mx, my+15, mx+31, my+15], fill=lighten(side_magma,1.2), width=1)
    d.line([mx, my, mx, my+15], fill=PALETTE["outline"], width=1)
    d.line([mx+31, my, mx+31, my+15], fill=PALETTE["outline"], width=1)

    # (1,8) generic stone side lighter
    sx, sy = 1*32, 8*32
    draw_crypt_side(d, sx, sy)
    # override tint slightly lighter for variety
    # (3,8) emerald
    ex, ey = 3*32, 8*32
    base = PALETTE["emerald_mid"]
    side_e = darken(base,0.52)
    d.rectangle([ex, ey, ex+31, ey+15], fill=side_e)
    for bx in [0,8,16,24]:
        d.line([ex+bx, ey, ex+bx, ey+15], fill=darken(PALETTE["emerald_dark"],0.6), width=1)
    d.rectangle([ex, ey, ex+31, ey+1], fill=(0,0,0,160))
    d.line([ex, ey+15, ex+31, ey+15], fill=lighten(side_e,1.2), width=1)
    d.line([ex, ey, ex, ey+15], fill=PALETTE["outline"], width=1)
    d.line([ex+31, ey, ex+31, ey+15], fill=PALETTE["outline"], width=1)
    # (5,8) purple
    px, py = 5*32, 8*32
    side_p = darken(PALETTE["purple_mid"],0.55)
    d.rectangle([px, py, px+31, py+15], fill=side_p)
    for bx in [0,8,16,24]:
        d.line([px+bx, py, px+bx, py+15], fill=darken(PALETTE["purple_dark"],0.6), width=1)
    d.rectangle([px, py, px+31, py+1], fill=(0,0,0,160))
    d.line([px, py+15, px+31, py+15], fill=lighten(side_p,1.2), width=1)
    d.line([px, py, px, py+15], fill=PALETTE["outline"], width=1)
    d.line([px+31, py, px+31, py+15], fill=PALETTE["outline"], width=1)
    # (7,8) outline filler
    draw_filler_shadow(d, 7*32, 8*32, alpha_top=55)

    # --- Row 9 (y=288) filler/overlap tiles with shadow gradients for y-sorting tests ---
    # (0,9) shadow gradient tile
    draw_filler_shadow(d, 0*32, 9*32, alpha_top=110)
    # Add ellipse shadow in center for test
    d.ellipse([0*32+4, 9*32+20, 0*32+27, 9*32+28], fill=(0,0,0,70))
    # (1,9) checker with AO
    draw_filler_shadow(d, 1*32, 9*32, alpha_top=75)
    d.rectangle([1*32+4, 9*32+4, 1*32+27, 9*32+27], fill=darken(PALETTE["mid_gray"],0.45), outline=PALETTE["outline"])
    d.rectangle([1*32, 9*32, 1*32+31, 9*32+1], fill=(0,0,0,120))
    # (2,9) - repeat crypt side but lower variant (thicker)
    draw_crypt_side(d, 2*32, 9*32)
    # (3,9)-(7,9) gradients of varying intensity
    for col, alpha in [(3,45),(4,80),(5,100),(6,60),(7,30)]:
        draw_filler_shadow(d, col*32, 9*32, alpha_top=alpha)
        # small wall stub to test sorting
        d.rectangle([col*32+8, 9*32+8, col*32+23, 9*32+15], fill=darken(PALETTE["dark_gray"],0.7), outline=PALETTE["outline"])

    # Row 10-11 (y=320..384) keep transparent + add y-sorting debug overlap tiles
    # (0,10) solid overlap test tile
    d.rectangle([0*32, 10*32, 0*32+31, 10*32+31], fill=(0,0,0,45), outline=(0,0,0,80))
    d.ellipse([0*32+6, 10*32+18, 0*32+25, 10*32+26], fill=(0,0,0,90))
    # (1,10) another
    d.rectangle([1*32, 10*32, 1*32+31, 10*32+31], fill=(0,0,0,35), outline=(0,0,0,60))
    # (2,10) label stub
    draw_filler_shadow(d, 2*32, 10*32, alpha_top=40)

    dst.save(DST_TILESET)
    print(f"Saved {DST_TILESET} {dst.size} {os.path.getsize(DST_TILESET)} bytes")
    return dst

def generate_shadows():
    # shadow_blob.png 32x16 ellipse 0,0,0,90
    blob = Image.new("RGBA", (32,16), (0,0,0,0))
    d = ImageDraw.Draw(blob)
    d.ellipse([0,0,31,15], fill=(0,0,0,90))
    blob.save(SHADOW_BLOB)
    print(f"Saved {SHADOW_BLOB} {blob.size} {os.path.getsize(SHADOW_BLOB)} bytes")

    # shadow_wall_ao.png 32x8 gradient dark strip for wall base AO
    ao = Image.new("RGBA", (32,8), (0,0,0,0))
    d2 = ImageDraw.Draw(ao, "RGBA")
    for y in range(8):
        # gradient: top darkest, fade to transparent bottom
        a = int(110 * (1 - y/8))
        d2.line([0, y, 31, y], fill=(0,0,0,a), width=1)
    ao.save(SHADOW_AO)
    print(f"Saved {SHADOW_AO} {ao.size} {os.path.getsize(SHADOW_AO)} bytes")
    return blob, ao

def generate_props():
    """tileset_2p5d_props.png 256x256 - 8x8 grid 32x32 billboard props"""
    props = Image.new("RGBA", (256,256), (0,0,0,0))
    d = ImageDraw.Draw(props, "RGBA")

    def put(col, row, fn):
        # fn draws into a 32x32 tile at col,row using local ImageDraw
        # we create temp then paste
        tile = Image.new("RGBA", (32,32), (0,0,0,0))
        td = ImageDraw.Draw(tile, "RGBA")
        fn(td, tile)
        props.paste(tile, (col*32, row*32), tile)

    def tree_fn(td, tile):
        # 32x48 tall tree concept but in 32x32 we do trunk + canopy billboard
        # trunk bottom 16px
        td.rectangle([14, 20, 18, 28], fill=PALETTE["brown_dark"], outline=PALETTE["outline"])
        td.rectangle([15, 20, 17, 28], fill=PALETTE["brown_mid"])
        for y in range(20,28,2):
            td.point((16,y), fill=darken(PALETTE["brown_dark"],0.7))
        # canopy
        td.ellipse([4, 2, 28, 22], fill=PALETTE["emerald_dark"], outline=PALETTE["outline"])
        td.ellipse([7, 5, 18, 18], fill=PALETTE["emerald_mid"])
        td.ellipse([14, 3, 26, 16], fill=PALETTE["emerald_light"])
        td.ellipse([10, 8, 16, 14], fill=lighten(PALETTE["emerald_light"],1.15))
        # cast shadow bottom
        td.ellipse([8, 28, 24, 31], fill=(0,0,0,75))

    def tree_tall_fn(td, tile):
        # separate trunk + bush canopy - 32x48 concept squeezed: full height trunk
        td.rectangle([14, 8, 18, 28], fill=PALETTE["brown_dark"], outline=PALETTE["outline"])
        td.rectangle([15, 9, 17, 27], fill=PALETTE["brown_mid"])
        td.ellipse([6, 0, 26, 16], fill=PALETTE["emerald_dark"], outline=PALETTE["outline"])
        td.ellipse([9, 3, 20, 13], fill=PALETTE["emerald_mid"])
        td.ellipse([14, 5, 23, 12], fill=PALETTE["emerald_light"])
        td.ellipse([8, 28, 24, 31], fill=(0,0,0,85))

    def chest_fn(td, tile):
        # chest with height: body + lid, bottom 8px shadow
        td.rectangle([7, 14, 25, 24], fill=PALETTE["brown_mid"], outline=PALETTE["outline"])
        td.rectangle([7, 14, 25, 18], fill=PALETTE["gold_dark"], outline=PALETTE["outline"])
        td.rectangle([7, 15, 25, 17], fill=PALETTE["gold_mid"])
        # lock
        td.rectangle([14, 19, 17, 22], fill=PALETTE["gold_light"], outline=PALETTE["outline"])
        td.rectangle([15, 20, 16, 21], fill=PALETTE["black"])
        # planks
        td.line([7, 20, 25, 20], fill=PALETTE["brown_dark"], width=1)
        td.line([14, 14, 14, 24], fill=PALETTE["brown_dark"], width=1)
        # side face height (1px darker bottom)
        td.rectangle([7, 24, 25, 26], fill=darken(PALETTE["brown_mid"],0.55))
        td.line([7, 26, 25, 26], fill=darken(PALETTE["brown_mid"],0.4), width=1)
        # shadow bottom 8px
        td.ellipse([8, 27, 24, 30], fill=(0,0,0,85))

    def pillar_fn(td, tile):
        td.rectangle([10, 4, 22, 8], fill=PALETTE["light_gray"], outline=PALETTE["outline"])
        td.rectangle([12, 2, 20, 4], fill=PALETTE["mid_gray"], outline=PALETTE["outline"])
        td.rectangle([11, 8, 21, 26], fill=PALETTE["mid_gray"], outline=PALETTE["outline"])
        for x in [13,16,19]:
            td.line([x, 8, x, 26], fill=darken(PALETTE["mid_gray"],0.7), width=1)
            td.line([x+1, 8, x+1, 26], fill=lighten(PALETTE["mid_gray"],1.15), width=1)
        td.rectangle([10, 26, 22, 28], fill=PALETTE["light_gray"], outline=PALETTE["outline"])
        td.ellipse([10, 28, 22, 31], fill=(0,0,0,85))

    def crate_fn(td, tile):
        td.rectangle([6, 10, 26, 24], fill=PALETTE["brown_mid"], outline=PALETTE["outline"])
        td.line([6, 15, 26, 15], fill=darken(PALETTE["brown_mid"],0.65), width=1)
        td.line([6, 19, 26, 19], fill=darken(PALETTE["brown_mid"],0.65), width=1)
        td.line([14, 10, 14, 24], fill=darken(PALETTE["brown_mid"],0.7), width=1)
        for x,y in [(8,12),(19,12),(8,17),(19,17),(8,21),(19,21)]:
            td.rectangle([x,y,x+1,y+1], fill=PALETTE["gold_mid"])
        td.rectangle([6, 24, 26, 26], fill=darken(PALETTE["brown_mid"],0.55))
        td.ellipse([7, 27, 25, 30], fill=(0,0,0,75))

    def rock_fn(td, tile):
        td.ellipse([6, 12, 26, 26], fill=PALETTE["mid_gray"], outline=PALETTE["outline"])
        td.ellipse([9, 14, 18, 22], fill=PALETTE["light_gray"])
        td.ellipse([15, 16, 24, 24], fill=darken(PALETTE["mid_gray"],0.75))
        td.ellipse([12, 18, 16, 21], fill=PALETTE["white"])
        td.ellipse([7, 26, 25, 30], fill=(0,0,0,65))

    def rock_moss_fn(td, tile):
        td.ellipse([5, 14, 27, 27], fill=PALETTE["mid_gray"], outline=PALETTE["outline"])
        td.ellipse([8, 16, 20, 24], fill=PALETTE["emerald_dark"])
        td.ellipse([12, 12, 24, 20], fill=PALETTE["emerald_mid"])
        td.ellipse([7, 26, 25, 30], fill=(0,0,0,70))

    def barrel_fn(td, tile):
        td.rectangle([10, 10, 22, 26], fill=PALETTE["brown_mid"], outline=PALETTE["outline"])
        # bulge
        td.ellipse([9, 12, 23, 24], fill=PALETTE["brown_mid"], outline=PALETTE["outline"])
        td.line([10, 14, 22, 14], fill=PALETTE["outline"], width=1)
        td.line([10, 20, 22, 20], fill=PALETTE["outline"], width=1)
        td.rectangle([13, 10, 14, 26], fill=darken(PALETTE["brown_dark"],0.8))
        td.ellipse([10, 27, 22, 30], fill=(0,0,0,75))

    # Place props in grid 8x8
    put(0,0, tree_fn)
    put(1,0, tree_tall_fn)
    put(2,0, chest_fn)
    put(3,0, pillar_fn)
    put(4,0, crate_fn)
    put(5,0, rock_fn)
    put(6,0, rock_moss_fn)
    put(7,0, barrel_fn)
    # second row variations
    put(0,1, lambda td,t: (td.rectangle([8,12,24,24], fill=PALETTE["steel_mid"], outline=PALETTE["outline"]),
                           td.rectangle([10,14,22,22], fill=PALETTE["steel_light"]),
                           td.ellipse([9,27,23,30], fill=(0,0,0,70))))
    put(1,1, chest_fn)
    # crate metal variant
    def crate_metal(td,tile):
        td.rectangle([6,10,26,24], fill=PALETTE["mid_gray"], outline=PALETTE["outline"])
        td.rectangle([8,12,24,22], fill=PALETTE["light_gray"])
        td.line([6,16,26,16], fill=PALETTE["outline"], width=1)
        td.rectangle([6,24,26,26], fill=darken(PALETTE["mid_gray"],0.55))
        td.ellipse([7,27,25,30], fill=(0,0,0,75))
    put(2,1, crate_metal)
    put(3,1, rock_fn)
    put(4,1, pillar_fn)
    put(5,1, tree_fn)
    # shadow test tiles
    for c in range(8):
        d.rectangle([c*32, 3*32, c*32+31, 3*32+31], fill=(0,0,0,20), outline=(0,0,0,40))
        d.ellipse([c*32+6, 3*32+22, c*32+25, 3*32+28], fill=(0,0,0, 50 + c*5))

    props.save(DST_PROPS)
    print(f"Saved {DST_PROPS} {props.size} {os.path.getsize(DST_PROPS)} bytes")
    return props

if __name__ == "__main__":
    print("=== Generate 2.5D Assets ===")
    generate_tileset_2p5d()
    generate_shadows()
    generate_props()
    print("=== Done ===")

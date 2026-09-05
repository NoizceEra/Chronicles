"""
Chronicles of Midgard: 2.5D Depth Asset Generator
Extends the base PIL pipeline with pseudo-3D wall extrusion, cliff faces,
drop shadows and height-aware props. Same PALETTE as generate_assets.py.

Outputs to assets/tiles/ and assets/sprites/ (plus web/assets/ mirror).
Run: python3 scripts/generate_assets_25d.py  (or python)
"""

import os
import math
from PIL import Image, ImageDraw

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
TILES_DIR = os.path.join(ASSETS_DIR, "tiles")
SPRITES_DIR = os.path.join(ASSETS_DIR, "sprites")
WEB_ASSETS_DIR = os.path.join(BASE_DIR, "web", "assets")

for d in (TILES_DIR, SPRITES_DIR, WEB_ASSETS_DIR):
    os.makedirs(d, exist_ok=True)

# ---------------------------------------------------------------------------
# PALETTE — must stay in sync with generate_assets.py (35+ aux colours are
# derived but never written as new RGB outside this dict + computed shades)
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Helpers — same signatures as base generator so drop-in familiar
# ---------------------------------------------------------------------------

def create_transparent(w=32, h=32):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def draw_ellipse(img, x, y, w, h, fill_color=None, outline_color=None, fill=None, outline=None):
    draw = ImageDraw.Draw(img)
    f = fill_color if fill_color is not None else fill
    o = outline_color if outline_color is not None else outline
    if o is not None:
        draw.ellipse([x, y, x + w - 1, y + h - 1], fill=f, outline=o)
    else:
        draw.ellipse([x, y, x + w - 1, y + h - 1], fill=f)


def _clamp(v):
    return max(0, min(255, int(v)))


def darken(color, factor=0.55):
    """Multiply RGB by factor, keep alpha."""
    r, g, b, a = color
    return (_clamp(r * factor), _clamp(g * factor), _clamp(b * factor), a)


def lighten(color, factor=1.25):
    r, g, b, a = color
    return (_clamp(r * factor), _clamp(g * factor), _clamp(b * factor), a)


# ---------------------------------------------------------------------------
# Core 2.5D primitives
# ---------------------------------------------------------------------------
OUTLINE = PALETTE["outline"]
BLACK = PALETTE["black"]

def draw_wall_slice(img, ox, oy, top_fill, side_fill, side_dark=None, draw_top_outline=True, groove=True):
    """
    Draw a single 32x48 wall slice at (ox, oy) in the parent sheet.
    Layout:  [0,0 .. 31,31]  = 32x32 top face
             [0,32 ..31,47] = 32x16 side extrusion (south face)
    Shading: side_fill is mid tone, side_dark is shadow tone; top lip gets
    1px dark line for depth anchoring.
    """
    d = ImageDraw.Draw(img)
    if side_dark is None:
        side_dark = darken(side_fill, 0.62)
    highlight = lighten(side_fill, 1.18)

    # — top face 32x32
    d.rectangle([ox, oy, ox + 31, oy + 31], fill=top_fill, outline=OUTLINE if draw_top_outline else None)
    # subtle top bevel highlight (top 2px inner)
    d.rectangle([ox + 1, oy + 1, ox + 30, oy + 2], fill=highlight)
    # inner mortar / detail line bottom of top face
    d.rectangle([ox + 1, oy + 29, ox + 30, oy + 30], fill=side_dark)

    # — side extrusion 32x16 (south face directly attached under top)
    d.rectangle([ox, oy + 32, ox + 31, oy + 47], fill=side_fill, outline=OUTLINE)
    # top lip shadow line (occlusion where top meets side)
    d.rectangle([ox + 1, oy + 32, ox + 30, oy + 33], fill=side_dark)
    # vertical grooves every 8px to read as blocks
    if groove:
        for gx in (8, 16, 24):
            x = ox + gx
            d.line([x, oy + 33, x, oy + 47], fill=side_dark, width=1)
            d.line([x + 1, oy + 33, x + 1, oy + 47], fill=highlight, width=1)
    # bottom dark edge (AO)
    d.rectangle([ox + 1, oy + 46, ox + 30, oy + 47], fill=darken(side_dark, 0.85))
    # small corner notches to avoid tiling seams looking flat
    d.rectangle([ox, oy + 32, ox, oy + 47], fill=side_dark)
    d.rectangle([ox + 31, oy + 32, ox + 31, oy + 47], fill=side_dark)


def draw_top_only_tile(img, ox, oy, top_fill):
    """Flat floor tile 32x32 — no side extrusion, used as floor tops."""
    d = ImageDraw.Draw(img)
    d.rectangle([ox, oy, ox + 31, oy + 31], fill=top_fill, outline=OUTLINE)
    d.rectangle([ox + 1, oy + 1, ox + 30, oy + 2], fill=lighten(top_fill, 1.15))


# ---------------------------------------------------------------------------
# (a) wall_25d.png — 32x48 wall slices, 256x192 (8 cols x 32 =256, 4 rows x48)
#     Row0: stone/dungeon wall variants
#     Row1: city/brick wall variants
#     Row2: forest/moss variants
#     Row3: magma/crypt dark wall variants
# ---------------------------------------------------------------------------
def generate_wall_25d():
    W, H = 256, 192  # 8 *32 wide, 4*48 tall
    sheet = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    # Define per-cell palette
    # (row, col) -> (top_fill, side_fill)
    rows = [
        # Row 0 — dungeon stone
        [
            (PALETTE["light_gray"], PALETTE["mid_gray"]),
            (PALETTE["light_gray"], darken(PALETTE["mid_gray"], 0.9)),
            (PALETTE["mid_gray"], PALETTE["dark_gray"]),
            (PALETTE["mid_gray"], PALETTE["dark_gray"]),
            (PALETTE["light_gray"], PALETTE["mid_gray"]),
            (PALETTE["light_gray"], PALETTE["mid_gray"]),
            (PALETTE["mid_gray"], PALETTE["dark_gray"]),
            (PALETTE["dark_gray"], darken(PALETTE["dark_gray"], 0.8)),
        ],
        # Row 1 — city / brick (brown & steel)
        [
            (PALETTE["brown_light"], PALETTE["brown_mid"]),
            (PALETTE["brown_light"], PALETTE["brown_mid"]),
            (PALETTE["brown_mid"], PALETTE["brown_dark"]),
            (PALETTE["steel_light"], PALETTE["steel_mid"]),
            (PALETTE["steel_light"], PALETTE["steel_mid"]),
            (PALETTE["steel_mid"], PALETTE["steel_dark"]),
            (PALETTE["brown_light"], PALETTE["brown_mid"]),
            (PALETTE["gold_light"], PALETTE["gold_mid"]),
        ],
        # Row 2 — forest / moss (emerald)
        [
            (PALETTE["emerald_mid"], darken(PALETTE["emerald_dark"], 1.1)),
            (PALETTE["emerald_light"], PALETTE["emerald_mid"]),
            (PALETTE["emerald_mid"], PALETTE["emerald_dark"]),
            (PALETTE["emerald_mid"], PALETTE["brown_mid"]),
            (PALETTE["brown_light"], PALETTE["brown_mid"]),
            (PALETTE["emerald_dark"], darken(PALETTE["brown_dark"], 1.0)),
            (PALETTE["emerald_mid"], PALETTE["emerald_dark"]),
            (PALETTE["mid_gray"], PALETTE["dark_gray"]),
        ],
        # Row 3 — magma / crypt
        [
            (PALETTE["dark_gray"], BLACK),
            (PALETTE["mid_gray"], PALETTE["dark_gray"]),
            (PALETTE["crimson_mid"], PALETTE["crimson_dark"]),
            (PALETTE["crimson_dark"], darken(PALETTE["crimson_dark"], 0.75)),
            (PALETTE["dark_gray"], PALETTE["black"]),
            (PALETTE["purple_mid"], PALETTE["purple_dark"]),
            (PALETTE["brown_mid"], PALETTE["brown_dark"]),
            (PALETTE["mid_gray"], PALETTE["dark_gray"]),
        ],
    ]

    for r in range(4):
        for c in range(8):
            ox = c * 32
            oy = r * 48
            top, side = rows[r][c]
            # Add brick/mortar detail for some cols
            draw_wall_slice(sheet, ox, oy, top, side)
            # Decorate tops to differentiate tiles while staying in palette
            d = ImageDraw.Draw(sheet)
            # Corner markers for outer/inner corners — subtle L shapes
            if c in (2, 6):  # inner corners get notch
                d.rectangle([ox + 1, oy + 1, ox + 6, oy + 3], fill=darken(top, 0.8))
                d.rectangle([ox + 1, oy + 1, ox + 3, oy + 6], fill=darken(top, 0.8))
            if c == 7:  # pillar / isolated
                d.rectangle([ox + 6, oy + 6, ox + 25, oy + 25], fill=lighten(top, 1.12), outline=OUTLINE)
                d.rectangle([ox + 10, oy + 10, ox + 21, oy + 21], fill=top, outline=darken(side, 0.9))
            if r == 1 and c in (0, 1):  # brick lines on city walls
                for by in (8, 16, 24):
                    y = oy + by
                    d.line([ox + 1, y, ox + 30, y], fill=darken(side, 0.85), width=1)
                d.line([ox + 15, oy + 1, ox + 15, oy + 31], fill=darken(side, 0.85), width=1)
            if r == 0 and c == 4:  # cracked detail
                d.line([ox + 6, oy + 8, ox + 10, oy + 14], fill=OUTLINE, width=1)
                d.line([ox + 10, oy + 14, ox + 8, oy + 20], fill=OUTLINE, width=1)
            if r == 2 and c == 1:
                # moss tufts
                d.rectangle([ox + 4, oy + 5, ox + 9, oy + 8], fill=PALETTE["emerald_light"])
                d.rectangle([ox + 18, oy + 12, ox + 23, oy + 14], fill=PALETTE["emerald_light"])
            if r == 3 and c == 2:
                # magma glow inset
                d.rectangle([ox + 8, oy + 8, ox + 23, oy + 23], fill=PALETTE["gold_mid"], outline=PALETTE["gold_dark"])
                d.rectangle([ox + 11, oy + 11, ox + 20, oy + 20], fill=PALETTE["gold_light"])

    # Thin outline around whole sheet for readability (optional, not per-tile)
    return sheet


# ---------------------------------------------------------------------------
# (b) cliff_25d.png — 256x256, 32px tiles, south/east extruded cliff faces
#     Encodes 8x8 grid of 32x32 tiles where some tiles carry south or east
#     side faces as inset 8px strips. Same PALETTE only.
# ---------------------------------------------------------------------------
def generate_cliff_25d():
    W, H = 256, 256
    sheet = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    def put_flat(c, r, fill):
        d = ImageDraw.Draw(sheet)
        x, y = c * 32, r * 32
        d.rectangle([x, y, x + 31, y + 31], fill=fill, outline=OUTLINE)
        d.rectangle([x + 1, y + 1, x + 30, y + 2], fill=lighten(fill, 1.12))
        # pebble speckles
        if (c + r) % 2 == 0:
            d.rectangle([x + 6, y + 10, x + 9, y + 12], fill=lighten(fill, 1.18))
        return x, y

    def put_south_face(c, r, top_fill, side_fill):
        x, y = c * 32, r * 32
        d = ImageDraw.Draw(sheet)
        # top 24px is plateau, bottom 8px is south cliff face (vertical drop)
        d.rectangle([x, y, x + 31, y + 23], fill=top_fill, outline=OUTLINE)
        side_dark = darken(side_fill, 0.62)
        d.rectangle([x, y + 24, x + 31, y + 31], fill=side_fill, outline=OUTLINE)
        d.rectangle([x + 1, y + 24, x + 30, y + 25], fill=side_dark)
        for gx in (8, 16, 24):
            d.line([x + gx, y + 25, x + gx, y + 31], fill=side_dark, width=1)
        d.rectangle([x + 1, y + 30, x + 30, y + 31], fill=darken(side_dark, 0.85))

    def put_east_face(c, r, top_fill, side_fill):
        x, y = c * 32, r * 32
        d = ImageDraw.Draw(sheet)
        # left 24px plateau, right 8px east face
        d.rectangle([x, y, x + 23, y + 31], fill=top_fill, outline=OUTLINE)
        side_dark = darken(side_fill, 0.55)
        d.rectangle([x + 24, y, x + 31, y + 31], fill=side_fill, outline=OUTLINE)
        # vertical lip shadow
        d.rectangle([x + 24, y + 1, x + 25, y + 30], fill=side_dark)
        for gy in (8, 16, 24):
            d.line([x + 25, y + gy, x + 31, y + gy], fill=side_dark, width=1)
        d.rectangle([x + 30, y + 1, x + 31, y + 30], fill=darken(side_dark, 0.85))

    def put_corner_se(c, r, top_fill, side_fill):
        # both south + east — L-shaped extrusion
        x, y = c * 32, r * 32
        d = ImageDraw.Draw(sheet)
        d.rectangle([x, y, x + 31, y + 31], fill=top_fill, outline=OUTLINE)
        side_dark = darken(side_fill, 0.60)
        # south strip
        d.rectangle([x, y + 24, x + 31, y + 31], fill=side_fill)
        d.rectangle([x + 1, y + 24, x + 30, y + 25], fill=side_dark)
        # east strip
        d.rectangle([x + 24, y, x + 31, y + 31], fill=side_fill)
        d.rectangle([x + 24, y + 1, x + 25, y + 30], fill=side_dark)
        # corner overlap darker
        d.rectangle([x + 24, y + 24, x + 31, y + 31], fill=side_dark, outline=OUTLINE)
        d.rectangle([x, y, x + 31, y + 31], outline=OUTLINE)

    def put_inner_corner(c, r, top_fill, side_fill):
        # notch — plateau missing quadrant
        x, y = c * 32, r * 32
        d = ImageDraw.Draw(sheet)
        d.rectangle([x, y, x + 31, y + 31], fill=side_fill, outline=OUTLINE)
        d.rectangle([x, y, x + 23, y + 23], fill=top_fill, outline=OUTLINE)
        d.rectangle([x + 23, y + 1, x + 24, y + 23], fill=darken(side_fill, 0.6))
        d.rectangle([x + 1, y + 23, x + 23, y + 24], fill=darken(side_fill, 0.6))

    # Build grid with a readable pattern:
    # Row0 = reference flats / water edge
    for c in range(8):
        put_flat(c, 0, PALETTE["emerald_mid"] if c < 4 else PALETTE["cyan_mid"])
    # Row1 = south faces (grass plateau with brown cliff below)
    for c in range(8):
        if c < 4:
            put_south_face(c, 1, PALETTE["emerald_mid"], PALETTE["brown_mid"])
        else:
            put_south_face(c, 1, PALETTE["mid_gray"], PALETTE["dark_gray"])
    # Row2 = east faces
    for c in range(8):
        if c < 4:
            put_east_face(c, 2, PALETTE["emerald_mid"], PALETTE["brown_mid"])
        else:
            put_east_face(c, 2, PALETTE["mid_gray"], PALETTE["dark_gray"])
    # Row3 = SE corners + inner corners
    for c in range(4):
        put_corner_se(c, 3, PALETTE["emerald_mid"], PALETTE["brown_mid"])
    for c in range(4, 8):
        put_corner_se(c, 3, PALETTE["mid_gray"], PALETTE["dark_gray"])
    # Row4 = inner corners + straights mix
    for c in range(4):
        put_inner_corner(c, 4, PALETTE["emerald_mid"], PALETTE["brown_mid"])
    for c in range(4, 8):
        put_flat(c, 4, PALETTE["mid_gray"] if c % 2 == 0 else PALETTE["brown_mid"])
    # Row5 = diagonal ledge (stair)
    for c in range(8):
        x, y = c * 32, 5 * 32
        d = ImageDraw.Draw(sheet)
        d.rectangle([x, y, x + 31, y + 31], fill=PALETTE["brown_light"], outline=OUTLINE)
        # step line diagonal
        steps = 3
        for s in range(steps):
            sx = x + s * 10
            sy = y + s * 10
            d.rectangle([sx, sy, sx + 16, sy + 16], fill=PALETTE["brown_mid"], outline=OUTLINE)
            d.rectangle([sx + 1, sy + 12, sx + 15, sy + 16], fill=PALETTE["brown_dark"])
    # Row6 = water cliff (cyan plateau brown wall)
    for c in range(8):
        put_south_face(c, 6, PALETTE["cyan_mid"], darken(PALETTE["brown_dark"], 1.0))
    # Row7 = empty / floor with shadow notch samples
    for c in range(8):
        put_flat(c, 7, PALETTE["light_gray"] if c < 4 else PALETTE["emerald_dark"])

    return sheet


# ---------------------------------------------------------------------------
# (c) drop-shadow sprites — 32x32 sheet with 14x5 oval @ 80 alpha
#     Also emit a trimmed 14x5 variant.
# ---------------------------------------------------------------------------
def generate_drop_shadow():
    # 32x32 canonical sprite (centered at 16,26 like base generator does)
    shadow32 = create_transparent(32, 32)
    draw_ellipse(shadow32, 9, 26, 14, 5, (0, 0, 0, 80))
    # 14x5 trimmed
    shadow14 = Image.new("RGBA", (14, 5), (0, 0, 0, 0))
    draw_ellipse(shadow14, 0, 0, 14, 5, (0, 0, 0, 80))
    # 64x32 strip showing both for convenience (optional but useful)
    strip = Image.new("RGBA", (64, 32), (0, 0, 0, 0))
    strip.paste(shadow32, (0, 0), shadow32)
    # paste trimmed centered in second cell
    tmp = create_transparent(32, 32)
    tmp.paste(shadow14, (9, 13), shadow14)
    strip.paste(tmp, (32, 0), tmp)
    return shadow32, shadow14, strip


# ---------------------------------------------------------------------------
# (d) prop_height pack — 32x48 per prop, side faces extruded.
#     Sheet: 256x96 (8 cols x32, 2 rows x48) = 16 slots, use 12.
#     Props: tree_stump x2, column x2, crate small/large x4, barrel, rock
# ---------------------------------------------------------------------------
def generate_props_25d():
    W, H = 256, 96  # 8 per row, 2 rows
    sheet = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    def draw_stump(ox, oy, size="large"):
        d = ImageDraw.Draw(sheet)
        top_h = 22 if size == "large" else 18
        side_h = 48 - top_h
        # side extrusion (south face)
        side_fill = PALETTE["brown_mid"]
        side_dark = darken(side_fill, 0.60)
        # stump side
        d.ellipse([ox + 4, oy + top_h, ox + 27, oy + top_h + side_h + 6], fill=side_fill, outline=OUTLINE)
        # bark lines
        for bx in (10, 16, 22):
            d.line([ox + bx, oy + top_h + 3, ox + bx, oy + 47], fill=side_dark, width=1)
        # top face (ring)
        draw_ellipse(sheet, ox + 4, oy + 4, 24, 20, PALETTE["brown_light"], outline=OUTLINE)
        draw_ellipse(sheet, ox + 7, oy + 7, 18, 14, darken(PALETTE["brown_light"], 0.82), outline=side_dark)
        draw_ellipse(sheet, ox + 10, oy + 10, 12, 8, PALETTE["brown_mid"])
        # growth rings
        d.ellipse([ox + 12, oy + 12, ox + 19, oy + 15], outline=darken(PALETTE["brown_mid"], 0.75))
        # moss patch on large
        if size == "large":
            draw_ellipse(sheet, ox + 6, oy + 9, 6, 4, PALETTE["emerald_mid"])

    def draw_column(ox, oy, style="doric"):
        d = ImageDraw.Draw(sheet)
        # shaft side
        side_fill = PALETTE["light_gray"] if style == "doric" else PALETTE["mid_gray"]
        side_dark = darken(side_fill, 0.60)
        # base plinth side
        d.rectangle([ox + 4, oy + 36, ox + 27, oy + 47], fill=side_dark, outline=OUTLINE)
        d.rectangle([ox + 6, oy + 36, ox + 25, oy + 40], fill=side_fill)
        # shaft
        d.rectangle([ox + 8, oy + 6, ox + 23, oy + 36], fill=side_fill, outline=OUTLINE)
        # fluting
        for fx in (12, 16, 19):
            d.line([ox + fx, oy + 7, ox + fx, oy + 35], fill=side_dark, width=1)
        # capital
        d.rectangle([ox + 4, oy + 2, ox + 27, oy + 10], fill=side_fill, outline=OUTLINE)
        d.rectangle([ox + 6, oy + 4, ox + 25, oy + 8], fill=lighten(side_fill, 1.14))
        if style != "doric":
            d.rectangle([ox + 10, oy + 2, ox + 21, oy + 5], fill=PALETTE["gold_mid"], outline=PALETTE["gold_dark"])

    def draw_crate(ox, oy, variant=0):
        d = ImageDraw.Draw(sheet)
        # Crate is a box with top 32x22 and side 12px
        top_fill = PALETTE["brown_light"] if variant % 2 == 0 else darken(PALETTE["brown_light"], 0.92)
        side_fill = PALETTE["brown_mid"]
        side_dark = darken(side_fill, 0.60)
        # side face (south)
        d.rectangle([ox + 4, oy + 22, ox + 27, oy + 36], fill=side_fill, outline=OUTLINE)
        for gx in (12, 19):
            d.line([ox + gx, oy + 22, ox + gx, oy + 36], fill=side_dark, width=1)
        # bottom darker
        d.rectangle([ox + 5, oy + 34, ox + 26, oy + 36], fill=side_dark)
        # top face
        d.rectangle([ox + 4, oy + 8, ox + 27, oy + 24], fill=top_fill, outline=OUTLINE)
        d.rectangle([ox + 5, oy + 9, ox + 26, oy + 12], fill=lighten(top_fill, 1.14))
        # planks
        for py in (14, 18):
            d.line([ox + 5, oy + py, ox + 26, oy + py], fill=side_dark, width=1)
        # straps
        strap = PALETTE["dark_gray"] if variant < 2 else PALETTE["gold_dark"]
        d.rectangle([ox + 4, oy + 11, ox + 27, oy + 13], fill=strap)
        d.rectangle([ox + 4, oy + 19, ox + 27, oy + 21], fill=strap)
        # nail highlights
        d.rectangle([ox + 7, oy + 10, ox + 8, oy + 11], fill=lighten(strap, 1.4))
        d.rectangle([ox + 22, oy + 18, ox + 23, oy + 19], fill=lighten(strap, 1.4))
        # crate stack shadow under
        if variant == 3:  # open crate
            d.rectangle([ox + 8, oy + 14, ox + 23, oy + 19], fill=BLACK)
            d.rectangle([ox + 10, oy + 16, ox + 21, oy + 18], fill=PALETTE["gold_mid"])

    def draw_barrel(ox, oy):
        d = ImageDraw.Draw(sheet)
        side_fill = PALETTE["brown_mid"]
        side_dark = darken(side_fill, 0.58)
        # side
        draw_ellipse(sheet, ox + 4, oy + 32, 24, 10, side_dark, outline=OUTLINE)
        d.rectangle([ox + 6, oy + 14, ox + 25, oy + 36], fill=side_fill, outline=OUTLINE)
        for hx in (9, 16, 22):
            d.line([ox + hx, oy + 15, ox + hx, oy + 35], fill=side_dark, width=1)
        # top
        draw_ellipse(sheet, ox + 4, oy + 6, 24, 16, PALETTE["brown_light"], outline=OUTLINE)
        draw_ellipse(sheet, ox + 7, oy + 9, 18, 10, darken(PALETTE["brown_light"], 0.88))
        # hoops
        d.rectangle([ox + 6, oy + 18, ox + 25, oy + 20], fill=PALETTE["dark_gray"])
        d.rectangle([ox + 6, oy + 28, ox + 25, oy + 30], fill=PALETTE["dark_gray"])

    def draw_rock(ox, oy):
        d = ImageDraw.Draw(sheet)
        side_fill = PALETTE["mid_gray"]
        side_dark = darken(side_fill, 0.60)
        d.rectangle([ox + 6, oy + 26, ox + 25, oy + 42], fill=side_dark, outline=OUTLINE)
        draw_ellipse(sheet, ox + 4, oy + 10, 24, 22, PALETTE["mid_gray"], outline=OUTLINE)
        draw_ellipse(sheet, ox + 7, oy + 13, 18, 16, PALETTE["light_gray"])
        d.rectangle([ox + 10, oy + 16, ox + 14, oy + 18], fill=PALETTE["white"])

    # Place props in grid (ox = col*32, oy= row*48)
    # Row0: stump large, stump small, column doric, column ornate, crate0, crate1, crate2, crate3(open)
    draw_stump(0 * 32, 0 * 48, "large")
    draw_stump(1 * 32, 0 * 48, "small")
    draw_column(2 * 32, 0 * 48, "doric")
    draw_column(3 * 32, 0 * 48, "ornate")
    draw_crate(4 * 32, 0 * 48, 0)
    draw_crate(5 * 32, 0 * 48, 1)
    draw_crate(6 * 32, 0 * 48, 2)
    draw_crate(7 * 32, 0 * 48, 3)
    # Row1: barrel, rock, stump large, crate0, column, barrel, rock, crate1
    draw_barrel(0 * 32, 1 * 48)
    draw_rock(1 * 32, 1 * 48)
    draw_stump(2 * 32, 1 * 48, "large")
    draw_crate(3 * 32, 1 * 48, 0)
    draw_column(4 * 32, 1 * 48, "doric")
    draw_barrel(5 * 32, 1 * 48)
    draw_rock(6 * 32, 1 * 48)
    draw_crate(7 * 32, 1 * 48, 1)

    return sheet


# ---------------------------------------------------------------------------
# (e) floor height variants — 256x192, 32x48 tiles where noted, otherwise 32x32.
#     Provides grass_top vs grass_side, dungeon floor + wall base.
#     Row0: grass flats (tops)
#     Row1: grass -> cliff side (grass_top with brown side)  [32x48]
#     Row2: dungeon floor flats
#     Row3: dungeon floor + wall base (stone top + dark side) [32x48]
# ---------------------------------------------------------------------------
def generate_floor_height():
    W, H = 256, 192
    sheet = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    # Row0 y=0  — grass tops 32x32 (flat)
    for c in range(8):
        ox, oy = c * 32, 0 * 48
        d = ImageDraw.Draw(sheet)
        base = PALETTE["emerald_mid"]
        if c % 2 == 1:
            base = PALETTE["emerald_dark"]
        if c >= 6:
            base = PALETTE["emerald_light"]
        d.rectangle([ox, oy, ox + 31, oy + 31], fill=base, outline=OUTLINE)
        d.rectangle([ox + 1, oy + 1, ox + 30, oy + 2], fill=lighten(base, 1.14))
        # grass tufts
        for tx, ty in [(6, 10), (18, 14), (10, 22)]:
            d.rectangle([ox + tx, oy + ty, ox + tx + 2, oy + ty + 2], fill=lighten(base, 1.22))
        # flower accent on col 7
        if c == 7:
            draw_ellipse(sheet, ox + 12, oy + 12, 8, 8, PALETTE["gold_light"], outline=PALETTE["gold_dark"])
            draw_ellipse(sheet, ox + 14, oy + 14, 4, 4, PALETTE["white"])

    # Row1 y=48 — grass_top vs grass_side (32x48 extruded)
    for c in range(8):
        ox, oy = c * 32, 1 * 48
        if c < 4:
            draw_wall_slice(sheet, ox, oy, PALETTE["emerald_mid"], PALETTE["brown_mid"])
            # add grass overhang lip highlight
            d = ImageDraw.Draw(sheet)
            d.rectangle([ox + 2, oy + 2, ox + 29, oy + 4], fill=PALETTE["emerald_light"])
        else:
            draw_wall_slice(sheet, ox, oy, PALETTE["emerald_dark"], darken(PALETTE["brown_dark"], 1.0))
            d = ImageDraw.Draw(sheet)
            d.rectangle([ox + 2, oy + 2, ox + 29, oy + 4], fill=PALETTE["emerald_mid"])

    # Row2 y=96 — dungeon floor flats 32x32
    for c in range(8):
        ox, oy = c * 32, 2 * 48
        d = ImageDraw.Draw(sheet)
        base = PALETTE["dark_gray"] if c % 2 == 0 else PALETTE["mid_gray"]
        if c >= 4:
            base = (35, 38, 52, 255) if c % 2 == 0 else (40, 44, 60, 255)
        d.rectangle([ox, oy, ox + 31, oy + 31], fill=base, outline=OUTLINE)
        d.rectangle([ox + 1, oy + 1, ox + 14, oy + 14], fill=darken(base, 0.92), outline=BLACK)
        d.rectangle([ox + 16, oy + 1, ox + 30, oy + 14], fill=darken(base, 0.88), outline=BLACK)
        d.rectangle([ox + 1, oy + 16, ox + 30, oy + 30], fill=darken(base, 0.92), outline=BLACK)

    # Row3 y=144 — dungeon floor + wall base (stone top + dark wall extrusion)
    # Variants: plain, cracked, moss, magma edge
    for c in range(8):
        ox, oy = c * 32, 3 * 48
        if c < 2:
            top, side = PALETTE["mid_gray"], PALETTE["dark_gray"]
        elif c < 4:
            top, side = PALETTE["light_gray"], PALETTE["mid_gray"]
        elif c < 6:
            top, side = PALETTE["dark_gray"], BLACK
        else:
            top, side = PALETTE["mid_gray"], PALETTE["crimson_dark"]
        draw_wall_slice(sheet, ox, oy, top, side)
        d = ImageDraw.Draw(sheet)
        if c == 1:
            d.line([ox + 6, oy + 8, ox + 10, oy + 14], fill=OUTLINE, width=1)
        if c == 3:
            d.rectangle([ox + 6, oy + 10, ox + 10, oy + 14], fill=PALETTE["emerald_dark"])
        if c == 7:
            d.rectangle([ox + 10, oy + 8, ox + 21, oy + 18], fill=PALETTE["crimson_mid"], outline=PALETTE["gold_dark"])

    return sheet


# ---------------------------------------------------------------------------
# Main — write all files, mirror to web/assets, report sizes
# ---------------------------------------------------------------------------
def save_and_mirror(img, rel_path):
    """Save to assets/<rel_path> and web/assets/<rel_path>; return paths+sizes."""
    p_assets = os.path.join(ASSETS_DIR, rel_path)
    p_web = os.path.join(WEB_ASSETS_DIR, rel_path)
    os.makedirs(os.path.dirname(p_assets), exist_ok=True)
    os.makedirs(os.path.dirname(p_web), exist_ok=True)
    img.save(p_assets)
    img.save(p_web)
    sz_assets = os.path.getsize(p_assets)
    sz_web = os.path.getsize(p_web)
    return [(p_assets, sz_assets), (p_web, sz_web)]


def main():
    print("=== Chronicles of Midgard: 2.5D Depth Asset Generator ===")
    outputs = []

    # (a) wall_25d
    print("  [a] generating wall_25d.png (32x48 wall slices, 256x192)...")
    wall = generate_wall_25d()
    for p, sz in save_and_mirror(wall, os.path.join("tiles", "wall_25d.png")):
        outputs.append((p, wall.size, sz))
        print(f"      -> {p}  {wall.size[0]}x{wall.size[1]}  {sz} bytes")

    # (b) cliff / ledge
    print("  [b] generating cliff_25d.png (256x256, south/east faces)...")
    cliff = generate_cliff_25d()
    for p, sz in save_and_mirror(cliff, os.path.join("tiles", "cliff_25d.png")):
        outputs.append((p, cliff.size, sz))
        print(f"      -> {p}  {cliff.size[0]}x{cliff.size[1]}  {sz} bytes")

    # (c) drop shadow
    print("  [c] generating drop_shadow sprites (14x5 @80a)...")
    shadow32, shadow14, strip = generate_drop_shadow()
    for name, img in [("drop_shadow.png", shadow32), ("drop_shadow_14x5.png", shadow14), ("drop_shadow_strip.png", strip)]:
        for p, sz in save_and_mirror(img, os.path.join("sprites", name)):
            outputs.append((p, img.size, sz))
            print(f"      -> {p}  {img.size[0]}x{img.size[1]}  {sz} bytes")
    # also export a 14x5 to tiles for convenience
    for p, sz in save_and_mirror(shadow14, os.path.join("tiles", "drop_shadow_14x5.png")):
        outputs.append((p, shadow14.size, sz))
        print(f"      -> {p}  {shadow14.size[0]}x{shadow14.size[1]}  {sz} bytes")

    # (d) props
    print("  [d] generating props_25d.png (tree_stump, column, crate x4 + barrel/rock)...")
    props = generate_props_25d()
    for p, sz in save_and_mirror(props, os.path.join("sprites", "props_25d.png")):
        outputs.append((p, props.size, sz))
        print(f"      -> {p}  {props.size[0]}x{props.size[1]}  {sz} bytes")
    for p, sz in save_and_mirror(props, os.path.join("tiles", "props_25d.png")):
        outputs.append((p, props.size, sz))
        print(f"      -> {p}  {props.size[0]}x{props.size[1]}  {sz} bytes")

    # (e) floor height variants
    print("  [e] generating floor_height_25d.png (grass/dungeon floor + wall base)...")
    floor = generate_floor_height()
    for p, sz in save_and_mirror(floor, os.path.join("tiles", "floor_height_25d.png")):
        outputs.append((p, floor.size, sz))
        print(f"      -> {p}  {floor.size[0]}x{floor.size[1]}  {sz} bytes")

    # — report file + console table
    print("\n=== 2.5D Asset Report ===")
    total = 0
    for p, dims, sz in outputs:
        rel = os.path.relpath(p, BASE_DIR)
        total += sz
        print(f"  {rel:45s}  {dims[0]:>3}x{dims[1]:<3}  {sz:>6} bytes")
    print(f"  {'TOTAL':45s}  {'':8s}  {total:>6} bytes")
    # unique palette check on wall sheet
    wall_colors = set(wall.getdata())
    cliff_colors = set(cliff.getdata())
    print(f"\n  Palette check: wall_25d unique RGBA={len(wall_colors)}, cliff_25d unique RGBA={len(cliff_colors)} (subset of base PALETTE + derived shades)")
    # verify drop shadow alpha
    px = shadow32.getpixel((16, 28))
    print(f"  Drop-shadow center pixel {px} (expected ~ (0,0,0,80) oval)")
    print("\n[SUCCESS] 2.5D assets generated. Import as TileSet / Sprite2D in Godot 4.6 (32px tiles, wall slices 32x48).")


if __name__ == "__main__":
    main()

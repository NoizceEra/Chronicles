"""
Chronicles of Midgard: 2D MMORPG - Comprehensive Asset Suite Generator
Generates pixel-perfect 32x32 spritesheets, FX, tilesets, icons, and Godot 4 .tres SpriteFrames.
"""

import os
import shutil
import math
from PIL import Image, ImageDraw, ImageFont

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
SPRITES_DIR = os.path.join(ASSETS_DIR, "sprites")
TILES_DIR = os.path.join(ASSETS_DIR, "tiles")
WEB_ASSETS_DIR = os.path.join(BASE_DIR, "web", "assets")

os.makedirs(SPRITES_DIR, exist_ok=True)
os.makedirs(TILES_DIR, exist_ok=True)
os.makedirs(WEB_ASSETS_DIR, exist_ok=True)

# Color Palette Definitions
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

def build_spritesheet(frames_4x4):
    sheet = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    for r in range(4):
        for c in range(4):
            frame = frames_4x4[r][c]
            sheet.paste(frame, (c * 32, r * 32), frame)
    return sheet

def generate_hero_frames(hero_name):
    frames = [[None for _ in range(4)] for _ in range(4)]
    
    for r, direction in enumerate(["down", "left", "right", "up"]):
        for c, action in enumerate(["walk0", "idle", "walk1", "attack"]):
            img = create_transparent(32, 32)
            d = ImageDraw.Draw(img)
            
            leg_offset = 0
            body_bob = 0
            if action == "walk0":
                leg_offset = -1
                body_bob = -1
            elif action == "walk1":
                leg_offset = 1
                body_bob = -1
            elif action == "attack":
                body_bob = 1
                
            bx = 16
            by = 16 + body_bob
            
            # Shadow
            draw_ellipse(img, bx - 7, 26, 14, 5, (0, 0, 0, 80))
            
            # 1. KNIGHT (Swordsman / Paladin)
            if hero_name == "knight":
                boot_c = PALETTE["steel_dark"]
                if direction in ["down", "up"]:
                    d.rectangle([bx - 5, by + 7 + (leg_offset if leg_offset > 0 else 0), bx - 2, by + 12], fill=boot_c)
                    d.rectangle([bx + 2, by + 7 + (-leg_offset if leg_offset < 0 else 0), bx + 5, by + 12], fill=boot_c)
                elif direction == "left":
                    d.rectangle([bx - 4 + leg_offset, by + 7, bx - 1, by + 12], fill=boot_c)
                    d.rectangle([bx + 1 - leg_offset, by + 7, bx + 4, by + 12], fill=boot_c)
                elif direction == "right":
                    d.rectangle([bx - 4 - leg_offset, by + 7, bx - 1, by + 12], fill=boot_c)
                    d.rectangle([bx + 1 + leg_offset, by + 7, bx + 4, by + 12], fill=boot_c)
                    
                if direction == "up":
                    d.rectangle([bx - 6, by - 2, bx + 6, by + 9], fill=PALETTE["royal_blue_dark"])
                    d.rectangle([bx - 5, by - 1, bx + 5, by + 8], fill=PALETTE["royal_blue_mid"])
                elif direction in ["left", "right"]:
                    cx = bx + 3 if direction == "left" else bx - 7
                    d.rectangle([cx, by - 1, cx + 4, by + 8], fill=PALETTE["royal_blue_mid"])
                
                # Chestplate
                d.rectangle([bx - 5, by - 3, bx + 5, by + 7], fill=PALETTE["steel_mid"], outline=PALETTE["outline"])
                d.rectangle([bx - 4, by - 2, bx + 4, by + 3], fill=PALETTE["steel_light"])
                if direction == "down":
                    d.rectangle([bx - 1, by - 1, bx + 1, by + 4], fill=PALETTE["gold_mid"])
                    d.rectangle([bx - 3, by + 1, bx + 3, by + 2], fill=PALETTE["gold_mid"])
                
                # Helmet
                d.rectangle([bx - 6, by - 12, bx + 6, by - 4], fill=PALETTE["steel_mid"], outline=PALETTE["outline"])
                d.rectangle([bx - 5, by - 11, bx + 5, by - 9], fill=PALETTE["steel_light"])
                d.rectangle([bx - 2, by - 15, bx + 2, by - 12], fill=PALETTE["royal_blue_light"])
                if direction == "down":
                    d.rectangle([bx - 4, by - 8, bx + 4, by - 6], fill=PALETTE["outline"])
                    d.rectangle([bx - 3, by - 7, bx + 3, by - 7], fill=PALETTE["cyan_light"])
                elif direction == "left":
                    d.rectangle([bx - 6, by - 8, bx - 1, by - 6], fill=PALETTE["outline"])
                    d.rectangle([bx - 5, by - 7, bx - 2, by - 7], fill=PALETTE["cyan_light"])
                elif direction == "right":
                    d.rectangle([bx + 1, by - 8, bx + 6, by - 6], fill=PALETTE["outline"])
                    d.rectangle([bx + 2, by - 7, bx + 5, by - 7], fill=PALETTE["cyan_light"])
                
                # Broadsword & Shield
                if direction == "down":
                    d.rectangle([bx - 8, by, bx - 5, by + 7], fill=PALETTE["royal_blue_mid"], outline=PALETTE["outline"])
                    d.rectangle([bx - 7, by + 2, bx - 6, by + 5], fill=PALETTE["gold_mid"])
                    if action == "attack":
                        d.rectangle([bx + 6, by - 5, bx + 9, by + 8], fill=PALETTE["steel_light"], outline=PALETTE["gold_dark"])
                    else:
                        d.rectangle([bx + 6, by + 1, bx + 8, by + 9], fill=PALETTE["steel_light"])
                        d.rectangle([bx + 5, by + 3, bx + 9, by + 4], fill=PALETTE["gold_dark"])
                elif direction == "left":
                    if action == "attack":
                        d.rectangle([bx - 12, by, bx - 6, by + 4], fill=PALETTE["steel_light"], outline=PALETTE["gold_dark"])
                    else:
                        d.rectangle([bx - 8, by + 1, bx - 5, by + 7], fill=PALETTE["royal_blue_mid"])
                elif direction == "right":
                    if action == "attack":
                        d.rectangle([bx + 6, by, bx + 12, by + 4], fill=PALETTE["steel_light"], outline=PALETTE["gold_dark"])
                    else:
                        d.rectangle([bx + 5, by + 1, bx + 8, by + 7], fill=PALETTE["royal_blue_mid"])
                elif direction == "up":
                    d.rectangle([bx + 6, by - 2, bx + 8, by + 7], fill=PALETTE["steel_light"])
                    d.rectangle([bx - 8, by, bx - 5, by + 6], fill=PALETTE["royal_blue_dark"])

            # 2. WIZARD / MAGE (Arch-Wizard)
            elif hero_name in ["mage", "wizard"]:
                d.rectangle([bx - 6, by + 4, bx + 6, by + 12], fill=PALETTE["purple_dark"], outline=PALETTE["outline"])
                d.rectangle([bx - 4, by + 5, bx + 4, by + 11], fill=PALETTE["purple_mid"])
                d.rectangle([bx - 5, by + 10, bx + 5, by + 11], fill=PALETTE["gold_mid"])
                
                d.rectangle([bx - 5, by - 3, bx + 5, by + 4], fill=PALETTE["purple_mid"], outline=PALETTE["outline"])
                d.rectangle([bx - 2, by - 2, bx + 2, by + 3], fill=PALETTE["purple_light"])
                
                d.rectangle([bx - 4, by - 9, bx + 4, by - 4], fill=PALETTE["skin_mid"])
                if direction == "down":
                    d.rectangle([bx - 3, by - 8, bx - 2, by - 7], fill=PALETTE["cyan_light"])
                    d.rectangle([bx + 2, by - 8, bx + 3, by - 7], fill=PALETTE["cyan_light"])
                elif direction == "left":
                    d.rectangle([bx - 4, by - 8, bx - 2, by - 7], fill=PALETTE["cyan_light"])
                elif direction == "right":
                    d.rectangle([bx + 2, by - 8, bx + 4, by - 7], fill=PALETTE["cyan_light"])
                
                # Wizard Hat
                d.rectangle([bx - 7, by - 10, bx + 7, by - 8], fill=PALETTE["purple_dark"])
                d.rectangle([bx - 5, by - 13, bx + 5, by - 10], fill=PALETTE["purple_mid"])
                d.rectangle([bx - 3, by - 16, bx + 3, by - 13], fill=PALETTE["purple_dark"])
                d.rectangle([bx - 1, by - 18, bx + 1, by - 16], fill=PALETTE["gold_mid"])
                
                # Magic Staff
                staff_c = PALETTE["brown_mid"]
                orb_c = PALETTE["cyan_light"] if action != "attack" else PALETTE["crimson_light"]
                if direction in ["down", "right"]:
                    sx = bx + 7
                    d.rectangle([sx, by - 4, sx + 2, by + 11], fill=staff_c)
                    d.rectangle([sx - 2, by - 8, sx + 4, by - 4], fill=orb_c)
                    d.rectangle([sx - 1, by - 7, sx + 3, by - 5], fill=PALETTE["white"])
                elif direction == "left":
                    sx = bx - 9
                    d.rectangle([sx, by - 4, sx + 2, by + 11], fill=staff_c)
                    d.rectangle([sx - 2, by - 8, sx + 4, by - 4], fill=orb_c)
                elif direction == "up":
                    sx = bx - 7
                    d.rectangle([sx, by - 4, sx + 2, by + 11], fill=staff_c)
                    d.rectangle([sx - 2, by - 8, sx + 4, by - 4], fill=orb_c)

            # 3. ASSASSIN / ROGUE (Shadow Blade / Cross)
            elif hero_name in ["rogue", "assassin"]:
                d.rectangle([bx - 5, by + 6, bx - 2, by + 12], fill=PALETTE["dark_gray"])
                d.rectangle([bx + 2, by + 6, bx + 5, by + 12], fill=PALETTE["dark_gray"])
                
                d.rectangle([bx - 5, by - 3, bx + 5, by + 6], fill=PALETTE["outline"], outline=PALETTE["black"])
                d.rectangle([bx - 4, by - 2, bx + 4, by + 4], fill=PALETTE["dark_gray"])
                d.rectangle([bx - 4, by - 4, bx + 4, by - 2], fill=PALETTE["crimson_mid"])
                if direction in ["left", "down"]:
                    d.rectangle([bx + 3, by - 3, bx + 7, by + 3], fill=PALETTE["crimson_light"])
                elif direction in ["right", "up"]:
                    d.rectangle([bx - 7, by - 3, bx - 3, by + 3], fill=PALETTE["crimson_light"])
                    
                d.rectangle([bx - 5, by - 12, bx + 5, by - 4], fill=PALETTE["outline"])
                d.rectangle([bx - 4, by - 11, bx + 4, by - 6], fill=PALETTE["dark_gray"])
                if direction == "down":
                    d.rectangle([bx - 3, by - 8, bx - 2, by - 7], fill=PALETTE["emerald_light"])
                    d.rectangle([bx + 2, by - 8, bx + 3, by - 7], fill=PALETTE["emerald_light"])
                elif direction == "left":
                    d.rectangle([bx - 4, by - 8, bx - 2, by - 7], fill=PALETTE["emerald_light"])
                elif direction == "right":
                    d.rectangle([bx + 2, by - 8, bx + 4, by - 7], fill=PALETTE["emerald_light"])
                
                katar_c = PALETTE["cyan_light"]
                if action == "attack":
                    if direction == "down":
                        d.rectangle([bx - 8, by + 2, bx - 4, by + 10], fill=katar_c)
                        d.rectangle([bx + 4, by + 2, bx + 8, by + 10], fill=katar_c)
                    elif direction == "left":
                        d.rectangle([bx - 12, by - 2, bx - 4, by + 4], fill=katar_c)
                    elif direction == "right":
                        d.rectangle([bx + 4, by - 2, bx + 12, by + 4], fill=katar_c)
                    elif direction == "up":
                        d.rectangle([bx - 7, by - 6, bx - 4, by + 2], fill=katar_c)
                        d.rectangle([bx + 4, by - 6, bx + 7, by + 2], fill=katar_c)
                else:
                    d.rectangle([bx - 7, by + 2, bx - 5, by + 7], fill=katar_c)
                    d.rectangle([bx + 5, by + 2, bx + 7, by + 7], fill=katar_c)

            # 4. HIGH PRIEST / CLERIC (Acolyte / Priest)
            elif hero_name in ["cleric", "priest", "high_priest"]:
                d.rectangle([bx - 6, by + 3, bx + 6, by + 12], fill=PALETTE["white"], outline=PALETTE["gold_dark"])
                d.rectangle([bx - 4, by + 4, bx + 4, by + 11], fill=PALETTE["light_gray"])
                d.rectangle([bx - 2, by - 2, bx + 2, by + 11], fill=PALETTE["gold_mid"])
                d.rectangle([bx - 1, by + 9, bx + 1, by + 10], fill=PALETTE["gold_light"])
                
                d.rectangle([bx - 5, by - 3, bx + 5, by + 3], fill=PALETTE["white"], outline=PALETTE["gold_dark"])
                
                d.rectangle([bx - 4, by - 9, bx + 4, by - 4], fill=PALETTE["skin_mid"])
                if direction == "down":
                    d.rectangle([bx - 3, by - 8, bx - 2, by - 7], fill=PALETTE["royal_blue_light"])
                    d.rectangle([bx + 2, by - 8, bx + 3, by - 7], fill=PALETTE["royal_blue_light"])
                elif direction == "left":
                    d.rectangle([bx - 4, by - 8, bx - 2, by - 7], fill=PALETTE["royal_blue_light"])
                elif direction == "right":
                    d.rectangle([bx + 2, by - 8, bx + 4, by - 7], fill=PALETTE["royal_blue_light"])
                
                # Holy Mitre
                d.rectangle([bx - 5, by - 15, bx + 5, by - 9], fill=PALETTE["white"], outline=PALETTE["gold_dark"])
                d.rectangle([bx - 1, by - 14, bx + 1, by - 10], fill=PALETTE["gold_mid"])
                d.rectangle([bx - 3, by - 12, bx + 3, by - 11], fill=PALETTE["gold_mid"])
                
                s_c = PALETTE["gold_mid"]
                if direction in ["down", "right"]:
                    sx = bx + 7
                    d.rectangle([sx, by - 3, sx + 2, by + 10], fill=PALETTE["brown_dark"])
                    d.rectangle([sx - 2, by - 8, sx + 4, by - 4], fill=s_c)
                    d.rectangle([sx, by - 7, sx + 2, by - 5], fill=PALETTE["gold_light"])
                elif direction == "left":
                    sx = bx - 8
                    d.rectangle([sx, by - 3, sx + 2, by + 10], fill=PALETTE["brown_dark"])
                    d.rectangle([sx - 2, by - 8, sx + 4, by - 4], fill=s_c)
                elif direction == "up":
                    sx = bx + 6
                    d.rectangle([sx, by - 3, sx + 2, by + 10], fill=PALETTE["brown_dark"])
                    d.rectangle([sx - 2, by - 8, sx + 4, by - 4], fill=s_c)

            # 5. HUNTER (Archer with Bow & Falcon Feather)
            elif hero_name == "hunter":
                d.rectangle([bx - 5, by + 7, bx - 2, by + 12], fill=PALETTE["brown_dark"])
                d.rectangle([bx + 2, by + 7, bx + 5, by + 12], fill=PALETTE["brown_dark"])
                
                d.rectangle([bx - 5, by - 3, bx + 5, by + 7], fill=PALETTE["emerald_dark"], outline=PALETTE["outline"])
                d.rectangle([bx - 4, by - 2, bx + 4, by + 5], fill=PALETTE["emerald_mid"])
                d.rectangle([bx - 3, by + 1, bx + 3, by + 3], fill=PALETTE["brown_mid"])
                
                if direction in ["up", "left", "right"]:
                    qx = bx - 6 if direction != "left" else bx + 3
                    d.rectangle([qx, by - 6, qx + 3, by + 4], fill=PALETTE["brown_dark"])
                    d.rectangle([qx, by - 8, qx + 1, by - 6], fill=PALETTE["white"])
                    d.rectangle([qx + 2, by - 8, qx + 3, by - 6], fill=PALETTE["cyan_light"])
                
                d.rectangle([bx - 4, by - 9, bx + 4, by - 4], fill=PALETTE["skin_mid"])
                if direction == "down":
                    d.rectangle([bx - 3, by - 8, bx - 2, by - 7], fill=PALETTE["brown_dark"])
                    d.rectangle([bx + 2, by - 8, bx + 3, by - 7], fill=PALETTE["brown_dark"])
                elif direction == "left":
                    d.rectangle([bx - 4, by - 8, bx - 2, by - 7], fill=PALETTE["brown_dark"])
                elif direction == "right":
                    d.rectangle([bx + 2, by - 8, bx + 4, by - 7], fill=PALETTE["brown_dark"])
                    
                d.rectangle([bx - 6, by - 13, bx + 5, by - 9], fill=PALETTE["emerald_mid"], outline=PALETTE["outline"])
                d.rectangle([bx - 5, by - 16, bx - 3, by - 12], fill=PALETTE["crimson_light"])
                d.rectangle([bx - 4, by - 18, bx - 2, by - 15], fill=PALETTE["white"])
                
                bow_c = PALETTE["brown_light"]
                if action == "attack":
                    if direction == "down":
                        d.rectangle([bx - 7, by, bx + 7, by + 2], fill=bow_c)
                        d.line([bx - 7, by + 1, bx, by + 6, bx + 7, by + 1], fill=PALETTE["white"])
                    elif direction == "left":
                        d.rectangle([bx - 8, by - 6, bx - 6, by + 8], fill=bow_c)
                        d.line([bx - 7, by - 6, bx - 2, by + 1, bx - 7, by + 8], fill=PALETTE["white"])
                    elif direction == "right":
                        d.rectangle([bx + 6, by - 6, bx + 8, by + 8], fill=bow_c)
                        d.line([bx + 7, by - 6, bx + 2, by + 1, bx + 7, by + 8], fill=PALETTE["white"])
                    elif direction == "up":
                        d.rectangle([bx - 7, by - 6, bx + 7, by - 4], fill=bow_c)
                else:
                    if direction in ["down", "left"]:
                        d.rectangle([bx - 8, by - 4, bx - 6, by + 8], fill=bow_c)
                    else:
                        d.rectangle([bx + 6, by - 4, bx + 8, by + 8], fill=bow_c)

            # 6. BLACKSMITH (Merchant with War Hammer & Apron & Goggles)
            elif hero_name == "blacksmith":
                d.rectangle([bx - 5, by + 7, bx - 2, by + 12], fill=PALETTE["dark_gray"])
                d.rectangle([bx + 2, by + 7, bx + 5, by + 12], fill=PALETTE["dark_gray"])
                
                d.rectangle([bx - 6, by - 3, bx + 6, by + 7], fill=PALETTE["crimson_dark"], outline=PALETTE["outline"])
                d.rectangle([bx - 4, by - 2, bx + 4, by + 7], fill=PALETTE["brown_mid"])
                d.rectangle([bx - 2, by + 3, bx + 2, by + 5], fill=PALETTE["gold_dark"])
                
                d.rectangle([bx - 5, by - 9, bx + 5, by - 4], fill=PALETTE["skin_mid"])
                if direction == "down":
                    d.rectangle([bx - 4, by - 6, bx + 4, by - 3], fill=PALETTE["brown_light"])
                    d.rectangle([bx - 3, by - 8, bx - 2, by - 7], fill=PALETTE["dark_gray"])
                    d.rectangle([bx + 2, by - 8, bx + 3, by - 7], fill=PALETTE["dark_gray"])
                elif direction == "left":
                    d.rectangle([bx - 5, by - 6, bx - 1, by - 3], fill=PALETTE["brown_light"])
                elif direction == "right":
                    d.rectangle([bx + 1, by - 6, bx + 5, by - 3], fill=PALETTE["brown_light"])
                    
                d.rectangle([bx - 5, by - 12, bx + 5, by - 9], fill=PALETTE["brown_dark"])
                d.rectangle([bx - 4, by - 12, bx - 1, by - 9], fill=PALETTE["gold_mid"])
                d.rectangle([bx + 1, by - 12, bx + 4, by - 9], fill=PALETTE["gold_mid"])
                d.rectangle([bx - 3, by - 11, bx - 2, by - 10], fill=PALETTE["cyan_light"])
                d.rectangle([bx + 2, by - 11, bx + 3, by - 10], fill=PALETTE["cyan_light"])
                
                ham_handle = PALETTE["brown_dark"]
                ham_head = PALETTE["steel_mid"]
                if action == "attack":
                    if direction == "down":
                        d.rectangle([bx + 4, by - 2, bx + 6, by + 10], fill=ham_handle)
                        d.rectangle([bx + 1, by + 6, bx + 9, by + 12], fill=ham_head, outline=PALETTE["gold_mid"])
                    elif direction == "left":
                        d.rectangle([bx - 12, by - 4, bx - 4, by + 2], fill=ham_head, outline=PALETTE["gold_mid"])
                    elif direction == "right":
                        d.rectangle([bx + 4, by - 4, bx + 12, by + 2], fill=ham_head, outline=PALETTE["gold_mid"])
                    elif direction == "up":
                        d.rectangle([bx + 4, by - 8, bx + 10, by - 2], fill=ham_head, outline=PALETTE["gold_mid"])
                else:
                    hx = bx + 6
                    d.rectangle([hx, by - 4, hx + 2, by + 10], fill=ham_handle)
                    d.rectangle([hx - 2, by - 8, hx + 4, by - 3], fill=ham_head, outline=PALETTE["gold_mid"])

            frames[r][c] = img

    return frames

def generate_monster_frames(monster_name):
    frames = [[None for _ in range(4)] for _ in range(4)]
    
    for r, direction in enumerate(["down", "left", "right", "up"]):
        for c, action in enumerate(["walk0", "idle", "walk1", "attack"]):
            img = create_transparent(32, 32)
            d = ImageDraw.Draw(img)
            
            bob = 0
            squish_w = 0
            squish_h = 0
            if action == "walk0":
                bob = -2
                squish_w = -1
                squish_h = 2
            elif action == "walk1":
                bob = -1
                squish_w = 1
                squish_h = -1
            elif action == "attack":
                bob = 2
                squish_w = 2
                squish_h = -2
                
            bx = 16
            by = 18 + bob
            
            # SLIMES
            if "slime" in monster_name or monster_name in ["poring", "drops", "poporing", "marin"]:
                palette_map = {
                    "poring": (PALETTE["emerald_dark"], PALETTE["emerald_mid"], PALETTE["emerald_light"]),
                    "slime_green": (PALETTE["emerald_dark"], PALETTE["emerald_mid"], PALETTE["emerald_light"]),
                    "drops": (PALETTE["cyan_dark"], PALETTE["cyan_mid"], PALETTE["cyan_light"]),
                    "slime_blue": (PALETTE["cyan_dark"], PALETTE["cyan_mid"], PALETTE["cyan_light"]),
                    "poporing": (PALETTE["purple_dark"], PALETTE["purple_mid"], PALETTE["purple_light"]),
                    "slime_poison": (PALETTE["purple_dark"], PALETTE["purple_mid"], PALETTE["purple_light"]),
                    "marin": (PALETTE["crimson_dark"], PALETTE["crimson_mid"], PALETTE["crimson_light"]),
                    "slime_red": (PALETTE["crimson_dark"], PALETTE["crimson_mid"], PALETTE["crimson_light"]),
                    "slime_magma": (PALETTE["crimson_dark"], PALETTE["crimson_mid"], PALETTE["gold_light"])
                }
                dark_c, mid_c, light_c = palette_map.get(monster_name, (PALETTE["emerald_dark"], PALETTE["emerald_mid"], PALETTE["emerald_light"]))
                
                draw_ellipse(img, bx - 8, 25, 16, 5, (0, 0, 0, 70))
                rx = 8 + squish_w
                ry = 7 + squish_h
                draw_ellipse(img, bx - rx, by - ry, rx * 2, ry * 2, mid_c, outline=dark_c)
                draw_ellipse(img, bx - rx + 3, by - ry + 2, 5, 3, light_c)
                draw_ellipse(img, bx - rx + 4, by - ry + 3, 2, 2, PALETTE["white"])
                
                if direction == "down":
                    d.rectangle([bx - 4, by - 1, bx - 3, by + 1], fill=PALETTE["outline"])
                    d.rectangle([bx + 3, by - 1, bx + 4, by + 1], fill=PALETTE["outline"])
                    d.rectangle([bx - 1, by + 2, bx + 1, by + 3], fill=PALETTE["outline"])
                elif direction == "left":
                    d.rectangle([bx - 6, by - 1, bx - 5, by + 1], fill=PALETTE["outline"])
                    d.rectangle([bx - 1, by - 1, bx, by + 1], fill=PALETTE["outline"])
                elif direction == "right":
                    d.rectangle([bx, by - 1, bx + 1, by + 1], fill=PALETTE["outline"])
                    d.rectangle([bx + 5, by - 1, bx + 6, by + 1], fill=PALETTE["outline"])
                elif direction == "up":
                    draw_ellipse(img, bx - 3, by - ry + 1, 6, 3, light_c)

            # GOBLIN SCOUT
            elif monster_name in ["goblin", "goblin_scout"]:
                draw_ellipse(img, bx - 6, 26, 12, 5, (0, 0, 0, 80))
                d.rectangle([bx - 4, by + 6, bx - 2, by + 9], fill=PALETTE["brown_dark"])
                d.rectangle([bx + 2, by + 6, bx + 4, by + 9], fill=PALETTE["brown_dark"])
                d.rectangle([bx - 4, by - 1, bx + 4, by + 6], fill=PALETTE["brown_mid"], outline=PALETTE["outline"])
                d.rectangle([bx - 4, by - 8, bx + 4, by - 2], fill=PALETTE["emerald_mid"], outline=PALETTE["outline"])
                d.rectangle([bx - 7, by - 7, bx - 4, by - 5], fill=PALETTE["emerald_light"])
                d.rectangle([bx + 4, by - 7, bx + 7, by - 5], fill=PALETTE["emerald_light"])
                d.rectangle([bx - 5, by - 10, bx + 5, by - 8], fill=PALETTE["crimson_mid"])
                if direction == "down":
                    d.rectangle([bx - 3, by - 6, bx - 2, by - 5], fill=PALETTE["gold_light"])
                    d.rectangle([bx + 2, by - 6, bx + 3, by - 5], fill=PALETTE["gold_light"])
                    d.rectangle([bx - 2, by - 3, bx + 2, by - 3], fill=PALETTE["white"])
                if action == "attack":
                    d.rectangle([bx + 5, by, bx + 9, by + 3], fill=PALETTE["steel_light"])
                else:
                    d.rectangle([bx + 5, by + 2, bx + 7, by + 6], fill=PALETTE["steel_light"])

            # UNDEAD SKELETON
            elif monster_name in ["skeleton", "undead_skeleton"]:
                draw_ellipse(img, bx - 6, 26, 12, 5, (0, 0, 0, 80))
                d.rectangle([bx - 4, by + 5, bx - 3, by + 9], fill=PALETTE["light_gray"])
                d.rectangle([bx + 2, by + 5, bx + 3, by + 9], fill=PALETTE["light_gray"])
                d.rectangle([bx - 4, by - 1, bx + 4, by + 5], fill=PALETTE["outline"])
                d.rectangle([bx - 3, by, bx + 3, by + 1], fill=PALETTE["white"])
                d.rectangle([bx - 3, by + 2, bx + 3, by + 3], fill=PALETTE["white"])
                d.rectangle([bx - 4, by - 8, bx + 4, by - 2], fill=PALETTE["white"], outline=PALETTE["outline"])
                if direction == "down":
                    d.rectangle([bx - 3, by - 6, bx - 2, by - 5], fill=PALETTE["crimson_light"])
                    d.rectangle([bx + 2, by - 6, bx + 3, by - 5], fill=PALETTE["crimson_light"])
                    d.rectangle([bx - 2, by - 3, bx + 2, by - 3], fill=PALETTE["dark_gray"])
                elif direction == "left":
                    d.rectangle([bx - 4, by - 6, bx - 2, by - 5], fill=PALETTE["crimson_light"])
                elif direction == "right":
                    d.rectangle([bx + 2, by - 6, bx + 4, by - 5], fill=PALETTE["crimson_light"])
                scim_c = PALETTE["brown_mid"] if action != "attack" else PALETTE["steel_light"]
                if action == "attack":
                    d.rectangle([bx + 5, by - 2, bx + 10, by + 2], fill=scim_c)
                else:
                    d.rectangle([bx + 5, by + 1, bx + 7, by + 8], fill=scim_c)

            # ORC WARRIOR
            elif monster_name in ["orc", "orc_warrior"]:
                draw_ellipse(img, bx - 8, 26, 16, 6, (0, 0, 0, 90))
                d.rectangle([bx - 6, by + 6, bx - 2, by + 10], fill=PALETTE["brown_dark"])
                d.rectangle([bx + 2, by + 6, bx + 6, by + 10], fill=PALETTE["brown_dark"])
                d.rectangle([bx - 7, by - 2, bx + 7, by + 6], fill=PALETTE["emerald_dark"], outline=PALETTE["outline"])
                d.rectangle([bx - 5, by - 1, bx + 5, by + 5], fill=PALETTE["emerald_mid"])
                d.rectangle([bx - 4, by + 1, bx + 4, by + 3], fill=PALETTE["brown_mid"])
                d.rectangle([bx - 5, by - 10, bx + 5, by - 3], fill=PALETTE["steel_mid"], outline=PALETTE["outline"])
                d.rectangle([bx - 7, by - 12, bx - 5, by - 9], fill=PALETTE["brown_light"])
                d.rectangle([bx + 5, by - 12, bx + 7, by - 9], fill=PALETTE["brown_light"])
                if direction == "down":
                    d.rectangle([bx - 3, by - 7, bx - 2, by - 6], fill=PALETTE["crimson_light"])
                    d.rectangle([bx + 2, by - 7, bx + 3, by - 6], fill=PALETTE["crimson_light"])
                    d.rectangle([bx - 4, by - 4, bx - 3, by - 2], fill=PALETTE["white"])
                    d.rectangle([bx + 3, by - 4, bx + 4, by - 2], fill=PALETTE["white"])
                if action == "attack":
                    d.rectangle([bx + 6, by - 4, bx + 12, by + 4], fill=PALETTE["steel_light"], outline=PALETTE["outline"])
                else:
                    d.rectangle([bx + 6, by - 2, bx + 9, by + 9], fill=PALETTE["steel_light"])

            # MVP BOSS: GOLDEN THIEF BUG
            elif monster_name in ["gtb", "golden_thief_bug"]:
                draw_ellipse(img, bx - 9, 26, 18, 6, (0, 0, 0, 100))
                leg_c = PALETTE["gold_dark"]
                d.line([bx - 10, by, bx - 6, by + 6, bx - 9, by + 10], fill=leg_c)
                d.line([bx + 10, by, bx + 6, by + 6, bx + 9, by + 10], fill=leg_c)
                draw_ellipse(img, bx - 8, by - 6, 16, 14, PALETTE["gold_mid"], outline=PALETTE["gold_dark"])
                draw_ellipse(img, bx - 6, by - 5, 12, 10, PALETTE["gold_light"])
                d.line([bx, by - 5, bx, by + 7], fill=PALETTE["gold_dark"])
                d.rectangle([bx - 4, by - 11, bx + 4, by - 6], fill=PALETTE["gold_dark"])
                d.rectangle([bx - 6, by - 13, bx - 4, by - 10], fill=PALETTE["gold_mid"])
                d.rectangle([bx + 4, by - 13, bx + 6, by - 10], fill=PALETTE["gold_mid"])
                if direction == "down":
                    d.rectangle([bx - 3, by - 9, bx - 2, by - 8], fill=PALETTE["crimson_light"])
                    d.rectangle([bx + 2, by - 9, bx + 3, by - 8], fill=PALETTE["crimson_light"])
                if action == "attack":
                    d.rectangle([bx - 10, by - 10, bx - 8, by - 8], fill=PALETTE["white"])
                    d.rectangle([bx + 8, by - 10, bx + 10, by - 8], fill=PALETTE["white"])
                    d.rectangle([bx, by - 14, bx + 1, by - 13], fill=PALETTE["white"])

            # MVP BOSS: BAPHOMET / LORD OF DEATH
            elif monster_name in ["baphomet", "lord_of_death"]:
                draw_ellipse(img, bx - 10, 26, 20, 6, (0, 0, 0, 110))
                d.rectangle([bx - 6, by + 5, bx + 6, by + 11], fill=PALETTE["black"], outline=PALETTE["crimson_dark"])
                d.polygon([(bx - 12, by - 10), (bx - 4, by - 2), (bx - 14, by + 5)], fill=PALETTE["dark_gray"])
                d.polygon([(bx + 12, by - 10), (bx + 4, by - 2), (bx + 14, by + 5)], fill=PALETTE["dark_gray"])
                d.rectangle([bx - 6, by - 2, bx + 6, by + 5], fill=PALETTE["outline"])
                d.rectangle([bx - 4, by - 1, bx + 4, by + 4], fill=PALETTE["dark_gray"])
                d.rectangle([bx - 5, by - 9, bx + 5, by - 3], fill=PALETTE["black"], outline=PALETTE["outline"])
                d.arc([bx - 11, by - 15, bx - 3, by - 5], 180, 360, fill=PALETTE["gold_mid"], width=2)
                d.arc([bx + 3, by - 15, bx + 11, by - 5], 180, 360, fill=PALETTE["gold_mid"], width=2)
                if direction == "down":
                    d.rectangle([bx - 3, by - 7, bx - 2, by - 6], fill=PALETTE["crimson_light"])
                    d.rectangle([bx + 2, by - 7, bx + 3, by - 6], fill=PALETTE["crimson_light"])
                scythe_c = PALETTE["cyan_light"] if action == "attack" else PALETTE["steel_light"]
                if action == "attack":
                    d.rectangle([bx + 4, by - 10, bx + 7, by + 10], fill=PALETTE["brown_dark"])
                    d.arc([bx - 6, by - 14, bx + 12, by + 4], 0, 180, fill=scythe_c, width=3)
                else:
                    d.rectangle([bx + 7, by - 8, bx + 9, by + 10], fill=PALETTE["brown_dark"])
                    d.arc([bx + 2, by - 12, bx + 12, by - 2], 45, 180, fill=scythe_c, width=3)

            # MVP BOSS: RED ELDER DRAGON
            elif monster_name in ["dragon", "red_dragon"]:
                draw_ellipse(img, bx - 10, 26, 20, 6, (0, 0, 0, 110))
                d.rectangle([bx - 7, by + 4, bx - 3, by + 10], fill=PALETTE["crimson_dark"])
                d.rectangle([bx + 3, by + 4, bx + 7, by + 10], fill=PALETTE["crimson_dark"])
                d.polygon([(bx - 14, by - 12), (bx - 4, by - 1), (bx - 12, by + 3)], fill=PALETTE["crimson_mid"])
                d.polygon([(bx + 14, by - 12), (bx + 4, by - 1), (bx + 12, by + 3)], fill=PALETTE["crimson_mid"])
                d.rectangle([bx - 6, by - 2, bx + 6, by + 6], fill=PALETTE["crimson_dark"], outline=PALETTE["outline"])
                d.rectangle([bx - 4, by, bx + 4, by + 5], fill=PALETTE["gold_mid"])
                d.rectangle([bx - 5, by - 10, bx + 5, by - 3], fill=PALETTE["crimson_mid"], outline=PALETTE["outline"])
                d.polygon([(bx - 6, by - 13), (bx - 4, by - 9), (bx - 2, by - 9)], fill=PALETTE["gold_dark"])
                d.polygon([(bx + 6, by - 13), (bx + 4, by - 9), (bx + 2, by - 9)], fill=PALETTE["gold_dark"])
                if direction == "down":
                    d.rectangle([bx - 3, by - 8, bx - 2, by - 7], fill=PALETTE["gold_light"])
                    d.rectangle([bx + 2, by - 8, bx + 3, by - 7], fill=PALETTE["gold_light"])
                    if action == "attack":
                        d.rectangle([bx - 2, by - 4, bx + 2, by - 1], fill=PALETTE["gold_light"])
                d.line([bx - 8, by + 6, bx - 12, by + 8], fill=PALETTE["crimson_dark"], width=2)

            frames[r][c] = img

    return frames

def generate_spell_fx():
    fx_dict = {}

    fb = create_transparent(32, 32)
    d = ImageDraw.Draw(fb)
    draw_ellipse(fb, 8, 8, 16, 16, PALETTE["crimson_mid"], outline=PALETTE["gold_dark"])
    draw_ellipse(fb, 11, 11, 10, 10, PALETTE["gold_mid"])
    draw_ellipse(fb, 13, 13, 6, 6, PALETTE["white"])
    d.polygon([(6, 12), (2, 16), (6, 20)], fill=PALETTE["crimson_light"])
    d.polygon([(12, 6), (16, 2), (20, 6)], fill=PALETTE["gold_light"])
    fx_dict["projectile_fireball.png"] = fb
    fx_dict["fx_fireball.png"] = fb

    ice = create_transparent(32, 32)
    d = ImageDraw.Draw(ice)
    d.polygon([(6, 28), (11, 8), (16, 28)], fill=PALETTE["cyan_light"], outline=PALETTE["cyan_dark"])
    d.polygon([(14, 28), (19, 4), (24, 28)], fill=PALETTE["white"], outline=PALETTE["cyan_mid"])
    d.polygon([(20, 28), (25, 12), (29, 28)], fill=PALETTE["cyan_light"], outline=PALETTE["cyan_dark"])
    d.rectangle([4, 6, 6, 8], fill=PALETTE["white"])
    d.rectangle([26, 4, 28, 6], fill=PALETTE["white"])
    fx_dict["fx_storm_gust.png"] = ice
    fx_dict["projectile_ice.png"] = ice
    fx_dict["ice_spikes.png"] = ice

    gc = create_transparent(32, 32)
    d = ImageDraw.Draw(gc)
    draw_ellipse(gc, 4, 4, 24, 24, (255, 230, 110, 60))
    d.rectangle([13, 2, 18, 29], fill=PALETTE["gold_mid"], outline=PALETTE["white"])
    d.rectangle([2, 9, 29, 14], fill=PALETTE["gold_mid"], outline=PALETTE["white"])
    d.rectangle([14, 4, 17, 27], fill=PALETTE["white"])
    d.rectangle([4, 10, 27, 13], fill=PALETTE["white"])
    fx_dict["projectile_holy.png"] = gc
    fx_dict["fx_grand_cross.png"] = gc
    fx_dict["grand_cross.png"] = gc

    slash = create_transparent(32, 32)
    d = ImageDraw.Draw(slash)
    d.line([4, 6, 26, 24], fill=PALETTE["cyan_light"], width=3)
    d.line([6, 26, 24, 4], fill=PALETTE["crimson_light"], width=3)
    d.line([8, 10, 22, 20], fill=PALETTE["white"], width=1)
    d.line([10, 22, 20, 8], fill=PALETTE["white"], width=1)
    d.rectangle([14, 14, 17, 17], fill=PALETTE["white"])
    fx_dict["slash_fx.png"] = slash
    fx_dict["fx_sonic_blow.png"] = slash
    fx_dict["sonic_blow.png"] = slash

    arrow = create_transparent(32, 32)
    d = ImageDraw.Draw(arrow)
    d.line([6, 26, 24, 8], fill=PALETTE["brown_light"], width=2)
    d.polygon([(22, 6), (27, 5), (25, 10)], fill=PALETTE["steel_light"])
    d.polygon([(5, 25), (3, 28), (8, 27)], fill=PALETTE["cyan_light"])
    fx_dict["projectile_arrow.png"] = arrow

    falcon = create_transparent(32, 32)
    d = ImageDraw.Draw(falcon)
    d.polygon([(16, 26), (6, 12), (16, 8), (26, 12)], fill=PALETTE["gold_mid"], outline=PALETTE["brown_dark"])
    d.polygon([(16, 24), (10, 14), (16, 10), (22, 14)], fill=PALETTE["gold_light"])
    d.rectangle([15, 24, 17, 28], fill=PALETTE["white"])
    fx_dict["fx_arrow_shower.png"] = arrow
    fx_dict["fx_falcon_strike.png"] = falcon
    fx_dict["falcon_strike.png"] = falcon

    mammon = create_transparent(32, 32)
    d = ImageDraw.Draw(mammon)
    d.line([6, 26, 26, 26], fill=PALETTE["brown_dark"], width=2)
    d.line([12, 26, 16, 22], fill=PALETTE["gold_dark"], width=2)
    draw_ellipse(mammon, 6, 8, 8, 8, PALETTE["gold_mid"], outline=PALETTE["gold_dark"])
    draw_ellipse(mammon, 18, 6, 8, 8, PALETTE["gold_mid"], outline=PALETTE["gold_dark"])
    draw_ellipse(mammon, 12, 14, 8, 8, PALETTE["gold_light"], outline=PALETTE["gold_dark"])
    d.rectangle([9, 11, 11, 13], fill=PALETTE["white"])
    d.rectangle([15, 17, 17, 19], fill=PALETTE["white"])
    fx_dict["fx_mammonite.png"] = mammon
    fx_dict["mammonite.png"] = mammon

    sanc = create_transparent(32, 32)
    d = ImageDraw.Draw(sanc)
    draw_ellipse(sanc, 3, 6, 26, 20, (255, 230, 110, 40), outline=PALETTE["gold_mid"])
    draw_ellipse(sanc, 7, 9, 18, 14, None, outline=PALETTE["white"])
    d.rectangle([14, 8, 17, 24], fill=PALETTE["gold_light"])
    d.rectangle([8, 14, 23, 17], fill=PALETTE["gold_light"])
    fx_dict["fx_sanctuary.png"] = sanc
    fx_dict["sanctuary.png"] = sanc

    return fx_dict

def generate_tilesets():
    tilesets = {}

    def new_sheet():
        return Image.new("RGBA", (256, 256), (0, 0, 0, 0))

    def put_tile(sheet, c, r, tile_img):
        sheet.paste(tile_img, (c * 32, r * 32), tile_img)

    # 1. CAPITAL CITY TILESET
    city_sheet = new_sheet()
    for r in range(8):
        for c in range(8):
            t = create_transparent(32, 32)
            d = ImageDraw.Draw(t)
            d.rectangle([0, 0, 31, 31], fill=PALETTE["steel_light"])
            d.rectangle([1, 1, 14, 14], fill=(200, 215, 235, 255), outline=PALETTE["steel_mid"])
            d.rectangle([16, 1, 30, 14], fill=(190, 205, 225, 255), outline=PALETTE["steel_mid"])
            d.rectangle([1, 16, 30, 30], fill=(200, 215, 235, 255), outline=PALETTE["steel_mid"])
            
            if r == 0 and c == 0:
                pass
            elif r == 0 and c == 1:
                d.rectangle([0, 0, 31, 31], fill=PALETTE["steel_mid"], outline=PALETTE["outline"])
                d.rectangle([2, 2, 13, 10], fill=PALETTE["steel_dark"])
                d.rectangle([18, 2, 29, 10], fill=PALETTE["steel_dark"])
                d.rectangle([0, 12, 31, 14], fill=PALETTE["gold_mid"])
            elif r == 0 and c == 2:
                d.rectangle([0, 0, 31, 31], fill=PALETTE["white"], outline=PALETTE["steel_mid"])
                draw_ellipse(t, 4, 4, 24, 24, PALETTE["cyan_mid"], outline=PALETTE["cyan_dark"])
                draw_ellipse(t, 8, 8, 16, 16, PALETTE["cyan_light"])
                d.rectangle([14, 14, 17, 17], fill=PALETTE["white"])
            elif r == 0 and c == 3:
                d.rectangle([2, 2, 29, 29], fill=PALETTE["brown_mid"], outline=PALETTE["brown_dark"])
                d.rectangle([4, 4, 27, 27], fill=PALETTE["emerald_dark"])
                draw_ellipse(t, 6, 6, 6, 6, PALETTE["crimson_light"])
                draw_ellipse(t, 19, 7, 6, 6, PALETTE["gold_light"])
                draw_ellipse(t, 12, 18, 6, 6, PALETTE["purple_light"])
            elif r == 1 and c == 0:
                d.rectangle([0, 0, 31, 14], fill=PALETTE["crimson_mid"])
                d.rectangle([8, 0, 15, 14], fill=PALETTE["white"])
                d.rectangle([24, 0, 31, 14], fill=PALETTE["white"])
                d.rectangle([2, 16, 29, 30], fill=PALETTE["brown_mid"], outline=PALETTE["brown_dark"])
            elif r == 1 and c == 1:
                d.rectangle([14, 6, 17, 31], fill=PALETTE["dark_gray"])
                draw_ellipse(t, 11, 2, 10, 8, PALETTE["gold_light"], outline=PALETTE["gold_dark"])
                d.rectangle([13, 4, 18, 6], fill=PALETTE["white"])
            else:
                d.rectangle([8, 8, 23, 23], fill=(210, 225, 245, 255), outline=PALETTE["steel_mid"])
                
            put_tile(city_sheet, c, r, t)
    tilesets["tileset_city.png"] = city_sheet

    # 2. WHISPERING FOREST TILESET
    forest_sheet = new_sheet()
    for r in range(8):
        for c in range(8):
            t = create_transparent(32, 32)
            d = ImageDraw.Draw(t)
            d.rectangle([0, 0, 31, 31], fill=PALETTE["emerald_mid"])
            d.rectangle([2, 4, 4, 8], fill=PALETTE["emerald_light"])
            d.rectangle([18, 12, 20, 16], fill=PALETTE["emerald_light"])
            d.rectangle([8, 22, 10, 26], fill=PALETTE["emerald_light"])
            
            if r == 0 and c == 0:
                pass
            elif r == 0 and c == 1:
                d.rectangle([6, 0, 25, 31], fill=PALETTE["brown_mid"], outline=PALETTE["brown_dark"])
                d.rectangle([10, 2, 21, 29], fill=PALETTE["brown_light"])
            elif r == 0 and c == 2:
                d.rectangle([0, 0, 31, 31], fill=PALETTE["cyan_mid"])
                d.line([2, 8, 14, 8], fill=PALETTE["cyan_light"], width=2)
                d.line([16, 20, 28, 20], fill=PALETTE["white"], width=2)
            elif r == 0 and c == 3:
                d.rectangle([0, 0, 31, 15], fill=PALETTE["emerald_mid"])
                d.rectangle([0, 16, 31, 18], fill=PALETTE["brown_dark"])
                d.rectangle([0, 19, 31, 31], fill=PALETTE["cyan_mid"])
            elif r == 1 and c == 0:
                draw_ellipse(t, 2, 2, 28, 28, PALETTE["emerald_dark"], outline=PALETTE["outline"])
                draw_ellipse(t, 5, 5, 22, 22, PALETTE["emerald_mid"])
                draw_ellipse(t, 8, 8, 12, 12, PALETTE["emerald_light"])
            elif r == 1 and c == 1:
                d.rectangle([10, 0, 21, 26], fill=PALETTE["brown_dark"], outline=PALETTE["outline"])
                d.rectangle([12, 2, 19, 24], fill=PALETTE["brown_mid"])
                d.line([6, 26, 12, 24], fill=PALETTE["brown_dark"], width=2)
                d.line([25, 26, 19, 24], fill=PALETTE["brown_dark"], width=2)
            elif r == 1 and c == 2:
                d.rectangle([0, 0, 31, 31], fill=PALETTE["cyan_mid"])
                for py in [2, 10, 18, 26]:
                    d.rectangle([2, py, 29, py + 6], fill=PALETTE["brown_light"], outline=PALETTE["brown_dark"])
            elif r == 1 and c == 3:
                draw_ellipse(t, 6, 14, 10, 8, PALETTE["crimson_mid"], outline=PALETTE["outline"])
                d.rectangle([9, 7, 11, 7], fill=PALETTE["white"])
                d.rectangle([9, 20, 13, 26], fill=PALETTE["white"])
            else:
                d.rectangle([12, 12, 19, 19], fill=PALETTE["emerald_light"])

            put_tile(forest_sheet, c, r, t)
    tilesets["tileset_forest.png"] = forest_sheet

    # 3. CRYPT CATACOMBS TILESET
    crypt_sheet = new_sheet()
    for r in range(8):
        for c in range(8):
            t = create_transparent(32, 32)
            d = ImageDraw.Draw(t)
            d.rectangle([0, 0, 31, 31], fill=PALETTE["dark_gray"])
            d.rectangle([1, 1, 14, 14], fill=(35, 38, 52, 255), outline=PALETTE["black"])
            d.rectangle([16, 1, 30, 14], fill=(40, 44, 60, 255), outline=PALETTE["black"])
            d.rectangle([1, 16, 30, 30], fill=(35, 38, 52, 255), outline=PALETTE["black"])
            
            if r == 0 and c == 0:
                pass
            elif r == 0 and c == 1:
                d.rectangle([4, 2, 27, 29], fill=PALETTE["mid_gray"], outline=PALETTE["black"])
                d.rectangle([6, 4, 25, 27], fill=PALETTE["light_gray"])
                d.line([15, 6, 15, 25], fill=PALETTE["dark_gray"], width=2)
                d.line([8, 12, 23, 12], fill=PALETTE["dark_gray"], width=2)
            elif r == 0 and c == 2:
                d.rectangle([2, 2, 29, 29], fill=PALETTE["black"], outline=PALETTE["mid_gray"])
                for gx in [6, 12, 18, 24]:
                    d.line([gx, 4, gx, 27], fill=PALETTE["steel_light"], width=2)
                for gy in [6, 12, 18, 24]:
                    d.line([4, gy, 27, gy], fill=PALETTE["steel_light"], width=2)
            elif r == 0 and c == 3:
                draw_ellipse(t, 8, 10, 8, 8, PALETTE["white"], outline=PALETTE["black"])
                d.rectangle([10, 13, 11, 14], fill=PALETTE["crimson_light"])
                draw_ellipse(t, 16, 14, 8, 8, PALETTE["light_gray"], outline=PALETTE["black"])
            elif r == 1 and c == 0:
                d.rectangle([0, 0, 31, 31], fill=PALETTE["black"])
                d.rectangle([14, 14, 17, 28], fill=PALETTE["brown_dark"])
                draw_ellipse(t, 11, 4, 10, 12, PALETTE["crimson_mid"])
                draw_ellipse(t, 13, 6, 6, 8, PALETTE["gold_light"])
                d.rectangle([15, 8, 16, 9], fill=PALETTE["white"])
            elif r == 1 and c == 1:
                draw_ellipse(t, 4, 4, 24, 24, None, outline=PALETTE["crimson_mid"])
                d.line([8, 8, 23, 23], fill=PALETTE["crimson_light"], width=2)
                d.line([8, 23, 23, 8], fill=PALETTE["crimson_light"], width=2)
            else:
                d.rectangle([10, 10, 21, 21], fill=(50, 55, 75, 255), outline=PALETTE["black"])

            put_tile(crypt_sheet, c, r, t)
    tilesets["tileset_crypt.png"] = crypt_sheet

    # 4. MAGMA CAVERNS TILESET
    magma_sheet = new_sheet()
    for r in range(8):
        for c in range(8):
            t = create_transparent(32, 32)
            d = ImageDraw.Draw(t)
            d.rectangle([0, 0, 31, 31], fill=(28, 18, 24, 255))
            d.rectangle([2, 2, 13, 13], fill=(42, 25, 35, 255), outline=PALETTE["black"])
            d.rectangle([17, 2, 29, 13], fill=(36, 20, 30, 255), outline=PALETTE["black"])
            d.rectangle([2, 17, 29, 29], fill=(42, 25, 35, 255), outline=PALETTE["black"])
            
            if r == 0 and c == 0:
                pass
            elif r == 0 and c == 1:
                d.rectangle([0, 0, 31, 31], fill=PALETTE["crimson_mid"])
                d.rectangle([4, 4, 27, 27], fill=PALETTE["gold_mid"])
                d.line([6, 12, 25, 12], fill=PALETTE["gold_light"], width=3)
                d.line([8, 20, 23, 20], fill=PALETTE["white"], width=2)
            elif r == 0 and c == 2:
                d.line([2, 4, 15, 16], fill=PALETTE["crimson_light"], width=2)
                d.line([15, 16, 29, 8], fill=PALETTE["gold_mid"], width=2)
                d.line([15, 16, 12, 29], fill=PALETTE["gold_light"], width=2)
            elif r == 0 and c == 3:
                draw_ellipse(t, 4, 4, 24, 24, PALETTE["crimson_dark"], outline=PALETTE["black"])
                draw_ellipse(t, 7, 7, 18, 18, PALETTE["crimson_mid"])
                draw_ellipse(t, 11, 11, 10, 10, PALETTE["gold_light"])
                draw_ellipse(t, 13, 13, 6, 6, PALETTE["white"])
            elif r == 1 and c == 0:
                d.polygon([(4, 28), (9, 6), (14, 28)], fill=PALETTE["crimson_light"], outline=PALETTE["black"])
                d.polygon([(16, 28), (22, 2), (28, 28)], fill=PALETTE["gold_mid"], outline=PALETTE["black"])
                d.line([18, 26, 22, 4], fill=PALETTE["white"])
            elif r == 1 and c == 1:
                d.rectangle([2, 10, 29, 21], fill=PALETTE["black"])
                d.line([4, 15, 27, 15], fill=PALETTE["crimson_light"], width=2)
            else:
                d.rectangle([8, 8, 23, 23], fill=(55, 30, 42, 255))

            put_tile(magma_sheet, c, r, t)
    tilesets["tileset_magma.png"] = magma_sheet

    # 5. MASTER COMPOSITE TILESET
    master_sheet = new_sheet()
    city_crop = city_sheet.crop((0, 0, 128, 128))
    master_sheet.paste(city_crop, (0, 0))
    forest_crop = forest_sheet.crop((0, 0, 128, 128))
    master_sheet.paste(forest_crop, (128, 0))
    crypt_crop = crypt_sheet.crop((0, 0, 128, 128))
    master_sheet.paste(crypt_crop, (0, 128))
    magma_crop = magma_sheet.crop((0, 0, 128, 128))
    master_sheet.paste(magma_crop, (128, 128))

    tilesets["tileset.png"] = master_sheet

    return tilesets

def generate_item_icons():
    icons = {}

    def new_icon():
        img = create_transparent(32, 32)
        draw_ellipse(img, 2, 2, 28, 28, (15, 20, 30, 200), outline=PALETTE["outline"])
        return img

    # 1. WEAPONS
    excal = new_icon()
    d = ImageDraw.Draw(excal)
    d.line([8, 23, 23, 8], fill=PALETTE["steel_light"], width=3)
    d.line([9, 22, 22, 9], fill=PALETTE["white"], width=1)
    d.line([6, 21, 11, 26], fill=PALETTE["gold_mid"], width=3)
    d.rectangle([5, 25, 7, 27], fill=PALETTE["gold_dark"])
    draw_ellipse(excal, 20, 5, 7, 7, PALETTE["cyan_light"])
    icons["item_excalibur.png"] = excal
    icons["weapon_excalibur.png"] = excal

    staff = new_icon()
    d = ImageDraw.Draw(staff)
    d.line([6, 26, 22, 10], fill=PALETTE["brown_mid"], width=3)
    draw_ellipse(staff, 18, 4, 10, 10, PALETTE["cyan_mid"], outline=PALETTE["gold_mid"])
    draw_ellipse(staff, 20, 6, 6, 6, PALETTE["cyan_light"])
    d.rectangle([22, 7, 24, 9], fill=PALETTE["white"])
    icons["item_wizard_staff.png"] = staff
    icons["weapon_wizard_staff.png"] = staff

    katar = new_icon()
    d = ImageDraw.Draw(katar)
    d.rectangle([6, 12, 10, 20], fill=PALETTE["crimson_mid"], outline=PALETTE["gold_mid"])
    d.polygon([(10, 10), (27, 8), (12, 13)], fill=PALETTE["steel_light"], outline=PALETTE["outline"])
    d.polygon([(10, 19), (27, 24), (12, 21)], fill=PALETTE["steel_light"], outline=PALETTE["outline"])
    d.rectangle([14, 11, 23, 12], fill=PALETTE["white"])
    icons["item_katar.png"] = katar
    icons["weapon_katar.png"] = katar

    bow = new_icon()
    d = ImageDraw.Draw(bow)
    d.arc([4, 4, 24, 27], 45, 225, fill=PALETTE["emerald_light"], width=3)
    d.line([8, 8, 8, 24], fill=PALETTE["white"], width=1)
    d.line([6, 16, 24, 16], fill=PALETTE["brown_light"], width=2)
    d.polygon([(24, 14), (28, 16), (24, 18)], fill=PALETTE["steel_light"])
    icons["item_hunter_bow.png"] = bow
    icons["weapon_hunter_bow.png"] = bow

    axe = new_icon()
    d = ImageDraw.Draw(axe)
    d.line([6, 26, 26, 6], fill=PALETTE["brown_dark"], width=3)
    d.polygon([(16, 6), (25, 4), (27, 14), (19, 13)], fill=PALETTE["steel_light"], outline=PALETTE["gold_mid"])
    d.polygon([(13, 19), (24, 27), (14, 25), (11, 16)], fill=PALETTE["steel_light"], outline=PALETTE["gold_mid"])
    icons["item_battle_axe.png"] = axe
    icons["weapon_battle_axe.png"] = axe

    # 2. ARMOR & HEADGEARS
    plate = new_icon()
    d = ImageDraw.Draw(plate)
    d.rectangle([8, 6, 23, 25], fill=PALETTE["steel_mid"], outline=PALETTE["gold_mid"])
    d.rectangle([10, 8, 21, 16], fill=PALETTE["steel_light"])
    d.line([15, 8, 15, 23], fill=PALETTE["gold_mid"], width=2)
    d.rectangle([6, 6, 9, 12], fill=PALETTE["gold_mid"])
    d.rectangle([22, 6, 25, 12], fill=PALETTE["gold_mid"])
    icons["item_plate_mail.png"] = plate

    robe = new_icon()
    d = ImageDraw.Draw(robe)
    d.polygon([(11, 6), (20, 6), (26, 26), (5, 26)], fill=PALETTE["purple_mid"], outline=PALETTE["gold_mid"])
    d.polygon([(13, 8), (18, 8), (22, 24), (9, 24)], fill=PALETTE["purple_light"])
    d.rectangle([13, 6, 18, 25], fill=PALETTE["gold_mid"])
    icons["item_mage_robe.png"] = robe

    ninja = new_icon()
    d = ImageDraw.Draw(ninja)
    d.rectangle([8, 6, 23, 25], fill=PALETTE["outline"], outline=PALETTE["crimson_mid"])
    d.rectangle([10, 8, 21, 23], fill=PALETTE["dark_gray"])
    d.line([8, 15, 23, 15], fill=PALETTE["crimson_light"], width=3)
    icons["item_ninja_suit.png"] = ninja

    angel = new_icon()
    d = ImageDraw.Draw(angel)
    d.arc([6, 12, 25, 26], 180, 360, fill=PALETTE["gold_mid"], width=2)
    d.polygon([(6, 16), (2, 8), (8, 6), (10, 14)], fill=PALETTE["white"], outline=PALETTE["cyan_light"])
    d.polygon([(25, 16), (29, 8), (23, 6), (21, 14)], fill=PALETTE["white"], outline=PALETTE["cyan_light"])
    icons["item_angel_wing_headband.png"] = angel

    # 3. CONSUMABLES & CARDS
    hp_pot = new_icon()
    d = ImageDraw.Draw(hp_pot)
    d.rectangle([13, 5, 18, 9], fill=PALETTE["brown_mid"])
    draw_ellipse(hp_pot, 8, 9, 16, 18, PALETTE["crimson_mid"], outline=PALETTE["white"])
    draw_ellipse(hp_pot, 10, 13, 12, 12, PALETTE["crimson_light"])
    d.rectangle([11, 14, 13, 16], fill=PALETTE["white"])
    icons["item_health_potion.png"] = hp_pot
    icons["potion_red.png"] = hp_pot

    mp_pot = new_icon()
    d = ImageDraw.Draw(mp_pot)
    d.rectangle([13, 5, 18, 9], fill=PALETTE["brown_mid"])
    draw_ellipse(mp_pot, 8, 9, 16, 18, PALETTE["cyan_mid"], outline=PALETTE["white"])
    draw_ellipse(mp_pot, 10, 13, 12, 12, PALETTE["cyan_light"])
    d.rectangle([11, 14, 13, 16], fill=PALETTE["white"])
    icons["item_mana_potion.png"] = mp_pot
    icons["potion_blue.png"] = mp_pot

    yp_pot = new_icon()
    d = ImageDraw.Draw(yp_pot)
    d.rectangle([13, 5, 18, 9], fill=PALETTE["brown_mid"])
    draw_ellipse(yp_pot, 8, 9, 16, 18, PALETTE["gold_mid"], outline=PALETTE["white"])
    draw_ellipse(yp_pot, 10, 13, 12, 12, PALETTE["gold_light"])
    d.rectangle([11, 14, 13, 16], fill=PALETTE["white"])
    icons["item_yellow_potion.png"] = yp_pot
    icons["potion_yellow.png"] = yp_pot

    card = new_icon()
    d = ImageDraw.Draw(card)
    d.rectangle([6, 4, 25, 27], fill=PALETTE["white"], outline=PALETTE["gold_dark"])
    d.rectangle([8, 6, 23, 25], fill=PALETTE["dark_gray"])
    d.rectangle([9, 7, 22, 17], fill=PALETTE["purple_mid"])
    draw_ellipse(card, 13, 9, 6, 6, PALETTE["crimson_light"])
    d.line([9, 20, 22, 20], fill=PALETTE["gold_mid"], width=1)
    d.line([9, 23, 18, 23], fill=PALETTE["gold_mid"], width=1)
    icons["item_monster_card.png"] = card
    icons["card_baphomet.png"] = card
    icons["card_poring.png"] = card

    gold = new_icon()
    d = ImageDraw.Draw(gold)
    draw_ellipse(gold, 6, 14, 12, 12, PALETTE["gold_mid"], outline=PALETTE["gold_dark"])
    draw_ellipse(gold, 14, 12, 12, 12, PALETTE["gold_mid"], outline=PALETTE["gold_dark"])
    draw_ellipse(gold, 10, 6, 12, 12, PALETTE["gold_light"], outline=PALETTE["gold_dark"])
    d.rectangle([14, 10, 17, 13], fill=PALETTE["white"])
    icons["item_gold.png"] = gold
    icons["item_gold_coins.png"] = gold

    gem = new_icon()
    d = ImageDraw.Draw(gem)
    d.polygon([(11, 8), (20, 8), (26, 14), (16, 25), (5, 14)], fill=PALETTE["crimson_light"], outline=PALETTE["white"])
    d.polygon([(13, 10), (18, 10), (22, 14), (16, 22), (9, 14)], fill=PALETTE["crimson_mid"])
    d.line([(11, 8), (16, 25)], fill=PALETTE["white"], width=1)
    d.line([(20, 8), (16, 25)], fill=PALETTE["white"], width=1)
    icons["item_gem.png"] = gem
    icons["item_ruby_gem.png"] = gem
    icons["item_diamond_gem.png"] = gem

    chest = new_icon()
    d = ImageDraw.Draw(chest)
    d.rectangle([5, 8, 26, 25], fill=PALETTE["brown_mid"], outline=PALETTE["black"])
    d.rectangle([5, 8, 26, 13], fill=PALETTE["brown_light"], outline=PALETTE["gold_dark"])
    d.rectangle([7, 14, 24, 23], fill=PALETTE["brown_mid"])
    d.rectangle([13, 12, 18, 17], fill=PALETTE["gold_mid"], outline=PALETTE["gold_dark"])
    d.rectangle([15, 14, 16, 16], fill=PALETTE["black"])
    icons["item_chest.png"] = chest

    return icons

def generate_godot_spriteframes_tres(texture_rel_path, tres_path):
    content = f"""[gd_resource type="SpriteFrames" load_steps=18 format=3]

[ext_resource type="Texture2D" path="{texture_rel_path}" id="1_tex"]

[sub_resource type="AtlasTexture" id="AtlasTexture_walk_down_0"]
atlas = ExtResource("1_tex")
region = Rect2(0, 0, 32, 32)

[sub_resource type="AtlasTexture" id="AtlasTexture_idle_down"]
atlas = ExtResource("1_tex")
region = Rect2(32, 0, 32, 32)

[sub_resource type="AtlasTexture" id="AtlasTexture_walk_down_1"]
atlas = ExtResource("1_tex")
region = Rect2(64, 0, 32, 32)

[sub_resource type="AtlasTexture" id="AtlasTexture_action_down"]
atlas = ExtResource("1_tex")
region = Rect2(96, 0, 32, 32)

[sub_resource type="AtlasTexture" id="AtlasTexture_walk_left_0"]
atlas = ExtResource("1_tex")
region = Rect2(0, 32, 32, 32)

[sub_resource type="AtlasTexture" id="AtlasTexture_idle_left"]
atlas = ExtResource("1_tex")
region = Rect2(32, 32, 32, 32)

[sub_resource type="AtlasTexture" id="AtlasTexture_walk_left_1"]
atlas = ExtResource("1_tex")
region = Rect2(64, 32, 32, 32)

[sub_resource type="AtlasTexture" id="AtlasTexture_walk_right_0"]
atlas = ExtResource("1_tex")
region = Rect2(0, 64, 32, 32)

[sub_resource type="AtlasTexture" id="AtlasTexture_idle_right"]
atlas = ExtResource("1_tex")
region = Rect2(32, 64, 32, 32)

[sub_resource type="AtlasTexture" id="AtlasTexture_walk_right_1"]
atlas = ExtResource("1_tex")
region = Rect2(64, 64, 32, 32)

[sub_resource type="AtlasTexture" id="AtlasTexture_walk_up_0"]
atlas = ExtResource("1_tex")
region = Rect2(0, 96, 32, 32)

[sub_resource type="AtlasTexture" id="AtlasTexture_idle_up"]
atlas = ExtResource("1_tex")
region = Rect2(32, 96, 32, 32)

[sub_resource type="AtlasTexture" id="AtlasTexture_walk_up_1"]
atlas = ExtResource("1_tex")
region = Rect2(64, 96, 32, 32)

[resource]
animations = [{{
"frames": [SubResource("AtlasTexture_idle_down")],
"loop": true,
"name": &"idle_down",
"speed": 5.0
}}, {{
"frames": [SubResource("AtlasTexture_idle_left")],
"loop": true,
"name": &"idle_left",
"speed": 5.0
}}, {{
"frames": [SubResource("AtlasTexture_idle_right")],
"loop": true,
"name": &"idle_right",
"speed": 5.0
}}, {{
"frames": [SubResource("AtlasTexture_idle_up")],
"loop": true,
"name": &"idle_up",
"speed": 5.0
}}, {{
"frames": [SubResource("AtlasTexture_walk_down_0"), SubResource("AtlasTexture_idle_down"), SubResource("AtlasTexture_walk_down_1"), SubResource("AtlasTexture_idle_down")],
"loop": true,
"name": &"walk_down",
"speed": 6.0
}}, {{
"frames": [SubResource("AtlasTexture_walk_left_0"), SubResource("AtlasTexture_idle_left"), SubResource("AtlasTexture_walk_left_1"), SubResource("AtlasTexture_idle_left")],
"loop": true,
"name": &"walk_left",
"speed": 6.0
}}, {{
"frames": [SubResource("AtlasTexture_walk_right_0"), SubResource("AtlasTexture_idle_right"), SubResource("AtlasTexture_walk_right_1"), SubResource("AtlasTexture_idle_right")],
"loop": true,
"name": &"walk_right",
"speed": 6.0
}}, {{
"frames": [SubResource("AtlasTexture_walk_up_0"), SubResource("AtlasTexture_idle_up"), SubResource("AtlasTexture_walk_up_1"), SubResource("AtlasTexture_idle_up")],
"loop": true,
"name": &"walk_up",
"speed": 6.0
}}, {{
"frames": [SubResource("AtlasTexture_action_down")],
"loop": false,
"name": &"action",
"speed": 5.0
}}]
"""
    with open(tres_path, "w", encoding="utf-8") as f:
        f.write(content)

def generate_walk_preview_gif(sheet_img, gif_path):
    f0 = sheet_img.crop((0, 0, 32, 32))
    f1 = sheet_img.crop((32, 0, 64, 32))
    f2 = sheet_img.crop((64, 0, 96, 32))
    f3 = sheet_img.crop((32, 0, 64, 32))
    
    frames = [f.resize((128, 128), Image.NEAREST) for f in [f0, f1, f2, f3]]
    frames[0].save(
        gif_path,
        save_all=True,
        append_images=frames[1:],
        duration=180,
        loop=0,
        disposal=2
    )

def generate_showcase_poster(hero_sheets, monster_sheets, item_icons, tilesets):
    poster_w = 640
    poster_h = 760
    poster = Image.new("RGBA", (poster_w, poster_h), (9, 13, 22, 255))
    d = ImageDraw.Draw(poster)
    
    d.rectangle([4, 4, poster_w - 5, poster_h - 5], outline=PALETTE["steel_mid"], width=2)
    d.rectangle([8, 8, poster_w - 9, poster_h - 9], outline=PALETTE["gold_mid"], width=1)
    
    d.rectangle([10, 10, poster_w - 11, 46], fill=(15, 23, 42, 255))
    title = "CHRONICLES OF MIDGARD: 2D MMORPG - ASSET SUITE"
    d.text((20, 20), title, fill=PALETTE["gold_light"])
    
    y = 60
    d.text((20, y), "★ 6 PLAYABLE JOB CLASSES (Knight, Wizard, Assassin, Priest, Hunter, Blacksmith)", fill=PALETTE["cyan_light"])
    y += 24
    hero_keys = ["knight", "mage", "rogue", "cleric", "hunter", "blacksmith"]
    for i, hk in enumerate(hero_keys):
        if hk in hero_sheets:
            idle = hero_sheets[hk].crop((32, 0, 64, 32)).resize((64, 64), Image.NEAREST)
            poster.paste(idle, (24 + i * 100, y), idle)
            d.text((24 + i * 100, y + 68), hk.upper(), fill=PALETTE["white"])
            
    y += 95
    d.text((20, y), "★ EXPANDED MONSTER & MVP BOSS ROSTER", fill=PALETTE["crimson_light"])
    y += 24
    m_keys = ["poring", "drops", "poporing", "marin", "goblin", "skeleton", "orc", "gtb", "baphomet", "dragon"]
    for i, mk in enumerate(m_keys):
        if mk in monster_sheets:
            row_idx = i // 5
            col_idx = i % 5
            idle = monster_sheets[mk].crop((32, 0, 64, 32)).resize((56, 56), Image.NEAREST)
            px = 24 + col_idx * 120
            py = y + row_idx * 75
            poster.paste(idle, (px, py), idle)
            d.text((px, py + 58), mk.upper(), fill=PALETTE["light_gray"])
            
    y += 175
    d.text((20, y), "★ 4 EXPANDED BIOMES (Capital City, Whispering Forest, Crypt, Magma Caverns)", fill=PALETTE["emerald_light"])
    y += 24
    if "tileset.png" in tilesets:
        ts_prev = tilesets["tileset.png"].resize((160, 160), Image.NEAREST)
        poster.paste(ts_prev, (24, y), ts_prev)
        
    d.text((210, y - 2), "★ WEAPONS, ARMOR & CONSUMABLES", fill=PALETTE["gold_light"])
    icon_list = [
        "item_excalibur.png", "item_wizard_staff.png", "item_katar.png", "item_hunter_bow.png", "item_battle_axe.png",
        "item_plate_mail.png", "item_mage_robe.png", "item_ninja_suit.png", "item_angel_wing_headband.png", "item_monster_card.png",
        "item_health_potion.png", "item_mana_potion.png", "item_yellow_potion.png", "item_gold.png", "item_gem.png"
    ]
    for i, ik in enumerate(icon_list):
        if ik in item_icons:
            col = i % 5
            row = i // 5
            ic = item_icons[ik].resize((40, 40), Image.NEAREST)
            poster.paste(ic, (210 + col * 46, y + 20 + row * 46), ic)
            
    poster_path = os.path.join(SPRITES_DIR, "showcase_roster.png")
    poster.save(poster_path)
    poster.save(os.path.join(WEB_ASSETS_DIR, "showcase_roster.png"))

def main():
    print("=== Chronicles of Midgard: 2D MMORPG Asset Generator ===")
    
    hero_configs = {
        "knight": ["knight.png"],
        "mage": ["mage.png", "wizard.png"],
        "rogue": ["rogue.png", "assassin.png"],
        "cleric": ["cleric.png", "priest.png", "high_priest.png"],
        "hunter": ["hunter.png"],
        "blacksmith": ["blacksmith.png"]
    }
    
    hero_sheets = {}
    for hero_key, file_names in hero_configs.items():
        frames = generate_hero_frames(hero_key)
        sheet = build_spritesheet(frames)
        hero_sheets[hero_key] = sheet
        
        for fname in file_names:
            base_name = os.path.splitext(fname)[0]
            p_sprite = os.path.join(SPRITES_DIR, fname)
            p_web = os.path.join(WEB_ASSETS_DIR, fname)
            sheet.save(p_sprite)
            sheet.save(p_web)
            
            tres_name = f"{base_name}_frames.tres"
            generate_godot_spriteframes_tres(f"res://assets/sprites/{fname}", os.path.join(SPRITES_DIR, tres_name))
            
            gif_name = f"{base_name}_walk_preview.gif"
            generate_walk_preview_gif(sheet, os.path.join(SPRITES_DIR, gif_name))
            generate_walk_preview_gif(sheet, os.path.join(WEB_ASSETS_DIR, gif_name))
            print(f"  [+] Hero Generated: {fname} & {tres_name}")

    monster_configs = {
        "poring": ["poring.png", "slime_green.png"],
        "drops": ["drops.png", "slime_blue.png"],
        "poporing": ["poporing.png", "slime_poison.png"],
        "marin": ["marin.png", "slime_red.png", "slime_magma.png"],
        "goblin": ["goblin.png", "goblin_scout.png"],
        "skeleton": ["skeleton.png", "undead_skeleton.png"],
        "orc": ["orc.png", "orc_warrior.png"],
        "gtb": ["gtb.png", "golden_thief_bug.png"],
        "baphomet": ["baphomet.png", "lord_of_death.png"],
        "dragon": ["dragon.png", "red_dragon.png"]
    }
    
    monster_sheets = {}
    for m_key, file_names in monster_configs.items():
        frames = generate_monster_frames(m_key)
        sheet = build_spritesheet(frames)
        monster_sheets[m_key] = sheet
        
        for fname in file_names:
            base_name = os.path.splitext(fname)[0]
            p_sprite = os.path.join(SPRITES_DIR, fname)
            p_web = os.path.join(WEB_ASSETS_DIR, fname)
            sheet.save(p_sprite)
            sheet.save(p_web)
            
            tres_name = f"{base_name}_frames.tres"
            generate_godot_spriteframes_tres(f"res://assets/sprites/{fname}", os.path.join(SPRITES_DIR, tres_name))
            
            gif_name = f"{base_name}_walk_preview.gif"
            generate_walk_preview_gif(sheet, os.path.join(SPRITES_DIR, gif_name))
            generate_walk_preview_gif(sheet, os.path.join(WEB_ASSETS_DIR, gif_name))
            print(f"  [+] Monster Generated: {fname} & {tres_name}")

    fx_dict = generate_spell_fx()
    for fname, img in fx_dict.items():
        img.save(os.path.join(SPRITES_DIR, fname))
        img.save(os.path.join(WEB_ASSETS_DIR, fname))
        print(f"  [+] Visual FX Generated: {fname}")

    tilesets = generate_tilesets()
    for fname, sheet in tilesets.items():
        sheet.save(os.path.join(TILES_DIR, fname))
        sheet.save(os.path.join(WEB_ASSETS_DIR, fname))
        print(f"  [+] Tileset Generated: {fname}")

    item_icons = generate_item_icons()
    for fname, img in item_icons.items():
        img.save(os.path.join(SPRITES_DIR, fname))
        img.save(os.path.join(WEB_ASSETS_DIR, fname))
        print(f"  [+] Item Icon Generated: {fname}")

    generate_showcase_poster(hero_sheets, monster_sheets, item_icons, tilesets)
    print("  [+] Showcase Poster Generated: showcase_roster.png")

    print("\n[SUCCESS] All assets, .tres SpriteFrames, and web assets generated successfully!")

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Generate tile map data and character sprites for Emerald MMO."""
import struct
from PIL import Image, ImageDraw
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TILE = 16

def generate_tilemap_data():
    """Map native tileset to extracted atlas, generate PackedByteArray for Godot."""
    native = Image.open(os.path.join(BASE, "assets/tilesets/tileset_native.png")).convert("RGBA")
    extracted = Image.open(os.path.join(BASE, "assets/tilesets/tileset_extracted.png")).convert("RGBA")
    
    ext_cols = extracted.width // TILE  # 16
    ext_rows = extracted.height // TILE  # 8
    
    tile_lookup = {}
    for ey in range(ext_rows):
        for ex in range(ext_cols):
            tile = extracted.crop((ex*TILE, ey*TILE, (ex+1)*TILE, (ey+1)*TILE))
            tile_lookup[tile.tobytes()] = (ex, ey)
    
    nat_cols = native.width // TILE   # 18
    nat_rows = native.height // TILE  # 32
    
    # Map native tiles to atlas coords
    native_map = {}  # (nx,ny) -> (ax,ay)
    for ny in range(nat_rows):
        for nx in range(nat_cols):
            tile = native.crop((nx*TILE, ny*TILE, (nx+1)*TILE, (ny+1)*TILE))
            tb = tile.tobytes()
            if tb in tile_lookup:
                native_map[(nx,ny)] = tile_lookup[tb]
            else:
                best = min(tile_lookup.items(), key=lambda kv: sum(abs(a-b) for a,b in zip(tb, kv[0])))
                native_map[(nx,ny)] = best[1]
    
    # Grass tile = (0,0) in atlas (confirmed from data)
    grass = (0, 0)
    
    # Collision tiles - identified from the visual map:
    # Tree canopy tiles (rows 0-7 area): dark green tree tops and trunks
    # Looking at the atlas coords used in tree areas:
    # Trees use: (10,1),(11,1) top, (2,2),(13,1) mid, and more
    # Rocks, fences, sign, benches
    collision_atlas = {
        # Tree tiles
        (10,1), (11,1),  # tree top
        (2,2), (13,1),   # tree trunk area  
        (0,2), (1,2),    # tree canopy
        (3,2), (4,2),    # tree mid
        # Signpost
        (9,2), (10,2),   # sign top
        (14,2), (15,2),  # sign bottom area
        # Fence/bench tiles
        (5,4), (6,4),    # fence horizontal
        (11,4), (12,4),  # fence horizontal lower
        (7,6), (8,6),    # fence piece
        (9,6),           # fence piece
        # Rocks
        (1,6), (2,6),    # rock
        (0,6), (3,6),    # rock edge
        # Bushes with berries (treated as soft collision)
        (4,5), (5,5),    # bush top
        (13,5), (14,5),  # bush bottom
        (4,3), (5,3),    # special bush
        # Bench
        (5,6), (14,6),
        (11,6), (12,6), (13,6),
    }
    
    # Padded map: 30 wide, native content centered, 3 rows padding top/bottom
    PAD_W = 30
    PAD_H = nat_rows + 6  # 38
    off_x = (PAD_W - nat_cols) // 2  # 6
    off_y = 3
    
    ground_cells = []
    collision_cells = []
    
    for y in range(PAD_H):
        for x in range(PAD_W):
            nx = x - off_x
            ny = y - off_y
            if 0 <= nx < nat_cols and 0 <= ny < nat_rows:
                ax, ay = native_map[(nx, ny)]
            else:
                ax, ay = grass
            ground_cells.append((x, y, ax, ay))
            if (ax, ay) in collision_atlas:
                collision_cells.append((x, y, ax, ay))
    
    def to_bytes(cells):
        data = bytearray()
        for x, y, ax, ay in cells:
            data.extend(struct.pack('<hhHHHH', x, y, 0, ax, ay, 0))
        return list(data)
    
    ground_bytes = to_bytes(ground_cells)
    collision_bytes = to_bytes(collision_cells)
    
    print(f"Map: {PAD_W}x{PAD_H}, Ground: {len(ground_cells)}, Collision: {len(collision_cells)}")
    return ground_bytes, collision_bytes


def generate_character_sprites():
    """Generate 16x16 Pokemon-style character sprites."""
    os.makedirs(os.path.join(BASE, "assets/sprites/player"), exist_ok=True)
    
    SHEET_W = 3 * TILE  # 48
    SHEET_H = 4 * 4 * TILE  # 256
    
    sheet = Image.new("RGBA", (SHEET_W, SHEET_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sheet)
    
    variants = [
        {"hair": (40, 40, 80),   "skin": (255, 210, 170), "shirt": (70, 120, 200), "pants": (50, 50, 120)},
        {"hair": (140, 40, 30),  "skin": (240, 195, 155), "shirt": (200, 60, 60),  "pants": (80, 40, 40)},
        {"hair": (30, 100, 40),  "skin": (255, 220, 180), "shirt": (60, 170, 80),  "pants": (40, 80, 50)},
        {"hair": (200, 180, 50), "skin": (245, 205, 165), "shirt": (220, 200, 60), "pants": (120, 100, 40)},
    ]
    
    for vi, v in enumerate(variants):
        for di, direction in enumerate(["down", "up", "left", "right"]):
            for fi, frame in enumerate(["stand", "step_left", "step_right"]):
                x0 = fi * TILE
                y0 = (vi * 4 + di) * TILE
                
                hair, skin, shirt, pants = v["hair"], v["skin"], v["shirt"], v["pants"]
                outline = (30, 30, 30)
                eye = (20, 20, 40)
                
                # Head
                draw.rectangle([x0+4, y0+0, x0+11, y0+7], fill=outline)
                draw.rectangle([x0+5, y0+1, x0+10, y0+6], fill=skin)
                draw.rectangle([x0+5, y0+1, x0+10, y0+3], fill=hair)
                
                if direction == "down":
                    draw.point((x0+6, y0+5), fill=eye)
                    draw.point((x0+9, y0+5), fill=eye)
                    draw.point((x0+7, y0+6), fill=(200,130,130))
                    draw.point((x0+8, y0+6), fill=(200,130,130))
                elif direction == "up":
                    draw.rectangle([x0+5, y0+3, x0+10, y0+6], fill=hair)
                elif direction == "left":
                    draw.point((x0+6, y0+5), fill=eye)
                elif direction == "right":
                    draw.point((x0+9, y0+5), fill=eye)
                
                # Body
                draw.rectangle([x0+4, y0+8, x0+11, y0+13], fill=outline)
                draw.rectangle([x0+5, y0+8, x0+10, y0+11], fill=shirt)
                draw.rectangle([x0+5, y0+12, x0+10, y0+13], fill=pants)
                
                # Legs
                leg_offsets = {"stand": (5,8), "step_left": (4,8), "step_right": (5,9)}
                lo = leg_offsets[frame]
                draw.rectangle([x0+lo[0], y0+14, x0+lo[0]+2, y0+15], fill=outline)
                draw.rectangle([x0+lo[1], y0+14, x0+lo[1]+2, y0+15], fill=outline)
                
                # Arms
                arm_y = {"stand": (10,10), "step_left": (9,11), "step_right": (11,9)}
                ay_l, ay_r = arm_y[frame]
                draw.point((x0+3, y0+ay_l), fill=skin)
                draw.point((x0+12, y0+ay_r), fill=skin)
    
    out = os.path.join(BASE, "assets/sprites/player/player_spritesheet.png")
    sheet.save(out)
    print(f"Saved spritesheet: {out} ({SHEET_W}x{SHEET_H})")


def fmt(data):
    return "PackedByteArray(" + ", ".join(str(b) for b in data) + ")"


if __name__ == "__main__":
    ground, collision = generate_tilemap_data()
    generate_character_sprites()
    
    with open(os.path.join(BASE, "tools/ground_data.txt"), 'w') as f:
        f.write(fmt(ground))
    with open(os.path.join(BASE, "tools/collision_data.txt"), 'w') as f:
        f.write(fmt(collision))
    
    print("Done!")

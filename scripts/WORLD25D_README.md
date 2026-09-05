# WORLD25D_README.md
# 2.5D World System - Additive module for RPG_Quest_2D

> **Additive & non-destructive:** `world.gd` is untouched. These two files add a 2.5D path you can opt into per-scene.

## Files

| File | Role |
|------|------|
| `world_builder_25d.gd` | `class_name WorldBuilder25D` - static builder with `build_25d_world(parent, tile_tex)` |
| `world_25d.gd` | `Node2D` scene script - drop-in replacement for `world.gd` that delegates to the builder |

## What it adds over `world.gd`

Replicates the 50x40 tile map (1600x1280), same zones (grass/plaza/water/flower, dungeon stone), same wall layout (outer rect + internal partition at x=36 / y=26 with door gaps), same 12 scattered trees + boundary ring + monster/chest spawns, **plus**:

- **Wall height** - every brick block gets a `top 32x32` sprite + `16px south face` darkened sprite (`Color(0.45,0.38,0.32)`) as a child offset `Vector2(0,16)`. Collider stays `Rect 32x32` (parity with original).
- **Raised platforms (2 tiles / 32px high)** - two rects: `Rect2i(8,6,6,4)` overworld plaza and `Rect2i(35,22,8,5)` dungeon dais. Tops use ground tiles brightened; south edges extrude a 32px cliff face darkened; thin `12px` / `6px` side blockers prevent falling off without stairs.
- **Stair tiles** - 2+2 walkable tiles bridging cliffs (`(10,10),(11,10)` and `(34,24),(34,25)`), no collider, plaza tile tinted + step-line overlays.
- **YSort** - `parent.y_sort_enabled = true` on entry; every wall / tree / crate / column / platform cell is added to group `ysort` (plus `walls_25d` / `props_25d` / `decor_25d` for queries).
- **Foot-anchored props** - `crates` (6) and `columns` (4) whose collision is offset to the **foot** (`crate: Rect 18x12 at +8y, sprite at -8y; column: Rect 14x10 at +9y, sprite at -10y`) so stacking/sorting reads correctly. Each has a darkened face/base sprite.
- **Decoration density + height variation** - matches original 12 trees, plus 6 extra bushes scaled `0.75x`; scattered trees get random `0.90-1.15` scale for parallax height.

All visuals use only Godot 4 core APIs: `Node2D`, `Sprite2D`, `AtlasTexture`, `StaticBody2D`, `CollisionShape2D` (+ `RectangleShape2D`/`CircleShape2D` shapes). No `TileMap`, no custom shaders.

## Usage

### Option A - Switch the scene script

1. Duplicate `scenes/world.tscn` -> `scenes/world_25d.tscn`.
2. Change root node's script from `res://scripts/world.gd` to `res://scripts/world_25d.gd`.
3. Run `world_25d.tscn`. That's it.

### Option B - Call the builder from any Node2D

```gdscript
# In any Node2D's _ready():
extends Node2D

func _ready() -> void:
	var tile_tex: Texture2D = load("res://assets/tiles/tileset.png")
	# parent can be `self` or any Node2D container (e.g. $WorldRoot)
	WorldBuilder25D.build_25d_world(self, tile_tex)

	# Spawn individual 2.5D helpers elsewhere:
	WorldBuilder25D.create_wall_25d(self, Vector2(800, 400), tile_tex)
	WorldBuilder25D.create_tree_25d(self, Vector2(200, 600), tile_tex)
	WorldBuilder25D.create_crate_25d(self, Vector2(900, 620), tile_tex)
	WorldBuilder25D.create_column_25d(self, Vector2(1000, 680), tile_tex)
	WorldBuilder25D.create_stair_tile(self, Vector2(352, 336), tile_tex)
```

### Option C - Use `world_25d.gd` wrappers

```gdscript
# If your scene already uses world_25d.gd as root:
var tex: Texture2D = load("res://assets/tiles/tileset.png")
create_wall_25d(Vector2(512, 512), tex)
create_crate_25d(Vector2(600, 400), tex)
build_25d_world($SubWorld, tex) # build a second chunk into a child Node2D
```

## YSort notes

- Godot 4 uses `Node2D.y_sort_enabled`. The builder enables it on the `parent` passed to `build_25d_world`.
- Walls/props/trees are added to group `ysort` so you can query or re-sort: `get_tree().get_nodes_in_group("ysort")`.
- If you add dynamic entities (player, NPCs, enemies), also add them to `ysort` and ensure they are children of the same YSort-enabled parent (or of `$Entities` which itself is under that parent).

## Collision foot anchoring

```
crate body at foot (e.g. Vector2(900, 620)):
  Sprite  offset (0, -8)  -- visual center lifted
  Face    offset (0, +6)  -- south side strip
  Collider Rect 18x12 offset (0, +8) -- at feet, not center
column similarly: sprite (0,-10), collider (0,+9)
tree: sprite (0,-6), collider Circle r=12 at (0,+4)
```

This means `body.position` **is** the foot. Sorting by `y` (YSort) then matches where the character stands.

## Tileset regions used

Ground (same as `world.gd`, base `tileset.png`): `(0,224)`, `(192,0)`, `(224,64)`, `(0,64)`, `(128,64)`.
Walls (`tiles/wall_25d.png`, 32x48 slices): row 0 dungeon stone, top `(col*32,0,32,32)` +
baked side `(col*32,32,32,16)`; cols 0/1/3/5 plain rotation, col 4 cracked accent.
Platforms (`tiles/floor_height_25d.png`): grass flats row 0 / extruded grass cliff row 1
(`(col*32,48,32,48)` on south edge), dungeon flats row 2 / extruded dungeon row 3.
Props (`tiles/props_25d.png`, 32x48 cells): crates row 0 cols 4-7, doric column row 0 col 2.
Trees stay on base `tileset.png` canopy `(128,32)`.

If a 2.5D sheet is missing, the builder falls back to shaded base-tileset regions.

## Testing

Open `world_25d.tscn` and verify:
- Dungeon walls show a darkened south lip.
- Two raised dais areas block entry except via stairs.
- Player sorts in front of / behind walls, trees, crates as `y` changes.
- Crates/columns collide at feet, not center.

## Compatibility

- Godot 4.6, `Forward Plus`, `canvas_items` stretch, `filter=Nearest` (per `project.godot`).
- Original `world.gd` / `world.tscn` continue to work unchanged.

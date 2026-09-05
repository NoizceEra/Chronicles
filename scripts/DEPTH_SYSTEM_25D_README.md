# Depth & Shadow 2.5D System — RPG Quest 2D

Non-breaking 2.5D helpers. Two scripts only; no existing files are modified.

## Files

| File | Class | Purpose |
|------|-------|---------|
| `scripts/depth_sort_25d.gd` | `Depth25D` | YSort helper, z_index + wall occlusion |
| `scripts/shadow_system_25d.gd` | `Shadow25D` | Procedural drop shadow (14×5 ellipse, alpha 80, offset y+12) |

## Integration

### 1 — YSort parent in `world.tscn` (recommended)

Wrap all depth-sorted sprites under a `YSort` node so Godot sorts by `y`.

Current `world.tscn` has `World > Entities` (Node2D). Minimal change:

```
[before]
World (Node2D, script world.gd)
 ├─ Entities (Node2D)          <- holds enemies, chests
 ├─ Player
 └─ HUD

[after — edit in editor]
World (Node2D)
 ├─ YSort (Node2D, y_sort_enabled = true)   <- new; move Entities+Player inside
 │   ├─ Entities
 │   └─ Player
 └─ HUD
```

Editor steps: create `YSort` child of `World`, enable `Y Sort > Enabled`, drag `Entities` and `Player` inside it. No script changes. Walls/trees added by `world.gd` should be added to the YSort instead: in `world.gd` either reparent, or call `Depth25D` helpers as fallback (see below).

Pure-code fallback if you do not want to edit `world.tscn` — call each frame:

```gdscript
# world.gd _physics_process (or player/enemy _physics_process)
Depth25D.update_sort_recursive($YSort)          # if YSort exists
# or per-actor:
Depth25D.update_sprite_sort(player)
Depth25D.update_sprite_sort(enemy)
# walls
for e in $Entities.get_children():
    Depth25D.update_sprite_sort(e)
```

Foot model: `Depth25D.compute_z_index(y + offset)` where `CHARACTER_FOOT_OFFSET = 12`, `WALL_FOOT_OFFSET = 16`, so `z_index = int(y + offset)`.

### 2 — Shadows on Player / Enemy

Option A — one-liner in code (no scene edits):

```gdscript
# player.gd _ready() or world.gd after spawning enemy
Shadow25D.attach_to(player)
Shadow25D.attach_to(enemy)
# later, if you add jump height (0..1 normalized or 0..32 px):
$Shadow25D.set_height(jump_height_norm)   # or .update_shadow_scale(h)
```

Option B — editor: add `Shadow25D` as child of `Player`/`Enemy` scene, it auto-creates the `DropShadow` Sprite2D.

Shadow details (to spec):
- Sprite2D `DropShadow`, ellipse 14×5 generated procedurally, `modulate = Color(0,0,0, 80/255)`, `position = (0, 12)`, `z_index = -1`
- Scale: `shadow_scale = clamp(height, 0.4, 1.0)` — `height == 0` => scale `1.0` (on ground). Pass height in 0..1; if you pass pixels (>1) it normalizes by `/32`.
- For the common "higher = smaller shadow" look, pass `1.0 - elevation` or call `update_shadow_scale(elev_px)` which normalizes and inverts appropriately (see code comments).

### 3 — Wall occlusion (see-through when player behind wall)

Tag walls so they auto-fade:

```gdscript
# world.gd create_wall_block / create_tree_obstacle — after add_child(body):
Depth25D.tag_wall(body)  # adds to group "walls"
```

Then each frame:

```gdscript
func _process(_delta):
    Depth25D.update_wall_occlusion(player)  # fades occluding walls to alpha 0.35
    # or explicit list:
    # Depth25D.update_wall_occlusion(player, wall_list, 0.35)
```

Helpers: `Depth25D.is_actor_behind_wall(actor, wall)`, `Depth25D.set_wall_alpha(wall, alpha)`, `Depth25D.get_occluded_walls(actor)`.

## Tuning

- Offsets: edit `CHARACTER_FOOT_OFFSET` / `WALL_FOOT_OFFSET` if sprite pivots change.
- Shadow size/alpha: `Shadow25D.SHADOW_SIZE`, `SHADOW_ALPHA`, `SHADOW_OFFSET`.
- Occlusion: `Depth25D.OCCLUSION_DISTANCE` (96px) and `DEFAULT_OCCLUSION_ALPHA` (0.35).

## Does not break existing game

- Both scripts are `class_name` helpers, no autoload required, no dependencies beyond `Node2D`/`Sprite2D`.
- Not referenced by existing scripts; opt-in only.
- Works with current `Camera2D zoom 2x` and 32px tiles.

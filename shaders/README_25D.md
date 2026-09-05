# 2.5D Camera, Lighting & Shader Pack

Fake 2.5D depth without full 3D. Viewport `640×360`, base zoom `2.0`.

## Files

| File | Purpose |
|------|---------|
| `scripts/camera_25d.gd` | Camera2D with perspective offset + breathing zoom + Y-parallax |
| `shaders/height_fog.gdshader` | Height fog — darkens/fogs low ground by world Y |
| `shaders/sprite_depth.gdshader` | Sprite depth — drop-shadow + outline driven by `z_height` |
| `assets/theme/lighting_25d.tres` | Pre-tuned `ShaderMaterial` wrapping `height_fog` |

All shaders are `shader_type canvas_item;` and Godot 4.x compatible.

---

## 1. Camera — `camera_25d.gd`

### What it does
- **Perspective offset:** `offset.y = clamp((player.y - 640) * 0.06, ±48)` — looking slightly down as the player moves south. Literal spec is `player.y * 0.06`; centered variant subtracts mid-map (640) so north areas don't offset off-screen. Swap one line if you want absolute.
- **Breathing zoom:** `zoom = 2.0 + sin(TAU * 0.4 * t) * 0.015`
- **Y-parallax:** `parallax_layers` drift with `player.y * 0.18` for distant backdrops.

### Setup (pick one)

**A) As child of Player** (recommended — follows player automatically):
1. Open `scenes/player.tscn`.
2. Replace the `Camera2D` node script with `res://scripts/camera_25d.gd` (or add a new `Camera25D` node and disable the old one).
3. No `player_path` needed — it auto-detects parent.

**B) Standalone camera in World:**
1. Open `scenes/world.tscn` → add `Camera2D` → attach `camera_25d.gd`.
2. Set `player_path` to `../Player` (or drag the Player node).
3. Ensure `Current` is checked or call `make_current()`.

### Parallax
- Create `ParallaxBackground`/`Sprite2D` for sky/mountains (e.g. `World/DistantBG`).
- In the camera inspector add their `NodePath`s to `parallax_layers`.
- Or call at runtime: `camera.add_parallax_layer($DistantBG)`.
- Tune `distant_parallax_factor` (default `0.18`). Layers farther back move less via internal `depth_curve`.

### Properties

```
perspective_strength = 0.06
zoom_breath_amplitude = 0.015
zoom_breath_frequency = 0.4   # Hz
distant_parallax_factor = 0.18
max_perspective_offset = 48
follow_smoothing = 6.0
```

### API
```gdscript
camera.snap_to_player()                       # after teleport
camera.add_parallax_layer(node)
camera.set_perspective_strength_override(0.12, 1.5) # cutscene tilt for 1.5s
```

---

## 2. Height Fog — `shaders/height_fog.gdshader`

Darkens lower ground; optionally fog-colors it.

### Assign to World

**Option A — Tiles / ground sprites:**
```gdscript
# In world.gd build_world_map(), after creating tile_sprite:
var mat = ShaderMaterial.new()
mat.shader = load("res://shaders/height_fog.gdshader")
# Optional: share the tuned preset
# mat = load("res://assets/theme/lighting_25d.tres")
tile_sprite.material = mat
```
Or in the editor: select the TileMap / Sprite2D → `Material` → `New ShaderMaterial` → `Shader = height_fog.gdshader`.

**Option B — Full-screen fog overlay (cheap):**
1. In `world.tscn` add `CanvasLayer` → `ColorRect` (anchors full rect, color white).
2. Assign `height_fog.gdshader` as its material.
3. Set `use_uv_y = true` so fog keys off `UV.y` (screen height) instead of world coords.

### Uniforms

| Uniform | Default | Notes |
|---------|---------|-------|
| `fog_color` | `Color(0.08,0.12,0.22)` | Fog tint |
| `fog_start_y` | 560 | World Y where fog begins |
| `fog_end_y` | 1280 | Fully fogged at this Y |
| `fog_intensity` | 0.55 | Blend amount |
| `darken_strength` | 0.35 | AO-like darken for low areas |
| `fog_curve` | 1.6 | `pow` curve (higher = sharper low-end) |
| `use_uv_y` | false | Key off `UV.y` for screen quads |
| `ambient_falloff` | 0.2 | Subtle lift for high ground |
| `world_origin_y` | 0 | Set from GDScript for world-space mode |
| `world_scale_y` | 1.0 |  |

Map is `50×40` tiles → `1280px` tall. `fog_start_y=560` fogs roughly the southern dungeon. Raise `fog_start_y` to push fog lower, or lower it to bring fog north.

### Runtime tweak
```gdscript
var mat = $Ground.material as ShaderMaterial
mat.set_shader_parameter("fog_intensity", 0.7)
mat.set_shader_parameter("fog_color", Color(0.1, 0.15, 0.3))
```

`assets/theme/lighting_25d.tres` is a ready-made `ShaderMaterial` with the defaults above — `load()` and assign directly.

---

## 3. Sprite Depth — `shaders/sprite_depth.gdshader`

Adds drop-shadow + outline scaling with `z_height`. Handles fake jump / elevation.

### Assign to entities

**Editor:**
1. Select `AnimatedSprite2D` (player, enemy, chest sprite) → `Material` → `New ShaderMaterial` → `Shader = sprite_depth.gdshader`.

**Code (player/enemy):**
```gdscript
var dmat := ShaderMaterial.new()
dmat.shader = load("res://shaders/sprite_depth.gdshader")
$AnimatedSprite2D.material = dmat
# Optional: keep a reference
set_meta("depth_mat", dmat)
```

### Animate z_height
```gdscript
# Jump arc example (in player.gd or enemy.gd):
var t := Time.get_ticks_msec() / 1000.0
var z := sin(t * 6.0) * 24.0  # 0..24
z = max(z, 0.0)
($AnimatedSprite2D.material as ShaderMaterial).set_shader_parameter("z_height", z)
```

Wire it to your existing movement: when `velocity.y < 0` (jumping), ramp `z_height`; on landing tween back to `0`.

### Uniforms

| Uniform | Default | Notes |
|---------|---------|-------|
| `z_height` | 0 | Elevation px — drives shadow + outline + lift |
| `max_z` | 64 | Normalization for `h = z/max_z` |
| `shadow_color` | `rgba(0,0,0,0.45)` | Shadow tint |
| `shadow_offset` | `(3,6)` | px offset in texture space |
| `shadow_softness` | 0.5 | Softens high shadows |
| `shadow_scale_with_height` | 0.8 | Shadow grows with height |
| `outline_color` | warm highlight | Rim when elevated |
| `outline_width` | 1.2 | px |
| `outline_threshold` | 0.3 | Neighbor alpha gate |
| `outline_height_fade` | 0.6 | How much outline tracks height |
| `height_lift_factor` | 1.0 | Vertex Y lift per z |
| `squash_at_peak` | 0.08 | Fake squash at max height |

Vertex stage lifts the sprite (`VERTEX.y -= z * lift`) and squashes slightly so jumps read as 2.5D.

---

## Quick integration checklist

- [ ] Attach `camera_25d.gd` to the Player's Camera2D (or World camera).
- [ ] Add `height_fog.gdshader` (or `lighting_25d.tres`) to ground tiles / TileMap material.
- [ ] Add `sprite_depth.gdshader` to `AnimatedSprite2D` on Player / Enemies / NPCs / Chests.
- [ ] In `_physics_process`, update `z_height` for jumping / platforms.
- [ ] (Optional) Wire `world_origin_y` each frame if using world-space fog:
  ```gdscript
  tile_material.set_shader_parameter("world_origin_y", global_position.y)
  ```

## Performance

Both shaders are single-pass `canvas_item` with no extra textures. Height fog adds ~4 ALU ops per fragment; sprite depth does 8 neighbor fetches only when `outline_width > 0` — set to `0` on low-end to halve cost.

## Do not edit

Existing shaders and `project.godot` are untouched. These files are additive — delete them to revert.

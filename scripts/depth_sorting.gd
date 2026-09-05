# depth_sorting.gd - Reusable 2.5D helper for y-sorting, shadows, and wall occlusion.
# Godot 4.x idiomatic, no scene dependencies. Use as autoload or via preload().
# Keeps original world.gd intact - opt-in only.
# Example:
#   var DepthSorting = preload("res://scripts/depth_sorting.gd")
#   DepthSorting.get_sort_offset(32.0)       # -> 16.0
#   DepthSorting.get_shadow_alpha(16.0)      # -> 0.5 .. 1.0
#   DepthSorting.is_behind_wall(entity_y, wall_y) # -> true if entity is behind wall
extends RefCounted
class_name DepthSorting

## Foot anchor offsets (pixels). 32px tiles, origin at tile center.
## Characters: feet 12px below center. Walls: feet 16px (bottom edge).
const CHARACTER_FOOT_OFFSET: float = 12.0
const WALL_FOOT_OFFSET: float = 16.0

## Shadow defaults (matches assets/sprites/shadow_blob.png 14x5, also drop_shadow_14x5.png).
const SHADOW_OFFSET_Y: float = 12.0
const SHADOW_MAX_ALPHA: float = 0.55
const SHADOW_MIN_ALPHA: float = 0.22

## Occlusion fade for walls blocking the player.
const OCCLUDED_ALPHA: float = 0.35

# ---------------------------------------------------------------------------
# Sorting
# ---------------------------------------------------------------------------

## Returns the y_sort offset to add to a node's y so sorting uses the feet.
## @param sprite_height - Height of the sprite in pixels (e.g. 32). Half-height
##                        is commonly used so feet drive sorting. For wall blocks
##                        pass 32 and you get 16; for 24px characters you get 12.
static func get_sort_offset(sprite_height: float) -> float:
	return sprite_height * 0.5

## Convenience: foot Y for any world position.
## @param y - Node global_position.y
## @param is_wall - true = wall/static (16px offset), false = character (12px)
static func get_foot_y(y: float, is_wall: bool = false) -> float:
	return y + (WALL_FOOT_OFFSET if is_wall else CHARACTER_FOOT_OFFSET)

## Deterministic z_index from a foot Y. Useful if not using YSort node.
static func compute_z_index(foot_y: float) -> int:
	return clampi(int(round(foot_y)), -4096, 4096)

# ---------------------------------------------------------------------------
# Shadow
# ---------------------------------------------------------------------------

## Shadow alpha by height above ground.
## 0 px = on ground -> full opacity; higher = more transparent / smaller.
## Linear falloff: height 0..32 maps to alpha MAX..MIN. Clamped 0..64.
## For jump systems that pass normalized 0..1, multiply by 32 before calling,
## or use get_shadow_scale() below.
static func get_shadow_alpha(height_px: float) -> float:
	var h: float = clampf(height_px, 0.0, 64.0)
	# Normalize 0..32 -> 0..1, beyond 32 stays at MIN
	var t: float = clampf(h / 32.0, 0.0, 1.0)
	return lerpf(SHADOW_MAX_ALPHA, SHADOW_MIN_ALPHA, t)

## Shadow scale by height. Spec helper: clamp(height, 0.4, 1.0) variant
## is kept for compat, but pixel-aware scale is 1.0 at ground -> 0.4 at 32px.
static func get_shadow_scale(height_px: float) -> float:
	if height_px <= 0.0:
		return 1.0
	var t: float = clampf(height_px / 32.0, 0.0, 1.0)
	return lerpf(1.0, 0.4, t)

## Spec-compat alias: when caller already has normalized 0.4..1.0 height,
## this directly returns clamp(height, 0.4, 1.0).
static func get_shadow_scale_normalized(height_norm: float) -> float:
	if height_norm == 0.0:
		return 1.0
	return clampf(height_norm, 0.4, 1.0)

# ---------------------------------------------------------------------------
# Occlusion
# ---------------------------------------------------------------------------

## True if entity is visually behind the wall (entity foot above wall foot).
## Classic 2.5D occlusion test: entity_y is global_position.y of actor,
## wall_y is global_position.y of wall block. Feet are derived via offsets.
static func is_behind_wall(entity_y: float, wall_y: float) -> bool:
	var ef: float = entity_y + CHARACTER_FOOT_OFFSET
	var wf: float = wall_y + WALL_FOOT_OFFSET
	return ef < wf

## Overload for Node2D callers (null-safe).
static func is_actor_behind_wall(actor: Node2D, wall: Node2D) -> bool:
	if not is_instance_valid(actor) or not is_instance_valid(wall):
		return false
	return is_behind_wall(actor.global_position.y, wall.global_position.y)

## Apply occlusion fade to a wall node (Sprite2D or parent with Sprite2D child).
## Preserves hue, only touches alpha. Call per-frame via update_wall_occlusion().
static func set_wall_alpha(wall: Node2D, alpha: float) -> void:
	var sprites: Array[Node] = wall.find_children("*", "Sprite2D", true, false)
	if sprites.is_empty() and wall is Sprite2D:
		sprites = [wall]
	for s in sprites:
		if s is CanvasItem:
			var ci: CanvasItem = s as CanvasItem
			var c: Color = ci.modulate
			c.a = clampf(alpha, 0.0, 1.0)
			ci.modulate = c
	if sprites.is_empty() and wall is CanvasItem:
		var ci2: CanvasItem = wall as CanvasItem
		var c2: Color = ci2.modulate
		c2.a = clampf(alpha, 0.0, 1.0)
		ci2.modulate = c2

static func reset_wall_alpha(wall: Node2D) -> void:
	set_wall_alpha(wall, 1.0)

## Scan walls and fade those occluding the player. Call each _process frame.
## @param player - CharacterBody2D to test
## @param walls  - Array of wall Node2D; if empty, auto-discovers group "walls"
static func update_wall_occlusion(player: Node2D, walls: Array = [], occluded_alpha: float = OCCLUDED_ALPHA) -> void:
	if not is_instance_valid(player):
		return
	var wall_list: Array = walls
	if wall_list.is_empty() and player.is_inside_tree():
		wall_list = player.get_tree().get_nodes_in_group("walls")
	for w in wall_list:
		if not is_instance_valid(w) or not (w is Node2D):
			continue
		var wn: Node2D = w as Node2D
		if is_actor_behind_wall(player, wn):
			set_wall_alpha(wn, occluded_alpha)
		else:
			reset_wall_alpha(wn)

## Tag a wall so auto-discovery works. Call after add_child(body).
static func tag_wall(wall: Node2D) -> void:
	if is_instance_valid(wall) and not wall.is_in_group("walls"):
		wall.add_to_group("walls")

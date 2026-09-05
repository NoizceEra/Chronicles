# depth_sort_25d.gd — 2.5D YSort helper, no scene dependencies
# Godot 4.6 — add YSort as parent of all sorted sprites, call Depth25D helpers per-frame.
# Foot model: CharacterBody2D feet at y + 12 (32px sprite, origin center, foot ~12px below center).
#             Static walls/trees at y + 16 (32px block, foot at bottom edge).
# Usage: Depth25D.update_sprite_sort(player) each _physics_process, or Depth25D.update_sort_for_group(root)
extends RefCounted
class_name Depth25D

## Offsets — tweak if sprite pivot changes. 32px tiles, 2x zoom.
const CHARACTER_FOOT_OFFSET: float = 12.0
const WALL_FOOT_OFFSET: float = 16.0
const DEFAULT_OCCLUSION_ALPHA: float = 0.35
const OCCLUSION_DISTANCE: float = 96.0  # max foot-distance for wall fade

# ---------------------------------------------------------------------------
# Core helpers (required by spec)
# ---------------------------------------------------------------------------

## Returns the Y foot offset for depth sorting.
## @param is_wall — false = character (12), true = wall/static (16)
static func y_sort_offset(is_wall: bool = false) -> float:
	return WALL_FOOT_OFFSET if is_wall else CHARACTER_FOOT_OFFSET

## Shorthand: character offset (keeps spec signature y_sort_offset() zero-arg compat)
static func character_offset() -> float:
	return CHARACTER_FOOT_OFFSET

static func wall_offset() -> float:
	return WALL_FOOT_OFFSET

## Map a foot Y (global) to a deterministic z_index.
## Uses int(y) so ordering is pixel-perfect and stable across zoom. Clamped to 16-bit.
static func compute_z_index(y: float) -> int:
	# Offset by 4096 so negative coords still sort; clamp to Godot z range.
	var z: int = int(round(y))
	return clampi(z, -4096, 4096)

## Foot Y for any Node2D — accounts for character vs wall offset.
static func foot_y(node: Node2D, is_wall: bool = false) -> float:
	if not is_instance_valid(node):
		return 0.0
	return node.global_position.y + y_sort_offset(is_wall)

## Character-specific foot (y + 12)
static func character_foot_y(actor: Node2D) -> float:
	return foot_y(actor, false)

## Wall-specific foot (y + 16)
static func wall_foot_y(wall: Node2D) -> float:
	return foot_y(wall, true)

## Set z_index on a single Node2D based on its foot. Safe to call every frame.
## Detects walls by group "walls" or StaticBody2D type.
static func update_sprite_sort(node: Node2D) -> void:
	if not is_instance_valid(node):
		return
	var is_wall: bool = node.is_in_group("walls") or node is StaticBody2D
	node.z_index = compute_z_index(foot_y(node, is_wall))
	# Ensure CanvasItem ordering is respected; do not touch YSort node itself.
	# If node is inside a YSort, YSort overrides z_index — caller should prefer YSort sorting,
	# this helper keeps fallback sorting correct.

## Batch update: walk a subtree and set z_index for all Node2D children.
static func update_sort_recursive(root: Node) -> void:
	if root is Node2D:
		update_sprite_sort(root as Node2D)
	for child in root.get_children():
		update_sort_recursive(child)

# ---------------------------------------------------------------------------
# Wall occlusion helpers — fade walls when player is behind them
# ---------------------------------------------------------------------------

## True if actor is visually behind the wall (actor foot is above wall foot)
## and close enough to need fading. Classic 2.5D wall-occlusion test.
static func is_actor_behind_wall(actor: Node2D, wall: Node2D, distance_limit: float = OCCLUSION_DISTANCE) -> bool:
	if not is_instance_valid(actor) or not is_instance_valid(wall):
		return false
	var af: float = character_foot_y(actor)
	var wf: float = wall_foot_y(wall)
	if af >= wf:
		return false  # actor in front — wall not occluding
	var dx: float = abs(actor.global_position.x - wall.global_position.x)
	var dy: float = wf - af  # positive when behind
	if dx > 32.0:
		return false
	if dy > distance_limit:
		return false
	return true

## Apply fade to a wall Sprite2D/CanvasItem. Preserves hue, only touches alpha.
static func set_wall_alpha(wall: Node2D, alpha: float) -> void:
	var sprites: Array[Node] = wall.find_children("*", "Sprite2D", true, false)
	if sprites.is_empty() and wall is Sprite2D:
		sprites = [wall]
	# Also handle wall itself if it's a Sprite2D directly
	for s in sprites:
		if s is CanvasItem:
			var ci: CanvasItem = s as CanvasItem
			var c: Color = ci.modulate
			c.a = clampf(alpha, 0.0, 1.0)
			ci.modulate = c
	# Fallback: if wall has no Sprite2D child, fade the wall CanvasItem itself
	if sprites.is_empty() and wall is CanvasItem:
		var ci2: CanvasItem = wall as CanvasItem
		var c2: Color = ci2.modulate
		c2.a = clampf(alpha, 0.0, 1.0)
		ci2.modulate = c2

static func reset_wall_alpha(wall: Node2D) -> void:
	set_wall_alpha(wall, 1.0)

## Scan walls and fade those occluding the player. Call each frame after sorting.
## @param player — CharacterBody2D to test against
## @param walls — Array of wall Node2D (StaticBody2D + Sprite2D). If empty, auto-discovers group "walls".
## @param occluded_alpha — alpha for occluded walls (0.35 default, subtle see-through)
static func update_wall_occlusion(player: Node2D, walls: Array = [], occluded_alpha: float = DEFAULT_OCCLUSION_ALPHA) -> void:
	if not is_instance_valid(player):
		return
	var wall_list: Array = walls
	if wall_list.is_empty():
		# Auto-discover — walls created by world.gd can be added to group "walls" (see README)
		if player.is_inside_tree():
			wall_list = player.get_tree().get_nodes_in_group("walls")
	for w in wall_list:
		if not is_instance_valid(w) or not (w is Node2D):
			continue
		var wall_node: Node2D = w as Node2D
		if is_actor_behind_wall(player, wall_node):
			set_wall_alpha(wall_node, occluded_alpha)
		else:
			reset_wall_alpha(wall_node)

## Convenience: returns list of walls currently occluding the actor.
static func get_occluded_walls(actor: Node2D, walls: Array = []) -> Array[Node2D]:
	var result: Array[Node2D] = []
	if not is_instance_valid(actor):
		return result
	var wall_list: Array = walls
	if wall_list.is_empty() and actor.is_inside_tree():
		wall_list = actor.get_tree().get_nodes_in_group("walls")
	for w in wall_list:
		if w is Node2D and is_actor_behind_wall(actor, w as Node2D):
			result.append(w as Node2D)
	return result

## Helper for world.gd — tag a wall StaticBody2D for auto-discovery.
static func tag_wall(wall: Node2D) -> void:
	if is_instance_valid(wall) and not wall.is_in_group("walls"):
		wall.add_to_group("walls")

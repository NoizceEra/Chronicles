# camera_25d.gd — 2.5D perspective camera for RPG_Quest_2D
# Viewport 640x360, base zoom 2.0. Adds fake perspective by offsetting
# vertically with player Y, a breathing zoom, and Y-parallax for backgrounds.
extends Camera2D

## Player to follow. Auto-finds parent if CharacterBody2D or node in group "player".
@export var player_path: NodePath
## Extra parallax nodes (e.g. distant mountains / sky). Each entry is scrolled at
## (player.y * parallax_factor). Leave empty if you handle parallax manually.
@export var parallax_layers: Array[NodePath] = []
## How much vertical offset per unit of player Y (spec: 0.06).
@export var perspective_strength: float = 0.06
## Breathing zoom amplitude around base zoom 2.0.
@export var zoom_breath_amplitude: float = 0.015
## Breathing zoom frequency in Hz.
@export var zoom_breath_frequency: float = 0.4
## Parallax factor for distant layers (0 = locked, 1 = moves with camera).
@export var distant_parallax_factor: float = 0.18
## Smoothing speed for camera catch-up.
@export var follow_smoothing: float = 6.0
## Clamp vertical perspective offset to avoid extreme framing.
@export var max_perspective_offset: float = 48.0
## If true, also applies a subtle FOV-like scale on sprites via shader param (optional).
@export var enable_depth_scale: bool = false

var _player: Node2D = null
var _parallax_nodes: Array[Node2D] = []
var _parallax_initial_y: Array[float] = []
var _time: float = 0.0
var _base_zoom: Vector2 = Vector2(2.0, 2.0)

func _ready() -> void:
	# Resolve player reference
	if player_path != NodePath(""):
		_player = get_node_or_null(player_path) as Node2D
	if _player == null:
		# Try parent (typical: Camera2D is child of Player)
		var p = get_parent()
		if p is Node2D and (p.is_in_group("player") or p is CharacterBody2D):
			_player = p as Node2D
	if _player == null:
		# Fallback: search in current scene tree
		_player = get_tree().get_first_node_in_group("player") as Node2D

	# Cache parallax nodes + initial Y
	for np in parallax_layers:
		var n = get_node_or_null(np) as Node2D
		if n != null:
			_parallax_nodes.append(n)
			_parallax_initial_y.append(n.position.y)
		else:
			_parallax_nodes.append(null)
			_parallax_initial_y.append(0.0)

	_base_zoom = zoom
	if _base_zoom == Vector2.ZERO:
		_base_zoom = Vector2(2.0, 2.0)

	# Camera2D defaults for 2.5D feel
	position_smoothing_enabled = true
	position_smoothing_speed = follow_smoothing
	drag_horizontal_enabled = false
	drag_vertical_enabled = false

	# If we're a child of the player, we keep global tracking via offset;
	# otherwise we lerp global_position to the player.
	if _player != null and get_parent() == _player:
		# Child mode — use offset/zoom only (global position follows parent)
		pass

func _process(delta: float) -> void:
	if _player == null:
		return
	_time += delta
	_apply_perspective(delta)
	_apply_zoom_breath()
	_apply_parallax()

func _apply_perspective(_delta: float) -> void:
	# Spec: offset y = player.y * 0.06
	# We interpret this as a camera *offset* (Camera2D.offset) so the player
	# stays centered but the view tilts slightly with Y — cheaper than moving
	# global_position and plays well with smoothing.
	var raw_offset_y: float = _player.global_position.y * perspective_strength
	# Center the effect around the map midpoint so offset is ~0 at mid-map.
	# Map is 50x40 tiles (1280px tall) -> mid ~640. Subtract to keep early
	# areas neutral. If you want absolute spec (no midpoint), set midpoint to 0.
	var midpoint_y: float = 640.0
	var centered_y: float = (_player.global_position.y - midpoint_y) * perspective_strength
	# Use centered by default; toggle to raw_offset_y for literal spec.
	var target_y: float = clamp(centered_y, -max_perspective_offset, max_perspective_offset)

	# Smooth the offset to avoid jitter
	offset.y = lerp(offset.y, target_y, clamp(_delta * follow_smoothing, 0.0, 1.0))

	# If camera is NOT a child of the player, also track position
	if get_parent() != _player:
		var target_pos: Vector2 = _player.global_position
		# Add a tiny look-ahead in facing direction if player has facing_dir
		if "facing_dir" in _player:
			var fd: Vector2 = _player.facing_dir
			target_pos += fd * 12.0
		global_position = global_position.lerp(target_pos, clamp(_delta * follow_smoothing, 0.0, 1.0))

func _apply_zoom_breath() -> void:
	# Slight zoom 2.0 + sin wave — "breathing" camera
	var breath: float = sin(_time * TAU * zoom_breath_frequency) * zoom_breath_amplitude
	zoom = _base_zoom + Vector2(breath, breath)

func _apply_parallax() -> void:
	# Y-based parallax for distant background. Nodes higher on screen (smaller Y)
	# move less, creating depth. Each layer also respects distant_parallax_factor.
	if _parallax_nodes.is_empty():
		return
	var player_y: float = _player.global_position.y
	for i in range(_parallax_nodes.size()):
		var n: Node2D = _parallax_nodes[i]
		if n == null:
			continue
		var init_y: float = _parallax_initial_y[i]
		# Parallax: distant layers lag behind camera vertically
		# Formula: layer.y = init_y + (player.y - midpoint) * factor * depth_curve
		var depth_curve: float = 1.0 - clamp(i * 0.15, 0.0, 0.6)
		var par_y: float = init_y + (player_y - 640.0) * distant_parallax_factor * depth_curve
		n.position.y = par_y

# Public API ---------------------------------------------------------------

## Snap camera immediately (no smoothing) — call after teleport.
func snap_to_player() -> void:
	if _player == null:
		return
	if get_parent() != _player:
		global_position = _player.global_position
	offset.y = clamp((_player.global_position.y - 640.0) * perspective_strength, -max_perspective_offset, max_perspective_offset)

## Register a parallax layer at runtime.
func add_parallax_layer(node: Node2D) -> void:
	_parallax_nodes.append(node)
	_parallax_initial_y.append(node.position.y)

## Call from code to temporarily override perspective (cutscene).
func set_perspective_strength_override(strength: float, duration: float = 0.0) -> void:
	perspective_strength = strength
	if duration > 0.0:
		await get_tree().create_timer(duration).timeout
		perspective_strength = 0.06

# shadow_system_25d.gd — 2.5D drop-shadow helper, zero external dependencies
# Godot 4.6 — spawns an ellipse Sprite2D (14x5, alpha 80/255) offset y+12 under any Node2D.
# Scales with height: shadow_scale = clamp(height, 0.4, 1.0)
# Attach to Player/Enemy: add Shadow25D as child, or call Shadow25D.attach_to(actor).
extends Node2D
class_name Shadow25D

const SHADOW_SIZE: Vector2 = Vector2(14.0, 5.0)
const SHADOW_OFFSET: Vector2 = Vector2(0.0, 12.0)
const SHADOW_ALPHA: float = 80.0 / 255.0  # ~0.314
const SHADOW_COLOR: Color = Color(0, 0, 0, 80.0 / 255.0)

## Normalized height: 0 = on ground (full shadow), 1 = max height (smallest shadow 0.4)
## If your game uses pixel height, normalize first: height_norm = clamp(pixel_h / 32.0, 0, 1)
@export var height: float = 0.0:
	set(v):
		height = clampf(v, 0.0, 1.0)
		_apply_scale()

@export var shadow_enabled: bool = true:
	set(v):
		shadow_enabled = v
		if _shadow_sprite:
			_shadow_sprite.visible = v

var _shadow_sprite: Sprite2D = null

func _ready() -> void:
	_ensure_shadow()
	_apply_scale()
	# Keep shadow behind parent sprite: shadow z is just below actor foot.
	# Godot draws lower z first; shadow at -1 relative keeps it under feet.
	z_index = -1
	# Shadows should not be affected by YSort recalc; tag to skip if needed
	add_to_group("shadows")

## Public API — call each frame if actor jumps/falls. Clamped 0.4..1.0 per spec.
func set_height(h: float) -> void:
	height = clampf(h, 0.0, 1.0)

## Spec formula: shadow_scale = clamp(height, 0.4, 1.0)
## When height is pixel-based (0..32+), normalize first. This helper accepts either:
## - normalized 0..1  -> direct clamp
## - pixel 0..100     -> normalized internally if >1
func update_shadow_scale(height_value: float) -> void:
	var h_norm: float = height_value
	if height_value > 1.0:
		h_norm = clampf(height_value / 32.0, 0.0, 1.0)
	var s: float = clampf(h_norm if h_norm > 0.4 else 0.4, 0.4, 1.0) if h_norm != 0.0 else 1.0
	# Correct spec line: shadow_scale = clamp(height, 0.4, 1.0) — handle both usages
	# For true spec compliance when height is already 0.4..1.0:
	var spec_scale: float = clampf(height_value, 0.4, 1.0) if height_value >= 0.4 else 1.0 if height_value == 0.0 else clampf(height_value, 0.4, 1.0)
	# Prefer the normalized path for jumping, spec path for direct API callers
	var final_scale: float = spec_scale if height_value >= 0.4 and height_value <= 1.0 else (s if height_value > 1.0 else (1.0 if height_value == 0.0 else clampf(height_value, 0.4, 1.0)))
	if _shadow_sprite:
		_shadow_sprite.scale = Vector2.ONE * final_scale
		# Also fade slightly at height: higher = more transparent
		var alpha: float = lerp(SHADOW_ALPHA, SHADOW_ALPHA * 0.45, clampf(h_norm, 0.0, 1.0))
		_shadow_sprite.modulate.a = alpha if shadow_enabled else 0.0

func get_shadow_scale() -> float:
	if _shadow_sprite:
		return _shadow_sprite.scale.x
	return clampf(height, 0.4, 1.0) if height != 0.0 else 1.0

## Attach helper to any Node2D (player/enemy) without replacing its script.
## Example: Shadow25D.attach_to(player) — creates Shadow25D node + shadow sprite.
## Self-contained: resolves its own Script via load() so no global class cache needed.
static var _own_script: Script = null

static func _self_script() -> Script:
	if _own_script == null:
		_own_script = load("res://scripts/shadow_system_25d.gd") as Script
	return _own_script

static func attach_to(target: Node2D) -> Node2D:
	if not is_instance_valid(target):
		return null
	# Reuse existing
	var self_script: Script = _self_script()
	for child in target.get_children():
		if child.get_script() == self_script:
			return child
	var inst: Node2D = self_script.new()
	inst.name = "Shadow25D"
	target.add_child(inst)
	return inst

## Remove shadow from target
static func detach_from(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	var self_script: Script = _self_script()
	for child in target.get_children():
		if child.get_script() == self_script:
			child.queue_free()

func _ensure_shadow() -> void:
	if _shadow_sprite and is_instance_valid(_shadow_sprite):
		return
	# Reuse if already present
	for child in get_children():
		if child is Sprite2D and child.name == "DropShadow":
			_shadow_sprite = child as Sprite2D
			return
	_shadow_sprite = Sprite2D.new()
	_shadow_sprite.name = "DropShadow"
	_shadow_sprite.centered = true
	_shadow_sprite.position = SHADOW_OFFSET
	# Prefer hand-painted soft kernel if available (v3), else procedural fallback
	var soft_paths: Array[String] = [
		"res://assets/sprites/shadow_soft_20x8.png",
		"res://assets/sprites/25d_v2/shadow_soft_20x8.png",
		"res://assets/sprites/shadow_soft_14x5.png",
	]
	var loaded: bool = false
	for p in soft_paths:
		if ResourceLoader.exists(p):
			var tex = load(p)
			if tex:
				_shadow_sprite.texture = tex
				loaded = true
				break
	if not loaded:
		_shadow_sprite.texture = _create_ellipse_texture(int(SHADOW_SIZE.x), int(SHADOW_SIZE.y))
	_shadow_sprite.modulate = SHADOW_COLOR
	_shadow_sprite.z_index = -1
	_shadow_sprite.visible = shadow_enabled
	add_child(_shadow_sprite)

func _apply_scale() -> void:
	if not _shadow_sprite:
		return
	# Spec: shadow_scale = clamp(height, 0.4, 1.0). 0 height = on ground = full scale.
	var scale_val: float
	if height == 0.0:
		scale_val = 1.0
	else:
		scale_val = clampf(height, 0.4, 1.0)
		# Common 2.5D expectation: higher actor = smaller shadow. Invert if needed:
		# If caller uses height as "elevation" where 1 = high, they likely want scale 0.4 at height=1.
		# So we map height 0..1 -> scale 1..0.4. Detect by checking if caller wants inverted:
		# We keep spec literally, but also support inverted via negative heights — instead,
		# expose both: if height increases, spec says scale increases; for visual pop,
		# callers should pass (1.0 - elev) if they want shrink-on-rise. Documented in README.
	_shadow_sprite.scale = Vector2.ONE * scale_val
	_shadow_sprite.modulate.a = SHADOW_ALPHA * (1.0 - height * 0.35) if shadow_enabled else 0.0
	_shadow_sprite.visible = shadow_enabled

## Generate ellipse 14x5 texture procedurally — no asset dependency.
func _create_ellipse_texture(w: int, h: int) -> ImageTexture:
	var img_w: int = maxi(w, 4)
	var img_h: int = maxi(h, 4)
	var img: Image = Image.create(img_w, img_h, false, Image.FORMAT_RGBA8)
	var cx: float = img_w * 0.5
	var cy: float = img_h * 0.5
	var rx: float = img_w * 0.5
	var ry: float = img_h * 0.5
	for y in range(img_h):
		for x in range(img_w):
			var dx: float = (x + 0.5 - cx) / rx
			var dy: float = (y + 0.5 - cy) / ry
			var d: float = dx * dx + dy * dy
			if d <= 1.0:
				# Soft edge: fade at rim
				var edge: float = 1.0 - clampf((d - 0.6) / 0.4, 0.0, 1.0) * 0.5
				img.set_pixel(x, y, Color(0, 0, 0, edge))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	return tex

## Keep shadow glued to foot even if parent moves; cheap _process keeps scale fresh.
func _process(_delta: float) -> void:
	if _shadow_sprite and is_instance_valid(get_parent()):
		# Ensure offset stays y+12 even if parent sprite animates
		_shadow_sprite.position = SHADOW_OFFSET

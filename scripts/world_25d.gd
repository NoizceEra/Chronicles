# world_25d.gd
# Additive 2.5D World - drop-in alternative to world.gd that delegates to WorldBuilder25D.
# Keeps original world.gd intact; use this scene/script when you want wall height,
# raised platforms, stairs, YSort, and foot-anchored props.
extends Node2D

const WorldBuilder25D = preload("res://scripts/world_builder_25d.gd")
const Depth25D = preload("res://scripts/depth_sort_25d.gd")
const Shadow25D = preload("res://scripts/shadow_system_25d.gd")

@onready var player = $Player
@onready var hud = $HUD
@onready var world_entities = $Entities

var enemy_types = ["slime_green", "slime_blue", "slime_red", "goblin", "skeleton"]

func _ready() -> void:
	# 2.5D default: single YSort root so Player sorts against walls/trees/enemies.
	# Entities is the sort parent; World also sorts for ground/decor parity.
	y_sort_enabled = true
	if world_entities:
		world_entities.y_sort_enabled = true
	# Build statics INTO Entities so they share the sort space with actors.
	_build_into_sort_root()
	_reparent_player_to_sort_root()
	spawn_monsters_and_chests()
	Shadow25D.attach_to(player)
	_attach_height_fog()
	if player and hud:
		player.stats_changed.connect(hud.update_stats)
		player.player_died.connect(hud.show_game_over)
		player.emit_stats()

func _process(_delta: float) -> void:
	if player:
		# Query both wall groups: builder tags "walls_25d", legacy tags "walls".
		var walls: Array = get_tree().get_nodes_in_group("walls_25d")
		walls.append_array(get_tree().get_nodes_in_group("walls"))
		Depth25D.update_wall_occlusion(player, walls)

func _sort_root() -> Node2D:
	return world_entities if world_entities else self

# Replicates world.gd build_world_map but via the 2.5D builder
func build_25d_world_map() -> void:
	_build_into_sort_root()

func _build_into_sort_root() -> void:
	var tile_tex: Texture2D = load("res://assets/tiles/tileset.png")
	if tile_tex == null:
		push_warning("[world_25d] tileset.png not found")
		return
	WorldBuilder25D.build_25d_world(_sort_root(), tile_tex)

func _reparent_player_to_sort_root() -> void:
	var root := _sort_root()
	if player and root and player.get_parent() != root:
		var gp: Vector2 = player.global_position
		player.get_parent().remove_child(player)
		root.add_child(player)
		player.global_position = gp

# Height fog overlay, default OFF (intensity 0.0) — mirrors world.gd.
# Raise fog_intensity to 0.55 for the full southern-dungeon fog look.
func _attach_height_fog() -> void:
	var fog_shader = load("res://shaders/height_fog.gdshader")
	if fog_shader == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = -1
	layer.name = "HeightFogLayer"
	var overlay := ColorRect.new()
	overlay.name = "HeightFogOverlay"
	overlay.color = Color(0, 0, 0, 0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = fog_shader
	mat.set_shader_parameter("fog_start_y", 560.0)
	mat.set_shader_parameter("fog_end_y", 1280.0)
	mat.set_shader_parameter("fog_intensity", 0.0)
	mat.set_shader_parameter("use_uv_y", true)
	overlay.material = mat
	layer.add_child(overlay)
	add_child(layer)

# Thin wrappers exposed for external callers that already have a texture
func build_25d_world(parent: Node2D, tile_tex: Texture2D) -> void:
	WorldBuilder25D.build_25d_world(parent, tile_tex)

func create_wall_25d(pos: Vector2, tile_tex: Texture2D) -> StaticBody2D:
	return WorldBuilder25D.create_wall_25d(self, pos, tile_tex)

func create_tree_25d(pos: Vector2, tile_tex: Texture2D) -> StaticBody2D:
	return WorldBuilder25D.create_tree_25d(self, pos, tile_tex)

func create_crate_25d(pos: Vector2, tile_tex: Texture2D) -> StaticBody2D:
	return WorldBuilder25D.create_crate_25d(self, pos, tile_tex)

func create_column_25d(pos: Vector2, tile_tex: Texture2D) -> StaticBody2D:
	return WorldBuilder25D.create_column_25d(self, pos, tile_tex)

func create_stair_tile(pos: Vector2, tile_tex: Texture2D) -> Node2D:
	return WorldBuilder25D.create_stair_tile(self, pos, tile_tex)

# ----------------------------------------------------------------
# Monster & chest spawning - identical to world.gd for parity
func spawn_monsters_and_chests() -> void:
	var enemy_script = load("res://scripts/enemy.gd")
	var chest_script = load("res://scripts/chest.gd")

	var monster_spawns = [
		["slime_green", Vector2(220, 260)],
		["slime_green", Vector2(340, 200)],
		["slime_blue", Vector2(450, 300)],
		["slime_blue", Vector2(280, 500)],
		["slime_green", Vector2(180, 680)],
		["slime_blue", Vector2(420, 700)],
		["goblin", Vector2(920, 600)],
		["goblin", Vector2(1050, 750)],
		["skeleton", Vector2(1250, 650)],
		["skeleton", Vector2(1100, 950)],
		["slime_red", Vector2(1300, 900)],
		["skeleton", Vector2(1350, 1050)],
		["goblin", Vector2(980, 1080)]
	]
	for spawn_info in monster_spawns:
		var m_type = spawn_info[0]
		var pos: Vector2 = spawn_info[1]
		var enemy = CharacterBody2D.new()
		enemy.set_script(enemy_script)
		enemy.position = pos
		enemy.set("enemy_type", m_type)
		var anim = AnimatedSprite2D.new()
		anim.name = "AnimatedSprite2D"
		enemy.add_child(anim)
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 12.0
		col.shape = shape
		enemy.add_child(col)
		if world_entities:
			world_entities.add_child(enemy)
		else:
			add_child(enemy)
		Shadow25D.attach_to(enemy)

	var chest_spawns = [
		Vector2(140, 180),
		Vector2(550, 150),
		Vector2(1350, 580),
		Vector2(1400, 1100),
		Vector2(950, 1120)
	]
	for pos in chest_spawns:
		var chest = Area2D.new()
		chest.set_script(chest_script)
		chest.position = pos
		if world_entities:
			world_entities.add_child(chest)
		else:
			add_child(chest)
		Shadow25D.attach_to(chest)

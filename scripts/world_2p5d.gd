# world_2p5d.gd - 2.5D variant of world.gd. Non-breaking: original world.gd untouched.
# Enhancements over world.gd:
# - y_sort_enabled = true on World and Entities (scene + code fallback)
# - Wall blocks get a darkened side-face Sprite2D at y+16 (tileset_2p5d.png)
#   dungeon walls: Rect2(64,256,32,16), city walls: Rect2(128,256,32,16)
# - Tree sprites foot-aligned (offset y-6) so base meets collision; y_sort works
# - Enemies/chests get a drop shadow Sprite2D (shadow_blob.png) at y+12, z_index=-1
# Spawn positions identical to world.gd (50x40 map, same monster/chest vectors).
extends Node2D

@onready var player = $Player
@onready var hud = $HUD
@onready var world_entities: Node2D = $Entities

var enemy_types = ["slime_green", "slime_blue", "slime_red", "goblin", "skeleton"]

# Preload shared helpers (optional - graceful if missing)
const DepthSortingScript = preload("res://scripts/depth_sorting.gd")

func _ready() -> void:
	# Ensure y_sort is enabled even if scene was opened without it
	y_sort_enabled = true
	if world_entities:
		world_entities.y_sort_enabled = true

	build_world_map()
	spawn_monsters_and_chests()

	if player and hud:
		if player.has_signal("stats_changed"):
			player.stats_changed.connect(hud.update_stats)
		if player.has_signal("player_died"):
			player.player_died.connect(hud.show_game_over)
		if player.has_method("emit_stats"):
			player.emit_stats()

	# Attach shadow under player if player_2p5d.tscn not used (fallback)
	_ensure_shadow(player)

func _process(_delta: float) -> void:
	# Optional wall occlusion fade (requires walls tagged with group "walls")
	if player and DepthSortingScript:
		DepthSortingScript.update_wall_occlusion(player)

func build_world_map() -> void:
	var tile_tex: Texture2D = load("res://assets/tiles/tileset.png")
	if not tile_tex:
		return

	var tileset_2p5d: Texture2D = load("res://assets/tiles/tileset_2p5d.png")

	var map_w: int = 50
	var map_h: int = 40

	# Ground Layer - identical tile choices to world.gd
	for y in range(map_h):
		for x in range(map_w):
			var tile_sprite := Sprite2D.new()
			var atlas := AtlasTexture.new()
			atlas.atlas = tile_tex

			if x > 25 and y > 15:
				atlas.region = Rect2(0, 224, 32, 32) # Dungeon stone floor
			elif (x < 10 and y < 10) or (x >= 20 and x <= 25 and y >= 5 and y <= 10):
				atlas.region = Rect2(192, 0, 32, 32) # Water pond
			elif (x + y) % 9 == 0:
				atlas.region = Rect2(224, 64, 32, 32) # Flower grass
			elif x % 7 == 0 or y % 8 == 0:
				atlas.region = Rect2(0, 64, 32, 32) # Dirt path
			else:
				atlas.region = Rect2(128, 64, 32, 32) # Plain grass

			tile_sprite.texture = atlas
			tile_sprite.position = Vector2(x * 32 + 16, y * 32 + 16)
			tile_sprite.z_index = -100 # ground below everything
			add_child(tile_sprite)

	# Dungeon Brick Walls with Colliders + side face
	for y in range(15, 38):
		for x in range(25, 48):
			var is_wall: bool = (x in [25, 47] or y in [15, 37])
			if x == 36 and not (y in [22, 23]):
				is_wall = true
			if y == 26 and not (x in [30, 31, 41, 42]):
				is_wall = true
			if x == 25 and y in [20, 21]:
				is_wall = false # entrance door

			if is_wall:
				# Dungeon walls use 64,256; city variant would be 128,256 (see create_wall_block)
				create_wall_block(Vector2(x * 32 + 16, y * 32 + 16), tile_tex, tileset_2p5d, false)

	# Outer Map Boundary Trees
	for x in range(map_w):
		create_tree_obstacle(Vector2(x * 32 + 16, 16), tile_tex)
		create_tree_obstacle(Vector2(x * 32 + 16, (map_h - 1) * 32 + 16), tile_tex)
	for y in range(1, map_h - 1):
		create_tree_obstacle(Vector2(16, y * 32 + 16), tile_tex)
		create_tree_obstacle(Vector2((map_w - 1) * 32 + 16, y * 32 + 16), tile_tex)

	# Scattered Forest Trees - identical positions to world.gd
	var tree_positions: Array[Vector2] = [
		Vector2(120, 150), Vector2(180, 220), Vector2(240, 160), Vector2(320, 280),
		Vector2(150, 400), Vector2(280, 460), Vector2(400, 350), Vector2(500, 200),
		Vector2(200, 600), Vector2(350, 720), Vector2(150, 850), Vector2(450, 900)
	]
	for pos in tree_positions:
		create_tree_obstacle(pos, tile_tex)

func create_wall_block(pos: Vector2, tile_tex: Texture2D, tileset_2p5d: Texture2D = null, is_city: bool = false) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos

	var spr := Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = tile_tex
	atlas.region = Rect2(64, 128, 32, 32) # iron grate / brick wall top
	spr.texture = atlas
	body.add_child(spr)

	# --- 2.5D side face (16px extrusion below wall) ---
	if tileset_2p5d:
		var face := Sprite2D.new()
		var face_atlas := AtlasTexture.new()
		face_atlas.atlas = tileset_2p5d
		# Dungeon: 64,256  City: 128,256  (both 32x16)
		face_atlas.region = Rect2(128, 256, 32, 16) if is_city else Rect2(64, 256, 32, 16)
		face.texture = face_atlas
		face.position = Vector2(0, 16) # sits directly below top face
		face.z_index = -1
		body.add_child(face)
	else:
		# Fallback: reuse lower half of wall tile darkened (no 2p5d asset)
		var face2 := Sprite2D.new()
		var a2 := AtlasTexture.new()
		a2.atlas = tile_tex
		a2.region = Rect2(64, 144, 32, 16)
		face2.texture = a2
		face2.position = Vector2(0, 16)
		face2.modulate = Color(0.45, 0.38, 0.32, 1.0)
		face2.z_index = -1
		body.add_child(face2)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	col.shape = shape
	body.add_child(col)

	# Tag for DepthSorting occlusion + y_sort grouping
	body.add_to_group("walls")
	body.add_to_group("ysort")

	add_child(body)
	return body

func create_tree_obstacle(pos: Vector2, tile_tex: Texture2D) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos

	var spr := Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = tile_tex
	atlas.region = Rect2(128, 32, 32, 32) # canopy / bush
	spr.texture = atlas
	# Foot alignment: lift sprite so trunk base meets body origin (collision foot)
	spr.position = Vector2(0, -6)
	body.add_child(spr)

	# Soft shadow hint at base (visual only)
	var shadow := Sprite2D.new()
	var shadow_tex: Texture2D = load("res://assets/sprites/shadow_blob.png")
	if shadow_tex == null:
		shadow_tex = load("res://assets/sprites/drop_shadow_14x5.png")
	if shadow_tex:
		shadow.texture = shadow_tex
		shadow.position = Vector2(0, 10)
		shadow.modulate = Color(1, 1, 1, 0.55)
		shadow.z_index = -1
		body.add_child(shadow)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	col.shape = shape
	col.position = Vector2(0, 4) # foot-anchored at bottom
	body.add_child(col)

	body.add_to_group("ysort")
	body.add_to_group("decor_2p5d")

	add_child(body)
	return body

func spawn_monsters_and_chests() -> void:
	var enemy_script = load("res://scripts/enemy.gd")
	var chest_script = load("res://scripts/chest.gd")

	# Identical spawns to world.gd for parity
	var monster_spawns: Array = [
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
		var m_type: String = spawn_info[0]
		var pos: Vector2 = spawn_info[1]
		var enemy := CharacterBody2D.new()
		if enemy_script:
			enemy.set_script(enemy_script)
		enemy.position = pos
		enemy.set("enemy_type", m_type)

		var anim := AnimatedSprite2D.new()
		anim.name = "AnimatedSprite2D"
		# Foot alignment for 2.5D: lift sprite so feet sit at body origin
		anim.offset = Vector2(0, -7)
		enemy.add_child(anim)

		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 12.0
		col.shape = shape
		enemy.add_child(col)

		# Drop shadow under enemy
		_ensure_shadow(enemy)

		if world_entities:
			world_entities.add_child(enemy)
		else:
			add_child(enemy)

	var chest_spawns: Array[Vector2] = [
		Vector2(140, 180),
		Vector2(550, 150),
		Vector2(1350, 580),
		Vector2(1400, 1100),
		Vector2(950, 1120)
	]
	for cpos in chest_spawns:
		var chest := Area2D.new()
		if chest_script:
			chest.set_script(chest_script)
		chest.position = cpos
		_ensure_shadow(chest)
		if world_entities:
			world_entities.add_child(chest)
		else:
			add_child(chest)

# ---------------------------------------------------------------------------
# Shadow helper - adds Sprite2D blob if not already present
func _ensure_shadow(target: Node) -> void:
	if not is_instance_valid(target) or not (target is Node2D):
		return
	# Avoid duplicates
	for child in (target as Node).get_children():
		if child.name == "ShadowBlob":
			return
	var tex: Texture2D = load("res://assets/sprites/shadow_blob.png")
	if tex == null:
		tex = load("res://assets/sprites/drop_shadow_14x5.png")
	if tex == null:
		tex = load("res://assets/tiles/drop_shadow_14x5.png")
	if tex == null:
		return
	var shadow := Sprite2D.new()
	shadow.name = "ShadowBlob"
	shadow.texture = tex
	shadow.position = Vector2(0, 12)
	shadow.z_index = -1
	shadow.modulate = Color(1, 1, 1, 0.55)
	(target as Node2D).add_child(shadow)

# world.gd
extends Node2D

@onready var player = $Player
@onready var hud = $HUD
@onready var world_entities = $Entities

var enemy_types = ["slime_green", "slime_blue", "slime_red", "goblin", "skeleton"]

func _ready() -> void:
	build_world_map()
	spawn_monsters_and_chests()
	
	if player and hud:
		player.stats_changed.connect(hud.update_stats)
		player.player_died.connect(hud.show_game_over)
		player.emit_stats()

func build_world_map() -> void:
	var tile_tex = load("res://assets/tiles/tileset.png")
	if not tile_tex:
		return

	# Map size: 50x40 tiles (1600x1280 px)
	var map_w = 50
	var map_h = 40
	
	# Ground Layer
	for y in range(map_h):
		for x in range(map_w):
			var tile_sprite = Sprite2D.new()
			var atlas = AtlasTexture.new()
			atlas.atlas = tile_tex
			
			# Overworld vs Dungeon zone
			if x > 25 and y > 15:
				# Dungeon Zone (Stone)
				atlas.region = Rect2(96, 0, 32, 32)
			elif (x < 10 and y < 10) or (x >= 20 and x <= 25 and y >= 5 and y <= 10):
				# Water Pond
				atlas.region = Rect2(160, 0, 32, 32)
			elif (x + y) % 9 == 0:
				# Flower grass
				atlas.region = Rect2(32, 0, 32, 32)
			elif x % 7 == 0 or y % 8 == 0:
				# Dirt path
				atlas.region = Rect2(64, 0, 32, 32)
			else:
				# Plain grass
				atlas.region = Rect2(0, 0, 32, 32)

			tile_sprite.texture = atlas
			tile_sprite.position = Vector2(x * 32 + 16, y * 32 + 16)
			add_child(tile_sprite)

	# Dungeon Brick Walls with Colliders
	for y in range(15, 38):
		for x in range(25, 48):
			var is_wall = (x in [25, 47] or y in [15, 37])
			# Add internal partition walls with doorways
			if x == 36 and not (y in [22, 23]):
				is_wall = true
			if y == 26 and not (x in [30, 31, 41, 42]):
				is_wall = true
			# Entrance door
			if x == 25 and y in [20, 21]:
				is_wall = false

			if is_wall:
				create_wall_block(Vector2(x * 32 + 16, y * 32 + 16), tile_tex)

	# Outer Map Boundary Walls & Trees
	for x in range(map_w):
		create_tree_obstacle(Vector2(x * 32 + 16, 16), tile_tex)
		create_tree_obstacle(Vector2(x * 32 + 16, (map_h - 1) * 32 + 16), tile_tex)
	for y in range(1, map_h - 1):
		create_tree_obstacle(Vector2(16, y * 32 + 16), tile_tex)
		create_tree_obstacle(Vector2((map_w - 1) * 32 + 16, y * 32 + 16), tile_tex)

	# Scattered Forest Trees
	var tree_positions = [
		Vector2(120, 150), Vector2(180, 220), Vector2(240, 160), Vector2(320, 280),
		Vector2(150, 400), Vector2(280, 460), Vector2(400, 350), Vector2(500, 200),
		Vector2(200, 600), Vector2(350, 720), Vector2(150, 850), Vector2(450, 900)
	]
	for pos in tree_positions:
		create_tree_obstacle(pos, tile_tex)

func create_wall_block(pos: Vector2, tile_tex: Texture2D) -> void:
	var body = StaticBody2D.new()
	body.position = pos
	
	var spr = Sprite2D.new()
	var atlas = AtlasTexture.new()
	atlas.atlas = tile_tex
	atlas.region = Rect2(128, 0, 32, 32)
	spr.texture = atlas
	body.add_child(spr)

	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	col.shape = shape
	body.add_child(col)
	add_child(body)

func create_tree_obstacle(pos: Vector2, tile_tex: Texture2D) -> void:
	var body = StaticBody2D.new()
	body.position = pos

	var spr = Sprite2D.new()
	var atlas = AtlasTexture.new()
	atlas.atlas = tile_tex
	atlas.region = Rect2(192, 0, 32, 32)
	spr.texture = atlas
	body.add_child(spr)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12.0
	col.shape = shape
	body.add_child(col)
	add_child(body)

func spawn_monsters_and_chests() -> void:
	var enemy_script = load("res://scripts/enemy.gd")
	var chest_script = load("res://scripts/chest.gd")

	# Spawning Monsters across overworld and dungeon
	var monster_spawns = [
		# Overworld Slimes
		["slime_green", Vector2(220, 260)],
		["slime_green", Vector2(340, 200)],
		["slime_blue", Vector2(450, 300)],
		["slime_blue", Vector2(280, 500)],
		["slime_green", Vector2(180, 680)],
		["slime_blue", Vector2(420, 700)],
		# Dungeon Goblins, Skeletons, and Magma Slimes
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
		var pos = spawn_info[1]
		var enemy = CharacterBody2D.new()
		enemy.set_script(enemy_script)
		enemy.position = pos
		enemy.enemy_type = m_type
		
		var anim = AnimatedSprite2D.new()
		anim.name = "AnimatedSprite2D"
		enemy.add_child(anim)

		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 12.0
		col.shape = shape
		enemy.add_child(col)

		world_entities.add_child(enemy)

	# Spawning Treasure Chests
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
		world_entities.add_child(chest)

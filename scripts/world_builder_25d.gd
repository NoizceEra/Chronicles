# world_builder_25d.gd
# Additive 2.5D world builder - replicates world.gd's 50x40 tile map but adds
# wall height (top + 16px south face darkened), raised platforms (2 tiles high
# with cliff side), stair tiles, YSort grouping, and foot-anchored props.
# Uses only Godot 4 core nodes: Node2D, Sprite2D, AtlasTexture, StaticBody2D, CollisionShape2D
# plus RectangleShape2D / CircleShape2D for collision shapes.
class_name WorldBuilder25D
extends RefCounted

const MAP_W: int = 50
const MAP_H: int = 40
const TILE: int = 32
const WALL_FACE_H: int = 16
const PLATFORM_H: int = 32 # 2 tiles high

# YSort helper - enables y_sort on parent and tags children
static func _enable_ysort(parent: Node2D) -> void:
	parent.y_sort_enabled = true
	# Parent itself is the YSort root in Godot 4. Children are ordered by y.

# ----------------------------------------------------------------
# Public entry point - call from any Node2D scene
# @param parent - Node2D that will own all generated nodes (typically the World root)
# @param tile_tex - tileset Texture2D (res://assets/tiles/tileset.png)
static func build_25d_world(parent: Node2D, tile_tex: Texture2D) -> void:
	if tile_tex == null:
		push_warning("[WorldBuilder25D] tile_tex is null, aborting.")
		return
	_enable_ysort(parent)
	_build_ground_layer(parent, tile_tex)
	_build_dungeon_walls_25d(parent, tile_tex)
	_build_raised_platforms(parent, tile_tex)
	_build_stairs(parent, tile_tex)
	_build_boundary_trees(parent, tile_tex)
	_build_scattered_decor(parent, tile_tex)
	_build_props_25d(parent, tile_tex)

# ----------------------------------------------------------------
# Ground layer - 1:1 replica of world.gd logic
static func _build_ground_layer(parent: Node2D, tile_tex: Texture2D) -> void:
	for y in range(MAP_H):
		for x in range(MAP_W):
			var spr := Sprite2D.new()
			var atlas := AtlasTexture.new()
			atlas.atlas = tile_tex
			if x > 25 and y > 15:
				atlas.region = Rect2(0, 224, 32, 32) # dungeon stone floor
			elif (x < 10 and y < 10) or (x >= 20 and x <= 25 and y >= 5 and y <= 10):
				atlas.region = Rect2(192, 0, 32, 32) # water pond
			elif (x + y) % 9 == 0:
				atlas.region = Rect2(224, 64, 32, 32) # flower grass
			elif x % 7 == 0 or y % 8 == 0:
				atlas.region = Rect2(0, 64, 32, 32) # dirt path / plaza
			else:
				atlas.region = Rect2(128, 64, 32, 32) # plain grass
			spr.texture = atlas
			spr.position = Vector2(x * TILE + TILE * 0.5, y * TILE + TILE * 0.5)
			# Ground is below everything - push slightly back
			spr.z_index = -100
			parent.add_child(spr)

# ----------------------------------------------------------------
# Dungeon walls with 2.5D height: top 32x32 + 16px south face darkened
static func _build_dungeon_walls_25d(parent: Node2D, tile_tex: Texture2D) -> void:
	for y in range(15, 38):
		for x in range(25, 48):
			var is_wall: bool = (x == 25 or x == 47 or y == 15 or y == 37)
			if x == 36 and y not in [22, 23]:
				is_wall = true
			if y == 26 and x not in [30, 31, 41, 42]:
				is_wall = true
			if x == 25 and y in [20, 21]:
				is_wall = false # entrance door
			if is_wall:
				create_wall_25d(parent, Vector2(x * TILE + 16, y * TILE + 16), tile_tex)

# Single 2.5D wall block: StaticBody2D with top sprite, darkened south face, Rect collider
static func create_wall_25d(parent: Node2D, pos: Vector2, tile_tex: Texture2D) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	body.add_to_group("ysort")
	body.add_to_group("walls_25d")
	body.add_to_group("walls") # Depth25D auto-discovery group as well

	# Improved art: wall_25d.png 32x48 slices (32 top + 16 baked side,
	# row 0 = dungeon stone). Falls back to shaded base-tileset regions.
	var wall_sheet: Texture2D = load("res://assets/tiles/wall_25d.png")
	if wall_sheet != null:
		# Texture variety along the run + occasional cracked accent block.
		var tx: int = int(pos.x / TILE)
		var ty: int = int(pos.y / TILE)
		var cols: Array[int] = [0, 1, 3, 5]
		var wcol: int = cols[(tx + ty) % 4]
		if (tx * 3 + ty * 7) % 11 == 0:
			wcol = 4
		var ox: int = wcol * 32
		var top_spr := Sprite2D.new()
		var top_atlas := AtlasTexture.new()
		top_atlas.atlas = wall_sheet
		top_atlas.region = Rect2(ox, 0, 32, 32)
		top_spr.texture = top_atlas
		body.add_child(top_spr)

		var face_spr := Sprite2D.new()
		var face_atlas := AtlasTexture.new()
		face_atlas.atlas = wall_sheet
		face_atlas.region = Rect2(ox, 32, 32, 16)
		face_spr.texture = face_atlas
		face_spr.position = Vector2(0, 24) # baked side spans +16..+32
		face_spr.z_index = -1
		body.add_child(face_spr)
	else:
		# Top face 32x32 - brick / iron grate tile
		var top_spr := Sprite2D.new()
		var top_atlas := AtlasTexture.new()
		top_atlas.atlas = tile_tex
		top_atlas.region = Rect2(64, 128, 32, 32)
		top_spr.texture = top_atlas
		body.add_child(top_spr)

		# South face - 32 wide x 16 tall, darkened, offset to the south edge
		var face_spr := Sprite2D.new()
		var face_atlas := AtlasTexture.new()
		face_atlas.atlas = tile_tex
		# Use lower half of brick tile for side; darkened via modulate
		face_atlas.region = Rect2(64, 144, 32, 16)
		face_spr.texture = face_atlas
		face_spr.position = Vector2(0, 16) # sits directly below top, 16px extrusion
		face_spr.modulate = Color(0.45, 0.38, 0.32, 1.0) # darkened / shaded side
		# Face should render just behind top's bottom edge but above ground
		face_spr.z_index = -1
		body.add_child(face_spr)

	# Collider - 32x32 Rect centered on body (same as original)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	col.shape = shape
	body.add_child(col)

	parent.add_child(body)
	return body

# ----------------------------------------------------------------
# Raised platforms - 2 tiles high (32px) with cliff side on south edge
# Two platforms: overworld plaza and dungeon dais
static func _build_raised_platforms(parent: Node2D, tile_tex: Texture2D) -> void:
	# Platform A: overworld high ground (6x4) near (10,6)
	_create_platform_rect(parent, Rect2i(8, 6, 6, 4), tile_tex, Rect2(0, 96, 32, 32))
	# Platform B: dungeon overlook (8x5) inside dungeon near (35,22)
	_create_platform_rect(parent, Rect2i(35, 22, 8, 5), tile_tex, Rect2(0, 224, 32, 32))

static func _create_platform_rect(parent: Node2D, rect: Rect2i, tile_tex: Texture2D, top_region: Rect2) -> void:
	# Create each tile of the platform top
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			var is_edge_south: bool = (y == rect.position.y + rect.size.y - 1)
			var is_edge_east: bool = (x == rect.position.x + rect.size.x - 1)
			var is_edge_west: bool = (x == rect.position.x)
			var is_edge_north: bool = (y == rect.position.y)
			var pos := Vector2(x * TILE + 16, y * TILE + 16)

			# Platform container for this cell (keeps sprites grouped)
			var cell := Node2D.new()
			cell.position = pos
			cell.add_to_group("ysort")
			cell.add_to_group("platform_25d")

			# Platform visuals: improved floor_height_25d.png art when available
			# (row 1 = extruded grass cliff 32x48, row 3 = extruded dungeon 32x48,
			#  row 0/2 = flat tops). Falls back to shaded base-tileset regions.
			var floor_sheet: Texture2D = load("res://assets/tiles/floor_height_25d.png")
			var grass: bool = top_region == Rect2(0, 96, 32, 32)
			if floor_sheet != null:
				if is_edge_south:
					# One extruded 32x48 slice: top + 16px baked side, uniform with walls.
					var scol: int = x % 4
					var sbase_y: int = 48 if grass else 144
					var edge_spr := Sprite2D.new()
					var edge_atlas := AtlasTexture.new()
					edge_atlas.atlas = floor_sheet
					edge_atlas.region = Rect2(scol * 32, sbase_y, 32, 48)
					edge_spr.texture = edge_atlas
					edge_spr.position = Vector2(0, 8) # top covers tile, side hangs below
					cell.add_child(edge_spr)
				else:
					var fbase_y: int = 0 if grass else 96
					var fcol: int = (x + y) % 6 if grass else (x + y) % 8
					var top_spr := Sprite2D.new()
					var top_atlas := AtlasTexture.new()
					top_atlas.atlas = floor_sheet
					top_atlas.region = Rect2(fcol * 32, fbase_y, 32, 32)
					top_spr.texture = top_atlas
					cell.add_child(top_spr)
				# East/west caps on flat-top perimeter cells (skipped on extruded edge).
				if not is_edge_south and (is_edge_east or is_edge_west):
					var cap := Sprite2D.new()
					var cap_atlas := AtlasTexture.new()
					cap_atlas.atlas = tile_tex
					cap_atlas.region = Rect2(64, 128, 8, 32)
					cap.texture = cap_atlas
					var east: bool = is_edge_east
					cap.position = Vector2(12, 8) if east else Vector2(-12, 8)
					cap.modulate = Color(0.35, 0.30, 0.26, 1.0) if east else Color(0.50, 0.44, 0.38, 1.0)
					cap.z_index = -1
					cell.add_child(cap)
			else:
				# Top surface sprite
				var top_spr := Sprite2D.new()
				var top_atlas := AtlasTexture.new()
				top_atlas.atlas = tile_tex
				top_atlas.region = top_region
				top_spr.texture = top_atlas
				# Slightly brighter on top to sell height
				top_spr.modulate = Color(1.05, 1.05, 1.05, 1.0)
				cell.add_child(top_spr)

				# Cliff faces - south edge always, corners handle east/west
				if is_edge_south:
					var cliff_s := Sprite2D.new()
					var cliff_atlas := AtlasTexture.new()
					cliff_atlas.atlas = tile_tex
					cliff_atlas.region = Rect2(64, 128, 32, 32) # brick side reused
					cliff_s.texture = cliff_atlas
					# Stretch visually to 32px tall south face (2 tiles high)
					cliff_s.position = Vector2(0, 16 + 8) # center of 32px extrusion below tile
					cliff_s.scale = Vector2(1, 1) # keeps 32px; region scale via custom draw would need 32h
					# Instead use region height 32 chopped: show 32px tall face
					cliff_atlas.region = Rect2(64, 128, 32, 32)
					cliff_s.modulate = Color(0.42, 0.36, 0.30, 1.0)
					cliff_s.z_index = -1
					cell.add_child(cliff_s)
				# East/west cliff caps for side readability (narrow vertical strip darkened)
				if is_edge_east and not is_edge_south:
					var cliff_e := Sprite2D.new()
					var cliff_e_atlas := AtlasTexture.new()
					cliff_e_atlas.atlas = tile_tex
					cliff_e_atlas.region = Rect2(64, 128, 8, 32)
					cliff_e.texture = cliff_e_atlas
					cliff_e.position = Vector2(12, 8)
					cliff_e.modulate = Color(0.35, 0.30, 0.26, 1.0)
					cliff_e.z_index = -1
					cell.add_child(cliff_e)
				if is_edge_west and not is_edge_south:
					var cliff_w := Sprite2D.new()
					var cliff_w_atlas := AtlasTexture.new()
					cliff_w_atlas.atlas = tile_tex
					cliff_w_atlas.region = Rect2(64, 128, 8, 32)
					cliff_w.texture = cliff_w_atlas
					cliff_w.position = Vector2(-12, 8)
					cliff_w.modulate = Color(0.50, 0.44, 0.38, 1.0)
					cliff_w.z_index = -1
					cell.add_child(cliff_w)

			parent.add_child(cell)

			# Collision only on perimeter to block stepping off cliff without stairs
			# South edge and outer rim get a blocker; interior is walkable (no collider)
			var is_perimeter: bool = is_edge_south or is_edge_north or is_edge_east or is_edge_west
			# For perimeter south edge, add static blocker at cliff base
			if is_edge_south:
				var blocker := StaticBody2D.new()
				blocker.position = pos + Vector2(0, 16) # at cliff foot
				blocker.add_to_group("ysort")
				var col := CollisionShape2D.new()
				var shape := RectangleShape2D.new()
				shape.size = Vector2(32, 12)
				col.shape = shape
				blocker.add_child(col)
				parent.add_child(blocker)
			elif is_perimeter and (is_edge_east or is_edge_west or is_edge_north):
				# Thin side blockers (optional - keep walkable top but block side entry)
				var side_blocker := StaticBody2D.new()
				side_blocker.position = pos
				side_blocker.add_to_group("ysort")
				var scol := CollisionShape2D.new()
				var sshape := RectangleShape2D.new()
				# North edge blocks from outside; east/west thin
				if is_edge_north:
					sshape.size = Vector2(32, 6)
					scol.position = Vector2(0, -13)
				elif is_edge_east:
					sshape.size = Vector2(6, 32)
					scol.position = Vector2(13, 0)
				else:
					sshape.size = Vector2(6, 32)
					scol.position = Vector2(-13, 0)
				scol.shape = sshape
				side_blocker.add_child(scol)
				parent.add_child(side_blocker)

# ----------------------------------------------------------------
# Stair tiles - connect platform to ground, no collider (walkable ramp)
static func _build_stairs(parent: Node2D, tile_tex: Texture2D) -> void:
	# Stairs for Platform A (south center)
	var stair_a: Array[Vector2i] = [Vector2i(10, 10), Vector2i(11, 10)]
	# Stairs for Platform B (west side)
	var stair_b: Array[Vector2i] = [Vector2i(34, 24), Vector2i(34, 25)]
	for p in stair_a + stair_b:
		create_stair_tile(parent, Vector2(p.x * TILE + 16, p.y * TILE + 16), tile_tex)

static func create_stair_tile(parent: Node2D, pos: Vector2, tile_tex: Texture2D) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	n.add_to_group("stairs_25d")
	# Stair sprite - use plaza tile with slight color shift to read as steps
	var spr := Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = tile_tex
	atlas.region = Rect2(0, 64, 32, 32) # light plaza tile
	spr.texture = atlas
	spr.modulate = Color(0.92, 0.88, 0.80, 1.0)
	n.add_child(spr)
	# Step lines overlay - two darkened thin sprites to suggest steps
	for i in range(2):
		var step := Sprite2D.new()
		var step_atlas := AtlasTexture.new()
		step_atlas.atlas = tile_tex
		step_atlas.region = Rect2(0, 64, 32, 4)
		step.texture = step_atlas
		step.position = Vector2(0, -8 + i * 8)
		step.modulate = Color(0.55, 0.50, 0.44, 1.0)
		n.add_child(step)
	parent.add_child(n)
	return n

# ----------------------------------------------------------------
# Boundary trees - same as world.gd outer ring but with YSort grouping
static func _build_boundary_trees(parent: Node2D, tile_tex: Texture2D) -> void:
	for x in range(MAP_W):
		create_tree_25d(parent, Vector2(x * TILE + 16, 16), tile_tex)
		create_tree_25d(parent, Vector2(x * TILE + 16, (MAP_H - 1) * TILE + 16), tile_tex)
	for y in range(1, MAP_H - 1):
		create_tree_25d(parent, Vector2(16, y * TILE + 16), tile_tex)
		create_tree_25d(parent, Vector2((MAP_W - 1) * TILE + 16, y * TILE + 16), tile_tex)

# Scattered decor - same density as original (12 trees) but with random height variation
static func _build_scattered_decor(parent: Node2D, tile_tex: Texture2D) -> void:
	var tree_positions: Array[Vector2] = [
		Vector2(120, 150), Vector2(180, 220), Vector2(240, 160), Vector2(320, 280),
		Vector2(150, 400), Vector2(280, 460), Vector2(400, 350), Vector2(500, 200),
		Vector2(200, 600), Vector2(350, 720), Vector2(150, 850), Vector2(450, 900)
	]
	for pos in tree_positions:
		var t := create_tree_25d(parent, pos, tile_tex)
		# Height variation: random scale 0.9-1.15 sells 2.5D depth
		var s: float = randf_range(0.9, 1.15)
		if t:
			for child in t.get_children():
				if child is Sprite2D:
					child.scale = Vector2(s, s)
	# Extra height-varied bushes / small trees to match decoration density
	var extra_bushes: Array[Vector2] = [
		Vector2(520, 340), Vector2(620, 180), Vector2(380, 500), Vector2(180, 520),
		Vector2(600, 620), Vector2(250, 920)
	]
	for pos in extra_bushes:
		var b := create_tree_25d(parent, pos, tile_tex)
		if b:
			for child in b.get_children():
				if child is Sprite2D:
					child.scale = Vector2(0.75, 0.75)
					child.modulate = Color(0.95, 1.0, 0.95, 1.0)

# Tree with foot-anchored collision (Circle radius 12, foot at bottom) + YSort
static func create_tree_25d(parent: Node2D, pos: Vector2, tile_tex: Texture2D) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	body.add_to_group("ysort")
	body.add_to_group("decor_25d")

	var spr := Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = tile_tex
	atlas.region = Rect2(128, 32, 32, 32) # canopy / bush tile
	spr.texture = atlas
	# Foot at bottom: sprite visually centered, but collision is at foot
	# Offset sprite slightly up so trunk base aligns with body's position (foot)
	spr.position = Vector2(0, -6)
	body.add_child(spr)

	# Shadow / foot ellipse darkened small sprite at base (visual only, no collision)
	var shadow := Sprite2D.new()
	var shadow_atlas := AtlasTexture.new()
	shadow_atlas.atlas = tile_tex
	shadow_atlas.region = Rect2(128, 32, 32, 8)
	shadow.texture = shadow_atlas
	shadow.position = Vector2(0, 10)
	shadow.modulate = Color(0.30, 0.30, 0.30, 0.55)
	shadow.z_index = -1
	body.add_child(shadow)

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	# Foot-anchored: collider at body's origin (foot level), not sprite center
	col.position = Vector2(0, 4)
	col.shape = shape
	body.add_child(col)

	parent.add_child(body)
	return body

# ----------------------------------------------------------------
# Props: crates and columns with foot-at-bottom collision offsets and YSort
static func _build_props_25d(parent: Node2D, tile_tex: Texture2D) -> void:
	# Crates - scattered in dungeon and near platforms (density ~6)
	var crate_positions: Array[Vector2] = [
		Vector2(900, 620), Vector2(960, 700), Vector2(1100, 640),
		Vector2(420, 320), Vector2(260, 500), Vector2(600, 880)
	]
	for pos in crate_positions:
		create_crate_25d(parent, pos, tile_tex)

	# Columns - overworld plaza and dungeon hall (density ~4)
	var column_positions: Array[Vector2] = [
		Vector2(300, 250), Vector2(340, 250), Vector2(1000, 680), Vector2(1200, 900)
	]
	for pos in column_positions:
		create_column_25d(parent, pos, tile_tex)

# Crate: 32x48 prop art with baked side, collision 18x12 rect at foot
static func create_crate_25d(parent: Node2D, pos: Vector2, tile_tex: Texture2D) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	body.add_to_group("ysort")
	body.add_to_group("props_25d")

	# Improved art: props_25d.png crate cells (row 0, cols 4-7 variants).
	# Crate variant picked from position so neighbours differ.
	var prop_sheet: Texture2D = load("res://assets/tiles/props_25d.png")
	if prop_sheet == null:
		prop_sheet = load("res://assets/sprites/props_25d.png")
	if prop_sheet != null:
		var ccol: int = 4 + (abs(int(pos.x / TILE) + int(pos.y / TILE)) % 4)
		var spr := Sprite2D.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = prop_sheet
		atlas.region = Rect2(ccol * 32, 0, 32, 48)
		spr.texture = atlas
		spr.position = Vector2(0, -8) # 48px art: bottom lands on the foot
		body.add_child(spr)
	else:
		var spr := Sprite2D.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = tile_tex
		# Wooden crate-ish tile - reuse brown/dirty tile; fallback to plaza dark
		atlas.region = Rect2(96, 64, 32, 32)
		# If that region is empty in some tilesets, 32,64 is dirt variant - both read as crate
		spr.texture = atlas
		spr.position = Vector2(0, -8) # lift sprite so foot aligns with body origin
		spr.modulate = Color(1.0, 0.95, 0.88, 1.0)
		body.add_child(spr)

		# South face for crate height (8px)
		var face := Sprite2D.new()
		var face_atlas := AtlasTexture.new()
		face_atlas.atlas = tile_tex
		face_atlas.region = Rect2(96, 88, 32, 8)
		face.texture = face_atlas
		face.position = Vector2(0, 6)
		face.modulate = Color(0.55, 0.45, 0.35, 1.0)
		body.add_child(face)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(18, 12)
	col.shape = shape
	col.position = Vector2(0, 8) # foot at bottom of sprite
	body.add_child(col)

	parent.add_child(body)
	return body

# Column: 32x48 prop art with baked plinth, collision rect 14x10 at foot
static func create_column_25d(parent: Node2D, pos: Vector2, tile_tex: Texture2D) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	body.add_to_group("ysort")
	body.add_to_group("props_25d")

	# Improved art: props_25d.png doric column (row 0, col 2).
	var prop_sheet: Texture2D = load("res://assets/tiles/props_25d.png")
	if prop_sheet == null:
		prop_sheet = load("res://assets/sprites/props_25d.png")
	if prop_sheet != null:
		var spr := Sprite2D.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = prop_sheet
		atlas.region = Rect2(2 * 32, 0, 32, 48)
		spr.texture = atlas
		spr.position = Vector2(0, -8) # 48px art: plinth lands on the foot
		body.add_child(spr)
	else:
		var spr := Sprite2D.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = tile_tex
		# Column / stone pillar tile - use stone tile variant
		atlas.region = Rect2(32, 128, 32, 32)
		spr.texture = atlas
		spr.position = Vector2(0, -10) # taller, so lift more
		body.add_child(spr)

		# Column foot shadow
		var base := Sprite2D.new()
		var base_atlas := AtlasTexture.new()
		base_atlas.atlas = tile_tex
		base_atlas.region = Rect2(32, 152, 32, 8)
		base.texture = base_atlas
		base.position = Vector2(0, 10)
		base.modulate = Color(0.40, 0.40, 0.40, 1.0)
		body.add_child(base)

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(14, 10)
	col.shape = shape
	col.position = Vector2(0, 9) # foot-anchored at bottom center
	body.add_child(col)

	parent.add_child(body)
	return body

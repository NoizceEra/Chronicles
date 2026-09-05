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
# Two rectangular + one L-shaped to showcase inner-corner mitering
static func _build_raised_platforms(parent: Node2D, tile_tex: Texture2D) -> void:
	# Platform A: overworld high ground (6x4) near (8,6) — grass
	_create_platform_rect(parent, Rect2i(8, 6, 6, 4), tile_tex, Rect2(0, 96, 32, 32))
	# Platform B: dungeon overlook (8x5) inside dungeon near (35,22) — stone
	_create_platform_rect(parent, Rect2i(35, 22, 8, 5), tile_tex, Rect2(0, 224, 32, 32))
	# Platform C: L-shaped ridge at (18,14) — demos outer SW/SE + inner NW notch
	# Shape:
	#   ###.
	#   #...
	#   #...
	#   #...
	var cells_l: Array[Vector2i] = []
	for x in range(18, 21): cells_l.append(Vector2i(x, 14))
	for y in range(15, 19): cells_l.append(Vector2i(18, y))
	_create_platform_from_cells(parent, cells_l, tile_tex, Rect2(0, 96, 32, 32), "grass")

# Corner-aware builder: each cell inspects its 4-neighbor mask and picks miters/edges
static func _create_platform_from_cells(parent: Node2D, cells: Array[Vector2i], tile_tex: Texture2D, top_region: Rect2, kind: String) -> void:
	var cell_set: Dictionary = {}
	for c in cells: cell_set[c] = true
	var has: Callable = func(p: Vector2i) -> bool: return cell_set.has(p)
	for c in cells:
		var x: int = c.x
		var y: int = c.y
		var pos := Vector2(x * TILE + 16, y * TILE + 16)
		var has_n: bool = has.call(Vector2i(x, y - 1))
		var has_s: bool = has.call(Vector2i(x, y + 1))
		var has_e: bool = has.call(Vector2i(x + 1, y))
		var has_w: bool = has.call(Vector2i(x - 1, y))
		var has_se: bool = has.call(Vector2i(x + 1, y + 1))
		var has_sw: bool = has.call(Vector2i(x - 1, y + 1))
		var has_ne: bool = has.call(Vector2i(x + 1, y - 1))
		var has_nw: bool = has.call(Vector2i(x - 1, y - 1))
		var cell := Node2D.new()
		cell.position = pos
		cell.add_to_group("ysort")
		cell.add_to_group("platform_25d")
		# Pick corner/edge sprite + its anchor offset, else fall back to per-edge logic.
		# 48x48 corners -> (8,8); 48x32 east edge -> (8,0); west edge -> (-8,0);
		# 32x48 south slice -> (0,8). Each lands its top exactly on the tile.
		var pick: Array = _corner_pick_for_mask(kind, has_n, has_s, has_e, has_w, has_se, has_sw, has_ne, has_nw)
		var corner_tex: Texture2D = pick[0]
		if corner_tex != null:
			var cspr := Sprite2D.new()
			cspr.texture = corner_tex
			cspr.position = pick[1]
			cell.add_child(cspr)
		else:
			# Fall back to legacy per-edge rendering (extruded south / flat + east caps)
			var floor_sheet: Texture2D = load("res://assets/tiles/floor_height_25d.png")
			var grass2: bool = top_region == Rect2(0, 96, 32, 32)
			if floor_sheet != null:
				var is_edge_south2: bool = not has_s
				if is_edge_south2:
					var scol: int = x % 4
					var sbase_y: int = 48 if grass2 else 144
					var edge_spr := Sprite2D.new()
					var edge_atlas := AtlasTexture.new()
					edge_atlas.atlas = floor_sheet
					edge_atlas.region = Rect2(scol * 32, sbase_y, 32, 48)
					edge_spr.texture = edge_atlas
					edge_spr.position = Vector2(0, 8)
					cell.add_child(edge_spr)
				else:
					var fbase_y2: int = 0 if grass2 else 96
					var fcol2: int = (x + y) % 6 if grass2 else (x + y) % 8
					var top_spr2 := Sprite2D.new()
					var top_atlas2 := AtlasTexture.new()
					top_atlas2.atlas = floor_sheet
					top_atlas2.region = Rect2(fcol2 * 32, fbase_y2, 32, 32)
					top_spr2.texture = top_atlas2
					cell.add_child(top_spr2)
					if not has_e or not has_w:
						var cap := Sprite2D.new()
						var cap_atlas := AtlasTexture.new()
						cap_atlas.atlas = tile_tex
						cap_atlas.region = Rect2(64, 128, 8, 32)
						cap.texture = cap_atlas
						var east2: bool = not has_e
						cap.position = Vector2(12, 8) if east2 else Vector2(-12, 8)
						cap.modulate = Color(0.35, 0.30, 0.26, 1.0) if east2 else Color(0.50, 0.44, 0.38, 1.0)
						cap.z_index = -1
						cell.add_child(cap)
			else:
				var top_spr3 := Sprite2D.new()
				var top_atlas3 := AtlasTexture.new()
				top_atlas3.atlas = tile_tex
				top_atlas3.region = top_region
				top_spr3.texture = top_atlas3
				top_spr3.modulate = Color(1.05, 1.05, 1.05, 1.0)
				cell.add_child(top_spr3)
		parent.add_child(cell)
		# Collision at cliff foot / perimeter (same as rect version)
		var is_perim: bool = not has_n or not has_s or not has_e or not has_w
		if not has_s:
			var blocker := StaticBody2D.new()
			blocker.position = pos + Vector2(0, 16)
			blocker.add_to_group("ysort")
			var col := CollisionShape2D.new()
			var shape := RectangleShape2D.new()
			shape.size = Vector2(32, 12)
			col.shape = shape
			blocker.add_child(col)
			parent.add_child(blocker)
		elif is_perim and (not has_e or not has_w or not has_n):
			var side_blocker := StaticBody2D.new()
			side_blocker.position = pos
			side_blocker.add_to_group("ysort")
			var scol2 := CollisionShape2D.new()
			var sshape2 := RectangleShape2D.new()
			if not has_n:
				sshape2.size = Vector2(32, 6)
				scol2.position = Vector2(0, -13)
			elif not has_e:
				sshape2.size = Vector2(6, 32)
				scol2.position = Vector2(13, 0)
			else:
				sshape2.size = Vector2(6, 32)
				scol2.position = Vector2(-13, 0)
			scol2.shape = sshape2
			side_blocker.add_child(scol2)
			parent.add_child(side_blocker)

static func _corner_pick_for_mask(kind: String, has_n: bool, has_s: bool, has_e: bool, has_w: bool, has_se: bool, has_sw: bool, has_ne: bool, has_nw: bool) -> Array:
	# Returns [Texture2D or null, Vector2 anchor]. Priority: inner (concave) before outer (convex).
	# Inner NW: has S && has E && !SE
	if has_s and has_e and not has_se:
		return [_load_tex("cliff_corner_inner_NW_%s_v2" % kind), Vector2(8, 8)]
	if has_s and has_w and not has_sw:
		return [_load_tex("cliff_corner_inner_NE_%s_v2" % kind), Vector2(8, 8)]
	if has_n and has_e and not has_ne:
		return [_load_tex("cliff_corner_inner_SW_%s_v2" % kind), Vector2(8, 8)]
	if has_n and has_w and not has_nw:
		return [_load_tex("cliff_corner_inner_SE_%s_v2" % kind), Vector2(8, 8)]
	# Outer corners (48x48)
	if not has_s and not has_e:
		return [_load_tex("cliff_corner_outer_SE_%s_v2" % kind), Vector2(8, 8)]
	if not has_s and not has_w:
		return [_load_tex("cliff_corner_outer_SW_%s_v2" % kind), Vector2(8, 8)]
	if not has_n and not has_e:
		return [_load_tex("cliff_corner_outer_NE_%s_v2" % kind), Vector2(8, 8)]
	if not has_n and not has_w:
		return [_load_tex("cliff_corner_outer_NW_%s_v2" % kind), Vector2(8, 8)]
	# Straight edges: south 32x48 slice, east/west 48x32 strips
	if not has_s:
		return [_load_tex("cliff_%s_cliff_25d" % kind), Vector2(0, 8)]
	if not has_e:
		return [_load_tex("cliff_edge_e_%s_v2" % kind), Vector2(8, 0)]
	if not has_w:
		return [_load_tex("cliff_edge_w_%s_v2" % kind), Vector2(-8, 0)]
	return [null, Vector2.ZERO]

static func _load_tex(stem: String) -> Texture2D:
	var paths: Array[String] = [
		"res://assets/tiles/25d_v2/%s.png" % stem,
		"res://assets/tiles/25d/%s.png" % stem,
	]
	for p in paths:
		if ResourceLoader.exists(p):
			var t = load(p)
			if t: return t
	return null

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
# Tries to load hand-painted stair tiles from 25d_v2; falls back to plaza-tint if missing
static func _build_stairs(parent: Node2D, tile_tex: Texture2D) -> void:
	# Stairs for Platform A (south center)
	var stair_a: Array[Vector2i] = [Vector2i(10, 10), Vector2i(11, 10)]
	# Stairs for Platform B (west side)
	var stair_b: Array[Vector2i] = [Vector2i(34, 24), Vector2i(34, 25)]
	for p in stair_a:
		_create_stair_tile_south(parent, Vector2(p.x * TILE + 16, p.y * TILE + 16), "grass")
	for p in stair_b:
		_create_stair_tile_east(parent, Vector2(p.x * TILE + 16, p.y * TILE + 16), "stone")

static func _stair_tex(kind: String, dir: String) -> Texture2D:
	var paths: Array[String] = [
		"res://assets/tiles/25d_v2/stair_%s_%s_v2.png" % [dir, kind],
		"res://assets/tiles/25d/stair_%s_%s_v2.png" % [dir, kind],
	]
	for pp in paths:
		if ResourceLoader.exists(pp):
			var t = load(pp)
			if t: return t
	return null

static func _create_stair_tile_south(parent: Node2D, pos: Vector2, kind: String) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	n.add_to_group("stairs_25d")
	var t := _stair_tex(kind, "south")
	if t:
		var spr := Sprite2D.new()
		spr.texture = t
		n.add_child(spr)
	else:
		# fallback: tinted plaza + step lines (legacy)
		var spr := Sprite2D.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = load("res://assets/tiles/tileset.png")
		atlas.region = Rect2(0, 64, 32, 32)
		spr.texture = atlas
		spr.modulate = Color(0.92, 0.88, 0.80, 1.0)
		n.add_child(spr)
		for i in range(2):
			var step := Sprite2D.new()
			var step_atlas := AtlasTexture.new()
			step_atlas.atlas = load("res://assets/tiles/tileset.png")
			step_atlas.region = Rect2(0, 64, 32, 4)
			step.texture = step_atlas
			step.position = Vector2(0, -8 + i * 8)
			step.modulate = Color(0.55, 0.50, 0.44, 1.0)
			n.add_child(step)
	parent.add_child(n)
	return n

static func _create_stair_tile_east(parent: Node2D, pos: Vector2, kind: String) -> Node2D:
	var n := Node2D.new()
	n.position = pos
	n.add_to_group("stairs_25d")
	var t := _stair_tex(kind, "east")
	if t:
		var spr := Sprite2D.new()
		spr.texture = t
		n.add_child(spr)
	else:
		var spr := Sprite2D.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = load("res://assets/tiles/tileset.png")
		atlas.region = Rect2(0, 64, 32, 32)
		spr.texture = atlas
		spr.modulate = Color(0.92, 0.88, 0.80, 1.0)
		n.add_child(spr)
	parent.add_child(n)
	return n

static func create_stair_tile(parent: Node2D, pos: Vector2, tile_tex: Texture2D) -> Node2D:
	# Legacy wrapper — still uses tile_tex atlas but now prefers v2 file
	return _create_stair_tile_south(parent, pos, "grass")

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

	# Stumps + barrels - individual v2 art, foot-anchored colliders
	create_stump_25d(parent, Vector2(600, 420))
	create_stump_25d(parent, Vector2(180, 760))
	create_barrel_25d(parent, Vector2(450, 330))
	create_barrel_25d(parent, Vector2(1000, 560))

	# Bushes - non-colliding decor tufts
	for pos in [Vector2(250, 300), Vector2(550, 450), Vector2(130, 750), Vector2(1150, 800)]:
		create_bush_25d(parent, pos)

# Individual v2 prop files live in sprites/25d_v2/, flat sprites/ name as fallback.
static func _prop_tex(v2_stem: String, flat_name: String) -> Texture2D:
	var paths: Array[String] = [
		"res://assets/sprites/25d_v2/%s.png" % v2_stem,
		"res://assets/sprites/%s.png" % flat_name,
	]
	for p in paths:
		if ResourceLoader.exists(p):
			var t = load(p)
			if t:
				return t
	return null

# Small v2 prop (stump/barrel): individual 32x40 file, foot-anchored collider.
static func _create_small_prop(parent: Node2D, pos: Vector2, v2_stem: String, flat_name: String, col_size: Vector2) -> StaticBody2D:
	var tex: Texture2D = _prop_tex(v2_stem, flat_name)
	if tex == null:
		return null
	var body := StaticBody2D.new()
	body.position = pos
	body.add_to_group("ysort")
	body.add_to_group("props_25d")
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.position = Vector2(0, -6) # 40px art: bottom lands on the foot
	body.add_child(spr)
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = col_size
	col.shape = shape
	col.position = Vector2(0, 8)
	body.add_child(col)
	parent.add_child(body)
	return body

static func create_stump_25d(parent: Node2D, pos: Vector2) -> StaticBody2D:
	return _create_small_prop(parent, pos, "prop_stump_v2", "prop_stump_25d", Vector2(20, 12))

static func create_barrel_25d(parent: Node2D, pos: Vector2) -> StaticBody2D:
	return _create_small_prop(parent, pos, "prop_barrel_v2", "prop_barrel_25d", Vector2(18, 12))

# Bush: non-colliding decor tuft.
static func create_bush_25d(parent: Node2D, pos: Vector2) -> Node2D:
	var tex: Texture2D = _prop_tex("prop_bush_v2", "prop_bush_large_25d")
	if tex == null:
		return null
	var n := Node2D.new()
	n.position = pos
	n.add_to_group("ysort")
	n.add_to_group("decor_25d")
	var spr := Sprite2D.new()
	spr.texture = tex
	n.add_child(spr)
	parent.add_child(n)
	return n

# Crate: 32x48 prop art with baked side, collision 18x12 rect at foot
static func create_crate_25d(parent: Node2D, pos: Vector2, tile_tex: Texture2D) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	body.add_to_group("ysort")
	body.add_to_group("props_25d")

	# Improved art: individual v2 crate files (32x40, baked side); wood/metal
	# picked by position. Falls back to the props atlas, then base tiles.
	var metal: bool = (abs(int(pos.x / TILE) + int(pos.y / TILE)) % 3 == 0)
	var cstem: String = "prop_crate_metal_v2" if metal else "prop_crate_v2"
	var cflat: String = "prop_crate_metal_25d" if metal else "prop_crate_25d"
	var ctex: Texture2D = _prop_tex(cstem, cflat)
	var prop_sheet: Texture2D = null
	if ctex == null:
		prop_sheet = load("res://assets/tiles/props_25d.png")
		if prop_sheet == null:
			prop_sheet = load("res://assets/sprites/props_25d.png")
	if ctex != null:
		var spr := Sprite2D.new()
		spr.texture = ctex
		spr.position = Vector2(0, -6) # 40px art: bottom lands on the foot
		body.add_child(spr)
	elif prop_sheet != null:
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

	# Improved art: individual v2 column file (32x48, baked plinth).
	# Falls back to the props atlas, then shaded base tiles.
	var xtex: Texture2D = _prop_tex("prop_column_v2", "prop_column_25d")
	var prop_sheet: Texture2D = null
	if xtex == null:
		prop_sheet = load("res://assets/tiles/props_25d.png")
		if prop_sheet == null:
			prop_sheet = load("res://assets/sprites/props_25d.png")
	if xtex != null:
		var spr := Sprite2D.new()
		spr.texture = xtex
		spr.position = Vector2(0, -8) # 48px art: plinth lands on the foot
		body.add_child(spr)
	elif prop_sheet != null:
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

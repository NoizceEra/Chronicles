# npc.gd
# Chronicles of Midgard - Scene-instantiable NPC node.
# Extends CharacterBody2D so wandering NPCs can use move_and_slide().
# Non-wandering NPCs (wanders=false) stay put; collision body is still useful for physics pushout.
# Signals feed into whatever UI system is active (dialogue_requested, shop_requested).
class_name NPC
extends CharacterBody2D

signal dialogue_requested(npc_id: String, dialogue_lines: Array)
signal shop_requested(npc_id: String, inventory_items: Array)
signal quest_board_requested(npc_id: String, available_quests: Array)

# ── Exported configuration ────────────────────────────────────────────────────
@export var npc_id: String = "merchant_doran"
@export var wander_speed: float = 28.0
@export var interaction_radius: float = 48.0

# ── Internal state ────────────────────────────────────────────────────────────
enum NPCState { IDLE, WANDER, TALKING }
var _state: NPCState = NPCState.IDLE
var _state_timer: float = 0.0
var _wander_dir: Vector2 = Vector2.ZERO
var _npc_data: Dictionary = {}
var _dialogue_index: int = 0
var _is_wander_npc: bool = false

# Cached child refs — created in _ready so no .tscn is required.
var _anim: AnimatedSprite2D = null
var _interact_area: Area2D = null

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("npcs")
	_load_npc_data()
	_build_collision()
	_build_sprite()
	_build_interaction_area()
	_state_timer = randf_range(1.5, 4.0)

func _load_npc_data() -> void:
	_npc_data = NPCDatabase.get_npc(npc_id)
	if _npc_data.is_empty():
		push_error("NPC: unknown npc_id '%s'. Check NPCDatabase." % npc_id)
		return
	_is_wander_npc = _npc_data.get("wanders", false)

func _build_collision() -> void:
	var col := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 10.0
	shape.height = 20.0
	col.shape = shape
	add_child(col)

func _build_sprite() -> void:
	_anim = AnimatedSprite2D.new()
	var sprite_hint: String = _npc_data.get("sprite_hint", "")
	if sprite_hint != "":
		var res = load(sprite_hint)
		if res:
			_anim.sprite_frames = res
			_anim.play("idle_down")
	add_child(_anim)

func _build_interaction_area() -> void:
	_interact_area = Area2D.new()
	var col_shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = interaction_radius
	col_shape.shape = circle
	_interact_area.add_child(col_shape)
	_interact_area.collision_layer = 0
	_interact_area.collision_mask = 1  # Layer 1: player bodies
	_interact_area.body_entered.connect(_on_player_in_range)
	_interact_area.body_exited.connect(_on_player_left_range)
	add_child(_interact_area)

# ── Physics process (wander only) ─────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if not _is_wander_npc or _state == NPCState.TALKING:
		velocity = Vector2.ZERO
		return

	_state_timer -= delta

	match _state:
		NPCState.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, wander_speed * delta * 6.0)
			if _state_timer <= 0.0:
				_state = NPCState.WANDER
				_wander_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
				_state_timer = randf_range(2.0, 4.5)

		NPCState.WANDER:
			velocity = _wander_dir * wander_speed
			if _state_timer <= 0.0:
				_state = NPCState.IDLE
				_state_timer = randf_range(2.0, 5.0)

	move_and_slide()
	_update_animation()

func _update_animation() -> void:
	if _anim == null:
		return
	if not _anim.sprite_frames:
		return

	var dir_str := "down"
	if abs(velocity.x) > abs(velocity.y):
		dir_str = "right" if velocity.x > 0 else "left"
	elif velocity.y < 0:
		dir_str = "up"

	var anim_name: String
	if velocity.length() > 5.0:
		anim_name = "walk_" + dir_str
	else:
		anim_name = "idle_" + dir_str

	if _anim.sprite_frames.has_animation(anim_name) and _anim.animation != anim_name:
		_anim.play(anim_name)

# ── Interaction ───────────────────────────────────────────────────────────────

# Primary entry point. Call from player.gd when the player presses the interact key
# while this NPC is the closest one in range (use get_nearby_npc() helper below).
func interact(player: Node) -> void:
	if _npc_data.is_empty():
		return

	# Pause wander briefly while talking
	_state = NPCState.TALKING
	_state_timer = 5.0
	get_tree().create_timer(5.0).timeout.connect(func():
		if _state == NPCState.TALKING:
			_state = NPCState.IDLE
			_state_timer = randf_range(2.0, 4.0)
	)

	# Rotate to face the player
	_face_toward(player.global_position)

	# Emit dialogue signal — the UI system connects to this
	var lines: Array = _npc_data.get("dialogue", [])
	if not lines.is_empty():
		var line_to_show: Array = [lines[_dialogue_index % lines.size()]]
		_dialogue_index += 1
		emit_signal("dialogue_requested", npc_id, line_to_show)

	# Emit shop signal if this NPC has a shop
	var inventory: Array = _npc_data.get("shop_inventory", [])
	if not inventory.is_empty():
		emit_signal("shop_requested", npc_id, inventory)

	# Emit quest board signal if the player has a quest_log and there are quests
	if player.has_node("QuestLog"):
		var quest_log: QuestLog = player.get_node("QuestLog")
		var available: Array = quest_log.get_available_from_npc(npc_id)
		if not available.is_empty():
			emit_signal("quest_board_requested", npc_id, available)

# ── Range callbacks ───────────────────────────────────────────────────────────

func _on_player_in_range(body: Node2D) -> void:
	# Optionally face the approaching player; UI can show an interact prompt.
	if body.is_in_group("player"):
		_face_toward(body.global_position)

func _on_player_left_range(_body: Node2D) -> void:
	pass  # UI layer handles hiding the interact prompt.

# ── Helpers ───────────────────────────────────────────────────────────────────

func _face_toward(target_pos: Vector2) -> void:
	if _anim == null or not _anim.sprite_frames:
		return
	var delta_pos: Vector2 = target_pos - global_position
	var dir_str := "down"
	if abs(delta_pos.x) > abs(delta_pos.y):
		dir_str = "right" if delta_pos.x > 0 else "left"
	elif delta_pos.y < 0:
		dir_str = "up"
	var idle_anim := "idle_" + dir_str
	if _anim.sprite_frames.has_animation(idle_anim):
		_anim.play(idle_anim)

func get_npc_name() -> String:
	return _npc_data.get("name", "NPC")

func get_role() -> String:
	return _npc_data.get("role", "")

# Convenience: returns the nearest NPC in range from the player's perspective.
# Call from player.gd: var npc = NPC.get_nearest_npc(self, 64.0)
static func get_nearest_npc(from_node: Node2D, radius: float = 64.0) -> NPC:
	var closest: NPC = null
	var closest_dist := radius * radius  # compare squared distances
	for npc_node in from_node.get_tree().get_nodes_in_group("npcs"):
		if not npc_node is NPC:
			continue
		var d := from_node.global_position.distance_squared_to(npc_node.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = npc_node
	return closest

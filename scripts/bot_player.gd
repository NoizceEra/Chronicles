# bot_player.gd
# Chronicles of Midgard - Lightweight decorative bot-player crowd member.
# Target: 10-20 instances running fine at 60 fps alongside real networked players.
# AI ticks ONLY when is_authority == true (server-side). Client instances are purely
# visual — they receive position updates from the server via MultiplayerSynchronizer.
# Call setup(is_authority, town_bounds, field_bounds) before adding to the scene tree
# or immediately after.
class_name BotPlayer
extends CharacterBody2D

# Fired on the server; world.gd (or a label overlay) connects this to display speech bubbles.
signal chat_said(bot_name: String, message: String)

# ── Name / personality pools (adapted from mmo_engine.gd) ────────────────────
const FIRST_NAMES: Array[String] = [
	"Valkyrie", "Shadow", "Grand", "Loki", "Saint", "Sniper", "Katar",
	"Frost", "Arcane", "Elven", "Crimson", "Silver", "Rune", "Mystic",
	"Diana", "Zero", "Nova", "Vesper", "Chrono", "Aegis", "Freya", "Thor",
	"Gwen", "Sora", "Riven", "Cael", "Mira", "Solus", "Wren", "Dune",
]

const LAST_NAMES: Array[String] = [
	"Rose", "Striker", "Templar", "Dagger", "Maiden", "Wolf", "Master",
	"Mage", "Sage", "Blade", "Marksman", "Knight", "Healer", "Hunter",
	"Cross", "Bane", "Storm", "Gale", "Soul", "Fang", "Seeker", "Shield",
	"Falcon", "Vex", "Orin", "Crest", "Drift", "Peak", "Ash", "Blaze",
]

const CHAT_TOWN: Array[String] = [
	"Need Priest for dungeon run!",
	"Buying Oridecon, PM me!",
	"Anyone selling slime gel?",
	"AFK vending here ^^",
	"/sit enjoying the fountain~",
	"Guild recruiting active players!",
	"Selling +7 Iron Sword - cheap!",
	"Where does the MVP spawn?",
	"Back from grinding, need potions.",
	"First time in Midgard, amazing!",
]

const CHAT_FIELD: Array[String] = [
	"Tank pull more mobs, I have AOE!",
	"Level up! Putting points into DEX.",
	"Storm Gust incoming, watch out!",
	"Out of blue potions...",
	"Sonic Blow burst is insane!",
	"These goblins are relentless!",
	"Anyone need a party?",
	"Almost at the next level!",
]

# ── State machine ─────────────────────────────────────────────────────────────
enum BotState {
	IDLE_TOWN,   # Standing in town, occasionally chatting
	WANDER_TOWN, # Strolling around the town area
	MOVE_TO_FIELD, # Heading out to the field region
	FIELD_GRIND,  # Cosmetically "fighting" near a random enemy node
	RETURN_TOWN,  # Heading back to town
}

# ── Public identity ───────────────────────────────────────────────────────────
var bot_name: String = ""
var bot_class_id: String = "knight"
var bot_level: int = 1

# ── Authority flag ────────────────────────────────────────────────────────────
var _is_authority: bool = false

# ── Spatial bounds ────────────────────────────────────────────────────────────
# Rect2 bounding boxes for town and field regions (world coordinates).
# Passed in via setup(); bots wander within these.
var _town_bounds: Rect2 = Rect2(-256, -256, 512, 512)
var _field_bounds: Rect2 = Rect2(256, -512, 1024, 1024)

# ── AI internals ──────────────────────────────────────────────────────────────
var _state: BotState = BotState.IDLE_TOWN
var _state_timer: float = 0.0
var _move_target: Vector2 = Vector2.ZERO
var _move_speed: float = 65.0

# Chat cooldown prevents bots from spamming messages.
var _chat_timer: float = 0.0
const CHAT_COOLDOWN_MIN: float = 8.0
const CHAT_COOLDOWN_MAX: float = 25.0

# Cosmetic "combat" — reference to a nearby enemy node; null if not in range.
var _combat_target: Node2D = null
var _combat_anim_timer: float = 0.0

# Cached sprite child (created in _ready).
var _anim: AnimatedSprite2D = null

# ── Setup ─────────────────────────────────────────────────────────────────────

# Call this before or immediately after adding to the tree.
# is_authority: true on the server instance; false on client mirror nodes.
func setup(
	is_authority: bool,
	p_town_bounds: Rect2 = Rect2(-256, -256, 512, 512),
	p_field_bounds: Rect2 = Rect2(256, -512, 1024, 1024)
) -> void:
	_is_authority = is_authority
	_town_bounds = p_town_bounds
	_field_bounds = p_field_bounds

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("bot_players")
	_assign_identity()
	_build_collision()
	_build_sprite()

	if _is_authority:
		# Randomise initial state so bots don't all act at the same moment.
		_state = BotState.IDLE_TOWN if randf() < 0.6 else BotState.WANDER_TOWN
		_state_timer = randf_range(2.0, 8.0)
		_chat_timer = randf_range(CHAT_COOLDOWN_MIN, CHAT_COOLDOWN_MAX)
		global_position = _random_point_in(_town_bounds)

func _assign_identity() -> void:
	var class_keys: Array = StatEngine.CLASS_PROFILES.keys()
	bot_class_id = class_keys[randi() % class_keys.size()]
	bot_name = FIRST_NAMES[randi() % FIRST_NAMES.size()] + " " + LAST_NAMES[randi() % LAST_NAMES.size()]
	bot_level = randi_range(5, 60)
	_move_speed = 55.0 + randf_range(-10.0, 20.0)

func _build_collision() -> void:
	var col := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 8.0
	shape.height = 16.0
	col.shape = shape
	add_child(col)

func _build_sprite() -> void:
	_anim = AnimatedSprite2D.new()
	# Sprite frames will be wired by world.gd at spawn time if available.
	# Bot shows a plain coloured rect if no frames are set — acceptable for crowd filler.
	add_child(_anim)

# ── Physics process ────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	# Client-side instances: do nothing — MultiplayerSynchronizer drives position.
	if not _is_authority:
		_update_animation()
		return

	_state_timer -= delta
	_chat_timer -= delta

	match _state:
		BotState.IDLE_TOWN:
			velocity = velocity.move_toward(Vector2.ZERO, _move_speed * delta * 6.0)
			_try_chat(CHAT_TOWN)
			if _state_timer <= 0.0:
				# 40% chance to start wandering; 30% chance to head to field; 30% stay idle.
				var roll := randf()
				if roll < 0.4:
					_begin_wander_town()
				elif roll < 0.7:
					_begin_move_to_field()
				else:
					_state_timer = randf_range(3.0, 8.0)

		BotState.WANDER_TOWN:
			_move_toward_target(delta)
			if _state_timer <= 0.0 or global_position.distance_to(_move_target) < 12.0:
				_state = BotState.IDLE_TOWN
				_state_timer = randf_range(2.0, 6.0)

		BotState.MOVE_TO_FIELD:
			_move_toward_target(delta)
			if global_position.distance_to(_move_target) < 24.0:
				_state = BotState.FIELD_GRIND
				_state_timer = randf_range(20.0, 60.0)
				_find_combat_target()

		BotState.FIELD_GRIND:
			_do_field_grind(delta)
			_try_chat(CHAT_FIELD)
			if _state_timer <= 0.0:
				_state = BotState.RETURN_TOWN
				_move_target = _random_point_in(_town_bounds)
				_combat_target = null

		BotState.RETURN_TOWN:
			_move_toward_target(delta)
			if global_position.distance_to(_move_target) < 32.0:
				_state = BotState.IDLE_TOWN
				_state_timer = randf_range(5.0, 12.0)

	move_and_slide()
	_update_animation()

# ── State helpers ─────────────────────────────────────────────────────────────

func _begin_wander_town() -> void:
	_state = BotState.WANDER_TOWN
	_move_target = _random_point_in(_town_bounds)
	_state_timer = randf_range(4.0, 10.0)

func _begin_move_to_field() -> void:
	_state = BotState.MOVE_TO_FIELD
	_move_target = _random_point_in(_field_bounds)

func _move_toward_target(delta: float) -> void:
	var to_target: Vector2 = _move_target - global_position
	if to_target.length() > 8.0:
		velocity = to_target.normalized() * _move_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, _move_speed * delta * 8.0)

func _do_field_grind(delta: float) -> void:
	# If we have a valid combat target, orbit it cosmetically.
	if _combat_target and is_instance_valid(_combat_target):
		var to_enemy: Vector2 = _combat_target.global_position - global_position
		var dist := to_enemy.length()
		if dist > 40.0:
			velocity = to_enemy.normalized() * _move_speed
		elif dist > 20.0:
			# Circle strafe
			var perp := Vector2(-to_enemy.normalized().y, to_enemy.normalized().x)
			velocity = perp * (_move_speed * 0.6)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, _move_speed * delta * 5.0)

		# Cosmetic combat anim swap
		_combat_anim_timer -= delta
		if _combat_anim_timer <= 0.0:
			_combat_anim_timer = randf_range(1.0, 2.5)
			# If anim has an "action" clip, flash it briefly (cosmetic only).
			if _anim and _anim.sprite_frames and _anim.sprite_frames.has_animation("action"):
				_anim.play("action")
				get_tree().create_timer(0.3).timeout.connect(func():
					_update_animation()
				)
	else:
		# No valid target; wander within field bounds until one is found.
		_find_combat_target()
		var to_target := _random_point_in(_field_bounds) - global_position
		velocity = to_target.normalized() * (_move_speed * 0.5)

func _find_combat_target() -> void:
	_combat_target = null
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return
	# Pick a random nearby enemy in the field bounds.
	enemies.shuffle()
	for enemy in enemies:
		if is_instance_valid(enemy) and _field_bounds.has_point(enemy.global_position):
			_combat_target = enemy
			break

func _try_chat(pool: Array[String]) -> void:
	if _chat_timer > 0.0 or pool.is_empty():
		return
	_chat_timer = randf_range(CHAT_COOLDOWN_MIN, CHAT_COOLDOWN_MAX)
	emit_signal("chat_said", bot_name, pool[randi() % pool.size()])

# ── Animation ─────────────────────────────────────────────────────────────────

func _update_animation() -> void:
	if _anim == null or not _anim.sprite_frames:
		return

	var dir_str := "down"
	if abs(velocity.x) > abs(velocity.y):
		dir_str = "right" if velocity.x > 0 else "left"
	elif velocity.y < 0:
		dir_str = "up"

	var anim_name: String
	if velocity.length() > 8.0:
		anim_name = "walk_" + dir_str
	else:
		anim_name = "idle_" + dir_str

	if _anim.sprite_frames.has_animation(anim_name) and _anim.animation != anim_name:
		_anim.play(anim_name)

# ── Utility ───────────────────────────────────────────────────────────────────

func _random_point_in(bounds: Rect2) -> Vector2:
	return Vector2(
		randf_range(bounds.position.x, bounds.position.x + bounds.size.x),
		randf_range(bounds.position.y, bounds.position.y + bounds.size.y)
	)

# Called by server networking layer to push new authoritative state to clients.
# (No-op here; MultiplayerSynchronizer handles it — this is a hook for manual integration.)
func receive_server_state(pos: Vector2, vel: Vector2) -> void:
	if not _is_authority:
		global_position = global_position.lerp(pos, 0.15)
		velocity = vel

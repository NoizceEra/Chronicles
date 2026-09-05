# player.gd
extends CharacterBody2D

const Shadow25D = preload("res://scripts/shadow_system_25d.gd")

signal stats_changed(hp, max_hp, mp, max_mp, hero_idx, gold, level, xp)
signal player_died

const HERO_DATA = [
	{
		"name": "Knight",
		"title": "Paladin",
		"speed": 110.0,
		"max_hp": 150,
		"max_mp": 50,
		"defense": 8,
		"attack_dmg": 35,
		"attack_type": "melee",
		"frames_path": "res://assets/sprites/knight_frames.tres",
		"icon": "res://assets/sprites/knight.png"
	},
	{
		"name": "Mage",
		"title": "Arch-Wizard",
		"speed": 95.0,
		"max_hp": 80,
		"max_mp": 160,
		"defense": 2,
		"attack_dmg": 45,
		"attack_type": "fireball",
		"frames_path": "res://assets/sprites/mage_frames.tres",
		"icon": "res://assets/sprites/mage.png"
	},
	{
		"name": "Rogue",
		"title": "Shadow Blade",
		"speed": 140.0,
		"max_hp": 100,
		"max_mp": 70,
		"defense": 4,
		"attack_dmg": 28,
		"attack_type": "dagger_dash",
		"frames_path": "res://assets/sprites/rogue_frames.tres",
		"icon": "res://assets/sprites/rogue.png"
	},
	{
		"name": "Cleric",
		"title": "High Priest",
		"speed": 100.0,
		"max_hp": 120,
		"max_mp": 130,
		"defense": 5,
		"attack_dmg": 25,
		"attack_type": "holy_burst",
		"frames_path": "res://assets/sprites/cleric_frames.tres",
		"icon": "res://assets/sprites/cleric.png"
	}
]

var current_hero_idx: int = 0
var hp: int = 150
var max_hp: int = 150
var mp: int = 50
var max_mp: int = 50
var gold: int = 0
var level: int = 1
var xp: int = 0
var xp_needed: int = 100

var facing_dir: Vector2 = Vector2.DOWN
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var invulnerable_timer: float = 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var slash_area: Area2D = $SlashArea
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	add_to_group("player")
	Shadow25D.attach_to(self)
	set_hero(0)
	emit_stats()

func set_hero(idx: int) -> void:
	current_hero_idx = idx % HERO_DATA.size()
	var hero = HERO_DATA[current_hero_idx]
	var old_max_hp = max_hp
	max_hp = hero["max_hp"] + (level - 1) * 15
	max_mp = hero["max_mp"] + (level - 1) * 10
	
	# Scale current HP / MP proportionally
	if old_max_hp > 0:
		hp = int(float(hp) / old_max_hp * max_hp)
	else:
		hp = max_hp
	hp = clampi(hp, 1, max_hp)
	mp = clampi(mp, 0, max_mp)
	
	var frames_res = load(hero["frames_path"])
	if frames_res:
		anim.sprite_frames = frames_res
	anim.play("idle_down")
	emit_stats()

func _physics_process(delta: float) -> void:
	if hp <= 0:
		return

	if attack_cooldown > 0:
		attack_cooldown -= delta
	if invulnerable_timer > 0:
		invulnerable_timer -= delta
		anim.modulate.a = 0.5 if fmod(invulnerable_timer * 10.0, 1.0) > 0.5 else 1.0
	else:
		anim.modulate.a = 1.0

	# Input Direction
	var input_vec = Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_vec.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_vec.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_vec.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_vec.y += 1

	input_vec = input_vec.normalized()
	
	if input_vec != Vector2.ZERO:
		facing_dir = input_vec
		var hero = HERO_DATA[current_hero_idx]
		velocity = input_vec * hero["speed"]
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# Animation Handling
	if not is_attacking:
		var dir_str = get_dir_string(facing_dir)
		if velocity.length() > 5.0:
			anim.play("walk_" + dir_str)
		else:
			anim.play("idle_" + dir_str)

	# Combat Inputs
	if Input.is_action_just_pressed("ui_attack") or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_J):
		execute_attack()

	# Hero Switching (1, 2, 3, 4, or TAB)
	if Input.is_key_pressed(KEY_1):
		set_hero(0)
	elif Input.is_key_pressed(KEY_2):
		set_hero(1)
	elif Input.is_key_pressed(KEY_3):
		set_hero(2)
	elif Input.is_key_pressed(KEY_4):
		set_hero(3)
	elif Input.is_action_just_pressed("ui_switch") or Input.is_key_pressed(KEY_TAB):
		set_hero((current_hero_idx + 1) % HERO_DATA.size())

	# MP Regen over time
	if mp < max_mp:
		mp = clampi(mp + int(5 * delta), 0, max_mp)
		emit_stats()

func get_dir_string(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	return "down" if dir.y >= 0 else "up"

func execute_attack() -> void:
	if attack_cooldown > 0:
		return

	var hero = HERO_DATA[current_hero_idx]
	is_attacking = true
	attack_cooldown = 0.35
	anim.play("action")

	match hero["attack_type"]:
		"melee":
			# Knight Sword Slash
			perform_melee_slash(hero["attack_dmg"], 40.0)
		"fireball":
			# Mage Fireball Spell
			if mp >= 15:
				mp -= 15
				spawn_projectile("fireball", hero["attack_dmg"], 220.0)
			else:
				perform_melee_slash(12, 30.0) # Weak staff smack if out of MP
		"dagger_dash":
			# Rogue Dash Slash
			velocity += facing_dir * 180.0
			perform_melee_slash(hero["attack_dmg"], 35.0)
		"holy_burst":
			# Cleric Radiant Burst + Minor Self Heal
			if mp >= 20:
				mp -= 20
				heal(20)
				perform_radial_burst(hero["attack_dmg"], 75.0)
			else:
				perform_melee_slash(hero["attack_dmg"], 30.0)

	emit_stats()
	get_tree().create_timer(0.2).timeout.connect(func(): is_attacking = false)

func perform_melee_slash(damage: int, range_px: float) -> void:
	var hit_pos = global_position + facing_dir * range_px
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			var dist = enemy.global_position.distance_to(hit_pos)
			if dist < 32.0 or enemy.global_position.distance_to(global_position) < range_px:
				enemy.take_damage(damage, (enemy.global_position - global_position).normalized())

func spawn_projectile(type: String, damage: int, speed: float) -> void:
	var proj_script = load("res://scripts/projectile.gd")
	var proj = Area2D.new()
	proj.set_script(proj_script)
	proj.global_position = global_position + facing_dir * 16.0
	proj.init(type, facing_dir, damage, speed, true)
	get_parent().add_child(proj)

func perform_radial_burst(damage: int, radius: float) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			if enemy.global_position.distance_to(global_position) <= radius:
				enemy.take_damage(damage, (enemy.global_position - global_position).normalized())

func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> void:
	if invulnerable_timer > 0 or hp <= 0:
		return

	var hero = HERO_DATA[current_hero_idx]
	var actual_dmg = maxi(1, amount - hero["defense"])
	hp = clampi(hp - actual_dmg, 0, max_hp)
	invulnerable_timer = 0.6
	velocity += knockback_dir * 120.0
	spawn_damage_text(actual_dmg, Color(0.95, 0.2, 0.2))
	emit_stats()

	if hp <= 0:
		player_died.emit()
		anim.modulate = Color(0.6, 0.2, 0.2, 0.8)

func heal(amount: int) -> void:
	hp = clampi(hp + amount, 0, max_hp)
	spawn_damage_text(amount, Color(0.2, 0.95, 0.3), "+")
	emit_stats()

func restore_mp(amount: int) -> void:
	mp = clampi(mp + amount, 0, max_mp)
	spawn_damage_text(amount, Color(0.2, 0.6, 1.0), "+MP ")
	emit_stats()

func add_gold(amount: int) -> void:
	gold += amount
	spawn_damage_text(amount, Color(1.0, 0.85, 0.1), "+G ")
	emit_stats()

func add_xp(amount: int) -> void:
	xp += amount
	if xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = int(xp_needed * 1.5)
		max_hp += 20
		max_mp += 15
		hp = max_hp
		mp = max_mp
		spawn_damage_text(level, Color(1.0, 0.9, 0.2), "LEVEL UP! Lv.")
	emit_stats()

func spawn_damage_text(val: int, col: Color, prefix: String = "") -> void:
	var dmg_script = load("res://scripts/damage_number.gd")
	var lbl = Node2D.new()
	lbl.set_script(dmg_script)
	lbl.global_position = global_position + Vector2(randf_range(-10, 10), -20)
	lbl.setup(prefix + str(val), col)
	get_parent().add_child(lbl)

func emit_stats() -> void:
	stats_changed.emit(hp, max_hp, mp, max_mp, current_hero_idx, gold, level, xp)

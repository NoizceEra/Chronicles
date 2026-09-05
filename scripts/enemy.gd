# enemy.gd
extends CharacterBody2D

enum State { IDLE, WANDER, CHASE, ATTACK, HURT, DEAD }

@export var enemy_type: String = "slime_green"
@export var max_hp: int = 40
@export var damage: int = 15
@export var speed: float = 45.0
@export var aggro_range: float = 140.0
@export var attack_range: float = 24.0
@export var xp_reward: int = 25
@export var gold_reward: int = 10

var hp: int = 40
var state: State = State.IDLE
var target_player: CharacterBody2D = null
var wander_dir: Vector2 = Vector2.ZERO
var state_timer: float = 0.0
var attack_cooldown: float = 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	load_type_settings()
	state_timer = randf_range(1.0, 3.0)

func load_type_settings() -> void:
	match enemy_type:
		"slime_green":
			max_hp = 35
			damage = 10
			speed = 40.0
			xp_reward = 20
			gold_reward = 5
			setup_frames("res://assets/sprites/slime_green_frames.tres")
		"slime_blue":
			max_hp = 50
			damage = 14
			speed = 48.0
			xp_reward = 30
			gold_reward = 12
			setup_frames("res://assets/sprites/slime_blue_frames.tres")
		"slime_red":
			max_hp = 70
			damage = 20
			speed = 55.0
			xp_reward = 45
			gold_reward = 20
			setup_frames("res://assets/sprites/slime_red_frames.tres")
		"goblin":
			max_hp = 60
			damage = 18
			speed = 65.0
			xp_reward = 40
			gold_reward = 25
			setup_frames("res://assets/sprites/goblin_frames.tres")
		"skeleton":
			max_hp = 85
			damage = 24
			speed = 50.0
			xp_reward = 55
			gold_reward = 35
			setup_frames("res://assets/sprites/skeleton_frames.tres")
	hp = max_hp

func setup_frames(path: String) -> void:
	var res = load(path)
	if res and anim:
		anim.sprite_frames = res
		anim.play("idle_down")

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if attack_cooldown > 0:
		attack_cooldown -= delta

	find_player()

	match state:
		State.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 5.0)
			state_timer -= delta
			if state_timer <= 0:
				state = State.WANDER
				wander_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				state_timer = randf_range(1.5, 3.5)
			if target_player and is_player_in_range(aggro_range):
				state = State.CHASE

		State.WANDER:
			velocity = wander_dir * (speed * 0.5)
			state_timer -= delta
			if state_timer <= 0:
				state = State.IDLE
				state_timer = randf_range(1.0, 2.5)
			if target_player and is_player_in_range(aggro_range):
				state = State.CHASE

		State.CHASE:
			if target_player:
				var to_player = (target_player.global_position - global_position)
				var dist = to_player.length()
				if dist <= attack_range and attack_cooldown <= 0:
					state = State.ATTACK
					attack_player()
				elif dist > aggro_range * 1.5:
					state = State.IDLE
					state_timer = 2.0
				else:
					velocity = to_player.normalized() * speed
			else:
				state = State.IDLE

		State.ATTACK:
			velocity = Vector2.ZERO
			# Returns to chase after brief pause

		State.HURT:
			velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 8.0)

	move_and_slide()
	update_animation()

func find_player() -> void:
	if not target_player or not is_instance_valid(target_player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0]

func is_player_in_range(r: float) -> bool:
	if target_player and is_instance_valid(target_player):
		return global_position.distance_to(target_player.global_position) <= r
	return false

func attack_player() -> void:
	attack_cooldown = 1.0
	if anim.sprite_frames.has_animation("action"):
		anim.play("action")
	if target_player and is_instance_valid(target_player) and target_player.has_method("take_damage"):
		var knock_dir = (target_player.global_position - global_position).normalized()
		target_player.take_damage(damage, knock_dir)
	
	get_tree().create_timer(0.4).timeout.connect(func():
		if state != State.DEAD:
			state = State.CHASE
	)

func take_damage(amount: int, knock_dir: Vector2 = Vector2.ZERO) -> void:
	if state == State.DEAD:
		return
	
	hp -= amount
	state = State.HURT
	velocity = knock_dir * 140.0
	spawn_damage_text(amount, Color(1.0, 0.9, 0.2))

	# Red flash
	anim.modulate = Color(1.5, 0.3, 0.3, 1.0)
	get_tree().create_timer(0.15).timeout.connect(func():
		if state != State.DEAD:
			anim.modulate = Color(1, 1, 1, 1)
			state = State.CHASE
	)

	if hp <= 0:
		die()

func die() -> void:
	state = State.DEAD
	collision_layer = 0
	collision_mask = 0
	anim.modulate = Color(0.4, 0.4, 0.4, 0.6)
	
	# Reward player
	if target_player and is_instance_valid(target_player):
		if target_player.has_method("add_xp"):
			target_player.add_xp(xp_reward)
		if target_player.has_method("add_gold"):
			target_player.add_gold(gold_reward)
	
	# Chance to drop potion
	if randf() < 0.4:
		spawn_loot_drop()

	get_tree().create_timer(0.6).timeout.connect(queue_free)

func spawn_loot_drop() -> void:
	var pickup_script = load("res://scripts/pickup.gd")
	var pickup = Area2D.new()
	pickup.set_script(pickup_script)
	pickup.global_position = global_position
	var is_hp = randf() < 0.6
	pickup.setup("health" if is_hp else "mana", 30)
	get_parent().add_child(pickup)

func spawn_damage_text(val: int, col: Color) -> void:
	var dmg_script = load("res://scripts/damage_number.gd")
	var lbl = Node2D.new()
	lbl.set_script(dmg_script)
	lbl.global_position = global_position + Vector2(randf_range(-6, 6), -16)
	lbl.setup(str(val), col)
	get_parent().add_child(lbl)

func update_animation() -> void:
	if not anim or state == State.DEAD or state == State.ATTACK:
		return
	var dir_str = "down"
	if abs(velocity.x) > abs(velocity.y):
		dir_str = "right" if velocity.x > 0 else "left"
	elif velocity.y != 0:
		dir_str = "down" if velocity.y > 0 else "up"

	if velocity.length() > 5.0:
		anim.play("walk_" + dir_str)
	else:
		anim.play("idle_" + dir_str)

# projectile.gd
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 200.0
var damage: int = 20
var is_player_projectile: bool = true
var lifetime: float = 2.5

var sprite: Sprite2D

func init(type: String, dir: Vector2, dmg: int, spd: float, from_player: bool = true) -> void:
	direction = dir.normalized()
	speed = spd
	damage = dmg
	is_player_projectile = from_player

	sprite = Sprite2D.new()
	var tex_path = "res://assets/sprites/projectile_fireball.png" if type == "fireball" else "res://assets/sprites/projectile_holy.png"
	var tex = load(tex_path)
	if tex:
		sprite.texture = tex
	add_child(sprite)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	col.shape = shape
	add_child(col)

	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if is_player_projectile:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(damage, direction)
			queue_free()
		elif not body.is_in_group("player") and body is TileMapLayer or body is StaticBody2D:
			queue_free()
	else:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(damage, direction)
			queue_free()

func _on_area_entered(_area: Area2D) -> void:
	pass

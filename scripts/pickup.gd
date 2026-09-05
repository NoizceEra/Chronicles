# pickup.gd
extends Area2D

var pickup_type: String = "health"
var amount: int = 25
var float_time: float = 0.0

var sprite: Sprite2D

func setup(type: String, val: int) -> void:
	pickup_type = type
	amount = val
	sprite = Sprite2D.new()
	var path = "res://assets/sprites/item_health_potion.png" if type == "health" else "res://assets/sprites/item_mana_potion.png"
	var tex = load(path)
	if tex:
		sprite.texture = tex
	add_child(sprite)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12.0
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	float_time += delta * 4.0
	if sprite:
		sprite.position.y = sin(float_time) * 3.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if pickup_type == "health" and body.has_method("heal"):
			body.heal(amount)
			queue_free()
		elif pickup_type == "mana" and body.has_method("restore_mp"):
			body.restore_mp(amount)
			queue_free()

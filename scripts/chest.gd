# chest.gd
extends Area2D

@export var gold_amount: int = 50
var is_opened: bool = false
var sprite: Sprite2D

func _ready() -> void:
	sprite = Sprite2D.new()
	var tex = load("res://assets/tiles/tileset.png")
	if tex:
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(224, 0, 32, 32) # Closed chest
		sprite.texture = atlas
	add_child(sprite)

	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 18.0
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not is_opened and body.is_in_group("player"):
		open_chest(body)

func open_chest(player: Node2D) -> void:
	is_opened = true
	var tex = load("res://assets/tiles/tileset.png")
	if tex and sprite:
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(0, 32, 32, 32) # Open chest
		sprite.texture = atlas

	if player.has_method("add_gold"):
		player.add_gold(gold_amount)
	if player.has_method("heal"):
		player.heal(40)

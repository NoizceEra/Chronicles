# damage_number.gd
extends Node2D

var velocity: Vector2 = Vector2(0, -35.0)
var lifetime: float = 0.8
var label: Label

func setup(text_val: String, color: Color) -> void:
	label = Label.new()
	label.text = text_val
	label.modulate = color
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.scale = Vector2(0.8, 0.8)
	label.position = Vector2(-20, -10)
	add_child(label)
	velocity.x = randf_range(-15, 15)

func _process(delta: float) -> void:
	global_position += velocity * delta
	lifetime -= delta
	modulate.a = lifetime / 0.8
	if lifetime <= 0:
		queue_free()

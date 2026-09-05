# CharacterController.gd
# Drop this script on a CharacterBody2D with an AnimatedSprite2D child named "AnimatedSprite2D".
extends CharacterBody2D

@export var move_speed: float = 80.0
@export var sprite_frames_res: SpriteFrames

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_dir: String = "down"

func _ready() -> void:
	if sprite_frames_res:
		anim_sprite.sprite_frames = sprite_frames_res
	anim_sprite.play("idle_down")

func _physics_process(_delta: float) -> void:
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_axis("ui_left", "ui_right")
	input_vector.y = Input.get_axis("ui_up", "ui_down")
	input_vector = input_vector.normalized()

	velocity = input_vector * move_speed
	move_and_slide()

	# Update Animations
	if input_vector != Vector2.ZERO:
		if abs(input_vector.x) > abs(input_vector.y):
			last_dir = "right" if input_vector.x > 0 else "left"
		else:
			last_dir = "down" if input_vector.y > 0 else "up"
		anim_sprite.play("walk_" + last_dir)
	else:
		anim_sprite.play("idle_" + last_dir)

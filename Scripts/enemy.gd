extends Node3D

@export var animated_sprite: AnimatedSprite3D
@onready var camera: Camera3D = get_viewport().get_camera_3d()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animated_sprite.play("front")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	render_correct_animation()

func render_correct_animation() -> void:
	var player_angle = get_player_angle_to_character()
	play_correct_angle_animation_4_way(player_angle)

func get_player_angle_to_character() -> float:
	var character_facing := Vector2(-transform.basis.x.z, -transform.basis.z.z).normalized()
	var to_camera := Vector2(camera.global_position.x - global_position.x, camera.global_position.z - global_position.z).normalized()
	var angle_deg := rad_to_deg(character_facing.angle_to(to_camera))
	return angle_deg

func play_correct_angle_animation_4_way(angle_deg: float) -> void:
	if angle_deg >= -45 and angle_deg < 45:
		animated_sprite.play("front")
		animated_sprite.flip_h = false
	elif angle_deg >= 45 and angle_deg < 90:
		animated_sprite.play("right")
		animated_sprite.flip_h = false
	elif angle_deg < -45 and angle_deg >= -112.5:
		animated_sprite.play("right")
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false
		animated_sprite.play("back")

func play_correct_angle_animation_8_way(angle_deg: float) -> void:
	if angle_deg >= -22.5 and angle_deg < 22.5:
		animated_sprite.play("front")
		animated_sprite.flip_h = false
	elif angle_deg >= 22.5 and angle_deg < 67.5:
		animated_sprite.play("front_diagonal")
		animated_sprite.flip_h = false
	elif angle_deg >= 67.5 and angle_deg < 112.5:
		animated_sprite.play("right")
		animated_sprite.flip_h = false
	elif angle_deg >= 112.5 and angle_deg < 157.5:
		animated_sprite.play("back_diagonal")
		animated_sprite.flip_h = false
	elif angle_deg <= -22.5 and angle_deg > -67.5:
		animated_sprite.play("front_diagonal")
		animated_sprite.flip_h = true
	elif angle_deg <= -67.5 and angle_deg > -112.5:
		animated_sprite.play("right")
		animated_sprite.flip_h = true
	elif angle_deg <= -112.5 and angle_deg > -157.5:
		animated_sprite.play("back_diagonal")
		animated_sprite.flip_h = true
	else:
		animated_sprite.play("back")

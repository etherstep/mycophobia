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
	var animation_name = get_4way_animation_name(player_angle)
	if animation_name == "left":
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false
	animated_sprite.play(animation_name)

func get_player_angle_to_character() -> float:
	var character_facing := Vector2(-transform.basis.x.z, -transform.basis.z.z).normalized()
	var to_camera := Vector2(camera.global_position.x - global_position.x, camera.global_position.z - global_position.z).normalized()
	var angle_deg := rad_to_deg(character_facing.angle_to(to_camera))
	return angle_deg

func get_4way_animation_name(angle_deg: float) -> String:
	if angle_deg >= -45.0 and angle_deg < 45:
		return "front"
	elif angle_deg >= 45.0 and angle_deg < 135.0:
		return "right"
	elif angle_deg >= -135.0 and angle_deg < -45.0:
		return "left"
	else:
		return "back"

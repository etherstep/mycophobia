extends CharacterBody3D


const SPEED = 5.0
const MOUSE_SENSITIVITY := 0.0022
const PITCH_LIMIT := deg_to_rad(80.0)

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var pitch := 0.0

@onready var camera_3d: Camera3D = $Camera3D
@export var inventory_ui: Control

# AUDIO
@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer
@export var footstep_sounds: Array[AudioStream]
@export var footstep_interval: float = 0.45
var footstep_tween: Tween
var footstep_timer: float = 0.0
var last_footstep_index: int = -1

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if event.is_action_pressed("inventory"):
		toggle_inventory()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		# Yaw turns the body. Pitch turns only the camera, so the horizon stays level.
		rotate_y(-event.relative.x * Settings.mouse_sensitivity)
		pitch = clampf(pitch - event.relative.y * Settings.mouse_sensitivity, -PITCH_LIMIT, PITCH_LIMIT)
		camera_3d.rotation.x = pitch
		return

func toggle_inventory() -> void:
	if inventory_ui:
		inventory_ui.visible = not inventory_ui.visible

		if inventory_ui.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	var input_dir := Input.get_vector("left", "right", "up", "down")
	#var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	update_footsteps(delta)

# AUDIO
func update_footsteps(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var is_moving := is_on_floor() and horizontal_speed > 0.1
	if not is_moving:
		return
	footstep_timer -= delta
	if footstep_timer <= 0.0:
		if not footstep_player.playing:
			play_random_footstep()
			footstep_timer = footstep_interval

func stop_footsteps() -> void:
	if not footstep_player.playing:
		return
	if footstep_tween and footstep_tween.is_running():
		footstep_tween.kill()
	footstep_tween = create_tween()
	footstep_tween.tween_property(
		footstep_player, "volume_db", -40.0, 0.2
	)
	footstep_tween.tween_callback(footstep_player.stop)
	footstep_tween.tween_callback(
		func(): footstep_player.volume_db = 0.0
	)

func play_random_footstep() -> void:
	if footstep_sounds.is_empty():
		return
	if footstep_player.playing:
		return
	var sound_index: int
	if footstep_sounds.size() == 1:
		sound_index = 0
	else:
		sound_index = randi_range(0, footstep_sounds.size() - 1)
		while sound_index == last_footstep_index:
			sound_index = randi_range(0, footstep_sounds.size() - 1)
	last_footstep_index = sound_index
	footstep_player.stream = footstep_sounds[sound_index]
	footstep_player.play()

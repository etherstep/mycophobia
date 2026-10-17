extends CharacterBody3D


const SPEED = 5.0
const MOUSE_SENSITIVITY := 0.0022
const PITCH_LIMIT := deg_to_rad(80.0)

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var pitch := 0.0

@onready var camera_3d: Camera3D = $Camera3D
@export var inventory_ui: Control

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
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		pitch = clampf(pitch - event.relative.y * MOUSE_SENSITIVITY, -PITCH_LIMIT, PITCH_LIMIT)
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
		
	#var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backwards")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

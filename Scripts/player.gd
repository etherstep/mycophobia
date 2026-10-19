extends CharacterBody3D


const MOUSE_SENSITIVITY := 0.0022
const PITCH_LIMIT := deg_to_rad(80.0)
const CROUCH_HEIGHT := 1.4
const CROUCH_CAMERA_Y = 1.15
const CROUCH_CAMERA_SPEED := 6.0

const SPEED = 5.0
const JUMP_VELOCITY := 5.0
const SPRINT_SPEED := 8.0
const CROUCH_SPEED := 2.5

const GRAVITY := 16.0
const FALL_GRAVITY_MULTIPLIER := 1.15
const JUMP_CUT_MULTIPLIER := 1.5

# RUNNING CAMERA BOB
const BOB_AMOUNT := 0.045
const BOB_FREQUENCY := 10.0
const SPRINT_BOB_MULTIPLIER := 1.35
const BOB_SMOOTHING := 10.0

var bob_time := 0.0
var camera_base_y := 0.0

var gravity: float = GRAVITY

var dead := false
var pitch := 0.0
var crouched := false
var stand_height: float
var stand_shape_y: float
var stand_camera_y: float

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var camera_3d: Camera3D = $Camera3D
@export var inventory_ui: Control
@export var player_hand: CanvasLayer

# AUDIO
@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer
@export var footstep_sounds: Array[AudioStream]
@export var footstep_interval: float = 0.45
var footstep_tween: Tween
var footstep_timer: float = 0.0
var last_footstep_index: int = -1

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if inventory_ui:
		inventory_ui.hide()
	if player_hand:
		player_hand.show()
	var capsule := collision_shape_3d.shape as CapsuleShape3D
	stand_height = capsule.height
	stand_shape_y = collision_shape_3d.position.y
	stand_camera_y = camera_3d.position.y
	camera_base_y = camera_3d.position.y

func _unhandled_input(event: InputEvent) -> void:
	if dead:
		return
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

func die() -> void:
	if dead:
		return
	dead = true
	velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var layer := CanvasLayer.new()
	var label := Label.new()
	label.text = "The enemy caught you"
	label.position = Vector2(520, 340)
	layer.add_child(label)
	add_child(layer)
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()


func toggle_inventory() -> void:
	if inventory_ui == null:
		push_warning("Inventory UI is not assigned!")
		return
	if inventory_ui.close_note_if_open():
		get_viewport().set_input_as_handled()
		return
	inventory_ui.visible = not inventory_ui.visible
	inventory_ui.play_inventory_sfx(inventory_ui.visible)
	_update_inventory_state()
	get_viewport().set_input_as_handled()

func _update_inventory_state() -> void:
	var inventory_open := inventory_ui.visible
	if player_hand:
		player_hand.visible = not inventory_open
	Input.mouse_mode = (
		Input.MOUSE_MODE_VISIBLE
		if inventory_open
		else Input.MOUSE_MODE_CAPTURED
	)

func _physics_process(delta: float) -> void:
	if dead:
		return
	if Input.is_action_just_pressed("crouch"):
		if crouched:
			if _can_stand():
				crouched = false
		else:
			crouched = true
	
	var capsule := collision_shape_3d.shape as CapsuleShape3D
	if crouched :
		capsule.height = CROUCH_HEIGHT
		collision_shape_3d.position.y = CROUCH_HEIGHT * 0.5
	else:
		capsule.height = stand_height
		collision_shape_3d.position.y = stand_shape_y
	
	if is_on_floor():
		if Input.is_action_just_pressed("jump") and not crouched:
			velocity.y = JUMP_VELOCITY
	else:
		var current_gravity := GRAVITY

		if velocity.y < 0.0:
			current_gravity *= FALL_GRAVITY_MULTIPLIER
		elif velocity.y > 0.0 and not Input.is_action_pressed("jump"):
			current_gravity *= JUMP_CUT_MULTIPLIER

		velocity.y -= current_gravity * delta
	
	var speed := SPEED
	if crouched:
		speed = CROUCH_SPEED
	elif Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
		
	var input_dir := Input.get_vector("left", "right", "up", "down")
	#var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		# Responsive ground movement.
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0.0, speed * 2.5 * delta)
			velocity.z = move_toward(velocity.z, 0.0, speed * 2.5 * delta)
	else:
		# Preserve momentum in the air, with limited air control.
		var air_acceleration := 4.0

		if direction:
			velocity.x = move_toward(
				velocity.x,
				direction.x * speed,
				air_acceleration * delta
			)
			velocity.z = move_toward(
				velocity.z,
				direction.z * speed,
				air_acceleration * delta
			)

	move_and_slide()
	# Stop horizontal momentum immediately upon landing
	if is_on_floor() and not Input.is_action_pressed("left") \
	and not Input.is_action_pressed("right") \
	and not Input.is_action_pressed("up") \
	and not Input.is_action_pressed("down"):
		velocity.x = 0.0
		velocity.z = 0.0
	update_camera_bob(delta)
	update_footsteps(delta)

func _can_stand() -> bool:
	var capsule := collision_shape_3d.shape as CapsuleShape3D
	var stand_shape := CapsuleShape3D.new()
	stand_shape.radius = capsule.radius
	stand_shape.height = stand_height
	var bottom := stand_shape_y - stand_height * 0.5
	var lift: float = maxf(0.0, -bottom) + 0.01
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = stand_shape
	query.margin = 0.0
	query.transform = global_transform * Transform3D(Basis(), Vector3(0, stand_shape_y + lift, 0))
	query.exclude = [get_rid()]
	var hits := get_world_3d().direct_space_state.intersect_shape(query, 1)
	return hits.is_empty()

func update_camera_bob(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var is_running := is_on_floor() and horizontal_speed > 0.5 and not crouched

	var bob_offset := 0.0

	if is_running:
		var frequency := BOB_FREQUENCY
		var amount := BOB_AMOUNT

		if Input.is_action_pressed("sprint"):
			frequency *= SPRINT_BOB_MULTIPLIER
			amount *= SPRINT_BOB_MULTIPLIER

		bob_time += delta * frequency
		bob_offset = absf(sin(bob_time)) * amount

	var target_y := (CROUCH_CAMERA_Y if crouched else stand_camera_y) + bob_offset

	camera_3d.position.y = move_toward(
		camera_3d.position.y,
		target_y,
		BOB_SMOOTHING * delta
	)

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

extends CharacterBody3D

const WALK_SPEED := 1.0
const GRAVITY := 18.0
const WAIT_TIME := 2.5
const BURN_TIME := 2.0
const ENDING_SCENE := "res://Scenes/EndingScreen.tscn"

@export var chamber: Area3D
@export var salted_color := Color(0.9, 0.85, 0.65)
@export var salt_effect: Node3D
@export var fire_effect: Node3D

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var salt_particles: GPUParticles3D = (
	salt_effect.get_node_or_null("Salt") as GPUParticles3D
	if is_instance_valid(salt_effect)
	else null
)

var _salted := false
var _dead := false
var _ending_started := false
var _fires_left := 0
var _wait := 0.0
var _stuck := 0.0
var _goal := Vector3.ZERO
var _use_nav := false
var _camera: Camera3D


func _ready() -> void:
	if not is_in_group("enemies"):
		add_to_group("enemies")
	animated_sprite.play("idle_front")
	animated_sprite.pause()
	_fit_use_area()
	await get_tree().physics_frame
	_pick_point()


func _process(_delta: float) -> void:
	_play_facing()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if _dead:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) == 0:
		move_and_slide()
		return
	if _wait > 0.0:
		_wait -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		_stuck = 0.0
	elif _use_nav and agent.is_navigation_finished():
		_begin_wait()
	elif not _use_nav and _reached(_goal):
		_begin_wait()
	elif _use_nav:
		_move_along_path()
	else:
		_move_toward(_goal)
	move_and_slide()
	_watch_stuck(delta)


func apply_salted() -> void:
	if _dead or _salted:
		return
	_salted = true
	animated_sprite.modulate = salted_color
	if is_instance_valid(salt_particles):
		salt_particles.restart()
		salt_particles.emitting = true


func is_salted() -> bool:
	return _salted


func kill_by_matches() -> void:
	if _dead or not _salted:
		return
	_dead = true
	velocity.x = 0.0
	velocity.z = 0.0
	if is_instance_valid(salt_effect):
		salt_effect.queue_free()
	var fires := _flame_nodes()
	if fires.is_empty():
		_show_ending()
		return
	_fires_left = fires.size()
	for flames in fires:
		flames.one_shot = true
		flames.lifetime = BURN_TIME
		flames.finished.connect(_on_fire_finished)
		flames.restart()
		flames.emitting = true
	get_tree().create_timer(BURN_TIME * 2.0 + 0.5).timeout.connect(_show_ending)


func _flame_nodes() -> Array[GPUParticles3D]:
	var fires: Array[GPUParticles3D] = []
	for child in get_children():
		var flames := child.get_node_or_null("Flames") as GPUParticles3D
		if flames != null:
			fires.append(flames)
	return fires


func _on_fire_finished() -> void:
	_fires_left -= 1
	if _fires_left <= 0:
		_show_ending()


func _show_ending() -> void:
	if _ending_started or not is_inside_tree():
		return
	_ending_started = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(ENDING_SCENE)


func _fit_use_area() -> void:
	var shape_node := get_node_or_null("UseArea/CollisionShape3D") as CollisionShape3D
	if shape_node == null or not shape_node.shape is CylinderShape3D:
		return
	var span := 1920.0 * animated_sprite.pixel_size
	var cylinder := shape_node.shape.duplicate() as CylinderShape3D
	cylinder.height = span
	cylinder.radius = span * 0.46
	shape_node.shape = cylinder
	shape_node.position = animated_sprite.position


func _begin_wait() -> void:
	_wait = WAIT_TIME
	_stuck = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	_pick_point()


func _pick_point() -> void:
	_goal = _random_point_in_chamber()
	_use_nav = _point_on_nav(_goal)
	_stuck = 0.0
	if _use_nav:
		agent.target_position = _goal


func _random_point_in_chamber() -> Vector3:
	var shape_node := _chamber_shape()
	if shape_node == null:
		return global_position
	var any_point := global_position
	var found_any := false
	var far_point := global_position
	var found_far := false
	var map := agent.get_navigation_map()
	var nav_ready := NavigationServer3D.map_get_iteration_id(map) != 0
	for _attempt in 16:
		var local := _random_local_in_shape(shape_node.shape)
		if local == Vector3.INF:
			return global_position
		var world_point := shape_node.to_global(local)
		world_point.y = global_position.y
		any_point = world_point
		found_any = true
		var flat := world_point - global_position
		flat.y = 0.0
		if flat.length() < 2.0:
			continue
		far_point = world_point
		found_far = true
		if not nav_ready:
			return world_point
		var closest := NavigationServer3D.map_get_closest_point(map, world_point)
		var flat_gap := closest - world_point
		flat_gap.y = 0.0
		if flat_gap.length() > 0.6:
			continue
		if _chamber_contains(closest):
			return closest
	if found_far:
		return far_point
	return any_point if found_any else global_position


func _random_local_in_shape(shape: Shape3D) -> Vector3:
	if shape is BoxShape3D:
		var box := shape as BoxShape3D
		var half := box.size * 0.5
		return Vector3(randf_range(-half.x, half.x), 0.0, randf_range(-half.z, half.z))
	if shape is CylinderShape3D:
		var cylinder := shape as CylinderShape3D
		var angle := randf() * TAU
		var reach := cylinder.radius * sqrt(randf())
		return Vector3(cos(angle) * reach, 0.0, sin(angle) * reach)
	return Vector3.INF


func _point_on_nav(point: Vector3) -> bool:
	var map := agent.get_navigation_map()
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return false
	var closest := NavigationServer3D.map_get_closest_point(map, point)
	var flat_gap := closest - point
	flat_gap.y = 0.0
	return flat_gap.length() <= 0.6 and _chamber_contains(closest)


func _chamber_shape() -> CollisionShape3D:
	if chamber == null:
		return null
	return chamber.get_node_or_null("CollisionShape3D") as CollisionShape3D


func _chamber_contains(at: Vector3) -> bool:
	var shape_node := _chamber_shape()
	if shape_node == null:
		return true
	var local := shape_node.global_transform.affine_inverse() * at
	var shape := shape_node.shape
	if shape is BoxShape3D:
		var box := shape as BoxShape3D
		var half := box.size * 0.5
		return absf(local.x) <= half.x and absf(local.z) <= half.z
	if shape is CylinderShape3D:
		var cylinder := shape as CylinderShape3D
		return Vector2(local.x, local.z).length() <= cylinder.radius
	return true


func _reached(point: Vector3) -> bool:
	var flat := point - global_position
	flat.y = 0.0
	return flat.length() < 0.4


func _move_toward(point: Vector3) -> void:
	var flat := point - global_position
	flat.y = 0.0
	if flat.length() < 0.15:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var direction := flat.normalized()
	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	look_at(global_position + direction, Vector3.UP)


func _watch_stuck(delta: float) -> void:
	if _dead or _wait > 0.0:
		return
	if Vector2(velocity.x, velocity.z).length() > 0.05:
		_stuck = 0.0
		return
	_stuck += delta
	if _stuck > 1.2:
		_pick_point()


func _move_along_path() -> void:
	var next := agent.get_next_path_position()
	var flat := next - global_position
	flat.y = 0.0
	if flat.length() < 0.15:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var direction := flat.normalized()
	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	look_at(global_position + direction, Vector3.UP)


func _play_facing() -> void:
	if _camera == null or not is_instance_valid(_camera):
		_camera = get_viewport().get_camera_3d()
	if _camera == null:
		return
	var facing := Vector2(-global_basis.x.z, -global_basis.z.z).normalized()
	var to_camera := Vector2(
		_camera.global_position.x - global_position.x,
		_camera.global_position.z - global_position.z
	)
	if to_camera.length() < 0.01 or facing.length() < 0.01:
		return
	var angle_deg := rad_to_deg(facing.angle_to(to_camera.normalized()))
	var abs_angle := absf(angle_deg)
	var view := "front"
	var flip := false
	if abs_angle > 135.0:
		view = "back"
	elif abs_angle >= 45.0:
		view = "side"
		flip = angle_deg > 0.0
	animated_sprite.flip_h = flip
	var moving := not _dead and Vector2(velocity.x, velocity.z).length() > 0.05
	var clip := ("walk_" if moving else "idle_") + view
	if not moving:
		if animated_sprite.animation != clip:
			animated_sprite.animation = clip
		animated_sprite.pause()
		animated_sprite.frame = 0
		return
	if animated_sprite.animation != clip or not animated_sprite.is_playing():
		animated_sprite.play(clip)

extends CharacterBody3D

const WALK_SPEED := 2.5
const GRAVITY := 18.0

enum State { WANDER, CHASE, SEARCH }

@export var animated_sprite: AnimatedSprite3D
@export var detect_range := 8.0
@export var view_degrees := 70.0
@export var lose_time := 2.0
@export var guards := false
@export var guard_point: Node3D
@export var leash_radius := 6.0

@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var agent: NavigationAgent3D = $NavigationAgent3D

var state := State.WANDER
var last_known := Vector3.ZERO
var unseen_time := 0.0


func _ready() -> void:
	animated_sprite.play("front")
	await get_tree().physics_frame
	_pick_patrol_point()


func _process(_delta: float) -> void:
	render_correct_animation()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) == 0:
		move_and_slide()
		return

	var player := get_tree().get_first_node_in_group("player") as Node3D
	var seen := player != null and _can_see(player)
	if seen:
		last_known = player.global_position
		unseen_time = 0.0
		if _inside_leash(player.global_position):
			state = State.CHASE
	elif state == State.CHASE:
		unseen_time += delta
		var left_leash := player != null and not _inside_leash(player.global_position)
		if unseen_time >= lose_time or left_leash:
			state = State.SEARCH
			agent.target_position = guard_point.global_position if guards and guard_point != null else last_known

	match state:
		State.WANDER:
			if agent.is_navigation_finished():
				_pick_patrol_point()
		State.CHASE:
			if player != null:
				agent.target_position = player.global_position
		State.SEARCH:
			if agent.is_navigation_finished():
				state = State.WANDER
				_pick_patrol_point()

	_move_along_path()
	move_and_slide()


func _can_see(player: Node3D) -> bool:
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() > detect_range or to_player.length() < 0.01:
		return false
	var forward := -global_basis.z
	forward.y = 0.0
	if forward.length() < 0.01:
		return false
	if forward.angle_to(to_player) > deg_to_rad(view_degrees * 0.5):
		return false
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 1.2, 0),
		player.global_position + Vector3(0, 1.2, 0)
	)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == player


func _pick_patrol_point() -> void:
	if guards and guard_point != null:
		agent.target_position = guard_point.global_position
		return
	var points := get_tree().get_nodes_in_group("patrol_point")
	if points.is_empty():
		return
	var point: Node3D = points.pick_random() as Node3D
	agent.target_position = point.global_position


func _move_along_path() -> void:
	var next := agent.get_next_path_position()
	var flat := next - global_position
	flat.y = 0.0
	if flat.length() < 0.3:
		var path := agent.get_current_navigation_path()
		for point in path:
			var candidate := point - global_position
			candidate.y = 0.0
			if candidate.length() >= 0.3:
				flat = candidate
				break
	if flat.length() < 0.1:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var direction := flat.normalized()
	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	_face_direction(direction)


func _face_direction(direction: Vector3) -> void:
	look_at(global_position + direction, Vector3.UP)


func _inside_leash(at: Vector3) -> bool:
	if not guards or guard_point == null:
		return true
	var flat := at - guard_point.global_position
	flat.y = 0.0
	return flat.length() <= leash_radius


func alert(at: Vector3) -> void:
	last_known = at
	unseen_time = 0.0
	state = State.CHASE
	agent.target_position = at


func _on_catch_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("die"):
		body.die()


func render_correct_animation() -> void:
	if camera == null:
		camera = get_viewport().get_camera_3d()
	if camera == null:
		return
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

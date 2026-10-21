extends CharacterBody3D

const WALK_SPEED := 2.5
const CHASE_SPEED := 4.5
const GRAVITY := 18.0

enum State { WANDER, CHASE, SEARCH }

@export var animated_sprite: AnimatedSprite3D
@export var detect_range := 8.0
@export var view_degrees := 70.0
@export var lose_time := 2.0
@export var guards := false
@export var guard_point: Node3D
@export var leash_radius := 6.0
@export var see_over_cover := true
@export var eye_height := 2.6

@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var agent: NavigationAgent3D = $NavigationAgent3D

@onready var chase_sfx_player: AudioStreamPlayer = $ChaseSFX
@onready var lose_interest_sfx_player: AudioStreamPlayer = $LoseInterestSFX
const LOSE_INTEREST_FADE_TIME := 1.5

@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer
@export var footstep_sounds: Array[AudioStream]

@export var footstep_interval: float = 0.45
@export var footstep_interval_chase: float = 0.22

@onready var enemy_voice_player: AudioStreamPlayer3D = $EnemyVoicePlayer

@export var enemy_sounds: Array[AudioStream]

@export var enemy_sound_interval_min: float = 3.0
@export var enemy_sound_interval_max: float = 7.0

var enemy_sound_timer: float = 0.0
var last_enemy_sound_index: int = -1

var footstep_timer: float = 0.0
var last_footstep_index: int = -1

var state := State.WANDER
var last_known := Vector3.ZERO
var unseen_time := 0.0


func _ready() -> void:
	animated_sprite.play("front")
	_reset_enemy_sound_timer()

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
	if player != null and _has_used_syringe(player):
		if state != State.WANDER:
			state = State.WANDER
			chase_sfx_player.stop()
			_pick_patrol_point()
		_move_along_path()
		move_and_slide()
		return
	var seen := player != null and _can_see(player)
	if seen:
		last_known = player.global_position
		unseen_time = 0.0
		if _inside_leash(player.global_position):
			if state != State.CHASE:
				state = State.CHASE
				chase_sfx_player.play()
	elif state == State.CHASE:
		unseen_time += delta
		var left_leash := player != null and not _inside_leash(player.global_position)
		if unseen_time >= lose_time or left_leash:
			state = State.SEARCH
			chase_sfx_player.stop()
			play_lose_interest_sfx()
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
	update_footsteps(delta)
	update_enemy_sounds(delta)

func update_footsteps(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var is_moving := is_on_floor() and horizontal_speed > 0.1

	if not is_moving:
		footstep_timer = 0.0
		return

	var current_interval := footstep_interval

	if state == State.CHASE:
		current_interval = footstep_interval_chase

	footstep_timer -= delta

	if footstep_timer <= 0.0:
		play_random_footstep()
		footstep_timer = current_interval


func play_random_footstep() -> void:
	if footstep_sounds.is_empty():
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
	var eye_y := 1.2
	var target_y := 1.2
	if see_over_cover:
		eye_y = eye_height
		target_y = _player_head_height(player)
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, eye_y, 0),
		player.global_position + Vector3(0, target_y, 0)
	)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.collider != player:
		return false
	return _is_player_lit(player)


func _player_head_height(player: Node3D) -> float:
	if player is Player:
		var body: Player = player
		if body.crouched:
			return Player.CROUCH_CAMERA_Y
		return body.stand_camera_y
	return 1.2


func _is_player_lit(player: Node3D) -> bool:
	var chest := player.global_position + Vector3(0, 1.2, 0)
	for node in get_tree().get_nodes_in_group("detection_light"):
		if not node is Light3D:
			continue
		var light: Light3D = node
		if not light.visible:
			continue
		# The player's own flashlight points forward, so the body is outside its cone.
		if player.is_ancestor_of(light):
			return true
		if _light_reaches(light, chest, player):
			return true
	return false


func _light_reaches(light: Light3D, chest: Vector3, player: Node3D) -> bool:
	var to_chest := chest - light.global_position
	var distance := to_chest.length()
	if distance < 0.01:
		return true
	var light_range := 0.0
	if light is OmniLight3D:
		var omni: OmniLight3D = light
		light_range = omni.omni_range
	elif light is SpotLight3D:
		var spot: SpotLight3D = light
		light_range = spot.spot_range
		var forward := -light.global_basis.z
		if forward.angle_to(to_chest) > deg_to_rad(spot.spot_angle):
			return false
	else:
		return false
	if distance > light_range:
		return false
	if _point_hits_player(light.global_position, player):
		return true
	var query := PhysicsRayQueryParameters3D.create(light.global_position, chest)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == player


func _point_hits_player(point: Vector3, player: Node3D) -> bool:
	var query := PhysicsPointQueryParameters3D.new()
	query.position = point
	query.exclude = [get_rid()]
	var hits := get_world_3d().direct_space_state.intersect_point(query)
	for hit in hits:
		if hit.collider == player:
			return true
	return false


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
	var current_speed := WALK_SPEED

	if state == State.CHASE:
		current_speed = CHASE_SPEED

	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	_face_direction(direction)


func _face_direction(direction: Vector3) -> void:
	look_at(global_position + direction, Vector3.UP)


func _inside_leash(at: Vector3) -> bool:
	if not guards or guard_point == null:
		return true
	var flat := at - guard_point.global_position
	flat.y = 0.0
	return flat.length() <= leash_radius

func _has_used_syringe(player: Node3D) -> bool:
	if player is Player:
		var body: Player = player
		return body.syringe_used
	return false

func alert(at: Vector3) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null and _has_used_syringe(player):
		return

	if state != State.CHASE:
		state = State.CHASE
		chase_sfx_player.play()

	last_known = at
	unseen_time = 0.0
	agent.target_position = at

func _on_catch_area_body_entered(body: Node3D) -> void:
	if _has_used_syringe(body):
		return
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

func play_correct_angle_animation_4_way(_angle_deg: float) -> void:
	animated_sprite.flip_h = false
	animated_sprite.play("front")

func play_correct_angle_animation_8_way(_angle_deg: float) -> void:
	animated_sprite.flip_h = false
	animated_sprite.play("front")


func play_lose_interest_sfx() -> void:
	lose_interest_sfx_player.stop()
	lose_interest_sfx_player.volume_db = -40.0
	lose_interest_sfx_player.play()

	var tween := create_tween()
	tween.tween_property(
		lose_interest_sfx_player,
		"volume_db",
		0.0,
		LOSE_INTEREST_FADE_TIME
	)

func update_enemy_sounds(delta: float) -> void:
	if enemy_sounds.is_empty():
		return

	enemy_sound_timer -= delta

	if enemy_sound_timer <= 0.0:
		play_random_enemy_sound()
		_reset_enemy_sound_timer()


func play_random_enemy_sound() -> void:
	if enemy_sounds.is_empty():
		return

	var sound_index := randi_range(0, enemy_sounds.size() - 1)

	if enemy_sounds.size() > 1:
		while sound_index == last_enemy_sound_index:
			sound_index = randi_range(0, enemy_sounds.size() - 1)

	last_enemy_sound_index = sound_index

	enemy_voice_player.stream = enemy_sounds[sound_index]
	enemy_voice_player.play()


func _reset_enemy_sound_timer() -> void:
	var min_interval := enemy_sound_interval_min
	var max_interval := enemy_sound_interval_max

	if state == State.CHASE:
		min_interval *= 0.5
		max_interval *= 0.5

	enemy_sound_timer = randf_range(min_interval, max_interval)

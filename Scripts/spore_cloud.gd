extends Node3D

@export var fire_interval := 1.5
@export var range := 8.0
@export var infection_per_hit := 5
@export var spore_speed := 6.0

const AIM_HEIGHT := 1.0
const HIT_DISTANCE := 0.6
const SPORE_LIFETIME := 4.0

var _cooldown := 0.0


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown = fire_interval
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var aim := player.global_position + Vector3(0, AIM_HEIGHT, 0)
	var to_player := aim - global_position
	if to_player.length() > range or to_player.length() < 0.01:
		return
	var query := PhysicsRayQueryParameters3D.create(global_position, aim)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.collider != player:
		return
	_spawn_spore(player, aim)


func _spawn_spore(player: Node3D, aim: Vector3) -> void:
	var spore := Spore.new()
	spore.target = aim
	spore.speed = spore_speed
	spore.infection = infection_per_hit
	spore.player = player
	spore.life = SPORE_LIFETIME
	spore.aim_height = AIM_HEIGHT
	spore.hit_distance = HIT_DISTANCE
	get_parent().add_child(spore)
	spore.global_position = global_position


class Spore extends MeshInstance3D:
	var target := Vector3.ZERO
	var speed := 6.0
	var infection := 5
	var player: Node3D
	var life := 4.0
	var aim_height := 1.0
	var hit_distance := 0.6

	func _ready() -> void:
		var sphere := SphereMesh.new()
		sphere.radius = 0.12
		sphere.height = 0.24
		mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.62, 0.82, 0.32)
		mat.emission_enabled = true
		mat.emission = Color(0.45, 0.7, 0.2)
		mat.emission_energy_multiplier = 1.2
		material_override = mat

	func _physics_process(delta: float) -> void:
		life -= delta
		if life <= 0.0:
			queue_free()
			return
		var step := speed * delta
		var to_target := target - global_position
		if to_target.length() <= step:
			global_position = target
		else:
			global_position += to_target.normalized() * step
		if player == null or not is_instance_valid(player):
			return
		var body := player.global_position + Vector3(0, aim_height, 0)
		if global_position.distance_to(body) > hit_distance:
			return
		if player.has_method("increase_infection"):
			player.increase_infection(infection)
		queue_free()


extends StaticBody3D

# -------------------------
# Spore shooting settings
# -------------------------
@export var fire_interval := 1.5
@export var range := 8.0
@export var infection_per_hit := 5
@export var spore_speed := 6.0

@export var salted_color := Color(0.9, 0.85, 0.65)

# -------------------------
# Touch infection settings
# -------------------------
const TOUCH_INFECTION := 5
const TOUCH_COOLDOWN := 0.8
const PUSH_STEPS := 0.3

# -------------------------
# Spore projectile settings
# -------------------------
const AIM_HEIGHT := 1.0
const HIT_DISTANCE := 0.6
const SPORE_LIFETIME := 4.0

# -------------------------
# State
# -------------------------
var _fire_cooldown := 0.0
var _touch_cooldown := 0.0
var _salted := false
var _dead := false
var _original_materials: Array[Dictionary] = []


func _ready() -> void:
	if not is_in_group("enemies"):
		add_to_group("enemies")

	_cache_original_materials(self)


func _physics_process(delta: float) -> void:
	if _dead:
		return

	# Handle touch infection and pushing.
	if _touch_cooldown > 0.0:
		_touch_cooldown -= delta

	var area := get_node_or_null("Area3D") as Area3D
	if area != null:
		for body in area.get_overlapping_bodies():
			if body is Player:
				_try_push(body as Player)

	# Handle spore shooting.
	_fire_cooldown -= delta
	if _fire_cooldown > 0.0:
		return

	_fire_cooldown = fire_interval

	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return

	# Ignore the player after they have used the syringe.
	if player.syringe_used:
		return

	var aim := player.global_position + Vector3(0, AIM_HEIGHT, 0)
	var to_player := aim - global_position

	if to_player.length() > range or to_player.length() < 0.01:
		return

	var query := PhysicsRayQueryParameters3D.create(
		global_position,
		aim
	)
	# Prevent the ray from hitting this enemy itself.
	query.exclude = [get_rid()]

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)

	if hit.is_empty() or hit.collider != player:
		return

	_spawn_spore(player, aim)


# -------------------------
# Salt and Matches
# -------------------------

# Called by the player's Salt item.
func apply_salted() -> void:
	if _dead or _salted:
		return

	_salted = true
	_set_enemy_color(salted_color)


# Called by the player's Matches item.
func is_salted() -> bool:
	return _salted and not _dead


# Called by Matches after the enemy has been salted.
func kill_by_matches() -> void:
	if _dead or not _salted:
		return

	_dead = true
	queue_free()


# -------------------------
# Touch infection and pushing
# -------------------------

func _try_push(player: Player) -> void:
	if _touch_cooldown > 0.0 or player.dead:
		return

	var away := _push_normal(player)
	if away == Vector3.ZERO:
		return

	_touch_cooldown = TOUCH_COOLDOWN
	player.shove(away, PUSH_STEPS)
	player.increase_infection(TOUCH_INFECTION)


func _push_normal(player: Player) -> Vector3:
	var count := player.get_slide_collision_count()

	for i in range(count):
		var hit := player.get_slide_collision(i)

		if hit.get_collider() != self:
			continue

		var normal := hit.get_normal()

		if hit.get_remainder().dot(normal) >= -0.02:
			continue

		normal.y = 0.0

		if normal.length() < 0.01:
			continue

		return normal.normalized()

	return Vector3.ZERO


# -------------------------
# Enemy appearance
# -------------------------

func _cache_original_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var surface_count := 0

		if mesh_instance.mesh != null:
			surface_count = mesh_instance.mesh.get_surface_count()

		for surface_index in range(surface_count):
			_original_materials.append({
				"mesh": mesh_instance,
				"surface": surface_index,
				"material": mesh_instance.get_surface_override_material(
					surface_index
				)
			})

	for child in node.get_children():
		_cache_original_materials(child)


func _set_enemy_color(color: Color) -> void:
	for entry in _original_materials:
		var mesh_instance := entry["mesh"] as MeshInstance3D

		if not is_instance_valid(mesh_instance):
			continue

		var surface_index: int = entry["surface"]
		var original_material := entry["material"] as Material
		var material: StandardMaterial3D

		if original_material is StandardMaterial3D:
			material = (
				original_material as StandardMaterial3D
			).duplicate()
		else:
			material = StandardMaterial3D.new()

		material.albedo_color = color
		mesh_instance.set_surface_override_material(
			surface_index,
			material
		)


# -------------------------
# Spore projectile spawning
# -------------------------

func _spawn_spore(player: Node3D, aim: Vector3) -> void:
	if _dead:
		return

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


# -------------------------
# Spore projectile
# -------------------------

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

		# Remove spores if the player has used the syringe.
		if player is Player and (player as Player).syringe_used:
			queue_free()
			return

		var body := player.global_position + Vector3(0, aim_height, 0)

		if global_position.distance_to(body) > hit_distance:
			return

		if player.has_method("increase_infection"):
			player.increase_infection(infection)

		queue_free()

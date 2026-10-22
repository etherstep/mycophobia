
extends StaticBody3D

@export var salted_color := Color(0.9, 0.85, 0.65)

const TOUCH_INFECTION := 5
const TOUCH_COOLDOWN := 0.8
const PUSH_STEPS := 0.3

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

	if _touch_cooldown > 0.0:
		_touch_cooldown -= delta

	var area := get_node_or_null("Area3D") as Area3D
	if area == null:
		return

	for body in area.get_overlapping_bodies():
		if body is Player:
			_try_push(body as Player)


# -------------------------
# Salt and Matches
# -------------------------

func apply_salted() -> void:
	if _dead or _salted:
		return

	_salted = true
	_set_enemy_color(salted_color)


func is_salted() -> bool:
	return _salted and not _dead


func kill_by_matches() -> void:
	if _dead or not _salted:
		return

	_dead = true
	for node in get_tree().get_nodes_in_group("enemies"):
		if node.get("starts_chase") != true or node.get("cloud") != self:
			continue
		var intro := get_tree().get_first_node_in_group("chase_intro")
		if intro != null and intro.has_method("begin"):
			intro.begin()
		break
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

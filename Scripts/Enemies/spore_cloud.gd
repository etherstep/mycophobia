
extends StaticBody3D

const TOUCH_INFECTION := 5
const TOUCH_COOLDOWN := 0.8
const PUSH_STEPS := 0.3

var _touch_cooldown := 0.0
var _dead := false
var _original_materials: Array[Dictionary] = []

@onready var touch_sound: AudioStreamPlayer = $TouchSound

@export var player: Player

var sound_cooldown := 0.0
const SOUND_COOLDOWN := 1.0

func _ready() -> void:
	if not is_in_group("enemies"):
		add_to_group("enemies")
	_cache_original_materials(self)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	update_syringe_collision()
	if sound_cooldown > 0.0:
		sound_cooldown -= delta
	if _touch_cooldown > 0.0:
		_touch_cooldown -= delta
	var area := get_node_or_null("Area3D") as Area3D
	if area == null:
		return
	for body in area.get_overlapping_bodies():
		if body is Player and not player.syringe_used:
			_try_push(body as Player)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.is_in_group("player") and not player.syringe_used:
		if sound_cooldown <= 0.0:
			touch_sound.play()
			sound_cooldown = SOUND_COOLDOWN

func _linked_shooter() -> Node:
	for node in get_tree().get_nodes_in_group("enemies"):
		if node == self:
			continue
		if node.get("cloud") == self and node.has_method("kill_by_matches"):
			return node
	return null

func _start_chase_if_linked() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if node.get("starts_chase") != true or node.get("cloud") != self:
			continue
		var intro := get_tree().get_first_node_in_group("chase_intro")
		if intro != null and intro.has_method("begin"):
			intro.begin()
		break

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

func update_syringe_collision() -> void:
	if player == null:
		return

	if player.syringe_used:
		collision_layer = collision_layer & ~(1 << 1)
		collision_mask = collision_mask & ~(1 << 1)

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

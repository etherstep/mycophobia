extends StaticBody3D

signal burned

@onready var spore_audio_player: AudioStreamPlayer3D = $SporePlayer

@export var salted_color := Color(0.9, 0.85, 0.65)
@export var cloud: StaticBody3D
@export var starts_chase := false

@export var salt_effect: Node3D

@onready var salt_particles: GPUParticles3D = (
	salt_effect.get_node_or_null("Salt") as GPUParticles3D
	if is_instance_valid(salt_effect)
	else null
)

@export var fire_effect: Node3D

@onready var fire_particles: GPUParticles3D = (
	fire_effect.get_node_or_null("Flames") as GPUParticles3D
	if is_instance_valid(fire_effect)
	else null
)

var _salted := false
var _dead := false
var _original_materials: Array[Dictionary] = []

func _ready() -> void:
	if not is_in_group("enemies"):
		add_to_group("enemies")

	_cache_original_materials(self)
	spore_audio_player.play()

func get_spore_shooter() -> Node3D:
	return self

func apply_salted() -> void:
	if _dead or _salted:
		return

	_salted = true
	_set_enemy_color(salted_color)

	# Play the salt particle effect.
	if is_instance_valid(salt_particles):
		salt_particles.restart()
		salt_particles.emitting = true

func kill_by_matches() -> void:
	if _dead or not _salted:
		return

	_dead = true
	if starts_chase:
		var intro := get_tree().get_first_node_in_group("chase_intro")
		if intro != null and intro.has_method("begin"):
			intro.begin()
		burned.emit()

	# Remove the salt effect.
	if is_instance_valid(salt_effect):
		salt_effect.queue_free()

	# Stop the spore cloud.
	if is_instance_valid(cloud):
		cloud.queue_free()

	# Play the fire effect.
	if is_instance_valid(fire_particles):
		fire_particles.restart()
		fire_particles.emitting = true

	# Let the fire play for 2 seconds, then destroy the shooter.
	get_tree().create_timer(2.0).timeout.connect(queue_free)


func interact() -> void:
	if _dead:
		return

	# The Player script handles equipped items and consumption.
	# This function should not automatically consume inventory items.
	pass

func is_salted() -> bool:
	return _salted
	

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

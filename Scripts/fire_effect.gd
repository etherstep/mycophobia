@tool
extends Node3D

@export_range(0.1, 10.0) var fire_scale: float = 1.0:
	set(value):
		fire_scale = value
		update_fire_scale()

@onready var flames: GPUParticles3D = $Flames
@onready var light: OmniLight3D = $Light

# Base values (for scale = 1.0)
const BASE_MESH_SIZE := Vector2(0.5, 0.5)
const BASE_VELOCITY_MIN := 1.0
const BASE_VELOCITY_MAX := 2.5
const BASE_AMOUNT := 16
const BASE_LIGHT_RANGE := 8.0
const BASE_LIGHT_ENERGY := 2.0

func _ready() -> void:
	_make_resources_unique()
	update_fire_scale()

func _make_resources_unique() -> void:
	var flames := get_node_or_null("Flames") as GPUParticles3D
	if flames:
		if flames.draw_pass_1:
			flames.draw_pass_1 = flames.draw_pass_1.duplicate()
		if flames.process_material:
			flames.process_material = flames.process_material.duplicate()

func update_fire_scale() -> void:
	if not is_inside_tree():
		return

	# Fetch nodes dynamically with get_node_or_null to prevent null refs in @tool mode
	var flames := get_node_or_null("Flames") as GPUParticles3D
	var light := get_node_or_null("Light") as OmniLight3D

	if not flames or not light:
		return

	# 1. Scale QuadMesh
	if flames.draw_pass_1 is QuadMesh:
		var mesh := flames.draw_pass_1 as QuadMesh
		mesh.size = BASE_MESH_SIZE * fire_scale

	# 2. Scale Particle Velocities
	if flames.process_material is ParticleProcessMaterial:
		var mat := flames.process_material as ParticleProcessMaterial
		mat.initial_velocity_min = BASE_VELOCITY_MIN * fire_scale
		mat.initial_velocity_max = BASE_VELOCITY_MAX * fire_scale

	# 3. Adjust Particle Count & Light
	flames.amount = clampi(int(BASE_AMOUNT * fire_scale), 4, 100)
	light.omni_range = BASE_LIGHT_RANGE * fire_scale
	light.light_energy = BASE_LIGHT_ENERGY * sqrt(fire_scale)

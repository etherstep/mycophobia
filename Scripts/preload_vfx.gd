extends Node3D

@export var salt: Node3D
@export var fire: Node3D
@export var smoke: StaticBody3D

var particles: Array[GPUParticles3D] = []

func _ready() -> void:
	var scenes: Array[Node] = [salt, fire, smoke]
	for scene in scenes:
		if scene:
			find_gpu_particles(scene)
	for particle in particles:
		particle.emitting = true
	await get_tree().create_timer(4.0).timeout

func find_gpu_particles(node: Node) -> void:
	if node is GPUParticles3D:
		particles.append(node)
	for child in node.get_children():
		find_gpu_particles(child)

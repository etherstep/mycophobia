extends Control

const WORLD_SCENE_PATH := "res://Scenes/world.tscn"
const EFFECT_DURATION := 5.0

@onready var loading_label: Label = $LoadingLabel
@onready var progress_bar: ProgressBar = $ProgressBar
var target_progress: float = 0.0
var displayed_progress: float = 0.0
const PROGRESS_SPEED := 5.0

var particles: Array[GPUParticles3D] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading_label.text = "Loading your experience..."
	progress_bar.value = 0.0

	# Allow the loading screen to render.
	await get_tree().process_frame
	await get_tree().process_frame

	var error := ResourceLoader.load_threaded_request(WORLD_SCENE_PATH)

	if error != OK:
		loading_label.text = "COULD NOT START LOADING"
		push_error("Threaded load request failed: %s" % error)
		return

	# Wait until the world has loaded.
	while true:
		var progress: Array = []
		var status := ResourceLoader.load_threaded_get_status(
			WORLD_SCENE_PATH, progress
		)

		if not progress.is_empty():
			target_progress = progress[0] * 100.0

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			target_progress = 100.0
		elif status == ResourceLoader.THREAD_LOAD_FAILED \
		or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			loading_label.text = "LOADING FAILED - CHECK DEBUGGER"
			push_error("Failed to load: " + WORLD_SCENE_PATH)
			return

		# Smoothly move the visible bar toward the reported progress.
		displayed_progress = move_toward(
			displayed_progress,
			target_progress,
			PROGRESS_SPEED * get_process_delta_time()
		)
		progress_bar.value = displayed_progress

		# Don't exit until loading is complete AND the bar reaches 100%.
		if status == ResourceLoader.THREAD_LOAD_LOADED \
		and displayed_progress >= 99.9:
			break

		await get_tree().process_frame

	progress_bar.value = 100.0

	var packed_scene := ResourceLoader.load_threaded_get(
		WORLD_SCENE_PATH
	) as PackedScene

	if packed_scene == null:
		loading_label.text = "FAILED TO LOAD WORLD"
		push_error("The loaded world scene is not a PackedScene.")
		return

	# Instantiate the world.
	var world := packed_scene.instantiate()
	var tree := get_tree()
	var old_scene := tree.current_scene

	tree.root.add_child(world)
	tree.current_scene = world

	# Allow the world and its nodes to initialize.
	await get_tree().process_frame

	# Warm up rendering while the loading screen is visible.
	await warm_up_world(world)

	# Find all GPUParticles3D nodes in the world.
	# Find only the Loading node.
	var loading_node := world.find_child("Loading", true, false) as Node3D

	if loading_node:
		find_gpu_particles(loading_node)
	else:
		push_warning("Node3D named 'Loading' was not found in world.")

	# Start every particle effect.
	for particle in particles:
		particle.emitting = true

	# Keep the loading screen visible while effects play.
	loading_label.text = "Enjoy the ride :P"
	progress_bar.value = 100.0

	await get_tree().create_timer(EFFECT_DURATION).timeout

	# Stop emitting new particles.
	for particle in particles:
		if is_instance_valid(particle):
			particle.emitting = false

	# Remove the loading screen.
	if is_instance_valid(old_scene):
		old_scene.queue_free()

func find_gpu_particles(node: Node) -> void:
	if node is GPUParticles3D:
		particles.append(node)

	for child in node.get_children():
		find_gpu_particles(child)

func warm_up_world(world: Node3D) -> void:
	var loading_node := world.find_child("Loading", true, false) as Node3D
	if loading_node == null:
		push_warning("Loading node not found; skipping warm-up.")
		return

	var camera := loading_node.find_child("Camera3D", true, false) as Camera3D
	if camera == null:
		push_warning("Camera3D not found under Loading.")
		return

	# Save the current gameplay camera BEFORE switching.
	var viewport := get_viewport()
	var gameplay_camera := viewport.get_camera_3d()

	# Save the temporary camera's original transform.
	var original_position := camera.position
	var original_rotation := camera.rotation

	# Switch to the temporary warm-up camera.
	camera.position = Vector3(-257, 21, -24)
	camera.rotation_degrees = Vector3(0, 90, 0)
	camera.make_current()

	# Let the renderer process the view.
	for i in range(10):
		await get_tree().process_frame

	# Restore the temporary camera's transform.
	camera.position = original_position
	camera.rotation = original_rotation

	# Restore the gameplay camera.
	if is_instance_valid(gameplay_camera):
		gameplay_camera.make_current()
	else:
		camera.current = false

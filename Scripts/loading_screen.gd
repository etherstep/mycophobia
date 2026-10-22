extends Control

const WORLD_SCENE_PATH := "res://Scenes/world.tscn"

@onready var loading_label: Label = $LoadingLabel
@onready var progress_bar: ProgressBar = $ProgressBar


func _ready() -> void:
	# Ensure the loading UI is visible.
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

	while true:
		var progress: Array = []
		var status := ResourceLoader.load_threaded_get_status(
			WORLD_SCENE_PATH,
			progress
		)

		if not progress.is_empty():
			progress_bar.value = progress[0] * 100.0

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break

		if status == ResourceLoader.THREAD_LOAD_FAILED \
		or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			loading_label.text = "LOADING FAILED - CHECK DEBUGGER"
			push_error("Failed to load: " + WORLD_SCENE_PATH)
			return

		await get_tree().process_frame

	loading_label.text = "Enjoy the ride :P"
	progress_bar.value = 100.0

	var packed_scene := ResourceLoader.load_threaded_get(WORLD_SCENE_PATH) as PackedScene

	if packed_scene == null:
		loading_label.text = "FAILED TO LOAD WORLD"
		push_error("The loaded world scene is not a PackedScene.")
		return

	var world := packed_scene.instantiate()

	var tree := get_tree()
	var old_scene := tree.current_scene

	tree.root.add_child(world)
	tree.current_scene = world

	# Allow the world to initialize across multiple frames.
	await tree.process_frame
	await tree.process_frame
	await tree.process_frame

	# Remove the loading screen after initialization.
	if is_instance_valid(old_scene):
		old_scene.queue_free()

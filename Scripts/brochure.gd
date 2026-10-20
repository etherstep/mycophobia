extends Control

var scene_changing := false
@export var skip_text: Label

var fade_screen: ColorRect


func _ready() -> void:
	# Start with the screen covered in black.
	fade_screen = ColorRect.new()
	fade_screen.color = Color.BLACK
	fade_screen.modulate.a = 1.0
	fade_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_screen.z_index = 100
	add_child(fade_screen)

	skip_text.modulate.a = 0.0

	MusicManager.play_brochure_sequence()

	# Allow the scene to finish a frame before fading in.
	await get_tree().process_frame
	await get_tree().process_frame

	var tween := create_tween()
	tween.tween_property(fade_screen, "modulate:a", 0.0, 1.5)
	await tween.finished

	await get_tree().create_timer(5.0).timeout
	if scene_changing:
		return

	skip_text.visible = true
	fade_skip_text()

	await get_tree().create_timer(85.0).timeout
	go_to_world()


func fade_skip_text() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(skip_text, "modulate:a", 0.25, 1.5)
	tween.tween_property(skip_text, "modulate:a", 1.0, 1.5)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		go_to_world()

func go_to_world() -> void:
	if scene_changing:
		return

	scene_changing = true
	MusicManager.stop_brochure_sequence()

	# Fade out to black
	fade_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(fade_screen, "modulate:a", 1.0, 1.5)
	await tween.finished

	get_tree().change_scene_to_file("res://Scenes/world.tscn")

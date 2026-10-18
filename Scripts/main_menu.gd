extends Control

var starting_game := false

func _on_new_game_pressed() -> void:
	if starting_game:
		return

	starting_game = true

	var black_screen := ColorRect.new()
	black_screen.color = Color.BLACK
	black_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	black_screen.z_index = 100
	add_child(black_screen)

	MusicManager.play_starting_effect()

	await get_tree().create_timer(5.0).timeout

	get_tree().change_scene_to_file("res://Scenes/brochure.tscn")
	#get_tree().change_scene_to_file("res://Scenes/world.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/options_menu.tscn")

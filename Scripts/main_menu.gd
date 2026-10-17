
extends Control

func _on_new_game_pressed() -> void:
	MusicManager.play_game_music()
	get_tree().change_scene_to_file("res://Scenes/world.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/options_menu.tscn")

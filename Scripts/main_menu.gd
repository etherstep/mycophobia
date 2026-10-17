extends Control

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/world.tscn")
	pass # Replace with function body.


func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/options_menu.tscn")
	pass # Replace with function body.

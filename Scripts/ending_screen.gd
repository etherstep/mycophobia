extends Control

@export var main_menu_button: Button
@export var button_hover_sfx: AudioStream
@export var button_pressed_sfx: AudioStream

@onready var end_screen_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	main_menu_button.mouse_entered.connect(_on_play_again_hovered)
	main_menu_button.mouse_exited.connect(_on_play_again_unhovered)
	if end_screen_player:
		MusicManager.stop_game_ambience()
		end_screen_player.play()

func _on_play_again_hovered() -> void:
	main_menu_button.text = "< MAIN MENU >"
	MusicManager.play_ui_sfx(button_hover_sfx)

func _on_play_again_unhovered() -> void:
	main_menu_button.text = "MAIN MENU"

func _on_play_again_button_pressed() -> void:
	MusicManager.play_ui_sfx(button_pressed_sfx)
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

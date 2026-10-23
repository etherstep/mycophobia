extends Control

@export var play_again_button: Button
@export var button_hover_sfx: AudioStream
@export var button_pressed_sfx: AudioStream

@onready var death_screen_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	play_again_button.mouse_entered.connect(_on_play_again_hovered)
	play_again_button.mouse_exited.connect(_on_play_again_unhovered)

	if death_screen_player:
		MusicManager.stop_game_ambience()
		death_screen_player.play()

func _on_play_again_hovered() -> void:
	play_again_button.text = "< PLAY AGAIN >"
	MusicManager.play_ui_sfx(button_hover_sfx)

func _on_play_again_unhovered() -> void:
	play_again_button.text = "PLAY AGAIN"

func _on_play_again_button_pressed() -> void:
	MusicManager.play_ui_sfx(button_pressed_sfx)
	get_tree().change_scene_to_file("res://Scenes/world.tscn")

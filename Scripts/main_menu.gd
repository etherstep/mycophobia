extends Control

var starting_game := false

@export var button_hover_sfx: AudioStream
@export var button_pressed_sfx: AudioStream
@export var new_game_button: Button
@export var options_button: Button

func _ready() -> void:
	new_game_button.mouse_entered.connect(_on_button_hovered)
	options_button.mouse_entered.connect(_on_button_hovered)
	new_game_button.pressed.connect(_on_button_pressed)
	options_button.pressed.connect(_on_button_pressed)

func _on_button_hovered() -> void:
	MusicManager.play_ui_sfx(button_hover_sfx)

func _on_button_pressed() -> void:
	MusicManager.play_ui_sfx(button_pressed_sfx)

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
	
	MusicManager.lower_menu_music()
	MusicManager.play_starting_effect()
	
	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file("res://Scenes/brochure.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/options_menu.tscn")

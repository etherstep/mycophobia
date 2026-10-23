extends Control

var starting_game := false

@export var button_hover_sfx: AudioStream
@export var button_pressed_sfx: AudioStream
@export var new_game_button: Button
@export var options_button: Button

const start_game_focus_text: String = "< START GAME >"
const start_game_text: String = "START GAME"
const options_focus_text: String = "< OPTIONS >"
const options_text: String = "OPTIONS"

func _ready() -> void:
	new_game_button.mouse_entered.connect(_on_new_game_hovered)
	new_game_button.mouse_exited.connect(_on_new_game_unhovered)
	options_button.mouse_entered.connect(_on_options_hovered)
	options_button.mouse_exited.connect(_on_options_unhovered)
	fade_in()

func fade_in() -> void:
	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.z_index = 100
	add_child(fade)
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 1.5)
	await tween.finished
	fade.queue_free()

func _on_new_game_hovered() -> void:
	new_game_button.text = start_game_focus_text
	MusicManager.play_ui_sfx(button_hover_sfx)

func _on_new_game_unhovered() -> void:
	new_game_button.text = start_game_text

func _on_options_hovered() -> void:
	options_button.text = options_focus_text
	MusicManager.play_ui_sfx(button_hover_sfx)

func _on_options_unhovered() -> void:
	options_button.text = options_text

func _on_new_game_button_pressed() -> void:
	_on_new_game_pressed()

func _on_options_button_pressed() -> void:
	_on_options_pressed()

func _on_new_game_pressed() -> void:
	if starting_game:
		return

	starting_game = true

	var black_screen := ColorRect.new()
	black_screen.color = Color.BLACK
	black_screen.modulate.a = 0.0
	black_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	black_screen.z_index = 100
	add_child(black_screen)

	var tween := create_tween()
	tween.tween_property(black_screen, "modulate:a", 1.0, 1.5)

	MusicManager.lower_menu_music()
	MusicManager.play_starting_effect()

	await tween.finished
	await get_tree().create_timer(5.0).timeout

	get_tree().change_scene_to_file("res://Scenes/brochure.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/options_menu.tscn")

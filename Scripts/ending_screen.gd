extends Control

const FADE_DURATION := 0.8
const TEXTURE_DISPLAY_DURATION := 3.0
const MAIN_MENU_SCENE := "res://Scenes/main_menu.tscn"

@export var main_menu_button: Button
@export var button_hover_sfx: AudioStream
@export var button_pressed_sfx: AudioStream

@onready var end_screen_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var end_screen_video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var texture_rect: TextureRect = $TextureRect
@onready var fade_rect: ColorRect = $FadeRect

var _changing_scene := false
var _transitioning := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	main_menu_button.hide()
	texture_rect.hide()

	# Start with a black overlay.
	fade_rect.visible = true
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 1.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	main_menu_button.mouse_entered.connect(_on_play_again_hovered)
	main_menu_button.mouse_exited.connect(_on_play_again_unhovered)
	main_menu_button.pressed.connect(_on_play_again_button_pressed)
	end_screen_video_player.finished.connect(_on_video_finished)

	if end_screen_player:
		MusicManager.stop_game_ambience()
		end_screen_player.play()

	end_screen_video_player.play()

	await _fade_in()


func _fade_in() -> void:
	fade_rect.visible = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()
	tween.tween_property(
		fade_rect,
		"modulate:a",
		0.0,
		FADE_DURATION
	)

	await tween.finished

	if is_inside_tree():
		fade_rect.visible = false
		fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _fade_out() -> void:
	fade_rect.visible = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_rect.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(
		fade_rect,
		"modulate:a",
		1.0,
		FADE_DURATION
	)

	await tween.finished


func _on_video_finished() -> void:
	if _transitioning or _changing_scene:
		return

	_transitioning = true

	# Fade out the video.
	await _fade_out()

	if not is_inside_tree():
		return

	end_screen_video_player.hide()
	texture_rect.show()

	# Fade in the texture.
	await _fade_in()

	# Keep the texture visible for the intended duration.
	await get_tree().create_timer(TEXTURE_DISPLAY_DURATION).timeout

	if not is_inside_tree():
		return

	# Fade to black before switching to the button.
	await _fade_out()

	if not is_inside_tree():
		return

	texture_rect.hide()
	main_menu_button.show()

	# Fade in the button.
	await _fade_in()

	_transitioning = false


func _on_play_again_hovered() -> void:
	main_menu_button.text = "< MAIN MENU >"
	MusicManager.play_ui_sfx(button_hover_sfx)


func _on_play_again_unhovered() -> void:
	main_menu_button.text = "MAIN MENU"


func _on_play_again_button_pressed() -> void:
	if _changing_scene or _transitioning:
		return

	_changing_scene = true
	main_menu_button.disabled = true

	MusicManager.play_ui_sfx(button_pressed_sfx)

	await _fade_out()

	if is_inside_tree():
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)


extends Node3D

const OPTIONS_SCENE = preload("res://Scenes/options_menu.tscn")

var _options_layer: CanvasLayer

@export var player: Player

var help_label: Label


func _ready() -> void:
	MusicManager.play_game_ambience()
	Settings.apply_gamma($WorldEnvironment)

	if player != null:
		help_label = player.get_node("HUD/HelpLabel") as Label
		help_label.visible = true
		help_label.modulate.a = 0.0

		await get_tree().create_timer(5.0).timeout

		if is_instance_valid(help_label):
			help_label.modulate.a = 1.0


func _unhandled_input(event: InputEvent) -> void:
	if _options_layer != null:
		return
	if event.is_action_pressed("flashlight") and help_label != null:
		help_label.hide()
	if event.is_action_pressed("ui_cancel"):
		_open_options()
		get_viewport().set_input_as_handled()

func _open_options() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_options_layer = CanvasLayer.new()
	_options_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_options_layer)
	var menu := OPTIONS_SCENE.instantiate()
	menu.opened_from_game = true
	menu.closed.connect(_close_options)
	_options_layer.add_child(menu)

func _close_options() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_options_layer.queue_free()
	_options_layer = null

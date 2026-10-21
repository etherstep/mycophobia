extends Node3D

const OPTIONS_SCENE = preload("res://Scenes/options_menu.tscn")

var _options_layer: CanvasLayer

func _ready() -> void:
	MusicManager.play_game_ambience()
	Settings.apply_gamma($WorldEnvironment)

func _unhandled_input(event: InputEvent) -> void:
	if _options_layer != null:
		return
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

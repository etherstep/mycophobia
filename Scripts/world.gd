extends Node3D

const OPTIONS_SCENE = preload("res://Scenes/options_menu.tscn")

var _options_layer: CanvasLayer

@export var player: Player

var help_label: Label
signal game_loaded


func _ready() -> void:
	var start_time := Time.get_ticks_msec()

	MusicManager.play_game_ambience()
	print("MusicManager: ", Time.get_ticks_msec() - start_time, " ms")

	var gamma_start := Time.get_ticks_msec()
	Settings.apply_gamma($WorldEnvironment)
	print("Apply gamma: ", Time.get_ticks_msec() - gamma_start, " ms")

	if player != null:
		var player_start := Time.get_ticks_msec()

		help_label = player.get_node("HUD/HelpLabel") as Label
		help_label.visible = true
		help_label.modulate.a = 0.0

		print("Player setup: ", Time.get_ticks_msec() - player_start, " ms")

		await get_tree().create_timer(10.0).timeout

		if is_instance_valid(help_label):
			help_label.modulate.a = 1.0

		game_loaded.emit()

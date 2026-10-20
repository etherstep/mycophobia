extends Node

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_SENSITIVITY := 0.0022
const DEFAULT_GAMMA := 1.0
const DEFAULT_MUSIC_VOLUME := 50.0
const DEFAULT_GAME_VOLUME := 100.0

var mouse_sensitivity := DEFAULT_SENSITIVITY
var gamma := DEFAULT_GAMMA
var music_volume := DEFAULT_MUSIC_VOLUME
var game_volume := DEFAULT_GAME_VOLUME

func _ready() -> void:
	load_settings()
	apply_volume()

func load_settings() -> void:
	var config := ConfigFile.new()

	if config.load(SETTINGS_PATH) != OK:
		return

	mouse_sensitivity = float(
		config.get_value("controls", "mouse_sensitivity", DEFAULT_SENSITIVITY)
	)
	gamma = float(
		config.get_value("display", "gamma", DEFAULT_GAMMA)
	)
	music_volume = float(
		config.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME)
	)
	game_volume = float(
		config.get_value("audio", "game_volume", DEFAULT_GAME_VOLUME)
	)

func save_settings() -> void:
	var config := ConfigFile.new()

	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("display", "gamma", gamma)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "game_volume", game_volume)

	config.save(SETTINGS_PATH)

func apply_volume() -> void:
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus >= 0:
		AudioServer.set_bus_volume_db(
			music_bus,
			music_volume_to_db(music_volume)
		)

	var game_bus := AudioServer.get_bus_index("Game")
	if game_bus >= 0:
		AudioServer.set_bus_volume_db(
			game_bus,
			game_volume_to_db(game_volume)
		)

func music_volume_to_db(percent: float) -> float:
	return lerpf(-80.0, 6.0, clampf(percent / 100.0, 0.0, 1.0))


func game_volume_to_db(percent: float) -> float:
	var normalized := clampf(percent / 100.0, 0.0, 1.0)
	if normalized <= 0.0:
		return -80.0
	return linear_to_db(normalized)

func apply_gamma(world_environment: WorldEnvironment) -> void:
	if world_environment.environment == null:
		world_environment.environment = Environment.new()

	world_environment.environment.adjustment_enabled = true
	world_environment.environment.adjustment_brightness = gamma

func apply_gamma_to_open_world() -> void:
	var world_environment := get_tree().root.find_child(
		"WorldEnvironment", true, false
	)

	if world_environment is WorldEnvironment:
		apply_gamma(world_environment)

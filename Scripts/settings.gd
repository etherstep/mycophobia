extends Node

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_SENSITIVITY := 0.0022
const DEFAULT_GAMMA := 1.0
const DEFAULT_VOLUME := 1.0

var mouse_sensitivity := DEFAULT_SENSITIVITY
var gamma := DEFAULT_GAMMA
var volume := DEFAULT_VOLUME

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_settings()
	apply_volume()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	mouse_sensitivity = float(config.get_value("controls", "mouse_sensitivity", DEFAULT_SENSITIVITY))
	gamma = float(config.get_value("display", "gamma", DEFAULT_GAMMA))
	volume = float(config.get_value("audio", "volume", DEFAULT_VOLUME))

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("display", "gamma", gamma)
	config.set_value("audio", "volume", volume)
	config.save(SETTINGS_PATH)

func apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	if volume <= 0.0:
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_mute(bus, false)
		AudioServer.set_bus_volume_db(bus, linear_to_db(volume))
		
func apply_gamma(world_environment: WorldEnvironment) -> void:
	if world_environment.environment == null:
		world_environment.environment = Environment.new()
	world_environment.environment.adjustment_enabled = true
	world_environment.environment.adjustment_brightness = gamma

func apply_gamma_to_open_world() -> void:
	var world_environment := get_tree().root.find_child("WorldEnvironment", true, false)
	if world_environment is WorldEnvironment:
		apply_gamma(world_environment)

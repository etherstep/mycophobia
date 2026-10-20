extends Control

signal closed
var opened_from_game := false

@onready var sensitivity_slider: HSlider = $VBoxContainer/SensitivityRow/SensitivitySlider
@onready var sensitivity_value: Label = $VBoxContainer/SensitivityRow/SensitivityValue
@onready var gamma_slider: HSlider = $VBoxContainer/GammaRow/GammaSlider
@onready var gamma_value: Label = $VBoxContainer/GammaRow/GammaValue
@onready var volume_slider: HSlider = $VBoxContainer/VolumeRow/VolumeSlider
@onready var volume_value: Label = $VBoxContainer/VolumeRow/VolumeValue

@export var button_hover_sfx: AudioStream
@export var button_pressed_sfx: AudioStream

@export var back_button: Button

const back_focus_text: String = "< BACK >"
const back_text: String = "BACK"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sensitivity_slider.step = 0.0001
	sensitivity_slider.value = Settings.mouse_sensitivity
	gamma_slider.value = Settings.gamma
	volume_slider.min_value = 0.0
	volume_slider.max_value = 100.0
	volume_slider.step = 1.0
	volume_slider.value = Settings.volume
	_show_sensitivity(sensitivity_slider.value)
	_show_gamma(gamma_slider.value)
	_show_volume(volume_slider.value)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	gamma_slider.value_changed.connect(_on_gamma_changed)
	volume_slider.value_changed.connect(_on_volume_changed)
	sensitivity_slider.mouse_entered.connect(_on_button_hovered)
	volume_slider.mouse_entered.connect(_on_button_hovered)
	gamma_slider.mouse_entered.connect(_on_button_hovered)
	back_button.mouse_entered.connect(_on_back_hovered)
	back_button.mouse_exited.connect(_on_back_unhovered)
	back_button.pressed.connect(_on_button_pressed)

func _on_back_hovered() -> void:
	back_button.text = back_focus_text
	MusicManager.play_ui_sfx(button_hover_sfx)

func _on_back_unhovered() -> void:
	back_button.text = back_text

func _on_button_hovered() -> void:
	MusicManager.play_ui_sfx(button_hover_sfx)

func _on_button_pressed() -> void:
	MusicManager.play_ui_sfx(button_pressed_sfx)

func _on_sensitivity_changed(value: float) -> void:
	Settings.mouse_sensitivity = value
	_show_sensitivity(value)
	Settings.save_settings()

func _on_gamma_changed(value: float) -> void:
	Settings.gamma = value
	_show_gamma(value)
	Settings.apply_gamma_to_open_world()
	Settings.save_settings()

func _on_volume_changed(value: float) -> void:
	Settings.volume = value

	var bus_index := AudioServer.get_bus_index("Music")
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(
			bus_index,
			Settings.volume_to_db(value)
		)

	_show_volume(value)
	Settings.save_settings()

func _show_volume(value: float) -> void:
	volume_value.text = "%d%%" % roundi(value)

func _show_sensitivity(value: float) -> void:
	sensitivity_value.text = "%.4f" % value

func _show_gamma(value: float) -> void:
	gamma_value.text = "%.2f" % value

func _on_back_pressed() -> void:
	if opened_from_game:
		closed.emit()
	else:
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

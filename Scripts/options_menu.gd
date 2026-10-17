extends Control

signal closed
var opened_from_game := false

@onready var sensitivity_slider: HSlider = $VBoxContainer/SensitivityRow/SensitivitySlider
@onready var sensitivity_value: Label = $VBoxContainer/SensitivityRow/SensitivityValue
@onready var gamma_slider: HSlider = $VBoxContainer/GammaRow/GammaSlider
@onready var gamma_value: Label = $VBoxContainer/GammaRow/GammaValue
@onready var volume_slider: HSlider = $VBoxContainer/VolumeRow/VolumeSlider
@onready var volume_value: Label = $VBoxContainer/VolumeRow/VolumeValue


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sensitivity_slider.step = 0.0001
	sensitivity_slider.value = Settings.mouse_sensitivity
	gamma_slider.value = Settings.gamma
	volume_slider.value = Settings.volume
	_show_sensitivity(sensitivity_slider.value)
	_show_gamma(gamma_slider.value)
	_show_volume(volume_slider.value)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	gamma_slider.value_changed.connect(_on_gamma_changed)
	volume_slider.value_changed.connect(_on_volume_changed)


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
	_show_volume(value)
	Settings.save_settings()


func _show_sensitivity(value: float) -> void:
	sensitivity_value.text = "%.4f" % value

func _show_gamma(value: float) -> void:
	gamma_value.text = "%.2f" % value

func _show_volume(value: float) -> void:
	volume_value.text = "%d%%" % roundi(value * 100.0)

func _on_back_pressed() -> void:
	if opened_from_game:
		closed.emit()
	else:
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

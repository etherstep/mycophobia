class_name DoorButton
extends StaticBody3D

@export var door: Door
@export_range(1.0, 120.0, 1.0) var timeout: float = 1.0
@export_range(1.0, 10.0, 0.1) var brightness: float = 1.0

@onready var timer: Timer = $Timer

@onready var button_body: MeshInstance3D = $Button

var is_active: bool = false
var door_opened: bool = false

var button_material: StandardMaterial3D = null

signal button_pressed

func _process(_delta: float) -> void:
	if not is_active:
		return
	var color_ratio: float = timer.time_left / timer.wait_time
	var g_value: float = color_ratio * 1
	var r_value: float = 1 - g_value
	var color: Color = Color(r_value, g_value, 0)
	set_button_color(color)

func _ready() -> void:
	door.door_opened.connect(_on_door_opened)
	timer.wait_time = timeout
	timer.one_shot = true
	timer.ignore_time_scale = true
	timer.timeout.connect(_on_timer_timeout)
	button_material = button_body.material_override as StandardMaterial3D
	if not button_material:
		button_material = StandardMaterial3D.new()
		button_body.material_override = button_material
	else:
		button_material = button_material.duplicate() as StandardMaterial3D
		button_body.material_override = button_material
	button_material.emission_enabled = true
	button_material.emission_energy_multiplier = brightness
	set_button_color(Color.RED)

func interact() -> void:
	if door_opened:
		return
	if not is_active:
		is_active = true
		timer.start()
		set_button_color(Color.GREEN)
		button_pressed.emit()
	else:
		is_active = false
		timer.stop()
		set_button_color(Color.RED)

func _on_timer_timeout() -> void:
	if door_opened:
		return
	is_active = false
	set_button_color(Color.RED)

func set_button_color(color: Color) -> void:
	button_material.albedo_color = color
	button_material.emission = color

func _on_door_opened() -> void:
	door_opened = true
	set_button_color(Color.GREEN)
	set_process(false)

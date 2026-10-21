class_name Door
extends AnimatableBody3D

## Local direction and distance to slide when opening (e.g., slide 2 units on X)
@export var open_offset: Vector3 = Vector3(2.0, 0.0, 0.0)
@export var slide_duration: float = 1.0
@export var buttons: Array[DoorButton]

var is_open: bool = false
var closed_position: Vector3
var open_position: Vector3
var tween: Tween

signal door_opened

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	closed_position = position
	open_position = closed_position + open_offset
	_connect_to_button_signals()

func _connect_to_button_signals() -> void:
	for button in buttons:
		button.button_pressed.connect(_on_button_pressed)
	pass

func _on_button_pressed() -> void:
	for button in buttons:
		if not button.is_active:
			return
	is_open = true
	door_opened.emit()
	open_door()

func open_door() -> void:
	is_open = true
	_animate_slide(open_position)

func close_door() -> void:
	is_open = false
	_animate_slide(closed_position)

func _animate_slide(target_position: Vector3) -> void:
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target_position, slide_duration)

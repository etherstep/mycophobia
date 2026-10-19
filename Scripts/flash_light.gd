extends SpotLight3D

signal flashlight_visibility_changed(is_visible: bool)

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	flashlight_visibility_changed.emit(visible)

extends Area3D

@export var enemy: Node


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and enemy != null and enemy.has_method("alert"):
		enemy.alert(global_position)

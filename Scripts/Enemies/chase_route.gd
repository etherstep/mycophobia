extends Area3D

@export var enemy: Node
@export var ends_chase := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or enemy == null or not is_instance_valid(enemy):
		return
	if ends_chase:
		if enemy.has_method("end_committed_chase"):
			enemy.end_committed_chase()
	elif enemy.has_method("begin_committed_chase"):
		enemy.begin_committed_chase()

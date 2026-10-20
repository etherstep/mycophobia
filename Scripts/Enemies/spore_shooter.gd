extends StaticBody3D

@export var cloud: Node3D


func interact() -> void:
	var inventory := get_tree().get_first_node_in_group("inventory") as Inventory
	if inventory == null:
		return
	if not inventory.has_type(ItemData.ItemType.SALT):
		return
	if not inventory.has_type(ItemData.ItemType.MATCHES):
		return
	inventory.remove_one(ItemData.ItemType.SALT)
	inventory.remove_one(ItemData.ItemType.MATCHES)
	if is_instance_valid(cloud):
		cloud.queue_free()
	queue_free()

extends StaticBody3D

@export var cloud: Node3D

func interact() -> void:
	var inventory := get_tree().get_first_node_in_group("inventory") as Inventory

	if inventory == null:
		return

	# Make sure the target still exists.
	if not is_instance_valid(cloud):
		return

	# Step 1: Salt the spore shooter.
	if not inventory.has_type(ItemData.ItemType.SALT):
		return

	#if cloud.has_method("apply_salted") and not cloud.is_salted():
		#cloud.apply_salted()
		#inventory.remove_one_item_by_type(ItemData.ItemType.SALT)
		#return

	# Step 2: Use matches to kill the salted spore shooter.
	if not inventory.has_type(ItemData.ItemType.MATCHES):
		return

	#if cloud.has_method("is_salted") and cloud.is_salted():
		#cloud.kill_by_matches()
		#inventory.remove_one_item_by_type(ItemData.ItemType.MATCHES)
		#queue_free()

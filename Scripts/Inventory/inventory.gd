extends Node
class_name Inventory

signal inventory_changed

@export var max_slots: int = 9

var items: Array[ItemData] = []

func add_item(item: ItemData) -> bool:
	if item == null:
		return false

	if items.size() >= max_slots:
		print("Inventory is full!")
		return false

	items.append(item)
	inventory_changed.emit()

	print("Added to inventory: ", item.name)
	return true

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

	#if items.
	items.append(item)
	inventory_changed.emit()

	print("Added to inventory: ", item.name)
	return true


func has_type(type: ItemData.ItemType) -> bool:
	for item in items:
		if item != null and item.item_type == type:
			return true
	return false


func remove_one(type: ItemData.ItemType) -> bool:
	for i in items.size():
		var item: ItemData = items[i]
		if item != null and item.item_type == type:
			items.remove_at(i)
			inventory_changed.emit()
			return true
	return false

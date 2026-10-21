extends Node
class_name Inventory

signal inventory_changed

#@export var note_interact_sfx: AudioStream
@export var salt_use_sfx: AudioStream
@export var matches_use_sfx: AudioStream
@export var saline_use_sfx: AudioStream
@export var syringe_use_sfx: AudioStream

@export var player: Player

class ItemStack:
	var item: ItemData
	var quantity: int

	func _init(new_item: ItemData, amount: int = 1) -> void:
		item = new_item
		quantity = amount

@export var max_slots: int = 9
@export var items: Array[ItemData] = []
var quantities: Array[int] = []

func add_item(item: ItemData) -> bool:
	if item == null:
		return false

	if item.stackable:
		for i in range(items.size()):
			if items[i] == item and quantities[i] < item.stack_limit:
				quantities[i] += 1
				inventory_changed.emit()
				return true

	if items.size() >= max_slots:
		return false

	items.append(item)
	quantities.append(1)
	inventory_changed.emit()
	return true

func has_type(type: ItemData.ItemType) -> bool:
	for item in items:
		if item != null and item.item_type == type:
			return true
	return false

func remove_one_item(item: ItemData) -> void:
	for i in range(items.size()):
		if items[i] == item:
			if quantities[i] > 1:
				quantities[i] -= 1
			else:
				items.remove_at(i)
				quantities.remove_at(i)
			if item.item_type == ItemData.ItemType.SALT:
				MusicManager.play_player_dialogue(salt_use_sfx)

			if item.item_type == ItemData.ItemType.MATCHES:
				MusicManager.play_player_dialogue(matches_use_sfx)

			if item.item_type == ItemData.ItemType.SALINE:
				MusicManager.play_player_dialogue(saline_use_sfx)

			if item.item_type == ItemData.ItemType.SYRINGE:
				player.increase_infection(100)
				MusicManager.play_player_dialogue(syringe_use_sfx)
			inventory_changed.emit()
			return

func remove_one_item_by_type(type: ItemData.ItemType) -> bool:
	for i in range(items.size()):
		var item := items[i]

		if item != null and item.item_type == type:
			if quantities[i] > 1:
				quantities[i] -= 1
			else:
				items.remove_at(i)
				quantities.remove_at(i)

			if type == ItemData.ItemType.SALT:
				MusicManager.play_player_dialogue(salt_use_sfx)
			elif type == ItemData.ItemType.MATCHES:
				MusicManager.play_player_dialogue(matches_use_sfx)
			elif type == ItemData.ItemType.SALINE:
				MusicManager.play_player_dialogue(saline_use_sfx)
			elif type == ItemData.ItemType.SYRINGE:
				player.increase_infection(100)
				MusicManager.play_player_dialogue(syringe_use_sfx)

			inventory_changed.emit()
			return true

	return false

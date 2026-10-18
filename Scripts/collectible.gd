extends Area3D

@export var item_data: ItemData
@export var sprite: Sprite3D
@export var label: Label3D
@export var note_interact_sfx: AudioStream

const BASE_SCALE = Vector3(0.15, 0.15, 0.15)
var original_modulate: Color

func _ready() -> void:
	if item_data == null:
		return
	sprite.texture = item_data.texture
	scale = BASE_SCALE
	label.text = item_data.text
	original_modulate = sprite.modulate

func interact() -> void:
	if item_data == null:
		return
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory == null:
		print("No Inventory node found in the 'inventory' group.")
		return
	if inventory.add_item(item_data):
		if item_data.item_type == ItemData.ItemType.NOTE:
			MusicManager.play_sfx(note_interact_sfx)
		queue_free()

func set_hovered(hovered: bool) -> void:
	if hovered:
		sprite.modulate = Color("ffffffff")
	else:
		sprite.modulate = original_modulate

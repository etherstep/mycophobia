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
		push_warning("No Inventory node found in the 'inventory' group.")
		return
	if not inventory.add_item(item_data):
		return
	if item_data.item_type == ItemData.ItemType.NOTE:
		MusicManager.play_world_sfx(note_interact_sfx)
		var note_viewer = get_tree().get_first_node_in_group("note_viewer")
		if note_viewer:
			note_viewer.open_note(item_data)
		else:
			push_warning("No NoteViewer found in the 'note_viewer' group.")
	queue_free()

func set_hovered(hovered: bool) -> void:
	if hovered:
		sprite.modulate = Color("c3c1b4ff")
	else:
		sprite.modulate = original_modulate

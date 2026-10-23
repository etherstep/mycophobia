@tool
extends Area3D

@export var item_data: ItemData:
	set(value):
		item_data = value
		_update_collectible()

@export var sprite: Sprite3D
@export var sprite_outline: Sprite3D
@export var label: Label3D
@export var note_interact_sfx: AudioStream
@export var salt_interact_sfx: AudioStream
@export var matches_interact_sfx: AudioStream
@export var saline_interact_sfx: AudioStream
@export var syringe_interact_sfx: AudioStream

const BASE_SCALE = Vector3(0.02, 0.02, 0.02)
var original_modulate: Color = Color.WHITE


func _ready() -> void:
	_update_collectible()
	original_modulate = sprite.modulate if sprite else Color.WHITE

	if sprite_outline:
		sprite_outline.visible = false


func _update_collectible() -> void:
	if not is_inside_tree():
		return

	if item_data == null:
		if sprite:
			sprite.texture = null
		if sprite_outline:
			sprite_outline.texture = null	
		if label:
			label.text = ""
		return

	if sprite:
		sprite.texture = item_data.texture

	if sprite_outline:
		sprite_outline.texture = item_data.texture_outline

	if label:
		label.text = item_data.name

	scale = BASE_SCALE


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

	if item_data.item_type == ItemData.ItemType.SALT:
		MusicManager.play_world_sfx(salt_interact_sfx)

	if item_data.item_type == ItemData.ItemType.MATCHES:
		MusicManager.play_world_sfx(matches_interact_sfx)

	if item_data.item_type == ItemData.ItemType.SALINE:
		MusicManager.play_world_sfx(saline_interact_sfx)

	if item_data.item_type == ItemData.ItemType.SYRINGE:
		MusicManager.play_world_sfx(syringe_interact_sfx)
	queue_free()

func set_hovered(hovered: bool) -> void:
	if sprite:
		if hovered:
			sprite.modulate = Color("c3c1b4ff")
		else:
			sprite.modulate = original_modulate
	if sprite_outline:
		sprite_outline.visible = hovered

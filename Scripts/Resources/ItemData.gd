extends Resource
class_name ItemData

enum ItemType { ITEM, NOTE }

@export var name : String = ""
@export var item_type: ItemType = ItemType.ITEM
@export var stack_limit : int = 1
@export var texture : Texture2D

@export_multiline var text: String = ""

# Set this to note_1, note_2, note_3, or note_4.
@export_enum("note_1", "note_2", "note_3", "note_4")
var note_id: String = "note_1"

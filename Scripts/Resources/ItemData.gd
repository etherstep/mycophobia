extends Resource
class_name ItemData

enum ItemType { SYRINGE, MATCHES, SALT, SALINE, NOTE }

enum ItemEffect {
	NONE,
	CURE_INFECTION,
	SALT_ENEMY,
	KILL_SALTED_ENEMY,
	APPLY_SYRINGE
}

@export var item_effect: ItemEffect = ItemEffect.NONE
@export_range(0.0, 100.0, 1.0) var infection_cure_amount: float = 50.0
@export var consume_on_use: bool = true

@export var name : String = ""
@export var item_type: ItemType = ItemType.NOTE
@export var stack_limit : int = 1
@export var texture : Texture2D
@export var texture_outline : Texture2D
@export var stackable: bool = false
@export_multiline var text: String = ""

# Set this to note_1, note_2, note_3, or note_4.
@export_enum("note_1", "note_2", "note_3", "note_4")
var note_id: String = "note_1"

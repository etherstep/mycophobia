extends Resource
class_name ItemData

enum ItemType { ITEM, NOTE }

@export var name : String = ""
@export var item_type: ItemType = ItemType.ITEM
@export var stack_limit : int = 1
@export var texture : Texture2D

@export_multiline var text: String = ""

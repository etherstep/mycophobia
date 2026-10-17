extends PanelContainer

@onready var icon: TextureRect = $TextureRect

var item: ItemData

func set_item(new_item: ItemData) -> void:
	item = new_item
	icon.texture = item.icon

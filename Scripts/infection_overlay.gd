extends TextureRect
@export var player: Player

const MAX_INFECTION: float = Player.MAX_INFECTION

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(player)
	modulate.a = 0.0
	player.infection_level_changed.connect(_on_infection_level_changed)
	
func _on_infection_level_changed(infection: float) -> void:
	var infection_percent: float = infection / MAX_INFECTION * 0.8
	modulate.a = infection_percent

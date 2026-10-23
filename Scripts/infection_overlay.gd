extends TextureRect
@export var player: Player

const MAX_INFECTION: float = Player.MAX_INFECTION
var infected_texture = preload("res://Assets/UI/Infection overlay.png") as CompressedTexture2D
var syringe_texture = preload("res://Assets/UI/Syringe use overlay.png") as CompressedTexture2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(player)
	texture = infected_texture
	modulate.a = 0.0
	player.infection_level_changed.connect(_on_infection_level_changed)
	player.inventory_ui.syringe_used.connect(_on_syringe_used)
	
func _on_infection_level_changed(infection: float) -> void:
	if player.syringe_used:
		return
	texture = infected_texture
	var infection_percent: float = infection / MAX_INFECTION * 0.8
	modulate.a = infection_percent

func _on_syringe_used() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0, 1.0)
	tween.finished.connect(_on_syringe_effects_start)

func _on_syringe_effects_start() -> void:
	texture = syringe_texture
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.8, 5.0)

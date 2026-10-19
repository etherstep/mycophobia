extends Node2D

@export var background: ColorRect
@export var meter: ColorRect
@export var player: Player

const MAX_INFECTION: float = Player.MAX_INFECTION

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	meter.size = meter.custom_minimum_size
	player.infection_level_changed.connect(_on_infection_level_changed)
	
func _on_infection_level_changed(infection: float) -> void:
	var infection_percent: float = infection / MAX_INFECTION
	var meter_width: float = infection_percent * meter.custom_maximum_size.x
	meter.size.x = meter_width

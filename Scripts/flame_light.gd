extends OmniLight3D

@export var base_energy: float = 2.0
@export var flicker_intensity: float = 0.5
@export var flicker_speed: float = 15.0

var noise := FastNoiseLite.new()
var time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	noise.seed = randi()
	noise.frequency = 0.1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta * flicker_speed
	var sample := noise.get_noise_1d(time)
	light_energy = base_energy + (sample * flicker_intensity)

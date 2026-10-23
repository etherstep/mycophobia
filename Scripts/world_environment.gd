extends WorldEnvironment

@export var target_density: float = 0.08
@export var transition_duration: float = 5.0

func increase_fog() -> void:
	var tween = create_tween()
	tween.tween_property(
		environment,
		"fog_density",
		target_density,
		transition_duration
	)

extends Area3D

@onready var sfx: AudioStreamPlayer3D = $AudioStreamPlayer3D

@export var fade_duration: float = 5.0

var fade_tween: Tween

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	sfx.volume_db = -30.0


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if fade_tween and fade_tween.is_running():
			fade_tween.kill()

		if not sfx.playing:
			sfx.volume_db = -30.0
			sfx.play()

		fade_tween = create_tween()
		fade_tween.tween_property(
			sfx, "volume_db", 0.0, fade_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		if fade_tween and fade_tween.is_running():
			fade_tween.kill()

		fade_tween = create_tween()
		fade_tween.tween_property(
			sfx, "volume_db", -30.0, fade_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

		fade_tween.tween_callback(sfx.stop)

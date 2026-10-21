extends Area3D

@onready var safe_house_music: AudioStreamPlayer3D = $AudioStreamPlayer3D

@export var fade_duration: float = 5.0
@export var silent_volume_db: float = -40.0

var fade_tween: Tween


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	safe_house_music.volume_db = silent_volume_db
	safe_house_music.stop()


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	if fade_tween and fade_tween.is_running():
		fade_tween.kill()

	if not safe_house_music.playing:
		safe_house_music.volume_db = silent_volume_db
		safe_house_music.play()

	fade_tween = create_tween()
	fade_tween.tween_property(
		safe_house_music,
		"volume_db",
		0.0,
		fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	if fade_tween and fade_tween.is_running():
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.tween_property(
		safe_house_music,
		"volume_db",
		silent_volume_db,
		fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	fade_tween.tween_callback(safe_house_music.stop)

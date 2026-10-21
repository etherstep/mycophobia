
extends Node3D

@export var ambience_sounds: Array[AudioStream] = []

@export_group("Timing")
@export var min_wait_time: float = 8.0
@export var max_wait_time: float = 25.0

@export_group("Fading")
@export var fade_in_time: float = 2.0
@export var fade_out_time: float = 3.0

@export_group("Playback")
@export var min_volume_db: float = -8.0
@export var max_volume_db: float = 0.0
@export var random_pitch: bool = false
@export var min_pitch: float = 0.9
@export var max_pitch: float = 1.1

@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var safe_house: Area3D = $"../SafeHouse"

var last_sound_index: int = -1
var player_in_safe_house: bool = false

func _ready() -> void:
	randomize()
	audio_player.volume_db = -40.0

	safe_house.body_entered.connect(_on_safe_house_body_entered)
	safe_house.body_exited.connect(_on_safe_house_body_exited)

	_play_ambience_loop()


func _on_safe_house_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_safe_house = true
		audio_player.stop()
		audio_player.volume_db = -40.0


func _on_safe_house_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_safe_house = false


func _play_ambience_loop() -> void:
	while is_inside_tree():
		if player_in_safe_house or ambience_sounds.is_empty():
			await get_tree().create_timer(1.0).timeout
			continue

		var wait_time := randf_range(min_wait_time, max_wait_time)
		await get_tree().create_timer(wait_time).timeout

		if not is_inside_tree():
			return

		# Check again after waiting.
		if player_in_safe_house:
			continue

		var sound_index := randi_range(0, ambience_sounds.size() - 1)

		if ambience_sounds.size() > 1:
			while sound_index == last_sound_index:
				sound_index = randi_range(0, ambience_sounds.size() - 1)

		last_sound_index = sound_index

		var selected_sound: AudioStream = ambience_sounds[sound_index]
		if selected_sound == null:
			continue

		audio_player.stream = selected_sound
		audio_player.volume_db = -40.0
		audio_player.pitch_scale = (
			randf_range(min_pitch, max_pitch)
			if random_pitch
			else 1.0
		)

		var target_volume := randf_range(min_volume_db, max_volume_db)
		var duration := selected_sound.get_length()

		if duration <= 0.0:
			push_warning("Ambience sound has no known duration.")
			continue

		var fade_in := minf(fade_in_time, duration * 0.5)
		var fade_out := minf(fade_out_time, duration * 0.5)

		audio_player.play()

		# Fade in.
		if fade_in > 0.0:
			var fade_in_tween := create_tween()
			fade_in_tween.tween_property(
				audio_player,
				"volume_db",
				target_volume,
				fade_in
			).from(-40.0)

			await fade_in_tween.finished
		else:
			audio_player.volume_db = target_volume

		# Stop immediately if the player enters the safe house.
		if player_in_safe_house:
			audio_player.stop()
			audio_player.volume_db = -40.0
			continue

		var remaining_time := maxf(0.0, duration - fade_in - fade_out)

		if remaining_time > 0.0:
			await get_tree().create_timer(remaining_time).timeout

		if not is_inside_tree():
			return

		if player_in_safe_house:
			audio_player.stop()
			audio_player.volume_db = -40.0
			continue

		# Fade out.
		if fade_out > 0.0 and audio_player.playing:
			var fade_out_tween := create_tween()
			fade_out_tween.tween_property(
				audio_player,
				"volume_db",
				-40.0,
				fade_out
			)
			await fade_out_tween.finished

		audio_player.stop()
		audio_player.volume_db = -40.0

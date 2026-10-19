extends AudioStreamPlayer

var sfx_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer
var starting_effect_player: AudioStreamPlayer
var brochure_player: AudioStreamPlayer
var world_player: AudioStreamPlayer

const STARTING_EFFECT: AudioStream = preload("res://Assets/SFX/UI/game-start.wav")
const BROCHURE_PART_1: AudioStream = preload("res://Assets/SFX/UI/brochure_part_1.mp3")

var menu_music_volume_db: float = 0.0
var music_tween: Tween

func _ready() -> void:
	stream = preload("res://Assets/Music/main_menu_theme.mp3")
	bus = "Music"
	play()

	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX-Movement"
	add_child(sfx_player)
	
	ui_player = AudioStreamPlayer.new()
	ui_player.bus = "SFX-UI"
	add_child(ui_player)

	starting_effect_player = AudioStreamPlayer.new()
	starting_effect_player.bus = "SFX-UI"
	add_child(starting_effect_player)

	brochure_player = AudioStreamPlayer.new()
	brochure_player.bus = "SFX-Dialogue"
	add_child(brochure_player)
	
	world_player = AudioStreamPlayer.new()
	world_player.bus = "SFX-World"
	add_child(world_player)

func play_game_music() -> void:
	var game_song = preload("res://Assets/Music/game_ambience.mp3")
	stream = game_song
	play()

func play_sfx(sound: AudioStream) -> void:
	if sound == null:
		return
	sfx_player.stream = sound
	sfx_player.play()

func play_world_sfx(sound: AudioStream) -> void:
	if sound == null:
		return
	world_player.stream = sound
	world_player.play()

func play_ui_sfx(sound: AudioStream) -> void:
	if sound == null:
		return
	ui_player.stream = sound
	ui_player.play()

func play_starting_effect() -> void:
	starting_effect_player.stream = STARTING_EFFECT
	starting_effect_player.play()

func play_brochure_sequence() -> void:
	brochure_player.stream = BROCHURE_PART_1
	brochure_player.play()

func stop_brochure_sequence() -> void:
	brochure_player.stop()

func lower_menu_music() -> void:
	_fade_music_to(-32.0)

func _fade_music_to(target_db: float) -> void:
	if music_tween and music_tween.is_running():
		music_tween.kill()

	music_tween = create_tween()
	music_tween.tween_property(self, "volume_db", target_db, 0.5)

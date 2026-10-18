extends AudioStreamPlayer

var sfx_player: AudioStreamPlayer

func _ready() -> void:
	stream = preload("res://Assets/Music/main_menu_theme.mp3")
	bus = "Music"
	play()
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX-Movement"
	add_child(sfx_player)

func play_game_music() -> void:
	var game_song = preload("res://Assets/Music/game_ambience.mp3")
	stream = game_song
	play()

func play_sfx(sound: AudioStream) -> void:
	if sound == null:
		return
	sfx_player.stream = sound
	sfx_player.play()

extends AudioStreamPlayer

func _ready() -> void:
	stream = preload("res://Assets/Music/main_menu_theme.mp3")
	bus = "Music"
	play()

func play_game_music() -> void:
	var game_song = preload("res://Assets/Music/game_ambience.mp3")
	stream = game_song
	play()

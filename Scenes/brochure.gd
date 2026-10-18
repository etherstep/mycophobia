extends Control

var scene_changing := false
@export var skip_text: Label

func _ready() -> void:
	skip_text.modulate.a = 0.0
	MusicManager.play_brochure_sequence()
	await get_tree().create_timer(5.0).timeout
	if scene_changing:
		return
	skip_text.visible = true
	fade_skip_text()
	await get_tree().create_timer(85.0).timeout
	go_to_world()

func fade_skip_text() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(skip_text, "modulate:a", 0.25, 1.5)
	tween.tween_property(skip_text, "modulate:a", 1.0, 1.5)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		go_to_world()

func go_to_world() -> void:
	if scene_changing:
		return
	scene_changing = true
	MusicManager.stop_brochure_sequence()
	get_tree().change_scene_to_file("res://Scenes/world.tscn")

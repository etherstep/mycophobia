extends Node3D

const ENEMY_SCENE := preload("res://Scenes/enemy.tscn")
const LOOK_TIME := 0.8
const REVEAL_HOLD := 0.35
const HEAD_START := 3.0

@export var spawn_point: Marker3D
@export var chase_end: Node

var _played := false
var _player: Player
var _enemy: CharacterBody3D
var _saved_yaw := 0.0
var _saved_pitch := 0.0


func _ready() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if node.get("starts_chase") != true or not node.has_signal("burned"):
			continue
		if not node.burned.is_connected(_on_burned):
			node.burned.connect(_on_burned)


func _on_burned() -> void:
	begin()


func begin() -> void:
	if _played or spawn_point == null:
		return
	var player := _find_player()
	if player == null:
		return
	_played = true
	_player = player
	var enemy := ENEMY_SCENE.instantiate() as CharacterBody3D
	enemy.set("intro_hold", true)
	get_parent().add_child(enemy)
	enemy.global_position = spawn_point.global_position
	_enemy = enemy
	if chase_end != null:
		chase_end.set("enemy", enemy)
	_saved_yaw = player.rotation.y
	_saved_pitch = player.pitch
	player.begin_cutscene()
	_turn_toward_spawn()


func _turn_toward_spawn() -> void:
	var point := spawn_point.global_position + Vector3(0.0, 1.4, 0.0)
	var flat := point - _player.global_position
	flat.y = 0.0
	var tween := create_tween()
	if flat.length() >= 0.05:
		var look := Transform3D(Basis.IDENTITY, _player.global_position).looking_at(_player.global_position + flat, Vector3.UP)
		var yaw := look.basis.get_euler().y
		var from_yaw := _player.rotation.y
		var delta_yaw := wrapf(yaw - from_yaw, -PI, PI)
		tween.tween_method(func(t: float) -> void:
			if is_instance_valid(_player):
				_player.rotation.y = from_yaw + delta_yaw * t
		, 0.0, 1.0, LOOK_TIME)
		tween.parallel().tween_property(_player.camera_3d, "rotation:x", 0.0, LOOK_TIME)
	tween.chain().tween_interval(REVEAL_HOLD)
	tween.chain().tween_callback(_show_run)


func _show_run() -> void:
	if not is_instance_valid(_player):
		return
	_player.pitch = 0.0
	var label := _player.get_node("HUD/RunLabel") as Label
	label.visible = true
	label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.15)
	tween.tween_interval(0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.25)
	tween.tween_callback(_return_camera.bind(label))


func _return_camera(label: Label) -> void:
	if is_instance_valid(label):
		label.visible = false
	if not is_instance_valid(_player):
		_give_head_start()
		return
	var from_yaw := _player.rotation.y
	var delta_yaw := wrapf(_saved_yaw - from_yaw, -PI, PI)
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		if is_instance_valid(_player):
			_player.rotation.y = from_yaw + delta_yaw * t
	, 0.0, 1.0, LOOK_TIME)
	tween.parallel().tween_property(_player.camera_3d, "rotation:x", _saved_pitch, LOOK_TIME)
	tween.chain().tween_callback(_give_head_start)


func _give_head_start() -> void:
	if is_instance_valid(_player):
		_player.pitch = _saved_pitch
		if _player.camera_3d != null:
			_player.camera_3d.rotation.x = _saved_pitch
		_player.end_cutscene()
	var tween := create_tween()
	tween.tween_interval(HEAD_START)
	tween.tween_callback(_start_chase)


func _start_chase() -> void:
	if is_instance_valid(_enemy):
		_enemy.set("intro_hold", false)
		if _enemy.has_method("begin_committed_chase"):
			_enemy.begin_committed_chase()


func _find_player() -> Player:
	var body := get_node_or_null("../Player")
	if body is Player:
		return body
	for node in get_tree().get_nodes_in_group("player"):
		if node is Player:
			return node
	return null

extends Camera3D

@export var interaction_distance: float = 4.0
@export var crosshair_interact: TextureRect
@export var crosshair_normal: Label
@export var flashlight: SpotLight3D
@export var flashlight_asset: TextureRect

var current_target: Object = null

@export var flashlight_on_sfx: AudioStream
@export var flashlight_off_sfx: AudioStream
@onready var flashlight_player: AudioStreamPlayer3D = $"../FlashlightPlayer"

func _ready() -> void:
	if is_instance_valid(flashlight):
		flashlight.visible = false

func _process(_delta: float) -> void:
	update_target()

func _unhandled_input(event: InputEvent) -> void:
	# Toggle flashlight
	if event.is_action_pressed("flashlight") and not event.is_echo():
		if is_instance_valid(flashlight):
			flashlight.visible = not flashlight.visible
			if flashlight.visible:
				play_flashlight_sfx(flashlight_on_sfx)
			else:
				play_flashlight_sfx(flashlight_off_sfx)
		return

	# Interact with targeted object
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:

		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return

		if is_instance_valid(current_target):
			if current_target.has_method("interact"):
				current_target.interact()

func update_target() -> void:
	# Hide interaction crosshairs while the inventory is open.
	var player := get_parent() as Player
	var inventory_open := (
		player != null
		and player.inventory_ui != null
		and player.inventory_ui.visible
	)

	if inventory_open:
		if is_instance_valid(current_target):
			if current_target.has_method("set_hovered"):
				current_target.set_hovered(false)

		current_target = null

		if is_instance_valid(crosshair_interact):
			crosshair_interact.hide()

		if is_instance_valid(crosshair_normal):
			crosshair_normal.hide()

		return  # IMPORTANT: stop here while inventory is open

	# Raycast to find an interactable object.
	var screen_center := get_viewport().get_visible_rect().size / 2.0
	var ray_origin := project_ray_origin(screen_center)
	var ray_direction := project_ray_normal(screen_center)

	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + ray_direction * interaction_distance
	)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask &= ~2
	query.exclude = [get_parent().get_rid()]

	var result := get_world_3d().direct_space_state.intersect_ray(query)
	var new_target: Object = null

	if not result.is_empty():
		var hit = result["collider"]
		if hit.has_method("interact"):
			new_target = hit

	if new_target != current_target:
		if is_instance_valid(current_target):
			if current_target.has_method("set_hovered"):
				current_target.set_hovered(false)

		current_target = new_target

		if is_instance_valid(current_target):
			if current_target.has_method("set_hovered"):
				current_target.set_hovered(true)

	# Update crosshair visibility during gameplay.
	if is_instance_valid(crosshair_interact):
		crosshair_interact.visible = is_instance_valid(current_target)

	if is_instance_valid(crosshair_normal):
		crosshair_normal.visible = not is_instance_valid(current_target)

# AUDIO
func play_flashlight_sfx(sound: AudioStream) -> void:
	if sound == null:
		return
	flashlight_player.stop()
	flashlight_player.stream = sound
	flashlight_player.play()

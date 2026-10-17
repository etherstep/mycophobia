extends Camera3D

@export var interaction_distance: float = 4.0
@export var crosshair: Label

var current_target: Object = null


func _process(_delta: float) -> void:
	update_target()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:

		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return

		if is_instance_valid(current_target):
			if current_target.has_method("interact"):
				current_target.interact()


func update_target() -> void:
	var screen_center := get_viewport().get_visible_rect().size / 2.0
	var ray_origin := project_ray_origin(screen_center)
	var ray_direction := project_ray_normal(screen_center)

	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + ray_direction * interaction_distance
	)
	query.collide_with_areas = true
	query.collide_with_bodies = true
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

	if is_instance_valid(crosshair):
		crosshair.text = "+" if is_instance_valid(current_target) else "·"

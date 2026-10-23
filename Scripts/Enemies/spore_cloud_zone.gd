extends "res://Scripts/Enemies/spore_cloud.gd"

func _try_push(body: Player) -> void:
	if _touch_cooldown > 0.0 or body.dead:
		return
	var away := _push_normal(body)
	if away == Vector3.ZERO:
		away = body.global_position - global_position
		away.y = 0.0
		if away.length() < 0.05:
			away = -body.global_basis.z
			away.y = 0.0
		if away.length() < 0.01:
			return
		away = away.normalized()
	_touch_cooldown = TOUCH_COOLDOWN
	body.shove(away, PUSH_STEPS)
	body.increase_infection(TOUCH_INFECTION)

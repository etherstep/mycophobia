extends StaticBody3D

const TOUCH_INFECTION := 5
const TOUCH_COOLDOWN := 0.8
const PUSH_STEPS := 1

var _cooldown := 0.0


func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	var area := $Area3D as Area3D
	for body in area.get_overlapping_bodies():
		if body is Player:
			_try_push(body as Player)


func _try_push(player: Player) -> void:
	if _cooldown > 0.0 or player.dead:
		return
	var away := _push_normal(player)
	if away == Vector3.ZERO:
		return
	_cooldown = TOUCH_COOLDOWN
	player.shove(away, PUSH_STEPS)
	player.increase_infection(TOUCH_INFECTION)


func _push_normal(player: Player) -> Vector3:
	var count := player.get_slide_collision_count()
	for i in count:
		var hit := player.get_slide_collision(i)
		if hit.get_collider() != self:
			continue
		var normal := hit.get_normal()
		if hit.get_remainder().dot(normal) >= -0.02:
			continue
		normal.y = 0.0
		if normal.length() < 0.01:
			continue
		return normal.normalized()
	return Vector3.ZERO

extends CanvasLayer

@export var player: Player
@export var flashlight_array: Array[TextureRect]
@export var hands_array: Array[TextureRect]
@export var photo: TextureRect
@export var flashlight: SpotLight3D
@onready var flashlight_original_position: Vector2 = flashlight_array[0].position

@onready var active_sprite_array: Array[TextureRect] = flashlight_array
const HALF_MAX_INFECTION: float = Player.MAX_INFECTION / 2
const QUARTER_MAX_INFECTION: float = Player.MAX_INFECTION / 4


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	active_sprite_array[1].visible = false
	active_sprite_array[2].visible = false
	player.infection_level_changed.connect(_on_infection_changed)
	flashlight.flashlight_visibility_changed.connect(_on_flashlight_visibility_changed)
	#if flashlight.visible:
	active_sprite_array = flashlight_array
	#else:
		#active_sprite_array = hands_array
	player.world.game_loaded.connect(_lower_photo_animation)
	player.mouse_disabled = true

func calculate_hand_sprite_visibility(infection_level: float) -> void:
	var current_infection_level: float = player.infection_level
	if current_infection_level >= Player.MAX_INFECTION - QUARTER_MAX_INFECTION:
		active_sprite_array[0].visible = false
	else:
		active_sprite_array[0].visible = true
	if current_infection_level < QUARTER_MAX_INFECTION:
		active_sprite_array[1].visible = false
	else:
		active_sprite_array[1].visible = true
		var alpha: float = (current_infection_level - QUARTER_MAX_INFECTION) / HALF_MAX_INFECTION
		active_sprite_array[1].modulate.a = clampf(alpha, 0.0, 1.0)
	if current_infection_level < HALF_MAX_INFECTION:
		active_sprite_array[2].visible = false
	else:
		active_sprite_array[2].visible = true
		var alpha: float = (current_infection_level - HALF_MAX_INFECTION) / HALF_MAX_INFECTION
		active_sprite_array[2].modulate.a = clampf(alpha, 0.0, 1.0)

func _on_infection_changed(infection_level: float) -> void:
	calculate_hand_sprite_visibility(infection_level)

func _lower_photo_animation() -> void:
	var screen_height: float = get_viewport().get_visible_rect().size.y
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(photo, "position:y", screen_height, 4.0)
	tween.finished.connect(_on_photo_lowered)



func _on_flashlight_visibility_changed(is_visible: bool) -> void:
	if is_visible:
		for sprite in hands_array:
			sprite.visible = false
		active_sprite_array = flashlight_array
	#else:
		#for sprite in flashlight_array:
			#sprite.visible = false
		#active_sprite_array = hands_array
	calculate_hand_sprite_visibility(player.infection_level)

func _on_photo_lowered() -> void:
	var screen_height: float = get_viewport().get_visible_rect().size.y
	active_sprite_array[0].position.y = screen_height
	calculate_hand_sprite_visibility(player.infection_level)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(active_sprite_array[0], "position:y", flashlight_original_position.y, 1.0)
	tween.finished.connect(func(): player.mouse_disabled = false)

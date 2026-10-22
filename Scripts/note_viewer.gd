extends CanvasLayer

@onready var note_view: Control = $NoteView
@onready var note_texture: TextureRect = $NoteView/NoteTexture
@onready var note_text: RichTextLabel = $NoteView/NoteText
@onready var note_readable_text: RichTextLabel = $NoteView/NoteReadablePanel/NoteReadableText
@onready var note_readable_panel: PanelContainer = $NoteView/NoteReadablePanel

@onready var note_dialogue_player: AudioStreamPlayer = $NoteDialoguePlayer
@export var note_1: AudioStream
@export var note_2: AudioStream
@export var note_3: AudioStream
@export var note_4: AudioStream

var readable_font: Font = ThemeDB.fallback_font
var decorative_font: Font = preload("res://Assets/Fonts/Allura-Regular.ttf")

func _ready() -> void:
	note_view.visible = false
	note_view.mouse_filter = Control.MOUSE_FILTER_STOP
	note_view.gui_input.connect(_on_note_view_gui_input)
	note_readable_panel.add_theme_stylebox_override(
		"panel",
		_create_readable_text_background()
	)

func open_note(item: ItemData) -> void:
	if item == null:
		return
	play_note_sound(item.note_id)
	note_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	note_view.visible = true

	# Note image
	note_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	note_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	note_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	note_texture.texture = item.texture

	# Decorative writing on the note
	note_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	note_text.text = item.text
	note_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	note_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	note_text.add_theme_font_override("normal_font", decorative_font)
	note_text.add_theme_font_size_override("normal_font_size", 64)
	note_text.add_theme_color_override("default_color", Color.BLACK)

	# Plain, readable text overlay
	note_readable_panel.visible = true
	note_readable_text.text = item.text
	note_readable_text.add_theme_font_override("normal_font", readable_font)
	note_readable_text.add_theme_font_size_override("normal_font_size", 22)
	note_readable_text.add_theme_color_override(
		"default_color",
		Color(1.0, 1.0, 1.0, 1.0)
	)
	note_readable_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	note_readable_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_readable_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	await get_tree().process_frame
	_update_readable_panel()

func close_note_view() -> void:
	note_view.visible = false

func close_note_if_open() -> bool:
	if note_view.visible:
		close_note_view()
		return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if not note_view.visible:
		return

	if event.is_action_pressed("ui_cancel") \
	or (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_TAB
	):
		close_note_view()
		get_viewport().set_input_as_handled()

func _on_note_view_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:

		var note_rect: Rect2 = note_readable_panel.get_global_rect()

		if not note_rect.has_point(event.global_position):
			close_note_view()

func _create_readable_text_background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.004, 0.004, 0.004, 0.745)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16)
	return style

func _update_readable_panel() -> void:
	if note_texture.texture == null:
		return

	var texture_size: Vector2 = note_texture.texture.get_size()
	var available_size: Vector2 = note_view.size

	if texture_size.x <= 0 or texture_size.y <= 0:
		return
	if available_size.x <= 0 or available_size.y <= 0:
		return

	# Match the displayed image dimensions while preserving its aspect ratio.
	var scale_factor: float = minf(
		available_size.x / texture_size.x,
		available_size.y / texture_size.y
	)

	var displayed_size: Vector2 = texture_size * scale_factor

	note_readable_panel.size = displayed_size
	note_readable_panel.position = (
		available_size - displayed_size
	) / 2.0


func play_note_sound(note_id: String) -> void:
	print("Note ID received: ", note_id)

	var note_sound: AudioStream = null
	var reaction_sound: AudioStream = null
	var reaction_delay: float = 0.0

	match note_id:
		"note_1":
			note_sound = note_1
			reaction_sound = MusicManager.NOTE_1_REACTION
			reaction_delay = 34.0

		"note_2":
			note_sound = note_2
			reaction_sound = MusicManager.NOTE_2_REACTION
			reaction_delay = 26.0

		"note_3":
			note_sound = note_3
			reaction_sound = MusicManager.NOTE_3_REACTION
			reaction_delay = 11.0

		"note_4":
			note_sound = note_4
			reaction_sound = MusicManager.NOTE_4_REACTION
			reaction_delay = 23.0

		_:
			push_error("Unrecognized note ID: '%s'" % note_id)
			return

	if note_sound == null or reaction_sound == null:
		push_error("Missing audio for '%s'." % note_id)
		return

	# Play the original note SFX.
	note_dialogue_player.stop()
	note_dialogue_player.stream = note_sound
	note_dialogue_player.volume_db = 0.0
	note_dialogue_player.play(2.30)

	# Wait for the specified delay.
	await get_tree().create_timer(reaction_delay).timeout

	# Play the reaction through MusicManager.
	MusicManager.play_player_dialogue(reaction_sound)

	print("Playing reaction for ", note_id)

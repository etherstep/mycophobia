
extends Control

@export var inventory: Inventory

@export var player: Player

@export var button_hover_sfx: AudioStream
@export var button_pressed_sfx: AudioStream
@export var note_pressed_sfx: AudioStream
@export var inventory_open_sfx: AudioStream
@export var inventory_close_sfx: AudioStream

@onready var slots: GridContainer = $Slots
@export var item_texture: TextureRect
@export var item_text: Label
@export var item_quantity: Label
@onready var note_view: Control = $NoteView
@onready var note_texture: TextureRect = $NoteView/NoteTexture
@onready var note_text: RichTextLabel = $NoteView/NoteText
@onready var note_readable_text: RichTextLabel = $NoteView/NoteReadablePanel/NoteReadableText
@onready var note_readable_panel: PanelContainer = $NoteView/NoteReadablePanel

@export var infection_meter: Control

var selected_item: ItemData = null
var readable_font: Font = ThemeDB.fallback_font
var decorative_font: Font = preload("res://Assets/Fonts/Bastliga One.otf")

@export var selection_ui: Control
@export var inventory_slots: Array[Control] = []

var hovered_slot: Sprite2D = null

const MAX_INFECTION: float = Player.MAX_INFECTION

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	note_view.visible = false
	selection_ui.hide()
	note_readable_panel.add_theme_stylebox_override(
		"panel",
		_create_readable_text_background()
	)

	if inventory == null:
		push_warning("Assign the Inventory node in the Inspector.")
		return
		
	for slot in inventory_slots:
		slot.mouse_entered.connect(_on_slot_mouse_entered.bind(slot))
		slot.mouse_exited.connect(_on_slot_mouse_exited.bind(slot))

	inventory.inventory_changed.connect(refresh_inventory)
	infection_meter.size = infection_meter.custom_minimum_size
	player.infection_level_changed.connect(_on_infection_level_changed)
	refresh_inventory()

func _on_slot_mouse_entered(slot: Control) -> void:
	play_hovered()
	selection_ui.show()
	selection_ui.global_position = (
		slot.global_position
		+ (slot.size - selection_ui.size) / 2.0
	)

func _on_slot_mouse_exited(_slot: Control) -> void:
	selection_ui.hide()

func close_note_view() -> void:
	note_view.visible = false

func _on_note_view_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:

		var note_rect := note_readable_panel.get_global_rect()

		if not note_rect.has_point(event.global_position):
			close_note_view()

func refresh_inventory() -> void:
	for child in slots.get_children():
		slots.remove_child(child)
		child.queue_free()

	for i in range(9):
		var slot := Control.new()
		slot.custom_minimum_size = Vector2(200, 200)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP

		slot.mouse_entered.connect(_on_slot_mouse_entered.bind(slot))
		slot.mouse_exited.connect(_on_slot_mouse_exited.bind(slot))

		if i < inventory.items.size():
			var item: ItemData = inventory.items[i]

			var new_item_icon := TextureRect.new()
			new_item_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			new_item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			new_item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			new_item_icon.texture = item.texture
			new_item_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.add_child(new_item_icon)

			var new_item_text := Label.new()
			new_item_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			new_item_text.text = item.name
			new_item_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			new_item_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			new_item_text.autowrap_mode = TextServer.AUTOWRAP_WORD
			new_item_text.clip_text = true
			new_item_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
			#new_item_text.add_theme_font_override("font", decorative_font)
			new_item_text.add_theme_font_size_override("font_size", 24)
			new_item_text.add_theme_color_override("font_color", Color.WHITE)
			new_item_text.add_theme_color_override("font_shadow_color", Color.BLACK)
			new_item_text.add_theme_constant_override("shadow_offset_x", 1)
			new_item_text.add_theme_constant_override("shadow_offset_y", 1)
			slot.add_child(new_item_text)

			slot.gui_input.connect(_on_slot_input.bind(item))

		slots.add_child(slot)

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

	# Match the actual Keep Aspect Centered image dimensions.
	var scale_factor: float = minf(
		available_size.x / texture_size.x,
		available_size.y / texture_size.y
	)

	var displayed_size: Vector2 = texture_size * scale_factor

	note_readable_panel.size = displayed_size
	note_readable_panel.position = (available_size - displayed_size) / 2

func close_note_if_open() -> bool:
	if note_view.visible:
		close_note_view()
		return true
	return false

func _on_slot_input(event: InputEvent, item: ItemData) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			play_pressed()
			if item.item_type == ItemData.ItemType.NOTE:
				play_note_pressed()
				note_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				note_view.visible = true

				# Note image
				note_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				note_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				note_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				note_texture.texture = item.texture

				# Decorative text on the note
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

				# Wait for layout, then size the panel to the displayed note.
				await get_tree().process_frame
				_update_readable_panel()

func _on_item_selected(item: ItemData) -> void:
	selected_item = item
	item_texture.texture = item.texture
	item_text.text = item.name

func _clear_details() -> void:
	selected_item = null
	item_texture.texture = null
	item_text.text = "No item selected"

func play_hovered() -> void:
	MusicManager.play_ui_sfx(button_hover_sfx)

func play_pressed() -> void:
	MusicManager.play_ui_sfx(button_pressed_sfx)

func play_note_pressed() -> void:
	MusicManager.play_ui_sfx(note_pressed_sfx)

func play_inventory_sfx(is_open: bool) -> void:
	play_inventory_open() if is_open else play_inventory_close()

func play_inventory_open() -> void:
	MusicManager.play_ui_sfx(inventory_open_sfx)

func play_inventory_close() -> void:
	MusicManager.play_ui_sfx(inventory_close_sfx)
	
func _on_infection_level_changed(infection: float) -> void:
	var infection_percent: float = infection / MAX_INFECTION
	var meter_width: float = infection_percent * infection_meter.custom_maximum_size.x
	infection_meter.size.x = meter_width

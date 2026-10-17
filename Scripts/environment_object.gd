@tool

class_name EnvironmentObject
extends Node3D

@export var sprite: Sprite3D
@export var rigid_body: RigidBody3D
@export var collider: CollisionShape3D

@export var object_type: ObjectType = ObjectType.MUSHROOM:
	set(value):
		object_type = value
		_on_type_changed()

var height: float
var width: float

enum ObjectType {
	MUSHROOM,
	MUSHROOM2,
}

const SPRITE_DICTIONARY: Dictionary = {
	ObjectType.MUSHROOM: "res://Assets/Sprites/mushroom1.png",
	ObjectType.MUSHROOM2: "res://Assets/Sprites/mushroom2.png",
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup() -> void:
	if not sprite or not collider:
		push_error("No sprite or collider on environment object")
		return
	if not SPRITE_DICTIONARY.has(object_type):
		push_error("No sprite found in dictionary for object type: ", ObjectType.find_key(object_type))
		return
	var path = SPRITE_DICTIONARY.get(object_type)
	var texture: Texture2D = load(path)
	if not texture:
		push_error("No texture file found for: ", path)
		return
	sprite.texture = texture
	var img: Image = texture.get_image()
	var used_rect: Rect2i = img.get_used_rect()
	var pixel_size: float = sprite.pixel_size
	width = used_rect.size.x * pixel_size * sprite.scale.x * 0.9
	height = used_rect.size.y * pixel_size * sprite.scale.y
	
	var cylinder_shape := CylinderShape3D.new()
	cylinder_shape.height = height
	cylinder_shape.radius = width / 2
	collider.shape = cylinder_shape

func _on_type_changed() -> void:
	if is_node_ready():
		setup()

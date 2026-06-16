class_name MapTile
extends Sprite2D

enum CollisionType {
	WALKABLE,
	BLOCKED
}

static var selected_mapTile:MapTile

var collision_type: CollisionType = CollisionType.WALKABLE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func setup() -> void:
	(get_node("TriggerArea") as Area2D).mouse_entered.connect(_on_mouse_entered)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_mouse_entered():
	selected_mapTile = self

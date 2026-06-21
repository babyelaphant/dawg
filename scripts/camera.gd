class_name MainCamera
extends Node

var speed:float = 2.0
var can_move:bool = false
var camera : Camera2D
var initialized : bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_moving()
	
func initialize(position:Vector2):
	camera = get_tree().current_scene.get_node("Camera2D")
	camera.global_position = position
	initialized = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func move(destination:Vector2):
	if !initialized:
		return
	camera.global_position = camera.global_position.lerp(destination,camera.get_process_delta_time()*speed)
		
func start_moving():
	can_move=true

func stop_moving():
	can_move=false

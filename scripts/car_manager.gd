class_name Car_Manager
extends Node

var spawn_interval = 2
var timer = 0
@onready var car_path: Node2D = $CarPath
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	timer += delta	
	if timer > spawn_interval:
		spawn_interval = randi_range(2,4)
		spawn_car()
		timer = 0

func spawn_car():
	print("manager car_path:", car_path)
	var car_scene = preload("res://scenes/car_scene.tscn")
	print(car_scene)
	var car = car_scene.instantiate() as Car
	print("CAR: ", car)
	car._car_path = car_path
	car.initialized = true
	car.global_position = car_path.get_child(0).global_position
	add_child(car)

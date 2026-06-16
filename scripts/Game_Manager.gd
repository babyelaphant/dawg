extends Node

var _dog:GuideDog
var _dog_owner:DogDowner
var initialized:bool = false
var dog_position_offset:Vector2
var _ui:UIManager

func register_dog(d:GuideDog) ->void:
	_dog = d

func register_ui(ui:UIManager):
	_ui = ui
	
func register_dog_owner(do:DogDowner) ->void:
	_dog_owner = do
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !initialized:
		initialize_game()

func recalculate_dog_position_offset():
	dog_position_offset =  _dog_owner.global_position -_dog.global_position

func initialize_game():
	recalculate_dog_position_offset()
	_dog_owner.initialize()
	initialized = true

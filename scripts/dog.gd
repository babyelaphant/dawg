extends Node2D

const lines: Array[String] = [
	"You are a blind old lady.",
	"Your faithful dog Buddy is an essential companion in your everyday life.",
	"He brings you to places that you otherwise could never dream of being.",
	"But Buddy urgently needs some food.",
	"He hasn't eaten anything since morning.",
	"First find a food source in the neighbourhood.",
]

var dialog_done = false
var enters = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$dog.position += Vector2(-0.02,0)
	
	#if DialogueManager.is_dialog_active:
		
			#get_tree().change_scene_to_file("res://scenes/city_scene.tscn")

func _unhandled_input(event):
	if (event.is_action_pressed("advance_dialog")):
		$Label2.visible = false
		DialogueManager.start_dialog($dialogSpawn.global_position, lines)
		print(DialogueManager.current_line_index)

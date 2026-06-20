class_name SoundManager
extends Node

var ingame_music:AudioStreamPlayer2D
var dog_commands = {}
var dog_barks = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func initialize():
	ingame_music = get_tree().current_scene.get_node("ingame_music")
	ingame_music.play()
	
func register_dog_bark(dog:GuideDog, bark:AudioStreamPlayer2D):
	dog_barks[dog.name] = bark 

func register_command(owner:DogDowner, command:AudioStreamPlayer2D):
	dog_commands[command.name] = command
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func play_dog_bark(bark:String):
	if dog_barks.has(bark):
		return
	dog_barks[bark].play()
	
func play_dog_command(command:String):
	if dog_commands.has(command):
		return
	dog_commands[command].play()

class_name SoundManager
extends Node

var ingame_music:AudioStreamPlayer2D
var sounds : Dictionary[String, AudioStream]
var commandsounds : Dictionary[String, AudioStream]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sounds["bark1"] = load("res://assets/sounds/bark1.wav")
	sounds["bark2"] = load("res://assets/sounds/bark2.wav")
	
	commandsounds["go1"] = load("res://assets/sounds/Go1.mp3")
	commandsounds["go2"] = load("res://assets/sounds/Go2.mp3")
	commandsounds["go3"] = load("res://assets/sounds/Go3.mp3")
	commandsounds["go4"] = load("res://assets/sounds/Go4.mp3")
	commandsounds["stop1"] = load("res://assets/sounds/Stop1.mp3")
	commandsounds["stop2"] = load("res://assets/sounds/Stop2.mp3")
	commandsounds["hey1"] = load("res://assets/sounds/Hey1.mp3")
	commandsounds["hey2"] = load("res://assets/sounds/Hey2.mp3")
	commandsounds["wait1"] = load("res://assets/sounds/Wait.mp3")
	commandsounds["wait2"] = load("res://assets/sounds/Wait2.mp3")

func _on_music_finished():
	ingame_music.play()
	
func initialize():
	ingame_music = get_tree().current_scene.get_node("ingame_music")
	ingame_music.finished.connect(_on_music_finished)
	ingame_music.play()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func play_sound(source:AudioStreamPlayer2D, sound:String):
	if sounds.has(sound):
		source.stream = sounds[sound]
		source.play()
	print("playing: ", sound)
	
func play_commandsound(source:AudioStreamPlayer2D, sound:String):
	if commandsounds.has(sound):
		source.stream = commandsounds[sound]
		source.play()
	

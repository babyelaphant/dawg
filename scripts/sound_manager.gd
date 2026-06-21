class_name SoundManager
extends Node

var ingame_music:AudioStreamPlayer2D
var sounds : Dictionary[String, AudioStream]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sounds["bark1"] = load("res://assets/sounds/bark1.wav")
	sounds["bark2"] = load("res://assets/sounds/bark2.wav")

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
	

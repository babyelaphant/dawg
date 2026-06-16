class_name UIManager
extends Node

@onready var nv_progress_bar:NervousenessProgressBar = $Nervouseness_Meter
@onready var command_label:Label= $Command_Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game_Manager.register_ui(self)
	$Timer.start()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$TimerLabel.text =  str(ceil($Timer.time_left))
	
func increase_nervouseness_meter(value):
	nv_progress_bar.increase__meter(value)
	
func show_command(command):
	print("SHOW CMD")
	command_label.visible = true
	command_label.text = command
	await get_tree().create_timer(1).timeout
	command_label.visible = false
	
	

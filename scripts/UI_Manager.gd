class_name UIManager
extends Node

@onready var nv_progress_bar:NervousenessProgressBar = $Nervouseness_Meter
@onready var command_label:Label= $Command_Label
@onready var info:RichTextLabel = get_node("InfoText/Container/TextContainer/Info")
@onready var continue_btn:Button= get_node("InfoText/Container/HBoxContainer/ContinueBtn")

var info_texts = {}
var current_info = "info_start"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game_Manager.register_ui(self)
	info_texts["info_start"] = "Your faithful dog Buddy is an essential companion in your everyday life.\n
He brings you to places that you otherwise could never dream of being.\n
But Buddy urgently needs some food.\n
He hasn't eaten anything since morning.\n
First find a food source in the neighbourhood."

	info_texts["eaten food"] = "Mmmmh. That tasted good.\nNow Buddy has enough energy to continue!
								\nNext Objective: Find a park bench to relax."
	info_texts["New Attempt"] = "You collided with a car and died.\nRestarting from last checkpoint!"
	
	info_texts["game won"] = "Finally! Buddy reached his destination and his dog owner is relieved.
							  You completed the game in " + str(300-$Timer.time_left) + " seconds!"
	
	info_texts["game lost(missing objective)"] = "You found a park bench but you could not locate a food source for Budy. Tommy needs to train his dog better next time..."
	
	info_texts["game lost(no attempts)"] = "You have no attempts remaining. Tommy needs to train his dog better next time..."
		
	info_texts["game lost(timeout)"] = "Oops. Your time has run out! Tommy needs to train his dog better next time..."

func update_info(info:String):
	current_info = info
	if Game_Manager.gamelost:
		continue_btn.queue_free()
	pause_game(true)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$TimerLabel.text =  str(ceil($Timer.time_left))
	if timeout():
		Game_Manager.gamelost = true
		update_info("game lost(timeout)")
	
func reset_timer(value:float):
	$Timer.wait_time = value
	$Timer.start()

func get_time_left():
	return $Timer.time_left
	
func timeout():
	return $Timer.time_left == 0
	
func pause_game(pause:bool):
	get_tree().paused = pause
	get_node("InfoText").visible = pause
	info.text = info_texts[current_info]
	Game_Manager.game_paused = pause
	
func start_game():
	pause_game(true)
	continue_btn.pressed.connect(continue_btn_pressed)

func increase_nervouseness_meter(value):
	nv_progress_bar.increase__meter(value)
	
func show_command(command):
	print("SHOW CMD")
	command_label.visible = true
	command_label.text = command
	await get_tree().create_timer(1).timeout
	command_label.visible = false
	
func continue_btn_pressed():
	if !Game_Manager.gamewon and !Game_Manager.gamelost:
		pause_game(false)
	if current_info == "info_start":
		$Timer.start()

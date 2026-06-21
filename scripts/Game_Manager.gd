extends Node

var _dog:GuideDog
var _dog_owner:DogDowner
var _ai_dogs : Dictionary[String,GuideDog] = {}
var _ai_dog_owners :Dictionary[String,DogDowner] = {}

var initialized:bool = false
var dog_position_offset:Vector2
var ai_dog_position_offset1:Vector2
var ai_dog_position_offset2:Vector2
var _ui:UIManager
var objectives = {}
var objectives_list = ["find_food", "cross road", "avoid dog", "find_bench"]
var num_tries = 0
var dog_checkpoint:Vector2 = Vector2.ZERO
var dog_owner_checkpoint:Vector2 = Vector2.ZERO
var game_paused = false
var initialized_game = false
var npc_spawn1:Node2D
var npc_spawn2:Node2D
var park_bench:Node2D
var park_bench2:Node2D
var water_place:Node2D
var gamelost:bool = false
var gamewon:bool = false
var checkpoint:Node2D
var time_checkpoint:float = 0
var nervousness_checkpoint:float = 0
signal load_checkpoints

var additional_benches:Node2D

var title_scene = load("res://scenes/title_screen.tscn")
var game_scene =  load("res://scenes/city_scene.tscn")
func register_dog(d:GuideDog) ->void:
	
	if !d.is_ai:
		_dog = d

	else:
		_ai_dogs[d.name] = d
		_ai_dogs[d.name].can_move = false

func register_ui(ui:UIManager):
	_ui = ui
	
func register_dog_owner(do:DogDowner) ->void:
	
	if !do.is_ai:
		_dog_owner = do
	else:
		_ai_dog_owners[do.name] = do
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !initialized:
		load_title_screen()
		initialized = true
	elif initialized_game:
		if (npc_spawn1.global_position - _dog.global_position).length() < 200 \
		and _ai_dogs["AI_GuideDog"].move_direction == Vector2.ZERO:
			print("dist to ai dog: " , (npc_spawn1.global_position - _dog.global_position).length())
			trigger_ai_dog("AI_GuideDog")
			
func recalculate_dog_position_offset():
	dog_position_offset =  _dog_owner.global_position -_dog.global_position
	
func recalculate_ai_dog_position_offset(dog:String):
	
	if dog == "AI_GuideDog":
		ai_dog_position_offset1 = _ai_dog_owners["AI_Dog_Owner"].global_position - _ai_dogs[dog].global_position
	else:
		ai_dog_position_offset2 = _ai_dog_owners["AI_Dog_Owner2"].global_position - _ai_dogs[dog].global_position

func trigger_ai_dog(dog:String):
	_ai_dogs[dog].can_move = true
	
func reached_water_place(body):
	objective_completed("find water")
	_ui.update_info("drink water")

func reached_bench(body):
	_ui.update_info("other bench")
	
func load_title_screen():
	get_tree().change_scene_to_packed(title_scene)
	
func load_game_scene():
	get_tree().change_scene_to_packed(game_scene)
	await get_tree().scene_changed
	await get_tree().create_timer(0.5).timeout
	initialize_game()
			
func initialize_game():
	print("Loading Game")
	recalculate_dog_position_offset()
	recalculate_ai_dog_position_offset("AI_GuideDog")
	recalculate_ai_dog_position_offset("AI_GuideDog2")
	_dog_owner.initialize(_dog, dog_position_offset)
	_dog.initialize(_dog_owner)
	_ai_dog_owners["AI_Dog_Owner"].initialize(_ai_dogs["AI_GuideDog"], ai_dog_position_offset1)
	_ai_dog_owners["AI_Dog_Owner2"].initialize(_ai_dogs["AI_GuideDog2"],  ai_dog_position_offset1)
	_ai_dogs["AI_GuideDog"].initialize(_ai_dog_owners["AI_Dog_Owner"])
	_ai_dogs["AI_GuideDog2"].initialize(_ai_dog_owners["AI_Dog_Owner2"])
	initialized = true
	objectives["find food"] = false
	objectives["find water"] = false
	objectives["find bench"] = false
	water_place = get_tree().current_scene.get_node("Waterplace")
	water_place.get_node("Area2D").body_entered.connect(reached_water_place)
	npc_spawn1 = get_tree().current_scene.get_node("Npc_Spawn")
	npc_spawn2 = get_tree().current_scene.get_node("Npc_Spawn2")
	park_bench = get_tree().current_scene.get_node("ParkBench")
	park_bench2 = get_tree().current_scene.get_node("ParkBench2")
	additional_benches = get_tree().current_scene.get_node("Additional Benches")
	
	for i in range(additional_benches.get_children().size()):
		additional_benches.get_child(i).get_node("Area2D").body_entered.connect(reached_bench)
	
	park_bench.get_node("Area2D").collision_mask = 0xFFFFFFFF
	park_bench2.get_node("Area2D").collision_mask = 0xFFFFFFFF
	park_bench.get_node("Area2D").body_entered.connect(reached_park_bench)
	park_bench2.get_node("Area2D").body_entered.connect(reached_park_bench)
	checkpoint = get_tree().current_scene.get_node("CheckPoint")
	trigger_ai_dog("AI_GuideDog2")	#saveCheckPoints()
	checkpoint.get_node("Area2D").body_entered.connect(save_checkpoints)
	
	_dog.distractionsources.get_node("DogFood").visible = false
	place_dog_food()
	#
	_ui.start_game()
	Sound_Manager.initialize()
	Game_Camera.initialize(_dog_owner.global_position)
	initialized_game = true

func save_checkpoints():
	time_checkpoint = _ui.get_time_left()
	nervousness_checkpoint = _dog_owner.total_nervouseness
	
func reached_park_bench(body):
	print("reached bench")
	objective_completed("find bench")
	if is_objective_completed("find food") and is_objective_completed("find water"):
		gamewon = true
		_ui.update_info("game won")
	else:
		gamelost = true
		_ui.update_info("game lost(missing objective)")

func new_highscore(score:float) ->bool:
	if not FileAccess.file_exists("user://save_game.dat"):
		var file = FileAccess.open("user://save_game.dat", FileAccess.WRITE)
		file.close()

	var savefile = FileAccess.open("user://save_game.dat", FileAccess.READ_WRITE)
	var content = savefile.get_as_text()
	var result = false
	if savefile:
		savefile.seek_end()
		if content == "":
			result=true
			savefile.store_string(str(snappedf(score, 0.1)))
		else:
			for line in content.split("\n"):
				if int(line) > score:
					result = true
					savefile.store_string(str(score))
					break
					
		savefile.close()
	return result
	
func place_dog_food():
	
	_dog.distractionsources.get_node("DogFood").visible = true
	
	var r = randi_range(0,4)
	var c = randi_range(0,3)
	_dog.distractionsources.get_node("DogFood").region_rect = Rect2(c*16, r*16, 16, 16)
	
	var posx = randi_range(13,392)
	var posy = randi_range(1095,1350)
	var v= Vector2(posx,posy)
	var space_state = _dog.get_world_2d().direct_space_state	
	var query = PhysicsPointQueryParameters2D.new()
	query.position = v
	query.collide_with_bodies = true
	var result = space_state.intersect_point(query)
	
	while (!result.is_empty() or !can_place_dog_food(v,result) or(v-_dog.global_position).length() < 200):
		posx = randi_range(13,392)
		posy = randi_range(1095,1350)
		v = Vector2(posx,posy)
	
		#query = PhysicsPointQueryParameters2D.new()
		query.position = v
		query.collide_with_bodies = true
		result = space_state.intersect_point(query)
	
	_dog.distractionsources.get_node("DogFood").position = v
	
func objective_completed(objective:String):
	if objective in objectives.keys():
		objectives[objective] = true

func is_objective_completed(objective:String):
	if !objectives.has(objective):
		return false
	return objectives[objective] == true
	
func new_attempt():
	num_tries+=1
	print("NUMTRIES: ", num_tries)
	if num_tries <= 2:
		print("NEW ATTEMPTI")
		_ui.update_info("New Attempt")
		start_from_last_checkpoint()
		Car.collided_car = null
	else:
		gamelost = true
		_ui.update_info("game lost(no attempts)")

func start_from_last_checkpoint():
	_dog.global_position = checkpoint.global_position
	_dog_owner.global_position = checkpoint.global_position - Vector2.RIGHT*10-Vector2.RIGHT*10
	_dog_owner.reset_nervousness(nervousness_checkpoint)
	while(game_paused):
		await get_tree().process_frame
	_ui.reset_timer(time_checkpoint)
	#_ui.start_timer()

func game_lost():
	if game_paused:return
	return _dog_owner.total_nervouseness >= 100 or _ui.timeout() or num_tries > 2 or (is_objective_completed("find_bench") and !is_objective_completed("find_food"))
	
func can_place_dog_food(v:Vector2,result):
	for i in range(result.size()):
		if (v-result[i].collider.global_position).length() < 40:
			return false
	return true

class_name DogDowner
extends Movable

var move_delay:float = 0.25
var timer:float = 0.0
var process_timer: bool = false
var can_follow:bool = false
var target_offset:Vector2
var target2:Vector2
var get_move_direction:bool = false
var avoiding_obstacles:bool = false
var saved_dog_pos:Vector2 = Vector2.ZERO
var saved_wallnormal:Vector2 = Vector2.ZERO
var saved_dog_positions = []
var	go_interval_min = 2
var go_interval_max = 5
var stop_interval = 0
var waiting_for_response :bool = false
var response_delay:float= 0
var critical_response_delay = 4

@export var test:Sprite2D

var current_command:String= "GO"
var old_command:String = "STOP"

class NervousenessLevel:
	var _max_nervouseness : float
	var _current_nervouseness : float
	var _dogowner : DogDowner
	static var currentLevel : int = 0
	
	signal nervouseness_level_increased()
	
	func _init(dogowner,max_nervouseness) -> void:
		_current_nervouseness = 0
		_max_nervouseness = max_nervouseness
		_dogowner = dogowner
		nervouseness_level_increased.connect(_dogowner._on_nervouseness_level_increased)
	
	#get the max anger
	func get_max_nervouseness():
		return _max_nervouseness
		
	func increase_nervouseness(nervouseness) -> void:
		if _current_nervouseness < _max_nervouseness:
			_current_nervouseness += nervouseness
			_dogowner.total_nervouseness  += _current_nervouseness
			
			Game_Manager._ui.increase_nervouseness_meter(nervouseness)
		elif _current_nervouseness >= _max_nervouseness and currentLevel < 9:
			currentLevel += 1
			nervouseness_level_increased.emit()

var nervouseness_levels: Array[NervousenessLevel] = []
var total_nervouseness: int = 0

func command_dog(repeat:bool = false):
	old_command = current_command
	
	if current_command == "GO":
		stop_interval = randf_range(2,5)
			
	if !repeat:
		print("not rep")
		if current_command == "STOP":
			current_command = "GO"
		else:
			current_command = "STOP"
	
	Game_Manager._ui.show_command(current_command)
	response_delay = 0
	waiting_for_response = true
	while response_delay < critical_response_delay and !Game_Manager._dog.respond_to_command(current_command):
		await get_tree().process_frame
		response_delay += get_process_delta_time()
	waiting_for_response = false

	if response_delay >= critical_response_delay:
		command_dog(true)
		make_nervous(4)
	else:
		make_nervous(response_delay)
		
#Make the bus driver angry
func make_nervous(nervouseness_amount) -> void:
	nervouseness_levels[NervousenessLevel.currentLevel].increase_nervouseness(nervouseness_amount)
	
#Notify the ui manager that the anger level increased
func _on_nervouseness_level_increased() -> void:
	pass

#get the total anger
func get_total_anger() -> int:
	return total_nervouseness
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game_Manager.register_dog_owner(self)
	set_process_input(true)
	randomize()
	for i in range(10):
		nervouseness_levels.append(NervousenessLevel.new(self, 30+i*7))
			
func initialize() -> void:
	Game_Manager._dog.on_started_moving.connect(on_dog_started_moving)
	# Called every frame. 'delta' is the elapsed time since the previous frame.
	
func _process(delta: float) -> void:
	if waiting_for_response:
		timer = 0
		return
		
	timer += delta

	if current_command == "GO":
		if timer > go_interval_min and timer < go_interval_max:
			var random = randi()%100
			if random < nervouseness_levels[NervousenessLevel.currentLevel]._max_nervouseness:
				command_dog(false)
			timer = 0
		elif !Game_Manager._dog.respond_to_command(current_command):
			make_nervous(4);
			command_dog(true)
			print("DISOBEYED, REPEATING COMMAND GO")
			timer = 0

	else:
		if timer > stop_interval:
			command_dog(false)
			timer = 0
		elif !Game_Manager._dog.respond_to_command(current_command):
			make_nervous(4);
			command_dog(true)
			print("DISOBEYED, REPEATING COMMAND STOP")
			timer = 0

func on_dog_started_moving() -> void:
	can_follow = false

	await get_tree().create_timer(.25).timeout

	can_follow = true
	
	if avoiding_obstacles:
		return
	var temp :Vector2 = find_random_target_offset()
	if temp != Vector2.ZERO and Game_Manager._dog.move_direction != Vector2.ZERO:target_offset = temp

func check_obstacles():
	
	var hitResult = {}
	var to_dog = (Game_Manager._dog.global_position - global_position)
	var perpendicular = to_dog.normalized().rotated(PI/2)
	var offsets = [-10, 0, 10]
	var temp = 0
	var min_temp = 0
	
	for i in range(3):
		var offset = perpendicular * offsets[i]
		var from = global_position-to_dog.normalized()*2 + offset
		var to = Game_Manager._dog.global_position
		
		var query = PhysicsRayQueryParameters2D.create(from, to)
		query.exclude = [self, Game_Manager._dog]
		var result = get_world_2d().direct_space_state.intersect_ray(query)
			
		if  !result.is_empty():
			temp = (result.position-from).length()
			if min_temp < temp:
				min_temp = temp
				print("mintemp ", min_temp)
			to = result.position 
			
		if !result.is_empty() and hitResult.is_empty():
			hitResult = result

		var line = get_node("Line2D" + str(i))
		line.clear_points()
		line.add_point(to_local(from))
		line.add_point(to_local(to))
		line.width = 0.4
		line.default_color = Color.BLACK
		if !result.is_empty():
			line.default_color = Color.RED
	return !hitResult.is_empty() and min_temp +5< (Game_Manager._dog.global_position-global_position).length()

func _physics_process(delta):
	if !can_follow:	
		idle()
		return

	var temp1 :Vector2 = find_random_target_offset()
	if temp1 != Vector2.ZERO and Game_Manager._dog.move_direction != Vector2.ZERO:target_offset = temp1
		
	#check_obstacles()
	#if Game_Manager._dog.velocity.length() > 0:move_direction = Game_Manager._dog.move_direction
	move_speed = Game_Manager._dog.move_speed
	
	print("to: ", target_offset)
	var hitResult = {}
	#line.clear_points()
	for i in range(3):
		
		var line  = get_node("Line2D" + str(i))
		var space_state = get_world_2d().direct_space_state
		var from = global_position - move_direction.rotated(PI/2)*3 + i * move_direction.rotated(PI/2) * 3
		var to = from + move_direction*5
		var query = PhysicsRayQueryParameters2D.create(
			from,
			to
		)
		query.exclude = [self, Game_Manager._dog]
		
		var result = get_world_2d().direct_space_state.intersect_ray(query)
		#line.clear_points()
		#line.add_point(to_local(from))
		#line.add_point(to_local(to))
		#line.width = .2
		
		if !result.is_empty() and hitResult.is_empty():
			hitResult = result

	if Game_Manager._dog.is_near_wall and !avoiding_obstacles:
		var temp = Game_Manager._dog.global_position - Game_Manager._dog.move_direction* 10
		if abs(Game_Manager._dog.move_direction.angle_to(Game_Manager._dog.wall_normal)) >= PI/2:
			print("kalender")
			temp += Game_Manager._dog.wall_normal * 10
			
		if Game_Manager._dog.move_direction != Vector2.ZERO:
			target_offset = temp
			target_offset = target_offset - Game_Manager._dog.global_position
	
	if avoiding_obstacles:
		target_offset = saved_dog_pos - Game_Manager._dog.global_position

	move_direction = (Game_Manager._dog.global_position + target_offset - global_position).normalized()
	
	can_move = (hitResult.is_empty() or check_obstacles()) and (Game_Manager._dog.global_position + target_offset-global_position).length() > 0.1 and (Game_Manager._dog.global_position-global_position).length() > Game_Manager.dog_position_offset.length()
	print("dist to target: ", (Game_Manager._dog.global_position + target_offset-global_position).length())
	print("hitresult empty: ",hitResult.is_empty() , " avoiding obs ", avoiding_obstacles )
	test.global_position = Game_Manager._dog.global_position + target_offset
	
	#test.global_position = saved_dog_pos
	
	if !check_obstacles() and !avoiding_obstacles and Game_Manager._dog.movement_cache.size() > 0:
		print("reset cache")
		Game_Manager._dog.movement_cache.clear()
		Game_Manager._dog.is_building=false
		saved_dog_positions.clear()
	
	if Game_Manager._dog.is_near_wall:
		saved_wallnormal = Game_Manager._dog.wall_normal*5

	if can_move:	
		print("can move!")
		if Game_Manager._dog.movement_cache.size() == 0:
			print("cache size = 0")
			move_direction = (Game_Manager._dog.global_position + target_offset - global_position).normalized()
		get_move_direction = false
		velocity = move_direction.normalized() * move_speed
		#Game_Manager._dog.movement_cache = []
		move()
	else:
		print("cant move")
		Game_Manager._dog.reset_movement_cache()
		idle()
	
	if velocity.length() < 0.1:
		saved_dog_pos = Vector2.ZERO
	
	if avoiding_obstacles and ((global_position-saved_dog_pos).length() < 0.3):
		print("saved dog pos IS ", saved_dog_pos)
		avoiding_obstacles = false

		
	print("CANMOVE: ", can_move, " target dist: ",(Game_Manager._dog.global_position + target_offset-global_position).length(), " env hit: ", !hitResult.is_empty() , " obs hit: ", check_obstacles())
	if(check_obstacles() and !avoiding_obstacles) :
	
		if(Game_Manager._dog.movement_cache.is_empty() and !Game_Manager._dog.is_building ):
			print("building movement cache")
			Game_Manager._dog.build_movement_cache()
		
		if !get_move_direction :
			saved_dog_pos = Game_Manager._dog.pop_movement_cache()
			print("sv dogpos",saved_dog_pos )
			
			saved_dog_positions.append(saved_dog_pos)
			if saved_dog_pos != Vector2.ZERO:
				saved_dog_pos += saved_wallnormal
				avoiding_obstacles = true
				move_direction = (saved_dog_pos - global_position).normalized()
				get_move_direction = true
				
	super._physics_process(delta)
		
func find_random_target_offset():
	
	if Game_Manager._dog.move_direction != Vector2.UP and Game_Manager._dog.move_direction != Vector2.RIGHT and  Game_Manager._dog.move_direction != Vector2.LEFT and Game_Manager._dog.move_direction != Vector2.DOWN:
		return Vector2.ZERO
	
	if Game_Manager._dog.is_near_wall:
		return Vector2.ZERO
		
	var target = Vector2.ZERO
	var targets = [Game_Manager._dog.global_position  -  Game_Manager._dog.move_direction*10 + Game_Manager._dog.move_direction.rotated(PI/2)*10,
				Game_Manager._dog.global_position  -  Game_Manager._dog.move_direction*10 + Game_Manager._dog.move_direction.rotated(-PI/2)*10]
	
	if ((global_position-targets[0]).length() > (global_position-targets[1]).length()):
		target = targets[1]
	else:
		target = targets[0]
	
	print("target offset: ", target - Game_Manager._dog.global_position)
	return target - Game_Manager._dog.global_position

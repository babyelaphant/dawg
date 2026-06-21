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
var	go_interval_min = 5
var go_interval_max = 10
var stop_interval = 0
var waiting_for_response :bool = false
var response_delay:float= 0
var critical_response_delay:float = 3
var base_nervousness:float = 4
var guide_dog:GuideDog
var dog_position_offset:Vector2 = Vector2.ZERO
var temp1:Vector2

@export var test:Sprite2D

var current_command:String= "STOP"
var old_command:String = "GO"

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
			_dogowner.total_nervouseness += nervouseness
			
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
	
	else:
		print("repeating cmd")
	
	Game_Manager._ui.show_command(current_command)
	response_delay = 0
	waiting_for_response = true
	while !Game_Manager.gamelost and ! Game_Manager.gamewon and response_delay < critical_response_delay and !guide_dog.respond_to_command(current_command):
		await get_tree().process_frame
		response_delay += get_process_delta_time()

	if response_delay >= critical_response_delay:
		command_dog(true)
		print("critical response delayy")
		print("making nervous")
		make_nervous(base_nervousness)
	else:
		make_nervous((response_delay/critical_response_delay)*base_nervousness)
		print("not waiting for respo")
		waiting_for_response = false


func reset_nervousness(value:float) -> void:
	total_nervouseness = value
	NervousenessLevel.currentLevel = total_nervouseness/10
	Game_Manager._ui.reset_nervouseness_meter(value)
	
#Make the bus driver angry
func make_nervous(nervouseness_amount) -> void:
	nervouseness_levels[NervousenessLevel.currentLevel].increase_nervouseness(nervouseness_amount)
	if total_nervouseness >= 100:
		Game_Manager.gamelost = true
		Game_Manager._ui.update_info("game lost(nervous)")

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
			
func initialize(guidedog:GuideDog, dog_pos_offset) -> void:
	guide_dog = guidedog
	dog_position_offset = dog_pos_offset
	guide_dog.on_started_moving.connect(on_dog_started_moving)
	guide_dog.on_move_direction_changed.connect(on_dog_changed_direction)
	# Called every frame. 'delta' is the elapsed time since the previous frame.
	
func _process(delta: float) -> void:
	if is_ai:
		return
	
	Game_Camera.move(global_position)

	if!Game_Manager.initialized_game:
		return
		
	if waiting_for_response or guide_dog.eating_food:
		timer = 0
		return
		
	timer += delta
	print("current cmd: ", current_command)
	if current_command == "GO":
		if timer > go_interval_min and timer < go_interval_max:
			var random = randi()%100
			if random < nervouseness_levels[NervousenessLevel.currentLevel]._max_nervouseness:
				command_dog(false)
			timer = 0
		
		#dog stopped responsing to command
		elif !guide_dog.respond_to_command(current_command):
			if !guide_dog.eating_food:
				make_nervous(2);
				command_dog(true)
				print("DISOBEYED, REPEATING COMMAND GO")
			timer = 0

	else:
		if timer > stop_interval:
			command_dog(false)
			timer = 0
		elif !guide_dog.respond_to_command(current_command):
			make_nervous(2);
			command_dog(true)
			print("DISOBEYED, REPEATING COMMAND STOP")
			timer = 0
			
func on_dog_changed_direction(dog:GuideDog) -> void:
	if dog != guide_dog:
		return
	can_follow = false
	
	print("chdir")
	await get_tree().create_timer(.1).timeout
	temp1 = find_random_target_offset()
	#
	can_follow = true

func on_dog_started_moving(dog:GuideDog) -> void:
	
	if dog != guide_dog:
		return
	
	#temp1 = find_random_target_offset()
	
	can_follow = false

	await get_tree().create_timer(.25).timeout
	temp1 = find_random_target_offset()

	can_follow = true
	
	#if temp1 != Vector2.ZERO and guide_dog.move_direction != Vector2.ZERO:target_offset = temp1

func check_obstacles():
	
	var hitResult = {}
	var to_dog = (guide_dog.global_position - global_position)
	var perpendicular = to_dog.normalized().rotated(PI/2)
	var offsets = [-7, 0, 7]
	var temp = 0
	var min_temp = 0
	
	for i in range(3):
		var offset = perpendicular * offsets[i]
		var from = global_position-to_dog.normalized() + offset
		var to = guide_dog.global_position
		
		var query = PhysicsRayQueryParameters2D.create(from, to)
		query.exclude = [self, guide_dog]
		var result = get_world_2d().direct_space_state.intersect_ray(query)
			
		if  !result.is_empty():
			temp = (result.position-from).length()
			if min_temp < temp:
				min_temp = temp
				print("mintemp ", min_temp)
				hitResult = result
			#to = result.position 
			
		#if !result.is_empty() and hitResult.is_empty():
			#hitResult = result

		var line = get_node("Line2D" + str(i))
		line.clear_points()
		line.add_point(to_local(from))
		line.add_point(to_local(to))
		line.width = 1
		line.default_color = Color.BLACK
	
	if !hitResult.is_empty():
		var shape_index = hitResult.shape

		var owner_id = hitResult.collider.shape_find_owner(shape_index)
		var shape_node = hitResult.collider.shape_owner_get_owner(owner_id)
		print("Hit shape:", shape_node.name)
		
	return !hitResult.is_empty()# and min_temp +5< (guide_dog.global_position-global_position).length()

func _physics_process(delta):
	if !can_follow:	
		#idle()
		velocity = Vector2.ZERO
		return
	
	#var temp1 :Vector2 = find_random_target_offset()
	#if temp1 != Vector2.ZERO and !avoiding_obstacles and guide_dog.move_direction != Vector2.ZERO:target_offset = temp1
		
	#check_obstacles()
	#if guide_dog.velocity.length() > 0:move_direction = guide_dog.move_direction
	move_speed = guide_dog.move_speed
		
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
		query.exclude = [self, guide_dog]
		
		var result = get_world_2d().direct_space_state.intersect_ray(query)

		if !result.is_empty() and hitResult.is_empty():
			hitResult = result

	if avoiding_obstacles and ((global_position - saved_dog_pos).length() < 0.3) :
		avoiding_obstacles = false
		#saved_dog_pos = Vector2.ZERO
		get_move_direction = false
	
	print("avoiding obs: ", avoiding_obstacles)
	#get_node("CollisionShape2D").disabled = avoiding_obstacles
	print("CANMOVE: ", can_move, " target dist: ",(guide_dog.global_position + target_offset-global_position).length(), " env hit: ", !hitResult.is_empty() , " obs hit: ", check_obstacles())
	#if(check_obstacles() and !avoiding_obstacles) :
	#if(check_obstacles()) :
	
	if check_obstacles() and !avoiding_obstacles:
		if !guide_dog.is_building:
			guide_dog.movement_cache.clear()  # force fresh cache
			guide_dog.build_movement_cache()

	if !avoiding_obstacles and guide_dog.can_pop_movement_cache:
		saved_dog_pos = guide_dog.pop_movement_cache()
		print("sv dogpos",saved_dog_pos )
		if saved_dog_pos != Vector2.ZERO:
			print("popping from cache")
			#test.global_position = saved_dog_pos
			#target_offset = saved_dog_pos - guide_dog.global_position
			avoiding_obstacles = true
			get_move_direction = true
			#dog_position_offset = saved_dog_pos - guide_dog.global_position

	if !check_obstacles() and guide_dog.can_pop_movement_cache:
		guide_dog.can_pop_movement_cache = false
		#await get_tree().create_timer(0.2).timeout
		print("clear cache")
		guide_dog.movement_cache.clear()
		guide_dog.is_building = false
		avoiding_obstacles = false
		
	if avoiding_obstacles:
		target_offset = saved_dog_pos - guide_dog.global_position
		
	elif !avoiding_obstacles and guide_dog.is_near_wall:
		var temp = guide_dog.global_position - guide_dog.move_direction* 10
		if abs(guide_dog.move_direction.angle_to(guide_dog.wall_normal)) >= PI/2:
			temp += guide_dog.wall_normal * 10
			
		if guide_dog.move_direction != Vector2.ZERO:
			target_offset = temp
			target_offset = target_offset - guide_dog.global_position

	elif !avoiding_obstacles:
		if temp1 != Vector2.ZERO:
			target_offset = temp1
	
	if target_offset == Vector2.ZERO:
		print("to is 0")
			
	move_direction = (guide_dog.global_position+target_offset-global_position).normalized()
	print("dist to target: ", (guide_dog.global_position + target_offset-global_position).length())
	print("hitresult empty: ",hitResult.is_empty() , " avoiding obs ", avoiding_obstacles )		
	
	#can_move = (guide_dog.global_position-global_position).length() > dog_position_offset.length()
	can_move = (guide_dog.global_position + target_offset-global_position).length() > 0.3 #and (guide_dog.global_position-global_position).length() > dog_position_offset.length()

	if can_move:	
		print("can move!")
		velocity = move_direction.normalized() * move_speed
		move()
	else:
		print("cant move")
		velocity = Vector2.ZERO
		#guide_dog.movement_cache.clear()
		#guide_dog.is_building = false
		#guide_dog.can_pop_movement_cache = false
		idle()
	
	if velocity.length() < 0.1:
		saved_dog_pos = Vector2.ZERO
		
	print("CAN MOVE: ", can_move)
	super._physics_process(delta)
		
func find_random_target_offset():
	
	if guide_dog.is_near_wall:
		return Vector2.ZERO
			
	#if abs(guide_dog.move_direction.angle_to(Vector2.UP))<0.1 or abs(guide_dog.move_direction.angle_to(Vector2.RIGHT))<0.1 or abs(guide_dog.move_direction.angle_to(Vector2.LEFT))<0.1 or abs(guide_dog.move_direction.angle_to(Vector2.DOWN))<0.1:
	if guide_dog.move_direction != Vector2.UP and guide_dog.move_direction != Vector2.RIGHT and guide_dog.move_direction != Vector2.LEFT and guide_dog.move_direction != Vector2.DOWN:
		print("guide dog movedir: ", guide_dog.move_direction)
		return Vector2.ZERO

	var target = Vector2.ZERO
	var targets = [guide_dog.global_position  -  guide_dog.move_direction*10 + guide_dog.move_direction.rotated(PI/2)*10,
				guide_dog.global_position  -  guide_dog.move_direction*10 + guide_dog.move_direction.rotated(-PI/2)*10]
	
	if ((global_position-targets[0]).length() > (global_position-targets[1]).length()):
		target = targets[1]
	else:
		target = targets[0]

	#if is_ai:
		#print("target offset: ", target - guide_dog.global_position)
	return target - guide_dog.global_position
	
	return Vector2.ZERO

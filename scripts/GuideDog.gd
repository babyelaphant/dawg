class_name GuideDog
extends Movable

var old_move_direction:Vector2 = Vector2.ZERO

signal on_move_direction_changed
signal on_wall_normal_changed
signal on_started_moving

var directions: Array[Vector2] = [Vector2.UP,Vector2.RIGHT, Vector2.DOWN,Vector2.LEFT]
var wall_normal:Vector2
var old_wall_normal:Vector2 = Vector2.ZERO
var is_near_wall:bool = false
var wall_check_interval = 0.25
var timer = 0
var movement_cache = []
var can_pop_movement_cache = false
var is_building:bool = false
var offset:Vector2 = Vector2.ZERO
var eating_food:bool = false
var _owner:DogDowner
var ai_waypoint_index:int = 1

@export var distractionsources: Node2D
@export var test:Sprite2D
@export var max_distance:float = 30
@export var ai_path:Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game_Manager.register_dog(self)
	set_process_input(true)
	collision_mask = 1 # e.g., Layer 1
	if !is_ai:
		can_move = true


func check_obstacles():
	var hitResult = {}
	for i in range(3):
		
		var line  = get_node("Line2D" + str(i))
		var space_state = get_world_2d().direct_space_state
		var from = global_position - move_direction.rotated(PI/2)*3 + i * move_direction.rotated(PI/2) * 3
		var to = from + move_direction*5
		var query = PhysicsRayQueryParameters2D.create(
			from,
			to
		)
		query.exclude = [self, _owner]
		
		var result = get_world_2d().direct_space_state.intersect_ray(query)		#line.clear_points()

		if !result.is_empty() and hitResult.is_empty():
			hitResult = result
			
	return !hitResult.is_empty()
	
func build_movement_cache():
	var timer = 0
	if is_building: return
	is_building = true
	while is_building:		
		if can_move:
			if !check_obstacles() and move_direction == Vector2.UP or move_direction == Vector2.RIGHT or move_direction == Vector2.DOWN or move_direction == Vector2.LEFT:
				print("offseti: ", offset)
				if movement_cache.size() == 0:
					movement_cache.append(global_position -move_direction*5)
				else:
					movement_cache.append(global_position + offset)
		#test.global_position = global_position	
		await get_tree().create_timer(.25).timeout	
		#if movement_cache.is_empty():
			#return		
		timer += .25
		#if timer >= 1:
		if timer >= .5:
			can_pop_movement_cache = true

func pop_movement_cache():
	if not can_pop_movement_cache:
		return Vector2.ZERO
	if movement_cache.is_empty():  # use is_empty() instead of size() > 0
		return Vector2.ZERO
	return movement_cache.pop_front()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	timer += delta
	if timer > wall_check_interval:
		wall_check()
		timer = 0

func reset_movement_cache():
	is_building = false

func respond_to_command(current_command) -> bool:
	if current_command == "STOP" and velocity.length() > 0.1:
		print("vel > 0: ", velocity.length(), "dir: ", move_direction)
		return false
	elif current_command == "GO" and velocity.length() <= 0.1:
		return false
	else:
		return true

func _physics_process(delta: float) -> void:
	
	if eating_food: return
	
	if !can_move:
		velocity = Vector2.ZERO
		#return
	
	#ai_controlled =  !abs(Input.get_axis("move_left", "move_right")) > 0.01 \
	#and !abs(Input.get_axis("move_up", "move_down")) > 0.01
	
	ai_controlled =  smells_dog_food()
	
	if !is_ai:
		if !ai_controlled:
			move_direction.x = Input.get_axis("move_left", "move_right")
			move_direction.y = Input.get_axis("move_up", "move_down")
			move_direction = move_direction.normalized()
			
			print("MDIR: ", move_direction)
		
		elif !Game_Manager.is_objective_completed("find_food") and smells_dog_food():
			
			print("smells dog food")
			move_direction = (distractionsources.get_node("DogFood").global_position - global_position)
			move_speed = 20 + (move_direction.length()/40)*10
			if move_direction.length() > 0.1:
				velocity = move_direction.normalized()* move_speed
			else:
				velocity = velocity.move_toward(Vector2.ZERO, move_speed)
				if !eating_food:
					eating_food = true
					eat_food()
		else:
			velocity = velocity.move_toward(Vector2.ZERO, move_speed)		
			
		if !eating_food:
			move_and_slide()	
	
	elif can_move:
		print("moving ai")
		move_ai()
	
	if(move_direction-old_move_direction).length() > 0.1:
		if old_move_direction == Vector2.ZERO:
			on_started_moving.emit()
			can_move=true
			#build_movement_cache()
		if velocity.length() > 0 and move_direction != Vector2.ZERO:
			on_move_direction_changed.emit()
			if !check_obstacles() and old_move_direction == Vector2.UP or old_move_direction == Vector2.RIGHT or old_move_direction == Vector2.DOWN or old_move_direction== Vector2.LEFT:
				offset = old_move_direction * 5
			
	if move_direction and within_max_distance():
		velocity = move_direction * move_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed)
			
	if velocity == Vector2.ZERO:
		timer = 0
		can_pop_movement_cache = false
		can_move = false
	else:
		move()
	
	old_move_direction = move_direction


func move_ai():
	
	if ai_waypoint_index >= ai_path.get_children().size():
		return
	move_direction = ai_path.get_child(ai_waypoint_index).global_position - ai_path.get_child(ai_waypoint_index-1).global_position
	if (ai_path.get_child(ai_waypoint_index).global_position - global_position).length() > 2:
		velocity = move_direction.normalized() * move_speed
		move_and_slide()
	elif ai_waypoint_index < ai_path.get_children().size():
		ai_waypoint_index += 1
	else:
		queue_free()
		Game_Manager._ai_dog_owner.queue_free() 
	
func eat_food():
	_owner.make_nervous(5)
	await get_tree().create_timer(8).timeout
	eating_food = false
	Game_Manager.objective_completed("find_food")
	Game_Manager._ui.update_info("eaten food")
	_owner.current_command = "GO"

func initialize(owner:DogDowner):
	_owner = owner
	
func within_max_distance() -> bool:
	var dist = (move_direction+global_position-global_position).length()
	print("dist: ", dist)
	return true
	#return dist < max_distance

func wall_check():
	var from = global_position
	var found_wall := false
	
	for i in range(4):
		var to = from + directions[i]*10
		var query = PhysicsRayQueryParameters2D.create(
			from,
			to
		)
		query.exclude = [self, _owner]
		var result = get_world_2d().direct_space_state.intersect_ray(query)
		if !result.is_empty():
			found_wall = true	
			wall_normal = result.normal
			print(result.collider)
			is_near_wall = true
			if(wall_normal.distance_to(old_wall_normal) > 0.3):
				on_wall_normal_changed.emit(wall_normal,old_wall_normal)
			break
				
	if !found_wall:
		old_wall_normal = Vector2.ZERO
		is_near_wall = false
	else:
		old_wall_normal = wall_normal	
		#wall_normal = Vector2.ZERO

func switchedDirections() -> bool:
	print ("test: ", abs(old_move_direction.angle_to(move_direction)))
	return abs(old_move_direction.angle_to(move_direction)) > PI/1.5

func smells_dog_food():
	return (global_position - distractionsources.get_node("DogFood").global_position).length() < 40
	

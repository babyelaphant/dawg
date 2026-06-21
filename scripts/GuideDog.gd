class_name GuideDog
extends Movable

var old_move_direction:Vector2 = Vector2.ZERO

signal on_move_direction_changed(dog)
signal on_wall_normal_changed
signal on_started_moving(dog)

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
var dogs:Array[GuideDog] = []
var initialized = false
var can_update_movement_cache:bool = true
var wall_hit_point:Vector2
var start_barking:bool =false
@export var distractionsources: Node2D
@export var test:Sprite2D
@export var max_distance:float = 30
@export var ai_path:Node2D
@onready var audioSource = get_node("AudioSource")
@export var barksound:String = "bark2"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Game_Manager.register_dog(self)
	set_process_input(true)
	#can_move = true

func check_obstacles():
	var hitResult = {}
	for i in range(3):
		
		var line  = get_node("Line2D" + str(i))
		var space_state = get_world_2d().direct_space_state
		var from = global_position - move_direction.rotated(PI/2)*3 + i * move_direction.rotated(PI/2) * 3
		from = global_position
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

	#while is_building:		
		#if can_move:
			#if  move_direction == Vector2.UP or move_direction == Vector2.RIGHT or move_direction == Vector2.DOWN or move_direction == Vector2.LEFT:
				#print("offseti: ", offset)
				#if movement_cache.size() == 0:
					#movement_cache.append(wall_hit_point+wall_normal*15)
				#else:
					#movement_cache.append(wall_hit_point+wall_normal*15)
				#test.global_position = wall_hit_point+wall_normal*15
		#await get_tree().create_timer(.25).timeout	
		##if movement_cache.is_empty():
			##return		
		#timer += .25
		##if timer >= 1:
		#if timer >= .5:
			#can_pop_movement_cache = true

func pop_movement_cache():
	if not can_pop_movement_cache:
		return Vector2.ZERO
	if movement_cache.is_empty():  # use is_empty() instead of size() > 0
		return Vector2.ZERO
	return movement_cache.pop_front()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	#if !is_ai:
		#test.global_position = global_position+wall_normal*15
	
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
		
	if !initialized:
		return
		
	timer += delta	
	if timer > wall_check_interval:
		wall_check()
		if is_building and can_move:
			print("GOOD BUILDING", "CACHE SIZE: ", movement_cache.size())
			#if  move_direction == Vector2.UP or move_direction == Vector2.RIGHT or move_direction == Vector2.DOWN or move_direction == Vector2.LEFT
			#movement_cache.append(global_position+wall_normal*10)
			movement_cache.append(global_position+wall_normal*10)
			#get_wall_normal()
			#test.global_position = global_position+wall_normal*10
		if movement_cache.size() > 3:
			can_pop_movement_cache = true
			timer = 0
		
		
	var nearby_dog = smells_dog()
	
	var distance_to_food = (global_position - distractionsources.get_node("DogFood").global_position).length()
	
	if is_ai:
		ai_controlled =  !nearby_dog.is_empty()  and nearby_dog[0].ai_controlled#and abs((nearby_dog[0] as GuideDog).move_direction.angle_to(move_direction)) > PI/2 #and nearby_dog[0].ai_controlled 
	else:
		ai_controlled =  abs(Input.get_axis("move_left", "move_right")) < 0.1 \
		and abs(Input.get_axis("move_up", "move_down")) < 0.1 and ((smells_dog_food() and distance_to_food <=40) or (!nearby_dog.is_empty()) and (velocity.length() < 0.1 or  abs((nearby_dog[0] as GuideDog).move_direction.angle_to(move_direction)) > PI/2))

	if !is_ai:
		if  !Game_Manager.is_objective_completed("find food") and smells_dog_food():
			print("smells dog food")
			
			if distance_to_food < 40:
				move_direction = (distractionsources.get_node("DogFood").global_position - global_position).normalized()
				move_speed = 30 + (distance_to_food/40)*10
				if !start_barking:
					Sound_Manager.play_sound($AudioSource,"bark2")
					start_barking = true
			else:
				move_speed = 30 + (distance_to_food/200)*10
				
			if distance_to_food > 5:
				velocity = move_direction.normalized()* move_speed
			else:
				velocity = velocity.move_toward(Vector2.ZERO, move_speed)
				if !eating_food:
					eating_food = true
					eat_food()
	
	if nearby_dog != []:
		print("smells dog")
		
		if (nearby_dog[0].global_position - global_position).length() > 15:
			
			if !start_barking and !nearby_dog[0].start_barking:
				Sound_Manager.play_sound($AudioSource,barksound)
				start_barking= true
			elif !start_barking:
				start_barking= true
				await get_tree().create_timer(1).timeout
				Sound_Manager.play_sound($AudioSource,barksound)
	
			if ai_controlled:
				move_direction = (nearby_dog[0].global_position - global_position).normalized()
				move_speed = 30 + ((nearby_dog[0].global_position - global_position).length()/150)*10
				velocity = move_direction.normalized()* move_speed
					
		else:
			velocity = velocity.move_toward(Vector2.ZERO, move_speed)
	
	if !is_ai:
		if !ai_controlled:
			move_direction.x = Input.get_axis("move_left", "move_right")
			move_direction.y = Input.get_axis("move_up", "move_down")
			move_direction = move_direction.normalized()
			velocity = move_direction.normalized()* move_speed
		if !eating_food:
			move_and_slide()	
	
	else:
		if !ai_controlled:
			move_ai()
		elif velocity.length() > 0:
			move_and_slide()
	
	if start_barking and !smells_dog() and !smells_dog_food():
		start_barking = false
		
	if(move_direction-old_move_direction).length() >0.1:
		can_update_movement_cache = false
		if old_move_direction == Vector2.ZERO:
			on_started_moving.emit(self)
			can_move=true
			#build_movement_cache()
			
	if(move_direction-old_move_direction).length() > 0.1:		
		on_move_direction_changed.emit(self)

	if move_direction and within_max_distance():
		velocity = move_direction * move_speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, move_speed)
			
	if velocity == Vector2.ZERO:
		timer = 0
		#can_pop_movement_cache = false
		can_move = false

	move()
	
	old_move_direction = move_direction


func move_ai():
	
	if ai_waypoint_index >= ai_path.get_children().size():
		return
	move_direction = (ai_path.get_child(ai_waypoint_index).global_position - global_position).normalized()
	if (ai_path.get_child(ai_waypoint_index).global_position - global_position).length() > 1:
		velocity = move_direction * move_speed
		move_and_slide()
	elif ai_waypoint_index < ai_path.get_children().size():
		ai_waypoint_index += 1
	else:
		queue_free()
		Game_Manager._ai_dog_owner.queue_free() 
	
func eat_food():
	_owner.make_nervous(5)
	await get_tree().create_timer(2).timeout
	eating_food = false
	Game_Manager.objective_completed("find food")
	Game_Manager._ui.update_info("eaten food")
	print("eaten food")
	_owner.current_command = "GO"

func initialize(owner:DogDowner):
	_owner = owner
	initialized = true
	findByNameTag(get_tree().current_scene, "GuideDog", dogs)
	print("DOGS: ", dogs)
	
func within_max_distance() -> bool:
	var dist = (move_direction+global_position-global_position).length()
	print("dist: ", dist)
	return true
	#return dist < max_distance

func wall_check():
	var found_wall := false
	wall_normal = Vector2.ZERO
	var wn = Vector2.ZERO
	var hits = []
	var offsets =[-2,0,2]
	if is_ai:return
	for i in range(4):
		for j in range(3):
			var line  = get_node("Line2D" + str(j))
			var from = global_position + offsets[j]*directions[i].rotated(PI/2)
			var to = from + directions[i]*10
			var query = PhysicsRayQueryParameters2D.create(
				from,
				to
			)
			#if i==0:
				#line.clear_points()
				#line.add_point(to_local(from))
				#line.add_point(to_local(to))
				#line.width = .1
			query.exclude = [self, _owner]
			var result = get_world_2d().direct_space_state.intersect_ray(query)
			if !result.is_empty():
				hits.append(result)
				found_wall = true	
				wall_normal = result.normal
				wall_hit_point = result.position
				print("wallnormal: ", wall_normal)
				is_near_wall = true
				#if(wall_normal.distance_to(old_wall_normal) > 0.3):
					#on_wall_normal_changed.emit(wall_normal,old_wall_normal)
				break
		#if found_wall: break
	if !found_wall:
		old_wall_normal = Vector2.ZERO
		is_near_wall = false
	else:	
		pass
		var mindist = 100
		for i in range(hits.size()):
			var dist = (global_position - hits[i].position).length()
			if dist < mindist:
				mindist = dist
				wn = hits[i].normal
		old_wall_normal = wall_normal	
		wall_normal = wn
	##if wn != Vector2.ZERO:
		#wall_normal = wn
	
func switchedDirections() -> bool:
	print ("test: ", abs(old_move_direction.angle_to(move_direction)))
	return abs(old_move_direction.angle_to(move_direction)) > PI/1.5

func smells_dog_food():
	return (global_position - distractionsources.get_node("DogFood").global_position).length() < 200
	
func findByNameTag(node: Node, tag : String, result : Array) -> void:
	for child in node.get_children():
		print("child: ", child)
		if tag in child.name:
			result.push_back(child)
		findByNameTag(child, tag, result)
		
func smells_dog() -> Array[GuideDog]:
	for i in range(dogs.size()):
		if dogs[i] == self:
			continue
		if (dogs[i].global_position - global_position).length() < 150:
			return [dogs[i]]
	return []

func move():
	super.move()
	if velocity.length() < 0.1:
		if target_anim == "walk_n":
			target_anim = "idle_n"
		elif target_anim == "walk_e":
			target_anim = "idle_e"
		elif target_anim == "walk_s":
			target_anim = "idle_s"
		elif target_anim == "walk_w":
			target_anim = "idle_w"
		elif target_anim in ["walk_nw","walk_sw"]:
			target_anim = "idle_w"
		elif target_anim in ["walk_ne","walk_se"]:
			target_anim = "idle_e"
		play_animation(target_anim)

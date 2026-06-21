class_name Car
extends CharacterBody2D

@export var move_speed : float = 40
@onready var sprite: Sprite2D = $Sprite2D
var _car_path:Node2D
var current_waypoint:int = 1
var initialized:bool = false
var checkpoint:Vector2 = Vector2.ZERO
var move_direction:Vector2 = Vector2.ZERO
var target_anim:String = ""
var update_pose_interval:float = 0.25
var timer:float = 0
static var collided_car = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("car ready")
	#Game_Manager.load_checkpoints.connect(load_checkpoint)
	saveCheckPoint()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	timer += delta
	if !initialized or _car_path == null:
		return
	
	if current_waypoint == _car_path.get_children().size():
		queue_free()
		return
	
	if current_waypoint < 3:
		move_speed = 105
	else:
		move_speed = 120
		
	#Game_Manager._dog_owner.test.global_position = _car_path.get_child(current_waypoint).position
	print("collided car: ", collided_car)
	move_direction = (_car_path.get_child(current_waypoint).global_position - _car_path.get_child(current_waypoint-1).global_position).normalized()
	if timer > update_pose_interval:
		update_pose()
		timer = 0
		
	var collision = move_and_collide(velocity*delta)
		
	if collision and collided_car == null:
		if not collision.get_collider() is DogDowner and not collision.get_collider() is GuideDog : 
			print("what?")
			return
		collided_car = self
		#.get_collider().get_node("CollisionShape2D").disabled = true
		Game_Manager.new_attempt()
		if !Game_Manager.gamelost:
			global_position = Vector2.ZERO
	
	if (_car_path.get_child(current_waypoint).global_position - global_position).length() > 2:
		velocity = move_direction* move_speed

	elif current_waypoint < _car_path.get_children().size():
		velocity = Vector2.ZERO
		current_waypoint += 1
		print("current wp: ", current_waypoint)

func load_checkpoint():
	global_position = checkpoint
	await get_tree().create_timer(0.2).timeout

func update_pose():
	
	var texture = null

	if abs(move_direction.angle())< PI/8:
		texture = load('res://assets/cars/Red-Rolls-Royce Phantom/Idle/move_e.png')
	if abs(move_direction.angle_to(Vector2.from_angle(PI/4))) < PI/8:
		texture = load('res://assets/cars/Red-Rolls-Royce Phantom/Idle/move_se.png')
	if abs(move_direction.angle_to(Vector2.from_angle(PI/2)))< PI/8:
		texture = load('res://assets/cars/Red-Rolls-Royce Phantom/Idle/move_s.png')
	if abs(move_direction.angle_to(Vector2.from_angle(PI/2 + PI/4)))< PI/8:
		texture = load('res://assets/cars/Red-Rolls-Royce Phantom/Idle/move_sw.png')
	if abs(move_direction.angle_to(Vector2.from_angle(PI)))< PI/8:
		texture = load('res://assets/cars/Red-Rolls-Royce Phantom/Idle/move_w.png')
	if abs(move_direction.angle_to(Vector2.from_angle(PI + PI/4)))< PI/8:
		texture = load('res://assets/cars/Red-Rolls-Royce Phantom/Idle/move_nw.png')
	if abs(move_direction.angle_to(Vector2.from_angle(PI + PI/2)))< PI/8:
		texture = load('res://assets/cars/Red-Rolls-Royce Phantom/Idle/move_n.png')
	if abs(move_direction.angle_to(Vector2.from_angle(PI + PI/2 +PI/4)))< PI/8:
		texture = load('res://assets/cars/Red-Rolls-Royce Phantom/Idle/move_ne.png')
	
	sprite.texture = texture
	
func saveCheckPoint():
	while(!Game_Manager.gamelost and !Game_Manager.gamewon and collided_car == null):
		if Game_Manager._dog.velocity.length() <= 0:
			checkpoint = global_position
		await get_tree().process_frame

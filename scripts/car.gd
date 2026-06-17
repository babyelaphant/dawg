class_name Car
extends CharacterBody2D

@export var move_speed : float = 40
var _car_path:Node2D
var current_waypoint:int = 1
var initialized:bool = false
var checkpoint:Vector2 = Vector2.ZERO
static var collided_car = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("car ready")
	Game_Manager.load_checkpoints.connect(load_checkpoint)
	saveCheckPoint()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	if !initialized or _car_path == null:
		return
	
	if current_waypoint == _car_path.get_children().size():
		queue_free()
		return
		
	#Game_Manager._dog_owner.test.global_position = _car_path.get_child(current_waypoint).position
	print("collided car: ", collided_car)
	var direction = _car_path.get_child(current_waypoint).global_position - _car_path.get_child(current_waypoint-1).global_position
	if (_car_path.get_child(current_waypoint).global_position - global_position).length() > 2:
		velocity = direction.normalized() * move_speed
		var collision = move_and_collide(velocity*delta)
		
		if collision and collided_car == null:
			if not collision.get_collider() is DogDowner and not collision.get_collider() is GuideDog : 
				return
			collided_car = self
			collision.get_collider().get_node("CollisionShape2D").disabled = true
			Game_Manager.new_attempt()

	elif current_waypoint < _car_path.get_children().size():
		current_waypoint += 1
		print("current wp: ", current_waypoint)

func load_checkpoint():
	global_position = checkpoint
	await get_tree().create_timer(0.2).timeout

func saveCheckPoint():
	while(!Game_Manager.game_lost() and !Game_Manager.game_won() and collided_car == null):
		if Game_Manager._dog.velocity.length() <= 0:
			checkpoint = global_position
		await get_tree().process_frame

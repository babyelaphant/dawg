class_name Movable
extends CharacterBody2D

@export var move_speed: float
@onready var sprite:AnimatedSprite2D = $AnimatedSprite
var move_direction:Vector2 = Vector2.ZERO
var can_move:float = false
var target_anim = ""
var ai_controlled:bool = false
@export var is_ai:bool = false

@export var _animations:Array[String]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process_input(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	
	print(target_anim)
	if can_move:
		move_and_slide()
		
	if is_on_wall():
		print("on wall")
		velocity.y = clamp(velocity.y, -INF, 0)
		
	if is_on_floor():
		velocity.y = clamp(velocity.y, -INF, 0)
		
func idle():
	if sprite != null:
		sprite.play("idle_s")
	
func play_animation(direction:String):
	if sprite != null and direction in _animations:
		sprite.play(direction)

func move():
	if abs(move_direction.angle())< PI/8:
		target_anim = "walk_e"
	if abs(move_direction.angle_to(Vector2.from_angle(PI/4))) < PI/8:
		target_anim = "walk_se"
	if abs(move_direction.angle_to(Vector2.from_angle(PI/2)))< PI/8:
		target_anim = "walk_s"
	if abs(move_direction.angle_to(Vector2.from_angle(PI/2 + PI/4)))< PI/8:
		target_anim = "walk_sw"
	if abs(move_direction.angle_to(Vector2.from_angle(PI)))< PI/8:
		target_anim = "walk_w"
	if abs(move_direction.angle_to(Vector2.from_angle(PI + PI/4)))< PI/8:
		target_anim = "walk_nw"
	if abs(move_direction.angle_to(Vector2.from_angle(PI + PI/2)))< PI/8:
		target_anim = "walk_n"
	if abs(move_direction.angle_to(Vector2.from_angle(PI + PI/2 +PI/4)))< PI/8:
		target_anim = "walk_ne"

	play_animation(target_anim)

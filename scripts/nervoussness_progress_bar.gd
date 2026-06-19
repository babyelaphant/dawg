class_name NervousenessProgressBar
extends TextureProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func increase__meter(amount) -> void:
	if self.value < self.max_value:
		self.value += amount

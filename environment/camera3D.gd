extends Camera3D
@onready var player = $"../Player"

func _physics_process(delta):
	global_position.x = player.current_level * 50


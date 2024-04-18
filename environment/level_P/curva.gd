extends LevelNode



# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_final_target_body_entered(body):
	if body.is_class("CharacterBody3D"):
		var rotate = randi_range(0,1) 
		find_child("Curve").rotation.x = deg_to_rad(180 * rotate)
		find_child("Target").rotation.x = deg_to_rad(180 * rotate)
		find_child("Spawn").position.z = 8 if rotate == 0 else -8

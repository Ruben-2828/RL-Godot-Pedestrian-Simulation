extends LevelNode

# extract a boolean and if it is 1 rotate the env
func _on_final_target_body_entered(body):
	if body.is_class("CharacterBody3D"):
		var rotate = randi_range(0,1) 
		find_child("Curve").rotation.x = deg_to_rad(180 * rotate)
		find_child("Target").rotation.x = deg_to_rad(180 * rotate)
		find_child("Spawn").position.z = 8 if rotate == 0 else -8
		find_child("Spawn").rotation.y = deg_to_rad(180 * (1 - rotate))

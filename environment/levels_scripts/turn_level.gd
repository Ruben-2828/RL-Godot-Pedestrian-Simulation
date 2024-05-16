extends LevelNode

## Extract a boolean and if it is 1 rotate the level
func _on_final_target_body_entered(body):
	if body.is_class("CharacterBody3D"):
		var rotate = randi_range(0,1) 
		find_child("AllTargets").rotation.y = deg_to_rad(90 * rotate)
		find_child("Oblique").rotation.x = deg_to_rad(180 * rotate)
		find_child("Final").rotation.z = deg_to_rad(180 * rotate)
		find_child("Walls").rotation.y = deg_to_rad(90 * rotate)
		find_child("Curve").rotation.x = deg_to_rad(180 * rotate)
		find_child("Curve").rotation.y = deg_to_rad(180 * rotate)
		find_child("Pedestrian").rotation.y = deg_to_rad(180) if rotate == 0 else deg_to_rad(-90)

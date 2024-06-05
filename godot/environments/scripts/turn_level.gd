extends LevelNode

## Extract a boolean and if it is 1 rotate the level
func _on_final_target_body_entered(body):
	if body.is_class("CharacterBody3D"):
		var rotate = randi_range(0,1) 
		
		find_child("AllTargets").rotation.y = deg_to_rad(90 * rotate)
		find_child("Final").rotation.z = deg_to_rad(180 * rotate)
		var pedestrian = find_child("Pedestrian")
		find_child("PedestrianController").initial_rot[pedestrian].y = deg_to_rad(180) if rotate == 1 else deg_to_rad(-90)
			
		var walls = find_child("Walls")
		if walls != null:
			walls.rotation.y = deg_to_rad(90 * rotate)
		
		if self.name == "TurnsObstacles":
			find_child("Oblique").rotation.x = deg_to_rad(180 * rotate)
			find_child("Curve").rotation.x = deg_to_rad(180 * rotate)
			find_child("Curve").rotation.y = deg_to_rad(180 * rotate)
		
		if self.name == "Turns":
			find_child("Oblique").rotation.z = deg_to_rad(180 * rotate)
			find_child("Curve").rotation.z = deg_to_rad(180 * rotate)
			find_child("Curve").rotation.y = deg_to_rad(90 * rotate)
		

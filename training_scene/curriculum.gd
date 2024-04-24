extends Node3D

var training_scene: PackedScene
var retraining_scene: PackedScene
var consolidation_scene: PackedScene

var current_phase: int = 0
var current_scene: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	training_scene = preload("res://training_scene/training_scene.tscn")
	retraining_scene = preload("res://training_scene/training_scene.tscn")
	consolidation_scene = preload("res://training_scene/training_scene.tscn")
	
	set_current_phase()

func set_current_phase() -> void:
	
	if current_scene != null:
		current_scene.queue_free()
		
	if current_phase == 0:
		print("Starting training phase")
		current_scene = training_scene.instantiate()
		current_scene.set_name("training scene")
		current_scene.end_training.connect(step_phase)
		add_child(current_scene)
		
	if current_phase == 1:
		print("Starting retraining phase")
		current_scene = retraining_scene.instantiate()
		current_scene.set_name("retraining scene")
		add_child(current_scene)
		
	if current_phase == 2:
		print("Starting consolidation phase")
		current_scene = consolidation_scene.instantiate()
		current_scene.set_name("consolidation scene")
		add_child(current_scene)
		
func step_phase() -> void:
	print("changing phase")
	current_phase += 1
	
	if current_phase > 2:
		get_tree().quit()
		
	set_current_phase()

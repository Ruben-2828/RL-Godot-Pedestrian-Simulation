extends Node3D

@export_group("Levels")
## List of levels used in curriculum
@export var levels_path: Array[PackedScene]

var training_scene: PackedScene
var retraining_scene: PackedScene
var consolidation_scene: PackedScene

var current_phase: int = 0
var current_scene: CurriculumPhase

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(levels_path.size() > 0, "No scenes set")
	assert(check_levels(), "Null levels found in levels array")
	
	training_scene = preload("res://training_scene/training_scene.tscn")
	retraining_scene = preload("res://training_scene/retraining_scene.tscn")
	consolidation_scene = preload("res://training_scene/training_scene.tscn")
	
	set_current_phase()

## Checks the levels list in input
func check_levels() -> bool:
	for l in levels_path:
		if l == null:
			return false
	return true

func set_current_phase() -> void:
	
	if current_scene != null:
		current_scene.queue_free()
		
	if current_phase == 0:
		print("Starting training phase")
		current_scene = training_scene.instantiate()
		current_scene.set_name("training scene")
		current_scene.end_phase.connect(step_phase)
		current_scene.levels_path = levels_path
		add_child(current_scene)
		
	if current_phase == 1:
		print("Starting retraining phase")
		current_scene = retraining_scene.instantiate()
		current_scene.set_name("retraining scene")
		current_scene.end_phase.connect(step_phase)
		current_scene.levels_path = levels_path
		add_child(current_scene)
		
	if current_phase == 2:
		print("Starting consolidation phase")
		current_scene = consolidation_scene.instantiate()
		current_scene.set_name("consolidation scene")
		current_scene.end_phase.connect(step_phase)
		current_scene.levels_path = levels_path
		add_child(current_scene)
		
	current_scene.levels_path = levels_path
		
func step_phase() -> void:
	print("changing phase")
	current_phase += 1
	
	if current_phase > 1:
		get_tree().quit()
		
	set_current_phase()

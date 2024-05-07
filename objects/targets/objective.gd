extends Area3D

@export var active: bool = true

signal custom_body_entered(area: Area3D, body: Node3D)

# Called when the node enters the scene tree for the first time.
func _ready():
	self.body_entered.connect(_custom_body_entered)

func _custom_body_entered(body: Node3D):
	if active:
		custom_body_entered.emit(self, body)
	#print("custom signal funzionante")

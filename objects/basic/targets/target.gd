extends Area3D

signal custom_body_entered(area: Area3D, body: Node3D)

# Called when the node enters the scene tree for the first time.
func _ready():
	self.body_entered.connect(_custom_body_entered)

func _custom_body_entered(body: Node3D):
	custom_body_entered.emit(self, body)
	#print("custom signal funzionante")

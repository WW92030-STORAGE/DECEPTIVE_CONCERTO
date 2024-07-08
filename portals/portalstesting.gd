extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	GlobalVariables.CURRENT_LEVEL = get_tree().get_current_scene().get_name()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

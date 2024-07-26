extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.



func _on_vorspiel_pressed():
	get_tree().change_scene_to_file("res://levels/vorspiel.tscn")



func _on_protogen_pressed():
	get_tree().change_scene_to_file("res://levels/protogen.tscn")

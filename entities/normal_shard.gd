extends CharacterBody3D

var dir = 1

func _ready():
	$ShardMesh.rotation.y = randi_range(0, 360 * PI)
	dir = 0.05 * (randi_range(0, 1) - 0.5)
	

func _physics_process(delta):
	var list = $Area3D.get_overlapping_bodies()
	for body in list:
		if body.name == "Player":
			# Play audio
			var players = get_tree().get_nodes_in_group("PLAYER")
			for plr in players:
				plr.shardcollect()
			queue_free()
			
	$ShardMesh.rotation.y = $ShardMesh.rotation.y + dir

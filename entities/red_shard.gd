extends CharacterBody3D

var dir = 1

var TIMESTAMP = -1000000

func _ready():
	$ShardMesh.rotation.y = randi_range(0, 360 * PI)
	dir = 0.05 * (randi_range(0, 1) - 0.5)
	

func _physics_process(delta):
	var list = $Area3D.get_overlapping_bodies()
	for body in list:
		if body.name == "Player":
			# Play audio
			var players = get_tree().get_nodes_in_group("PLAYER")
			GlobalVariables.ENEMIES_REVEALED = Time.get_ticks_msec()
			GlobalVariables.BONUS = GlobalVariables.BONUS + 1
			queue_free()
			
	$ShardMesh.rotation.y = $ShardMesh.rotation.y + dir
	
	var tickspassed = Time.get_ticks_msec() - TIMESTAMP
	if tickspassed > TIMESTAMP + 50 * 1000:
		if tickspassed % 500 < 250:
			$ShardMesh.scale = Vector3(0, 0, 0)
		else:
			$ShardMesh.scale = Vector3(0.2, 0.2, 0.2)
	if tickspassed > TIMESTAMP + 60 * 1000:
		$ShardMesh.scale = Vector3(0.2, 0.2, 0.2)
		if len(GlobalVariables.INITSHARDS) <= 0:
			return
		var randpos = GlobalVariables.INITSHARDS[randi_range(0, len(GlobalVariables.INITSHARDS) - 1)]
		TIMESTAMP = Time.get_ticks_msec()
		
		global_transform.origin = randpos
		

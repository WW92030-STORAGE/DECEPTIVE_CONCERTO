extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	var curtime = Time.get_ticks_msec()
	print("BEGIN", Time.get_ticks_msec() - curtime)
	$NavigationRegion3D.bake_navigation_mesh()
	
	for i in range(AudioServer.bus_count):
		print(i, AudioServer.get_bus_name(i))
		
	GlobalVariables.CURRENT_LEVEL = get_tree().get_current_scene().get_name()
		
	GlobalVariables.LIVES = GlobalVariables.INITLIVES
	GlobalVariables.SHARDSCOLLECTED = 0
	GlobalVariables.SHARDSTREAK = 0
	GlobalVariables.CURRENTSTREAK = 0
	GlobalVariables.TIME_START = Time.get_ticks_msec()
	GlobalVariables.BONUS = 0
	GlobalVariables.SECRETS = 0
	
	print("DATA RESET", Time.get_ticks_msec() - curtime)
	
	GlobalVariables.SHARDS = get_tree().get_nodes_in_group("SOUL_SHARD")
	GlobalVariables.INITSHARDS = []
	for shard in GlobalVariables.SHARDS:
		GlobalVariables.INITSHARDS.append(shard.global_transform.origin)
		
	
	print("SHARDS PLACED", Time.get_ticks_msec() - curtime)
	
	# print(GlobalVariables.INITSHARDS)
	
	
	# Spawn enemies
	
	GlobalVariables.spawnEnemies()
	
	print("ENEMIES SPAWNED", Time.get_ticks_msec() - curtime)



# Called every frame. 'delta' is the elapsed time since the previous frame.

var prevchase = false
var anychase = false
func _process(delta):
	prevchase = anychase
	anychase = false
	for node in get_tree().get_nodes_in_group("ENEMY"):
		if node.chasing:
			anychase = true
			
	if anychase != prevchase:
		print("CHASE STATUS ", anychase)
		if anychase:
			$MusicPanic.play()
			$MusicNormal.stop()
		else:
			$MusicPanic.stop()
			$MusicNormal.play()

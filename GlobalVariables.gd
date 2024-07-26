extends Node

var PlayerLocation = Vector3()
var Player = null
var PlayerPitch = 0
var PlayerInit = Vector3()
var PlayerCamRotation = Vector3()
var PlayerCamBasis = Basis()

var SHARDS = []
var INITSHARDS = [] # Initial shard positions
var SHARDSCOLLECTED = 0
var SHARDSTREAK = 0
var CURRENTSTREAK = 0
var TIME_START = 0
var TIME_END = 0

var INITLIVES = 0
var LIVES = 0

var SECRETS = 0
var BONUS = 0

var ENEMIES_REVEALED = -1 # Starting time of the enemies revealed
var SPEED_BOOST = 0

var CURRENT_LEVEL = "..."
var PLAYER_DEAD = false

# Portal values

var DISP_RED = Vector3()
var DISP_CYAN = Vector3()
var RED_TP = Vector3()
var CYAN_TP = Vector3()
var INSIDE_PORTAL_RED = false
var INSIDE_PORTAL_CYAN = false
var SAVED_V = null
var MOMENTUM_CONS = 0

# Audio data

var VOLUME = 10

func rotate(b1, b2):
	var rot1 = Quaternion(b1)
	var rot2 = Quaternion(b2)
	return Basis(rot1 * rot2)

func sigmoid(x, slope = 1):
	var res = 1 + exp(-2 * slope * x)
	return (2.0 / res) - 1
	
func normalizedVolume():
	var normalized = GlobalVariables.sigmoid(GlobalVariables.VOLUME + 60, 1.0 / 40.0)
	if (normalized < 0):
		normalized = 0
	elif (normalized > 1):
		normalized = 1
	return normalized

func basisnormal(new_y):
	var res = Basis()
	res.y = new_y
	res.x = res.y.cross(Vector3(randf_range(0, 1), randf_range(0, 1), randf_range(0, 1)))
	
	res = res.orthonormalized()
	
	var desired = Vector3(0, 1, 0) - Vector3(0, 1, 0).project(res.y)
	if desired != Vector3(0, 0, 0):
		res.x = desired
	else:
		desired = Vector3(1, 0, 0) - Vector3(1, 0, 0).project(res.y)
		if desired != Vector3(0, 0, 0):
			res.x = desired
	
	res.z = (res.x).cross(res.y)
	print(res)
	res = res.orthonormalized()
	return res.orthonormalized()

	
func rem(a, b):
	var res = fmod(a, b)
	while (res < 0):
		res = res + b
	return fmod(res, b)

func killPlayer():
	PLAYER_DEAD = true
	CURRENTSTREAK = 0
	var sc = get_tree().current_scene
	despawnEnemies()
	LIVES = LIVES - 1
	print("LIVES DECREMENTED")
	Player.death()
	prepareLoading()
	# get_tree().change_scene_to_file(sc.scene_file_path)
	
var LOAD_QUEUE = 0
var LOAD_MUTEX = Mutex.new()

func request(enemyType):
	LOAD_MUTEX.lock()
	ResourceLoader.load_threaded_request(enemyType)
	LOAD_QUEUE = LOAD_QUEUE + 1
	print("ENQUEUE", str(enemyType), LOAD_QUEUE)
	LOAD_MUTEX.unlock()
	
func instance(enemyType): # horrible mutexed preload system
	LOAD_MUTEX.lock()
	var result = ResourceLoader.load_threaded_get(enemyType)
	LOAD_QUEUE = LOAD_QUEUE - 1
	print("DEQUEUE", str(enemyType), LOAD_QUEUE)
	LOAD_MUTEX.unlock()
	return result
	
func flush():
	LOAD_MUTEX.lock()
	while true:
		for listing in ENEMY_SPAWNS:
			for enemyType in ENEMY_SPAWNS[listing]:
				for position in ENEMY_SPAWNS[listing][enemyType]:
					var x = ResourceLoader.load_threaded_get(enemyType)
					if x != null:
						LOAD_QUEUE -= 1
					print("FLUSH", str(x), LOAD_QUEUE)
					if LOAD_QUEUE <= 0:
						LOAD_MUTEX.unlock()
						return

func prepareLoading():
	if (LOAD_QUEUE > 0):
		flush()
	
	for listing in ENEMY_SPAWNS:
		for enemyType in ENEMY_SPAWNS[listing]:
			for position in ENEMY_SPAWNS[listing][enemyType]:
				request(enemyType)

# Called when the node enters the scene tree for the first time.
func _ready():
	prepareLoading()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	VOLUME = (AudioServer.get_bus_peak_volume_left_db(1,0) + AudioServer.get_bus_peak_volume_right_db(1,0)) / 2
	
	if ENEMIES_REVEALED >= 0 and Time.get_ticks_msec() - ENEMIES_REVEALED > 60 * 1000:
		ENEMIES_REVEALED = -1
		
	var enemymarkers = get_tree().get_nodes_in_group("REVEAL_MARKER")
	for node in enemymarkers:
		if ENEMIES_REVEALED >= 0:
			var currentscale = node.scale.x
			node.scale = move_toward(currentscale, 1, 0.05) * Vector3(1, 0, 1) + Vector3(0, 1, 0)
		else:
			var currentscale = node.scale.x
			node.scale = move_toward(currentscale, 0, 0.05) * Vector3(1, 0, 1) + Vector3(0, 1, 0)
	
	SHARDSTREAK = max(SHARDSTREAK, CURRENTSTREAK)
	
	pass

func despawnEnemies(): # Despawn all existing enemies
	print("DESPAWNING ENEMIES")
	var enemies = get_tree().get_nodes_in_group("ENEMY")
	print(enemies)
	for node in enemies:
		node.queue_free()
	
	print("ENEMIES DESPAWNED")

func spawnEnemies(): # Spawn enemies after clearing all existing ones
	var curtime = Time.get_ticks_msec()
	print("> SPAWNING ENEMIES...")
	despawnEnemies()
	print("> DESPAWNED", Time.get_ticks_msec() - curtime)
	if get_tree().get_current_scene().get_name() not in GlobalVariables.ENEMY_SPAWNS:
		return
		
	var enemylisting = GlobalVariables.ENEMY_SPAWNS[get_tree().get_current_scene().get_name()]
	print("> ENEMY DATA RETRIEVED", Time.get_ticks_msec() - curtime)
	for enemyType in enemylisting:
		while (ResourceLoader.load_threaded_get_status(enemyType) < 3):
			continue
		for position in enemylisting[enemyType]:
			var node = instance(enemyType).instantiate()
			node.global_transform.origin = position
			get_tree().get_current_scene().add_child(node)
			print(">> PLACED ENEMY", Time.get_ticks_msec() - curtime)
		print(">> FINISHED PLACING ENEMIES", str(enemyType), Time.get_ticks_msec() - curtime)
	
	print("> ENEMIES RESPAWNED...", Time.get_ticks_msec() - curtime)
			
func respawn(): # Respawn Player
	Player.global_transform.origin = PlayerInit

# Data of enemies
var ENEMY_SPAWNS = {"VORSPIEL": 
	{"res://entities/BZ_protogen.tscn": [Vector3(-32, 0, 32), Vector3(32, 0, 32), Vector3(32, 0, -32), Vector3(-32, 0, -32)]},
	"PROTOGEN":
	{"res://entities/BZ_protogen_173.tscn": [Vector3(-78, 0, -38), Vector3(78, 0, 38)],
	"res://entities/BZ_protogen_371.tscn": [Vector3(78, 0, -38), Vector3(-78, 0, 38)]}
	}

# Powers per level
var POWERS = {"VORSPIEL": [], 
"PROTOGEN": ["PORTALS", "SPEED"],
"PORTALS_TEST": ["PORTALS"]
}

# Power sprites
var P_SPR = {"SPEED": "res://sprites/SPEEDBOOST.png", "PORTALS": "res://sprites/TELEPORT.png"}

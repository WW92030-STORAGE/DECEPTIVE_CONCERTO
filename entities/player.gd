extends CharacterBody3D

var NORM_WALK = 3
var SPEED_WALK = 5

var WALK = 3
var RUN = 2 * WALK
# How fast the player moves in meters per second.
@export var speed = WALK
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 25

var target_velocity = Vector3.ZERO

var MAPSIZE = 20

var GRACE_PERIOD = 0 # Grace spawn period

var POWERS = []
var LPOWER = 0
var RPOWER = 0

# Powers!
var SPEED_ON = false # Is active or in cooldown
var SPEED_COOL = 20 # Cooldown in seconds (including duration)
var SPEED_DUR = 8 # Duration in seconds
var SPEED_TIME = null # Timestamp of last activation

func _ready():
	GlobalVariables.Player = self
	GlobalVariables.PlayerInit = global_transform.origin
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	rotation.x = 0
	rotation.z = 0
	$CanvasLayer.hide()
	GlobalVariables.SHARDS = get_tree().get_nodes_in_group("SOUL_SHARD")
	
	var scname = get_tree().get_current_scene().get_name()
	if scname not in GlobalVariables.POWERS:
		return
	
	for thing in GlobalVariables.POWERS[scname]:
		POWERS.append(thing)
	
	print(POWERS)
	
	if (len(POWERS) <= 0):
		LPOWER = -1;
		RPOWER = -1;
		$Head/Camera3D/SpringArm3D/TABLET/LP.get_active_material(0).albedo_color = Color(0, 0, 0)
		$Head/Camera3D/SpringArm3D/TABLET/RP.get_active_material(0).albedo_color = Color(0, 0, 0)
	else:
		LPOWER = 0
		RPOWER = 0

func getLP():
	if (len(POWERS) <= 0) or (LPOWER < 0):
		return ""
	return POWERS[LPOWER]

func getRP():
	if (len(POWERS) <= 0) or (RPOWER < 0):
		return ""
	return POWERS[RPOWER]

# p is the string name of the power in question
func activatePower(p):
	if p == "SPEED":
		if not SPEED_ON:
			SPEED_ON = true
			SPEED_TIME = Time.get_ticks_msec()
			return
		

func setIcons():
	if getLP() == "SPEED":
		if SPEED_ON:
			$Head/Camera3D/SpringArm3D/TABLET/LP.get_active_material(0).albedo_color = Color(0.5, 1, 1)
		else:
			$Head/Camera3D/SpringArm3D/TABLET/LP.get_active_material(0).albedo_color = Color(1, 1, 1)
	
	if getRP() == "SPEED":
		if SPEED_ON:
			$Head/Camera3D/SpringArm3D/TABLET/RP.get_active_material(0).albedo_color = Color(0.5, 1, 1)
		else:
			$Head/Camera3D/SpringArm3D/TABLET/RP.get_active_material(0).albedo_color = Color(1, 1, 1)



func powerMaintenance():
	setIcons()
	RUN = 2 * WALK
	var currentTime = Time.get_ticks_msec()
	if SPEED_TIME != null:
		if (currentTime - SPEED_TIME) < 1000 * SPEED_DUR:
			WALK = SPEED_WALK
		else:
			WALK = NORM_WALK
		if (currentTime - SPEED_TIME) >= 1000 * SPEED_COOL:
			SPEED_ON = false

func _input(event):
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x / 1000
		$Head/Camera3D.rotation.x -= event.relative.y / 1000
		$Head/Camera3D.rotation.x = clamp( $Head/Camera3D.rotation.x, -1 * PI / 2.0, PI / 2.0 )
		GlobalVariables.PlayerPitch = $Head/Camera3D.rotation.x
	
	if event is InputEventMouseButton:
		if (getLP() != "PORTALS") and (getRP() != "PORTALS"):
			return
		
		var bi = event.button_index
		
		var point = $Head/Camera3D/RayCast3D.get_collision_point()
		var norm = $Head/Camera3D/RayCast3D.get_collision_normal()
		var basis2 = GlobalVariables.basisnormal(norm)
		print(point, norm, basis2)
		var newportal = null
		if bi == MOUSE_BUTTON_LEFT:
			for node in get_tree().get_nodes_in_group("PORTAL_RED"):
				node.queue_free()
			newportal = load("res://portals/portal_red.tscn").instantiate()
		elif bi == MOUSE_BUTTON_RIGHT:
			for node in get_tree().get_nodes_in_group("PORTAL_CYAN"):
				node.queue_free()
			newportal = load("res://portals/portal_cyan.tscn").instantiate()
		if newportal != null:
			newportal.global_transform = Transform3D(basis2, point)
			get_tree().get_current_scene().add_child(newportal)
			
		
func shardcollect():
	$ShardAudio.pitch_scale = randf_range(0.9, 1.1)
	$ShardAudio.play()
	GlobalVariables.SHARDSCOLLECTED = GlobalVariables.SHARDSCOLLECTED + 1
	GlobalVariables.CURRENTSTREAK = GlobalVariables.CURRENTSTREAK + 1

func set_cam_basis(basis2):
	$Head/Camera3D.basis = basis2

func _physics_process(delta):
	powerMaintenance()
	
	if GRACE_PERIOD == 0:
		GlobalVariables.PLAYER_DEAD = false
	if (GRACE_PERIOD >= 0):
		GRACE_PERIOD = GRACE_PERIOD - 1
	
	# Shard count and shard indicator
	GlobalVariables.SHARDS = get_tree().get_nodes_in_group("SOUL_SHARD")
	$Head/Camera3D/SpringArm3D/TABLET/Label3D.text = str(len(GlobalVariables.SHARDS))
	
	var maxdist = INF
	var minpos = position
	
	for shard in GlobalVariables.SHARDS:
		var shardpos = shard.global_transform.origin
		var rsq = position.distance_squared_to(shardpos)
		if (rsq < maxdist):
			maxdist = rsq
			minpos = shardpos
			
	# Flashing dot in center
	
	$BLINKING_DOT.scale = 2 * GlobalVariables.normalizedVolume() * Vector3(1, 0, 1) + Vector3(0, 1, 0)
	# $BLINKING_DOT.scale = Vector3(0.5, 1, 0.5)
	# Process movement
	
	$Head/Camera3D/MapView/Minimap.size = MAPSIZE
	
	GlobalVariables.PlayerLocation = global_transform.origin
	GlobalVariables.PlayerCamRotation = $Head/Camera3D.global_rotation
	GlobalVariables.PlayerCamBasis = $Head/Camera3D.global_transform.basis
	
	$Head/Camera3D/MapView/Minimap.global_position.x = position.x
	$Head/Camera3D/MapView/Minimap.global_position.z = position.z
	$Head/Camera3D/MapView/Minimap.global_rotation.y = rotation.y
	
	# We create a local variable to store the input direction.
	var direction = Vector3.ZERO
	
	var dirqua = Quaternion()
	
	if Input.is_action_just_pressed("tablet"):
		var vis = $Head/Camera3D/SpringArm3D/TABLET.visible
		$Head/Camera3D/SpringArm3D/TABLET.visible = not vis
	
	if Input.is_action_just_pressed("zoom"):
		if MAPSIZE < 30:
			MAPSIZE = 40
		else:
			MAPSIZE = 20

	# We check for each move input and update the direction accordingly.
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		# Notice how we are working with the vector's x and z axes.
		# In 3D, the XZ plane is the ground plane.
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
	if Input.is_action_pressed("sprint"):
		speed = RUN
	else:
		speed = WALK
		
	# Swap powers
	
	if (len(POWERS) > 0):
		if Input.is_action_just_pressed("LSWAP"):
			LPOWER = (LPOWER + 1) % len(POWERS)
		if Input.is_action_just_pressed("RSWAP"):
			RPOWER = (RPOWER + 1) % len(POWERS)
		
		if Input.is_action_just_pressed("LPOW"):
			activatePower(getLP())
		if Input.is_action_just_pressed("RPOW"):
			activatePower(getRP())
	
	# Power sprites
	
	if (len(POWERS) > 0):
		var LImage = Image.load_from_file(GlobalVariables.P_SPR[POWERS[LPOWER]])
		var RImage = Image.load_from_file(GlobalVariables.P_SPR[POWERS[RPOWER]])
		$Head/Camera3D/SpringArm3D/TABLET/LP.get_active_material(0).albedo_texture = ImageTexture.create_from_image(LImage)
		$Head/Camera3D/SpringArm3D/TABLET/RP.get_active_material(0).albedo_texture = ImageTexture.create_from_image(RImage)
		
	direction = (transform.basis * Vector3(direction.x, 0, direction.z)).normalized()
		
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		

	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
	
	global_rotation.x = move_toward(global_rotation.x, 0, 0.05)
	global_rotation.z = move_toward(global_rotation.z, 0, 0.05)

	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
		if target_velocity.x == 0 and target_velocity.z == 0:
			target_velocity = velocity
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	else:
		target_velocity.y = 0
		if Input.is_action_pressed("jump"):
			target_velocity.y = 10
	
	if position.y < -100:
		target_velocity = Vector3(0, 0, 0)
		position = Vector3(0, 2, 0)
		
	if GlobalVariables.SAVED_V != null:
		print("RETRIEVING LOADED VELOCITY ", GlobalVariables.SAVED_V)
		target_velocity = GlobalVariables.SAVED_V
		GlobalVariables.MOMENTUM_CONS = move_toward(GlobalVariables.MOMENTUM_CONS, 0, 1)
		if GlobalVariables.MOMENTUM_CONS <= 0:
			GlobalVariables.SAVED_V = null		

	# Moving the Character
	velocity = target_velocity
	move_and_slide()

func death():
	$CanvasLayer/VBoxContainer/Failures.text = str(GlobalVariables.INITLIVES - GlobalVariables.LIVES) + " FAILS"
	$CanvasLayer/VBoxContainer/Shards.text = str(GlobalVariables.SHARDSCOLLECTED) + "/" + str(len(GlobalVariables.INITSHARDS)) + " SHARDS"
	$CanvasLayer.show()
	$CanvasLayer/VBoxContainer/Button.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func _on_button_pressed():
	$CanvasLayer/VBoxContainer/Button.hide()
	print("PRESSED!")
	GlobalVariables.spawnEnemies()
	GlobalVariables.respawn()
	$CanvasLayer.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GRACE_PERIOD = 2


func _on_button_2_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()
	


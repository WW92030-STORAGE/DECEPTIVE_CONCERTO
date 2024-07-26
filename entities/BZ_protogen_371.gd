extends CharacterBody3D

@onready var nav_a = $NavigationAgent3D
var facing = Vector3()

var WALK_SPEED = 5
var RUN_SPEED = 8

var WALK_THRESHOLD = 16

var SPEED = WALK_SPEED
var FOV = PI / 3

var wander = false
var chasing = false
var wandering = false

func update_target_location(location):
	nav_a.target_position = location

func randomPlace(radius = 40):
	return global_transform.origin + radius * Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))

func playerLooking():
	
	var displacement = global_transform.origin - GlobalVariables.Player.global_transform.origin
	$RayCast3D.target_position = (-1 * displacement).rotated(Vector3(0, -1, 0), global_rotation.y)
	
	var theta = GlobalVariables.rem(atan2(displacement.z, -1 * displacement.x), 2 * PI)
	var thetaplus = theta + 2 * PI
	var thetaminus = theta - 2 * PI
	
	var ptheta = GlobalVariables.rem(GlobalVariables.Player.global_rotation.y - 0.5 * PI, 2 * PI)
	# print(theta, " / ",  ptheta)
	
	var thetacheck = false
	
	if abs(ptheta - theta) < FOV:
		thetacheck = true
	if abs(ptheta - thetaplus) < FOV:
		thetacheck = true
	if abs(ptheta - thetaminus) < FOV:
		thetacheck = true
	
	var horizdisp = sqrt(displacement.x * displacement.x + displacement.y * displacement.y)
		
	var phi = atan2(displacement.y, horizdisp)
	var pphi = GlobalVariables.PlayerPitch
	
	# print(phi, " / ", pphi)
	
	if abs(pphi - phi) < FOV:
		return thetacheck
	
	return false

func _physics_process(delta):
	if nav_a.is_navigation_finished():
		wander = false
		wandering = false
	
	if not playerLooking():
		SPEED = 0
		$AnimationTree.get("parameters/playback").travel("idle")
		velocity = Vector3(0, 0, 0)
		if not is_on_floor():
			velocity.y = -0.1
		
		return
		
	rotation.y = atan2(velocity.x, velocity.z)
	
	for node in get_tree().get_nodes_in_group("ENEMY"):
		if node == self:
			continue
		if node.global_position.distance_to(global_position) < 2:
			wander = true
			break
	
	if wander:
		if not wandering:
			wandering = true
			update_target_location(randomPlace())
	else:
		update_target_location(GlobalVariables.PlayerLocation)
	
	var displacement = GlobalVariables.PlayerLocation - global_transform.origin
	
	chasing = displacement.length() < WALK_THRESHOLD

	var state_machine = $AnimationTree.get("parameters/playback")
	
	if not chasing:
		SPEED = RUN_SPEED
		state_machine.travel("running")
	else:
		SPEED = WALK_SPEED
		state_machine.travel("running")
	
	var cur_loc = global_transform.origin
	var next_loc = nav_a.get_next_path_position()
	var vprime = (next_loc - cur_loc).normalized() * SPEED
	
	velocity = velocity.move_toward(vprime, 0.25)
	if not is_on_floor():
		velocity.y = -0.1
	else:
		velocity.y = 0
	move_and_slide()
	
	# Kill player on collision
	
	for object in $Area3D.get_overlapping_areas():
		if object.is_in_group("PLAYER_HITBOX"):
			GlobalVariables.killPlayer()
		
	# Pulsing dot
	
	var dotscale = GlobalVariables.normalizedVolume() * 0.2 * Vector3(1, 0, 1) + Vector3(0, 0.005, 0)
	$Protogen/GeneralSkeleton/BoneAttachment3D/MeshInstance3D.scale = dotscale
	$Protogen/GeneralSkeleton/BoneAttachment3D/MeshInstance3D2.scale = dotscale


func _on_navigation_agent_3d_target_reached():
	print("!!!!!!!!!!!!!!!")
	wander = false
	wandering = false
	pass # Replace with function body.


func _on_navigation_agent_3d_navigation_finished():
	print("????????????????")
	wander = false
	wandering = false
	pass # Replace with function body.

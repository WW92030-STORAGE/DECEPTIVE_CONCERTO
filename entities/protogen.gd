extends CharacterBody3D

@onready var nav_a = $NavigationAgent3D
var facing = Vector3()

var WALK_SPEED = 2
var RUN_SPEED = 5

var SPEED = WALK_SPEED
var FOV = PI / 2

var wander = false
var wandering = false
var chasing = false

func update_target_location(location):
	nav_a.target_position = location
	
func playerVisible(maxdist = 256):
	var object = GlobalVariables.Player
	var displacement = object.global_transform.origin - global_transform.origin
	facing = global_transform.basis.z
	var len = displacement.length()
	var ang = acos(displacement.normalized().dot(facing))
	# print(len, " / ",  ang)
	if (len > maxdist):
		return false
	if (ang > FOV):
		return false
	var relpos = (object.global_transform.origin - $RayCast3D.global_transform.origin)
	$RayCast3D.target_position = relpos.rotated(Vector3(0, -1, 0), global_rotation.y)
	
	# print($RayCast3D.global_position, GlobalVariables.PlayerLocation)
	var collision = $RayCast3D.get_collider()
	# print(str(collision))
	if collision == null:
		return true
	
	# print(collision.to_string())
	if str(collision).substr(0, 6) == "Player":
		return true
	if collision.is_in_group("PLAYER_BODY"):
		return true
	
	return false

func randomPlace(radius = 40):
	return global_transform.origin + radius * Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))

func _physics_process(delta):
	if nav_a.is_navigation_finished():
		wander = false
		wandering = false
	rotation.y = atan2(velocity.x, velocity.z)
	
	if (playerVisible()):
		if (!chasing):
			chasing = true
			print("CHASING PLAYER")
		wander = false
		update_target_location(GlobalVariables.PlayerLocation)
	else:
		if (chasing):
			chasing = false
			print("No longer chasing player...")
		if (!wander):
			if not wandering:
				wandering = true
				update_target_location(randomPlace())
			wander = true
		
	var state_machine = $AnimationTree.get("parameters/playback")
		
	if chasing:
		SPEED = RUN_SPEED
		state_machine.travel("running")
	else:
		SPEED = WALK_SPEED
		state_machine.travel("walking")
	
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
			
	# Set visibility of reveal marker
		
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

extends CharacterBody3D

var CyanPortal = null

var check_cool = 4

var finalrotation = Basis()

@onready var checkers = [$SurfaceChecker, $SurfaceChecker2, $SurfaceChecker3, $SurfaceChecker4]

func restoreCollisions():
	for body in GlobalVariables.STORED_RED:
		body.set_collision_layer_value(1, true)

func sliceHole():
	# Get the current set of colliding meshes
	
	var new_stored_bodies = []
	for body in $BackingCollider.get_overlapping_bodies():
		# print("Backing Collider Overlaps:", body)
		if body.is_in_group("PLAYER") or body.is_in_group("ENEMY"):
			# print("BAD BODY!!!", body)
			continue
		new_stored_bodies.append(body)
		
	# print("CollisionsRed", new_stored_bodies)
	
	# Restore original bodies
	for body in GlobalVariables.STORED_RED:
		if body not in new_stored_bodies:
			body.set_collision_layer_value(1, true)
	# Set new collisions
	for body in new_stored_bodies:
		body.set_collision_layer_value(1, false)
		body.set_collision_layer_value(2, true)
		body.set_collision_layer_value(3, true)
		
	
	GlobalVariables.STORED_RED = new_stored_bodies

func _ready():
	var plist = get_tree().get_nodes_in_group("PORTAL_CYAN")
	if len(plist) > 0:
		CyanPortal = plist[0]
		
	check_cool = 16
	
	print("RED POS", global_position)

func prepkill():
	check_cool = 8
	restoreCollisions()
		
	queue_free()

func _physics_process(delta):
	
	# Begin surface checks
	if (check_cool > 0):
		check_cool = check_cool - 1
	else:
		check_cool = 8
	
		for object in $ObstructionChecker.get_overlapping_bodies():
			if object.is_class("StaticBody3D"):
				print("STUFF OVERLAPPING COLLISION CHECKER")
				prepkill()
			if object.is_in_group("PORTAL_HITBOX"):
				print("PORTAL HITBOX OVERLAPPING")
				prepkill()
	
		for object in $ObstructionChecker.get_overlapping_areas():
			if object.is_class("StaticBody3D"):
				print("COLLISION CHECK FAILED", object)
				prepkill()
			if object.is_in_group("PORTAL_HITBOX"):
				print("PORTAL HITBOX OVERLAPPING", object)
				prepkill()
	
		for check in checkers:
			if len(check.get_overlapping_bodies()) == 0:
				print("SURFACE CHECK FAILED", check)
				prepkill()
				
	# End surface checks
	
	# Find the other portal
	
	var plist = get_tree().get_nodes_in_group("PORTAL_CYAN")
	if len(plist) > 0:
		CyanPortal = plist[0]
	else:
		CyanPortal = null
		return
		
	# HOLE SLICING OPERATION
	
	if GlobalVariables.INSIDE_PORTAL_RED:
		sliceHole()
		
	# Player location
	if GlobalVariables.INSIDE_PORTAL_RED:
		var original_cos = GlobalVariables.PLR_COS_RED
		GlobalVariables.PLR_COS_RED = GlobalVariables.cosine(basis * $PortalNormal.target_position, GlobalVariables.PlayerCamLocation - global_transform.origin)
		# print("COSINE WITH RED", GlobalVariables.PLR_COS_RED)
		
		if original_cos < 0 and GlobalVariables.PLR_COS_RED >= 0 and CyanPortal != null:
			var backwards_other = CyanPortal.global_transform.basis.rotated(CyanPortal.global_transform.basis.x, PI)
			var relativerotation = (backwards_other) * global_transform.basis.inverse()
			var displacement = GlobalVariables.Player.global_transform.origin - global_transform.origin
			GlobalVariables.Player.global_transform.origin = CyanPortal.global_transform.origin + (relativerotation * displacement)
			finalrotation = relativerotation * GlobalVariables.Player.global_transform.basis 
			GlobalVariables.Player.global_transform.basis = (finalrotation)
			GlobalVariables.Player.velocity = relativerotation * GlobalVariables.Player.velocity
			GlobalVariables.MOMENTUM_CONS = 0
				
	# Camera controls
	
	GlobalVariables.DISP_RED = GlobalVariables.PlayerLocation - global_transform.origin + Vector3(0, 1, 0)
	# Rotate me
	
	var eulers = (CyanPortal.global_transform.basis * global_transform.basis.inverse()).rotated(CyanPortal.global_transform.basis.x, PI).get_euler()
	var relpos = GlobalVariables.DISP_RED.rotated(Vector3(0, 0, 1), 1 * eulers.z)
	relpos = relpos.rotated(Vector3(1, 0, 0), 1 * eulers.x)
	relpos = relpos.rotated(Vector3(0, 1, 0), 1 * eulers.y)
	var finalpos = CyanPortal.global_position + relpos
	$CamViewRed/Camera3D.global_position = finalpos
	
	var relativerotation = (CyanPortal.global_transform.basis * global_transform.basis.inverse())
	
	finalrotation = (relativerotation * Basis.from_euler(GlobalVariables.PlayerCamRotation)).rotated(CyanPortal.global_transform.basis.x, PI)
	$CamViewRed/Camera3D.global_transform.basis = finalrotation
	
	# Set albedo of the portal view texture (This is done in the material editor)
	
		# Cull things too close
	
	var distance = GlobalVariables.DISP_RED.length()
	$CamViewRed/Camera3D.set_near(distance + GlobalVariables.CAM_EPSILON)

func _on_area_3d_area_exited(area):
	if area.is_in_group("PLAYER_HITBOX"):
		GlobalVariables.INSIDE_PORTAL_RED = false
		restoreCollisions()


func _on_area_3d_area_entered(area):
	if GlobalVariables.INSIDE_PORTAL_RED:
		return
	if CyanPortal == null:
		return
	if area.is_in_group("PLAYER_HITBOX"):
		GlobalVariables.INSIDE_PORTAL_RED = true
		sliceHole()

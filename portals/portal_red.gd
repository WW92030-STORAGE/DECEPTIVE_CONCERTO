extends CharacterBody3D

var CyanPortal = null

var check_cool = 100

var finalrotation = Basis()

func _ready():
	var plist = get_tree().get_nodes_in_group("PORTAL_CYAN")
	if len(plist) > 0:
		CyanPortal = plist[0]

func _process(delta):
	GlobalVariables.RED_TP = $TP_LOC.global_position - global_position
	
	var plist = get_tree().get_nodes_in_group("PORTAL_CYAN")
	if len(plist) > 0:
		CyanPortal = plist[0]
	else:
		CyanPortal = null
		return
	
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
	$StencilViewRed/Camera3D.global_position = GlobalVariables.PlayerLocation + Vector3(0, 1, 0)
	$StencilViewRed/Camera3D.global_rotation = GlobalVariables.PlayerCamRotation
	
		# Cull things too close
	
	var distance = CyanPortal.global_position.distance_to($CamViewRed/Camera3D.global_position)
	
	$CamViewRed/Camera3D.set_near(distance + GlobalVariables.CAM_EPSILON)
	
	if (check_cool > 0):
		check_cool = check_cool - 1
		return
	
	for object in $CollisionChecker.get_overlapping_bodies():
		print(object)
		if object.is_class("StaticBody3D"):
			queue_free()
		if object.is_in_group("PORTAL_HITBOX"):
			queue_free()
	
	for object in $CollisionChecker.get_overlapping_areas():
		if object.is_class("StaticBody3D"):
			print("COLLISION CHECK FAILED", object)
			queue_free()
		if object.is_in_group("PORTAL_HITBOX"):
			print("COLLISION CHECK FAILED", object)
			queue_free()

	var checkers = [$SurfaceChecker, $SurfaceChecker2, $SurfaceChecker3, $SurfaceChecker4]
	
	for check in checkers:
		if len(check.get_overlapping_bodies()) == 0:
			print("SURFACE CHECK FAILED", check)
			queue_free()

func _on_area_3d_area_exited(area):
	if area.is_in_group("PLAYER_HITBOX"):
		GlobalVariables.INSIDE_PORTAL_RED = false


func _on_area_3d_area_entered(area):
	if GlobalVariables.INSIDE_PORTAL_CYAN or GlobalVariables.INSIDE_PORTAL_RED:
		return
	if CyanPortal == null:
		return
	if area.is_in_group("PLAYER_HITBOX"):
		var relativerotation = (CyanPortal.global_transform.basis * global_transform.basis.inverse())
		GlobalVariables.INSIDE_PORTAL_RED = true
		GlobalVariables.Player.global_transform.origin = (GlobalVariables.Player.global_transform.origin - global_position) + CyanPortal.global_transform.origin + GlobalVariables.CYAN_TP
		GlobalVariables.Player.global_transform.basis = (finalrotation)
		GlobalVariables.SAVED_V = (GlobalVariables.Player.velocity).length() * CyanPortal.global_transform.basis.y
		GlobalVariables.Player.velocity = GlobalVariables.SAVED_V
		GlobalVariables.MOMENTUM_CONS = 8

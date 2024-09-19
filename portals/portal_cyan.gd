extends CharacterBody3D

var RedPortal = null

var check_cool = 100

func _ready():
	var plist = get_tree().get_nodes_in_group("PORTAL_RED")
	if len(plist) > 0:
		RedPortal = plist[0]
	else:
		return

var finalrotation = Basis()

func _process(delta):
	GlobalVariables.CYAN_TP = $TP_LOC.global_position - global_position
	
	var plist = get_tree().get_nodes_in_group("PORTAL_RED")
	if len(plist) > 0:
		RedPortal = plist[0]
	else:
		RedPortal = null
		return
	GlobalVariables.DISP_CYAN = GlobalVariables.PlayerLocation - global_transform.origin + Vector3(0, 1, 0)
	# Rotate me
	var eulers = (RedPortal.global_transform.basis * global_transform.basis.inverse()).rotated(RedPortal.global_transform.basis.x, PI).get_euler()
	var relpos = GlobalVariables.DISP_CYAN.rotated(Vector3(0, 0, 1), eulers.z)
	relpos = relpos.rotated(Vector3(1, 0, 0), eulers.x)
	relpos = relpos.rotated(Vector3(0, 1, 0), eulers.y)
	var finalpos = RedPortal.global_position + relpos
	$CamViewCyan/Camera3D.global_position = finalpos
	
	var relativerotation = (RedPortal.global_transform.basis * global_transform.basis.inverse())
	finalrotation = (relativerotation * Basis.from_euler(GlobalVariables.PlayerCamRotation)).rotated(RedPortal.global_transform.basis.x, PI)
	$CamViewCyan/Camera3D.global_transform.basis = finalrotation
	$StencilViewCyan/Camera3D.global_position = GlobalVariables.PlayerLocation + Vector3(0, 1, 0)
	$StencilViewCyan/Camera3D.global_rotation = GlobalVariables.PlayerCamRotation
	
	# Cull things too close
	
	var distance = RedPortal.global_position.distance_to($CamViewCyan/Camera3D.global_position)
	
	$CamViewCyan/Camera3D.set_near(distance + GlobalVariables.CAM_EPSILON)
	
	
	if (check_cool > 0):
		check_cool = check_cool - 1
		return
	
	for object in $CollisionChecker.get_overlapping_bodies():
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
	
	var checkers = [$SurfaceCheckerC, $SurfaceChecker2C, $SurfaceChecker3C, $SurfaceChecker4C]
	
	for check in checkers:
		if len(check.get_overlapping_bodies()) == 0:
			print("SURFACE CHECK FAILED", check)
			queue_free()

func _on_area_3d_area_exited(area):
	if area.is_in_group("PLAYER_HITBOX"):
		GlobalVariables.INSIDE_PORTAL_CYAN = false


func _on_area_3d_area_entered(area):
	if GlobalVariables.INSIDE_PORTAL_CYAN or GlobalVariables.INSIDE_PORTAL_RED:
		return
	if RedPortal == null:
		return
	if area.is_in_group("PLAYER_HITBOX"):
		var relativerotation = (RedPortal.global_transform.basis * global_transform.basis.inverse())
		GlobalVariables.INSIDE_PORTAL_CYAN = true
		GlobalVariables.Player.global_transform.origin = (GlobalVariables.Player.global_transform.origin - global_position) + RedPortal.global_transform.origin + GlobalVariables.RED_TP
		GlobalVariables.Player.global_transform.basis = (finalrotation)
		GlobalVariables.SAVED_V = (GlobalVariables.Player.velocity).length() * RedPortal.global_transform.basis.y
		GlobalVariables.Player.velocity = GlobalVariables.SAVED_V
		GlobalVariables.MOMENTUM_CONS = 8
		# GlobalVariables.Player.set_cam_basis(Basis())

extends CharacterBody3D

var INIT_TIME = 0
var TIMER = 5000 # ms each period
var WARNING = 3000 # start of the warning cycle
var ACTIVATE = 4000 # when the trap activates

func _ready():
	INIT_TIME = Time.get_ticks_msec()
	
func _process(delta):
	var TIME_DISP = (Time.get_ticks_msec() - INIT_TIME) % TIMER
	
	if TIME_DISP >= WARNING:
		$MeshInstance3D.get_active_material(0).albedo_color = Color(1, 0, 0)
		$MeshInstance3D.get_active_material(0).emission_enabled = true
	else:
		$MeshInstance3D.get_active_material(0).albedo_color = Color(0.5, 0.5, 0.5)
		$MeshInstance3D.get_active_material(0).emission_enabled = true
	
	$Laser.visible = TIME_DISP >= ACTIVATE
	
	if TIME_DISP >= ACTIVATE and not GlobalVariables.PLAYER_DEAD:
		for object in $Hitbox.get_overlapping_areas():
			if object.is_in_group("PLAYER_HITBOX"):
				GlobalVariables.killPlayer()
		
	

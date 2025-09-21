extends CharacterBody3D

func _physics_process(delta):
	
	
	if len(GlobalVariables.SHARDS) > 0:
		$MeshInstance3D.get_active_material(0).albedo_color = Color(127, 127, 127)
		$DOT.get_active_material(0).albedo_color = Color(127, 127, 127)
		$MeshInstance3D.get_active_material(0).emission_enabled = false
	else:
		$MeshInstance3D.get_active_material(0).albedo_color = Color(255, 0, 0)
		$DOT.get_active_material(0).albedo_color = Color(255, 0, 0)
		$MeshInstance3D.get_active_material(0).emission_enabled = true
		
		for area in $Area3D.get_overlapping_areas():
			if area.is_in_group("PLAYER_HITBOX"):
				print("LEVEL END")
				get_tree().change_scene_to_file("res://ui/results.tscn")
				
				GlobalVariables.TIME_END = Time.get_ticks_msec()
				
	
	$MeshInstance3D.global_rotation.y += 0.04
	$DOT.scale = 0.9 * Vector3(1, 0, 1) * GlobalVariables.normalizedVolume() + 0.1 * Vector3(1, 0, 1) + Vector3(0, 1, 0)

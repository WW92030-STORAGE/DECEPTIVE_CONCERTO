extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	$PanelContainer/VBoxContainer/LVL.text = GlobalVariables.CURRENT_LEVEL
	$PanelContainer/VBoxContainer/TIME.text = "TIME-" + str(0.001 * (GlobalVariables.TIME_END - GlobalVariables.TIME_START))
	$PanelContainer/VBoxContainer/SHARDS.text = "SOUL SHARDS-" + str(GlobalVariables.SHARDSCOLLECTED)
	$PanelContainer/VBoxContainer/SECRETS.text = "SECRETS-" + str(GlobalVariables.SECRETS)
	$PanelContainer/VBoxContainer/BONUS.text = "BONUS SHARDS-" + str(GlobalVariables.BONUS)
	$PanelContainer/VBoxContainer/STREAK.text = "SHARD STREAK-" + str(GlobalVariables.SHARDSTREAK)
	$PanelContainer/VBoxContainer/LIVES.text = "LIVES LOST-" + str(GlobalVariables.INITLIVES - GlobalVariables.LIVES)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_pressed():
	get_tree().change_scene_to_file("res://menu.tscn")

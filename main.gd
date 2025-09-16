extends Node3D

func _ready():
	# This line connects the board's signal to the GameManager's function.
	# It says: "When $Board emits tile_clicked, call GameManager.on_tile_selected"
	$Board.tile_clicked.connect(GameManager.on_tile_selected)

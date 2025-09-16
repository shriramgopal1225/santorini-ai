extends Control

# UI Node references
@onready var turn_indicator = $TopPanel/TurnIndicator
@onready var phase_indicator = $TopPanel/PhaseIndicator
@onready var restart_button = $TopPanel/RestartButton
@onready var instructions_label = $CenterPanel/InstructionsLabel
@onready var winner_message = $CenterPanel/WinnerMessage
@onready var game_status = $BottomPanel/GameStatus

func _ready():
	# Hide winner message initially
	winner_message.visible = false
	
	# Connect restart button
	restart_button.pressed.connect(_on_restart_pressed)

func _on_restart_pressed():
	print("Restart button clicked!")
	# We'll connect this to GameManager later

# Test function to see if script works
func update_turn(player: int):
	turn_indicator.text = "Player " + str(player) + "'s Turn"
	
func update_instructions(text: String):
	instructions_label.text = text

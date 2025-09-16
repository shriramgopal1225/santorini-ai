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
	
	# Hide winner message
	hide_winner_message()
	
	# Tell GameManager to restart
	GameManager.new_game()
	
	# Reset UI to initial state
	reset_ui_to_start()

func reset_ui_to_start():
	# Reset colors and text
	phase_indicator.add_theme_color_override("font_color", Color.WHITE)
	winner_message.modulate = Color.WHITE
	
	print("UI reset to starting state")

# Test function to see if script works
func update_turn(player: int):
	turn_indicator.text = "Player " + str(player) + "'s Turn"
	
func update_instructions(text: String):
	instructions_label.text = text

func show_winner_message(winner_text: String):
	# Show winner message and hide instructions
	winner_message.text = winner_text
	winner_message.visible = true
	instructions_label.visible = false
	
	# Make winner text bigger and more prominent
	winner_message.add_theme_font_size_override("font_size", 36)
	winner_message.add_theme_color_override("font_color", Color.GOLD)
	
	# Add celebration animation
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(winner_message, "modulate", Color.WHITE, 0.5)
	tween.tween_property(winner_message, "modulate", Color.GOLD, 0.5)
	
	print("Winner message shown: " + winner_text)

func hide_winner_message():
	# Hide winner message and show instructions again
	winner_message.visible = false
	instructions_label.visible = true
	
	print("Winner message hidden")

func update_for_game_over(winner_text: String):
	show_winner_message(winner_text)
	phase_indicator.text = "Game Over"
	phase_indicator.add_theme_color_override("font_color", Color.RED)
	instructions_label.text = "Click 'Restart game' to play again."

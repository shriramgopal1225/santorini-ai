# game_settings.gd
extends Node

# We use an enum to define the possible game modes clearly.
enum GameMode { PVP, PVE }

# These variables will store the player's choices.
# They have default values.
var game_mode = GameMode.PVE  # Default to Player vs. AI
var ai_difficulty = 2         # Default to Medium

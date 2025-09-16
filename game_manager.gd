extends Node

enum GamePhase { PLACEMENT, SELECT_WORKER, MOVE, BUILD, GAME_OVER }

const PLAYER2_IS_AI = true
const AI_DIFFICULTY = 3

class GameState:
	var board = []
	var worker_positions = {}
	func _init():
		for x in range(6):
			board.append([])
			for y in range(6):
				board[x].append({"height": 0, "worker": null})
	
	func duplicate():
		var new_state = GameState.new()
		new_state.worker_positions = self.worker_positions.duplicate(true)
		for x in range(6):
			for y in range(6):
				new_state.board[x][y] = self.board[x][y].duplicate(true)
		return new_state

var current_state: GameState
var current_phase: GamePhase
var current_player: int = 1
var p1_workers_placed = 0
var p2_workers_placed = 0
var selected_worker_id: String = ""

var ai_agent = load("res://ai_agent.gd").new()

func _ready():
	new_game()

func new_game():
	current_state = GameState.new()
	current_phase = GamePhase.PLACEMENT
	current_player = 1
	p1_workers_placed = 0
	p2_workers_placed = 0
	selected_worker_id = ""
	print("New game started. Player 1, place your first worker.")

func on_tile_selected(grid_pos):
	if current_phase == GamePhase.GAME_OVER: return
	if PLAYER2_IS_AI and current_player == 2: return

	match current_phase:
		GamePhase.PLACEMENT: handle_placement(grid_pos)
		GamePhase.SELECT_WORKER: handle_select_worker(grid_pos)
		GamePhase.MOVE: handle_move(grid_pos)
		GamePhase.BUILD: handle_build(grid_pos)

func handle_placement(grid_pos):
	if current_state.board[grid_pos.x][grid_pos.y].worker != null: return
	
	var worker_num = 0
	if current_player == 1:
		p1_workers_placed += 1
		worker_num = p1_workers_placed
	else:
		p2_workers_placed += 1
		worker_num = p2_workers_placed
	
	var worker_id = "p" + str(current_player) + "_w" + str(worker_num)
	
	current_state.board[grid_pos.x][grid_pos.y].worker = worker_id
	current_state.worker_positions[worker_id] = grid_pos
	get_tree().get_root().get_node("Main/Board").spawn_worker_visual(worker_id, current_player, grid_pos)
	
	if current_player == 1: current_player = 2
	else: current_player = 1
	
	if p1_workers_placed >= 2 and p2_workers_placed >= 2:
		current_phase = GamePhase.SELECT_WORKER
		current_player = 1
		print("All workers placed. Phase: SELECT_WORKER. Player 1's turn.")
	else:
		print("Player " + str(current_player) + ", place your worker.")
		if PLAYER2_IS_AI and current_player == 2:
			_request_ai_placement()

func handle_select_worker(grid_pos):
	var worker_id = current_state.board[grid_pos.x][grid_pos.y].worker
	if worker_id == null: return
	if not worker_id.begins_with("p" + str(current_player)): return
	selected_worker_id = worker_id
	current_phase = GamePhase.MOVE
	get_tree().get_root().get_node("Main/Board").highlight_worker(selected_worker_id, true)
	print("Worker " + worker_id + " selected. Choose a tile to move to.")

func handle_move(grid_pos):
	if current_state.board[grid_pos.x][grid_pos.y].worker == selected_worker_id:
		get_tree().get_root().get_node("Main/Board").highlight_worker(selected_worker_id, false)
		selected_worker_id = ""; current_phase = GamePhase.SELECT_WORKER
		print("Worker deselected."); return

	var from_pos = current_state.worker_positions[selected_worker_id]
	if not is_valid_move(from_pos, grid_pos): print("Invalid move!"); return
	
	var destination_height = current_state.board[grid_pos.x][grid_pos.y].height
	current_state.board[from_pos.x][from_pos.y].worker = null
	current_state.board[grid_pos.x][grid_pos.y].worker = selected_worker_id
	current_state.worker_positions[selected_worker_id] = grid_pos
	get_tree().get_root().get_node("Main/Board").move_worker_visual(selected_worker_id, grid_pos, destination_height)
	
	if destination_height == 3: _game_over("Player " + str(current_player) + " wins!"); return
	
	current_phase = GamePhase.BUILD
	if not (PLAYER2_IS_AI and current_player == 2):
		print("Worker moved. Now in BUILD phase.")

func handle_build(grid_pos, worker_pos_override = null):
	var worker_pos = worker_pos_override if worker_pos_override != null else current_state.worker_positions[selected_worker_id]

	if not is_valid_build(worker_pos, grid_pos): print("Invalid build location!"); return
		
	current_state.board[grid_pos.x][grid_pos.y].height += 1
	var new_height = current_state.board[grid_pos.x][grid_pos.y].height
	get_tree().get_root().get_node("Main/Board").build_visual(grid_pos, new_height)
	get_tree().get_root().get_node("Main/Board").highlight_worker(selected_worker_id, false)
	
	if current_player == 1: current_player = 2
	else: current_player = 1
	
	if not _can_player_make_any_move(current_player):
		var winner = 1 if current_player == 2 else 2
		_game_over("Player " + str(winner) + " wins because Player " + str(current_player) + " has no valid moves!"); return
		
	selected_worker_id = ""
	current_phase = GamePhase.SELECT_WORKER
	print("Build successful. It is now Player " + str(current_player) + "'s turn.")
	
	if PLAYER2_IS_AI and current_player == 2:
		_request_ai_move()

# --- UPDATED _request_ai_move FUNCTION ---
func _request_ai_move():
	print("AI is thinking...")
	var search_depth = 1
	if AI_DIFFICULTY == 2: search_depth = 3
	elif AI_DIFFICULTY == 3: search_depth = 4
	
	await get_tree().create_timer(0.1).timeout
	
	var best_action = ai_agent.find_best_move(current_state, search_depth, 2)
	
	if best_action == null: _game_over("AI has no moves!"); return
	print("AI chose its move.")
	
	selected_worker_id = best_action.worker_id
	handle_move(best_action.to)
	
	# --- THIS IS THE FIX ---
	# If the move was a winning one, the game is now over. Do not proceed.
	if current_phase == GamePhase.GAME_OVER:
		return
	# -----------------------

	# The build step is only called if the move was NOT a winning one.
	handle_build(best_action.build, best_action.to)
# -----------------------------------------

func _request_ai_placement():
	var empty_spots = []
	for x in range(6):
		for y in range(6):
			if current_state.board[x][y].worker == null:
				empty_spots.append(Vector2i(x, y))
	empty_spots.shuffle()
	if not empty_spots.is_empty():
		handle_placement(empty_spots[0])

func is_valid_move(from_pos, to_pos):
	if current_state.board[to_pos.x][to_pos.y].worker != null: return false
	if from_pos.distance_to(to_pos) > 1.5: return false
	var from_height = current_state.board[from_pos.x][from_pos.y].height
	var to_height = current_state.board[to_pos.x][to_pos.y].height
	if to_height >= 4: return false
	if to_height - from_height > 1: return false
	return true

func is_valid_build(worker_pos, build_pos):
	if current_state.board[build_pos.x][build_pos.y].worker != null: return false
	if worker_pos.distance_to(build_pos) > 1.5: return false
	if current_state.board[build_pos.x][build_pos.y].height >= 4: return false
	return true

func _game_over(win_message):
	print("--- GAME OVER ---"); print(win_message); current_phase = GamePhase.GAME_OVER

func _can_player_make_any_move(player_id):
	return not ai_agent._get_all_actions_for_player(current_state, player_id).is_empty()

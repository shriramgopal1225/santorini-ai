extends Node

# --- Minimax parameters (existing logic kept) ---
func find_best_move(state, depth, ai_player_id):
	var best_score = -INF
	var best_action = null
	var alpha = -INF
	var beta = INF
	var all_possible_actions = _get_all_actions_for_player(state, ai_player_id)
	if not all_possible_actions.is_empty():
		best_action = all_possible_actions[0]
	for action in all_possible_actions:
		var temp_state = _get_next_state(state, action)
		var score = minimax(temp_state, depth - 1, false, ai_player_id, alpha, beta)
		if score > best_score:
			best_score = score
			best_action = action
		alpha = max(alpha, best_score)
	return best_action

func minimax(state, depth, is_maximizing_player, ai_player_id, alpha, beta):
	if depth == 0 or _is_terminal(state):
		return evaluate_state(state, ai_player_id)
	if is_maximizing_player:
		var max_eval = -INF
		var actions = _get_all_actions_for_player(state, ai_player_id)
		if actions.is_empty(): return -INF
		for action in actions:
			var next_state = _get_next_state(state, action)
			var eval = minimax(next_state, depth - 1, false, ai_player_id, alpha, beta)
			max_eval = max(max_eval, eval)
			alpha = max(alpha, eval)
			if beta <= alpha: break
		return max_eval
	else:
		var min_eval = INF
		var opponent_id = 1 if ai_player_id == 2 else 2
		var actions = _get_all_actions_for_player(state, opponent_id)
		if actions.is_empty(): return INF
		for action in actions:
			var next_state = _get_next_state(state, action)
			var eval = minimax(next_state, depth - 1, true, ai_player_id, alpha, beta)
			min_eval = min(min_eval, eval)
			beta = min(beta, eval)
			if beta <= alpha: break
		return min_eval

# --- Evaluation ---
func evaluate_state(state, ai_player_id):
	var ai_score = 0
	var opponent_score = 0
	for worker_id in state.worker_positions:
		var worker_pos = state.worker_positions[worker_id]
		var height = state.board[worker_pos.x][worker_pos.y].height
		if height == 3:
			if worker_id.begins_with("p" + str(ai_player_id)): return INF
			else: return -INF
		if worker_id.begins_with("p" + str(ai_player_id)): ai_score += height
		else: opponent_score += height
	return ai_score - opponent_score

func _is_terminal(state):
	for worker_id in state.worker_positions:
		var pos = state.worker_positions[worker_id]
		if state.board[pos.x][pos.y].height == 3:
			return true
	return false

# --- State Simulation ---
func _get_next_state(state, action):
	var new_state = state.duplicate()
	var from_pos = action.from
	var to_pos = action.to
	new_state.board[from_pos.x][from_pos.y].worker = null
	new_state.board[to_pos.x][to_pos.y].worker = action.worker_id
	new_state.worker_positions[action.worker_id] = to_pos
	
	if action.build != null:
		new_state.board[action.build.x][action.build.y].height += 1
	return new_state

# --- Action Generation ---
func _get_all_actions_for_player(state, player_id):
	var actions = []
	var player_workers = []
	for worker_id in state.worker_positions:
		if worker_id.begins_with("p" + str(player_id)):
			player_workers.append(worker_id)
			
	for worker_id in player_workers:
		var from_pos = state.worker_positions[worker_id]
		for dx in [-1, 0, 1]:
			for dy in [-1, 0, 1]:
				if dx == 0 and dy == 0: continue
				var to_pos = from_pos + Vector2i(dx, dy)
				if to_pos.x < 0 or to_pos.x > 5 or to_pos.y < 0 or to_pos.y > 5: continue
				if _is_valid_move_for_ai(state, from_pos, to_pos):
					var to_height = state.board[to_pos.x][to_pos.y].height
					if to_height == 3:
						actions.append({ "worker_id": worker_id, "from": from_pos, "to": to_pos, "build": null })
						continue
					for bx in [-1, 0, 1]:
						for by in [-1, 0, 1]:
							if bx == 0 and by == 0: continue
							var build_pos = to_pos + Vector2i(bx, by)
							if build_pos.x < 0 or build_pos.x > 5 or build_pos.y < 0 or build_pos.y > 5: continue
							if _is_valid_build_for_ai(state, to_pos, build_pos):
								actions.append({ "worker_id": worker_id, "from": from_pos, "to": to_pos, "build": build_pos })
	return actions

func _is_valid_move_for_ai(state, from_pos, to_pos):
	if state.board[to_pos.x][to_pos.y].worker != null: return false
	if from_pos.distance_to(to_pos) > 1.5: return false
	var from_height = state.board[from_pos.x][from_pos.y].height
	var to_height = state.board[to_pos.x][to_pos.y].height
	if to_height >= 4: return false
	if to_height - from_height > 1: return false
	return true

func _is_valid_build_for_ai(state, worker_pos, build_pos):
	if state.board[build_pos.x][build_pos.y].worker != null: return false
	if worker_pos.distance_to(build_pos) > 1.5: return false
	if state.board[build_pos.x][build_pos.y].height >= 4: return false
	return true

# ====================================================================
# === Q-LEARNING INTEGRATION =========================================
# ====================================================================
var Q = {}  # Stores learned Q-values (state+action)
var alpha = 0.1  # Learning rate
var gamma = 0.9  # Discount
var epsilon = 0.2  # Exploration chance
var move_history = []
const SAVE_PATH = "user://qtable.save"

func _ready():
	if FileAccess.file_exists(SAVE_PATH):
		load_q_table()
	else:
		print("No saved Q-table found, starting new learning...")

func serialize_state(state):
	return str(state.worker_positions) + str(state.board)

func record_move(state, action):
	move_history.append([serialize_state(state), action])

func update_q_values(result):
	var reward = 0
	if result == "WIN":
		reward = 1
	elif result == "LOSE":
		reward = -1
	
	for data in move_history:
		var key = data[0] + str(data[1])
		var old_q = Q.get(key, 0.0)
		Q[key] = old_q + alpha * (reward - old_q)
	move_history.clear()
	save_q_table()

func save_q_table():
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_var(Q)
		f.close()

func load_q_table():
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		Q = f.get_var()
		f.close()

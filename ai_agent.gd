extends Node

# (find_best_move and minimax are unchanged)
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

# (evaluate_state and _is_terminal are unchanged)
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


# --- UPDATED _get_next_state FUNCTION ---
# It now handles actions that don't have a build step (i.e., winning moves)
func _get_next_state(state, action):
	var new_state = state.duplicate()
	var from_pos = action.from
	var to_pos = action.to
	new_state.board[from_pos.x][from_pos.y].worker = null
	new_state.board[to_pos.x][to_pos.y].worker = action.worker_id
	new_state.worker_positions[action.worker_id] = to_pos
	
	# Only simulate a build if the action includes one
	if action.build != null:
		new_state.board[action.build.x][action.build.y].height += 1
		
	return new_state
# ----------------------------------------


# --- UPDATED _get_all_actions_for_player FUNCTION ---
# It now recognizes a winning move as a complete action by itself
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
					# --- NEW LOGIC ---
					# Check if this move is an instant win
					var to_height = state.board[to_pos.x][to_pos.y].height
					if to_height == 3:
						# If it's a winning move, it's a complete action. No build needed.
						actions.append({ "worker_id": worker_id, "from": from_pos, "to": to_pos, "build": null })
						continue # Move on to the next potential move
					# ------------------
					
					# If it's not a winning move, find a valid build to complete the action
					for bx in [-1, 0, 1]:
						for by in [-1, 0, 1]:
							if bx == 0 and by == 0: continue
							var build_pos = to_pos + Vector2i(bx, by)
							if build_pos.x < 0 or build_pos.x > 5 or build_pos.y < 0 or build_pos.y > 5: continue
							
							if _is_valid_build_for_ai(state, to_pos, build_pos):
								actions.append({ "worker_id": worker_id, "from": from_pos, "to": to_pos, "build": build_pos })
	return actions
# ----------------------------------------------------

# (The _is_valid... functions are unchanged)
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

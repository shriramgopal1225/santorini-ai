extends Node3D

signal tile_clicked(grid_pos)

const TILE_SCENE = preload("res://tile.tscn")
const BOARD_SIZE = 6

const P1_WORKER_SCENE = preload("res://models/mini_characters/GLB format/character-male-c.glb")
const P2_WORKER_SCENE = preload("res://models/mini_characters/GLB format/character-male-d.glb")

const BLOCK_SCENE = preload("res://block.tscn")
const DOME_SCENE = preload("res://dome.tscn")

var highlight_material = StandardMaterial3D.new()
var original_materials = {}

var worker_nodes = {}
var tile_nodes = {}

func _ready():
	highlight_material.albedo_color = Color.YELLOW
	generate_board()
	debug_block_mesh()
	#apply_tile_materials()

func debug_block_mesh():
	print("=== DEBUGGING BLOCK MESH ===")
	
	# Create a temporary block to inspect
	var test_block = BLOCK_SCENE.instantiate()
	add_child(test_block)
	
	# Wait a frame for the node to be ready
	await get_tree().process_frame
	
	# Find the MeshInstance3D in the block
	var mesh_instance = _find_mesh_instance_in_children(test_block)
	if mesh_instance:
		print("Block MeshInstance3D found!")
		
		# Get the mesh AABB (bounding box)
		var aabb = mesh_instance.get_aabb()
		print("Block AABB: ", aabb)
		print("Block size: ", aabb.size)
		print("Block position (offset from origin): ", aabb.position) 
		print("Block center: ", aabb.get_center())
		
		# Calculate where the bottom and top of the mesh are
		var bottom_y = aabb.position.y
		var top_y = aabb.position.y + aabb.size.y
		print("Block bottom Y: ", bottom_y)
		print("Block top Y: ", top_y)
		print("Block height: ", aabb.size.y)
		
		# This tells us how the mesh is oriented relative to its origin
		if bottom_y < -0.1:
			print("➤ MESH ORIGIN IS ABOVE THE BOTTOM - origin is in center or top")
		elif bottom_y > 0.1:
			print("➤ MESH ORIGIN IS BELOW THE BOTTOM - origin is below the mesh")
		else:
			print("➤ MESH ORIGIN IS AT THE BOTTOM")
			
	else:
		print("ERROR: No MeshInstance3D found in block!")
	
	# Clean up
	test_block.queue_free()
	print("=== DEBUG COMPLETE ===")

func generate_board():
	for x in range(BOARD_SIZE):
		for y in range(BOARD_SIZE):
			var tile = TILE_SCENE.instantiate()
			tile.grid_position = Vector2i(x, y)
			# Tiles sit at y = 0, so top surface is flush with 0
			tile.position = Vector3(x * 1.1, 0, y * 1.1)
			tile_nodes[Vector2i(x, y)] = tile
			add_child(tile)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var camera = get_viewport().get_camera_3d()
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.collision_mask = 1
		var result = get_world_3d().direct_space_state.intersect_ray(query)
		if result:
			var collider = result.collider
			if collider is Tile:
				tile_clicked.emit(collider.grid_position)

func spawn_worker_visual(worker_id, player_id, grid_pos):
	var worker
	if player_id == 1:
		worker = P1_WORKER_SCENE.instantiate()
	else: # Player 2
		worker = P2_WORKER_SCENE.instantiate()
	
	# Worker stands on tile surface (y=0)
	worker.position = Vector3(grid_pos.x * 1.1, 0.5, grid_pos.y * 1.1)
	worker_nodes[worker_id] = worker
	add_child(worker)

func move_worker_visual(worker_id, to_pos, to_height):
	var worker_node = worker_nodes[worker_id]
	# Worker stands on top of the tower - use same formula as blocks
	# Tile surface (height 0): y = 0.5
	# Tower height 1: y = 0.5 + 0.46 = 0.96
	# Tower height 2: y = 0.5 + 2*0.46 = 1.42  
	# Tower height 3: y = 0.5 + 3*0.46 = 1.88
	worker_node.position = Vector3(to_pos.x * 1.1, 0.5 + to_height * 0.46, to_pos.y * 1.1)

func build_visual(grid_pos, new_height):
	var tile_node = tile_nodes[grid_pos]
	if new_height >= 4:
		var dome = DOME_SCENE.instantiate()
		# Dome sits at top of third block (height 3)
		dome.position.y = 0.5 + 2 * 0.46 + 0.46
		tile_node.add_child(dome)
	else:
		var block = BLOCK_SCENE.instantiate()
		# Each block adds 1 height unit: level 1 → y=0, level 2 → y=1, etc.
		block.position.y = 0.5 + (new_height - 1) * 0.46
		tile_node.add_child(block)

func highlight_worker(worker_id, is_selected):
	var worker_node = worker_nodes[worker_id]
	var mesh_instance = _find_mesh_instance_in_children(worker_node)
	if mesh_instance == null: return # Failsafe

	if is_selected:
		original_materials[worker_id] = mesh_instance.get_surface_override_material(0)
		mesh_instance.set_surface_override_material(0, highlight_material)
	else:
		if original_materials.has(worker_id):
			mesh_instance.set_surface_override_material(0, original_materials[worker_id])

func _find_mesh_instance_in_children(node):
	for child in node.get_children():
		if child is MeshInstance3D:
			return child
		for grandchild in child.get_children():
			if grandchild is MeshInstance3D:
				return grandchild
	return null

func clear_board():
	print("Clearing board visuals...")
	
	# Remove all worker visuals
	for worker_id in worker_nodes:
		var worker_node = worker_nodes[worker_id]
		if worker_node:
			worker_node.queue_free()
	worker_nodes.clear()
	
	# Remove only blocks and domes from tiles (not tile components)
	for grid_pos in tile_nodes:
		var tile_node = tile_nodes[grid_pos]
		
		# Only remove children that we know we added (blocks and domes)
		var children_to_remove = []
		for child in tile_node.get_children():
			# Check if this is a block or dome we added
			if is_dynamic_building(child):
				children_to_remove.append(child)
		
		for child in children_to_remove:
			child.queue_free()
	
	print("Board cleared successfully")

# Helper function to identify blocks and domes we added
func is_dynamic_building(node: Node) -> bool:
	# Check if this node is one of our building instances
	if node.scene_file_path == BLOCK_SCENE.resource_path:
		return true
	if node.scene_file_path == DOME_SCENE.resource_path:
		return true
	
	# Alternative check by name if scene_file_path doesn't work
	if node.name.begins_with("block") or node.name.begins_with("dome"):
		return true
		
	return false

# Add this new function to board.gd
func create_tile_material() -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	
	# Base marble-like appearance
	material.albedo_color = Color(0.9, 0.9, 0.95)  # Slightly off-white
	material.metallic = 0.1  # Slight metallic sheen
	material.roughness = 0.3  # Smooth but not mirror-like
	material.specular = 0.7  # Nice reflections
	
	# Add subtle normal mapping effect
	material.normal_scale = 0.2
	
	# Better lighting response
	material.rim_enabled = true
	material.rim = 0.2
	material.rim_color = Color(0.8, 0.8, 1.0)
	
	return material

# Add this to apply the material to tiles
func apply_tile_materials():
	var tile_material = create_tile_material()
	
	for grid_pos in tile_nodes:
		var tile_node = tile_nodes[grid_pos]
		var mesh_instance = _find_mesh_instance_in_children(tile_node)
		if mesh_instance:
			mesh_instance.material_override = tile_material
	
	print("Applied beautiful tile materials")

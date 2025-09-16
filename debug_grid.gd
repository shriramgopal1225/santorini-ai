@tool
extends Node3D

func _ready():
	var debug_mesh = ImmediateMesh.new()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1)
	
	debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	
	# Draw a 10x10 grid at y=0
	for i in range(-5, 6):
		debug_mesh.surface_add_vertex(Vector3(i, 0, -5))
		debug_mesh.surface_add_vertex(Vector3(i, 0, 5))
		debug_mesh.surface_add_vertex(Vector3(-5, 0, i))
		debug_mesh.surface_add_vertex(Vector3(5, 0, i))
	
	debug_mesh.surface_end()
	
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = debug_mesh
	add_child(mesh_instance)

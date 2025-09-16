extends Node3D

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var camera = get_viewport().get_camera_3d()
		if camera:
			var from = camera.project_ray_origin(event.position)
			var to = from + camera.project_ray_normal(event.position) * 1000
			var space_state = get_world_3d().direct_space_state

			# Godot 4 requires parameters object
			var query = PhysicsRayQueryParameters3D.create(from, to)
			var result = space_state.intersect_ray(query)

			if result.has("position"):
				var clicked_position = result.position
				print("Clicked object at Y:", clicked_position.y)

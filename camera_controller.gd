extends Camera3D

@export var orbit_speed: float = 3
@export var zoom_speed: float = 0.5
@export var min_zoom: float = 6.0
@export var max_zoom: float = 15.0

# SIMPLE KNOWN-GOOD VALUES
var orbit_center: Vector3 = Vector3(3.0, 0, 2.5)  # Center of 5x5 board
var orbit_distance: float = 12.0
var orbit_angle_h: float = 90.0   # Start facing forward
var orbit_angle_v: float = 45.0  # HIGH angle = looking down from above

var is_orbiting: bool = false
var last_mouse_pos: Vector2

func _ready():
	update_camera_position()

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_orbiting = event.pressed
			last_mouse_pos = event.position
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			orbit_distance = max(orbit_distance - zoom_speed, min_zoom)
			update_camera_position()
			
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			orbit_distance = min(orbit_distance + zoom_speed, max_zoom)
			update_camera_position()
			
	elif event is InputEventMouseMotion and is_orbiting:
		var delta = event.position - last_mouse_pos
		
		orbit_angle_h += delta.x * orbit_speed * 0.01
		orbit_angle_v -= delta.y * orbit_speed * 0.01  # NOTE: minus here for natural feel
		
		# Keep camera looking down at board
		orbit_angle_v = clamp(orbit_angle_v, 30.0, 85.0)
		
		update_camera_position()
		last_mouse_pos = event.position

func update_camera_position():
	var h_rad = deg_to_rad(orbit_angle_h)
	var v_rad = deg_to_rad(orbit_angle_v)
	
	var x = orbit_center.x + orbit_distance * cos(v_rad) * cos(h_rad)
	var y = orbit_center.y + orbit_distance * sin(v_rad)
	var z = orbit_center.z + orbit_distance * cos(v_rad) * sin(h_rad)
	
	position = Vector3(x, y, z)
	look_at(orbit_center, Vector3.UP)

extends Node3D

@onready var camera: Camera3D = $Camera3D
@onready var skeleton: Skeleton3D = $waa/Wmn/Skeleton3D

const BASE_BUSTO = 88.0
const BASE_CINTURA = 70.0
const BASE_CADERAS = 96.0
const BASE_ALTURA = 165.0

var camera_angle := 0.0
var camera_distance := 3.0
var is_dragging := false
var last_mouse_x := 0.0

func _ready():
	camera.position = Vector3(0, 1.0, camera_distance)
	update_mannequin(88.0, 70.0, 96.0, 165.0)

	if OS.get_name() == "Web":
		JavaScriptBridge.create_callback(_on_js_message)
		JavaScriptBridge.eval("""
			window.addEventListener('message', function(e) {
				if (e.data && e.data.type === 'measurements') {
					GodotRuntime.callMain([JSON.stringify(e.data.data)]);
				}
			});
		""")
func _set_relaxed_pose():
	# Baja los brazos rotando los biceps
	var bl = skeleton.find_bone("bicep.l")
	var br = skeleton.find_bone("bicep.r")
	
	if bl != -1:
		var rot_l = Quaternion(Vector3(0, 0, 1), deg_to_rad(50))
		skeleton.set_bone_pose_rotation(bl, rot_l)
	
	if br != -1:
		var rot_r = Quaternion(Vector3(0, 0, 1), deg_to_rad(-50))
		skeleton.set_bone_pose_rotation(br, rot_r)
		
func _on_js_message(args):
	var json = JSON.new()
	var result = json.parse(args[0])
	if result == OK:
		var data = json.get_data()
		update_mannequin(
			float(data["busto"]),
			float(data["cintura"]),
			float(data["caderas"]),
			float(data["altura"])
		)

func update_mannequin(busto: float, cintura: float, caderas: float, altura: float):
	if not skeleton:
		print("ERROR: skeleton no encontrado")
		return

	var busto_s = busto / BASE_BUSTO
	var cintura_s = cintura / BASE_CINTURA
	var caderas_s = caderas / BASE_CADERAS
	var altura_s = altura / BASE_ALTURA

	# Busto - escala pecho en X y Z
	_scale_bone("Chest", Vector3(busto_s, 1.0, busto_s))
	_scale_bone("Chest.001", Vector3(busto_s, 1.0, busto_s))

	# Cintura
	_scale_bone("Waist", Vector3(cintura_s, 1.0, cintura_s))

	# Caderas + muslos
	_scale_bone("Hips", Vector3(caderas_s, 1.0, caderas_s))
	_scale_bone("thigh.l", Vector3(caderas_s * 0.8, 1.0, caderas_s * 0.8))
	_scale_bone("thigh.r", Vector3(caderas_s * 0.8, 1.0, caderas_s * 0.8))

	# Altura general - escala el hueso base
	_scale_bone("Base", Vector3(1.0, altura_s, 1.0))

func _scale_bone(bone_name: String, bone_scale: Vector3):
	var idx = skeleton.find_bone(bone_name)
	if idx != -1:
		skeleton.set_bone_pose_scale(idx, bone_scale)
	else:
		print("Hueso no encontrado: ", bone_name)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			last_mouse_x = event.position.x

	if event is InputEventMouseMotion and is_dragging:
		var delta = event.position.x - last_mouse_x
		camera_angle += delta * 0.5
		last_mouse_x = event.position.x
		_update_camera()

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = max(1.5, camera_distance - 0.2)
			_update_camera()
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = min(6.0, camera_distance + 0.2)
			_update_camera()

func _update_camera():
	var rad = deg_to_rad(camera_angle)
	camera.position = Vector3(
		sin(rad) * camera_distance,
		1.0,
		cos(rad) * camera_distance
	)
	camera.look_at(Vector3(0, 1.0, 0))

func _on_js_measurements(args):
	var data = args[0]
	update_mannequin(
		float(data["busto"]),
		float(data["cintura"]),
		float(data["caderas"]),
		float(data["altura"])
	)

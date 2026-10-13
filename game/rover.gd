extends CharacterBody3D
## Arcade rover: yaw steering + kinematic ground contact. Six visual wheels.

const TOP_SPEED := 11.0
const REVERSE_SPEED := 4.5
const ACCELERATION := 3.8
const GRAVITY := 1.24
const PAD_LOOK_SPEED := 2.0

var speed := 0.0
var occupied := false
var controls_enabled := true
var camera: Camera3D
var view_pivot: Node3D
var chassis: Node3D
var wheels: Array[Node3D] = []
var view_yaw := 0.0
var view_pitch := -0.04

func _ready() -> void:
	name = "Rover"
	collision_layer = 4
	collision_mask = 1 | 2
	floor_snap_length = 1.1
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(48.0)
	var box := BoxShape3D.new()
	box.size = Vector3(2.05, 1.5, 3.65)
	var collider := CollisionShape3D.new()
	collider.shape = box
	collider.position.y = 0.75
	add_child(collider)
	chassis = Node3D.new()
	add_child(chassis)
	build_vehicle()
	view_pivot = Node3D.new()
	view_pivot.position = Vector3(0.0, 2.15, -0.62)
	add_child(view_pivot)
	camera = Camera3D.new()
	camera.fov = 78.0
	camera.near = 0.07
	camera.far = 8000.0
	view_pivot.add_child(camera)
	update_view()

func material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.75
	mat.metallic = metallic
	return mat

func box_part(size: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = mat
	part.position = at
	chassis.add_child(part)
	return part

func build_vehicle() -> void:
	var white := material(Color(0.72, 0.76, 0.73), 0.15)
	var dark := material(Color(0.055, 0.08, 0.105), 0.2)
	var orange := material(Color(0.88, 0.39, 0.16))
	var rubber := material(Color(0.055, 0.06, 0.065))
	box_part(Vector3(1.95, 0.48, 3.5), Vector3(0, 1.05, 0), white)
	box_part(Vector3(1.8, 0.18, 3.35), Vector3(0, 0.72, 0), dark)
	box_part(Vector3(1.8, 0.16, 0.65), Vector3(0, 1.36, -1.33), orange)
	box_part(Vector3(0.1, 0.42, 2.6), Vector3(-0.99, 1.08, 0.15), orange)
	box_part(Vector3(0.1, 0.42, 2.6), Vector3(0.99, 1.08, 0.15), orange)
	# Open cockpit: the first-person camera has an unobstructed forward view.
	box_part(Vector3(0.62, 0.65, 0.25), Vector3(0, 1.55, 0.22), dark)
	box_part(Vector3(0.7, 0.12, 0.58), Vector3(0, 1.3, -0.05), dark)
	box_part(Vector3(1.05, 0.2, 0.32), Vector3(0, 1.55, -1.0), dark)
	box_part(Vector3(0.48, 0.75, 0.7), Vector3(-0.55, 1.66, 1.02), white)
	box_part(Vector3(0.48, 0.75, 0.7), Vector3(0.55, 1.66, 1.02), white)
	box_part(Vector3(0.035, 1.4, 0.035), Vector3(0.73, 2.4, 1.22), dark)
	box_part(Vector3(1.15, 0.05, 0.07), Vector3(0, 1.77, -1.02), orange)
	for side in [-1.0, 1.0]:
		for z in [-1.25, 0.0, 1.25]:
			var pivot := Node3D.new()
			pivot.position = Vector3(side * 1.18, 0.58, z)
			chassis.add_child(pivot)
			wheels.append(pivot)
			var tire := CylinderMesh.new()
			tire.top_radius = 0.57
			tire.bottom_radius = 0.57
			tire.height = 0.4
			tire.radial_segments = 12
			var wheel := MeshInstance3D.new()
			wheel.mesh = tire
			wheel.material_override = rubber
			wheel.rotation.z = PI / 2.0
			pivot.add_child(wheel)
			var hub := CylinderMesh.new()
			hub.top_radius = 0.28
			hub.bottom_radius = 0.28
			hub.height = 0.43
			hub.radial_segments = 8
			var cap := MeshInstance3D.new()
			cap.mesh = hub
			cap.material_override = orange
			cap.rotation.z = PI / 2.0
			pivot.add_child(cap)
			# A spoke makes wheel rotation visible without textures.
			var spoke_mesh := BoxMesh.new()
			spoke_mesh.size = Vector3(0.45, 0.48, 0.07)
			var spoke := MeshInstance3D.new()
			spoke.mesh = spoke_mesh
			spoke.material_override = white
			pivot.add_child(spoke)

func look(delta_look: Vector2) -> void:
	view_yaw = clampf(view_yaw - delta_look.x, -2.4, 2.4)
	view_pitch = clampf(view_pitch - delta_look.y, -1.25, 1.1)
	update_view()

func update_view() -> void:
	view_pivot.rotation = Vector3(view_pitch, view_yaw, 0.0)

func _physics_process(delta: float) -> void:
	var throttle := 0.0
	var steering := 0.0
	var braking := false
	if occupied and controls_enabled:
		var forward := maxf(Input.get_action_strength("move_forward"), Input.get_action_strength("accelerate"))
		var backward := maxf(Input.get_action_strength("move_back"), Input.get_action_strength("reverse"))
		throttle = forward - backward
		steering = Input.get_axis("move_left", "move_right")
		braking = Input.is_action_pressed("brake")
		var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
		look(stick * stick.length() * PAD_LOOK_SPEED * delta)
	step_motion(delta, throttle, steering, braking)

func step_motion(delta: float, throttle: float, steering: float, braking: bool = false) -> void:
	var target := throttle * (TOP_SPEED if throttle >= 0.0 else REVERSE_SPEED)
	var acceleration := 12.0 if braking else ACCELERATION if absf(throttle) > 0.01 else 2.5
	speed = move_toward(speed, 0.0 if braking else target, acceleration * delta)
	# Conventional steering, including reversed steering while backing up.
	rotation.y -= steering * 0.7 * clampf(speed / 4.0, -1.0, 1.0) * delta
	if is_on_floor() and velocity.y < 0.0:
		velocity.y = 0.0
	velocity.y -= GRAVITY * delta
	var forward := -global_transform.basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	move_and_slide()
	if is_on_wall():
		speed = get_real_velocity().dot(forward)
	for wheel in wheels:
		wheel.rotate_x(-speed * delta / 0.57)
	# Tilt the visual chassis to the ground; the stable collider stays upright.
	if is_on_floor():
		var local_normal := global_transform.basis.inverse() * get_floor_normal()
		chassis.rotation.x = lerp_angle(chassis.rotation.x, atan2(local_normal.z, local_normal.y), delta * 5.0)
		chassis.rotation.z = lerp_angle(chassis.rotation.z, -atan2(local_normal.x, local_normal.y), delta * 5.0)

func stop() -> void:
	speed = 0.0
	velocity = Vector3.ZERO

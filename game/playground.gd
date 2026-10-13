extends Node3D

const Controls = preload("res://game/controls.gd")
const Terrain = preload("res://game/terrain.gd")
const Astronaut = preload("res://game/astronaut.gd")
const Rover = preload("res://game/rover.gd")
const HUD = preload("res://game/hud.gd")
const JovianSky = preload("res://game/sky.gd")
const SurveyTrip = preload("res://game/survey.gd")
const ENTER_DISTANCE := 3.8
const SAFE_RADIUS := 108.0

var astronaut = Astronaut.new()
var rover = Rover.new()
var hud = HUD.new()
var survey = SurveyTrip.new()
var sky_objects: Node3D
var paused := false
var note := ""
var note_time := 0.0
var capture_mouse := true

func _ready() -> void:
	Controls.install()
	create_environment()
	var terrain := Terrain.new()
	add_child(terrain)
	terrain.build()
	add_child(survey)
	create_landmarks()
	add_child(rover)
	add_child(astronaut)
	add_child(hud)
	reset_site()
	if DisplayServer.get_name() != "headless" and capture_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func make_material(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	if emission > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission
	return material

func add_mesh(parent: Node3D, mesh: Mesh, position_at: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = position_at
	parent.add_child(instance)
	return instance

func box(parent: Node3D, size: Vector3, position_at: Vector3, material: Material, collision: bool = false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := add_mesh(parent, mesh, position_at, material)
	if collision:
		var body := StaticBody3D.new()
		body.position = position_at
		body.collision_layer = 1
		body.collision_mask = 0
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collider.shape = shape
		body.add_child(collider)
		parent.add_child(body)
	return instance

func create_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.001, 0.002, 0.004)
	# Modest artistic fill preserves readable silhouettes in the vacuum shadows.
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.46, 0.54, 0.63)
	environment.ambient_light_energy = 0.32
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)
	var sunlight := DirectionalLight3D.new()
	sunlight.name = "DistantSun"
	add_child(sunlight)
	sunlight.look_at(-JovianSky.SUN_DIRECTION, Vector3.UP)
	sunlight.light_color = Color(1.0, 0.91, 0.78)
	sunlight.light_energy = 1.35
	sunlight.shadow_enabled = true
	sunlight.directional_shadow_max_distance = 130.0
	sunlight.shadow_bias = 0.03
	sky_objects = JovianSky.new()
	add_child(sky_objects)

func create_landmarks() -> void:
	var white := make_material(Color(0.62, 0.66, 0.65))
	var charcoal := make_material(Color(0.12, 0.16, 0.19))
	var orange := make_material(Color(0.87, 0.36, 0.14))
	var teal := make_material(Color(0.32, 0.66, 0.69), 0.35)
	# A few landing-site primitives give scale and make home easy to recognize.
	box(self, Vector3(6.5, 3.1, 4.0), Vector3(-9.0, 1.7, 5.0), white, true)
	box(self, Vector3(6.6, 0.4, 4.1), Vector3(-9.0, 3.3, 5.0), charcoal)
	box(self, Vector3(1.3, 2.5, 0.15), Vector3(-9.0, 1.6, 2.95), charcoal)
	box(self, Vector3(1.5, 0.1, 0.2), Vector3(-9.0, 2.94, 2.8), teal)
	box(self, Vector3(6.6, 0.3, 0.12), Vector3(-9.0, 0.52, 2.9), orange)
	for x in [-11.3, -6.7]:
		box(self, Vector3(0.45, 0.45, 3.5), Vector3(x, 0.2, 5.0), charcoal)
	var plaque := Label3D.new()
	plaque.name = "ModuleSign"
	plaque.text = "WAKE / 01"
	plaque.font_size = 64
	plaque.pixel_size = 0.005
	plaque.position = Vector3(-7.0, 2.2, 2.86)
	plaque.rotation.y = PI
	plaque.double_sided = false
	plaque.modulate = Color(0.8, 0.9, 0.91)
	add_child(plaque)
	box(self, Vector3(0.12, 6.0, 0.12), Vector3(-14.0, 3.0, 9.0), white)
	box(self, Vector3(1.8, 0.12, 0.12), Vector3(-14.0, 5.8, 9.0), orange)
	# Rocks use low-poly sphere meshes and matching convex collision shapes.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in range(65):
		var x := rng.randf_range(-100.0, 100.0)
		var z := rng.randf_range(-100.0, 100.0)
		if Vector2(x, z).length() < 17.0:
			continue
		if Vector2(x - SurveyTrip.RIM.x, z - SurveyTrip.RIM.z).length() < 6.0:
			continue # Leave clear footing around the instrument deployment site.
		if SurveyTrip.on_approach(x, z):
			continue # Keep an unobstructed driving approach to the crater.
		var rock := SphereMesh.new()
		rock.radial_segments = 6
		rock.rings = 3
		rock.radius = 1.0
		rock.height = 2.0
		var scale_at := Vector3(rng.randf_range(0.7, 2.2), rng.randf_range(0.4, 1.3), rng.randf_range(0.8, 2.4))
		var location := Vector3(x, Terrain.height_at(x, z) + scale_at.y * 0.25, z)
		var instance := add_mesh(self, rock, location, make_material(Color(0.25, 0.28, 0.3) * rng.randf_range(0.7, 1.2)))
		instance.scale = scale_at
		instance.rotation.y = rng.randf_range(0, TAU)
		var body := StaticBody3D.new()
		body.transform = instance.transform
		body.collision_layer = 1
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		shape.shape = rock.create_convex_shape()
		body.add_child(shape)
		add_child(body)
	# Distant rim silhouettes cover the finite terrain edge.
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		var mountain := CylinderMesh.new()
		mountain.top_radius = rng.randf_range(1.0, 5.0)
		mountain.bottom_radius = rng.randf_range(27.0, 45.0)
		mountain.height = rng.randf_range(15.0, 36.0)
		mountain.radial_segments = 5
		var at := Vector3(sin(angle) * 180.0, mountain.height * 0.32 - 6.0, cos(angle) * 180.0)
		add_mesh(self, mountain, at, make_material(Color(0.23, 0.26, 0.29)))
	# A visible ring of survey markers identifies the explorable area.
	for i in range(16):
		var angle := TAU * float(i) / 16.0
		var x := sin(angle) * 102.0
		var z := cos(angle) * 102.0
		var y := Terrain.height_at(x, z)
		box(self, Vector3(0.14, 1.6, 0.14), Vector3(x, y + 0.8, z), white)
		box(self, Vector3(0.28, 0.22, 0.28), Vector3(x, y + 1.5, z), orange)
	# Invisible rim colliders stop both bodies before the mesh edge.
	for side in [-1.0, 1.0]:
		boundary(Vector3(side * 113.0, 10.0, 0.0), Vector3(2.0, 30.0, 228.0))
		boundary(Vector3(0.0, 10.0, side * 113.0), Vector3(228.0, 30.0, 2.0))

func boundary(at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = at
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func reset_site() -> void:
	survey.reset()
	rover.occupied = false
	rover.stop()
	rover.position = Vector3(4.0, 0.12, -7.0)
	rover.rotation = Vector3.ZERO
	rover.chassis.rotation = Vector3.ZERO
	rover.view_yaw = 0.0
	rover.view_pitch = -0.04
	rover.update_view()
	astronaut.set_seated(false)
	astronaut.position = Vector3(0.0, 0.04, 3.0)
	astronaut.rotation = Vector3.ZERO
	astronaut.pitch = 0.04
	astronaut.head.rotation.x = astronaut.pitch
	astronaut.camera.make_current()
	astronaut.camera.fov = Astronaut.NORMAL_FOV
	show_note("Take the rover to Survey 01. Deploy the instrument on foot.", 4.0)

func near_rover() -> bool:
	# Require proximity to the body at ground level, not just the horizontal map.
	return astronaut.global_position.distance_to(rover.global_position) <= ENTER_DISTANCE

func interact() -> bool:
	if rover.occupied:
		return exit_rover()
	if survey.can_deploy(astronaut):
		survey.deploy()
		show_note("INSTRUMENT DEPLOYED — Return to WAKE / 01.", 3.0)
		return true
	if not near_rover():
		return false
	rover.occupied = true
	rover.view_yaw = 0.0
	rover.view_pitch = -0.04
	rover.update_view()
	astronaut.set_seated(true)
	rover.camera.make_current()
	show_note("ROVER READY", 1.8)
	return true

func exit_rover() -> bool:
	# Test several sides before restoring the astronaut collider. An obstructed
	# door never teleports the player into a rock, building, or under the ground.
	var space := get_world_3d().direct_space_state
	var shape := CapsuleShape3D.new()
	shape.radius = 0.34
	shape.height = 1.8
	for offset in [Vector3(2.2, 0, 0), Vector3(-2.2, 0, 0), Vector3(0, 0, 2.9), Vector3(0, 0, -2.9)]:
		var candidate: Vector3 = rover.global_position + rover.global_transform.basis * offset
		if absf(candidate.x) > SAFE_RADIUS or absf(candidate.z) > SAFE_RADIUS:
			continue
		var ray := PhysicsRayQueryParameters3D.create(candidate + Vector3.UP * 4.0, candidate + Vector3.DOWN * 8.0, 1)
		var ground := space.intersect_ray(ray)
		if ground.is_empty() or ground.normal.y < 0.7:
			continue
		if absf(float(ground.position.y) - rover.global_position.y) > 1.0:
			continue # A rock/building roof is not a safe step out of the cockpit.
		candidate.y = ground.position.y + 0.07
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform = Transform3D(Basis(), candidate + Vector3.UP * 0.95)
		query.collision_mask = 1 | 4
		if not space.intersect_shape(query, 1).is_empty():
			continue
		rover.stop()
		rover.occupied = false
		astronaut.global_position = candidate
		astronaut.rotation.y = rover.rotation.y + rover.view_yaw
		astronaut.pitch = rover.view_pitch
		astronaut.head.rotation.x = astronaut.pitch
		astronaut.set_seated(false)
		astronaut.camera.make_current()
		show_note("BACK ON FOOT", 1.5)
		return true
	show_note("Exit blocked. Move the rover to clear ground.", 3.0)
	return false

func show_note(text: String, duration: float) -> void:
	note = text
	note_time = duration

func set_paused(value: bool) -> void:
	paused = value
	astronaut.set_physics_process(not paused)
	rover.set_physics_process(not paused)
	if DisplayServer.get_name() != "headless" and capture_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree() and is_instance_valid(hud):
		set_paused(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.25):
		hud.pad_mode = true
	elif event is InputEventKey or (event is InputEventMouseMotion and event.relative.length() > 2.0):
		hud.pad_mode = false
	if event.is_action_pressed("pause_playground"):
		set_paused(not paused)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("reset_playground"):
		reset_site()
		set_paused(false)
	elif paused:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			set_paused(false)
	elif event.is_action_pressed("interact"):
		interact()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if rover.occupied:
			rover.look(event.relative * Astronaut.MOUSE_SENSITIVITY)
		else:
			astronaut.look(event.relative * Astronaut.MOUSE_SENSITIVITY)

func _process(delta: float) -> void:
	var camera: Camera3D = rover.camera if rover.occupied else astronaut.camera
	sky_objects.global_position = camera.global_position
	if not paused:
		if not rover.occupied:
			var target_fov: float = Astronaut.ZOOM_FOV if Input.is_action_pressed("visor_zoom") else Astronaut.NORMAL_FOV
			astronaut.camera.fov = lerpf(astronaut.camera.fov, target_fov, minf(1.0, delta * 10.0))
		note_time = maxf(0.0, note_time - delta)
		if note_time <= 0.0:
			note = ""
		if astronaut.position.y < -12.0 or rover.position.y < -12.0:
			reset_site()
		if survey.check_return(astronaut, rover.occupied):
			show_note("SURVEY COMPLETE — Back at the landing site.", 4.0)
	var body: Node3D = rover if rover.occupied else astronaut
	if maxf(absf(body.position.x), absf(body.position.z)) > 103.0 and note.is_empty():
		note = "Survey boundary — turn back toward the landing site."
		note_time = 0.15
	hud.update(rover.occupied, near_rover(), rover.speed, paused, note, not rover.occupied and astronaut.camera.fov < 50.0)
	hud.objective.text = survey.guidance(camera, body.global_position)
	if not rover.occupied and survey.can_deploy(astronaut) and note.is_empty():
		hud.prompt.text = "X — DEPLOY SURVEY INSTRUMENT" if hud.pad_mode else "E — DEPLOY SURVEY INSTRUMENT"
	if not rover.occupied and astronaut.camera.fov < 50.0:
		var target: String = sky_objects.focused_body(camera)
		hud.status.text += "   /   VISOR" + (" — " + target.to_upper() if not target.is_empty() else "")

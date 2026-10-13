extends Node3D
## A static, plausible arrangement, not a live astronomical ephemeris.
## Dimensions use JPL radii/orbital distances; positions use chosen circular phases.

const SKY_DISTANCE := 4800.0
const CALLISTO_ORBIT_KM := 1882700.0
const CALLISTO_RADIUS_KM := 2410.3
const JUPITER_RADIUS_KM := 71492.0
# Approximate polar radius derived from JPL mean/equatorial radii (69911/71492).
const JUPITER_POLAR_KM := 66853.1
const SUN_RADIUS_KM := 696000.0
const SUN_DISTANCE_KM := 778000000.0
const JUPITER_DIRECTION := Vector3(-0.25, 0.35, -0.9)
const SUN_DIRECTION := Vector3(0.68, 0.24, -0.68)
const MOONS := [
	{"name": "Io", "orbit": 421800.0, "radius": 1821.49, "phase": 2.1, "color": Color(0.77, 0.66, 0.38)},
	{"name": "Europa", "orbit": 671100.0, "radius": 1560.8, "phase": -1.4, "color": Color(0.8, 0.77, 0.69)},
	{"name": "Ganymede", "orbit": 1070400.0, "radius": 2631.2, "phase": 0.97, "color": Color(0.52, 0.5, 0.47)},
]

static func angular_diameter(radius_km: float, distance_km: float) -> float:
	return rad_to_deg(2.0 * asin(radius_km / distance_km))

static func observer_position() -> Vector3:
	# The local up vector places the observer on Callisto's actual surface.
	return -JUPITER_DIRECTION.normalized() * CALLISTO_ORBIT_KM + Vector3.UP * CALLISTO_RADIUS_KM

static func moon_relative(moon: Dictionary) -> Vector3:
	var radial := -JUPITER_DIRECTION.normalized()
	var tangent := JUPITER_DIRECTION.cross(Vector3.UP).normalized()
	var position_km: Vector3 = (radial * cos(float(moon.phase)) + tangent * sin(float(moon.phase))) * float(moon.orbit)
	return position_km - observer_position()

func _ready() -> void:
	name = "DistantSky"
	var clouds := ShaderMaterial.new()
	clouds.shader = preload("res://game/jupiter.gdshader")
	var jupiter := body("Jupiter", JUPITER_RADIUS_KM, -observer_position(), clouds, JUPITER_POLAR_KM / JUPITER_RADIUS_KM)
	var orbit_normal := JUPITER_DIRECTION.cross(Vector3.UP).normalized().cross(JUPITER_DIRECTION.normalized()).normalized()
	jupiter.quaternion = Quaternion(Vector3.UP, orbit_normal)
	for moon in MOONS:
		var material := StandardMaterial3D.new()
		material.albedo_color = moon.color
		material.roughness = 1.0
		body(moon.name, float(moon.radius), moon_relative(moon), material)
	var sunlight := StandardMaterial3D.new()
	sunlight.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sunlight.albedo_color = Color(1.0, 0.95, 0.82)
	body("Sun", SUN_RADIUS_KM, SUN_DIRECTION.normalized() * SUN_DISTANCE_KM, sunlight)
	# A small optical glare makes the subpixel solar disk findable without
	# pretending the disk itself is larger. No atmospheric halo is simulated.
	var glare := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(45.0, 45.0)
	glare.mesh = quad
	glare.position = SUN_DIRECTION.normalized() * (SKY_DISTANCE - 20.0)
	var glow := ShaderMaterial.new()
	glow.shader = preload("res://game/sun_glare.gdshader")
	glare.material_override = glow
	glare.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(glare)
	glare.look_at(Vector3.ZERO, Vector3.UP)
	stars()

func body(label: String, radius_km: float, relative_km: Vector3, material: Material, flattening: float = 1.0) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = SKY_DISTANCE * radius_km / relative_km.length()
	sphere.height = sphere.radius * 2.0 * flattening
	sphere.radial_segments = 64 if label == "Jupiter" else 24
	sphere.rings = 32 if label == "Jupiter" else 12
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = sphere
	instance.material_override = material
	instance.position = relative_km.normalized() * SKY_DISTANCE
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
	return instance

func focused_body(camera: Camera3D) -> String:
	var closest := ""
	var best_alignment := cos(deg_to_rad(2.5))
	var forward := -camera.global_transform.basis.z
	for label in ["Jupiter", "Io", "Europa", "Ganymede", "Sun"]:
		var object := get_node(label) as Node3D
		var direction := (object.global_position - camera.global_position).normalized()
		var alignment := forward.dot(direction)
		if alignment > best_alignment:
			best_alignment = alignment
			closest = label
	return closest

func stars() -> void:
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	var mesh := SphereMesh.new()
	mesh.radius = 1.4
	mesh.height = 2.8
	mesh.radial_segments = 4
	mesh.rings = 2
	instances.mesh = mesh
	instances.instance_count = 180
	var rng := RandomNumberGenerator.new()
	rng.seed = 7331
	for i in range(instances.instance_count):
		var direction := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.08, 1), rng.randf_range(-1, 1)).normalized()
		instances.set_instance_transform(i, Transform3D(Basis(), direction * 6500.0))
		instances.set_instance_color(i, Color(0.35, 0.4, 0.46) * rng.randf_range(0.5, 1.0))
	var field := MultiMeshInstance3D.new()
	field.multimesh = instances
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.vertex_color_use_as_albedo = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	field.material_override = material
	field.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(field)

extends Node3D
## One short excursion. Its state is separate from movement and the HUD.

const Terrain = preload("res://game/terrain.gd")
const CRATER := Vector3(42.0, 0.0, -62.0)
const RIM := Vector3(42.0, 0.0, -77.0)
const APPROACH := Vector3(28.0, 0.0, -42.0)
const PARKING := Vector3(42.0, 0.0, -52.0)
const HOME := Vector3(-9.0, 0.0, 1.0)
const INTERACT_RANGE := 2.7
enum Stage { OUTBOUND, RETURNING, COMPLETE }

var stage := Stage.OUTBOUND
var target: Vector3
var instrument: Node3D
var indicator: MeshInstance3D

static func on_approach(x: float, z: float) -> bool:
	var point := Vector2(x, z)
	var points := [Vector2(4, -7), Vector2(APPROACH.x, APPROACH.z), Vector2(PARKING.x, PARKING.z)]
	for i in range(points.size() - 1):
		if point.distance_to(Geometry2D.get_closest_point_to_segment(point, points[i], points[i + 1])) < 6.0:
			return true
	return false

func _ready() -> void:
	name = "CraterSurvey"
	target = Vector3(RIM.x, Terrain.height_at(RIM.x, RIM.z), RIM.z)
	build_site()
	reset()

func material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.85
	return result

func part(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var result := MeshInstance3D.new()
	result.mesh = mesh
	result.material_override = material(color)
	result.position = at
	parent.add_child(result)
	return result

func build_site() -> void:
	var marker := Node3D.new()
	marker.position = target
	add_child(marker)
	var orange := Color(0.94, 0.42, 0.12)
	var white := Color(0.72, 0.79, 0.8)
	var dark := Color(0.11, 0.16, 0.19)
	part(marker, Vector3(0.16, 2.45, 0.16), Vector3(0.85, 1.225, 0), white)
	part(marker, Vector3(1.2, 0.45, 0.12), Vector3(0.85, 2.65, 0), orange)
	part(marker, Vector3(1.4, 0.05, 1.2), Vector3(0, 0.08, 0), dark)
	var plate := Label3D.new()
	plate.text = "SURVEY / 01"
	plate.position = Vector3(0.85, 2.68, 0.1)
	plate.font_size = 48
	plate.pixel_size = 0.0028
	plate.modulate = Color(0.1, 0.13, 0.14)
	plate.outline_size = 0
	# Two physical sides with separate front-facing text, never mirrored backs.
	plate.double_sided = false
	marker.add_child(plate)
	var back := plate.duplicate() as Label3D
	back.position.z = -0.1
	back.rotation.y = PI
	marker.add_child(back)
	instrument = Node3D.new()
	instrument.position = target + Vector3(-0.8, 0.05, 0)
	add_child(instrument)
	part(instrument, Vector3(0.7, 0.34, 0.62), Vector3(0, 0.33, 0), white)
	part(instrument, Vector3(0.08, 1.65, 0.08), Vector3(0, 1.25, 0), dark)
	part(instrument, Vector3(0.85, 0.08, 0.12), Vector3(0, 2.0, 0), white)
	for x in [-0.3, 0.3]:
		part(instrument, Vector3(0.09, 0.3, 0.6), Vector3(x, 0.15, 0), dark)
	indicator = part(instrument, Vector3(0.16, 0.08, 0.16), Vector3(0, 0.55, -0.23), Color(0.23, 0.83, 0.64))
	var lamp := indicator.material_override as StandardMaterial3D
	lamp.emission_enabled = true
	lamp.emission = lamp.albedo_color
	lamp.emission_energy_multiplier = 0.7
	# Exposed ice slabs identify this crater among the surrounding gray terrain.
	for offset in [Vector3(-3, 0, 0), Vector3(0, 0, -2), Vector3(3, 0, 1)]:
		var location: Vector3 = CRATER + offset
		location.y = Terrain.height_at(location.x, location.z) + 0.3
		var slab := part(self, Vector3(4.0, 0.65, 2.5), location, Color(0.66, 0.8, 0.83))
		slab.rotation = Vector3(0.08, offset.x * 0.12, -0.08)
		var body := StaticBody3D.new()
		body.transform = slab.transform
		body.collision_layer = 1
		body.collision_mask = 0
		var collider := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(4.0, 0.65, 2.5)
		collider.shape = shape
		body.add_child(collider)
		add_child(body)
	# Two simple stakes suggest an approach and a place to park. The final
	# stretch across the shallow crater to the far rim is a short walk.
	for at in [APPROACH, PARKING]:
		var location: Vector3 = at
		location.y = Terrain.height_at(location.x, location.z)
		part(self, Vector3(0.14, 1.9, 0.14), location + Vector3.UP * 0.95, white)
		part(self, Vector3(0.55, 0.18, 0.16), location + Vector3.UP * 1.65, orange)

func reset() -> void:
	stage = Stage.OUTBOUND
	instrument.visible = false

func can_deploy(astronaut: CharacterBody3D) -> bool:
	return stage == Stage.OUTBOUND and astronaut.is_on_floor() and astronaut.global_position.distance_to(target) <= INTERACT_RANGE

func deploy() -> bool:
	if stage != Stage.OUTBOUND:
		return false
	stage = Stage.RETURNING
	instrument.visible = true
	return true

func check_return(astronaut: CharacterBody3D, in_rover: bool) -> bool:
	if stage != Stage.RETURNING or in_rover or not astronaut.is_on_floor():
		return false
	if astronaut.global_position.distance_to(HOME) > 3.8:
		return false
	stage = Stage.COMPLETE
	return true

func guidance(camera: Camera3D, at: Vector3) -> String:
	if stage == Stage.COMPLETE:
		return "SURVEY 01 COMPLETE · Instrument deployed. Explore freely or reset the trip."
	var destination := target if stage == Stage.OUTBOUND else HOME
	var distance := Vector2(destination.x - at.x, destination.z - at.z).length()
	var delta_at := destination - camera.global_position
	delta_at.y = 0.0
	var forward := -camera.global_transform.basis.z
	forward.y = 0.0
	var right := camera.global_transform.basis.x
	right.y = 0.0
	var bearing := rad_to_deg(atan2(right.normalized().dot(delta_at), forward.normalized().dot(delta_at)))
	var direction := "ahead" if absf(bearing) < 20.0 else "behind" if absf(bearing) > 150.0 else "right" if bearing > 0.0 else "left"
	var objective := "SURVEY 01 · Deploy the instrument at the crater rim" if stage == Stage.OUTBOUND else "SURVEY 01 · Return to WAKE / 01 and step out"
	return "%s\n%02d m · %s" % [objective, roundi(distance), direction]

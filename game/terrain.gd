extends Node3D
## One immutable, low-poly height mesh. No chunks, voxels, or streaming.

const HALF_SIZE := 120.0
const CELL := 3.0
const CRATERS := [Vector3(-38.0, 0.0, -30.0), Vector3(42.0, 0.0, -62.0), Vector3(55.0, 0.0, 45.0)]

static func height_at(x: float, z: float) -> float:
	var h := 0.65 * sin(x * 0.065) * cos(z * 0.05) + 0.4 * sin(z * 0.11 + x * 0.035)
	for crater in CRATERS:
		var distance := Vector2(x - crater.x, z - crater.z).length()
		h += 1.5 * exp(-pow((distance - 15.0) / 4.5, 2.0)) - 1.7 * exp(-pow(distance / 11.0, 2.0))
	# A gentle, flat landing area around the astronaut and parked rover.
	h *= smoothstep(12.0, 25.0, Vector2(x, z).length())
	return h

func build() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cells := int(HALF_SIZE * 2.0 / CELL)
	for z in range(cells):
		for x in range(cells):
			var x0 := -HALF_SIZE + x * CELL
			var z0 := -HALF_SIZE + z * CELL
			var a := Vector3(x0, height_at(x0, z0), z0)
			var b := Vector3(x0 + CELL, height_at(x0 + CELL, z0), z0)
			var c := Vector3(x0, height_at(x0, z0 + CELL), z0 + CELL)
			var d := Vector3(x0 + CELL, height_at(x0 + CELL, z0 + CELL), z0 + CELL)
			triangle(surface, a, b, c, x, z)
			triangle(surface, b, d, c, x + 17, z)
	var mesh := surface.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.94
	mesh.surface_set_material(0, material)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	add_child(visual)
	var ground := StaticBody3D.new()
	ground.name = "TerrainCollision"
	ground.collision_layer = 1
	ground.collision_mask = 0
	var shape := CollisionShape3D.new()
	shape.shape = mesh.create_trimesh_shape()
	ground.add_child(shape)
	add_child(ground)

func triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, x: int, z: int) -> void:
	var tint := fposmod(sin(x * 12.9898 + z * 78.233) * 43758.5453, 1.0)
	var ice := smoothstep(0.25, 0.8, sin(a.x * 0.07 + a.z * 0.03))
	var color := Color(0.29, 0.32, 0.34).lerp(Color(0.62, 0.68, 0.7), ice)
	color *= 0.9 + tint * 0.16
	var normal := (c - a).cross(b - a).normalized()
	surface.set_color(color)
	surface.set_normal(normal)
	# Clockwise winding when viewed from above (Godot front faces).
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)

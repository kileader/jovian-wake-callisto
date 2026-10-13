extends SceneTree
## Render actual game cameras into PNGs for visual review; no headless renderer.

const Playground = preload("res://game/playground.gd")

func _initialize() -> void:
	call_deferred("run")

func shot(name_at: String) -> void:
	for i in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var result := image.save_png("res://artifacts/" + name_at + ".png")
	print("Capture %s: %d" % [name_at, result])

func run() -> void:
	var game := Playground.new()
	game.capture_mouse = false
	root.add_child(game)
	for i in range(40):
		await physics_frame
	game.set_paused(true)
	game.paused = false # Freeze bodies, retain normal HUD for the capture.
	game.note = ""
	await shot("on-foot")
	game.astronaut.position = Vector3(-9.0, 0.07, -4.0)
	game.astronaut.camera.look_at(Vector3(-9.0, 1.8, 3.0), Vector3.UP)
	await shot("building-sign")
	game.reset_site()
	game.note = ""
	game.astronaut.camera.rotation = Vector3.ZERO
	game.astronaut.position = Vector3(7, 0.07, -5)
	game.astronaut.rotation.y = 0.9
	game.astronaut.pitch = -0.14
	game.astronaut.head.rotation.x = game.astronaut.pitch
	await shot("rover-approach")
	game.interact()
	game.note = ""
	await shot("rover-cockpit")
	game.exit_rover()
	game.note = ""
	await shot("rover-exit")
	Input.action_press("visor_zoom")
	game.astronaut.camera.fov = 20.0
	game.astronaut.camera.look_at(game.sky_objects.get_node("Jupiter").global_position, Vector3.UP)
	await shot("jupiter-visor")
	game.astronaut.camera.look_at(game.sky_objects.get_node("Sun").global_position, Vector3.UP)
	await shot("sun-visor")
	game.astronaut.camera.look_at(game.sky_objects.get_node("Ganymede").global_position, Vector3.UP)
	await shot("ganymede-visor")
	Input.action_release("visor_zoom")
	game.reset_site()
	game.note = ""
	game.astronaut.position = Vector3(42, 0, -52)
	game.astronaut.position.y = Playground.Terrain.height_at(42, -52) + 0.07
	game.astronaut.camera.rotation = Vector3.ZERO
	game.astronaut.camera.look_at(game.survey.target + Vector3.UP * 1.4, Vector3.UP)
	await shot("survey-approach")
	game.astronaut.position = game.survey.target + Vector3(1.8, 0.1, 1.8)
	game.astronaut.camera.look_at(game.survey.target + Vector3.UP * 1.85, Vector3.UP)
	await shot("survey-marker")
	game.survey.deploy()
	await shot("survey-deployed")
	game.astronaut.position = Vector3(-9, 0.07, 1)
	game.survey.stage = Playground.SurveyTrip.Stage.COMPLETE
	game.astronaut.camera.look_at(Vector3(-9, 1.8, 3), Vector3.UP)
	await shot("survey-complete")
	quit()

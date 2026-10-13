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
	quit()

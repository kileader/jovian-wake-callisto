extends SceneTree
## Exercise the configured startup scene and its handoff to the actual game.

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func open_startup() -> Node:
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	await process_frame
	await process_frame
	return current_scene

func wait_for_game() -> bool:
	var deadline := Time.get_ticks_msec() + 5000
	while current_scene == null or current_scene.scene_file_path != "res://game/playground.tscn":
		if Time.get_ticks_msec() > deadline:
			check(false, "Splash must reach the playground within five seconds")
			return false
		await process_frame
	return true

func run() -> void:
	var splash := await open_startup()
	check(splash.scene_file_path == "res://game/startup.tscn", "Project starts with the inherited studio splash")
	check(splash.next_scene_path == "res://game/playground.tscn", "Splash destination is the playground")
	check(splash.get_node("Logo").modulate.a < 0.1, "Logo begins transparent")
	await create_timer(0.7).timeout
	check(splash.get_node("Logo").modulate.a > 0.99, "Logo fades in and holds")
	check(await wait_for_game(), "Normal fade sequence opens the game")
	var opening := current_scene
	opening.reset_site()
	await process_frame
	check(current_scene == opening, "Reset keeps the playground without replaying the splash")

	for kind in ["keyboard", "mouse", "gamepad"]:
		splash = await open_startup()
		var repeat := InputEventKey.new()
		repeat.keycode = KEY_ESCAPE
		repeat.pressed = true
		repeat.echo = true
		Input.parse_input_event(repeat)
		var drift := InputEventJoypadMotion.new()
		drift.axis_value = 0.1
		Input.parse_input_event(drift)
		await process_frame
		check(not splash._finished, "Key repeat and stick drift do not skip")
		var event: InputEvent
		if kind == "keyboard":
			event = InputEventKey.new()
			event.keycode = KEY_ESCAPE
		elif kind == "mouse":
			event = InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
		else:
			event = InputEventJoypadButton.new()
			event.button_index = JOY_BUTTON_START
		event.pressed = true
		Input.parse_input_event(event)
		# Duplicate presses must still produce only one transition.
		Input.parse_input_event(event.duplicate())
		check(await wait_for_game(), "%s skips to the game" % kind)
		check(not current_scene.paused, "%s skip does not pause the game" % kind)
		event.pressed = false
		Input.parse_input_event(event)
		await process_frame
	print("Startup checks: %d, failures: %d" % [checks, failures])
	quit(1 if failures else 0)

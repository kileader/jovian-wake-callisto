extends SceneTree

const Playground = preload("res://game/playground.gd")
const JovianSky = preload("res://game/sky.gd")
var game
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func action(name: StringName, pressed: bool) -> void:
	if pressed:
		Input.action_press(name)
	else:
		Input.action_release(name)

func pad_button(code: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = code
	event.pressed = pressed
	Input.parse_input_event(event)

func pad_axis(code: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = code
	event.axis_value = value
	Input.parse_input_event(event)

func run() -> void:
	game = Playground.new()
	game.capture_mouse = false
	root.add_child(game)
	await frames(40)
	check(game.astronaut.is_on_floor(), "Astronaut settles on collidable terrain")
	check(game.rover.is_on_floor(), "Rover settles on collidable terrain")
	check(game.astronaut.camera.current, "Start in first person")
	check(game.rover.wheels.size() == 6, "Six rover wheels")
	check(not game.interact(), "Cannot enter the rover from outside interaction range")
	check(absf(JovianSky.angular_diameter(71492.0, 1882700.0) - 4.35245) < 0.0001, "Jupiter angular diameter uses real radius and distance")
	check(absf(JovianSky.angular_diameter(JovianSky.SUN_RADIUS_KM, JovianSky.SUN_DISTANCE_KM) - 0.102514) < 0.00001, "Solar disk uses its angular diameter at Jupiter")
	var jupiter = game.sky_objects.get_node("Jupiter")
	check(jupiter.mesh.height < jupiter.mesh.radius * 2.0, "Jupiter is an oblate sphere")
	for moon in JovianSky.MOONS:
		var body = game.sky_objects.get_node(moon.name)
		var expected_ratio: float = float(moon.radius) / JovianSky.moon_relative(moon).length()
		check(absf(body.mesh.radius / body.position.length() - expected_ratio) < 0.000001, "%s apparent size follows observer distance" % moon.name)

	var start: Vector3 = game.astronaut.position
	action("move_forward", true)
	await frames(60)
	action("move_forward", false)
	check(game.astronaut.position.z < start.z - 2.5, "Forward walking uses real physics frames")
	await frames(25)
	check(absf(game.astronaut.velocity.z) < 0.01, "Walking stops without input")
	var ground_y: float = game.astronaut.position.y
	pad_button(JOY_BUTTON_A, true)
	await frames(1)
	pad_button(JOY_BUTTON_A, false)
	check(game.astronaut.velocity.y > 1.5, "Jump impulse")
	var early_velocity: float = game.astronaut.velocity.y
	await frames(30)
	check(absf((early_velocity - game.astronaut.velocity.y) - 0.62) < 0.07, "Callisto gravity is 1.24 m/s²")
	await frames(48)
	check(game.astronaut.position.y > ground_y + 0.95, "Low-gravity jump has a modest apex")
	await frames(110)
	check(game.astronaut.is_on_floor(), "Jump lands without sinking through terrain")
	game.reset_site()
	await frames(35)
	action("move_forward", true)
	await frames(40)
	pad_button(JOY_BUTTON_A, true)
	await frames(2)
	pad_button(JOY_BUTTON_A, false)
	action("move_forward", false)
	var ballistic_velocity := Vector2(game.astronaut.velocity.x, game.astronaut.velocity.z)
	action("move_back", true)
	game.astronaut.look(Vector2(1.0, 0.0))
	await frames(35)
	check(Vector2(game.astronaut.velocity.x, game.astronaut.velocity.z).is_equal_approx(ballistic_velocity), "Turning and opposite input cannot redirect a ballistic jump")
	action("move_back", false)
	await frames(35)
	check(Vector2(game.astronaut.velocity.x, game.astronaut.velocity.z).is_equal_approx(ballistic_velocity), "Releasing input cannot brake in midair")
	await frames(130)
	check(game.astronaut.is_on_floor() and absf(game.astronaut.velocity.z) < 0.01, "Boots brake only after landing")
	game.reset_site()
	await frames(35)
	pad_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await frames(30)
	pad_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	check(game.astronaut.camera.fov < 21.0, "LT zooms the visor on foot")
	await frames(40)
	check(game.astronaut.camera.fov > 74.0, "Releasing LT restores normal field of view")

	# Recenter on the rover, and use the actual gamepad input path for entry.
	game.astronaut.position = game.rover.position + Vector3(2.3, 0.08, 0.0)
	game.astronaut.velocity = Vector3.ZERO
	await frames(15)
	check(game.near_rover(), "Interaction range includes either side of the rover")
	pad_button(JOY_BUTTON_X, true)
	await frames(2)
	pad_button(JOY_BUTTON_X, false)
	check(game.rover.occupied, "Gamepad X enters the rover")
	check(not game.astronaut.active and game.astronaut.collision_layer == 0, "Seated astronaut has no independent movement or collision")
	check(game.rover.camera.current, "Rover cockpit camera is current")
	check(game.hud.pad_mode, "Gamepad input changes HUD prompts")

	var rover_start: Vector3 = game.rover.position
	pad_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await frames(150)
	pad_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	check(game.rover.position.distance_to(rover_start) > 8.0, "RT drives the rover")
	check(game.rover.speed > 8.0 and game.rover.speed <= 11.01, "Rover accelerates with a bounded speed")
	var heading: float = game.rover.rotation.y
	pad_axis(JOY_AXIS_LEFT_X, 0.8)
	await frames(30)
	pad_axis(JOY_AXIS_LEFT_X, 0.0)
	check(game.rover.rotation.y < heading - 0.15, "Left stick steers while moving")
	pad_button(JOY_BUTTON_B, true)
	await frames(60)
	pad_button(JOY_BUTTON_B, false)
	check(absf(game.rover.speed) < 0.01, "Gamepad B brakes to a stop")
	pad_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await frames(90)
	pad_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	check(game.rover.speed < -4.0 and game.rover.speed >= -4.51, "LT reverses with a lower speed cap")
	check(is_equal_approx(game.rover.camera.fov, 78.0), "LT reverses without zooming the rover camera")

	pad_button(JOY_BUTTON_X, true)
	await frames(2)
	pad_button(JOY_BUTTON_X, false)
	check(not game.rover.occupied and game.astronaut.active, "X exits a moving rover safely")
	check(absf(game.rover.speed) < 0.01, "Exiting parks the rover")
	check(game.astronaut.camera.current and game.astronaut.collision_layer == 2, "Exit restores first-person camera and body")
	await frames(20)
	check(game.astronaut.is_on_floor(), "Exit lands on clear ground")

	var yaw: float = game.astronaut.rotation.y
	pad_axis(JOY_AXIS_RIGHT_X, 0.1)
	await frames(20)
	check(is_equal_approx(game.astronaut.rotation.y, yaw), "Right-stick deadzone rejects drift")
	pad_axis(JOY_AXIS_RIGHT_X, 0.7)
	await frames(30)
	pad_axis(JOY_AXIS_RIGHT_X, 0.0)
	check(game.astronaut.rotation.y < yaw - 0.1, "Right stick looks around")
	pad_button(JOY_BUTTON_START, true)
	await frames(2)
	pad_button(JOY_BUTTON_START, false)
	check(game.paused, "Menu pauses")
	var paused_at: Vector3 = game.astronaut.position
	pad_axis(JOY_AXIS_LEFT_Y, -1.0)
	await frames(30)
	pad_axis(JOY_AXIS_LEFT_Y, 0.0)
	check(game.astronaut.position.is_equal_approx(paused_at), "Paused bodies do not move")
	pad_button(JOY_BUTTON_START, true)
	await frames(2)
	pad_button(JOY_BUTTON_START, false)
	check(not game.paused, "Menu resumes")
	pad_button(JOY_BUTTON_Y, true)
	await frames(2)
	pad_button(JOY_BUTTON_Y, false)
	check(game.astronaut.position.distance_to(Vector3(0, 0, 3)) < 0.1, "Y resets the site")
	check(not game.rover.occupied, "Reset returns to on-foot mode")
	await frames(30)
	var key_start: Vector3 = game.astronaut.position
	var keyboard := InputEventKey.new()
	keyboard.physical_keycode = KEY_W
	keyboard.pressed = true
	Input.parse_input_event(keyboard)
	await frames(35)
	keyboard.pressed = false
	Input.parse_input_event(keyboard)
	check(game.astronaut.position.z < key_start.z - 1.0, "Physical W key moves the astronaut")
	check(not game.hud.pad_mode, "Keyboard input restores keyboard prompts")
	game.reset_site()

	# Every exit candidate obstructed: remain seated rather than overlapping.
	game.astronaut.position = game.rover.position + Vector3(2.3, 0.08, 0)
	await frames(10)
	check(game.interact(), "Reentry succeeds")
	var blockers: Array[Node3D] = []
	for offset in [Vector3(2.2, 0, 0), Vector3(-2.2, 0, 0), Vector3(0, 0, 2.9), Vector3(0, 0, -2.9)]:
		var blocker := StaticBody3D.new()
		blocker.position = game.rover.position + offset + Vector3(0, 1.5, 0)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.5, 3, 1.5)
		collision.shape = shape
		blocker.add_child(collision)
		game.add_child(blocker)
		blockers.append(blocker)
	await frames(3)
	check(not game.exit_rover() and game.rover.occupied, "Blocked exits leave the astronaut seated")
	for blocker in blockers:
		blocker.queue_free()
	await frames(3)
	check(game.exit_rover(), "Exit becomes available after obstructions clear")

	game.reset_site()
	game.astronaut.position = Vector3(110, 2, 0)
	game.astronaut.rotation.y = -PI / 2.0
	action("move_forward", true)
	await frames(180)
	action("move_forward", false)
	check(game.astronaut.position.x < 112.0, "Survey boundary blocks walking off the terrain")
	game.reset_site()
	game.astronaut.position = game.rover.position + Vector3(2.3, 0.08, 0)
	await frames(15)
	game.interact()
	game.rover.position = Vector3(0, 0.1, -106)
	pad_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await frames(180)
	pad_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	check(game.rover.position.z > -111.0, "Survey boundary blocks the rover at full throttle")
	check(absf(game.rover.speed) < 0.1, "Wall collision stops rover speed")
	game.reset_site()
	game.astronaut.position = Vector3(-35, 5, -30)
	await frames(240)
	check(game.astronaut.is_on_floor(), "Astronaut lands inside the crater")
	game.reset_site()
	game.rover.position.y = -15.0
	await frames(2)
	check(game.rover.position.y > -1.0, "Fall recovery returns to the landing site")
	print("Callisto Playground: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)

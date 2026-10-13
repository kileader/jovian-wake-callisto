extends RefCounted
## All keyboard and standard Godot/Xbox mappings live here.

static func install() -> void:
	bind("move_left", [key(KEY_A), axis(JOY_AXIS_LEFT_X, -1.0)])
	bind("move_right", [key(KEY_D), axis(JOY_AXIS_LEFT_X, 1.0)])
	bind("move_forward", [key(KEY_W), axis(JOY_AXIS_LEFT_Y, -1.0)])
	bind("move_back", [key(KEY_S), axis(JOY_AXIS_LEFT_Y, 1.0)])
	bind("look_left", [axis(JOY_AXIS_RIGHT_X, -1.0)], 0.20)
	bind("look_right", [axis(JOY_AXIS_RIGHT_X, 1.0)], 0.20)
	bind("look_up", [axis(JOY_AXIS_RIGHT_Y, -1.0)], 0.20)
	bind("look_down", [axis(JOY_AXIS_RIGHT_Y, 1.0)], 0.20)
	bind("jump", [key(KEY_SPACE), button(JOY_BUTTON_A)])
	bind("interact", [key(KEY_E), button(JOY_BUTTON_X)])
	bind("sprint", [key(KEY_SHIFT), button(JOY_BUTTON_LEFT_SHOULDER)])
	bind("accelerate", [axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)], 0.08)
	bind("reverse", [axis(JOY_AXIS_TRIGGER_LEFT, 1.0)], 0.08)
	bind("brake", [key(KEY_SPACE), button(JOY_BUTTON_B)])
	bind("pause_playground", [key(KEY_ESCAPE), button(JOY_BUTTON_START)])
	bind("reset_playground", [key(KEY_R), button(JOY_BUTTON_Y)])

static func bind(action: StringName, events: Array, deadzone: float = 0.18) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action, deadzone)
	for event in events:
		InputMap.action_add_event(action, event)

static func key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event

static func button(code: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = -1
	event.button_index = code
	return event

static func axis(code: JoyAxis, direction: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = -1
	event.axis = code
	event.axis_value = direction
	return event

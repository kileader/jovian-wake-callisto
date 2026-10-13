extends CanvasLayer

var title: Label
var status: Label
var objective: Label
var controls: Label
var prompt: Label
var pause_message: Label
var crosshair: Label
var pad_mode := false

func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	title = label(root, 23, Color(0.83, 0.89, 0.88))
	title.text = "CALLISTO / FIELD SITE 01"
	title.position = Vector2(28, 24)
	status = label(root, 15, Color(0.59, 0.71, 0.74))
	status.position = Vector2(29, 59)
	objective = label(root, 17, Color(0.93, 0.75, 0.46))
	objective.position = Vector2(29, 91)
	controls = label(root, 15, Color(0.78, 0.84, 0.84))
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	controls.offset_left = 28
	controls.offset_right = 900
	controls.offset_top = -91
	controls.offset_bottom = -24
	prompt = label(root, 22, Color(0.93, 0.75, 0.46))
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -330
	prompt.offset_right = 330
	prompt.offset_top = -145
	prompt.offset_bottom = -100
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair = label(root, 16, Color(0.8, 0.87, 0.85, 0.7))
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -8
	crosshair.offset_top = -12
	pause_message = label(root, 24, Color(0.95, 0.86, 0.68))
	pause_message.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pause_message.offset_left = -320
	pause_message.offset_right = 320
	pause_message.offset_top = -75
	pause_message.offset_bottom = 60
	pause_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_message.visible = false
	pad_mode = not Input.get_connected_joypads().is_empty()

func label(parent: Control, size: int, color: Color) -> Label:
	var result := Label.new()
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	result.add_theme_constant_override("shadow_offset_x", 1)
	result.add_theme_constant_override("shadow_offset_y", 2)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result

func update(occupied: bool, near_rover: bool, speed: float, paused: bool, note: String, zoomed: bool = false) -> void:
	status.text = "SURFACE GRAVITY  1.24 m/s²   /   " + ("ROVER  %02d km/h" % roundi(absf(speed) * 3.6) if occupied else "ON FOOT")
	if pad_mode:
		controls.text = "LS steer · RT drive · LT reverse · B brake · RS look\nX exit rover · Y reset site · Menu pause" if occupied else "LS walk · RS look · A jump · LB hurry\nX interact · LT visor zoom · Y reset · Menu pause"
	else:
		controls.text = "W/S drive · A/D steer · Space brake · Mouse look\nE exit rover · R reset site · Esc pause" if occupied else "WASD walk · Mouse look · Space jump · Shift hurry\nE interact · RMB visor zoom · R reset · Esc pause"
	prompt.text = ("X — EXIT ROVER" if pad_mode else "E — EXIT ROVER") if occupied else ("X — ENTER ROVER" if pad_mode else "E — ENTER ROVER") if near_rover else ""
	if not note.is_empty():
		prompt.text = note
	pause_message.visible = paused
	pause_message.text = "PAUSED\nMenu to resume · Y to reset" if pad_mode else "PAUSED\nClick or Esc to resume · R to reset"
	crosshair.visible = not paused and not zoomed

extends CharacterBody3D

const GRAVITY := 1.24
const WALK_SPEED := 3.6
const RUN_SPEED := 5.8
const JUMP_SPEED := 1.65 # ~1.1 m ascent, ~2.7 s flight on level ground.
const MOUSE_SENSITIVITY := 0.0022
const PAD_LOOK_SPEED := 2.1
const NORMAL_FOV := 75.0
const ZOOM_FOV := 20.0

var head: Node3D
var camera: Camera3D
var pitch := 0.0
var active := true
var controls_enabled := true
var jump_buffer := 0.0
var coyote_time := 0.0

func _ready() -> void:
	name = "Astronaut"
	collision_layer = 2
	collision_mask = 1 | 4
	floor_snap_length = 0.45
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(48.0)
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.75
	var collider := CollisionShape3D.new()
	collider.shape = capsule
	collider.position.y = 0.88
	add_child(collider)
	head = Node3D.new()
	head.position.y = 1.65
	add_child(head)
	camera = Camera3D.new()
	camera.fov = NORMAL_FOV
	camera.near = 0.06
	camera.far = 8000.0
	head.add_child(camera)
	camera.make_current()

func look(delta_look: Vector2) -> void:
	rotation.y -= delta_look.x
	pitch = clampf(pitch - delta_look.y, deg_to_rad(-85.0), deg_to_rad(85.0))
	head.rotation.x = pitch

func _physics_process(delta: float) -> void:
	if not active:
		return
	var stick := Vector2.ZERO
	var movement := Vector2.ZERO
	var jumping := false
	var running := false
	if controls_enabled:
		stick = Input.get_vector("look_left", "look_right", "look_up", "look_down")
		movement = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		jumping = Input.is_action_just_pressed("jump")
		running = Input.is_action_pressed("sprint")
	look(stick * stick.length() * PAD_LOOK_SPEED * delta)
	step_motion(delta, movement, jumping, running)

func step_motion(delta: float, movement: Vector2, jumping: bool, running: bool = false) -> void:
	var grounded := is_on_floor()
	coyote_time = 0.12 if is_on_floor() else maxf(0.0, coyote_time - delta)
	jump_buffer = 0.12 if jumping else maxf(0.0, jump_buffer - delta)
	if is_on_floor() and velocity.y < 0.0:
		velocity.y = 0.0
	velocity.y -= GRAVITY * delta
	if jump_buffer > 0.0 and coyote_time > 0.0:
		velocity.y = JUMP_SPEED
		jump_buffer = 0.0
		coyote_time = 0.0
	var desired := transform.basis * Vector3(movement.x, 0.0, movement.y)
	desired *= RUN_SPEED if running else WALK_SPEED
	# Boots provide horizontal force only while grounded. Turning the camera,
	# releasing the stick, or pressing the opposite direction cannot brake or
	# redirect a ballistic jump in vacuum. Wall collisions can still stop it.
	if grounded:
		velocity.x = move_toward(velocity.x, desired.x, 16.0 * delta)
		velocity.z = move_toward(velocity.z, desired.z, 16.0 * delta)
	move_and_slide()

func set_seated(seated: bool) -> void:
	active = not seated
	velocity = Vector3.ZERO
	jump_buffer = 0.0
	coyote_time = 0.0
	# The parked astronaut cannot collide with the rover while seated.
	collision_layer = 0 if seated else 2
	collision_mask = 0 if seated else 1 | 4

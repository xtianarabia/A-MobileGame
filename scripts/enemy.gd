extends CharacterBody3D

# --- Exports and Variables ---
@export var speed = 3.0
@export var alert_speed = 5.0
@export var patrol_points: Array[Vector3] = [Vector3(10, 0, 10), Vector3(-10, 0, 10), Vector3(-10, 0, -10), Vector3(10, 0, -10)]
@export var vision_angle = 45.0 # Half of the total 90-degree cone
@export var vision_range = 15.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var alert_timer: Timer = $AlertTimer

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_patrol_index = 0
var player_ref: Node3D

enum State { UNAWARE, ALERTED }
var current_state = State.UNAWARE

# --- Engine Functions ---
func _ready():
	player_ref = get_tree().get_first_node_in_group("player")
	if not player_ref:
		push_error("Player not found! The enemy needs a node in the 'player' group.")
		return

	alert_timer.timeout.connect(_on_alert_timer_timeout)
	set_state(State.UNAWARE)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	match current_state:
		State.UNAWARE:
			_state_unaware(delta)
		State.ALERTED:
			_state_alerted(delta)

	move_and_slide()

# --- State Logic ---
func _state_unaware(delta):
	patrol()
	if can_see_player():
		set_state(State.ALERTED)

func _state_alerted(delta):
	nav_agent.target_position = player_ref.global_position

	if not can_see_player():
		if alert_timer.is_stopped():
			alert_timer.start()
	else:
		alert_timer.stop()

	var direction = (nav_agent.get_next_path_position() - global_position).normalized()
	velocity.x = direction.x * alert_speed
	velocity.z = direction.z * alert_speed

	look_at(Vector3(player_ref.global_position.x, global_position.y, player_ref.global_position.z))

# --- Helper Functions ---
func set_state(new_state):
	current_state = new_state
	match current_state:
		State.UNAWARE:
			set_target_location(patrol_points[current_patrol_index])
		State.ALERTED:
			print("STATE: ALERTED") # Placeholder
			nav_agent.target_position = player_ref.global_position

func patrol():
	if nav_agent.is_navigation_finished():
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		set_target_location(patrol_points[current_patrol_index])

	var direction = (nav_agent.get_next_path_position() - global_position).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

func set_target_location(target_pos):
	nav_agent.target_position = target_pos

func can_see_player():
	if not player_ref: return false

	var space_state = get_world_3d().direct_space_state
	var direction_to_player = player_ref.global_position - global_position

	if direction_to_player.length() > vision_range:
		return false

	var forward_vector = -global_transform.basis.z
	if forward_vector.dot(direction_to_player.normalized()) < cos(deg_to_rad(vision_angle)):
		return false

	# Collision mask 2 is the player
	var query = PhysicsRayQueryParameters3D.create(global_position, player_ref.global_position, 2)
	var result = space_state.intersect_ray(query)

	return result and result.collider == player_ref

func _on_alert_timer_timeout():
	set_state(State.UNAWARE)
	print("STATE: UNAWARE") # Placeholder

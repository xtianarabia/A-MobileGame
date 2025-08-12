extends CharacterBody3D

enum State { UNAWARE, SUSPICIOUS, ALERTED, GRABBED, UNCONSCIOUS }

@export var walk_speed = 3.0
@export var suspicious_speed = 4.0
@export var alert_speed = 6.0
@export var patrol_points: Array[Vector3] = [Vector3(10, 0, 10), Vector3(-10, 0, 10), Vector3(-10, 0, -10), Vector3(10, 0, -10)]
@export var vision_angle = 45.0
@export var vision_range = 15.0
@export var box_bump_distance = 1.5

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var state_timer: Timer = $StateTimer
@onready var mesh: MeshInstance3D = $MeshInstance3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_patrol_index = 0
var player_ref: Player
var current_state: State = State.UNAWARE
var last_known_player_position: Vector3

func _ready():
	var player_node = get_tree().get_first_node_in_group("player")
	if player_node is Player: player_ref = player_node
	else: push_error("Player not found or is not of type Player!"); return

	state_timer.timeout.connect(_on_state_timer_timeout)
	NoiseManager.noise_made.connect(_on_noise_made)
	set_state(State.UNAWARE)

func _physics_process(delta):
	if not is_on_floor() and current_state != State.GRABBED:
		velocity.y -= gravity * delta

	if current_state in [State.UNAWARE, State.SUSPICIOUS] and can_see_player():
		set_state(State.ALERTED)

	match current_state:
		State.UNAWARE: _state_unaware()
		State.SUSPICIOUS: _state_suspicious()
		State.ALERTED: _state_alerted()
		State.GRABBED: _state_grabbed()
		State.UNCONSCIOUS: _state_unconscious()

	if current_state != State.GRABBED:
		move_and_slide()

# --- Public Functions for Player Interaction ---
func get_grabbed(grabber: Node3D):
	set_state(State.GRABBED)

func release_grab():
	set_state(State.ALERTED) # When released, become alerted

func choke_out():
	set_state(State.UNCONSCIOUS)

# --- State Logic ---
func _state_unaware(): patrol()
func _state_suspicious():
	var speed = suspicious_speed
	var direction = (nav_agent.get_next_path_position() - global_position).normalized()
	velocity.x = direction.x * speed; velocity.z = direction.z * speed
	if nav_agent.is_navigation_finished() and state_timer.is_stopped(): state_timer.start()

func _state_alerted():
	nav_agent.target_position = player_ref.global_position
	last_known_player_position = player_ref.global_position
	if not can_see_player(): set_state(State.SUSPICIOUS)

	var speed = alert_speed
	var direction = (nav_agent.get_next_path_position() - global_position).normalized()
	velocity.x = direction.x * speed; velocity.z = direction.z * speed
	look_at(Vector3(player_ref.global_position.x, global_position.y, player_ref.global_position.z))

func _state_grabbed():
	velocity = Vector3.ZERO # Stop all movement

func _state_unconscious():
	velocity = Vector3.ZERO # Stay put
	# Optional: Lay down animation/rotation
	var target_rotation = Vector3(deg_to_rad(90), rotation.y, rotation.z)
	if not rotation.is_equal_approx(target_rotation):
		rotation = rotation.lerp(target_rotation, 0.1)

# --- Helper Functions ---
func set_state(new_state: State):
	if new_state == current_state: return
	current_state = new_state

	match current_state:
		State.UNAWARE:
			nav_agent.set_navigation_enabled(true)
			set_target_location(patrol_points[current_patrol_index])
		State.SUSPICIOUS:
			nav_agent.set_navigation_enabled(true)
			# Safety check to prevent crash if this state is entered without a known position
			if last_known_player_position:
				set_target_location(last_known_player_position)
			else:
				# Failsafe: if we have no position to investigate, just go back to patrolling.
				set_state(State.UNAWARE)
		State.ALERTED:
			nav_agent.set_navigation_enabled(true)
			state_timer.stop()
			nav_agent.target_position = player_ref.global_position
		State.GRABBED, State.UNCONSCIOUS:
			nav_agent.set_navigation_enabled(false)
			velocity = Vector3.ZERO

func patrol():
	if nav_agent.is_navigation_finished():
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		set_target_location(patrol_points[current_patrol_index])

	var speed = walk_speed
	var direction = (nav_agent.get_next_path_position() - global_position).normalized()
	velocity.x = direction.x * speed; velocity.z = direction.z * speed

func set_target_location(target_pos: Vector3): nav_agent.target_position = target_pos

func can_see_player() -> bool:
	if not player_ref or current_state in [State.GRABBED, State.UNCONSCIOUS]: return false
	var space_state = get_world_3d().direct_space_state
	var dir_to_player = player_ref.global_position - global_position
	if dir_to_player.length() > vision_range: return false
	if -global_transform.basis.z.dot(dir_to_player.normalized()) < cos(deg_to_rad(vision_angle)): return false

	var query = PhysicsRayQueryParameters3D.create(global_position, player_ref.global_position, 2, [self.get_rid()])
	var result = space_state.intersect_ray(query)

	if result and result.collider == player_ref:
		if player_ref.current_state == Player.State.BOX_HIDING:
			return global_position.distance_to(player_ref.global_position) < box_bump_distance
		return true
	return false

# --- Signal Handlers ---
func _on_noise_made(position: Vector3, loudness: float):
	if current_state == State.UNAWARE:
		if global_position.distance_to(position) < loudness:
			last_known_player_position = position
			set_state(State.SUSPICIOUS)

func _on_state_timer_timeout():
	if current_state == State.SUSPICIOUS: set_state(State.UNAWARE)

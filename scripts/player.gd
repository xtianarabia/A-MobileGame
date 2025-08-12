class_name Player
extends CharacterBody3D

enum State { NORMAL, SNEAKING, CROUCHING, BOX_HIDING, GRABBING }

@export var walk_speed = 5.0
@export var sneak_speed = 2.5
@export var crouch_speed = 1.5
@export var running_noise_loudness = 10.0
@export var ammo = 5

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var player_mesh: MeshInstance3D = $PlayerMesh
@onready var box_mesh: MeshInstance3D = $BoxMesh
@onready var grab_area: Area3D = $GrabArea
@onready var muzzle: Marker3D = $Muzzle

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_state: State = State.NORMAL
var grabbed_enemy: CharacterBody3D = null
var dart_scene = preload("res://scenes/dart.tscn")

const CAPSULE_HEIGHT_NORMAL = 2.0
const CAPSULE_HEIGHT_CROUCH = 1.0

func _input(event):
	# Handle single-press actions here. _unhandled_input is better but this works too.
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_C:
				if current_state == State.CROUCHING: set_state(State.NORMAL)
				else: set_state(State.CROUCHING)
			KEY_B:
				if current_state == State.BOX_HIDING: set_state(State.NORMAL)
				elif current_state != State.CROUCHING: set_state(State.BOX_HIDING)
			KEY_E:
				if current_state == State.GRABBING:
					if is_instance_valid(grabbed_enemy): grabbed_enemy.choke_out()
					set_state(State.NORMAL)
				else:
					attempt_grab()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		fire_weapon()

func _physics_process(delta):
	# State transitions for held keys
	if current_state == State.NORMAL or current_state == State.SNEAKING:
		if Input.is_key_pressed(KEY_SHIFT):
			set_state(State.SNEAKING)
		else:
			set_state(State.NORMAL)

	apply_gravity(delta)
	handle_movement()
	move_and_slide()

func apply_gravity(delta):
	if not is_on_floor(): velocity.y -= gravity * delta

func handle_movement():
	if current_state in [State.BOX_HIDING, State.GRABBING]:
		velocity.x = move_toward(velocity.x, 0, walk_speed)
		velocity.z = move_toward(velocity.z, 0, walk_speed)
		if current_state == State.GRABBING and is_instance_valid(grabbed_enemy):
			var hold_position = global_transform.origin - global_transform.basis.z * 1.0
			grabbed_enemy.global_position = hold_position
		return

	var input_dir = get_input_direction()
	# For top-down games, we use world coordinates, not player's transform.basis
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	var current_speed = get_current_speed()

	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		if current_state == State.NORMAL:
			NoiseManager.broadcast_noise(global_position, running_noise_loudness)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	if direction: look_at(global_position + direction)

func get_input_direction() -> Vector2:
	# Handle WASD and arrow keys for movement
	var input_dir = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"): input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"): input_dir.x += 1
	return input_dir

func get_current_speed() -> float:
	match current_state:
		State.SNEAKING: return sneak_speed
		State.CROUCHING: return crouch_speed
		_: return walk_speed

func set_state(new_state: State):
	if new_state == current_state: return

	if current_state == State.GRABBING and is_instance_valid(grabbed_enemy):
		grabbed_enemy.release_grab()
		grabbed_enemy = null

	current_state = new_state

	match current_state:
		State.CROUCHING:
			player_mesh.visible = true; box_mesh.visible = false
			if collision_shape.shape is CapsuleShape3D:
				var shape: CapsuleShape3D = collision_shape.shape
				shape.height = CAPSULE_HEIGHT_CROUCH
				collision_shape.position.y = CAPSULE_HEIGHT_CROUCH / 2.0
				player_mesh.position.y = CAPSULE_HEIGHT_CROUCH / 2.0
		State.BOX_HIDING:
			player_mesh.visible = false; box_mesh.visible = true
		_:
			player_mesh.visible = true; box_mesh.visible = false
			if collision_shape.shape is CapsuleShape3D:
				var shape: CapsuleShape3D = collision_shape.shape
				shape.height = CAPSULE_HEIGHT_NORMAL
				collision_shape.position.y = CAPSULE_HEIGHT_NORMAL / 2.0
				player_mesh.position.y = CAPSULE_HEIGHT_NORMAL / 2.0

func attempt_grab():
	var bodies = grab_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy"):
			grabbed_enemy = body
			grabbed_enemy.get_grabbed(self)
			set_state(State.GRABBING)
			return

func fire_weapon():
	if ammo > 0 and current_state not in [State.BOX_HIDING, State.GRABBING]:
		ammo -= 1
		print("Ammo left: ", ammo)
		var dart = dart_scene.instantiate()
		get_tree().root.add_child(dart)
		dart.global_transform = muzzle.global_transform
	else:
		print("Cannot fire! No ammo or wrong state.")

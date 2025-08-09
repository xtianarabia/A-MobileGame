extends CharacterBody3D

@export var speed = 5.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
    # Apply gravity.
    if not is_on_floor():
        velocity.y -= gravity * delta

    # Get input for X and Z axes from both arrow keys and WASD.
    var input_dir = Vector2.ZERO
    if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
        input_dir.x += 1
    if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
        input_dir.x -= 1
    if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
        input_dir.y += 1
    if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
        input_dir.y -= 1

    var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()

    # Set velocity for horizontal movement.
    if direction:
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    else:
        # Apply friction/deceleration when no input is given.
        velocity.x = move_toward(velocity.x, 0, speed)
        velocity.z = move_toward(velocity.z, 0, speed)

    move_and_slide()
